import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/roster_filter.dart';

/// Search field, filter button and the section chips of the roster.
class RosterToolbar extends StatelessWidget {
  const RosterToolbar({
    required this.filter,
    required this.classNames,
    required this.onQueryChanged,
    required this.onOpenFilters,
    required this.onClassSelected,
    super.key,
  });

  final RosterFilter filter;
  final List<String> classNames;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onOpenFilters;

  /// `null` clears the section restriction.
  final ValueChanged<String?> onClassSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search students or classes',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: filter.hasQuery
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          tooltip: 'Clear search',
                          onPressed: () => onQueryChanged(''),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filledTonal(
              onPressed: onOpenFilters,
              tooltip: 'Filters and sorting',
              icon: Badge(
                isLabelVisible: filter.activeCount > 0,
                label: Text('${filter.activeCount}'),
                child: const Icon(Icons.tune_rounded),
              ),
            ),
          ],
        ),
        if (classNames.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: const Text('All classes'),
                    selected: !filter.hasClass,
                    onSelected: (_) => onClassSelected(null),
                  ),
                ),
                for (final className in classNames)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(className),
                      selected: filter.className == className,
                      onSelected: (selected) =>
                          selected ? onClassSelected(className) : onClassSelected(null),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (filter.hasStatus) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.filter_alt_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Filtered by ${filter.status.label.toLowerCase()}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}