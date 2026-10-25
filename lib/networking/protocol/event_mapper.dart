import '../../domain/game_state/game_engine.dart';
import '../../domain/models/game_state.dart';
import 'messages.dart';

List<ServerMessage> messagesFor(EngineResult result) {
  final game = result.state.toJson();
  return [
    for (final event in result.events) _map(event, result.state, game),
    CurrentGameStateMessage(game: game),
  ];
}

ServerMessage _map(
  EngineEvent event,
  GameState state,
  Map<String, dynamic> game,
) {
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
    PlayerWonEvent() => PlayerWonMessage(playerId: event.playerId, game: game),
    GameFinishedEvent() => GameFinishedMessage(
      winnerId: event.winnerId,
      game: game,
    ),
    TurnAutoPlayedEvent() => TurnAutoPlayedMessage(
      playerId: event.playerId,
      tokenId: event.tokenId,
      game: game,
    ),
  };
}
