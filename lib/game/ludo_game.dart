import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../domain/models/game_state.dart';
import '../networking/protocol/messages.dart';
import 'board/board_renderer.dart';
import 'tokens/token_component.dart';

class BoardComponent extends PositionComponent {
  BoardComponent() : super(size: Vector2.all(15), position: Vector2.zero());

  @override
  void render(Canvas canvas) {
    BoardRenderer.paint(canvas, Size(size.x, size.y));
  }
}

class LudoFlameGame extends FlameGame {
  LudoFlameGame({required this.onTokenTapped});

  final void Function(String tokenId) onTokenTapped;
  final _tokens = <String, TokenComponent>{};
  String? _localPlayerId;
  GameState? _state;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.visibleGameSize = Vector2.all(15);
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
    world.add(BoardComponent());
  }

  void syncState(GameState state, String? localPlayerId, {bool snapIdle = false}) {
    _state = state;
    _localPlayerId = localPlayerId;
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
        if (!existing.animating &&
            existing.logical != token.position &&
            snapIdle) {
          existing.snapTo(token.position);
        }
      }
    }

    final live = state.tokens.map((t) => t.tokenId).toSet();
    for (final id in [..._tokens.keys]) {
      if (!live.contains(id)) {
        _tokens.remove(id)?.removeFromParent();
      }
    }
  }

  Future<void> handleEvent(ServerMessage message) async {
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

  void _handleTap(String tokenId) {
    final state = _state;
    if (state == null) {
      return;
    }
    if (state.currentPlayerId != _localPlayerId) {
      return;
    }
    if (!state.validMoves.contains(tokenId)) {
      _tokens[tokenId]?.shake();
      return;
    }
    onTokenTapped(tokenId);
  }
}
