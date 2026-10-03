import 'package:meta/meta.dart';

import 'attendance_status.dart';
import 'student.dart';

/// Aggregate view over a set of students, always derived from the source data
/// so it can never drift out of sync with the roster.
@immutable
class AttendanceStats {
  const AttendanceStats({
    required this.total,
    required this.present,
    required this.absent,
    this.late = 0,
    this.excused = 0,
  });

  factory AttendanceStats.fromStudents(Iterable<Student> students) {
    var present = 0;
    var late = 0;
    var excused = 0;
    var total = 0;

    for (final student in students) {
      total++;
      switch (student.status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.late:
          late++;
        case AttendanceStatus.excused:
          excused++;
        case AttendanceStatus.absent:
          break;
      }
    }

    return AttendanceStats(
      total: total,
      present: present,
      absent: total - present - late - excused,
      late: late,
      excused: excused,
    );
  }

  static const empty = AttendanceStats(total: 0, present: 0, absent: 0);

  final int total;

  /// Exactly on time.
  final int present;
  final int absent;

  /// Late arrivals, counted as attended for the rate.
  final int late;

  /// Approved absences (medical, school activity, ...).
  final int excused;

  /// Students physically in the room: [present] plus [late].
  int get attended => present + late;

  /// Students missing a lesson without an excuse.
  int get missing => absent + excused;

  /// Share of attended students in the `0..1` range; `0` for an empty roster.
  double get attendanceRate => total == 0 ? 0 : attended / total;

  /// Same rate rendered as a whole percentage.
  int get attendancePercent => (attendanceRate * 100).round();

  /// A one line sentence describing the day, used by the summary header.
  String get summaryLine => total == 0
      ? 'No students enrolled yet'
      : '$attendancePercent% attendance recorded';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceStats &&
          other.total == total &&
          other.present == present &&
          other.absent == absent &&
          other.late == late &&
          other.excused == excused;

  @override
  int get hashCode => Object.hash(total, present, absent, late, excused);

  @override
  String toString() => 'AttendanceStats(total: $total, present: $present, '
      'absent: $absent, late: $late, excused: $excused)';
}