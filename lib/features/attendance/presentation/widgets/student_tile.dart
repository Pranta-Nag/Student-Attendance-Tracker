import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/student.dart';
import 'status_visual.dart';

/// One roster row: the checkbox driving the status, the name with its roll
/// number, the section and the live status chip, plus quick actions.
///
/// Tapping the row opens the detail sheet, the checkbox toggles
/// present/absent and the trash icon removes the student.
class StudentTile extends StatelessWidget {
  const StudentTile({
    required this.student,
    required this.onAttendanceChanged,
    required this.onDelete,
    this.onOpen,
    super.key,
  });

  final Student student;
  final ValueChanged<bool> onAttendanceChanged;
  final VoidCallback onDelete;

  /// Invoked when the row itself is tapped.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, AppSpacing.sm, 4, AppSpacing.sm),
          child: Row(
            children: [
              Checkbox(
                value: student.status.checkboxValue,
                onChanged: (value) => onAttendanceChanged(value ?? false),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (student.rollNumber > 0)
                          _RollBadge(rollNumber: student.rollNumber),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        ClassChip(
                          label: student.className,
                          rollNumber: student.rollNumber,
                        ),
                        StatusChip(status: student.status),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: theme.colorScheme.error,
                tooltip: 'Remove ${student.name}',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RollBadge extends StatelessWidget {
  const _RollBadge({required this.rollNumber});

  final int rollNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.classic * 2),
      ),
      child: Text(
        '#$rollNumber',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}