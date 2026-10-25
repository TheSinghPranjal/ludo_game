/// Centralized constants. No magic numbers elsewhere.
library;

import 'package:flutter/material.dart';

import '../domain/models/player_color.dart';

abstract final class AppColors {
  static const background = Color(0xFF071428);
  static const backgroundDeep = Color(0xFF040C18);
  static const gridLine = Color(0xFF123056);
  static const gold = Color(0xFFFFD54F);
  static const goldDeep = Color(0xFFF9A825);
  static const goldRim = Color(0xFFFFE082);
  static const boardWhite = Color(0xFFFFFDF8);
  static const boardWhiteAlt = Color(0xFFF4F0E6);
  static const cellBorder = Color(0xFF1A1A1A);
  static const cellInnerHighlight = Color(0x66FFFFFF);
  static const logoFillStart = Color(0xFFFFE566);
  static const logoFillEnd = Color(0xFFFF8F00);
  static const logoStroke = Color(0xFF6A1B9A);
  static const buttonYellow = Color(0xFFFFC107);
  static const buttonYellowDark = Color(0xFFFFA000);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFFB0BEC5);
  static const card = Color(0xE61A2744);
  static const diceBlue = Color(0xFF1E88E5);
  static const diceBlueDark = Color(0xFF1565C0);
  static const glow = Color(0x66FFD54F);

  static const green = Color(0xFF2DB845);
  static const greenDeep = Color(0xFF178A30);
  static const yellow = Color(0xFFFFC61A);
  static const yellowDeep = Color(0xFFF09A00);
  static const red = Color(0xFFF23B2E);
  static const redDeep = Color(0xFFC41F17);
  static const blue = Color(0xFF2B86F2);
  static const blueDeep = Color(0xFF1159CC);

  // Game-screen chrome.
  static const navyPanel = Color(0xE60B1E4A);
  static const navyBorder = Color(0xFF2F6FE6);
  static const buttonText = Color(0xFF4A2A06);
  static const playingText = Color(0xFFE3E86C);
  static const subtleText = Color(0xFFC3D2EC);

  static Color of(PlayerColor color) => switch (color) {
    PlayerColor.green => green,
    PlayerColor.yellow => yellow,
    PlayerColor.red => red,
    PlayerColor.blue => blue,
  };

  static Color deepOf(PlayerColor color) => switch (color) {
    PlayerColor.green => greenDeep,
    PlayerColor.yellow => yellowDeep,
    PlayerColor.red => redDeep,
    PlayerColor.blue => blueDeep,
  };
}

abstract final class BoardConstants {
  static const gridSize = 15;
  static const trackLength = 52;
  static const homePathLength = 5;
  static const tokensPerPlayer = 4;
  static const maxPlayers = 4;
  static const minPlayers = 2;

  /// Track index where each color enters from BASE. Each start square sits
  /// beside its own yard; tokens travel clockwise.
  static const startIndex = {
    PlayerColor.green: 0,
    PlayerColor.yellow: 13,
    PlayerColor.blue: 26,
    PlayerColor.red: 39,
  };

  /// Shared-track index immediately before that color's home path.
  static const approachIndex = {
    PlayerColor.green: 50,
    PlayerColor.yellow: 11,
    PlayerColor.blue: 24,
    PlayerColor.red: 37,
  };

  /// Start squares plus classic star squares.
  static const safeTrackIndices = {0, 8, 13, 21, 26, 34, 39, 47};

  static const starTrackIndices = {8, 21, 34, 47};

  /// Clockwise turn order matching the yards (green TL → yellow TR →
  /// blue BR → red BL).
  static const turnOrder = [
    PlayerColor.green,
    PlayerColor.yellow,
    PlayerColor.blue,
    PlayerColor.red,
  ];

  /// Colors used for an N-player game, so 2 players sit opposite each other.
  static List<PlayerColor> seatColors(int count) => switch (count) {
    2 => const [PlayerColor.green, PlayerColor.blue],
    3 => const [PlayerColor.green, PlayerColor.yellow, PlayerColor.blue],
    _ => turnOrder,
  };

  /// Main-track cells as (col, row) with (0,0) at top-left, clockwise.
  /// Index 0 = green start, beside the top-left yard.
  static const trackCells = <(int, int)>[
    (1, 6),
    (2, 6),
    (3, 6),
    (4, 6),
    (5, 6),
    (6, 5),
    (6, 4),
    (6, 3),
    (6, 2),
    (6, 1),
    (6, 0),
    (7, 0),
    (8, 0),
    (8, 1),
    (8, 2),
    (8, 3),
    (8, 4),
    (8, 5),
    (9, 6),
    (10, 6),
    (11, 6),
    (12, 6),
    (13, 6),
    (14, 6),
    (14, 7),
    (14, 8),
    (13, 8),
    (12, 8),
    (11, 8),
    (10, 8),
    (9, 8),
    (8, 9),
    (8, 10),
    (8, 11),
    (8, 12),
    (8, 13),
    (8, 14),
    (7, 14),
    (6, 14),
    (6, 13),
    (6, 12),
    (6, 11),
    (6, 10),
    (6, 9),
    (5, 8),
    (4, 8),
    (3, 8),
    (2, 8),
    (1, 8),
    (0, 8),
    (0, 7),
    (0, 6),
  ];

  static const homePathCells = {
    PlayerColor.green: <(int, int)>[(1, 7), (2, 7), (3, 7), (4, 7), (5, 7)],
    PlayerColor.red: <(int, int)>[(7, 13), (7, 12), (7, 11), (7, 10), (7, 9)],
    PlayerColor.blue: <(int, int)>[(13, 7), (12, 7), (11, 7), (10, 7), (9, 7)],
    PlayerColor.yellow: <(int, int)>[(7, 1), (7, 2), (7, 3), (7, 4), (7, 5)],
  };

  /// 2x2 token wells inside each yard, in cell coordinates.
  static const baseSlots = {
    PlayerColor.green: <(int, int)>[(2, 2), (4, 2), (2, 4), (4, 4)],
    PlayerColor.yellow: <(int, int)>[(11, 2), (13, 2), (11, 4), (13, 4)],
    PlayerColor.red: <(int, int)>[(2, 11), (4, 11), (2, 13), (4, 13)],
    PlayerColor.blue: <(int, int)>[(11, 11), (13, 11), (11, 13), (13, 13)],
  };

  /// Exact centres of the four token wells, relative to the yard origin, so
  /// they sit symmetrically inside the white inset.
  static const baseSlotOffsets = <(double, double)>[
    (2.05, 2.05),
    (3.95, 2.05),
    (2.05, 3.95),
    (3.95, 3.95),
  ];

  /// Wooden frame around the 15×15 grid, in cell units.
  static const frameSide = 0.4;
  static const frameTop = 0.32;
  static const frameBottom = 0.58;

  static const yardOrigin = {
    PlayerColor.green: (0, 0),
    PlayerColor.yellow: (9, 0),
    PlayerColor.red: (0, 9),
    PlayerColor.blue: (9, 9),
  };
}

abstract final class NetworkConstants {
  static const serverPort = 4040;
  static const heartbeatInterval = Duration(seconds: 5);
  static const heartbeatTimeout = Duration(seconds: 15);
  static const reconnectGrace = Duration(seconds: 45);
}

abstract final class TimingConstants {
  static const diceAnimation = Duration(milliseconds: 700);
  static const tokenStep = Duration(milliseconds: 160);
  static const tokenBounce = Duration(milliseconds: 70);
  static const autoMoveDelay = Duration(milliseconds: 420);
  static const noMoveTurnDelay = Duration(milliseconds: 850);
  static const captureFlight = Duration(milliseconds: 420);
  static const highlightPulseSeconds = 1.15;
  static const turnDuration = Duration(seconds: 30);
  static const turnTimerSeconds = 30;
  static const timerUrgencySeconds = 5;
}

abstract final class RuleConstants {
  static const diceFaces = 6;
  static const extraTurnOnSix = true;
  static const extraTurnOnCapture = true;
  static const maxConsecutiveSixes = 3;
  static const leaveBaseRequires = 6;
}

abstract final class AppFonts {
  static const ui = 'Nunito';
  static const display = 'LilitaOne';

  /// Nunito ships as a variable font, so the weight axis is set explicitly.
  static TextStyle uiStyle({
    required double size,
    required Color color,
    double weight = 800,
    double? height,
  }) {
    return TextStyle(
      fontFamily: ui,
      fontSize: size,
      color: color,
      height: height,
      fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
      fontVariations: [FontVariation.weight(weight)],
    );
  }
}
