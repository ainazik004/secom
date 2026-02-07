import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mock_models.dart';

class MockAttemptStore {
  static const _key = 'active_mock_attempt_v1';

  Future<void> save(MockAttempt attempt) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(attempt.toJson()));
  }

  Future<MockAttempt?> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return null;
    return MockAttempt.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}
