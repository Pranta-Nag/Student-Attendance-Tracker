import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/attendance_status.dart';

/// Icon, label and colours used to render one attendance status.
@immutable
class StatusVisual {
  const StatusVisual({
    required this.status,
    required this.label,
    required this.icon,
    required this.color,
    required this.surface,
  });

  final AttendanceStatus status;
  final String label;
  final IconData icon;
  final Color color;
  final Color surface;
}

/// Resolves the presentation of [status] for the active theme.
StatusVisual statusVisual(BuildContext context, AttendanceStatus status) {
  final colors = StatusColors.of(context);
  return switch (status) {
    AttendanceStatus.present => StatusVisual(
        status: status,
        label: status.label,
        icon: Icons.check_circle_rounded,
        color: colors.present,
        surface: colors.presentSurface,
      ),
    AttendanceStatus.late => StatusVisual(
        status: status,
        label: status.label,
        icon: Icons.schedule_rounded,
        color: colors.late,
        surface: colors.lateSurface,
      ),
    AttendanceStatus.absent => StatusVisual(
        status: status,
        label: status.label,
        icon: Icons.cancel_rounded,
        color: colors.absent,
        surface: colors.absentSurface,
      ),
    AttendanceStatus.excused => StatusVisual(
        status: status,
        label: status.label,
        icon: Icons.assignment_turned_in_outlined,
        color: colors.excused,
        surface: colors.excusedSurface,
      ),
  };
}

/// Every status, in the order the school UI offers them.
const List<AttendanceStatus> allAttendanceStatuses = AttendanceStatus.values;

/// Compact pill showing the attendance status of a student.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, this.showIcon = true, super.key});

  final AttendanceStatus status;

  /// Compact chips drop the icon, which matters inside narrow list rows.
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final visual = statusVisual(context, status);
    final theme = Theme.of(context);

    return Semantics(
      label: 'Attendance: ${visual.label}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: showIcon ? 8 : 10,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: visual.surface,
          borderRadius: BorderRadius.circular(AppRadius.classic * 4),
          border: Border.all(color: visual.color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(visual.icon, size: 13, color: visual.color),
              const SizedBox(width: 4),
            ],
            Text(
              visual.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: visual.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outlined pill showing the section a student belongs to.
class ClassChip extends StatelessWidget {
  const ClassChip({required this.label, this.rollNumber, super.key});

  final String label;
  final int? rollNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suffix =
        rollNumber != null && rollNumber! > 0 ? ' • $rollNumber' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.classic * 4),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        '$label$suffix',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}