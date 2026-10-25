import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'screens/game/game_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/hotseat/pass_and_play_setup_screen.dart';
import 'screens/lobby/host_lobby_screen.dart';
import 'screens/lobby/join_game_screen.dart';
import 'screens/multiplayer/local_multiplayer_screen.dart';
import 'screens/result/result_screen.dart';
import 'screens/settings/settings_screen.dart';

class LudoApp extends StatelessWidget {
  const LudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ludo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: AppFonts.ui,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/hotseat': (_) => const PassAndPlaySetupScreen(),
        '/local': (_) => const LocalMultiplayerScreen(),
        '/host': (_) => const HostLobbyScreen(),
        '/join': (_) => const JoinGameScreen(),
        '/game': (_) => const GameScreen(),
        '/result': (_) => const ResultScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
