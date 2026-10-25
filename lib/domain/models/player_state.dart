import 'player_color.dart';

class PlayerState {
  const PlayerState({
    required this.playerId,
    required this.name,
    required this.color,
    required this.isReady,
    required this.isConnected,
    required this.isHost,
    required this.isAi,
    required this.reconnectToken,
    this.rank,
  });

  final String playerId;
  final String name;
  final PlayerColor color;
  final bool isReady;
  final bool isConnected;
  final bool isHost;
  final bool isAi;
  final String reconnectToken;
  final int? rank;

  PlayerState copyWith({
    String? name,
    PlayerColor? color,
    bool? isReady,
    bool? isConnected,
    bool? isHost,
    bool? isAi,
    String? reconnectToken,
    int? rank,
    bool clearRank = false,
  }) {
    return PlayerState(
      playerId: playerId,
      name: name ?? this.name,
      color: color ?? this.color,
      isReady: isReady ?? this.isReady,
      isConnected: isConnected ?? this.isConnected,
      isHost: isHost ?? this.isHost,
      isAi: isAi ?? this.isAi,
      reconnectToken: reconnectToken ?? this.reconnectToken,
      rank: clearRank ? null : (rank ?? this.rank),
    );
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'name': name,
    'color': color.name,
    'isReady': isReady,
    'isConnected': isConnected,
    'isHost': isHost,
    'isAi': isAi,
    'reconnectToken': reconnectToken,
    'rank': rank,
  };

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    return PlayerState(
      playerId: json['playerId'] as String,
      name: json['name'] as String,
      color: PlayerColor.fromId(json['color'] as String),
      isReady: json['isReady'] as bool? ?? false,
      isConnected: json['isConnected'] as bool? ?? true,
      isHost: json['isHost'] as bool? ?? false,
      isAi: json['isAi'] as bool? ?? false,
      reconnectToken: json['reconnectToken'] as String? ?? '',
      rank: json['rank'] as int?,
    );
  }
}
