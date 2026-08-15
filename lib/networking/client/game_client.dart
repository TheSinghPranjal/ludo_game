import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants.dart';
import '../../core/debug_log.dart';
import '../../domain/models/game_status.dart';
import '../network_info.dart';
import '../protocol/messages.dart';

class GameClient {
  GameClient({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _heartbeat;
  final _controller = StreamController<ServerMessage>.broadcast();
  var _closed = false;

  Stream<ServerMessage> get messages => _controller.stream;
  bool get isConnected => _channel != null && !_closed;

  Future<void> connect(HostAddress address) async {
    await disconnect();
    _closed = false;
    try {
      final channel = WebSocketChannel.connect(address.websocketUri);
      _channel = channel;
      await channel.ready.timeout(const Duration(seconds: 8));
      _sub = channel.stream.listen(
        _onData,
        onError: (_) => _onLost(),
        onDone: _onLost,
      );
      _heartbeat = Timer.periodic(NetworkConstants.heartbeatInterval, (_) {
        send(PingMessage(commandId: _uuid.v4(), nonce: _uuid.v4()));
      });
    } on TimeoutException {
      await disconnect();
      throw GameException(GameErrorCode.timeout, 'Connection timed out');
    } catch (_) {
      await disconnect();
      throw GameException(
        GameErrorCode.connectionRefused,
        'Could not connect to ${address.display}',
      );
    }
  }

  void send(ClientMessage message) {
    if (_channel == null) {
      return;
    }
    try {
      _channel!.sink.add(jsonEncode(message.toJson()));
    } catch (_) {
      _onLost();
    }
  }

  void join({
    required String name,
    String? playerId,
    String? reconnectToken,
  }) {
    send(
      JoinGameMessage(
        commandId: _uuid.v4(),
        name: name,
        playerId: playerId,
        reconnectToken: reconnectToken,
      ),
    );
  }

  void ready(bool value) =>
      send(ReadyMessage(commandId: _uuid.v4(), ready: value));

  void claimColor(String color) =>
      send(ClaimColorMessage(commandId: _uuid.v4(), color: color));

  void startGame() => send(StartGameMessage(commandId: _uuid.v4()));

  void rollDice() => send(RollDiceMessage(commandId: _uuid.v4()));

  void moveToken(String tokenId) =>
      send(MoveTokenMessage(commandId: _uuid.v4(), tokenId: tokenId));

  void requestState() => send(RequestStateMessage(commandId: _uuid.v4()));

  void leave() => send(LeaveGameMessage(commandId: _uuid.v4()));

  void setAiEnabled(bool enabled) =>
      send(SetAiEnabledMessage(commandId: _uuid.v4(), enabled: enabled));

  Future<void> disconnect() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _onData(dynamic raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      final message = ServerMessage.tryParse(decoded);
      if (message == null) {
        debugLog('MALFORMED_SERVER_MESSAGE');
        return;
      }
      if (message is ServerPingMessage) {
        send(ClientPongMessage(commandId: _uuid.v4(), nonce: message.nonce));
      }
      _controller.add(message);
    } catch (_) {
      debugLog('MALFORMED_SERVER_MESSAGE');
    }
  }

  void _onLost() {
    if (_closed) {
      return;
    }
    _closed = true;
    _controller.add(const HostDisconnectedMessage());
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }
}
