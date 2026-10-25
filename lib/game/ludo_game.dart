import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../domain/models/game_state.dart';
import '../domain/rules/board_map.dart';
import '../networking/protocol/messages.dart';
import 'board/board_renderer.dart';
import 'board/turn_highlight.dart';
import 'tokens/token_component.dart';

class BoardComponent extends PositionComponent {
  BoardComponent() : super(size: Vector2.all(15), position: Vector2.zero());

  /// Yards with no player in this game; drawn with resting marbles.
  Set<PlayerColor> idleColors = const {};

  @override
  void render(Canvas canvas) {
    // Canonical fixed orientation: green TL, yellow TR, red BL, blue BR.
    // Never rotate / mirror based on player, turn, or network role.
    BoardRenderer.paint(canvas, Size(size.x, size.y), idleColors: idleColors);
  }
}

class LudoFlameGame extends FlameGame {
  LudoFlameGame({required this.onTokenTapped});

  final void Function(String tokenId) onTokenTapped;
  final _tokens = <String, TokenComponent>{};
  String? _localPlayerId;
  GameState? _state;

  /// Token animations run strictly in order, so a capture plays after the
  /// capturing token lands. Tokens with queued animations are never snapped.
  Future<void> _animations = Future.value();
  final _pending = <String, int>{};

  /// True while any token animation is queued or running.
  final busy = ValueNotifier<bool>(false);

  /// Completes once every queued animation has finished.
  Future<void> get settled => _animations;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    // Fixed 15×15 world; no player-relative transforms.
    camera.viewport = MaxViewport();
    camera.viewfinder.visibleGameSize = Vector2(worldWidth, worldHeight);
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2(
      -BoardConstants.frameSide,
      -BoardConstants.frameTop,
    );
    camera.viewfinder.angle = 0;
    world.add(_board);
    world.add(_turnHighlight);
  }

  // Negative priorities keep both under tokens regardless of add order.
  final _board = BoardComponent()..priority = -2;
  final _turnHighlight = TurnHighlightComponent()..priority = -1;

  /// Grid plus wooden frame, in cell units.
  static const worldWidth =
      BoardConstants.gridSize + 2 * BoardConstants.frameSide;
  static const worldHeight =
      BoardConstants.gridSize +
      BoardConstants.frameTop +
      BoardConstants.frameBottom;

  /// Width / height of the widget that shows the board.
  static const aspectRatio = worldWidth / worldHeight;

  void syncState(
    GameState state,
    String? localPlayerId, {
    bool snapIdle = false,
  }) {
    _state = state;
    _localPlayerId = localPlayerId;
    _board.idleColors = {
      for (final color in PlayerColor.values)
        if (state.players.every((p) => p.color != color)) color,
    };
    _turnHighlight.color = state.status == GameStatus.active
        ? state.currentPlayer?.color
        : null;
    final highlight = <String>{};
    if (state.currentPlayerId == localPlayerId) {
      highlight.addAll(state.validMoves);
    }

    for (final token in state.tokens) {
      final color = PlayerColor.fromId(token.colorId);
      final existing = _tokens[token.tokenId];
      if (existing == null) {
        final component = TokenComponent(
          tokenId: token.tokenId,
          color: color,
          slot: token.slot,
          onTapped: _handleTap,
        )..snapTo(token.position);
        _tokens[token.tokenId] = component;
        world.add(component);
      } else {
        existing.highlighted = highlight.contains(token.tokenId);
        existing.priority = existing.highlighted ? 1 : 0;
        if (snapIdle) {
          _snapIfIdle(token.tokenId);
        }
      }
    }

    final live = state.tokens.map((t) => t.tokenId).toSet();
    for (final id in [..._tokens.keys]) {
      if (!live.contains(id)) {
        _tokens.remove(id)?.removeFromParent();
      }
    }
    _relayout();
  }

  /// Fan offsets (cell units) for 2, 3 and 4+ tokens resting on one square.
  static const _fanLayouts = [
    [(-0.17, 0.0), (0.17, 0.0)],
    [(-0.16, -0.12), (0.16, -0.12), (0.0, 0.14)],
    [(-0.15, -0.15), (0.15, -0.15), (-0.15, 0.15), (0.15, 0.15)],
  ];

  /// Centres lone tokens on their square and spreads out tokens that share
  /// one, so each stays visible and tappable. Moving tokens stay centred.
  void _relayout() {
    final groups = <(int, int), List<TokenComponent>>{};
    for (final token in _tokens.values) {
      final pos = token.logical;
      if (pos == null ||
          pos is BasePosition ||
          token.animating ||
          _pending.containsKey(token.tokenId)) {
        token.fanTarget = Vector2.zero();
        continue;
      }
      groups
          .putIfAbsent(BoardMap.cellOf(token.color, pos), () => [])
          .add(token);
    }
    for (final group in groups.values) {
      if (group.length == 1) {
        group.single.fanTarget = Vector2.zero();
        continue;
      }
      group.sort((a, b) => a.tokenId.compareTo(b.tokenId));
      final layout = _fanLayouts[(group.length - 2).clamp(0, 2)];
      for (final (i, token) in group.indexed) {
        final (dx, dy) = layout[i % layout.length];
        token.fanTarget = Vector2(dx, dy);
      }
    }
  }

  Future<void> handleEvent(ServerMessage message) {
    final tokenId = switch (message) {
      TokenMovedMessage(:final tokenId) => tokenId,
      TokenCapturedMessage(:final tokenId) => tokenId,
      _ => null,
    };
    if (tokenId == null) {
      return Future.value();
    }
    _pending.update(tokenId, (n) => n + 1, ifAbsent: () => 1);
    busy.value = true;
    return _animations = _animations.then((_) async {
      try {
        await _animate(message);
      } finally {
        final left = _pending[tokenId]! - 1;
        if (left == 0) {
          _pending.remove(tokenId);
          _snapIfIdle(tokenId);
        } else {
          _pending[tokenId] = left;
        }
        _relayout();
        busy.value = _pending.isNotEmpty;
      }
    });
  }

  Future<void> _animate(ServerMessage message) async {
    switch (message) {
      case TokenMovedMessage(:final tokenId, :final path, :final to):
        final token = _tokens[tokenId];
        if (token == null) {
          return;
        }
        if (path.isEmpty) {
          token.snapTo(to);
        } else {
          await token.travel(path);
        }
      case TokenCapturedMessage(:final tokenId):
        final token = _tokens[tokenId];
        final snapshot = _state?.tokens
            .where((t) => t.tokenId == tokenId)
            .firstOrNull;
        if (token != null && snapshot != null) {
          await token.flyTo(snapshot.position);
        }
      default:
        break;
    }
  }

  /// Puts a token exactly where the latest state says, unless it still has
  /// animations queued.
  void _snapIfIdle(String tokenId) {
    final component = _tokens[tokenId];
    final snapshot = _state?.tokens
        .where((t) => t.tokenId == tokenId)
        .firstOrNull;
    if (component == null ||
        snapshot == null ||
        _pending.containsKey(tokenId) ||
        component.animating ||
        component.logical == snapshot.position) {
      return;
    }
    component.snapTo(snapshot.position);
  }

  void _handleTap(String tokenId) {
    final state = _state;
    if (state == null) {
      return;
    }
    if (state.currentPlayerId != _localPlayerId) {
      return;
    }
    if (state.validMoves.contains(tokenId)) {
      onTokenTapped(tokenId);
      return;
    }
    // Tokens on the same square overlap; a tap on the top one should still
    // reach a movable token underneath it.
    final tapped = state.tokens.where((t) => t.tokenId == tokenId).firstOrNull;
    if (tapped != null) {
      final cell = BoardMap.cellOf(BoardMap.colorOf(tapped), tapped.position);
      for (final candidate in state.tokens) {
        if (state.validMoves.contains(candidate.tokenId) &&
            BoardMap.cellOf(BoardMap.colorOf(candidate), candidate.position) ==
                cell) {
          onTokenTapped(candidate.tokenId);
          return;
        }
      }
    }
    _tokens[tokenId]?.shake();
  }
}
