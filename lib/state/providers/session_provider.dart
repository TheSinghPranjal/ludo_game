import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/debug_log.dart';
import '../../domain/game_state/local_game_controller.dart';
import '../../domain/models/game_state.dart';
import '../../networking/client/game_client.dart';
import '../../networking/network_info.dart';
import '../../networking/protocol/messages.dart';
import '../../networking/server/game_server.dart';
import '../session_state.dart';

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);

final gameStateProvider = Provider<GameState?>((ref) {
  return ref.watch(sessionProvider).game;
});

final lobbyProvider = Provider<GameState?>((ref) {
  final game = ref.watch(gameStateProvider);
  return game?.status == GameStatus.lobby ? game : null;
});

final connectionProvider = Provider<ConnectionStatus>((ref) {
  return ref.watch(sessionProvider).connection;
});

final localPlayerProvider = Provider((ref) {
  final session = ref.watch(sessionProvider);
  final id = session.localPlayerId;
  if (id == null) {
    return null;
  }
  return session.game?.playerById(id);
});

final currentTurnProvider = Provider<CurrentTurnView>((ref) {
  final session = ref.watch(sessionProvider);
  final game = session.game;
  final player = game?.currentPlayer;
  // Pass-and-play seats all share this device, so name whoever is up.
  final isLocal =
      !session.isPassAndPlay &&
      player?.playerId != null &&
      player!.playerId == session.localPlayerId;
  return CurrentTurnView(
    playerId: player?.playerId,
    isLocal: isLocal,
    label: player == null
        ? ''
        : isLocal
        ? 'YOUR TURN'
        : '${player.name}\'s turn',
  );
});

final diceProvider = Provider<DiceUiState>((ref) {
  final session = ref.watch(sessionProvider);
  final game = session.game;
  final local = session.localPlayerId;
  final enabled =
      game != null &&
      game.status == GameStatus.active &&
      game.canRoll &&
      game.currentPlayerId == local;
  return DiceUiState(
    face: game?.diceValue ?? 1,
    rolling: false,
    enabled: enabled,
  );
});

/// Header sound toggle. The game has no audio yet; this records the choice.
final soundEnabledProvider = StateProvider<bool>((ref) => true);

final networkStatusProvider = Provider<String>((ref) {
  final session = ref.watch(sessionProvider);
  return switch (session.connection) {
    ConnectionStatus.idle => 'Idle',
    ConnectionStatus.hosting => 'Hosting',
    ConnectionStatus.connecting => 'Connecting',
    ConnectionStatus.connected =>
      session.isHost ? 'Host' : 'Connected to ${session.connectedHost}',
    ConnectionStatus.error => session.error ?? 'Error',
    ConnectionStatus.local => 'Pass and play',
  };
});

class SessionNotifier extends Notifier<SessionState> {
  final _uuid = const Uuid();
  final _network = const LocalNetworkInfo();
  GameServer? _server;
  GameClient? _client;
  LocalGameController? _local;
  StreamSubscription<ServerMessage>? _clientSub;

  @override
  SessionState build() {
    ref.onDispose(() {
      unawaited(_teardown());
    });
    return const SessionState();
  }

  void setPlayerName(String name) {
    final trimmed = name.trim();
    state = state.copyWith(playerName: trimmed.isEmpty ? 'Player' : trimmed);
  }

  Future<void> startPassAndPlay({
    required int playerCount,
    required List<String> names,
  }) async {
    await _teardown();
    final count = playerCount.clamp(
      BoardConstants.minPlayers,
      BoardConstants.maxPlayers,
    );
    final colors = BoardConstants.seatColors(count);
    final players = [
      for (var i = 0; i < colors.length; i++)
        PlayerState(
          playerId: 'hotseat-$i',
          name: i < names.length && names[i].trim().isNotEmpty
              ? names[i].trim()
              : 'Player ${i + 1}',
          color: colors[i],
          isReady: true,
          isConnected: true,
          isHost: i == 0,
          isAi: false,
          reconnectToken: '',
        ),
    ];
    final local = LocalGameController(onMessage: _onServerMessage);
    _local = local;
    state = state.copyWith(
      role: SessionRole.passAndPlay,
      connection: ConnectionStatus.local,
      localPlayerId: players.first.playerId,
      hostDisconnected: false,
      clearError: true,
    );
    local.start(players: players);
  }

  void adoptCurrentPassAndPlayPlayer() {
    if (!state.isPassAndPlay) {
      return;
    }
    final currentId = state.game?.currentPlayerId;
    if (currentId != null) {
      state = state.copyWith(localPlayerId: currentId);
    }
  }

  Future<void> hostGame() async {
    await _teardown();
    final playerId = _uuid.v4();
    final token = _uuid.v4();
    final server = GameServer();
    _server = server;
    try {
      await server.start(
        hostName: state.playerName,
        hostPlayerId: playerId,
        reconnectToken: token,
      );
      final ips = await _network.ipv4Addresses();
      server.attachLocalHost(_onServerMessage, playerId);
      state = state.copyWith(
        role: SessionRole.host,
        connection: ConnectionStatus.hosting,
        localPlayerId: playerId,
        reconnectToken: token,
        hostIps: ips,
        connectedHost: ips.isEmpty
            ? '0.0.0.0:${NetworkConstants.serverPort}'
            : '${ips.first}:${NetworkConstants.serverPort}',
        game: server.state,
        hostDisconnected: false,
        clearError: true,
      );
    } catch (error) {
      await _teardown();
      state = state.copyWith(
        connection: ConnectionStatus.error,
        error: 'Could not start host: $error',
      );
    }
  }

  Future<void> joinGame(String hostRaw) async {
    final address = HostAddress.tryParse(hostRaw);
    if (address == null) {
      state = state.copyWith(
        connection: ConnectionStatus.error,
        error: 'Invalid host IP',
      );
      throw GameException(GameErrorCode.invalidHostIp, 'Invalid host IP');
    }

    await _teardown();
    state = state.copyWith(
      role: SessionRole.client,
      connection: ConnectionStatus.connecting,
      connectedHost: address.display,
      clearError: true,
      hostDisconnected: false,
    );

    final client = GameClient();
    _client = client;
    _clientSub = client.messages.listen(_onServerMessage);
    try {
      await client.connect(address);
      final playerId = state.localPlayerId ?? _uuid.v4();
      final token = state.reconnectToken ?? _uuid.v4();
      state = state.copyWith(
        localPlayerId: playerId,
        reconnectToken: token,
        connection: ConnectionStatus.connected,
      );
      client.join(
        name: state.playerName,
        playerId: playerId,
        reconnectToken: token,
      );
    } on GameException catch (error) {
      state = state.copyWith(
        connection: ConnectionStatus.error,
        error: error.message,
      );
      rethrow;
    } catch (_) {
      state = state.copyWith(
        connection: ConnectionStatus.error,
        error: 'Host unavailable',
      );
      rethrow;
    }
  }

  Future<void> reconnect() async {
    final host = state.connectedHost;
    if (host == null || state.role != SessionRole.client) {
      return;
    }
    await joinGame(host);
    _client?.requestState();
  }

  void ready(bool value) =>
      _send(ReadyMessage(commandId: _uuid.v4(), ready: value));

  void claimColor(PlayerColor color) =>
      _send(ClaimColorMessage(commandId: _uuid.v4(), color: color.name));

  void startGame() => _send(StartGameMessage(commandId: _uuid.v4()));

  void rollDice() {
    final game = state.game;
    if (game == null ||
        game.currentPlayerId != state.localPlayerId ||
        !game.canRoll) {
      return;
    }
    debugLog('ROLL_DICE');
    _send(RollDiceMessage(commandId: _uuid.v4()));
  }

  void moveToken(String tokenId) {
    final game = state.game;
    if (game == null ||
        game.currentPlayerId != state.localPlayerId ||
        !game.validMoves.contains(tokenId)) {
      return;
    }
    debugLog('MOVE_TOKEN', {'tokenId': tokenId});
    _send(MoveTokenMessage(commandId: _uuid.v4(), tokenId: tokenId));
  }

  void setAiEnabled(bool enabled) =>
      _send(SetAiEnabledMessage(commandId: _uuid.v4(), enabled: enabled));

  void playAgain() {
    if (state.isPassAndPlay) {
      _local?.playAgain();
      return;
    }
    if (state.isHost) {
      _server?.playAgain();
    }
  }

  void requestState() => _send(RequestStateMessage(commandId: _uuid.v4()));

  Future<void> leave() async {
    _send(LeaveGameMessage(commandId: _uuid.v4()));
    await _teardown();
    state = const SessionState();
  }

  void _send(ClientMessage message) {
    if (state.isPassAndPlay) {
      switch (message) {
        case RollDiceMessage():
          _local?.rollDice(state.localPlayerId ?? '');
        case MoveTokenMessage(:final tokenId):
          _local?.moveToken(state.localPlayerId ?? '', tokenId);
        default:
          break;
      }
      return;
    }
    if (state.isHost) {
      _server?.handleLocal(message, state.localPlayerId ?? '');
    } else {
      _client?.send(message);
    }
  }

  void _onServerMessage(ServerMessage message) {
    if (message is ErrorMessage) {
      state = state.copyWith(error: message.message, lastEvent: message);
      return;
    }
    if (message is HostDisconnectedMessage) {
      state = state.copyWith(
        hostDisconnected: true,
        connection: ConnectionStatus.error,
        error: 'Host disconnected',
        lastEvent: message,
      );
      return;
    }
    if (message is TurnTimerUpdateMessage) {
      final game = state.game;
      if (game != null && game.turnId == message.turnId) {
        state = state.copyWith(
          game: game.copyWith(
            turnTimerSecondsRemaining: message.secondsRemaining,
          ),
          lastEvent: message,
        );
      }
      return;
    }

    final json = switch (message) {
      PlayerJoinedMessage(:final game) => game,
      PlayerLeftMessage(:final game) => game,
      PlayerReadyMessage(:final game) => game,
      GameStartMessage(:final game) => game,
      TurnStartedMessage(:final game) => game,
      DiceResultMessage(:final game) => game,
      ValidMovesMessage(:final game) => game,
      TokenMovedMessage(:final game) => game,
      TokenCapturedMessage(:final game) => game,
      TokenReachedHomeMessage(:final game) => game,
      TurnChangedMessage(:final game) => game,
      PlayerWonMessage(:final game) => game,
      GameFinishedMessage(:final game) => game,
      CurrentGameStateMessage(:final game) => game,
      TurnAutoPlayedMessage(:final game) => game,
      _ => null,
    };

    GameState? game = state.game;
    if (json != null) {
      try {
        final incoming = GameState.fromJson(json);
        if (game == null || incoming.revision >= game.revision) {
          game = incoming;
        }
      } catch (_) {
        debugLog('STALE_OR_BAD_STATE');
      }
    }

    String? localId = state.localPlayerId;
    String? token = state.reconnectToken;
    if (game != null && localId != null) {
      final me = game.playerById(localId);
      if (me != null && me.reconnectToken.isNotEmpty) {
        token = me.reconnectToken;
      }
    }

    // Pass-and-play: silently follow the authoritative current player so dice
    // and tokens work without any handoff popup. Wi-Fi keeps a fixed seat.
    if (state.isPassAndPlay &&
        game != null &&
        game.currentPlayerId != null &&
        game.status == GameStatus.active) {
      localId = game.currentPlayerId;
    }

    state = state.copyWith(
      game: game,
      localPlayerId: localId,
      reconnectToken: token,
      lastEvent: message,
      connection: state.isPassAndPlay
          ? ConnectionStatus.local
          : state.isHost
          ? ConnectionStatus.hosting
          : ConnectionStatus.connected,
      clearError: message is! ErrorMessage,
    );
  }

  Future<void> _teardown() async {
    await _clientSub?.cancel();
    _clientSub = null;
    await _client?.dispose();
    _client = null;
    await _server?.stop();
    _server = null;
    _local?.dispose();
    _local = null;
  }
}
