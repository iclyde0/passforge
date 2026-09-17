import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/models/models.dart';
import 'exam_catalog.dart';

class QuestionRepository {
  final Map<String, List<Question>> _cache = {};

  Future<List<Question>> loadExam(String examId) async {
    if (_cache.containsKey(examId)) return _cache[examId]!;

    final def = ExamCatalog.byId(examId);
    final raw = await rootBundle.loadString(def.assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    if ((json['country'] as String?)?.toLowerCase() != 'philippines' ||
        (json['region'] as String?)?.toUpperCase() != 'PH') {
      throw StateError('Question bank for $examId is not Philippine-scoped.');
    }

    final questions = (json['questions'] as List<dynamic>)
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .where((q) => q.examId == examId && q.isPhilippine)
        .toList();

    if (questions.isEmpty) {
      throw StateError('No Philippine questions found for $examId.');
    }

    _cache[examId] = questions;
    return questions;
  }

  Future<List<Question>> byIds(String examId, List<String> ids) async {
    final all = await loadExam(examId);
    final byId = {for (final q in all) q.id: q};
    final out = <Question>[];
    for (final id in ids) {
      final q = byId[id];
      if (q != null) out.add(q);
    }
    out.shuffle();
    return out;
  }

  Future<List<Question>> selectQuestions({
    required String examId,
    required Difficulty difficulty,
    required String focusArea,
    required int count,
    Set<String>? topicFilter,
    List<String>? preferQuestionIds,
  }) async {
    final all = await loadExam(examId);
    var pool = all.where((q) => q.isPhilippine).toList();

    if (focusArea != 'All subjects') {
      pool = pool.where((q) => q.subject == focusArea).toList();
    }
    if (topicFilter != null && topicFilter.isNotEmpty) {
      pool = pool.where((q) => topicFilter.contains(q.topic)).toList();
    }

    pool = _preferDifficultyPool(pool, difficulty, count);

    if (preferQuestionIds != null && preferQuestionIds.isNotEmpty) {
      final preferredQs = <Question>[];
      for (final id in preferQuestionIds) {
        final match = pool.where((q) => q.id == id);
        if (match.isNotEmpty) preferredQs.add(match.first);
      }
      final remaining = pool.where((q) => !preferQuestionIds.contains(q.id));
      pool = [...preferredQs, ...remaining];
    }

    if (pool.isEmpty) {
      pool = List<Question>.from(all)..shuffle();
    }

    return pool.take(count.clamp(1, pool.length)).toList();
  }

  /// Prefer exact difficulty, then nearest neighbors (medium ↔ easy/hard), then rest.
  List<Question> _preferDifficultyPool(
    List<Question> scoped,
    Difficulty difficulty,
    int count,
  ) {
    if (scoped.isEmpty) return scoped;

    List<Question> of(Difficulty d) =>
        scoped.where((q) => q.difficulty == d).toList()..shuffle();

    final exact = of(difficulty);
    if (exact.length >= count) return exact;

    final neighbors = <Difficulty>[];
    switch (difficulty) {
      case Difficulty.easy:
        neighbors.addAll([Difficulty.medium, Difficulty.hard]);
      case Difficulty.medium:
        neighbors.addAll([Difficulty.easy, Difficulty.hard]);
      case Difficulty.hard:
        neighbors.addAll([Difficulty.medium, Difficulty.easy]);
    }

    final picked = <Question>[...exact];
    final used = exact.map((q) => q.id).toSet();
    for (final d in neighbors) {
      if (picked.length >= count) break;
      for (final q in of(d)) {
        if (used.add(q.id)) picked.add(q);
        if (picked.length >= count) break;
      }
    }

    if (picked.length < count) {
      final rest = scoped.where((q) => !used.contains(q.id)).toList()..shuffle();
      picked.addAll(rest);
    }
    return picked;
  }

  Future<Question?> byId(String examId, String questionId) async {
    final all = await loadExam(examId);
    try {
      return all.firstWhere((q) => q.id == questionId);
    } catch (_) {
      return null;
    }
  }

  /// Debug/test helper: counts per difficulty after focus filter.
  Future<Map<Difficulty, int>> difficultyCounts(
    String examId, {
    String focusArea = 'All subjects',
  }) async {
    final all = await loadExam(examId);
    var pool = all.where((q) => q.isPhilippine);
    if (focusArea != 'All subjects') {
      pool = pool.where((q) => q.subject == focusArea);
    }
    final map = {for (final d in Difficulty.values) d: 0};
    for (final q in pool) {
      map[q.difficulty] = (map[q.difficulty] ?? 0) + 1;
    }
    return map;
  }
}
