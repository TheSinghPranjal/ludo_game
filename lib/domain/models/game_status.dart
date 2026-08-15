enum TokenLogicalState { base, active, home }

enum GameStatus { lobby, active, finished }

enum TurnPhase { waitingForRoll, waitingForMove, finished }

enum GameErrorCode {
  invalidHostIp,
  connectionRefused,
  hostUnavailable,
  gameFull,
  gameAlreadyStarted,
  invalidMove,
  notPlayersTurn,
  invalidDiceRequest,
  disconnectedPlayer,
  timeout,
  malformedMessage,
  unknownPlayer,
  colorTaken,
  notReady,
  notEnoughPlayers,
  hostOnly,
  gameFinished,
  duplicateCommand,
  staleState,
  fabricatedDice,
  fabricatedPosition,
  playerNotFound,
}

class GameException implements Exception {
  GameException(this.code, this.message);

  final GameErrorCode code;
  final String message;

  @override
  String toString() => 'GameException(${code.name}): $message';
}
