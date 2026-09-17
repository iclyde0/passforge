import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../simulation/simulation_screen.dart';

class RemedialScreen extends StatelessWidget {
  const RemedialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final topic = state.suggestedRemedial;
    final exam = state.activeExamDefinition;

    return GradientScaffold(
      accent: exam.accent,
      appBar: AppBar(title: const Text('AI Remedial Drill')),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          SectionCard(
            accent: exam.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExamColorChip(
                  label: exam.shortName,
                  color: exam.accent,
                  selected: true,
                ),
                const SizedBox(height: 10),
                Text(
                  'Focused learning mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: exam.accentDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  topic == null
                      ? 'No weak topic selected.'
                      : 'Intense drill on ${topic.topic} under ${topic.subject}.',
                ),
                const SizedBox(height: 10),
                const Text(
                  'This offline drill pulls only Philippine-bank items from your weakness map. '
                  'The tutor panel will coach you in real time after each answer.',
                  style: TextStyle(color: AppColors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (topic != null)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: exam.accentDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await state.startRemedialDrill(topic);
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SimulationScreen()),
                );
              },
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Begin Remedial Session'),
            ),
        ],
      ),
    );
  }
}
