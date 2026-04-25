import 'package:flutter/material.dart';

/// In-memory theme preference (System / Light / Dark) for QA and user choice.
/// Does not affect Firestore business settings.
class ThemeModeController extends ChangeNotifier {
  ThemeModeController([ThemeMode initial = ThemeMode.system]) : _mode = initial;

  ThemeMode _mode;

  ThemeMode get themeMode => _mode;

  void setThemeMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}
