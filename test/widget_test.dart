import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exmr/data/exam_catalog.dart';
import 'package:exmr/data/question_repository.dart';
import 'package:exmr/domain/models/models.dart';
import 'package:exmr/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('catalog is Philippine-only', () {
    expect(ExamCatalog.country, 'Philippines');
    expect(ExamCatalog.region, 'PH');
    expect(ExamCatalog.exams, isNotEmpty);
    for (final exam in ExamCatalog.exams) {
      expect(exam.regulator, anyOf('PRC', 'CSC'));
      expect(exam.assetPath, contains('assets/questions/'));
    }
  });

  test('question banks load as Philippine-only', () async {
    final repo = QuestionRepository();
    for (final exam in ExamCatalog.exams) {
      final qs = await repo.loadExam(exam.id);
      expect(qs, isNotEmpty, reason: 'Empty bank for ${exam.id}');
      for (final q in qs) {
        expect(q.country, 'Philippines');
        expect(q.region, 'PH');
        expect(q.examId, exam.id);
      }
    }
  });

  test('app state init marks ready', () async {
    final state = AppState();
    await state.init();
    expect(state.bootError, isNull, reason: '${state.bootError}');
    expect(state.ready, isTrue);
  });

  test('difficulty pools are reasonably full per exam', () async {
    final repo = QuestionRepository();
    for (final exam in ExamCatalog.exams) {
      final counts = await repo.difficultyCounts(exam.id);
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      expect(total, greaterThanOrEqualTo(45), reason: '${exam.id} total $total');
      for (final d in Difficulty.values) {
        expect(
          counts[d]!,
          greaterThanOrEqualTo(10),
          reason: '${exam.id} ${d.name}=${counts[d]}',
        );
      }
    }
  });
}
