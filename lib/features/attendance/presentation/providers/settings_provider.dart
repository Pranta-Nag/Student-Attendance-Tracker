import 'package:flutter/material.dart';

import '../../../../core/theme/app_style.dart';
import '../../domain/models/school_profile.dart';

/// Holds the preferences that describe *the school* and *the teacher* rather
/// than a single lesson: who is taking the register, and how the app is painted.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    SchoolProfile profile = const SchoolProfile(),
    AppStyle style = AppStyle.classic,
    ThemeMode themeMode = ThemeMode.system,
  }) {
    _profile = profile;
    _style = style;
    _themeMode = themeMode;
  }

  SchoolProfile _profile = const SchoolProfile();
  AppStyle _style = AppStyle.classic;
  ThemeMode _themeMode = ThemeMode.system;

  SchoolProfile get profile => _profile;

  /// Classic or Material 3 presentation.
  AppStyle get style => _style;

  bool get isClassic => _style == AppStyle.classic;

  ThemeMode get themeMode => _themeMode;

  String get schoolName => _profile.schoolName;

  String get section => _profile.section;

  /// Section to preselect when adding a student.
  String get defaultClassName =>
      _profile.section.isEmpty ? 'General' : _profile.section;

  void updateProfile(SchoolProfile profile) {
    if (profile == _profile) return;
    _profile = profile;
    notifyListeners();
  }

  void setStyle(AppStyle style) {
    if (style == _style) return;
    _style = style;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
  }

  /// Cycles system → light → dark, handy for a single tap in the app bar.
  void cycleThemeMode() {
    _themeMode = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    notifyListeners();
  }

  /// Restores the shipped defaults.
  void reset() {
    _profile = const SchoolProfile();
    _style = AppStyle.classic;
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}