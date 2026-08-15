import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants.dart';
import '../../core/debug_log.dart';
import '../../domain/game_state/game_engine.dart';
import '../../domain/models/game_state.dart';
import '../../services/dice_service.dart';
import '../protocol/messages.dart';

typedef ServerMessageHandler = void Function(ServerMessage message);

class _Session {
  _Session({
    required this.id,
    this.channel,
    this.onMessage,
    this.playerId,
  });

  final String id;
  final WebSocketChannel? channel;
  final ServerMessageHandler? onMessage;
  String? playerId;
  DateTime lastPong = DateTime.now();
}

/// Authoritative local multiplayer server. Owns game state and DiceService.
class GameServer {
  GameServer({
    DiceService? diceService,
    Uuid? uuid,
    this.port = NetworkConstants.serverPort,
  })  : _dice = diceService ?? const SecureDiceService(),
        _uuid = uuid ?? const Uuid() {
    _engine = GameEngine(diceService: _dice, uuid: _uuid);
  }

  final DiceService _dice;
  final Uuid _uuid;
  final int port;
  late final GameEngine _engine;

  HttpServer? _http;
  GameState? _state;
  final _sessions = <String, _Session>{};
  final _seenCommands = <String>{};
  var _actionGen = 0;
  Timer? _heartbeat;
  Timer? _aiTimer;

  GameState? get state => _state;
  bool get isRunning => _http != null || _state != null;

  Future<void> start({
    required String hostName,
    required String hostPlayerId,
    required String reconnectToken,
  }) async {
    await stop();
    final host = PlayerState(
      playerId: hostPlayerId,
      name: hostName,
      color: PlayerColor.green,
      isReady: false,
      isConnected: true,
      isHost: true,
      isAi: false,
      reconnectToken: reconnectToken,
    );
    _state = GameState.lobby(gameId: _uuid.v4(), host: host);

    final handler = webSocketHandler((WebSocketChannel channel, _) {
      final session = _Session(id: _uuid.v4(), channel: channel);
      _sessions[session.id] = session;
      channel.stream.listen(
        (raw) => _onRaw(session, raw),
        onDone: () => _onDisconnect(session),
        onError: (_) => _onDisconnect(session),
        cancelOnError: true,
      );
    });

    _http = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    _heartbeat = Timer.periodic(NetworkConstants.heartbeatInterval, (_) {
      _tickHeartbeat();
    });
    debugLog('SERVER_STARTED', {'port': port, 'gameId': _state!.gameId});
  }

  void attachLocalHost(ServerMessageHandler onMessage, String playerId) {
    final session = _Session(
      id: 'local-host',
      onMessage: onMessage,
      playerId: playerId,
    );
    _sessions[session.id] = session;
    _push(session, CurrentGameStateMessage(game: _state!.toJson()));
  }

  Future<void> stop() async {
    _actionGen++;
    _heartbeat?.cancel();
    _aiTimer?.cancel();
    for (final session in _sessions.values) {
      try {
        session.channel?.sink.close();
      } catch (_) {}
    }
    _sessions.clear();
    _seenCommands.clear();
    await _http?.close(force: true);
    _http = null;
    _state = null;
  }

  void playAgain() {
    if (_state == null) {
      return;
    }
    _actionGen++;
    _state = _engine.returnToLobby(_state!);
    _broadcast(CurrentGameStateMessage(game: _state!.toJson()));
  }

  void handleLocal(ClientMessage message, String playerId) {
    final session = _sessions['local-host'];
    if (session == null) {
      return;
    }
    session.playerId = playerId;
    _handle(session, message);
  }

  void _onRaw(_Session session, dynamic raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      final message = ClientMessage.tryParse(decoded);
      if (message == null) {
        _send(
          session,
          ErrorMessage(
            code: GameErrorCode.malformedMessage.name,
            message: 'Malformed network message',
          ),
        );
        return;
      }
      _handle(session, message);
    } catch (_) {
      _send(
        session,
        ErrorMessage(
          code: GameErrorCode.malformedMessage.name,
          message: 'Malformed network message',
        ),
      );
    }
  }

  void _handle(_Session session, ClientMessage message) {
    if (message.commandId.isNotEmpty) {
      if (_seenCommands.contains(message.commandId)) {
        debugLog('DUPLICATE_COMMAND', {'id': message.commandId});
        return;
      }
      _seenCommands.add(message.commandId);
      if (_seenCommands.length > 400) {
        _seenCommands.remove(_seenCommands.first);
      }
    }

    try {
      switch (message) {
        case JoinGameMessage():
          _join(session, message);
        case LeaveGameMessage():
          _leave(session);
        case ReadyMessage():
          _mutate(
            session,
            (state) => _engine.setReady(state, _requirePlayer(session), message.ready),
            extra: (s) => [PlayerReadyMessage(game: s.toJson())],
          );
        case ClaimColorMessage():
          _mutate(
            session,
            (state) => _engine.claimColor(
              state,
              _requirePlayer(session),
              PlayerColor.fromId(message.color),
            ),
            extra: (s) => [PlayerJoinedMessage(game: s.toJson())],
          );
        case StartGameMessage():
          _requireHost(session);
          final result = _engine.startGame(_state!);
          _commit(result);
          _broadcast(GameStartMessage(game: result.state.toJson()));
          _scheduleFollowUp();
        case RollDiceMessage():
          debugLog('ROLL_DICE', {'playerId': session.playerId});
          _play(
            session,
            (state) => _engine.rollDice(state, _requirePlayer(session)),
          );
        case MoveTokenMessage():
          debugLog('MOVE_TOKEN', {
            'playerId': session.playerId,
            'tokenId': message.tokenId,
          });
          _play(
            session,
            (state) => _engine.moveToken(
              state,
              _requirePlayer(session),
              message.tokenId,
            ),
          );
        case RequestStateMessage():
          if (_state != null) {
            _send(session, CurrentGameStateMessage(game: _state!.toJson()));
          }
        case PingMessage():
          _send(session, PongMessage(nonce: message.nonce));
        case ClientPongMessage():
          session.lastPong = DateTime.now();
        case SetAiEnabledMessage():
          _requireHost(session);
          _mutate(
            session,
            (state) => _engine.setAiEnabled(state, message.enabled),
            extra: (s) => [CurrentGameStateMessage(game: s.toJson())],
          );
        case FabricatedClientMessage():
          throw GameException(
            message.rawType == 'DICE_RESULT'
                ? GameErrorCode.fabricatedDice
                : GameErrorCode.fabricatedPosition,
            'Host does not accept client-authored ${message.rawType}',
          );
      }
    } on GameException catch (error) {
      _send(
        session,
        ErrorMessage(code: error.code.name, message: error.message),
      );
    } catch (error) {
      _send(
        session,
        ErrorMessage(
          code: GameErrorCode.malformedMessage.name,
          message: error.toString(),
        ),
      );
    }
  }

  void _join(_Session session, JoinGameMessage message) {
    final state = _state;
    if (state == null) {
      throw GameException(GameErrorCode.hostUnavailable, 'Server is not ready');
    }

    if (message.playerId != null && message.reconnectToken != null) {
      final existing = state.playerById(message.playerId!);
      if (existing != null &&
          existing.reconnectToken == message.reconnectToken) {
        session.playerId = existing.playerId;
        _state = _engine.markConnected(state, existing.playerId, true);
        _send(session, CurrentGameStateMessage(game: _state!.toJson()));
        _broadcast(PlayerJoinedMessage(game: _state!.toJson()));
        return;
      }
    }

    if (state.status != GameStatus.lobby) {
      throw GameException(
        GameErrorCode.gameAlreadyStarted,
        'Game already started',
      );
    }

    final color = _nextColor(state, message.requestedColor);
    final playerId = message.playerId ?? _uuid.v4();
    final player = PlayerState(
      playerId: playerId,
      name: message.name.trim().isEmpty ? 'Player' : message.name.trim(),
      color: color,
      isReady: false,
      isConnected: true,
      isHost: false,
      isAi: false,
      reconnectToken: _uuid.v4(),
    );
    _state = _engine.addPlayer(state, player);
    session.playerId = playerId;
    _send(session, CurrentGameStateMessage(game: _state!.toJson()));
    _broadcast(PlayerJoinedMessage(game: _state!.toJson()));
  }

  PlayerColor _nextColor(GameState state, String? requested) {
    if (requested != null) {
      final color = PlayerColor.fromId(requested);
      if (state.players.every((p) => p.color != color)) {
        return color;
      }
    }
    for (final color in PlayerColor.values) {
      if (state.players.every((p) => p.color != color)) {
        return color;
      }
    }
    throw GameException(GameErrorCode.gameFull, 'No colors remaining');
  }

  void _leave(_Session session) {
    final playerId = session.playerId;
    if (playerId == null || _state == null) {
      return;
    }
    if (_state!.playerById(playerId)?.isHost == true) {
      _broadcast(const HostDisconnectedMessage());
      unawaited(stop());
      return;
    }
    if (_state!.status == GameStatus.lobby) {
      _state = _engine.removePlayer(_state!, playerId);
    } else {
      _state = _engine.markConnected(_state!, playerId, false);
    }
    _broadcast(PlayerLeftMessage(playerId: playerId, game: _state!.toJson()));
    session.playerId = null;
  }

  void _onDisconnect(_Session session) {
    _sessions.remove(session.id);
    final playerId = session.playerId;
    if (playerId == null || _state == null) {
      return;
    }
    if (_state!.playerById(playerId)?.isHost == true) {
      _broadcast(const HostDisconnectedMessage());
      unawaited(stop());
      return;
    }
    try {
      _state = _engine.markConnected(_state!, playerId, false);
      _broadcast(PlayerLeftMessage(playerId: playerId, game: _state!.toJson()));
    } catch (_) {}
  }

  void _play(_Session session, EngineResult Function(GameState) apply) {
    if (_state == null) {
      return;
    }
    _actionGen++;
    final result = apply(_state!);
    _commit(result);
    _scheduleFollowUp();
  }

  void _mutate(
    _Session session,
    GameState Function(GameState) apply, {
    List<ServerMessage> Function(GameState)? extra,
  }) {
    _state = apply(_state!);
    for (final message in extra?.call(_state!) ?? const <ServerMessage>[]) {
      _broadcast(message);
    }
  }

  void _commit(EngineResult result) {
    _state = result.state;
    for (final event in result.events) {
      _broadcast(_toMessage(event, result.state));
    }
    _broadcast(CurrentGameStateMessage(game: result.state.toJson()));
  }

  ServerMessage _toMessage(EngineEvent event, GameState state) {
    final game = state.toJson();
    return switch (event) {
      DiceRolledEvent() => DiceResultMessage(
          playerId: event.playerId,
          value: event.value,
          turnId: event.turnId,
          forfeited: event.forfeited,
          game: game,
        ),
      ValidMovesEvent() => ValidMovesMessage(
          tokenIds: event.tokenIds,
          game: game,
        ),
      TokenMovedEvent() => TokenMovedMessage(
          tokenId: event.tokenId,
          from: event.from,
          to: event.to,
          path: event.path,
          game: game,
        ),
      TokenCapturedEvent() => TokenCapturedMessage(
          tokenId: event.tokenId,
          byTokenId: event.byTokenId,
          game: game,
        ),
      TokenReachedHomeEvent() => TokenReachedHomeMessage(
          tokenId: event.tokenId,
          game: game,
        ),
      TurnChangedEvent() => TurnChangedMessage(
          playerId: event.playerId,
          turnId: event.turnId,
          turnNumber: event.turnNumber,
          reason: event.reason,
          game: game,
        ),
      PlayerWonEvent() => PlayerWonMessage(
          playerId: event.playerId,
          game: game,
        ),
      GameFinishedEvent() => GameFinishedMessage(
          winnerId: event.winnerId,
          game: game,
        ),
    };
  }

  void _scheduleFollowUp() {
    final state = _state;
    if (state == null || state.status != GameStatus.active) {
      return;
    }
    final gen = _actionGen;
    final player = state.currentPlayer;
    if (player == null) {
      return;
    }

    if (player.isAi && state.canRoll) {
      _aiTimer?.cancel();
      _aiTimer = Timer(TimingConstants.autoMoveDelay, () {
        if (gen != _actionGen || _state == null) {
          return;
        }
        _actionGen++;
        final result = _engine.rollDice(_state!, player.playerId);
        _commit(result);
        _scheduleFollowUp();
      });
      return;
    }

    if (state.phase == TurnPhase.waitingForMove &&
        state.validMoves.length == 1) {
      final tokenId = state.validMoves.single;
      final delay = player.isAi
          ? TimingConstants.autoMoveDelay
          : TimingConstants.autoMoveDelay;
      _aiTimer?.cancel();
      _aiTimer = Timer(delay, () {
        if (gen != _actionGen || _state == null) {
          return;
        }
        if (!_state!.validMoves.contains(tokenId)) {
          return;
        }
        _actionGen++;
        final result =
            _engine.moveToken(_state!, state.currentPlayerId!, tokenId);
        _commit(result);
        _scheduleFollowUp();
      });
      return;
    }

    if (player.isAi &&
        state.phase == TurnPhase.waitingForMove &&
        state.validMoves.isNotEmpty) {
      _aiTimer?.cancel();
      _aiTimer = Timer(TimingConstants.autoMoveDelay, () {
        if (gen != _actionGen || _state == null) {
          return;
        }
        final choice =
            _state!.validMoves[Random().nextInt(_state!.validMoves.length)];
        _actionGen++;
        final result =
            _engine.moveToken(_state!, player.playerId, choice);
        _commit(result);
        _scheduleFollowUp();
      });
    }
  }

  void _tickHeartbeat() {
    final now = DateTime.now();
    for (final session in [..._sessions.values]) {
      _send(session, ServerPingMessage(nonce: _uuid.v4()));
      if (session.channel != null &&
          now.difference(session.lastPong) > NetworkConstants.heartbeatTimeout) {
        try {
          session.channel?.sink.close();
        } catch (_) {}
        _onDisconnect(session);
      }
    }
  }

  String _requirePlayer(_Session session) {
    final id = session.playerId;
    if (id == null) {
      throw GameException(GameErrorCode.unknownPlayer, 'Join the game first');
    }
    return id;
  }

  void _requireHost(_Session session) {
    final id = _requirePlayer(session);
    if (_state?.playerById(id)?.isHost != true) {
      throw GameException(GameErrorCode.hostOnly, 'Only the host can do that');
    }
  }

  void _broadcast(ServerMessage message) {
    debugLog(message.toJson()['type'] as String? ?? 'EVENT');
    for (final session in [..._sessions.values]) {
      _send(session, message);
    }
  }

  void _push(_Session session, ServerMessage message) =>
      _send(session, message);

  void _send(_Session session, ServerMessage message) {
    final encoded = jsonEncode(message.toJson());
    session.onMessage?.call(message);
    try {
      session.channel?.sink.add(encoded);
    } catch (_) {}
  }
}
