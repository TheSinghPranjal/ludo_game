sealed class BoardPosition {
  const BoardPosition();

  const factory BoardPosition.base({required int slot}) = BasePosition;
  const factory BoardPosition.track(int index) = TrackPosition;
  const factory BoardPosition.homePath(int index) = HomePathPosition;
  const factory BoardPosition.home() = HomePosition;

  Map<String, dynamic> toJson();

  factory BoardPosition.fromJson(Map<String, dynamic> json) {
    switch (json['kind'] as String?) {
      case 'base':
        return BoardPosition.base(slot: json['slot'] as int);
      case 'track':
        return BoardPosition.track(json['index'] as int);
      case 'homePath':
        return BoardPosition.homePath(json['index'] as int);
      case 'home':
        return const BoardPosition.home();
      default:
        throw FormatException('Unknown BoardPosition: $json');
    }
  }
}

class BasePosition extends BoardPosition {
  const BasePosition({required this.slot});

  final int slot;

  @override
  Map<String, dynamic> toJson() => {'kind': 'base', 'slot': slot};

  @override
  bool operator ==(Object other) => other is BasePosition && other.slot == slot;

  @override
  int get hashCode => Object.hash('base', slot);

  @override
  String toString() => 'BASE($slot)';
}

class TrackPosition extends BoardPosition {
  const TrackPosition(this.index);

  final int index;

  @override
  Map<String, dynamic> toJson() => {'kind': 'track', 'index': index};

  @override
  bool operator ==(Object other) =>
      other is TrackPosition && other.index == index;

  @override
  int get hashCode => Object.hash('track', index);

  @override
  String toString() => 'TRACK($index)';
}

class HomePathPosition extends BoardPosition {
  const HomePathPosition(this.index);

  final int index;

  @override
  Map<String, dynamic> toJson() => {'kind': 'homePath', 'index': index};

  @override
  bool operator ==(Object other) =>
      other is HomePathPosition && other.index == index;

  @override
  int get hashCode => Object.hash('homePath', index);

  @override
  String toString() => 'HOME_PATH($index)';
}

class HomePosition extends BoardPosition {
  const HomePosition();

  @override
  Map<String, dynamic> toJson() => {'kind': 'home'};

  @override
  bool operator ==(Object other) => other is HomePosition;

  @override
  int get hashCode => 'home'.hashCode;

  @override
  String toString() => 'HOME';
}
