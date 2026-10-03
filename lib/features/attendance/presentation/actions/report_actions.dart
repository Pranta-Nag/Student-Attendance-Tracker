import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/app_feedback.dart';
import '../../domain/reports/attendance_report.dart';
import '../providers/attendance_provider.dart';
import '../providers/settings_provider.dart';

/// Builds the register report and puts it on the clipboard.
///
/// Exporting to the clipboard keeps the app dependency free while still being
/// enough to paste the table into a spreadsheet, a report or a message.
void exportReportFlow(BuildContext context) {
  final attendance = context.read<AttendanceProvider>();
  final settings = context.read<SettingsProvider>();

  final report = AttendanceReport.build(
    students: attendance.students,
    days: attendance.history,
    selectedDay: attendance.selectedDay,
  );
  if (report.students.isEmpty) {
    showAppMessage(context, 'Add students before exporting a report');
    return;
  }

  final csv = report.toCsv(profile: settings.profile);
  // The clipboard write is fire and forget: the message must not wait for the
  // platform channel round trip.
  unawaited(Clipboard.setData(ClipboardData(text: csv)));
  showAppMessage(
    context,
    'Report copied to the clipboard (${report.recordedDays} '
    'lesson${report.recordedDays == 1 ? '' : 's'})',
  );
}