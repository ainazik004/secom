import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _kKey = 'theme_mode'; // 0=system, 1=light, 2=dark

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_kKey) ?? 0;
    _mode = ThemeMode.values[v.clamp(0, 2)];
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kKey, ThemeMode.values.indexOf(m));
  }

  Future<void> toggleLightDark() async {
    final next = (_mode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }
}
