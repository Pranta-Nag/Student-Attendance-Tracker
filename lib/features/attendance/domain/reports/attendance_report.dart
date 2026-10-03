import 'package:meta/meta.dart';

import '../../../../core/utils/date_formats.dart';
import '../models/attendance_day.dart';
import '../models/attendance_stats.dart';
import '../models/attendance_status.dart';
import '../models/school_profile.dart';
import '../models/student.dart';

/// Attendance counters for one section.
@immutable
class ClassSummary {
  const ClassSummary({required this.className, required this.stats});

  final String className;
  final AttendanceStats stats;

  int get total => stats.total;
  int get attended => stats.attended;
  int get absent => stats.absent;
  double get rate => stats.attendanceRate;
  int get percent => stats.attendancePercent;
}

/// Per student totals across every recorded day.
@immutable
class StudentSummary {
  const StudentSummary({
    required this.student,
    required this.daysRecorded,
    required this.present,
    required this.late,
    required this.excused,
    required this.absent,
  });

  final Student student;

  /// Days on which the student carries an explicit mark.
  final int daysRecorded;
  final int present;
  final int late;
  final int excused;
  final int absent;

  int get attended => present + late;

  double get attendanceRate => daysRecorded == 0 ? 0 : attended / daysRecorded;

  int get attendancePercent => (attendanceRate * 100).round();
}

/// One bar of the trend chart.
@immutable
class DailyPoint {
  const DailyPoint({required this.date, required this.stats});

  final DateTime date;
  final AttendanceStats stats;

  String get label => formatDayMonth(date);
  double get rate => stats.attendanceRate;
}

/// Aggregated view of the register: the selected day, a per section split,
/// per student totals and a short trend. Everything is derived, never stored.
@immutable
class AttendanceReport {
  const AttendanceReport({
    required this.selectedDay,
    required this.classes,
    required this.students,
    required this.trend,
    required this.recordedDays,
  });

  /// Attendance rate below which a student is flagged as needing support.
  static const double attentionThreshold = 0.75;

  /// Builds the report from the roster and every recorded day.
  ///
  /// [days] may be in any order; only days carrying marks contribute to the
  /// student totals and to the trend.
  factory AttendanceReport.build({
    required List<Student> students,
    required List<AttendanceDay> days,
    required AttendanceDay selectedDay,
    int trendDays = 7,
  }) {
    final recorded = days.where((day) => day.hasMarks).toList()
      ..sort(compareDaysDescending);

    return AttendanceReport(
      selectedDay: selectedDay,
      recordedDays: recorded.length,
      classes: _classSummaries(students, selectedDay),
      students: _studentSummaries(students, recorded),
      trend: recorded
          .take(trendDays)
          .map((day) => DailyPoint(date: day.date, stats: day.stats))
          .toList(growable: false),
    );
  }

  final AttendanceDay selectedDay;

  /// One entry per section, sorted by attendance rate descending.
  final List<ClassSummary> classes;

  /// One entry per student, weakest attendance first.
  final List<StudentSummary> students;

  /// Most recent days first, at most [AttendanceReport.build]'s `trendDays`.
  final List<DailyPoint> trend;

  /// Number of days on which at least one mark was recorded.
  final int recordedDays;

  bool get isEmpty => students.isEmpty;

  /// Students below [attentionThreshold], weakest first.
  List<StudentSummary> get atRisk => students
      .where((entry) => entry.attendanceRate < attentionThreshold)
      .toList();

  /// Average attendance across the recorded days.
  double get averageRate {
    final days = recordedDays;
    if (days == 0) return 0;
    final sum = trend.fold<double>(0, (acc, point) => acc + point.rate);
    final covered = trend.length;
    return covered == 0 ? 0 : sum / covered;
  }

  /// Renders the register as CSV, ready to be shared or pasted into a sheet.
  String toCsv({SchoolProfile profile = const SchoolProfile()}) {
    final buffer = StringBuffer()
      ..writeln('${_cell('School')},${_cell(profile.schoolName)}')
      ..writeln('${_cell('Section')},${_cell(profile.section)}')
      ..writeln('${_cell('Teacher')},${_cell(profile.teacher)}')
      ..writeln('${_cell('Academic year')},${_cell(profile.academicYear)}')
      ..writeln()
      ..writeln('Roll,Student,Class,Present,Late,Excused,Absent,'
          'Days Recorded,Attendance Rate');
    for (final entry in students) {
      buffer.writeln([
        entry.student.rollNumber > 0 ? entry.student.rollNumber : '',
        _cell(entry.student.name),
        _cell(entry.student.className),
        entry.present,
        entry.late,
        entry.excused,
        entry.absent,
        entry.daysRecorded,
        '${entry.attendancePercent}%',
      ].join(','));
    }

    buffer
      ..writeln()
      ..writeln('Date,Present,Late,Excused,Absent,Total,Attendance Rate');
    for (final point in trend.reversed) {
      buffer.writeln([
        formatFullDate(point.date),
        point.stats.present,
        point.stats.late,
        point.stats.excused,
        point.stats.absent,
        point.stats.total,
        '${point.stats.attendancePercent}%',
      ].join(','));
    }

    return buffer.toString();
  }

  /// Splits the roster per section using the marks of the selected day, so the
  /// caller never has to resolve the roster beforehand.
  static List<ClassSummary> _classSummaries(
    List<Student> students,
    AttendanceDay selectedDay,
  ) {
    final byClass = <String, List<Student>>{};
    for (final student in students) {
      final resolved = student.copyWith(
        status: selectedDay.marks[student.id] ?? AttendanceStatus.absent,
      );
      byClass.putIfAbsent(resolved.className, () => <Student>[]).add(resolved);
    }

    final summaries = byClass.entries
        .map(
          (entry) => ClassSummary(
            className: entry.key,
            stats: AttendanceStats.fromStudents(entry.value),
          ),
        )
        .toList();

    summaries.sort((a, b) {
      final byRate = b.rate.compareTo(a.rate);
      return byRate != 0 ? byRate : a.className.compareTo(b.className);
    });
    return summaries;
  }

  static List<StudentSummary> _studentSummaries(
    List<Student> students,
    List<AttendanceDay> days,
  ) {
    final summaries = <StudentSummary>[];

    for (final student in students) {
      var present = 0;
      var late = 0;
      var excused = 0;
      var absent = 0;
      var recorded = 0;

      for (final day in days) {
        final mark = day.marks[student.id];
        if (mark == null) continue;
        recorded++;
        switch (mark) {
          case AttendanceStatus.present:
            present++;
          case AttendanceStatus.late:
            late++;
          case AttendanceStatus.excused:
            excused++;
          case AttendanceStatus.absent:
            absent++;
        }
      }

      summaries.add(
        StudentSummary(
          student: student,
          daysRecorded: recorded,
          present: present,
          late: late,
          excused: excused,
          absent: absent,
        ),
      );
    }

    summaries.sort((a, b) {
      final byRate = a.attendanceRate.compareTo(b.attendanceRate);
      if (byRate != 0) return byRate;
      final byName =
          a.student.name.toLowerCase().compareTo(b.student.name.toLowerCase());
      return byName != 0 ? byName : a.student.rollNumber - b.student.rollNumber;
    });
    return summaries;
  }

  static String _cell(String value) =>
      value.contains(',') || value.contains('"')
          ? '"${value.replaceAll('"', '""')}"'
          : value;
}