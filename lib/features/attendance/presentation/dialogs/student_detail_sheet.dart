import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formats.dart';
import '../../domain/models/attendance_day.dart';
import '../../domain/models/attendance_status.dart';
import '../../domain/models/student.dart';
import '../providers/attendance_provider.dart';
import '../widgets/meter_bar.dart';
import '../widgets/section_card.dart';
import '../widgets/status_visual.dart';
import 'add_student_dialog.dart';

/// Bottom sheet with everything known about one student: the status picker,
/// their totals over the recorded days and their recent history.
Future<void> showStudentDetailSheet(BuildContext context, String studentId) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => StudentDetailSheet(studentId: studentId),
  );
}

class StudentDetailSheet extends StatelessWidget {
  const StudentDetailSheet({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AttendanceProvider>();
    final student = provider.studentById(studentId);

    if (student == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text('This student is no longer on the roster.'),
      );
    }

    final days = provider.daysForStudent(studentId);
    final tally = _Tally.from(days, studentId);
    final rate = tally.rate;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    _initials(student.name),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${student.className} • ${student.rollLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: 'Attendance for this lesson',
              icon: Icons.how_to_reg_rounded,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final status in allAttendanceStatuses)
                      ChoiceChip(
                        label: Text(status.label),
                        selected: student.status == status,
                        avatar: Icon(
                          statusVisual(context, status).icon,
                          size: 16,
                          color: statusVisual(context, status).color,
                        ),
                        onSelected: (_) => provider.setStatus(studentId, status),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text(
                      'Overall rate',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(rate * 100).round()}%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                MeterBar(
                  value: rate,
                  color: rate >= 0.75
                      ? StatusColors.of(context).present
                      : StatusColors.of(context).absent,
                  semanticLabel: 'Attendance rate',
                ),
                const SizedBox(height: AppSpacing.sm),
                DetailRow(label: 'Days recorded', value: '${tally.total}'),
                DetailRow(
                  label: 'Present',
                  value: '${tally.present}',
                  valueColor: StatusColors.of(context).present,
                ),
                DetailRow(
                  label: 'Late',
                  value: '${tally.late}',
                  valueColor: StatusColors.of(context).late,
                ),
                DetailRow(
                  label: 'Excused',
                  value: '${tally.excused}',
                  valueColor: StatusColors.of(context).excused,
                ),
                DetailRow(
                  label: 'Absent',
                  value: '${tally.absent}',
                  valueColor: StatusColors.of(context).absent,
                ),
              ],
            ),
            if (days.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                title: 'Recent lessons',
                icon: Icons.history_rounded,
                children: [
                  for (final day in days.take(6))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatFullDate(day.date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatusChip(
                            status: day.marks[studentId] ??
                                AttendanceStatus.absent,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _edit(context, student),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    onPressed: () => _remove(context, student),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, Student student) async {
    final provider = context.read<AttendanceProvider>();
    final result = await AddStudentDialog.show(
      context,
      initialName: student.name,
      initialClassName: student.className,
      classNames: provider.classNames,
      title: 'Edit student',
      submitLabel: 'Save',
    );
    if (result == null || !context.mounted) return;

    provider.updateStudent(
      student.id,
      name: result.name,
      className: result.className,
    );
  }

  Future<void> _remove(BuildContext context, Student student) async {
    final provider = context.read<AttendanceProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove student'),
        content: Text(
          '${student.name} will be removed from the roster and from every '
          'recorded lesson.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    Navigator.of(context).pop();
    provider.removeStudent(student.id);
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return _firstLetter(parts.first);
    return '${_firstLetter(parts.first)}${_firstLetter(parts.last)}';
  }

  static String _firstLetter(String value) =>
      value.isEmpty ? '' : value.substring(0, 1).toUpperCase();
}

/// Running totals of one student over the recorded days.
class _Tally {
  const _Tally({
    required this.total,
    required this.present,
    required this.late,
    required this.excused,
    required this.absent,
  });

  factory _Tally.from(List<AttendanceDay> days, String studentId) {
    var present = 0;
    var late = 0;
    var excused = 0;
    var absent = 0;
    var total = 0;

    for (final day in days) {
      final status = day.marks[studentId];
      if (status == null) continue;
      total++;
      switch (status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.late:
          late++;
        case AttendanceStatus.excused:
          excused++;
        case AttendanceStatus.absent:
          absent++;
      }
    }

    return _Tally(
      total: total,
      present: present,
      late: late,
      excused: excused,
      absent: absent,
    );
  }

  final int total;
  final int present;
  final int late;
  final int excused;
  final int absent;

  int get attended => present + late;

  double get rate => total == 0 ? 0 : attended / total;
}