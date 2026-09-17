import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/models/models.dart';

class SessionStore {
  static const _fileName = 'exmr_sessions.json';

  bool get _disabled => Platform.environment.containsKey('FLUTTER_TEST');

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<ExamSession>> loadAll() async {
    if (_disabled) return [];
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ExamSession.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> save(ExamSession session) async {
    if (_disabled) return;
    try {
      final all = await loadAll();
      final idx = all.indexWhere((s) => s.id == session.id);
      if (idx >= 0) {
        all[idx] = session;
      } else {
        all.insert(0, session);
      }
      final trimmed = all.take(40).toList();
      final file = await _file();
      await file.writeAsString(
        jsonEncode(trimmed.map((s) => s.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> clear() async {
    if (_disabled) return;
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
