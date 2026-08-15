import 'board_position.dart';
import 'game_status.dart';

class TokenState {
  const TokenState({
    required this.tokenId,
    required this.playerId,
    required this.colorId,
    required this.slot,
    required this.position,
    required this.state,
  });

  final String tokenId;
  final String playerId;
  final String colorId;
  final int slot;
  final BoardPosition position;
  final TokenLogicalState state;

  TokenState copyWith({
    BoardPosition? position,
    TokenLogicalState? state,
  }) {
    return TokenState(
      tokenId: tokenId,
      playerId: playerId,
      colorId: colorId,
      slot: slot,
      position: position ?? this.position,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        'playerId': playerId,
        'colorId': colorId,
        'slot': slot,
        'position': position.toJson(),
        'state': state.name,
      };

  factory TokenState.fromJson(Map<String, dynamic> json) {
    return TokenState(
      tokenId: json['tokenId'] as String,
      playerId: json['playerId'] as String,
      colorId: json['colorId'] as String,
      slot: json['slot'] as int,
      position: BoardPosition.fromJson(
        Map<String, dynamic>.from(json['position'] as Map),
      ),
      state: TokenLogicalState.values.byName(json['state'] as String),
    );
  }
}
