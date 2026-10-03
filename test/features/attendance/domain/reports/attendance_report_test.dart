import 'package:flutter_test/flutter_test.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/attendance_day.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/attendance_status.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/school_profile.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/student.dart';
import 'package:studentattendancetracker/features/attendance/domain/reports/attendance_report.dart';

void main() {
  const ada = Student(id: '1', name: 'Ada Lovelace', className: '8A', rollNumber: 1);
  const grace = Student(
    id: '2',
    name: 'Grace Hopper',
    className: '8A',
    rollNumber: 2,
  );
  const chen = Student(
    id: '3',
    name: 'Chen, Wei',
    className: '8B',
    rollNumber: 1,
  );

  AttendanceDay day(int dayOfMonth, Map<String, AttendanceStatus> marks) =>
      AttendanceDay.resolve(
        date: DateTime(2026, 3, dayOfMonth),
        marks: marks,
        students: const [ada, grace, chen],
      );

  final monday = day(2, const {
    '1': AttendanceStatus.present,
    '2': AttendanceStatus.present,
    '3': AttendanceStatus.absent,
  });
  final tuesday = day(3, const {
    '1': AttendanceStatus.present,
    '2': AttendanceStatus.late,
    '3': AttendanceStatus.excused,
  });

  final report = AttendanceReport.build(
    students: const [ada, grace, chen],
    days: [monday, tuesday],
    selectedDay: tuesday,
  );

  group('AttendanceReport', () {
    test('exposes the counters of the selected lesson', () {
      expect(report.selectedDay.key, '2026-03-03');
      expect(report.selectedDay.stats.total, 3);
      expect(report.selectedDay.stats.present, 1);
      expect(report.selectedDay.stats.late, 1);
      expect(report.selectedDay.stats.excused, 1);
    });

    test('counts only the lessons that carry marks', () {
      final withEmptyDay = AttendanceReport.build(
        students: const [ada],
        days: [monday, day(4, const {})],
        selectedDay: monday,
      );

      expect(report.recordedDays, 2);
      expect(withEmptyDay.recordedDays, 1);
    });

    test('splits the roster per class, best rate first', () {
      expect(report.classes.map((entry) => entry.className), ['8A', '8B']);
      expect(report.classes.first.total, 2);
      expect(report.classes.first.rate, 1);
      expect(report.classes.last.rate, 0);
    });

    test('ranks students by attendance, weakest first', () {
      expect(
        report.students.map((entry) => entry.student.name),
        ['Chen, Wei', 'Ada Lovelace', 'Grace Hopper'],
        reason: 'Ada and Grace both attend every lesson, so the name decides',
      );
    });

    test('student totals add up over the recorded lessons', () {
      final graceEntry = report.students
          .firstWhere((entry) => entry.student.name == 'Grace Hopper');

      expect(graceEntry.daysRecorded, 2);
      expect(graceEntry.present, 1);
      expect(graceEntry.late, 1);
      expect(graceEntry.attendanceRate, 1);
      expect(graceEntry.attendancePercent, 100);
    });

    test('flags the students below the attention threshold', () {
      expect(report.atRisk.map((entry) => entry.student.name), ['Chen, Wei']);
      expect(AttendanceReport.attentionThreshold, 0.75);
    });

    test('the trend is capped and ordered newest first', () {
      final days = [
        for (var index = 1; index <= 10; index++)
          day(index, const {'1': AttendanceStatus.present}),
      ];
      final long = AttendanceReport.build(
        students: const [ada],
        days: days,
        selectedDay: days.first,
      );

      expect(long.trend, hasLength(7));
      expect(long.trend.first.date, DateTime(2026, 3, 10));
      expect(long.trend.last.date, DateTime(2026, 3, 4));
    });

    test('an empty roster produces an empty report', () {
      final empty = AttendanceReport.build(
        students: const [],
        days: const [],
        selectedDay: day(3, const {}),
      );

      expect(empty.isEmpty, isTrue);
      expect(empty.classes, isEmpty);
      expect(empty.averageRate, 0);
    });

    test('exports CSV with the profile header and the tables', () {
      final csv = report.toCsv(
        profile: const SchoolProfile(
          schoolName: 'Riverside High',
          section: 'Grade 8',
          teacher: 'Ms. Okafor',
          academicYear: '2026 / 2027',
        ),
      );
      final lines = csv.trim().split('\n');

      expect(lines.first, 'School,Riverside High');
      expect(csv, contains('Roll,Student,Class,Present,Late,Excused,Absent,'));
      expect(csv, contains('1,Ada Lovelace,8A,2,0,0,0,2,100%'));
      expect(csv, contains('"Chen, Wei"'), reason: 'commas are escaped');
      expect(csv, contains('Date,Present,Late,Excused,Absent,Total,'));
    });
  });
}