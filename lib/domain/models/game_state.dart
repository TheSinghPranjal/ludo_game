import '../../core/constants.dart';
import 'board_position.dart';
import 'game_status.dart';
import 'player_state.dart';
import 'token_state.dart';

export 'board_position.dart';
export 'game_status.dart';
export 'player_color.dart';
export 'player_state.dart';
export 'token_state.dart';

class GameState {
  const GameState({
    required this.gameId,
    required this.status,
    required this.players,
    required this.tokens,
    required this.turnNumber,
    required this.diceRolled,
    required this.consecutiveSixes,
    required this.validMoves,
    required this.revision,
    required this.turnId,
    required this.phase,
    required this.aiEnabled,
    this.currentPlayerId,
    this.diceValue,
    this.winnerId,
    this.lastCaptureTokenId,
    this.forfeitedSixes = false,
    this.finishedOrder = const [],
    this.turnTimerSecondsRemaining = TimingConstants.turnTimerSeconds,
    this.lastTurnWasAutoPlayed = false,
    this.mode = GameMode.wifiMultiplayer,
  });

  final String gameId;
  final GameStatus status;
  final List<PlayerState> players;
  final List<TokenState> tokens;
  final String? currentPlayerId;
  final int turnNumber;
  final int? diceValue;
  final bool diceRolled;
  final int consecutiveSixes;
  final List<String> validMoves;
  final String? winnerId;
  final int revision;
  final String turnId;
  final TurnPhase phase;
  final bool aiEnabled;
  final String? lastCaptureTokenId;
  final bool forfeitedSixes;
  final List<String> finishedOrder;
  final int turnTimerSecondsRemaining;
  final bool lastTurnWasAutoPlayed;
  final GameMode mode;

  bool get isFinished => status == GameStatus.finished;
  bool get isActive => status == GameStatus.active;

  PlayerState? playerById(String id) {
    for (final player in players) {
      if (player.playerId == id) {
        return player;
      }
    }
    return null;
  }

  PlayerState? get currentPlayer =>
      currentPlayerId == null ? null : playerById(currentPlayerId!);

  TokenState tokenById(String tokenId) =>
      tokens.firstWhere((t) => t.tokenId == tokenId);

  List<TokenState> tokensFor(String playerId) =>
      tokens.where((t) => t.playerId == playerId).toList();

  bool get canRoll =>
      status == GameStatus.active &&
      phase == TurnPhase.waitingForRoll &&
      !diceRolled;

  bool get canMove =>
      status == GameStatus.active &&
      phase == TurnPhase.waitingForMove &&
      diceRolled &&
      validMoves.isNotEmpty;

  GameState copyWith({
    GameStatus? status,
    List<PlayerState>? players,
    List<TokenState>? tokens,
    String? currentPlayerId,
    bool clearCurrentPlayer = false,
    int? turnNumber,
    int? diceValue,
    bool clearDiceValue = false,
    bool? diceRolled,
    int? consecutiveSixes,
    List<String>? validMoves,
    String? winnerId,
    bool clearWinner = false,
    int? revision,
    String? turnId,
    TurnPhase? phase,
    bool? aiEnabled,
    String? lastCaptureTokenId,
    bool clearLastCapture = false,
    bool? forfeitedSixes,
    List<String>? finishedOrder,
    int? turnTimerSecondsRemaining,
    bool? lastTurnWasAutoPlayed,
    GameMode? mode,
  }) {
    return GameState(
      gameId: gameId,
      status: status ?? this.status,
      players: players ?? this.players,
      tokens: tokens ?? this.tokens,
      currentPlayerId: clearCurrentPlayer
          ? null
          : (currentPlayerId ?? this.currentPlayerId),
      turnNumber: turnNumber ?? this.turnNumber,
      diceValue: clearDiceValue ? null : (diceValue ?? this.diceValue),
      diceRolled: diceRolled ?? this.diceRolled,
      consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
      validMoves: validMoves ?? this.validMoves,
      winnerId: clearWinner ? null : (winnerId ?? this.winnerId),
      revision: revision ?? this.revision,
      turnId: turnId ?? this.turnId,
      phase: phase ?? this.phase,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      lastCaptureTokenId: clearLastCapture
          ? null
          : (lastCaptureTokenId ?? this.lastCaptureTokenId),
      forfeitedSixes: forfeitedSixes ?? this.forfeitedSixes,
      finishedOrder: finishedOrder ?? this.finishedOrder,
      turnTimerSecondsRemaining:
          turnTimerSecondsRemaining ?? this.turnTimerSecondsRemaining,
      lastTurnWasAutoPlayed:
          lastTurnWasAutoPlayed ?? this.lastTurnWasAutoPlayed,
      mode: mode ?? this.mode,
    );
  }

  GameState bumped() => copyWith(revision: revision + 1);

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'status': status.name,
    'players': players.map((p) => p.toJson()).toList(),
    'tokens': tokens.map((t) => t.toJson()).toList(),
    'currentPlayerId': currentPlayerId,
    'turnNumber': turnNumber,
    'diceValue': diceValue,
    'diceRolled': diceRolled,
    'consecutiveSixes': consecutiveSixes,
    'validMoves': validMoves,
    'winnerId': winnerId,
    'revision': revision,
    'turnId': turnId,
    'phase': phase.name,
    'aiEnabled': aiEnabled,
    'lastCaptureTokenId': lastCaptureTokenId,
    'forfeitedSixes': forfeitedSixes,
    'finishedOrder': finishedOrder,
    'turnTimerSecondsRemaining': turnTimerSecondsRemaining,
    'lastTurnWasAutoPlayed': lastTurnWasAutoPlayed,
    'mode': mode.name,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      gameId: json['gameId'] as String,
      status: GameStatus.values.byName(json['status'] as String),
      players: (json['players'] as List)
          .map((e) => PlayerState.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      tokens: (json['tokens'] as List)
          .map((e) => TokenState.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      currentPlayerId: json['currentPlayerId'] as String?,
      turnNumber: json['turnNumber'] as int? ?? 0,
      diceValue: json['diceValue'] as int?,
      diceRolled: json['diceRolled'] as bool? ?? false,
      consecutiveSixes: json['consecutiveSixes'] as int? ?? 0,
      validMoves: (json['validMoves'] as List? ?? const [])
          .map((e) => e as String)
          .toList(),
      winnerId: json['winnerId'] as String?,
      revision: json['revision'] as int? ?? 0,
      turnId: json['turnId'] as String? ?? '',
      phase: TurnPhase.values.byName(
        json['phase'] as String? ?? TurnPhase.waitingForRoll.name,
      ),
      aiEnabled: json['aiEnabled'] as bool? ?? false,
      lastCaptureTokenId: json['lastCaptureTokenId'] as String?,
      forfeitedSixes: json['forfeitedSixes'] as bool? ?? false,
      finishedOrder: (json['finishedOrder'] as List? ?? const [])
          .map((e) => e as String)
          .toList(),
      turnTimerSecondsRemaining:
          json['turnTimerSecondsRemaining'] as int? ??
          TimingConstants.turnTimerSeconds,
      lastTurnWasAutoPlayed: json['lastTurnWasAutoPlayed'] as bool? ?? false,
      mode: GameMode.values.byName(
        json['mode'] as String? ?? GameMode.wifiMultiplayer.name,
      ),
    );
  }

  static GameState lobby({
    required String gameId,
    required PlayerState host,
    GameMode mode = GameMode.wifiMultiplayer,
  }) {
    return GameState(
      gameId: gameId,
      status: GameStatus.lobby,
      players: [host],
      tokens: _tokensFor(host),
      currentPlayerId: null,
      turnNumber: 0,
      diceValue: null,
      diceRolled: false,
      consecutiveSixes: 0,
      validMoves: const [],
      winnerId: null,
      revision: 1,
      turnId: 't0',
      phase: TurnPhase.waitingForRoll,
      aiEnabled: false,
      mode: mode,
    );
  }

  static List<TokenState> _tokensFor(PlayerState player) {
    return [
      for (var slot = 0; slot < BoardConstants.tokensPerPlayer; slot++)
        TokenState(
          tokenId: '${player.color.name}_$slot',
          playerId: player.playerId,
          colorId: player.color.name,
          slot: slot,
          position: BoardPosition.base(slot: slot),
          state: TokenLogicalState.base,
        ),
    ];
  }

  static List<TokenState> tokensForPlayers(List<PlayerState> players) {
    return [for (final player in players) ..._tokensFor(player)];
  }
}
