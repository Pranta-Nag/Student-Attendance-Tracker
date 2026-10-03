import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/app_feedback.dart';
import '../dialogs/school_profile_dialog.dart';
import '../providers/attendance_provider.dart';
import '../providers/settings_provider.dart';

/// Actions behind the settings screen and its app bar button.

/// Edits the school profile shown on the register and in the export.
Future<void> editSchoolProfileFlow(BuildContext context) async {
  final settings = context.read<SettingsProvider>();
  final profile = await SchoolProfileDialog.show(
    context,
    initial: settings.profile,
  );
  if (profile == null || !context.mounted) return;

  settings.updateProfile(profile);
  showAppMessage(context, 'School details updated');
}

/// Fills the register with a demo class, after a confirmation.
Future<void> loadSampleClassFlow(BuildContext context) async {
  final attendance = context.read<AttendanceProvider>();
  final confirmed = await confirmDialog(
    context,
    title: 'Load a sample class',
    message: 'Eight demo students are added to the roster so you can try the '
        'features out. Existing students are kept.',
    confirmLabel: 'Load',
  );
  if (confirmed != true || !context.mounted) return;

  final added = attendance.seedSampleRoster();
  showAppMessage(context, '$added demo students added');
}

/// Removes every recorded lesson but keeps the roster.
Future<void> clearHistoryFlow(BuildContext context) async {
  final attendance = context.read<AttendanceProvider>();
  final confirmed = await confirmDialog(
    context,
    title: 'Clear recorded lessons',
    message: 'Marks of all days are deleted. The roster stays untouched.',
    confirmLabel: 'Clear',
  );
  if (confirmed != true || !context.mounted) return;

  attendance.clearHistory();
  showAppMessage(context, 'Recorded lessons cleared');
}

/// Wipes the roster, the history and the school details.
Future<void> resetEverythingFlow(BuildContext context) async {
  final attendance = context.read<AttendanceProvider>();
  final settings = context.read<SettingsProvider>();
  final confirmed = await confirmDialog(
    context,
    title: 'Reset everything',
    message: 'Students, recorded lessons and school details are deleted.',
    confirmLabel: 'Reset',
  );
  if (confirmed != true || !context.mounted) return;

  attendance.resetAll();
  settings.reset();
  showAppMessage(context, 'The app was reset');
}