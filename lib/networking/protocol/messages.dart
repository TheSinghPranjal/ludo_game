import '../../domain/models/board_position.dart';

enum ClientMessageType {
  joinGame,
  leaveGame,
  ready,
  claimColor,
  startGame,
  rollDice,
  moveToken,
  requestState,
  ping,
  pong,
  setAiEnabled,
}

enum ServerMessageType {
  playerJoined,
  playerLeft,
  playerReady,
  gameStart,
  turnStarted,
  diceResult,
  validMoves,
  tokenMoved,
  tokenCaptured,
  tokenReachedHome,
  turnChanged,
  playerWon,
  gameFinished,
  currentGameState,
  pong,
  ping,
  error,
  hostDisconnected,
}

sealed class ClientMessage {
  const ClientMessage({required this.commandId});

  final String commandId;
  ClientMessageType get type;
  Map<String, dynamic> toJson();

  static ClientMessage? tryParse(Object? raw) {
    try {
      if (raw is! Map) {
        return null;
      }
      final json = Map<String, dynamic>.from(raw);
      final type = json['type'] as String?;
      final commandId = json['commandId'] as String? ?? '';
      return switch (type) {
        'JOIN_GAME' => JoinGameMessage(
            commandId: commandId,
            name: json['name'] as String? ?? 'Player',
            playerId: json['playerId'] as String?,
            reconnectToken: json['reconnectToken'] as String?,
            requestedColor: json['requestedColor'] as String?,
          ),
        'LEAVE_GAME' => LeaveGameMessage(commandId: commandId),
        'READY' => ReadyMessage(
            commandId: commandId,
            ready: json['ready'] as bool? ?? true,
          ),
        'CLAIM_COLOR' => ClaimColorMessage(
            commandId: commandId,
            color: json['color'] as String,
          ),
        'START_GAME' => StartGameMessage(commandId: commandId),
        'ROLL_DICE' => RollDiceMessage(commandId: commandId),
        'MOVE_TOKEN' => MoveTokenMessage(
            commandId: commandId,
            tokenId: json['tokenId'] as String,
          ),
        'REQUEST_STATE' => RequestStateMessage(commandId: commandId),
        'PING' => PingMessage(
            commandId: commandId,
            nonce: json['nonce'] as String? ?? '',
          ),
        'PONG' => ClientPongMessage(
            commandId: commandId,
            nonce: json['nonce'] as String? ?? '',
          ),
        'SET_AI_ENABLED' => SetAiEnabledMessage(
            commandId: commandId,
            enabled: json['enabled'] as bool? ?? false,
          ),
        'DICE_RESULT' || 'TOKEN_POSITION' || 'SET_WINNER' =>
          FabricatedClientMessage(commandId: commandId, rawType: type!),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}

class JoinGameMessage extends ClientMessage {
  JoinGameMessage({
    required super.commandId,
    required this.name,
    this.playerId,
    this.reconnectToken,
    this.requestedColor,
  });

  final String name;
  final String? playerId;
  final String? reconnectToken;
  final String? requestedColor;

  @override
  ClientMessageType get type => ClientMessageType.joinGame;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'JOIN_GAME',
        'commandId': commandId,
        'name': name,
        'playerId': playerId,
        'reconnectToken': reconnectToken,
        'requestedColor': requestedColor,
      };
}

class LeaveGameMessage extends ClientMessage {
  LeaveGameMessage({required super.commandId});

  @override
  ClientMessageType get type => ClientMessageType.leaveGame;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'LEAVE_GAME',
        'commandId': commandId,
      };
}

class ReadyMessage extends ClientMessage {
  ReadyMessage({required super.commandId, required this.ready});

  final bool ready;

  @override
  ClientMessageType get type => ClientMessageType.ready;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'READY',
        'commandId': commandId,
        'ready': ready,
      };
}

class ClaimColorMessage extends ClientMessage {
  ClaimColorMessage({required super.commandId, required this.color});

  final String color;

  @override
  ClientMessageType get type => ClientMessageType.claimColor;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'CLAIM_COLOR',
        'commandId': commandId,
        'color': color,
      };
}

class StartGameMessage extends ClientMessage {
  StartGameMessage({required super.commandId});

  @override
  ClientMessageType get type => ClientMessageType.startGame;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'START_GAME',
        'commandId': commandId,
      };
}

class RollDiceMessage extends ClientMessage {
  RollDiceMessage({required super.commandId});

  @override
  ClientMessageType get type => ClientMessageType.rollDice;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ROLL_DICE',
        'commandId': commandId,
      };
}

class MoveTokenMessage extends ClientMessage {
  MoveTokenMessage({required super.commandId, required this.tokenId});

  final String tokenId;

  @override
  ClientMessageType get type => ClientMessageType.moveToken;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'MOVE_TOKEN',
        'commandId': commandId,
        'tokenId': tokenId,
      };
}

class RequestStateMessage extends ClientMessage {
  RequestStateMessage({required super.commandId});

  @override
  ClientMessageType get type => ClientMessageType.requestState;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'REQUEST_STATE',
        'commandId': commandId,
      };
}

class PingMessage extends ClientMessage {
  PingMessage({required super.commandId, required this.nonce});

  final String nonce;

  @override
  ClientMessageType get type => ClientMessageType.ping;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PING',
        'commandId': commandId,
        'nonce': nonce,
      };
}

class ClientPongMessage extends ClientMessage {
  ClientPongMessage({required super.commandId, required this.nonce});

  final String nonce;

  @override
  ClientMessageType get type => ClientMessageType.pong;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PONG',
        'commandId': commandId,
        'nonce': nonce,
      };
}

class SetAiEnabledMessage extends ClientMessage {
  SetAiEnabledMessage({required super.commandId, required this.enabled});

  final bool enabled;

  @override
  ClientMessageType get type => ClientMessageType.setAiEnabled;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'SET_AI_ENABLED',
        'commandId': commandId,
        'enabled': enabled,
      };
}

class FabricatedClientMessage extends ClientMessage {
  FabricatedClientMessage({required super.commandId, required this.rawType});

  final String rawType;

  @override
  ClientMessageType get type => ClientMessageType.rollDice;

  @override
  Map<String, dynamic> toJson() => {'type': rawType, 'commandId': commandId};
}

sealed class ServerMessage {
  const ServerMessage();

  Map<String, dynamic> toJson();

  static ServerMessage? tryParse(Object? raw) {
    try {
      if (raw is! Map) {
        return null;
      }
      final json = Map<String, dynamic>.from(raw);
      final type = json['type'] as String?;
      return switch (type) {
        'PLAYER_JOINED' => PlayerJoinedMessage.fromJson(json),
        'PLAYER_LEFT' => PlayerLeftMessage.fromJson(json),
        'PLAYER_READY' => PlayerReadyMessage.fromJson(json),
        'GAME_START' => GameStartMessage.fromJson(json),
        'TURN_STARTED' => TurnStartedMessage.fromJson(json),
        'DICE_RESULT' => DiceResultMessage.fromJson(json),
        'VALID_MOVES' => ValidMovesMessage.fromJson(json),
        'TOKEN_MOVED' => TokenMovedMessage.fromJson(json),
        'TOKEN_CAPTURED' => TokenCapturedMessage.fromJson(json),
        'TOKEN_REACHED_HOME' => TokenReachedHomeMessage.fromJson(json),
        'TURN_CHANGED' => TurnChangedMessage.fromJson(json),
        'PLAYER_WON' => PlayerWonMessage.fromJson(json),
        'GAME_FINISHED' => GameFinishedMessage.fromJson(json),
        'CURRENT_GAME_STATE' => CurrentGameStateMessage.fromJson(json),
        'PONG' => PongMessage.fromJson(json),
        'PING' => ServerPingMessage.fromJson(json),
        'ERROR' => ErrorMessage.fromJson(json),
        'HOST_DISCONNECTED' => const HostDisconnectedMessage(),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}

class PlayerJoinedMessage extends ServerMessage {
  PlayerJoinedMessage({required this.game});
  final Map<String, dynamic> game;

  factory PlayerJoinedMessage.fromJson(Map<String, dynamic> json) =>
      PlayerJoinedMessage(
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {'type': 'PLAYER_JOINED', 'game': game};
}

class PlayerLeftMessage extends ServerMessage {
  PlayerLeftMessage({required this.playerId, required this.game});
  final String playerId;
  final Map<String, dynamic> game;

  factory PlayerLeftMessage.fromJson(Map<String, dynamic> json) =>
      PlayerLeftMessage(
        playerId: json['playerId'] as String,
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PLAYER_LEFT',
        'playerId': playerId,
        'game': game,
      };
}

class PlayerReadyMessage extends ServerMessage {
  PlayerReadyMessage({required this.game});
  final Map<String, dynamic> game;

  factory PlayerReadyMessage.fromJson(Map<String, dynamic> json) =>
      PlayerReadyMessage(
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {'type': 'PLAYER_READY', 'game': game};
}

class GameStartMessage extends ServerMessage {
  GameStartMessage({required this.game});
  final Map<String, dynamic> game;

  factory GameStartMessage.fromJson(Map<String, dynamic> json) =>
      GameStartMessage(game: Map<String, dynamic>.from(json['game'] as Map));

  @override
  Map<String, dynamic> toJson() => {'type': 'GAME_START', 'game': game};
}

class TurnStartedMessage extends ServerMessage {
  TurnStartedMessage({
    required this.playerId,
    required this.turnId,
    required this.turnNumber,
    required this.game,
  });

  final String playerId;
  final String turnId;
  final int turnNumber;
  final Map<String, dynamic> game;

  factory TurnStartedMessage.fromJson(Map<String, dynamic> json) =>
      TurnStartedMessage(
        playerId: json['playerId'] as String,
        turnId: json['turnId'] as String,
        turnNumber: json['turnNumber'] as int,
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'TURN_STARTED',
        'playerId': playerId,
        'turnId': turnId,
        'turnNumber': turnNumber,
        'game': game,
      };
}

class DiceResultMessage extends ServerMessage {
  DiceResultMessage({
    required this.playerId,
    required this.value,
    required this.turnId,
    required this.forfeited,
    required this.game,
  });

  final String playerId;
  final int value;
  final String turnId;
  final bool forfeited;
  final Map<String, dynamic> game;

  factory DiceResultMessage.fromJson(Map<String, dynamic> json) =>
      DiceResultMessage(
        playerId: json['playerId'] as String,
        value: json['value'] as int,
        turnId: json['turnId'] as String,
        forfeited: json['forfeited'] as bool? ?? false,
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'DICE_RESULT',
        'playerId': playerId,
        'value': value,
        'turnId': turnId,
        'forfeited': forfeited,
        'game': game,
      };
}

class ValidMovesMessage extends ServerMessage {
  ValidMovesMessage({required this.tokenIds, required this.game});
  final List<String> tokenIds;
  final Map<String, dynamic> game;

  factory ValidMovesMessage.fromJson(Map<String, dynamic> json) =>
      ValidMovesMessage(
        tokenIds:
            (json['tokenIds'] as List).map((e) => e as String).toList(),
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'VALID_MOVES',
        'tokenIds': tokenIds,
        'game': game,
      };
}

class TokenMovedMessage extends ServerMessage {
  TokenMovedMessage({
    required this.tokenId,
    required this.from,
    required this.to,
    required this.path,
    required this.game,
  });

  final String tokenId;
  final BoardPosition from;
  final BoardPosition to;
  final List<BoardPosition> path;
  final Map<String, dynamic> game;

  factory TokenMovedMessage.fromJson(Map<String, dynamic> json) =>
      TokenMovedMessage(
        tokenId: json['tokenId'] as String,
        from: BoardPosition.fromJson(
          Map<String, dynamic>.from(json['from'] as Map),
        ),
        to: BoardPosition.fromJson(Map<String, dynamic>.from(json['to'] as Map)),
        path: (json['path'] as List)
            .map(
              (e) => BoardPosition.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'TOKEN_MOVED',
        'tokenId': tokenId,
        'from': from.toJson(),
        'to': to.toJson(),
        'path': path.map((p) => p.toJson()).toList(),
        'game': game,
      };
}

class TokenCapturedMessage extends ServerMessage {
  TokenCapturedMessage({
    required this.tokenId,
    required this.byTokenId,
    required this.game,
  });

  final String tokenId;
  final String byTokenId;
  final Map<String, dynamic> game;

  factory TokenCapturedMessage.fromJson(Map<String, dynamic> json) =>
      TokenCapturedMessage(
        tokenId: json['tokenId'] as String,
        byTokenId: json['byTokenId'] as String,
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'TOKEN_CAPTURED',
        'tokenId': tokenId,
        'byTokenId': byTokenId,
        'game': game,
      };
}

class TokenReachedHomeMessage extends ServerMessage {
  TokenReachedHomeMessage({required this.tokenId, required this.game});
  final String tokenId;
  final Map<String, dynamic> game;

  factory TokenReachedHomeMessage.fromJson(Map<String, dynamic> json) =>
      TokenReachedHomeMessage(
        tokenId: json['tokenId'] as String,
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'TOKEN_REACHED_HOME',
        'tokenId': tokenId,
        'game': game,
      };
}

class TurnChangedMessage extends ServerMessage {
  TurnChangedMessage({
    required this.playerId,
    required this.turnId,
    required this.turnNumber,
    required this.game,
    this.reason,
  });

  final String playerId;
  final String turnId;
  final int turnNumber;
  final String? reason;
  final Map<String, dynamic> game;

  factory TurnChangedMessage.fromJson(Map<String, dynamic> json) =>
      TurnChangedMessage(
        playerId: json['playerId'] as String,
        turnId: json['turnId'] as String,
        turnNumber: json['turnNumber'] as int,
        reason: json['reason'] as String?,
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'TURN_CHANGED',
        'playerId': playerId,
        'turnId': turnId,
        'turnNumber': turnNumber,
        'reason': reason,
        'game': game,
      };
}

class PlayerWonMessage extends ServerMessage {
  PlayerWonMessage({required this.playerId, required this.game});
  final String playerId;
  final Map<String, dynamic> game;

  factory PlayerWonMessage.fromJson(Map<String, dynamic> json) =>
      PlayerWonMessage(
        playerId: json['playerId'] as String,
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PLAYER_WON',
        'playerId': playerId,
        'game': game,
      };
}

class GameFinishedMessage extends ServerMessage {
  GameFinishedMessage({required this.winnerId, required this.game});
  final String winnerId;
  final Map<String, dynamic> game;

  factory GameFinishedMessage.fromJson(Map<String, dynamic> json) =>
      GameFinishedMessage(
        winnerId: json['winnerId'] as String,
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'GAME_FINISHED',
        'winnerId': winnerId,
        'game': game,
      };
}

class CurrentGameStateMessage extends ServerMessage {
  CurrentGameStateMessage({required this.game});
  final Map<String, dynamic> game;

  factory CurrentGameStateMessage.fromJson(Map<String, dynamic> json) =>
      CurrentGameStateMessage(
        game: Map<String, dynamic>.from(json['game'] as Map),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'CURRENT_GAME_STATE',
        'game': game,
      };
}

class PongMessage extends ServerMessage {
  PongMessage({required this.nonce});
  final String nonce;

  factory PongMessage.fromJson(Map<String, dynamic> json) =>
      PongMessage(nonce: json['nonce'] as String? ?? '');

  @override
  Map<String, dynamic> toJson() => {'type': 'PONG', 'nonce': nonce};
}

class ServerPingMessage extends ServerMessage {
  ServerPingMessage({required this.nonce});
  final String nonce;

  factory ServerPingMessage.fromJson(Map<String, dynamic> json) =>
      ServerPingMessage(nonce: json['nonce'] as String? ?? '');

  @override
  Map<String, dynamic> toJson() => {'type': 'PING', 'nonce': nonce};
}

class ErrorMessage extends ServerMessage {
  ErrorMessage({required this.code, required this.message});
  final String code;
  final String message;

  factory ErrorMessage.fromJson(Map<String, dynamic> json) => ErrorMessage(
        code: json['code'] as String? ?? 'unknown',
        message: json['message'] as String? ?? 'Unknown error',
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ERROR',
        'code': code,
        'message': message,
      };
}

class HostDisconnectedMessage extends ServerMessage {
  const HostDisconnectedMessage();

  @override
  Map<String, dynamic> toJson() => {'type': 'HOST_DISCONNECTED'};
}
