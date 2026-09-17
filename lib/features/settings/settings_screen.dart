import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dateLabel = state.examDate == null
        ? 'Not set'
        : DateFormat.yMMMMd().format(state.examDate!);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Settings')),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exam countdown', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Target date: $dateLabel'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: state.examDate ?? now.add(const Duration(days: 60)),
                          firstDate: now.subtract(const Duration(days: 1)),
                          lastDate: now.add(const Duration(days: 365 * 3)),
                        );
                        if (picked != null) await state.setExamDate(picked);
                      },
                      child: const Text('Set date'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => state.setExamDate(null),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Progress', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Clear locally saved sessions on this device.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset progress?'),
                        content: const Text('This deletes saved session history.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
                        ],
                      ),
                    );
                    if (ok == true) await state.resetProgress();
                  },
                  child: const Text('Reset progress'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accessibility',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enlarge text across PassForge. Contrast uses darker slate labels on light surfaces.',
                ),
                const SizedBox(height: 12),
                Text(
                  'Text size: ${(state.textScale * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: state.textScale,
                  min: 1.0,
                  max: 1.45,
                  divisions: 9,
                  label: '${(state.textScale * 100).round()}%',
                  onChanged: (v) => state.setTextScale(v),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final scale in [1.0, 1.15, 1.3, 1.45])
                      ChoiceChip(
                        label: Text('${(scale * 100).round()}%'),
                        selected: (state.textScale - scale).abs() < 0.02,
                        onSelected: (_) => state.setTextScale(scale),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Help', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text(
                  'Replay the first-launch user guide anytime.',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(fromSettings: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline_rounded),
                  label: const Text('Open user guide'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Coming soon', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  onChanged: null,
                  title: const Text('Live AI Tutor (Gemini)'),
                  subtitle: const Text('Placeholder — free daily quota coming later.'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  onChanged: null,
                  title: const Text('Bring Your Own Key (BYOK)'),
                  subtitle: const Text('Placeholder — paste your Gemini API key later.'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  onChanged: null,
                  title: const Text('Rewarded ads for extra hints'),
                  subtitle: const Text('Placeholder — AdMob unlock coming later.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About PassForge', style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text(
                  'PassForge — Simulate. Study. Pass.\n\n'
                  'Offline-first Philippine board exam simulator. Question banks are original practice items '
                  'associated only with Philippine exams (PRC/CSC coverage). Not affiliated with PRC or CSC.',
                ),
                SizedBox(height: 8),
                Text(
                  'Version 1.1.0 · Android + iOS (iPhone X / iOS 15+).',
                  style: TextStyle(color: AppColors.grey, fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  'Live Gemini tutor, AdMob unlocks, and BYOK are planned for a later phase.',
                  style: TextStyle(color: AppColors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
