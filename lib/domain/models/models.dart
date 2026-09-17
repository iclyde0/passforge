import 'package:flutter/material.dart';

enum Difficulty { easy, medium, hard }

Difficulty difficultyFromString(String value) {
  switch (value.toLowerCase()) {
    case 'easy':
      return Difficulty.easy;
    case 'hard':
      return Difficulty.hard;
    default:
      return Difficulty.medium;
  }
}

extension DifficultyX on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  String get wire {
    switch (this) {
      case Difficulty.easy:
        return 'easy';
      case Difficulty.medium:
        return 'medium';
      case Difficulty.hard:
        return 'hard';
    }
  }
}

class ExamDefinition {
  const ExamDefinition({
    required this.id,
    required this.shortName,
    required this.fullName,
    required this.regulator,
    required this.focusAreas,
    required this.assetPath,
    required this.description,
    required this.accent,
    required this.accentDark,
    this.passingScorePercent = 75,
  });

  final String id;
  final String shortName;
  final String fullName;
  final String regulator;
  final List<String> focusAreas;
  final String assetPath;
  final String description;
  final Color accent;
  final Color accentDark;
  /// Simulated pass mark used for end-of-exam verdict (default 75%).
  final int passingScorePercent;

  Color get soft => accent.withValues(alpha: 0.14);
}

class Question {
  const Question({
    required this.id,
    required this.examId,
    required this.subject,
    required this.topic,
    required this.difficulty,
    required this.stem,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
    required this.country,
    required this.region,
  });

  final String id;
  final String examId;
  final String subject;
  final String topic;
  final Difficulty difficulty;
  final String stem;
  final List<String> choices;
  final int correctIndex;
  final String explanation;
  final String country;
  final String region;

  bool get isPhilippine =>
      country.toLowerCase() == 'philippines' && region.toUpperCase() == 'PH';

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      examId: json['examId'] as String,
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      difficulty: difficultyFromString(json['difficulty'] as String? ?? 'medium'),
      stem: json['stem'] as String,
      choices: (json['choices'] as List<dynamic>).cast<String>(),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
      country: json['country'] as String? ?? 'Philippines',
      region: json['region'] as String? ?? 'PH',
    );
  }
}

class AnswerAttempt {
  const AnswerAttempt({
    required this.questionId,
    required this.subject,
    required this.topic,
    required this.selectedIndex,
    required this.correctIndex,
    required this.secondsSpent,
  });

  final String questionId;
  final String subject;
  final String topic;
  final int selectedIndex;
  final int correctIndex;
  final int secondsSpent;

  bool get isCorrect => selectedIndex == correctIndex;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'subject': subject,
        'topic': topic,
        'selectedIndex': selectedIndex,
        'correctIndex': correctIndex,
        'secondsSpent': secondsSpent,
      };

  factory AnswerAttempt.fromJson(Map<String, dynamic> json) {
    return AnswerAttempt(
      questionId: json['questionId'] as String,
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      selectedIndex: json['selectedIndex'] as int,
      correctIndex: json['correctIndex'] as int,
      secondsSpent: json['secondsSpent'] as int,
    );
  }
}

enum SessionMode { simulation, remedial, review }

class ExamSession {
  ExamSession({
    required this.id,
    required this.examId,
    required this.examName,
    required this.difficulty,
    required this.focusArea,
    required this.mode,
    required this.questionIds,
    required this.startedAt,
    this.completedAt,
    List<AnswerAttempt>? attempts,
  }) : attempts = attempts ?? [];

  final String id;
  final String examId;
  final String examName;
  final Difficulty difficulty;
  final String focusArea;
  final SessionMode mode;
  final List<String> questionIds;
  final DateTime startedAt;
  DateTime? completedAt;
  final List<AnswerAttempt> attempts;

  bool get isComplete => completedAt != null;

  double get masteryPercent {
    if (attempts.isEmpty) return 0;
    final correct = attempts.where((a) => a.isCorrect).length;
    return (correct / attempts.length) * 100;
  }

  int get correctCount => attempts.where((a) => a.isCorrect).length;

  int get wrongCount => attempts.length - correctCount;

  int get totalAnswered => attempts.length;

  double get averageSecondsPerItem {
    if (attempts.isEmpty) return 0;
    return attempts.map((a) => a.secondsSpent).reduce((a, b) => a + b) /
        attempts.length;
  }

  int get totalSecondsSpent =>
      attempts.fold<int>(0, (sum, a) => sum + a.secondsSpent);

  SessionPassStats passStats(int passingScorePercent) {
    final score = masteryPercent;
    final passed = attempts.isNotEmpty && score >= passingScorePercent;
    final neededCorrect =
        ((passingScorePercent / 100) * attempts.length).ceil();
    final marginItems = correctCount - neededCorrect;
    return SessionPassStats(
      scorePercent: score,
      passingScorePercent: passingScorePercent,
      passed: passed,
      correct: correctCount,
      wrong: wrongCount,
      total: totalAnswered,
      averageSeconds: averageSecondsPerItem,
      totalSeconds: totalSecondsSpent,
      itemsAboveOrBelowPass: marginItems,
      neededCorrectToPass: neededCorrect,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'examId': examId,
        'examName': examName,
        'difficulty': difficulty.wire,
        'focusArea': focusArea,
        'mode': mode.name,
        'questionIds': questionIds,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'attempts': attempts.map((a) => a.toJson()).toList(),
      };

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    return ExamSession(
      id: json['id'] as String,
      examId: json['examId'] as String,
      examName: json['examName'] as String,
      difficulty: difficultyFromString(json['difficulty'] as String? ?? 'medium'),
      focusArea: json['focusArea'] as String,
      mode: SessionMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => SessionMode.simulation,
      ),
      questionIds: (json['questionIds'] as List<dynamic>).cast<String>(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      attempts: (json['attempts'] as List<dynamic>? ?? [])
          .map((e) => AnswerAttempt.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

enum HeatLevel { mastered, review, critical }

class SessionPassStats {
  const SessionPassStats({
    required this.scorePercent,
    required this.passingScorePercent,
    required this.passed,
    required this.correct,
    required this.wrong,
    required this.total,
    required this.averageSeconds,
    required this.totalSeconds,
    required this.itemsAboveOrBelowPass,
    required this.neededCorrectToPass,
  });

  final double scorePercent;
  final int passingScorePercent;
  final bool passed;
  final int correct;
  final int wrong;
  final int total;
  final double averageSeconds;
  final int totalSeconds;
  final int itemsAboveOrBelowPass;
  final int neededCorrectToPass;

  String get verdictLabel => passed ? 'PASSED' : 'NOT YET PASSED';

  String get marginLabel {
    if (total == 0) return 'No items answered';
    if (passed) {
      if (itemsAboveOrBelowPass <= 0) {
        return 'Exactly at the $passingScorePercent% pass mark';
      }
      final n = itemsAboveOrBelowPass;
      return '+$n item${n == 1 ? '' : 's'} above the pass mark';
    }
    final short = neededCorrectToPass - correct;
    return 'Need $short more correct to reach $passingScorePercent%';
  }
}

class TopicPerformance {
  const TopicPerformance({
    required this.subject,
    required this.topic,
    required this.correct,
    required this.total,
    required this.avgSeconds,
  });

  final String subject;
  final String topic;
  final int correct;
  final int total;
  final double avgSeconds;

  double get percent => total == 0 ? 0 : (correct / total) * 100;

  HeatLevel get level {
    if (percent >= 80) return HeatLevel.mastered;
    if (percent >= 50) return HeatLevel.review;
    return HeatLevel.critical;
  }
}
