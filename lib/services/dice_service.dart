import 'dart:math';

/// Host-only dice. Clients must never instantiate this for gameplay.
abstract interface class DiceService {
  int secureRoll();
}

class SecureDiceService implements DiceService {
  const SecureDiceService();

  @override
  int secureRoll() => Random.secure().nextInt(6) + 1;
}

/// Test double. Never used in production gameplay.
class ScriptedDiceService implements DiceService {
  ScriptedDiceService(this._values);

  final List<int> _values;
  var _index = 0;

  @override
  int secureRoll() {
    if (_index >= _values.length) {
      throw StateError('ScriptedDiceService exhausted');
    }
    return _values[_index++];
  }
}
