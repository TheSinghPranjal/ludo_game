import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/core/constants.dart';
import 'package:ludo_game/domain/game_state/local_game_controller.dart';
import 'package:ludo_game/domain/models/game_state.dart';
import 'package:ludo_game/domain/rules/board_map.dart';
import 'package:ludo_game/networking/protocol/messages.dart';
import 'package:ludo_game/services/dice_service.dart';

class _SeededDice implements DiceService {
  _SeededDice(int seed) : _random = Random(seed);
  final Random _random;

  @override
  int secureRoll() => _random.nextInt(6) + 1;
}

List<PlayerState> _players(int count) => [
  for (final (i, color) in BoardConstants.seatColors(count).indexed)
    PlayerState(
      playerId: 'p$i',
      name: 'Player ${i + 1}',
      color: color,
      isReady: true,
      isConnected: true,
      isHost: i == 0,
      isAi: false,
      reconnectToken: '',
    ),
];

void _expectConsistent(GameState state) {
  // No two opponents may rest on the same unsafe track square: the second
  // arrival must have captured the first.
  final byCell = <int, Set<String>>{};
  for (final token in state.tokens) {
    final pos = token.position;
    if (pos is TrackPosition && !BoardMap.isSafe(pos)) {
      byCell.putIfAbsent(pos.index, () => {}).add(token.playerId);
    }
  }
  for (final entry in byCell.entries) {
    if (entry.value.length > 1) {
      final counts = {
        for (final id in entry.value)
          id: state.tokens
              .where(
                (t) =>
                    t.playerId == id && t.position == TrackPosition(entry.key),
              )
              .length,
      };
      // Only a blockade (2+ of one colour) can share with another colour.
      expect(
        counts.values.where((c) => c == 1).length <= 1,
        isTrue,
        reason: 'uncaptured opponents on track ${entry.key}: $counts',
      );
    }
  }
  for (final token in state.tokens) {
    final isHome = token.position is HomePosition;
    expect(token.state == TokenLogicalState.home, isHome);
  }
}

void main() {
  for (final count in [2, 3, 4]) {
    test('$count-player pass-and-play games always reach a winner', () {
      for (var seed = 0; seed < 25; seed++) {
        final messages = <ServerMessage>[];
        final controller = LocalGameController(
          onMessage: messages.add,
          diceService: _SeededDice(seed * 31 + count),
        );
        final pick = Random(seed);
        controller.start(players: _players(count));
        var steps = 0;
        while (controller.state!.status == GameStatus.active) {
          final state = controller.state!;
          final current = state.currentPlayerId!;
          if (state.canRoll) {
            controller.rollDice(current);
          } else {
            expect(state.canMove, isTrue);
            final moves = state.validMoves;
            controller.moveToken(current, moves[pick.nextInt(moves.length)]);
          }
          _expectConsistent(controller.state!);
          expect(++steps, lessThan(20000), reason: 'game did not finish');
        }
        final done = controller.state!;
        expect(messages.whereType<ErrorMessage>(), isEmpty);
        expect(done.winnerId, isNotNull);
        expect(
          done
              .tokensFor(done.winnerId!)
              .every((t) => t.position is HomePosition),
          isTrue,
        );
        expect(done.finishedOrder.toSet(), hasLength(count));
        expect(done.players.map((p) => p.rank).toSet(), {
          for (var r = 1; r <= count; r++) r,
        });
        controller.dispose();
      }
    });
  }

  test('2 players are seated opposite each other and green starts', () {
    final controller = LocalGameController(onMessage: (_) {});
    controller.start(players: _players(2));
    final state = controller.state!;
    expect(state.players.map((p) => p.color), [
      PlayerColor.green,
      PlayerColor.blue,
    ]);
    expect(state.currentPlayerId, 'p0');
    controller.dispose();
  });

  test('illegal commands report an error instead of throwing', () {
    final messages = <ServerMessage>[];
    final controller = LocalGameController(
      onMessage: messages.add,
      diceService: ScriptedDiceService([3]),
    );
    controller.start(players: _players(2));
    controller.rollDice('p1');
    controller.moveToken('p0', 'green_0');
    expect(messages.whereType<ErrorMessage>(), hasLength(2));
    expect(controller.state!.currentPlayerId, 'p0');
    controller.dispose();
  });

  testWidgets('a forced single move plays after the dice settles', (
    tester,
  ) async {
    final controller = LocalGameController(
      onMessage: (_) {},
      diceService: ScriptedDiceService([6, 3]),
    );
    controller.start(players: _players(2));
    controller.rollDice('p0');
    controller.moveToken('p0', 'green_0');
    controller.rollDice('p0');
    expect(controller.state!.validMoves, ['green_0']);

    await tester.pump(TimingConstants.diceAnimation);
    expect(
      controller.state!.tokenById('green_0').position,
      const BoardPosition.track(0),
    );

    await tester.pump(TimingConstants.autoMoveDelay);
    expect(
      controller.state!.tokenById('green_0').position,
      const BoardPosition.track(3),
    );
    expect(controller.state!.currentPlayerId, 'p1');
    controller.dispose();
  });

  testWidgets('play again resets the board and ranks', (tester) async {
    final controller = LocalGameController(
      onMessage: (_) {},
      diceService: _SeededDice(7),
    );
    controller.start(players: _players(2));
    var state = controller.state!;
    controller.playAgain();
    state = controller.state!;
    expect(state.status, GameStatus.active);
    expect(state.tokens.every((t) => t.position is BasePosition), isTrue);
    expect(state.players.every((p) => p.rank == null), isTrue);
    controller.dispose();
  });
}
