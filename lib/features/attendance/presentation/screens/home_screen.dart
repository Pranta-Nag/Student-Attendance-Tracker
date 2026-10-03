import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../actions/report_actions.dart';
import '../actions/roster_actions.dart';
import '../actions/settings_actions.dart';
import '../providers/attendance_provider.dart';
import '../providers/settings_provider.dart';
import 'attendance_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

/// Classic shell: a solid app bar, a filled bottom bar and three tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const List<String> _titles = ['Register', 'Reports', 'Settings'];

  static const List<({IconData icon, IconData selected, String label})>
      _destinations = [
    (
      icon: Icons.how_to_reg_outlined,
      selected: Icons.how_to_reg_rounded,
      label: 'Register'
    ),
    (
      icon: Icons.insights_outlined,
      selected: Icons.insights_rounded,
      label: 'Reports'
    ),
    (
      icon: Icons.settings_outlined,
      selected: Icons.settings_rounded,
      label: 'Settings'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final attendance = context.watch<AttendanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          ..._actionsFor(context, attendance, settings),
          IconButton(
            icon: Icon(_themeIcon(settings.themeMode)),
            tooltip: 'Theme: ${settings.themeMode.name}',
            onPressed: settings.cycleThemeMode,
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          AttendanceScreen(),
          ReportsScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => addStudentFlow(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add student'),
            )
          : null,
      bottomNavigationBar: settings.isClassic
          ? _classicNavigationBar()
          : _modernNavigationBar(),
    );
  }

  List<Widget> _actionsFor(
    BuildContext context,
    AttendanceProvider attendance,
    SettingsProvider settings,
  ) {
    return switch (_index) {
      0 => [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all present',
            onPressed: attendance.hasStudents
                ? () => markAllPresentFlow(context)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded),
            tooltip: 'Add several students',
            onPressed: () => addStudentsBulkFlow(context),
          ),
          PopupMenuButton<_LessonAction>(
            tooltip: 'Lesson options',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => _onLessonAction(context, action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _LessonAction.today,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.today_rounded),
                  title: Text('Go to today'),
                ),
              ),
              const PopupMenuItem(
                value: _LessonAction.rollOver,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.content_copy_rounded),
                  title: Text('Copy previous lesson'),
                ),
              ),
              const PopupMenuItem(
                value: _LessonAction.markAllAbsent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.playlist_remove_rounded),
                  title: Text('Clear and mark absent'),
                ),
              ),
              const PopupMenuItem(
                value: _LessonAction.clearLesson,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.restart_alt_rounded),
                  title: Text('Clear this lesson'),
                ),
              ),
            ],
          ),
        ],
      1 => [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Copy report as CSV',
            onPressed: () => exportReportFlow(context),
          ),
        ],
      _ => [
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: 'Edit school details',
            onPressed: () => editSchoolProfileFlow(context),
          ),
        ],
    };
  }

  void _onLessonAction(BuildContext context, _LessonAction action) {
    switch (action) {
      case _LessonAction.today:
        context.read<AttendanceProvider>().selectToday();
      case _LessonAction.rollOver:
        rollOverFlow(context);
      case _LessonAction.markAllAbsent:
        markAllAbsentFlow(context);
      case _LessonAction.clearLesson:
        clearLessonFlow(context);
    }
  }

  static IconData _themeIcon(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
      };

  Widget _classicNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _index,
      onTap: (index) => setState(() => _index = index),
      items: [
        for (final destination in _destinations)
          BottomNavigationBarItem(
            icon: Icon(destination.icon),
            activeIcon: Icon(destination.selected),
            label: destination.label,
          ),
      ],
    );
  }

  Widget _modernNavigationBar() {
    final theme = Theme.of(context);
    return NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (index) => setState(() => _index = index),
      backgroundColor: theme.colorScheme.surfaceContainer,
      destinations: [
        for (final destination in _destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selected),
            label: destination.label,
          ),
      ],
    );
  }
}

enum _LessonAction { today, rollOver, markAllAbsent, clearLesson }