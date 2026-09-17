import 'package:shared_preferences/shared_preferences.dart';

class UsageStore {
  static const freeDailySimulations = 1;
  static const freeQuestionCount = 20;
  static const premiumQuestionCount = 50;

  static const _simDateKey = 'free_sim_date';
  static const _simCountKey = 'free_sim_count';
  static const _examDateKey = 'exam_date_iso';
  static const _guideSeenKey = 'user_guide_seen_v1';
  static const _textScaleKey = 'a11y_text_scale_v1';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<bool> hasSeenGuide() async {
    try {
      final p = await _prefs;
      return p.getBool(_guideSeenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setGuideSeen(bool seen) async {
    try {
      final p = await _prefs;
      await p.setBool(_guideSeenKey, seen);
    } catch (_) {}
  }

  Future<int> simulationsUsedToday() async {
    try {
      final p = await _prefs;
      final date = p.getString(_simDateKey);
      if (date != _today()) return 0;
      return p.getInt(_simCountKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> canStartFreeSimulation() async {
    return (await simulationsUsedToday()) < freeDailySimulations;
  }

  Future<void> recordSimulationStart() async {
    try {
      final p = await _prefs;
      final today = _today();
      if (p.getString(_simDateKey) != today) {
        await p.setString(_simDateKey, today);
        await p.setInt(_simCountKey, 1);
      } else {
        await p.setInt(_simCountKey, (p.getInt(_simCountKey) ?? 0) + 1);
      }
    } catch (_) {}
  }

  Future<DateTime?> getExamDate() async {
    try {
      final p = await _prefs;
      final raw = p.getString(_examDateKey);
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> setExamDate(DateTime? date) async {
    try {
      final p = await _prefs;
      if (date == null) {
        await p.remove(_examDateKey);
      } else {
        await p.setString(_examDateKey, date.toIso8601String());
      }
    } catch (_) {}
  }

  Future<double> getTextScale() async {
    try {
      final p = await _prefs;
      final v = p.getDouble(_textScaleKey);
      if (v == null) return 1.0;
      return v.clamp(1.0, 1.45);
    } catch (_) {
      return 1.0;
    }
  }

  Future<void> setTextScale(double scale) async {
    try {
      final p = await _prefs;
      await p.setDouble(_textScaleKey, scale.clamp(1.0, 1.45));
    } catch (_) {}
  }
}
