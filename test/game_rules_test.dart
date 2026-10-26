import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/core/constants.dart';
import 'package:ludo_game/domain/game_state/game_engine.dart';
import 'package:ludo_game/domain/models/game_state.dart';
import 'package:ludo_game/domain/rules/board_map.dart';
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
      expect(
        after.tokensFor('g').every((t) => t.state == TokenLogicalState.base),
        isTrue,
      );
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
      expect(() => engine.rollDice(state, 'y'), throwsA(isA<GameException>()));
    });

    test('client cannot fabricate dice or positions', () {
      final engine = _engine([1]);
      final state = _started(engine);
      expect(
        () => engine.rejectFabricatedDice(state),
        throwsA(isA<GameException>()),
      );
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
      expect(() => engine.rollDice(state, 'g'), throwsA(isA<GameException>()));
    });
  });

  group('capture and safe squares', () {
    test('landing on a single opponent captures', () {
      final engine = _engine([1]);
      var state = _started(engine);
      final tokens = [
        _token('green_0', 'g', PlayerColor.green, const BoardPosition.track(4)),
        _token(
          'green_1',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 1),
        ),
        _token(
          'green_2',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 2),
        ),
        _token(
          'green_3',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 3),
        ),
        _token(
          'yellow_0',
          'y',
          PlayerColor.yellow,
          const BoardPosition.track(5),
        ),
        _token(
          'yellow_1',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 1),
        ),
        _token(
          'yellow_2',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 2),
        ),
        _token(
          'yellow_3',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 3),
        ),
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
        _token(
          'green_1',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 1),
        ),
        _token(
          'green_2',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 2),
        ),
        _token(
          'green_3',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 3),
        ),
        _token('yellow_0', 'y', PlayerColor.yellow, safe),
        _token(
          'yellow_1',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 1),
        ),
        _token(
          'yellow_2',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 2),
        ),
        _token(
          'yellow_3',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 3),
        ),
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
        _token(
          'green_2',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 2),
        ),
        _token(
          'green_3',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 3),
        ),
        _token(
          'yellow_0',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 0),
        ),
        _token(
          'yellow_1',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 1),
        ),
        _token(
          'yellow_2',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 2),
        ),
        _token(
          'yellow_3',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 3),
        ),
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

  group('home path', () {
    test('tokens on different colors\' home columns never interact', () {
      final engine = _engine([1]);
      var state = _started(engine);
      final tokens = [
        _token(
          'green_0',
          'g',
          PlayerColor.green,
          const BoardPosition.homePath(1),
        ),
        _token(
          'green_1',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 1),
        ),
        _token(
          'green_2',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 2),
        ),
        _token(
          'green_3',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 3),
        ),
        _token(
          'yellow_0',
          'y',
          PlayerColor.yellow,
          const BoardPosition.homePath(2),
        ),
        _token(
          'yellow_1',
          'y',
          PlayerColor.yellow,
          const BoardPosition.homePath(2),
        ),
        _token(
          'yellow_2',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 2),
        ),
        _token(
          'yellow_3',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 3),
        ),
      ];
      state = state.copyWith(
        tokens: tokens,
        diceValue: 1,
        diceRolled: true,
        phase: TurnPhase.waitingForMove,
      );
      // Yellow's pair on its own column must not block green's column.
      expect(GameRules.validMoves(state), ['green_0']);
      state = state.copyWith(validMoves: const ['green_0']);
      state = engine.moveToken(state, 'g', 'green_0').state;
      expect(
        state.tokenById('green_0').position,
        const BoardPosition.homePath(2),
      );
      expect(
        state.tokenById('yellow_0').position,
        const BoardPosition.homePath(2),
      );
      expect(
        state.tokenById('yellow_1').position,
        const BoardPosition.homePath(2),
      );
    });
  });

  group('home and winner', () {
    test('token reaching home and all four wins', () {
      final engine = _engine([1]);
      var state = _started(engine);
      final tokens = [
        _token(
          'green_0',
          'g',
          PlayerColor.green,
          const BoardPosition.homePath(4),
        ),
        _token('green_1', 'g', PlayerColor.green, const BoardPosition.home()),
        _token('green_2', 'g', PlayerColor.green, const BoardPosition.home()),
        _token('green_3', 'g', PlayerColor.green, const BoardPosition.home()),
        _token(
          'yellow_0',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 0),
        ),
        _token(
          'yellow_1',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 1),
        ),
        _token(
          'yellow_2',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 2),
        ),
        _token(
          'yellow_3',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 3),
        ),
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
      expect(result.state.finishedOrder, ['g', 'y']);
      expect(result.state.playerById('g')!.rank, 1);
      expect(result.state.playerById('y')!.rank, 2);
      expect(result.state.status, GameStatus.finished);
      expect(result.events.whereType<PlayerWonEvent>(), isNotEmpty);
    });

    GameState homeRun(GameEngine engine, BoardPosition from) {
      final state = _started(engine);
      return state.copyWith(
        tokens: [
          _token('green_0', 'g', PlayerColor.green, from),
          for (var i = 1; i < 4; i++)
            _token(
              'green_$i',
              'g',
              PlayerColor.green,
              BoardPosition.base(slot: i),
            ),
          for (var i = 0; i < 4; i++)
            _token(
              'yellow_$i',
              'y',
              PlayerColor.yellow,
              BoardPosition.base(slot: i),
            ),
        ],
        diceValue: 1,
        diceRolled: true,
        phase: TurnPhase.waitingForMove,
        validMoves: const ['green_0'],
      );
    }

    test('token reaching home (not the last) grants an extra turn', () {
      final engine = _engine([1]);
      final result = engine.moveToken(
        homeRun(engine, const BoardPosition.homePath(4)),
        'g',
        'green_0',
      );
      expect(result.state.status, GameStatus.active);
      expect(result.state.currentPlayerId, 'g');
      expect(result.state.canRoll, isTrue);
      expect(result.events.whereType<TurnChangedEvent>().single.reason, 'home');
    });

    test('a move that stops short of home passes the turn', () {
      final engine = _engine([1]);
      final result = engine.moveToken(
        homeRun(engine, const BoardPosition.homePath(3)),
        'g',
        'green_0',
      );
      expect(result.state.currentPlayerId, 'y');
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
      expect(BoardConstants.startIndex[PlayerColor.yellow], 13);
      expect(BoardConstants.startIndex[PlayerColor.blue], 26);
      expect(BoardConstants.startIndex[PlayerColor.red], 39);
    });

    test('track is a closed loop of adjacent cells', () {
      final cells = BoardConstants.trackCells;
      expect(cells.toSet(), hasLength(cells.length));
      for (var i = 0; i < cells.length; i++) {
        final a = cells[i];
        final b = cells[(i + 1) % cells.length];
        final dist = (a.$1 - b.$1).abs() + (a.$2 - b.$2).abs();
        expect(dist <= 2 && a != b, isTrue, reason: 'gap at track $i');
      }
    });

    test(
      'each color starts beside its own yard and walks home in 57 steps',
      () {
        for (final color in PlayerColor.values) {
          final (yc, yr) = BoardConstants.yardOrigin[color]!;
          final (sc, sr) =
              BoardConstants.trackCells[BoardMap.startIndex(color)];
          final besideYard =
              (sc >= yc - 1 && sc <= yc + 6) && (sr >= yr - 1 && sr <= yr + 6);
          expect(besideYard, isTrue, reason: '$color start not by its yard');

          final path = BoardMap.walk(
            color: color,
            from: const BoardPosition.base(slot: 0),
            to: BoardPosition.track(BoardMap.startIndex(color)),
          );
          expect(path, hasLength(1));
          final lap = BoardMap.walk(
            color: color,
            from: BoardPosition.track(BoardMap.startIndex(color)),
            to: const BoardPosition.home(),
          );
          expect(lap, hasLength(56));
          // The home column continues straight on from the approach square.
          final approach =
              BoardConstants.trackCells[BoardMap.approachIndex(color)];
          final firstHome = BoardConstants.homePathCells[color]!.first;
          expect(
            (approach.$1 - firstHome.$1).abs() +
                (approach.$2 - firstHome.$2).abs(),
            1,
          );
        }
      },
    );

    test('turn order goes clockwise around the yards', () {
      expect(BoardConstants.turnOrder, [
        PlayerColor.green,
        PlayerColor.yellow,
        PlayerColor.blue,
        PlayerColor.red,
      ]);
      expect(BoardConstants.seatColors(2), [
        PlayerColor.green,
        PlayerColor.blue,
      ]);
    });
  });

  group('turn timer auto-play', () {
    test('timer starts at 30 and extra turns reset it', () {
      final engine = _engine([6]);
      var state = _started(engine);
      expect(state.turnTimerSecondsRemaining, 30);
      state = engine.tickTimer(state);
      expect(state.turnTimerSecondsRemaining, 29);
      state = engine.rollDice(state, 'g').state;
      state = engine.moveToken(state, 'g', 'green_0').state;
      expect(state.currentPlayerId, 'g');
      expect(state.turnTimerSecondsRemaining, 30);
    });

    test('timeout with 1-5 and all in base passes the turn', () {
      final engine = _engine([2]);
      var state = _started(engine);
      final result = engine.expireTurn(state);
      expect(result.state.currentPlayerId, 'y');
      expect(
        result.state
            .tokensFor('g')
            .every((t) => t.state == TokenLogicalState.base),
        isTrue,
      );
      expect(result.events.whereType<TurnAutoPlayedEvent>(), isNotEmpty);
    });

    test('timeout with 6 enters a token from base', () {
      final engine = _engine([6]);
      var state = _started(engine);
      final result = engine.expireTurn(state);
      expect(
        result.state.tokenById('green_0').position,
        const BoardPosition.track(0),
      );
      expect(result.events.whereType<DiceRolledEvent>().single.value, 6);
      expect(
        result.events.whereType<TurnAutoPlayedEvent>().single.tokenId,
        isNotNull,
      );
    });

    test('pickAutoMove prefers capture over leaving base', () {
      final engine = _engine([6]);
      var state = _started(engine);
      final tokens = [
        _token('green_0', 'g', PlayerColor.green, const BoardPosition.track(0)),
        _token(
          'green_1',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 1),
        ),
        _token(
          'green_2',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 2),
        ),
        _token(
          'green_3',
          'g',
          PlayerColor.green,
          const BoardPosition.base(slot: 3),
        ),
        _token(
          'yellow_0',
          'y',
          PlayerColor.yellow,
          const BoardPosition.track(6),
        ),
        _token(
          'yellow_1',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 1),
        ),
        _token(
          'yellow_2',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 2),
        ),
        _token(
          'yellow_3',
          'y',
          PlayerColor.yellow,
          const BoardPosition.base(slot: 3),
        ),
      ];
      state = state.copyWith(
        tokens: tokens,
        diceValue: 6,
        diceRolled: true,
        phase: TurnPhase.waitingForMove,
        validMoves: const ['green_0', 'green_1'],
      );
      expect(GameRules.pickAutoMove(state), 'green_0');
      final expired = engine.expireTurn(state);
      expect(expired.state.tokenById('yellow_0').state, TokenLogicalState.base);
    });
  });
}
