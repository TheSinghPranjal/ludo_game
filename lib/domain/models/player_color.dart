enum PlayerColor {
  green,
  yellow,
  red,
  blue;

  String get displayName => switch (this) {
    PlayerColor.green => 'Green',
    PlayerColor.yellow => 'Yellow',
    PlayerColor.red => 'Red',
    PlayerColor.blue => 'Blue',
  };

  String get id => name;

  static PlayerColor fromId(String id) =>
      PlayerColor.values.firstWhere((c) => c.name == id);
}
