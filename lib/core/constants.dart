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

  static const green = Color(0xFF43A047);
  static const greenDeep = Color(0xFF2E7D32);
  static const yellow = Color(0xFFFDD835);
  static const yellowDeep = Color(0xFFF9A825);
  static const red = Color(0xFFE53935);
  static const redDeep = Color(0xFFC62828);
  static const blue = Color(0xFF1E88E5);
  static const blueDeep = Color(0xFF1565C0);

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

  /// Track index where each color enters from BASE.
  static const startIndex = {
    PlayerColor.green: 0,
    PlayerColor.red: 13,
    PlayerColor.blue: 26,
    PlayerColor.yellow: 39,
  };

  /// Shared-track index immediately before that color's home path.
  static const approachIndex = {
    PlayerColor.green: 50,
    PlayerColor.red: 11,
    PlayerColor.blue: 24,
    PlayerColor.yellow: 37,
  };

  /// Start squares plus classic star squares.
  static const safeTrackIndices = {0, 8, 13, 21, 26, 34, 39, 47};

  static const starTrackIndices = {8, 21, 34, 47};

  /// Clockwise turn order matching the board (green → red → blue → yellow).
  static const turnOrder = [
    PlayerColor.green,
    PlayerColor.red,
    PlayerColor.blue,
    PlayerColor.yellow,
  ];

  /// Main-track cells as (col, row) with (0,0) at top-left. Index 0 = green start.
  static const trackCells = <(int, int)>[
    (1, 8), (2, 8), (3, 8), (4, 8), (5, 8),
    (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 14),
    (7, 14),
    (8, 14), (8, 13), (8, 12), (8, 11), (8, 10), (8, 9),
    (9, 8), (10, 8), (11, 8), (12, 8), (13, 8), (14, 8),
    (14, 7),
    (14, 6), (13, 6), (12, 6), (11, 6), (10, 6), (9, 6),
    (8, 5), (8, 4), (8, 3), (8, 2), (8, 1), (8, 0),
    (7, 0),
    (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5),
    (5, 6), (4, 6), (3, 6), (2, 6), (1, 6), (0, 6),
    (0, 7),
    (0, 8),
  ];

  static const homePathCells = {
    PlayerColor.green: <(int, int)>[
      (1, 7),
      (2, 7),
      (3, 7),
      (4, 7),
      (5, 7),
    ],
    PlayerColor.red: <(int, int)>[
      (7, 13),
      (7, 12),
      (7, 11),
      (7, 10),
      (7, 9),
    ],
    PlayerColor.blue: <(int, int)>[
      (13, 7),
      (12, 7),
      (11, 7),
      (10, 7),
      (9, 7),
    ],
    PlayerColor.yellow: <(int, int)>[
      (7, 1),
      (7, 2),
      (7, 3),
      (7, 4),
      (7, 5),
    ],
  };

  /// 2x2 token wells inside each yard, in cell coordinates.
  static const baseSlots = {
    PlayerColor.green: <(int, int)>[
      (2, 2),
      (4, 2),
      (2, 4),
      (4, 4),
    ],
    PlayerColor.yellow: <(int, int)>[
      (11, 2),
      (13, 2),
      (11, 4),
      (13, 4),
    ],
    PlayerColor.red: <(int, int)>[
      (2, 11),
      (4, 11),
      (2, 13),
      (4, 13),
    ],
    PlayerColor.blue: <(int, int)>[
      (11, 11),
      (13, 11),
      (11, 13),
      (13, 13),
    ],
  };

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
}

abstract final class RuleConstants {
  static const diceFaces = 6;
  static const extraTurnOnSix = true;
  static const extraTurnOnCapture = true;
  static const maxConsecutiveSixes = 3;
  static const leaveBaseRequires = 6;
}
