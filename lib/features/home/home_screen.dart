import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../branding.dart';
import '../../data/exam_catalog.dart';
import '../../data/usage_store.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../analytics/analytics_screen.dart';
import '../setup/setup_screen.dart';
import '../settings/settings_screen.dart';
import '../simulation/simulation_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _startReview(
    BuildContext context,
    Future<String?> Function() starter,
  ) async {
    final err = await starter();
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SimulationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final remaining = UsageStore.freeDailySimulations - state.simsUsedToday;
    final days = state.daysUntilExam;

    return GradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Semantics(
            header: true,
            label: '${AppBranding.name}. ${AppBranding.tagline}',
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    AppBranding.iconAsset,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    semanticLabel: 'PassForge app icon',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppBranding.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.violetDark,
                            ),
                      ),
                      const Text(
                        AppBranding.tagline,
                        style: TextStyle(
                          color: AppColors.violetDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        AppBranding.subtitle,
                        style: TextStyle(color: AppColors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coverage locked to Philippine exams',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Each exam uses its own accent color across setup, questions, and feedback.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExamCatalog.exams
                      .map(
                        (e) => ExamColorChip(
                          label: e.shortName,
                          color: e.accent,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill('Free today: ${remaining.clamp(0, 99)} sim'),
                    _pill('${UsageStore.freeQuestionCount}-Q free length'),
                    if (days != null)
                      _pill(days >= 0 ? '$days days to exam' : 'Exam date passed'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SetupScreen()),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Smart Configuration'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.wrongAttemptCount == 0
                      ? null
                      : () => _startReview(
                            context,
                            () => state.startReviewWrong(),
                          ),
                  icon: const Icon(Icons.replay_circle_filled_outlined),
                  label: Text('Review wrong (${state.wrongAttemptCount})'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.bookmarkCount == 0
                      ? null
                      : () => _startReview(
                            context,
                            () => state.startReviewBookmarks(),
                          ),
                  icon: const Icon(Icons.bookmark_outline_rounded),
                  label: Text('Bookmarks (${state.bookmarkCount})'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Recent sessions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          if (state.history.isEmpty)
            const SectionCard(
              child: Text('No simulations yet. Configure an exam to begin.'),
            )
          else
            ...state.history.take(8).map((s) {
              final exam = ExamCatalog.byId(s.examId);
              final stats = s.isComplete
                  ? s.passStats(exam.passingScorePercent)
                  : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: s.isComplete
                        ? () {
                            state.openHistorySession(s);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AnalyticsScreen(),
                              ),
                            );
                          }
                        : null,
                    child: Semantics(
                      button: s.isComplete,
                      label: s.isComplete
                          ? 'Open pass stats for ${s.examName}, '
                              '${s.masteryPercent.toStringAsFixed(0)} percent'
                          : 'Incomplete session for ${s.examName}',
                      child: SectionCard(
                        accent: exam.accent,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 42,
                              decoration: BoxDecoration(
                                color: exam.accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${s.examName} · ${s.mode.name}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: exam.accentDark,
                                    ),
                                  ),
                                  Text(
                                    '${s.focusArea} · ${s.attempts.length} answered · '
                                    '${s.masteryPercent.toStringAsFixed(0)}%'
                                    '${stats == null ? '' : (stats.passed ? ' · Passed' : ' · Not yet')}',
                                    style: const TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (s.isComplete)
                                    Text(
                                      'Tap to view pass stats',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: exam.accentDark.withValues(alpha: 0.85),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              s.isComplete
                                  ? Icons.chevron_right_rounded
                                  : Icons.timelapse,
                              color: s.isComplete
                                  ? exam.accentDark
                                  : AppColors.review,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          const Text(
            'Disclaimer: Original educational practice content. Not affiliated with PRC or CSC.',
            style: TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
