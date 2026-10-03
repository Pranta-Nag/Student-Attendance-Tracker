import 'package:meta/meta.dart';

import 'attendance_status.dart';

/// Section a student belongs to, used when the school runs parallel classes.
const String kDefaultClassName = 'General';

/// An immutable domain entity describing a student.
///
/// Beyond the name it carries the school specific bits used for reporting: the
/// section ([className]) and the roll number inside that section. The model is
/// free of any UI or state-management concern.
@immutable
class Student {
  const Student({
    required this.id,
    required this.name,
    this.className = kDefaultClassName,
    this.rollNumber = 0,
    this.status = AttendanceStatus.absent,
  });

  final String id;
  final String name;
  final String className;

  /// Position inside [className]; `0` means "not assigned yet".
  final int rollNumber;

  /// Status for the currently tracked day.
  final AttendanceStatus status;

  bool get isPresent => status.isPresent;

  /// `12` or `No. 12`, hiding the label when no roll number is set.
  String get rollLabel => rollNumber > 0 ? 'No. $rollNumber' : 'Unassigned';

  Student copyWith({
    String? name,
    String? className,
    int? rollNumber,
    AttendanceStatus? status,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      className: className ?? this.className,
      rollNumber: rollNumber ?? this.rollNumber,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student &&
          other.id == id &&
          other.name == name &&
          other.className == className &&
          other.rollNumber == rollNumber &&
          other.status == status;

  @override
  int get hashCode =>
      Object.hash(id, name, className, rollNumber, status);

  @override
  String toString() =>
      'Student(id: $id, name: $name, class: $className, roll: $rollNumber, '
      'status: ${status.name})';
}