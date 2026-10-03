import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/attendance_stats.dart';
import 'meter_bar.dart';
import 'status_visual.dart';

/// Header panel of the register: the four counters, the attendance meter and
/// the one line summary. It receives a plain [AttendanceStats] so it can be
/// reused or tested without a provider.
class AttendanceSummary extends StatelessWidget {
  const AttendanceSummary({required this.stats, this.label, super.key});

  final AttendanceStats stats;

  /// Optional caption above the counters, e.g. `Grade 8 - B`.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);
    final percent = stats.attendancePercent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (label != null) ...[
              Text(
                label!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StatCell(
                      label: 'Total',
                      value: stats.total,
                      icon: Icons.groups_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const _CellDivider(),
                  Expanded(
                    child: _StatCell(
                      label: 'Present',
                      value: stats.present,
                      icon: Icons.check_circle_rounded,
                      color: colors.present,
                    ),
                  ),
                  const _CellDivider(),
                  Expanded(
                    child: _StatCell(
                      label: 'Late',
                      value: stats.late,
                      icon: Icons.schedule_rounded,
                      color: colors.late,
                    ),
                  ),
                  const _CellDivider(),
                  Expanded(
                    child: _StatCell(
                      label: 'Absent',
                      value: stats.absent,
                      icon: Icons.cancel_rounded,
                      color: colors.absent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'Attendance rate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '$percent%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _rateColor(stats, context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            MeterBar(
              value: stats.attendanceRate,
              color: _rateColor(stats, context),
              height: 10,
              semanticLabel: 'Attendance rate $percent percent',
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              stats.summaryLine,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Color _rateColor(AttendanceStats stats, BuildContext context) {
    if (stats.total == 0) return Theme.of(context).colorScheme.primary;
    final colors = StatusColors.of(context);
    return stats.attendanceRate >= 0.75 ? colors.present : colors.absent;
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) => VerticalDivider(
        width: AppSpacing.lg,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status legend, so the four colours are self explanatory.
class StatusLegend extends StatelessWidget {
  const StatusLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final status in allAttendanceStatuses)
          StatusChip(status: status, showIcon: false),
        Text(
          'Tap a name for details',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}