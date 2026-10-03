import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../actions/roster_actions.dart';
import '../actions/settings_actions.dart';
import '../dialogs/roster_filter_sheet.dart';
import '../dialogs/student_detail_sheet.dart';
import '../providers/attendance_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/attendance_summary.dart';
import '../widgets/date_selector_bar.dart';
import '../widgets/empty_students_view.dart';
import '../widgets/roster_toolbar.dart';
import '../widgets/student_tile.dart';

/// The register itself: lesson picker, summary, filters and the roster.
///
/// It is a plain widget (no [Scaffold]) because [HomeScreen] owns the app bar
/// and the bottom navigation. State lives entirely in [AttendanceProvider]: the
/// body is rebuilt through `context.watch` and every action is dispatched with
/// the shared flows, so no widget here uses `setState`.
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final settings = context.watch<SettingsProvider>();
    final visible = provider.visibleStudents;
    final profile = settings.profile;

    // An empty roster gets the whole screen for guidance; the register chrome
    // (counters, filters) only makes sense once there is somebody to mark.
    if (!provider.hasStudents) {
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStudentsView(
              caption: profile.detailsLine,
              onAddStudent: () => addStudentFlow(context),
              onLoadSample: () => loadSampleClassFlow(context),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            0,
            AppSpacing.gutter,
            AppSpacing.sm,
          ),
          sliver: SliverList.list(
            children: [
              _SchoolBanner(
                schoolName: profile.schoolName,
                details: profile.detailsLine,
                marked: provider.markedCount,
                total: provider.totalStudents,
              ),
              const SizedBox(height: AppSpacing.sm),
              DateSelectorBar(
                selectedDate: provider.selectedDate,
                dates: provider.recentDates(14),
                onSelect: provider.selectDate,
                onShift: provider.shiftDate,
                onOpenCalendar: () => pickDateFlow(context),
                hasMarks: provider.dayHasMarks,
              ),
              const SizedBox(height: AppSpacing.sm),
              AttendanceSummary(
                stats: provider.stats,
                label: profile.detailsLine.isEmpty ? null : profile.detailsLine,
              ),
              const SizedBox(height: AppSpacing.sm),
              RosterToolbar(
                filter: provider.filter,
                classNames: provider.classNames,
                onQueryChanged: provider.setQuery,
                onOpenFilters: () => showRosterFilterSheet(context),
                onClassSelected: provider.setClassFilter,
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
        if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: NoMatchesView(onClearFilters: provider.clearFilters),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.xs,
              AppSpacing.gutter,
              96,
            ),
            sliver: SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final student = visible[index];
                return StudentTile(
                  key: ValueKey(student.id),
                  student: student,
                  onAttendanceChanged: (isPresent) =>
                      provider.setAttendance(student.id, isPresent),
                  onDelete: () => removeStudentFlow(context, student.id),
                  onOpen: () => showStudentDetailSheet(context, student.id),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// One line identity strip: who the register belongs to and how far it is.
class _SchoolBanner extends StatelessWidget {
  const _SchoolBanner({
    required this.schoolName,
    required this.details,
    required this.marked,
    required this.total,
  });

  final String schoolName;
  final String details;
  final int marked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = total > 0 && marked >= total;

    return Row(
      children: [
        Icon(Icons.school_rounded, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schoolName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (details.isNotEmpty)
                Text(
                  details,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Tooltip(
          message: 'Students marked so far',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: complete
                  ? StatusColors.of(context).presentSurface
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.classic * 3),
            ),
            child: Text(
              '$marked / $total marked',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: complete
                    ? StatusColors.of(context).present
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}