import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/attendance_status.dart';
import '../../domain/models/roster_filter.dart';
import '../providers/attendance_provider.dart';
import '../widgets/status_visual.dart';

/// Bottom sheet grouping every roster restriction: status, section and order.
Future<void> showRosterFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const RosterFilterSheet(),
  );
}

class RosterFilterSheet extends StatelessWidget {
  const RosterFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AttendanceProvider>();
    final filter = provider.filter;
    final classNames = provider.classNames;

    return SafeArea(
      child: Padding(
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
                Text(
                  'Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (filter.isActive)
                  TextButton(
                    onPressed: provider.clearFilters,
                    child: const Text('Clear all'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const _SheetLabel('Status'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final status in StatusFilter.values)
                  ChoiceChip(
                    label: Text(status.label),
                    selected: filter.status == status,
                    avatar: status == StatusFilter.all
                        ? null
                        : Icon(
                            statusVisual(context, statusFrom(status)).icon,
                            size: 16,
                            color: statusVisual(context, statusFrom(status))
                                .color,
                          ),
                    onSelected: (_) => provider.setStatusFilter(status),
                  ),
              ],
            ),
            if (classNames.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const _SheetLabel('Class'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ChoiceChip(
                    label: const Text('All classes'),
                    selected: !filter.hasClass,
                    onSelected: (_) => provider.setClassFilter(null),
                  ),
                  for (final className in classNames)
                    ChoiceChip(
                      label: Text(className),
                      selected: filter.className == className,
                      onSelected: (selected) =>
                          provider.setClassFilter(selected ? className : null),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            const _SheetLabel('Sort by'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final sort in RosterSort.values)
                  ChoiceChip(
                    label: Text(sort.label),
                    selected: filter.sort == sort,
                    onSelected: (_) => provider.setSort(sort),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  static AttendanceStatus statusFrom(StatusFilter filter) =>
      AttendanceStatus.values.firstWhere(
        (status) => status.name == filter.name,
        orElse: () => AttendanceStatus.present,
      );
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}