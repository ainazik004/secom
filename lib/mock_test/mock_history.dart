import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MockHistory {
  static const _key = 'mock_history_v1';
  static const int maxPerBucket = 400; // adjust

  /// bucketKey = "$lang/$section"
  final Map<String, List<String>> _ids;

  MockHistory(this._ids);

  static Future<MockHistory> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return MockHistory({});
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    final out = <String, List<String>>{};
    for (final e in map.entries) {
      out[e.key] = List<String>.from(e.value as List);
    }
    return MockHistory(out);
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(_ids));
  }

  Set<String> getRecentIds(String lang, String section) {
    final k = '$lang/$section';
    return Set<String>.from(_ids[k] ?? const []);
  }

  void addUsedIds(String lang, String section, List<String> ids) {
    final k = '$lang/$section';
    final list = List<String>.from(_ids[k] ?? const []);
    list.insertAll(0, ids);
    // dedupe preserving order
    final seen = <String>{};
    final deduped = <String>[];
    for (final id in list) {
      if (seen.add(id)) deduped.add(id);
      if (deduped.length >= maxPerBucket) break;
    }
    _ids[k] = deduped;
  }
}
