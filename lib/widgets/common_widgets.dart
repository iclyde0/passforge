import 'package:flutter/material.dart';

import '../domain/models/models.dart';
import '../theme/app_theme.dart';

class MasteryRing extends StatelessWidget {
  const MasteryRing({
    super.key,
    required this.percent,
    this.size = 160,
    this.accent,
  });

  final double percent;
  final double size;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final value = percent.clamp(0, 100).toDouble();
    final ring = accent ?? AppColors.violet;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value / 100,
              strokeWidth: size * 0.08,
              backgroundColor: AppColors.greyLight,
              color: ring,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${value.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Mastery',
                style: TextStyle(color: AppColors.grey, fontSize: size * 0.08),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class KnowledgeHeatMap extends StatelessWidget {
  const KnowledgeHeatMap({super.key, required this.items});

  final List<TopicPerformance> items;

  Color _color(HeatLevel level) {
    switch (level) {
      case HeatLevel.mastered:
        return AppColors.mastered;
      case HeatLevel.review:
        return AppColors.review;
      case HeatLevel.critical:
        return AppColors.critical;
    }
  }

  String _label(HeatLevel level) {
    switch (level) {
      case HeatLevel.mastered:
        return 'Mastered';
      case HeatLevel.review:
        return 'Review';
      case HeatLevel.critical:
        return 'Critical';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No topic data yet.');
    }
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 42,
                decoration: BoxDecoration(
                  color: _color(item.level),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.topic,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${item.subject} · ${item.correct}/${item.total} · ${_label(item.level)}',
                      style: const TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${item.percent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _color(item.level),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class TutorPanel extends StatelessWidget {
  const TutorPanel({
    super.key,
    required this.correct,
    required this.explanation,
    this.encouragement,
    this.accent,
  });

  final bool correct;
  final String explanation;
  final String? encouragement;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tone = correct ? AppColors.mastered : (accent ?? AppColors.violet);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: tone,
                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                correct ? 'AI Tutor · Correct' : 'AI Tutor · Review this',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(explanation),
          if (encouragement != null) ...[
            const SizedBox(height: 8),
            Text(
              encouragement!,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: tone,
              ),
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            'Offline tutor note from your Philippine question bank.',
            style: TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
