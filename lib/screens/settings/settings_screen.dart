import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../services/dice_service.dart';
import '../../state/providers/session_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/ludo_logo.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _name;
  Map<int, int>? _fairness;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: ref.read(sessionProvider).playerName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const LudoLogo(size: 40),
              const SizedBox(height: 24),
              TextField(
                controller: _name,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Player name',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: ref.read(sessionProvider.notifier).setPlayerName,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                GoldButton(
                  label: 'Dice fairness sample (120k)',
                  onPressed: () {
                    const dice = SecureDiceService();
                    final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
                    for (var i = 0; i < 120000; i++) {
                      final value = dice.secureRoll();
                      counts[value] = counts[value]! + 1;
                    }
                    setState(() => _fairness = counts);
                  },
                ),
              ],
              if (_fairness != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _fairness!.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join('   '),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              const Spacer(),
              GoldButton(
                label: 'Done',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
