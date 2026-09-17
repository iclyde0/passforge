import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/bookmark_store.dart';
import '../data/exam_catalog.dart';
import '../data/question_repository.dart';
import '../data/session_store.dart';
import '../data/usage_store.dart';
import '../domain/models/models.dart';

class AppState extends ChangeNotifier {
  AppState({
    QuestionRepository? questions,
    SessionStore? sessions,
    UsageStore? usage,
    BookmarkStore? bookmarks,
  })  : _questions = questions ?? QuestionRepository(),
        _sessions = sessions ?? SessionStore(),
        _usage = usage ?? UsageStore(),
        _bookmarks = bookmarks ?? BookmarkStore();

  final QuestionRepository _questions;
  final SessionStore _sessions;
  final UsageStore _usage;
  final BookmarkStore _bookmarks;
  final _uuid = const Uuid();

  bool ready = false;
  String? bootError;
  bool hasSeenGuide = false;
  List<ExamSession> history = [];
  DateTime? examDate;
  int simsUsedToday = 0;
  double textScale = 1.0;
  Set<String> bookmarkedKeys = {};
  /// When true, Analytics shows a past session (not a live finish flow).
  bool viewingHistory = false;

  ExamDefinition selectedExam = ExamCatalog.exams.first;
  Difficulty selectedDifficulty = Difficulty.medium;
  String selectedFocus = 'All subjects';
  int selectedCount = UsageStore.freeQuestionCount;

  ExamSession? activeSession;
  List<Question> activeQuestions = [];
  int currentIndex = 0;
  int? selectedChoice;
  bool showTutor = false;
  bool answerRevealed = false;
  DateTime? questionStartedAt;
  List<TopicPerformance> lastHeatMap = [];
  TopicPerformance? suggestedRemedial;

  ExamDefinition get activeExamDefinition {
    final id = activeSession?.examId ?? selectedExam.id;
    return ExamCatalog.byId(id);
  }

  int get correctSoFar =>
      activeSession?.attempts.where((a) => a.isCorrect).length ?? 0;

  int get answeredSoFar => activeSession?.attempts.length ?? 0;

  int get bookmarkCount => bookmarkedKeys.length;

  int get wrongAttemptCount {
    final seen = <String>{};
    var n = 0;
    for (final session in history) {
      for (final a in session.attempts) {
        if (a.isCorrect) continue;
        final key = BookmarkStore.keyFor(session.examId, a.questionId);
        if (seen.add(key)) n++;
      }
    }
    return n;
  }

  bool isBookmarked(String examId, String questionId) =>
      bookmarkedKeys.contains(BookmarkStore.keyFor(examId, questionId));

  Future<void> init() async {
    try {
      for (final exam in ExamCatalog.exams) {
        await _questions.loadExam(exam.id);
      }
      history = await _sessions.loadAll();
      examDate = await _usage.getExamDate();
      simsUsedToday = await _usage.simulationsUsedToday();
      hasSeenGuide = await _usage.hasSeenGuide();
      textScale = await _usage.getTextScale();
      bookmarkedKeys = await _bookmarks.loadAll();
      ready = true;
    } catch (e) {
      bootError = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshUsage() async {
    simsUsedToday = await _usage.simulationsUsedToday();
    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    textScale = scale.clamp(1.0, 1.45);
    await _usage.setTextScale(textScale);
    notifyListeners();
  }

  Future<void> toggleBookmarkForCurrent() async {
    final session = activeSession;
    if (session == null || activeQuestions.isEmpty) return;
    final q = currentQuestion;
    bookmarkedKeys = await _bookmarks.toggle(session.examId, q.id);
    notifyListeners();
  }

  void selectExam(ExamDefinition exam) {
    selectedExam = exam;
    selectedFocus = exam.focusAreas.first;
    notifyListeners();
  }

  void setDifficulty(Difficulty d) {
    selectedDifficulty = d;
    notifyListeners();
  }

  void setFocus(String focus) {
    selectedFocus = focus;
    notifyListeners();
  }

  void setCount(int count) {
    selectedCount = count;
    notifyListeners();
  }

  Future<String?> startSimulation({bool forceRemedial = false}) async {
    if (!forceRemedial) {
      final allowed = await _usage.canStartFreeSimulation();
      if (!allowed && selectedCount <= UsageStore.freeQuestionCount) {
        return 'Daily free simulation used. Come back tomorrow, or run a shorter session later when limits reset.';
      }
    }

    final qs = await _questions.selectQuestions(
      examId: selectedExam.id,
      difficulty: selectedDifficulty,
      focusArea: selectedFocus,
      count: selectedCount,
    );

    _beginLiveSession(
      questions: qs,
      exam: selectedExam,
      focusArea: selectedFocus,
      mode: SessionMode.simulation,
      difficulty: selectedDifficulty,
    );

    if (!forceRemedial) {
      await _usage.recordSimulationStart();
      await refreshUsage();
    }
    notifyListeners();
    return null;
  }

  Future<String?> startRemedialDrill(TopicPerformance topic) async {
    final qs = await _questions.selectQuestions(
      examId: selectedExam.id,
      difficulty: selectedDifficulty,
      focusArea: 'All subjects',
      count: 10,
      topicFilter: {topic.topic},
    );

    final pool = qs.isNotEmpty
        ? qs
        : await _questions.selectQuestions(
            examId: selectedExam.id,
            difficulty: selectedDifficulty,
            focusArea: topic.subject,
            count: 10,
          );

    suggestedRemedial = topic;
    _beginLiveSession(
      questions: pool,
      exam: selectedExam,
      focusArea: topic.topic,
      mode: SessionMode.remedial,
      difficulty: selectedDifficulty,
    );
    notifyListeners();
    return null;
  }

  /// Review only previously missed items (optionally limited to one exam).
  Future<String?> startReviewWrong({String? examId}) async {
    final targets = <({String examId, String questionId})>[];
    final seen = <String>{};
    for (final session in history) {
      if (examId != null && session.examId != examId) continue;
      for (final a in session.attempts) {
        if (a.isCorrect) continue;
        final key = BookmarkStore.keyFor(session.examId, a.questionId);
        if (!seen.add(key)) continue;
        targets.add((examId: session.examId, questionId: a.questionId));
      }
    }
    return _startReviewFromTargets(
      targets,
      focusLabel: 'Wrong answers only',
      emptyMessage: 'No wrong answers yet. Finish a simulation first.',
    );
  }

  /// Drill saved bookmarks (optionally limited to one exam).
  Future<String?> startReviewBookmarks({String? examId}) async {
    final targets = <({String examId, String questionId})>[];
    for (final key in bookmarkedKeys) {
      final parts = key.split('|');
      if (parts.length != 2) continue;
      if (examId != null && parts[0] != examId) continue;
      targets.add((examId: parts[0], questionId: parts[1]));
    }
    return _startReviewFromTargets(
      targets,
      focusLabel: 'Bookmarked items',
      emptyMessage: 'No bookmarks yet. Tap the bookmark icon during a simulation.',
    );
  }

  Future<String?> _startReviewFromTargets(
    List<({String examId, String questionId})> targets, {
    required String focusLabel,
    required String emptyMessage,
  }) async {
    if (targets.isEmpty) return emptyMessage;

    final byExam = <String, List<String>>{};
    for (final t in targets) {
      byExam.putIfAbsent(t.examId, () => []).add(t.questionId);
    }

    // Prefer the selected exam's wrong/bookmark pool when present.
    final preferredExamId = byExam.containsKey(selectedExam.id)
        ? selectedExam.id
        : byExam.keys.first;
    final ids = byExam[preferredExamId]!;
    final qs = await _questions.byIds(preferredExamId, ids);
    if (qs.isEmpty) return 'Saved items could not be loaded from the question bank.';

    final exam = ExamCatalog.byId(preferredExamId);
    selectedExam = exam;
    _beginLiveSession(
      questions: qs.take(20).toList(),
      exam: exam,
      focusArea: focusLabel,
      mode: SessionMode.review,
      difficulty: selectedDifficulty,
    );
    notifyListeners();
    return null;
  }

  void _beginLiveSession({
    required List<Question> questions,
    required ExamDefinition exam,
    required String focusArea,
    required SessionMode mode,
    required Difficulty difficulty,
  }) {
    viewingHistory = false;
    activeQuestions = questions;
    currentIndex = 0;
    selectedChoice = null;
    showTutor = false;
    answerRevealed = false;
    questionStartedAt = DateTime.now();
    activeSession = ExamSession(
      id: _uuid.v4(),
      examId: exam.id,
      examName: exam.shortName,
      difficulty: difficulty,
      focusArea: focusArea,
      mode: mode,
      questionIds: questions.map((q) => q.id).toList(),
      startedAt: DateTime.now(),
    );
  }

  Question get currentQuestion => activeQuestions[currentIndex];

  void choose(int index) {
    if (selectedChoice != null) return;
    selectedChoice = index;
    showTutor = false;
    answerRevealed = false;
    final q = currentQuestion;
    final seconds = questionStartedAt == null
        ? 0
        : DateTime.now().difference(questionStartedAt!).inSeconds;
    activeSession?.attempts.add(
      AnswerAttempt(
        questionId: q.id,
        subject: q.subject,
        topic: q.topic,
        selectedIndex: index,
        correctIndex: q.correctIndex,
        secondsSpent: seconds,
      ),
    );
    notifyListeners();
  }

  void revealAnswer() {
    if (selectedChoice == null || answerRevealed) return;
    answerRevealed = true;
    showTutor = true;
    notifyListeners();
  }

  Future<bool> next() async {
    if (currentIndex < activeQuestions.length - 1) {
      currentIndex++;
      selectedChoice = null;
      showTutor = false;
      answerRevealed = false;
      questionStartedAt = DateTime.now();
      notifyListeners();
      return false;
    }
    await completeSession();
    return true;
  }

  Future<void> completeSession() async {
    final session = activeSession;
    if (session == null) return;
    session.completedAt = DateTime.now();
    viewingHistory = false;
    lastHeatMap = _buildHeatMap(session.attempts);
    suggestedRemedial = lastHeatMap
        .where((t) => t.level != HeatLevel.mastered)
        .fold<TopicPerformance?>(null, (best, t) {
      if (best == null) return t;
      return t.percent < best.percent ? t : best;
    });
    await _sessions.save(session);
    history = await _sessions.loadAll();
    notifyListeners();
  }

  /// Reopen a completed session's pass stats / heat map from Home.
  void openHistorySession(ExamSession session) {
    viewingHistory = true;
    activeSession = session;
    activeQuestions = [];
    currentIndex = 0;
    selectedChoice = null;
    showTutor = false;
    answerRevealed = false;
    questionStartedAt = null;
    lastHeatMap = _buildHeatMap(session.attempts);
    suggestedRemedial = lastHeatMap
        .where((t) => t.level != HeatLevel.mastered)
        .fold<TopicPerformance?>(null, (best, t) {
      if (best == null) return t;
      return t.percent < best.percent ? t : best;
    });
    selectedExam = ExamCatalog.byId(session.examId);
    notifyListeners();
  }

  void clearHistoryView() {
    if (!viewingHistory) return;
    viewingHistory = false;
    activeSession = null;
    lastHeatMap = [];
    suggestedRemedial = null;
    notifyListeners();
  }

  List<TopicPerformance> _buildHeatMap(List<AnswerAttempt> attempts) {
    final map = <String, List<AnswerAttempt>>{};
    for (final a in attempts) {
      final key = '${a.subject}||${a.topic}';
      map.putIfAbsent(key, () => []).add(a);
    }
    return map.entries.map((e) {
      final parts = e.key.split('||');
      final list = e.value;
      final correct = list.where((a) => a.isCorrect).length;
      final avg = list.isEmpty
          ? 0.0
          : list.map((a) => a.secondsSpent).reduce((a, b) => a + b) /
              list.length;
      return TopicPerformance(
        subject: parts[0],
        topic: parts[1],
        correct: correct,
        total: list.length,
        avgSeconds: avg,
      );
    }).toList()
      ..sort((a, b) => a.percent.compareTo(b.percent));
  }

  Future<void> setExamDate(DateTime? date) async {
    examDate = date;
    await _usage.setExamDate(date);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    await _sessions.clear();
    history = [];
    lastHeatMap = [];
    suggestedRemedial = null;
    activeSession = null;
    activeQuestions = [];
    viewingHistory = false;
    notifyListeners();
  }

  Future<void> completeGuide() async {
    hasSeenGuide = true;
    await _usage.setGuideSeen(true);
    notifyListeners();
  }

  void abortActiveSession() {
    activeSession = null;
    activeQuestions = [];
    currentIndex = 0;
    selectedChoice = null;
    showTutor = false;
    answerRevealed = false;
    questionStartedAt = null;
    viewingHistory = false;
    notifyListeners();
  }

  int? get daysUntilExam {
    final d = examDate;
    if (d == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    return target.difference(today).inDays;
  }
}
