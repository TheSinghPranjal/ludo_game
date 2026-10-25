import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../state/providers/session_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/ludo_logo.dart';

class PassAndPlaySetupScreen extends ConsumerStatefulWidget {
  const PassAndPlaySetupScreen({super.key});

  @override
  ConsumerState<PassAndPlaySetupScreen> createState() =>
      _PassAndPlaySetupScreenState();
}

class _PassAndPlaySetupScreenState
    extends ConsumerState<PassAndPlaySetupScreen> {
  var _count = 2;
  var _starting = false;
  final _names = List.generate(
    4,
    (i) => TextEditingController(text: 'Player ${i + 1}'),
  );

  @override
  void dispose() {
    for (final controller in _names) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BoardConstants.seatColors(_count);
    return GameBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const LudoLogo(size: 40),
              const SizedBox(height: 8),
              const Text(
                'Pass the phone each turn.\nNo Wi-Fi needed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Players',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final n in [2, 3, 4])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _PlayerCountChip(
                          count: n,
                          selected: _count == n,
                          onTap: () => setState(() => _count = n),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < _count; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: _names[i],
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.circle,
                              color: AppColors.of(colors[i]),
                            ),
                            labelText: colors[i].displayName,
                            labelStyle: TextStyle(
                              color: AppColors.of(colors[i]),
                            ),
                            filled: true,
                            fillColor: AppColors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              GoldButton(
                label: 'START GAME',
                onPressed: () async {
                  if (_starting) {
                    return;
                  }
                  _starting = true;
                  try {
                    await ref
                        .read(sessionProvider.notifier)
                        .startPassAndPlay(
                          playerCount: _count,
                          names: _names
                              .take(_count)
                              .map((c) => c.text)
                              .toList(),
                        );
                    if (context.mounted) {
                      await Navigator.pushNamed(context, '/game');
                    }
                  } finally {
                    _starting = false;
                  }
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Back',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerCountChip extends StatelessWidget {
  const _PlayerCountChip({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.goldDeep
                  : AppColors.gold.withValues(alpha: 0.35),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: selected ? const Color(0xFF3E2723) : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
