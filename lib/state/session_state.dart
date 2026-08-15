import '../../domain/models/game_state.dart';
import '../../networking/protocol/messages.dart';

enum SessionRole { none, host, client }

enum ConnectionStatus { idle, hosting, connecting, connected, error }

class SessionState {
  const SessionState({
    this.role = SessionRole.none,
    this.connection = ConnectionStatus.idle,
    this.game,
    this.localPlayerId,
    this.reconnectToken,
    this.playerName = 'Player',
    this.hostIps = const [],
    this.connectedHost,
    this.error,
    this.lastEvent,
    this.hostDisconnected = false,
  });

  final SessionRole role;
  final ConnectionStatus connection;
  final GameState? game;
  final String? localPlayerId;
  final String? reconnectToken;
  final String playerName;
  final List<String> hostIps;
  final String? connectedHost;
  final String? error;
  final ServerMessage? lastEvent;
  final bool hostDisconnected;

  bool get isHost => role == SessionRole.host;
  bool get isClient => role == SessionRole.client;

  SessionState copyWith({
    SessionRole? role,
    ConnectionStatus? connection,
    GameState? game,
    bool clearGame = false,
    String? localPlayerId,
    String? reconnectToken,
    String? playerName,
    List<String>? hostIps,
    String? connectedHost,
    String? error,
    bool clearError = false,
    ServerMessage? lastEvent,
    bool? hostDisconnected,
  }) {
    return SessionState(
      role: role ?? this.role,
      connection: connection ?? this.connection,
      game: clearGame ? null : (game ?? this.game),
      localPlayerId: localPlayerId ?? this.localPlayerId,
      reconnectToken: reconnectToken ?? this.reconnectToken,
      playerName: playerName ?? this.playerName,
      hostIps: hostIps ?? this.hostIps,
      connectedHost: connectedHost ?? this.connectedHost,
      error: clearError ? null : (error ?? this.error),
      lastEvent: lastEvent ?? this.lastEvent,
      hostDisconnected: hostDisconnected ?? this.hostDisconnected,
    );
  }
}

class DiceUiState {
  const DiceUiState({
    this.face = 1,
    this.rolling = false,
    this.enabled = false,
  });

  final int face;
  final bool rolling;
  final bool enabled;
}

class CurrentTurnView {
  const CurrentTurnView({
    required this.playerId,
    required this.isLocal,
    required this.label,
  });

  final String? playerId;
  final bool isLocal;
  final String label;
}
