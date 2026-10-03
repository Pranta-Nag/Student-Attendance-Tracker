import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentattendancetracker/app.dart';
import 'package:studentattendancetracker/core/theme/app_style.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/attendance_status.dart';
import 'package:studentattendancetracker/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:studentattendancetracker/features/attendance/presentation/providers/settings_provider.dart';
import 'package:studentattendancetracker/features/attendance/presentation/widgets/student_tile.dart';

/// Renders the whole app on a phone sized surface in every combination of
/// style and brightness, which is where layout overflows would show up.
void main() {
  const phone = Size(400, 780);

  Future<AttendanceProvider> pumpPhone(
    WidgetTester tester, {
    required SettingsProvider settings,
  }) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final attendance = AttendanceProvider()
      ..addStudents(
        const [
          'Bartholomew Fitzgerald-Montgomery',
          'Chen Wei',
          'Dalia Haddad',
          'Elias Novak',
        ],
        className: 'Grade 8 - A',
      )
      ..addStudents(
        const ['Fatima Zahra', 'Gabriel Santos', 'Hana Kobayashi'],
        className: 'Grade 8 - B',
      );
    attendance
      ..setStatus(attendance.students[0].id, AttendanceStatus.present)
      ..setStatus(attendance.students[1].id, AttendanceStatus.late)
      ..setStatus(attendance.students[2].id, AttendanceStatus.excused)
      ..selectDate(DateTime.now().subtract(const Duration(days: 1)))
      ..markAll(AttendanceStatus.present);

    await tester.pumpWidget(
      StudentAttendanceApp(provider: attendance, settings: settings),
    );
    await tester.pumpAndSettle();
    return attendance;
  }

  for (final style in AppStyle.values) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        '${style.label} in ${mode.name}: every tab fits a phone screen',
        (tester) async {
          final settings = SettingsProvider()
            ..setStyle(style)
            ..setThemeMode(mode);

          await pumpPhone(tester, settings: settings);

          expect(tester.takeException(), isNull);
          // The header cards scroll away, so only the first rows are built.
          expect(find.byType(StudentTile), findsAtLeastNWidgets(2));

          for (final tab in ['Reports', 'Settings', 'Register']) {
            await tester.tap(find.text(tab));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'on the $tab tab');
          }
        },
      );
    }
  }

  testWidgets('the detail sheet of a student fits a phone screen', (
    tester,
  ) async {
    final attendance = await pumpPhone(
      tester,
      settings: SettingsProvider(),
    );

    await tester.tap(find.byType(StudentTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Attendance for this lesson'), findsOneWidget);
    expect(find.text('Recent lessons'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(attendance.students, hasLength(7));
  });

  testWidgets('the filter sheet fits a phone screen', (tester) async {
    await pumpPhone(tester, settings: SettingsProvider());

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}