import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const _modeKey = 'theme_mode';
  static const _seedKey = 'theme_seed';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Color _seed = Colors.blue;
  Color get seed => _seed;

  /// Loads persisted theme prefs. Call once before runApp so the first frame
  /// renders with the saved theme instead of the defaults.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_modeKey);
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < ThemeMode.values.length) {
      _mode = ThemeMode.values[modeIndex];
    }
    final seedValue = prefs.getInt(_seedKey);
    if (seedValue != null) {
      _seed = Color(seedValue);
    }
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_modeKey, _mode.index);
  }

  Future<void> setSeed(Color color) async {
    if (color == _seed) return;
    _seed = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedKey, _seed.toARGB32());
  }
}
