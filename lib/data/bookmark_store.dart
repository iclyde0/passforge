import 'package:shared_preferences/shared_preferences.dart';

/// Persists bookmarked question keys as `examId|questionId`.
class BookmarkStore {
  static const _key = 'bookmarked_question_keys_v1';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  static String keyFor(String examId, String questionId) => '$examId|$questionId';

  Future<Set<String>> loadAll() async {
    try {
      final p = await _prefs;
      return (p.getStringList(_key) ?? const []).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> saveAll(Set<String> keys) async {
    try {
      final p = await _prefs;
      await p.setStringList(_key, keys.toList()..sort());
    } catch (_) {}
  }

  Future<Set<String>> toggle(String examId, String questionId) async {
    final keys = await loadAll();
    final key = keyFor(examId, questionId);
    if (keys.contains(key)) {
      keys.remove(key);
    } else {
      keys.add(key);
    }
    await saveAll(keys);
    return keys;
  }
}
