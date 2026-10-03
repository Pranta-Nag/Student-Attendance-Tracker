/// The attendance state of a single student for a tracked day.
enum AttendanceStatus {
  present,
  absent,
  late,
  excused;

  /// Whether the student was in the room, counting [late] as attended.
  bool get isPresent =>
      this == AttendanceStatus.present || this == AttendanceStatus.late;

  /// Whether the status still needs a decision from the teacher.
  bool get needsAttention =>
      this == AttendanceStatus.absent || this == AttendanceStatus.excused;

  String get label => switch (this) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.late => 'Late',
        AttendanceStatus.excused => 'Excused',
      };

  /// The value a [Checkbox] renders for this status.
  bool get checkboxValue => isPresent;

  /// Maps the raw checkbox value onto a status.
  static AttendanceStatus fromCheckbox(bool isPresent) =>
      isPresent ? AttendanceStatus.present : AttendanceStatus.absent;
}