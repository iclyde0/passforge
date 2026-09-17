import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/gradient_scaffold.dart';
import '../home/home_screen.dart';
import '../remedial/remedial_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final session = state.activeSession;
    final mastery = session?.masteryPercent ?? 0;
    final exam = state.activeExamDefinition;
    final stats = session?.passStats(exam.passingScorePercent);
    final fromHistory = state.viewingHistory;

    return PopScope(
      canPop: !fromHistory,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (fromHistory) {
          state.clearHistoryView();
          Navigator.of(context).pop();
        }
      },
      child: GradientScaffold(
        accent: exam.accent,
        appBar: AppBar(
          title: Text(fromHistory ? 'Session Pass Stats' : 'Performance Map'),
          automaticallyImplyLeading: fromHistory,
          leading: fromHistory
              ? IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    state.clearHistoryView();
                    Navigator.of(context).pop();
                  },
                )
              : null,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            SectionCard(
              accent: exam.accent,
              child: Column(
                children: [
                  ExamColorChip(
                    label: exam.shortName,
                    color: exam.accent,
                    selected: true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    session == null
                        ? 'Session complete'
                        : '${session.examName} · ${session.mode.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: exam.accentDark,
                    ),
                  ),
                  if (fromHistory && session != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Saved ${_shortDate(session.completedAt ?? session.startedAt)}',
                      style: const TextStyle(color: AppColors.grey),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Mastery ${mastery.toStringAsFixed(0)} percent',
                    child: MasteryRing(percent: mastery, accent: exam.accentDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${session?.correctCount ?? 0}/${session?.totalAnswered ?? 0} correct',
                    style: const TextStyle(color: AppColors.grey),
                  ),
                ],
              ),
            ),
            if (stats != null) ...[
              const SizedBox(height: 14),
              _PassStatsCard(
                stats: stats,
                accent: exam.accent,
                accentDark: exam.accentDark,
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Knowledge Heat Map',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SectionCard(
              accent: exam.accent,
              child: KnowledgeHeatMap(items: state.lastHeatMap),
            ),
            const SizedBox(height: 14),
            if (!fromHistory && state.suggestedRemedial != null)
              SectionCard(
                accent: exam.accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded, color: exam.accentDark),
                        const SizedBox(width: 8),
                        const Text(
                          'Targeted AI Analysis',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Focus next on "${state.suggestedRemedial!.topic}" '
                      '(${state.suggestedRemedial!.percent.toStringAsFixed(0)}% mastery).',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: exam.accentDark,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RemedialScreen(),
                          ),
                        );
                      },
                      child: const Text('Start Targeted Remedial Drill'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: exam.accentDark,
                side: BorderSide(color: exam.accentDark),
              ),
              onPressed: () {
                if (fromHistory) {
                  state.clearHistoryView();
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false,
                  );
                }
              },
              child: Text(fromHistory ? 'Close' : 'Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime d) {
    final local = d.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd $hh:$min';
  }
}

class _PassStatsCard extends StatelessWidget {
  const _PassStatsCard({
    required this.stats,
    required this.accent,
    required this.accentDark,
  });

  final SessionPassStats stats;
  final Color accent;
  final Color accentDark;

  @override
  Widget build(BuildContext context) {
    final passColor = stats.passed ? AppColors.mastered : AppColors.critical;
    return SectionCard(
      accent: passColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                stats.passed ? Icons.verified_rounded : Icons.warning_amber_rounded,
                color: passColor,
              ),
              const SizedBox(width: 8),
              Text(
                stats.verdictLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: passColor,
                ),
              ),
              const Spacer(),
              ExamColorChip(
                label: 'Pass mark ${stats.passingScorePercent}%',
                color: accent,
                selected: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stats.marginLabel,
            style: TextStyle(color: accentDark, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statTile('Passing rate', '${stats.scorePercent.toStringAsFixed(1)}%'),
              _statTile('Correct', '${stats.correct}'),
              _statTile('Wrong', '${stats.wrong}'),
              _statTile('Items', '${stats.total}'),
              _statTile('Avg / item', '${stats.averageSeconds.toStringAsFixed(0)}s'),
              _statTile('Total time', _formatDuration(stats.totalSeconds)),
              _statTile('Need to pass', '${stats.neededCorrectToPass} correct'),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Simulated pass rule: score ≥ pass mark. For practice only — not an official PRC/CSC result.',
            style: TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    if (m <= 0) return '${s}s';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  Widget _statTile(String label, String value) {
    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: accentDark,
            ),
          ),
        ],
      ),
    );
  }
}
