import 'package:meta/meta.dart';

import '../../../../core/utils/date_formats.dart';
import 'attendance_stats.dart';
import 'attendance_status.dart';
import 'student.dart';

/// Attendance captured for one calendar day.
///
/// [marks] maps a student id onto the status recorded that day. Students
/// missing from the map simply have no mark yet.
@immutable
class AttendanceDay {
  const AttendanceDay({
    required this.date,
    required this.marks,
    required this.stats,
  });

  /// Builds the day by resolving the marks against the current roster.
  factory AttendanceDay.resolve({
    required DateTime date,
    required Map<String, AttendanceStatus> marks,
    required List<Student> students,
  }) {
    final resolved = students
        .map(
          (student) => student.copyWith(
            status: marks[student.id] ?? AttendanceStatus.absent,
          ),
        )
        .toList(growable: false);

    return AttendanceDay(
      date: startOfDay(date),
      marks: Map<String, AttendanceStatus>.unmodifiable(marks),
      stats: AttendanceStats.fromStudents(resolved),
    );
  }

  final DateTime date;

  /// Immutable `studentId -> status` snapshot of the day.
  final Map<String, AttendanceStatus> marks;

  /// Counters derived from the marks and the roster at build time.
  final AttendanceStats stats;

  String get key => dateKey(date);

  bool get hasMarks => marks.isNotEmpty;

  int get markedCount => marks.length;

  /// Share of the roster that still has no explicit mark.
  int get unmarkedCount => stats.total - markedCount;

  bool isMarked(String studentId) => marks.containsKey(studentId);

  String get label => formatFullDate(date);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceDay &&
          other.date == date &&
          _marksEqual(other.marks, marks);

  @override
  int get hashCode => Object.hash(date, Object.hashAll(marks.entries));

  @override
  String toString() => 'AttendanceDay($key, ${marks.length} marks)';
}

/// Compares two dates descending, newest first.
int compareDaysDescending(AttendanceDay a, AttendanceDay b) =>
    b.date.compareTo(a.date);

bool _marksEqual(
  Map<String, AttendanceStatus> a,
  Map<String, AttendanceStatus> b,
) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}