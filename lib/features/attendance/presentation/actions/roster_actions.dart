import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/app_feedback.dart';
import '../../domain/models/attendance_status.dart';
import '../dialogs/add_student_dialog.dart';
import '../dialogs/bulk_add_students_dialog.dart';
import '../providers/attendance_provider.dart';
import '../providers/settings_provider.dart';

/// Reusable flows shared by the app bar, the empty state and the detail sheet,
/// so the same action always behaves the same way from anywhere.

/// Asks for a name and a section, then appends the student to the roster.
Future<void> addStudentFlow(BuildContext context) async {
  final attendance = context.read<AttendanceProvider>();
  final settings = context.read<SettingsProvider>();

  final result = await AddStudentDialog.show(
    context,
    classNames: attendance.classNames,
    initialClassName: settings.defaultClassName,
  );
  if (result == null || !context.mounted) return;

  attendance.addStudent(result.name, className: result.className);
  showAppMessage(context, '${result.name} added to ${result.className}');
}

/// Pastes a whole list of names at once.
Future<void> addStudentsBulkFlow(BuildContext context) async {
  final attendance = context.read<AttendanceProvider>();
  final settings = context.read<SettingsProvider>();

  final entries = await BulkAddStudentsDialog.show(
    context,
    classNames: attendance.classNames,
    initialClassName: settings.defaultClassName,
  );
  if (entries == null || entries.isEmpty || !context.mounted) return;

  var added = 0;
  for (final (name, className) in entries) {
    if (attendance.addStudent(name, className: className)) added++;
  }
  showAppMessage(
    context,
    added == 1 ? '1 student added' : '$added students added',
  );
}

/// Removes a student and offers an undo for a few seconds.
void removeStudentFlow(BuildContext context, String studentId) {
  final provider = context.read<AttendanceProvider>();
  final index =
      provider.students.indexWhere((student) => student.id == studentId);
  final removed = provider.removeStudent(studentId);
  if (removed == null) return;

  showAppMessage(
    context,
    '${removed.name} removed',
    actionLabel: 'Undo',
    onAction: () => provider.restoreStudent(removed, index: index),
  );
}

/// Marks everyone present.
///
/// While the lesson is still empty the whole roster is flagged at once; once
/// some students are marked only the remaining ones are flagged, so a
/// correction never overwrites deliberate marks.
void markAllPresentFlow(BuildContext context) {
  final provider = context.read<AttendanceProvider>();
  if (!provider.hasStudents) return;

  if (provider.markedCount == 0) {
    provider.markAllPresent();
    showAppMessage(context, 'Everyone marked present');
    return;
  }

  final touched = provider.markAllPresentUnmarked();
  showAppMessage(
    context,
    touched == 0
        ? 'Everyone is already marked'
        : '$touched student${touched == 1 ? '' : 's'} marked present',
  );
}

/// Marks every student absent, after a confirmation.
Future<void> markAllAbsentFlow(BuildContext context) async {
  final provider = context.read<AttendanceProvider>();
  if (!provider.hasStudents) return;

  final confirmed = await confirmDialog(
    context,
    title: 'Clear this lesson',
    message: 'Every mark of this lesson is replaced by "Absent".',
    confirmLabel: 'Mark absent',
  );
  if (confirmed != true || !context.mounted) return;

  provider.markAll(AttendanceStatus.absent);
  showAppMessage(context, 'Everyone marked absent');
}

/// Copies the marks of the closest earlier lesson onto the selected one.
void rollOverFlow(BuildContext context) {
  final provider = context.read<AttendanceProvider>();
  final copied = provider.rollOverFromPreviousDay();
  showAppMessage(
    context,
    copied == 0
        ? 'No earlier lesson to copy'
        : 'Copied $copied mark${copied == 1 ? '' : 's'} from the previous lesson',
  );
}

/// Drops every mark of the selected day.
void clearLessonFlow(BuildContext context) {
  final provider = context.read<AttendanceProvider>();
  if (provider.markedCount == 0) {
    showAppMessage(context, 'This lesson has no marks yet');
    return;
  }
  provider.clearSelectedDay();
  showAppMessage(context, 'Lesson cleared');
}

/// Opens the calendar and switches the register to the picked day.
Future<void> pickDateFlow(BuildContext context) async {
  final provider = context.read<AttendanceProvider>();
  final now = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: provider.selectedDate,
    firstDate: DateTime(now.year - 3),
    lastDate: DateTime(now.year + 1, 12, 31),
    helpText: 'Select lesson date',
  );
  if (picked == null || !context.mounted) return;
  provider.selectDate(picked);
}