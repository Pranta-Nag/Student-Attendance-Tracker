import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formats.dart';

/// Day navigation: arrows, the long form date, a calendar button and a strip
/// of the last days so switching lessons is one tap away.
class DateSelectorBar extends StatelessWidget {
  const DateSelectorBar({
    required this.selectedDate,
    required this.dates,
    required this.onSelect,
    required this.onShift,
    required this.onOpenCalendar,
    required this.hasMarks,
    super.key,
  });

  final DateTime selectedDate;
  final List<DateTime> dates;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<int> onShift;
  final VoidCallback onOpenCalendar;

  /// Whether a day already carries marks; drives the dot under the date.
  final bool Function(DateTime date) hasMarks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous day',
                  onPressed: () => onShift(-1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        formatFullDate(selectedDate),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRelativeDay(selectedDate, today),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next day',
                  onPressed: () => onShift(1),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_rounded),
                  tooltip: 'Pick a date',
                  onPressed: onOpenCalendar,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                itemCount: dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final date = dates[index];
                  return _DayCell(
                    date: date,
                    selected: dateKey(date) == dateKey(selectedDate),
                    marked: hasMarks(date),
                    onTap: () => onSelect(date),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.marked,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool marked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final dotColor = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;

    return Semantics(
      button: true,
      selected: selected,
      label: formatFullDate(date),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.classic * 2),
        child: Container(
          width: 46,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.classic * 2),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekdayShort[date.weekday - 1].substring(0, 1),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${date.day}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: marked ? dotColor : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}