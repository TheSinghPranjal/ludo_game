import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/core/constants.dart';
import 'package:ludo_game/domain/game_state/game_engine.dart';
import 'package:ludo_game/domain/models/game_state.dart';
import 'package:ludo_game/domain/rules/game_rules.dart';
import 'package:ludo_game/domain/rules/movement.dart';
import 'package:ludo_game/services/dice_service.dart';

PlayerState _player({
  required String id,
  required PlayerColor color,
  bool host = false,
  bool ready = true,
}) {
  return PlayerState(
    playerId: id,
    name: color.displayName,
    color: color,
    isReady: ready,
    isConnected: true,
    isHost: host,
    isAi: false,
    reconnectToken: 'tok-$id',
  );
}

GameEngine _engine(List<int> rolls) =>
    GameEngine(diceService: ScriptedDiceService(rolls));

GameState _lobby(GameEngine engine) {
  var state = GameState.lobby(
    gameId: 'game-1',
    host: _player(id: 'g', color: PlayerColor.green, host: true, ready: false),
  );
  state = engine.addPlayer(
    state,
    _player(id: 'y', color: PlayerColor.yellow, ready: false),
  );
  state = engine.setReady(state, 'g', true);
  state = engine.setReady(state, 'y', true);
  return state;
}

GameState _started(GameEngine engine) => engine.startGame(_lobby(engine)).state;

TokenState _token(
  String id,
  String playerId,
  PlayerColor color,
  BoardPosition position,
) {
  return TokenState(
    tokenId: id,
    playerId: playerId,
    colorId: color.name,
    slot: int.parse(id.split('_').last),
    position: position,
    state: position is BasePosition
        ? TokenLogicalState.base
        : position is HomePosition
            ? TokenLogicalState.home
            : TokenLogicalState.active,
  );
}

void main() {
  group('movement', () {
    test('base entry only on 6', () {
      const base = BoardPosition.base(slot: 0);
      expect(
        TokenMovement.destination(
          color: PlayerColor.green,
          current: base,
          dice: 5,
        ),
        isNull,
      );
      expect(
        TokenMovement.destination(
          color: PlayerColor.green,
          current: base,
          dice: 6,
        ),
        const BoardPosition.track(0),
      );
    });

    test('each dice 1-6 advances the track', () {
      for (var dice = 1; dice <= 6; dice++) {
        expect(
          TokenMovement.destination(
            color: PlayerColor.green,
            current: const BoardPosition.track(0),
            dice: dice,
          ),
          BoardPosition.track(dice),
        );
      }
    });

    test('exact home from home path', () {
      expect(
        TokenMovement.destination(
          color: PlayerColor.green,
          current: const BoardPosition.homePath(4),
          dice: 1,
        ),
        const BoardPosition.home(),
      );
      expect(
        TokenMovement.destination(
          color: PlayerColor.green,
          current: const BoardPosition.homePath(4),
          dice: 2,
        ),
        isNull,
      );
    });

    test('overshoot from approach is invalid', () {
      expect(
        TokenMovement.destination(
          color: PlayerColor.green,
          current: const BoardPosition.homePath(0),
          dice: 6,
        ),
        isNull,
      );
      expect(
        TokenMovement.destination(
          color: PlayerColor.green,
          current: const BoardPosition.homePath(0),
          dice: 5,
        ),
        const BoardPosition.home(),
      );
    });
  });

  group('turns and dice', () {
    test('1-5 with all tokens in base yields no moves and passes turn', () {
      final engine = _engine([1]);
      final after = engine.rollDice(_started(engine), 'g').state;
      expect(after.currentPlayerId, 'y');
      expect(after.tokensFor('g').every((t) => t.state == TokenLogicalState.base), isTrue);
    });

    test('6 with tokens in base enters start', () {
      final engine = _engine([6]);
      var state = _started(engine);
      state = engine.rollDice(state, 'g').state;
      expect(state.validMoves, isNotEmpty);
      state = engine.moveToken(state, 'g', 'green_0').state;
      expect(state.tokenById('green_0').position, const BoardPosition.track(0));
      expect(state.currentPlayerId, 'g');
    });

    test('three consecutive sixes forfeits the third roll', () {
      final engine = _engine([6, 6, 6]);
      var state = _started(engine);
      state = engine.rollDice(state, 'g').state;
      state = engine.moveToken(state, 'g', 'green_0').state;
      state = engine.rollDice(state, 'g').state;
      state = engine.moveToken(state, 'g', state.validMoves.first).state;
      final before = state.tokenById('green_0').position;
      state = engine.rollDice(state, 'g').state;
      expect(state.diceValue, 6);
      expect(state.forfeitedSixes || state.currentPlayerId == 'y', isTrue);
      expect(state.tokenById('green_0').position, before);
    });

    test('wrong player cannot roll or move', () {
      final engine = _engine([6]);
      final state = _started(engine);
      expect(
        () => engine.rollDice(state, 'y'),
        throwsA(isA<GameException>()),
      );
    });

    test('client cannot fabricate dice or positions', () {
      final engine = _engine([1]);
      final state = _started(engine);
      expect(() => engine.rejectFabricatedDice(state), throwsA(isA<GameException>()));
      expect(
        () => engine.rejectFabricatedPosition(state),
        throwsA(isA<GameException>()),
      );
    });

    test('commands after game end are rejected', () {
      final engine = _engine([6]);
      var state = _started(engine);
      state = state.copyWith(
        status: GameStatus.finished,
        phase: TurnPhase.finished,
        winnerId: 'g',
      );
      expect(
        () => engine.rollDice(state, 'g'),
        throwsA(isA<GameException>()),
      );
    });
  });

  group('capture and safe squares', () {
    test('landing on a single opponent captures', () {
      final engine = _engine([1]);
      var state = _started(engine);
      final tokens = [
        _token('green_0', 'g', PlayerColor.green, const BoardPosition.track(4)),
        _token('green_1', 'g', PlayerColor.green, const BoardPosition.base(slot: 1)),
        _token('green_2', 'g', PlayerColor.green, const BoardPosition.base(slot: 2)),
        _token('green_3', 'g', PlayerColor.green, const BoardPosition.base(slot: 3)),
        _token('yellow_0', 'y', PlayerColor.yellow, const BoardPosition.track(5)),
        _token('yellow_1', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 1)),
        _token('yellow_2', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 2)),
        _token('yellow_3', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 3)),
      ];
      state = state.copyWith(
        tokens: tokens,
        diceValue: 1,
        diceRolled: true,
        phase: TurnPhase.waitingForMove,
        validMoves: GameRules.validMoves(
          state.copyWith(
            tokens: tokens,
            diceValue: 1,
            diceRolled: true,
            phase: TurnPhase.waitingForMove,
          ),
        ),
      );
      expect(state.validMoves, contains('green_0'));
      state = engine.moveToken(state, 'g', 'green_0').state;
      expect(state.tokenById('yellow_0').state, TokenLogicalState.base);
      expect(state.currentPlayerId, 'g');
    });

    test('safe square does not capture', () {
      final engine = _engine([1]);
      var state = _started(engine);
      const safe = BoardPosition.track(8);
      final tokens = [
        _token('green_0', 'g', PlayerColor.green, const BoardPosition.track(7)),
        _token('green_1', 'g', PlayerColor.green, const BoardPosition.base(slot: 1)),
        _token('green_2', 'g', PlayerColor.green, const BoardPosition.base(slot: 2)),
        _token('green_3', 'g', PlayerColor.green, const BoardPosition.base(slot: 3)),
        _token('yellow_0', 'y', PlayerColor.yellow, safe),
        _token('yellow_1', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 1)),
        _token('yellow_2', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 2)),
        _token('yellow_3', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 3)),
      ];
      state = state.copyWith(
        tokens: tokens,
        diceValue: 1,
        diceRolled: true,
        phase: TurnPhase.waitingForMove,
        validMoves: const ['green_0'],
      );
      state = engine.moveToken(state, 'g', 'green_0').state;
      expect(state.tokenById('yellow_0').position, safe);
      expect(state.tokenById('yellow_0').state, TokenLogicalState.active);
    });

    test('same-color stack is allowed', () {
      final engine = _engine([1]);
      var state = _started(engine);
      final tokens = [
        _token('green_0', 'g', PlayerColor.green, const BoardPosition.track(2)),
        _token('green_1', 'g', PlayerColor.green, const BoardPosition.track(3)),
        _token('green_2', 'g', PlayerColor.green, const BoardPosition.base(slot: 2)),
        _token('green_3', 'g', PlayerColor.green, const BoardPosition.base(slot: 3)),
        _token('yellow_0', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 0)),
        _token('yellow_1', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 1)),
        _token('yellow_2', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 2)),
        _token('yellow_3', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 3)),
      ];
      state = state.copyWith(
        tokens: tokens,
        diceValue: 1,
        diceRolled: true,
        phase: TurnPhase.waitingForMove,
        validMoves: const ['green_0'],
      );
      state = engine.moveToken(state, 'g', 'green_0').state;
      expect(state.tokenById('green_0').position, const BoardPosition.track(3));
      expect(state.tokenById('green_1').position, const BoardPosition.track(3));
    });
  });

  group('home and winner', () {
    test('token reaching home and all four wins', () {
      final engine = _engine([1]);
      var state = _started(engine);
      final tokens = [
        _token('green_0', 'g', PlayerColor.green, const BoardPosition.homePath(4)),
        _token('green_1', 'g', PlayerColor.green, const BoardPosition.home()),
        _token('green_2', 'g', PlayerColor.green, const BoardPosition.home()),
        _token('green_3', 'g', PlayerColor.green, const BoardPosition.home()),
        _token('yellow_0', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 0)),
        _token('yellow_1', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 1)),
        _token('yellow_2', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 2)),
        _token('yellow_3', 'y', PlayerColor.yellow, const BoardPosition.base(slot: 3)),
      ];
      state = state.copyWith(
        tokens: tokens,
        diceValue: 1,
        diceRolled: true,
        phase: TurnPhase.waitingForMove,
        validMoves: const ['green_0'],
      );
      final result = engine.moveToken(state, 'g', 'green_0');
      expect(result.state.winnerId, 'g');
      expect(result.state.status, GameStatus.finished);
      expect(result.events.whereType<PlayerWonEvent>(), isNotEmpty);
    });

    test('start without enough players fails', () {
      final engine = _engine([]);
      final state = GameState.lobby(
        gameId: 'g',
        host: _player(id: 'g', color: PlayerColor.green, host: true),
      );
      expect(() => engine.startGame(state), throwsA(isA<GameException>()));
    });
  });

  group('board constants', () {
    test('track has 52 cells and starts 13 apart', () {
      expect(BoardConstants.trackCells, hasLength(52));
      expect(BoardConstants.startIndex[PlayerColor.green], 0);
      expect(BoardConstants.startIndex[PlayerColor.red], 13);
      expect(BoardConstants.startIndex[PlayerColor.blue], 26);
      expect(BoardConstants.startIndex[PlayerColor.yellow], 39);
    });
  });
}
