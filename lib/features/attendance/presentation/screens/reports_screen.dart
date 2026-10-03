import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formats.dart';
import '../../domain/reports/attendance_report.dart';
import '../actions/report_actions.dart';
import '../providers/attendance_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/meter_bar.dart';
import '../widgets/section_card.dart';

/// Aggregate view of the register: the selected lesson, the trend of the last
/// lessons, a per class split and the per student totals.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final settings = context.watch<SettingsProvider>();
    final report = AttendanceReport.build(
      students: provider.students,
      days: provider.history,
      selectedDay: provider.selectedDay,
    );

    if (report.isEmpty) return const _NoDataView();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.xl,
      ),
      children: [
        _LessonCard(report: report, schoolName: settings.schoolName),
        const SizedBox(height: AppSpacing.md),
        _TrendCard(report: report),
        const SizedBox(height: AppSpacing.md),
        _ClassCard(report: report),
        const SizedBox(height: AppSpacing.md),
        _StudentCard(report: report),
        const SizedBox(height: AppSpacing.md),
        _ExportCard(exportedDays: report.recordedDays),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.report, required this.schoolName});

  final AttendanceReport report;
  final String schoolName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);
    final stats = report.selectedDay.stats;
    final percent = stats.attendancePercent;

    return SectionCard(
      title: formatFullDate(report.selectedDay.date),
      subtitle: schoolName,
      icon: Icons.event_available_rounded,
      trailing: Text(
        '$percent%',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: stats.attendanceRate >= 0.75 ? colors.present : colors.absent,
        ),
      ),
      children: [
        MeterBar(
          value: stats.attendanceRate,
          color: stats.attendanceRate >= 0.75 ? colors.present : colors.absent,
          height: 10,
          semanticLabel: 'Attendance rate $percent percent',
        ),
        const SizedBox(height: AppSpacing.md),
        DetailRow(label: 'Students', value: '${stats.total}'),
        DetailRow(
          label: 'Present',
          value: '${stats.present}',
          valueColor: colors.present,
        ),
        DetailRow(
          label: 'Late',
          value: '${stats.late}',
          valueColor: colors.late,
        ),
        DetailRow(
          label: 'Excused',
          value: '${stats.excused}',
          valueColor: colors.excused,
        ),
        DetailRow(
          label: 'Absent',
          value: '${stats.absent}',
          valueColor: colors.absent,
        ),
        DetailRow(label: 'Lessons recorded', value: '${report.recordedDays}'),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.report});

  final AttendanceReport report;

  @override
  Widget build(BuildContext context) {
    if (report.trend.length < 2) {
      return SectionCard(
        title: 'Trend',
        subtitle: 'Record at least two lessons to see the trend',
        icon: Icons.show_chart_rounded,
        children: const [_EmptyNote(text: 'No trend yet')],
      );
    }

    return SectionCard(
      title: 'Trend',
      subtitle: 'Attendance of the last ${report.trend.length} lessons',
      icon: Icons.show_chart_rounded,
      children: [_TrendChart(points: report.trend)],
    );
  }
}

/// Dependency free bar chart: one rounded bar per lesson.
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<DailyPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);

    return SizedBox(
      height: 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    Text(
                      '${point.stats.attendancePercent}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: point.rate.clamp(0.02, 1),
                          widthFactor: 0.72,
                          child: Container(
                            decoration: BoxDecoration(
                              color: point.rate >= 0.75
                                  ? colors.present
                                  : colors.absent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        point.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.report});

  final AttendanceReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);

    return SectionCard(
      title: 'By class',
      subtitle: 'Sections taking this lesson',
      icon: Icons.account_balance_rounded,
      children: [
        for (final summary in report.classes) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.className,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${summary.absent} absent of ${summary.total}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${summary.percent}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: summary.rate >= 0.75 ? colors.present : colors.absent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          MeterBar(
            value: summary.rate,
            color: summary.rate >= 0.75 ? colors.present : colors.absent,
            height: 6,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.report});

  final AttendanceReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);

    return SectionCard(
      title: 'Students',
      subtitle: 'Weakest attendance first',
      icon: Icons.people_alt_rounded,
      children: [
        for (final summary in report.students) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.student.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                summary.student.className,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${summary.attendancePercent}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: summary.attendanceRate >= 0.75
                      ? colors.present
                      : colors.absent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: MeterBar(
                  value: summary.attendanceRate,
                  color: summary.attendanceRate >= 0.75
                      ? colors.present
                      : colors.absent,
                  height: 6,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${summary.attended}/${summary.daysRecorded} lessons',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.exportedDays});

  final int exportedDays;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Export',
      subtitle: 'Copy the register as CSV',
      icon: Icons.ios_share_rounded,
      children: [
        const _EmptyNote(
          text: 'The CSV contains the per student totals, the class split and '
              'the daily attendance, ready to paste into a spreadsheet.',
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => exportReportFlow(context),
            icon: const Icon(Icons.copy_rounded),
            label: Text(
              exportedDays == 0
                  ? 'Copy CSV'
                  : 'Copy CSV ($exportedDays lessons)',
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _NoDataView extends StatelessWidget {
  const _NoDataView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_rounded,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No report yet',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add students on the register tab; totals and trends appear here '
              'as soon as lessons are marked.',
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
}