import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/exam_catalog.dart';
import '../../data/usage_store.dart';
import '../../domain/models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../simulation/simulation_screen.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final accent = state.selectedExam.accent;
    final accentDark = state.selectedExam.accentDark;

    return GradientScaffold(
      accent: accent,
      appBar: AppBar(title: const Text('Smart Configuration')),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text(
            'Choose a Philippine exam and refine the simulation parameters.',
            style: TextStyle(color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          SectionCard(
            accent: accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exam', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ...ExamCatalog.exams.map((exam) {
                  final selected = state.selectedExam.id == exam.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: exam.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? exam.accentDark : Colors.white,
                          width: selected ? 3 : 1,
                        ),
                      ),
                    ),
                    title: Text(
                      '${exam.shortName} · ${exam.regulator}',
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? exam.accentDark : AppColors.ink,
                      ),
                    ),
                    subtitle: Text(exam.fullName),
                    tileColor: selected ? exam.soft : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () => state.selectExam(exam),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            accent: accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Difficulty', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: Difficulty.values.map((d) {
                    final selected = state.selectedDifficulty == d;
                    return ChoiceChip(
                      label: Text(d.label),
                      selected: selected,
                      selectedColor: accent.withValues(alpha: 0.35),
                      side: BorderSide(color: accent.withValues(alpha: 0.5)),
                      onSelected: (_) => state.setDifficulty(d),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Focus area', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: state.selectedFocus,
                  items: state.selectedExam.focusAreas
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) state.setFocus(v);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Question count', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: UsageStore.freeQuestionCount,
                      label: Text('20 (Free)'),
                    ),
                    ButtonSegment(
                      value: UsageStore.premiumQuestionCount,
                      label: Text('50 (Pack)'),
                    ),
                  ],
                  selected: {state.selectedCount},
                  onSelectionChanged: (s) => state.setCount(s.first),
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return accentDark;
                      }
                      return AppColors.grey;
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: accentDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              final err = await state.startSimulation();
              if (err != null) {
                messenger.showSnackBar(SnackBar(content: Text(err)));
                return;
              }
              if (!context.mounted) return;
              nav.pushReplacement(
                MaterialPageRoute(builder: (_) => const SimulationScreen()),
              );
            },
            child: const Text('Start Simulation'),
          ),
        ],
      ),
    );
  }
}
