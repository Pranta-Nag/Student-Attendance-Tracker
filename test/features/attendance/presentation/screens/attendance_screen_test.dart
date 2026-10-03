import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentattendancetracker/app.dart';
import 'package:studentattendancetracker/core/theme/app_style.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/roster_filter.dart';
import 'package:studentattendancetracker/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:studentattendancetracker/features/attendance/presentation/providers/settings_provider.dart';
import 'package:studentattendancetracker/features/attendance/presentation/widgets/student_tile.dart';

/// Scopes a text finder to the status chips of the roster rows, so it does not
/// collide with the identically named stat tiles.
Finder statusChip(String label) => find.descendant(
      of: find.byType(StudentTile),
      matching: find.text(label),
    );

void main() {
  Future<AttendanceProvider> pumpApp(
    WidgetTester tester, {
    SettingsProvider? settings,
  }) async {
    final provider = AttendanceProvider();
    await tester.pumpWidget(
      StudentAttendanceApp(provider: provider, settings: settings),
    );
    return provider;
  }

  Future<void> addStudent(WidgetTester tester, String name) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), name);
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
  }

  /// Scrolls a row action into view: the extended FAB floats above the bottom
  /// right corner of the list on the small test surface.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  group('empty state', () {
    testWidgets('shows guidance when there are no students', (tester) async {
      await pumpApp(tester);

      expect(find.text('No students yet'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(StudentTile), findsNothing);
      expect(find.text('Load a sample class'), findsOneWidget);
    });

    testWidgets('the empty state CTA opens the add dialog', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add student'));
      await tester.pumpAndSettle();

      expect(find.text('Add student'), findsWidgets);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('The roll number is assigned automatically.'),
          findsOneWidget);
    });

    testWidgets('the sample shortcut fills the roster', (tester) async {
      final provider = await pumpApp(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Load a sample class'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Load'));
      await tester.pumpAndSettle();

      expect(provider.students, hasLength(8));
      expect(find.text('No students yet'), findsNothing);
      expect(find.text('Total'), findsOneWidget);
    });
  });

  group('add student', () {
    testWidgets('a new student appears in the list as absent', (
      tester,
    ) async {
      final provider = await pumpApp(tester);

      await addStudent(tester, 'Ada Lovelace');

      expect(provider.students.single.name, 'Ada Lovelace');
      expect(provider.students.single.rollNumber, 1);
      expect(find.text('No students yet'), findsNothing);
      await reveal(tester, statusChip('Absent'));
      expect(statusChip('Absent'), findsOneWidget);
    });

    testWidgets('an empty name is rejected by the dialog', (tester) async {
      final provider = await pumpApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Student name cannot be empty'), findsOneWidget);
      expect(provider.students, isEmpty);
    });

    testWidgets('cancelling adds nothing', (tester) async {
      final provider = await pumpApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Ada');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(provider.students, isEmpty);
      expect(find.byType(TextFormField), findsNothing);
    });
  });

  group('mark attendance', () {
    testWidgets('checking the box marks present and updates stats', (
      tester,
    ) async {
      final provider = await pumpApp(tester);
      await addStudent(tester, 'Ada');
      await addStudent(tester, 'Grace');

      await reveal(tester, find.byType(Checkbox).first);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(provider.students.first.isPresent, isTrue);
      expect(statusChip('Present'), findsOneWidget);
      expect(find.text('50% attendance recorded'), findsOneWidget);
    });

    testWidgets('unchecking marks absent again', (tester) async {
      final provider = await pumpApp(tester);
      await addStudent(tester, 'Ada');

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(provider.students.single.isPresent, isTrue);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(provider.students.single.isPresent, isFalse);
      expect(find.text('0% attendance recorded'), findsOneWidget);
    });

    testWidgets('marking only the unmarked students keeps existing marks', (
      tester,
    ) async {
      final provider = await pumpApp(tester);
      await addStudent(tester, 'Ada');
      await addStudent(tester, 'Grace');

      await reveal(tester, find.byType(Checkbox).first);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.done_all_rounded));
      await tester.pumpAndSettle();

      // The second "mark all" only fills the gap, it never overwrites.
      expect(provider.students.every((student) => student.isPresent), isTrue);
    });
  });

  group('remove student', () {
    testWidgets('the delete icon removes the student and updates stats', (
      tester,
    ) async {
      final provider = await pumpApp(tester);
      await addStudent(tester, 'Ada');
      await addStudent(tester, 'Grace');
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      await reveal(tester, find.byIcon(Icons.delete_outline_rounded).first);
      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Ada'), findsNothing);
      expect(provider.students.single.name, 'Grace');
      expect(provider.stats.total, 1);
      expect(find.text('Ada removed'), findsOneWidget);
    });

    testWidgets('undo restores the removed student', (tester) async {
      final provider = await pumpApp(tester);
      await addStudent(tester, 'Ada');
      await addStudent(tester, 'Grace');

      await reveal(tester, find.byIcon(Icons.delete_outline_rounded).first);
      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(provider.students, hasLength(2));
      expect(find.text('Ada'), findsOneWidget);
    });

    testWidgets('deleting the last student shows the empty state', (
      tester,
    ) async {
      await pumpApp(tester);
      await addStudent(tester, 'Ada');

      await reveal(tester, find.byIcon(Icons.delete_outline_rounded));
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('No students yet'), findsOneWidget);
    });
  });

  group('filters', () {
    testWidgets('the search field narrows the roster', (tester) async {
      final provider = await pumpApp(tester);
      await addStudent(tester, 'Ada');
      await addStudent(tester, 'Grace');

      await tester.enterText(find.byType(TextField), 'gra');
      await tester.pumpAndSettle();

      expect(find.text('Grace'), findsOneWidget);
      expect(find.text('Ada'), findsNothing);
      expect(provider.filter.query, 'gra');
    });

    testWidgets('a query without matches offers to clear the filters', (
      tester,
    ) async {
      final provider = await pumpApp(tester);
      await addStudent(tester, 'Ada');

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No student matches the filters'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Clear filters'));
      await tester.pumpAndSettle();

      expect(provider.filter.isActive, isFalse);
      expect(find.text('Ada'), findsOneWidget);
    });
  });

  group('lesson navigation', () {
    testWidgets('the previous day action switches the lesson', (tester) async {
      final provider = await pumpApp(tester);
      await addStudent(tester, 'Ada');
      provider.setAttendance(provider.students.single.id, true);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(provider.isSelectedDayToday, isFalse);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(provider.students.single.isPresent, isFalse);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      expect(provider.isSelectedDayToday, isTrue);
      expect(provider.students.single.isPresent, isTrue);
    });

    testWidgets('copying the previous lesson fills the current day', (
      tester,
    ) async {
      final provider = await pumpApp(tester);
      await addStudent(tester, 'Ada');
      await addStudent(tester, 'Grace');
      provider.markAllPresent();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go to today'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(provider.stats.present, 0);

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy previous lesson'));
      await tester.pumpAndSettle();

      expect(provider.stats.present, 2);
      expect(find.text('Copied 2 marks from the previous lesson'),
          findsOneWidget);
    });
  });

  group('reports tab', () {
    testWidgets('summarises the register and exports it', (tester) async {
      final provider = await pumpApp(tester);
      await addStudent(tester, 'Ada');
      provider.markAllPresent();

      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();

      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Lessons recorded'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.ios_share_rounded));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Report copied to the clipboard'),
        findsOneWidget,
      );
    });
  });

  group('settings tab', () {
    testWidgets('switches between the classic and the modern interface', (
      tester,
    ) async {
      final settings = SettingsProvider();
      await pumpApp(tester, settings: settings);
      await addStudent(tester, 'Ada');

      expect(settings.isClassic, isTrue);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modern'));
      await tester.pumpAndSettle();

      expect(settings.style, AppStyle.modern);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('edits the school profile shown on the register', (
      tester,
    ) async {
      final settings = SettingsProvider();
      final provider = await pumpApp(tester, settings: settings);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.school_outlined).last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'School name'),
        'Riverside High',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(settings.schoolName, 'Riverside High');

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Riverside High'), findsOneWidget);
      expect(provider.totalStudents, 1);
    });
  });

  testWidgets('UI is rebuilt from provider notifications alone',
      (tester) async {
    final provider = await pumpApp(tester);
    expect(find.text('No students yet'), findsOneWidget);

    provider.addStudent('Ada');
    await tester.pump();

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('No students yet'), findsNothing);
  });

  testWidgets('mark-all-present updates the whole roster', (tester) async {
    final provider = await pumpApp(tester);
    await addStudent(tester, 'Ada');
    await addStudent(tester, 'Grace');

    await tester.tap(find.byIcon(Icons.done_all_rounded));
    await tester.pumpAndSettle();

    expect(provider.students.every((student) => student.isPresent), isTrue);
    expect(find.text('100% attendance recorded'), findsOneWidget);
  });

  testWidgets('the filter sheet changes the status filter', (tester) async {
    final provider = await pumpApp(tester);
    await addStudent(tester, 'Ada');
    await addStudent(tester, 'Grace');
    provider.markAllPresent();

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Absent'));
    await tester.pumpAndSettle();

    expect(provider.filter.status, StatusFilter.absent);
    expect(find.byType(StudentTile), findsNothing);
  });
}