import 'package:meta/meta.dart';

import 'attendance_status.dart';

/// Restricts the roster list to one of the attendance states.
enum StatusFilter {
  all('All'),
  present('Present'),
  late('Late'),
  absent('Absent'),
  excused('Excused');

  const StatusFilter(this.label);

  final String label;

  /// Whether a status passes this filter; [all] passes everything.
  bool matches(AttendanceStatus status) =>
      this == StatusFilter.all || name == status.name;

  static StatusFilter fromName(String? value) {
    for (final filter in StatusFilter.values) {
      if (filter.name == value) return filter;
    }
    return StatusFilter.all;
  }
}

/// Ordering applied to the roster list.
enum RosterSort {
  rollNumber('Roll number'),
  name('Name'),
  status('Status');

  const RosterSort(this.label);

  final String label;

  static RosterSort fromName(String? value) {
    for (final sort in RosterSort.values) {
      if (sort.name == value) return sort;
    }
    return RosterSort.rollNumber;
  }
}

/// Immutable snapshot of the roster filters, so the UI can diff them cheaply.
@immutable
class RosterFilter {
  const RosterFilter({
    this.query = '',
    this.status = StatusFilter.all,
    this.className,
    this.sort = RosterSort.rollNumber,
  });

  final String query;

  /// [StatusFilter.all] when no status restriction is applied.
  final StatusFilter status;

  /// `null` means "every class".
  final String? className;

  final RosterSort sort;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get hasClass => className != null;

  bool get hasStatus => status != StatusFilter.all;

  /// How many restrictions are active; drives the filter badge.
  int get activeCount =>
      (hasQuery ? 1 : 0) + (hasStatus ? 1 : 0) + (hasClass ? 1 : 0);

  bool get isActive => activeCount > 0;

  bool matches(AttendanceStatus value, String studentName, String studentClass) {
    if (hasStatus && !status.matches(value)) return false;
    if (hasClass && className != studentClass) return false;
    if (hasQuery) {
      final needle = query.trim().toLowerCase();
      final matchesQuery = studentName.toLowerCase().contains(needle) ||
          studentClass.toLowerCase().contains(needle) ||
          '$studentClass $studentName'.toLowerCase().contains(needle);
      if (!matchesQuery) return false;
    }
    return true;
  }

  RosterFilter copyWith({
    String? query,
    StatusFilter? status,
    String? className,
    bool clearClass = false,
    RosterSort? sort,
  }) {
    return RosterFilter(
      query: query ?? this.query,
      status: status ?? this.status,
      className: clearClass ? null : (className ?? this.className),
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RosterFilter &&
          other.query == query &&
          other.status == status &&
          other.className == className &&
          other.sort == sort;

  @override
  int get hashCode => Object.hash(query, status, className, sort);

  @override
  String toString() =>
      'RosterFilter(query: $query, status: ${status.name}, '
      'class: $className, sort: ${sort.name})';
}