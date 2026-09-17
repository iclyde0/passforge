import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/gradient_scaffold.dart';
import '../analytics/analytics_screen.dart';

enum _AnswerVisual { idle, flash, revealed }

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  _AnswerVisual _visual = _AnswerVisual.idle;
  Timer? _ticker;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncTimerFromState();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        final state = context.read<AppState>();
        if (state.selectedChoice != null) return;
        final started = state.questionStartedAt;
        if (started == null) return;
        setState(() {
          _elapsedSeconds = DateTime.now().difference(started).inSeconds;
        });
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTimerFromState() {
    final started = context.read<AppState>().questionStartedAt;
    _elapsedSeconds =
        started == null ? 0 : DateTime.now().difference(started).inSeconds;
  }

  Future<void> _onChoose(int index) async {
    final state = context.read<AppState>();
    if (state.selectedChoice != null) return;
    state.choose(index);
    setState(() => _visual = _AnswerVisual.flash);
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;
    state.revealAnswer();
    setState(() => _visual = _AnswerVisual.revealed);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final state = context.read<AppState>();
    final exam = state.activeExamDefinition;
    final answered = state.answeredSoFar;
    final total = state.activeQuestions.length;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave exam?'),
        content: Text(
          'Your unfinished progress will be discarded'
          '${total > 0 ? ' ($answered of $total answered)' : ''}.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep practicing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave exam'),
          ),
        ],
        icon: Icon(Icons.exit_to_app_rounded, color: exam.accentDark),
      ),
    );
    return result == true;
  }

  Future<void> _handleExit() async {
    final leave = await _confirmExit(context);
    if (!leave || !mounted) return;
    context.read<AppState>().abortActiveSession();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.activeSession == null || state.activeQuestions.isEmpty) {
      return GradientScaffold(
        appBar: AppBar(title: const Text('Simulation')),
        child: const Center(child: Text('No active session.')),
      );
    }

    // Reset local visual when moving to a new unanswered question.
    if (state.selectedChoice == null && _visual != _AnswerVisual.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _visual = _AnswerVisual.idle;
          _syncTimerFromState();
        });
      });
    }

    final exam = state.activeExamDefinition;
    final accent = exam.accent;
    final accentDark = exam.accentDark;
    final q = state.currentQuestion;
    final index = state.currentIndex;
    final total = state.activeQuestions.length;
    final mode = state.activeSession!.mode;
    final isRemedial = mode == SessionMode.remedial;
    final isReview = mode == SessionMode.review;
    final answered = state.selectedChoice != null;
    final revealed = _visual == _AnswerVisual.revealed || state.answerRevealed;
    final bookmarked = state.isBookmarked(q.examId, q.id);
    final title = isRemedial
        ? 'Remedial Drill'
        : isReview
            ? 'Review Drill'
            : 'Active Simulation';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleExit();
      },
      child: GradientScaffold(
        accent: accent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Leave exam',
            onPressed: _handleExit,
          ),
          title: Text(title),
          actions: [
            IconButton(
              tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark question',
              onPressed: () => state.toggleBookmarkForCurrent(),
              icon: Icon(
                bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: bookmarked ? accentDark : AppColors.ink,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: ExamColorChip(
                  label: exam.shortName,
                  color: accent,
                  selected: true,
                ),
              ),
            ),
          ],
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (index + 1) / total,
                      minHeight: 8,
                      color: accentDark,
                      backgroundColor: accent.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${index + 1}/$total',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: accentDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ExamColorChip(
                  label: 'Score ${state.correctSoFar}/${state.answeredSoFar}',
                  color: accent,
                ),
                const SizedBox(width: 8),
                ExamColorChip(
                  label: answered
                      ? 'Time ${_formatTime(state.activeSession!.attempts.last.secondsSpent)}'
                      : 'Timer ${_formatTime(_elapsedSeconds)}',
                  color: accentDark,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${state.activeSession!.examName} · ${q.subject}',
              style: const TextStyle(color: AppColors.grey),
            ),
            Text(
              q.topic,
              style: TextStyle(fontWeight: FontWeight.w700, color: accentDark),
            ),
            const SizedBox(height: 14),
            Semantics(
              label: 'Question ${index + 1} of $total. ${q.stem}',
              child: SectionCard(
                accent: accent,
                child: Text(
                  q.stem,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(q.choices.length, (i) {
              final selected = state.selectedChoice == i;
              final correct = i == q.correctIndex;

              Color border = AppColors.grey.withValues(alpha: 0.25);
              Color bg = Colors.white;
              Color letterColor = AppColors.ink;
              IconData? trailing;

              if (answered && _visual == _AnswerVisual.flash && selected) {
                border = accentDark;
                bg = accent.withValues(alpha: 0.35);
                letterColor = accentDark;
              } else if (revealed) {
                if (correct) {
                  border = AppColors.mastered;
                  bg = AppColors.mastered.withValues(alpha: 0.14);
                  letterColor = AppColors.mastered;
                  trailing = Icons.check_circle_rounded;
                } else if (selected) {
                  border = AppColors.critical;
                  bg = AppColors.critical.withValues(alpha: 0.14);
                  letterColor = AppColors.critical;
                  trailing = Icons.cancel_rounded;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border, width: 1.6),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: border.withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: answered ? null : () => _onChoose(i),
                      borderRadius: BorderRadius.circular(14),
                      child: Semantics(
                        button: !answered,
                        selected: selected,
                        label:
                            'Choice ${String.fromCharCode(65 + i)}. ${q.choices[i]}',
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: letterColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  String.fromCharCode(65 + i),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: letterColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  q.choices[i],
                                  style: const TextStyle(fontSize: 16, height: 1.35),
                                ),
                              ),
                              if (trailing != null)
                                Icon(trailing, color: letterColor, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (state.showTutor && revealed) ...[
              const SizedBox(height: 4),
              TutorPanel(
                correct: state.selectedChoice == q.correctIndex,
                explanation: q.explanation,
                accent: accentDark,
                encouragement: isRemedial
                    ? 'Analyze the principle first, then eliminate distractors.'
                    : isReview
                        ? 'Focus on why the correct option wins against close distractors.'
                        : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accentDark,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final done = await state.next();
                  if (!context.mounted) return;
                  if (done) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                    );
                  }
                },
                child: Text(index == total - 1 ? 'See Results' : 'Next Question'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
