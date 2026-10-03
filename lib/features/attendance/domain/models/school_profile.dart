import 'package:meta/meta.dart';

/// School wide details shown on the header and in the exported report.
@immutable
class SchoolProfile {
  const SchoolProfile({
    this.schoolName = 'My School',
    this.section = '',
    this.teacher = '',
    this.academicYear = '',
    this.period = '',
  });

  final String schoolName;

  /// The class/section the register belongs to, e.g. `Grade 8 - B`.
  final String section;
  final String teacher;
  final String academicYear;

  /// Optional period label such as `Period 3` or `Homeroom`.
  final String period;

  /// `Grade 8 - B` when a section is set, otherwise `School register`.
  String get subtitle => section.trim().isEmpty
      ? 'School register'
      : section.trim();

  /// Secondary line combining section, period and academic year.
  String get detailsLine => <String>[
        if (section.trim().isNotEmpty) section.trim(),
        if (period.trim().isNotEmpty) period.trim(),
        if (academicYear.trim().isNotEmpty) academicYear.trim(),
      ].join(' • ');

  /// Identity shown at the top of the register: the school and, when known,
  /// the section it belongs to.
  String get caption =>
      detailsLine.isEmpty ? schoolName : '$schoolName • $detailsLine';

  SchoolProfile copyWith({
    String? schoolName,
    String? section,
    String? teacher,
    String? academicYear,
    String? period,
  }) {
    return SchoolProfile(
      schoolName: schoolName ?? this.schoolName,
      section: section ?? this.section,
      teacher: teacher ?? this.teacher,
      academicYear: academicYear ?? this.academicYear,
      period: period ?? this.period,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolProfile &&
          other.schoolName == schoolName &&
          other.section == section &&
          other.teacher == teacher &&
          other.academicYear == academicYear &&
          other.period == period;

  @override
  int get hashCode =>
      Object.hash(schoolName, section, teacher, academicYear, period);

  @override
  String toString() =>
      'SchoolProfile($schoolName, section: $section, teacher: $teacher, '
      'academicYear: $academicYear, period: $period)';
}