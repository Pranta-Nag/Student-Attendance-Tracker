import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/attendance/presentation/providers/attendance_provider.dart';
import 'features/attendance/presentation/providers/settings_provider.dart';
import 'features/attendance/presentation/screens/home_screen.dart';

/// Composition root: the only place where the providers are instantiated and
/// exposed to the widget tree via [MultiProvider].
class StudentAttendanceApp extends StatelessWidget {
  const StudentAttendanceApp({super.key, this.provider, this.settings});

  /// Injectable for tests; a default instance is created in production.
  final AttendanceProvider? provider;
  final SettingsProvider? settings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AttendanceProvider>(
          create: (_) => provider ?? AttendanceProvider(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => settings ?? SettingsProvider(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, preferences, _) {
          final themes = AppTheme.forStyle(preferences.style);
          return MaterialApp(
            title: 'School Attendance',
            debugShowCheckedModeBanner: false,
            theme: themes.light,
            darkTheme: themes.dark,
            themeMode: preferences.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}