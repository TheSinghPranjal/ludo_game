import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/domain/models/board_position.dart';
import 'package:ludo_game/networking/protocol/messages.dart';

void main() {
  test('client ROLL_DICE round-trips and never carries a value', () {
    final message = RollDiceMessage(commandId: 'c1');
    final parsed = ClientMessage.tryParse(
      jsonDecode(jsonEncode(message.toJson())),
    );
    expect(parsed, isA<RollDiceMessage>());
    expect(message.toJson().containsKey('value'), isFalse);
  });

  test('fabricated client dice is classified as fabricated', () {
    final parsed = ClientMessage.tryParse({
      'type': 'DICE_RESULT',
      'commandId': 'x',
      'value': 6,
    });
    expect(parsed, isA<FabricatedClientMessage>());
  });

  test('malformed payload returns null instead of throwing', () {
    expect(ClientMessage.tryParse('nope'), isNull);
    expect(ServerMessage.tryParse({'type': 'NOT_A_THING'}), isNull);
    expect(ClientMessage.tryParse({'type': 'MOVE_TOKEN'}), isNull);
  });

  test('TURN_TIMER_UPDATE and TURN_AUTO_PLAYED round-trip', () {
    final timer = TurnTimerUpdateMessage(secondsRemaining: 17, turnId: 't9');
    final parsedTimer = ServerMessage.tryParse(
      jsonDecode(jsonEncode(timer.toJson())),
    );
    expect(parsedTimer, isA<TurnTimerUpdateMessage>());
    expect((parsedTimer as TurnTimerUpdateMessage).secondsRemaining, 17);

    final auto = TurnAutoPlayedMessage(
      playerId: 'p',
      tokenId: 'green_0',
      game: const {
        'gameId': 'g',
        'status': 'active',
        'players': [],
        'tokens': [],
        'turnNumber': 1,
        'diceRolled': true,
        'consecutiveSixes': 0,
        'validMoves': [],
        'revision': 3,
        'turnId': 't9',
        'phase': 'waitingForRoll',
        'aiEnabled': false,
        'forfeitedSixes': false,
        'finishedOrder': [],
      },
    );
    final parsedAuto = ServerMessage.tryParse(
      jsonDecode(jsonEncode(auto.toJson())),
    );
    expect(parsedAuto, isA<TurnAutoPlayedMessage>());
  });

  test('DICE_RESULT and TOKEN_MOVED round-trip', () {
    final dice = DiceResultMessage(
      playerId: 'p',
      value: 6,
      turnId: 't',
      forfeited: false,
      game: {
        'gameId': 'g',
        'status': 'active',
        'players': [],
        'tokens': [],
        'turnNumber': 1,
        'diceRolled': true,
        'consecutiveSixes': 1,
        'validMoves': [],
        'revision': 2,
        'turnId': 't',
        'phase': 'waitingForMove',
        'aiEnabled': false,
        'forfeitedSixes': false,
        'finishedOrder': [],
      },
    );
    final parsed = ServerMessage.tryParse(
      jsonDecode(jsonEncode(dice.toJson())),
    );
    expect(parsed, isA<DiceResultMessage>());
    expect((parsed as DiceResultMessage).value, 6);

    final moved = TokenMovedMessage(
      tokenId: 'green_0',
      from: const BoardPosition.base(slot: 0),
      to: const BoardPosition.track(0),
      path: const [BoardPosition.track(0)],
      game: dice.game,
    );
    final movedParsed = ServerMessage.tryParse(
      jsonDecode(jsonEncode(moved.toJson())),
    );
    expect(movedParsed, isA<TokenMovedMessage>());
  });
}
