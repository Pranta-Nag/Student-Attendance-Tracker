import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentattendancetracker/core/theme/app_style.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/school_profile.dart';
import 'package:studentattendancetracker/features/attendance/presentation/providers/settings_provider.dart';

void main() {
  late SettingsProvider provider;

  setUp(() => provider = SettingsProvider());

  test('defaults to the classic interface and the system theme', () {
    expect(provider.style, AppStyle.classic);
    expect(provider.isClassic, isTrue);
    expect(provider.themeMode, ThemeMode.system);
    expect(provider.profile, const SchoolProfile());
  });

  test('defaultClassName falls back to the general class', () {
    expect(provider.defaultClassName, 'General');

    provider.updateProfile(const SchoolProfile(section: 'Grade 8 - B'));

    expect(provider.defaultClassName, 'Grade 8 - B');
  });

  test('updateProfile notifies once and ignores identical values', () {
    var notifications = 0;
    provider.addListener(() => notifications++);

    provider.updateProfile(const SchoolProfile(schoolName: 'Riverside'));
    expect(notifications, 1);
    expect(provider.schoolName, 'Riverside');

    provider.updateProfile(const SchoolProfile(schoolName: 'Riverside'));
    expect(notifications, 1);
  });

  test('setStyle and setThemeMode only notify on a change', () {
    var notifications = 0;
    provider.addListener(() => notifications++);

    provider
      ..setStyle(AppStyle.modern)
      ..setStyle(AppStyle.modern)
      ..setThemeMode(ThemeMode.dark)
      ..setThemeMode(ThemeMode.dark);

    expect(notifications, 2);
    expect(provider.isClassic, isFalse);
    expect(provider.themeMode, ThemeMode.dark);
  });

  test('cycleThemeMode walks system, light and dark', () {
    expect(provider.themeMode, ThemeMode.system);

    provider
      ..cycleThemeMode()
      ..cycleThemeMode()
      ..cycleThemeMode();

    expect(provider.themeMode, ThemeMode.system);
  });

  test('reset restores the shipped defaults', () {
    provider
      ..updateProfile(const SchoolProfile(schoolName: 'Riverside'))
      ..setStyle(AppStyle.modern)
      ..setThemeMode(ThemeMode.dark)
      ..reset();

    expect(provider.profile, const SchoolProfile());
    expect(provider.style, AppStyle.classic);
    expect(provider.themeMode, ThemeMode.system);
  });

  group('AppStyle', () {
    test('resolves a stored name and falls back to classic', () {
      expect(AppStyle.fromName('modern'), AppStyle.modern);
      expect(AppStyle.fromName('nope'), AppStyle.classic);
      expect(AppStyle.fromName(null), AppStyle.classic);
    });
  });
}