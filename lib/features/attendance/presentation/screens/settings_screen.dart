import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/reports/attendance_report.dart';
import '../actions/settings_actions.dart';
import '../providers/attendance_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/section_card.dart';

/// Preferences of the school and the teacher, plus the data tools.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final attendance = context.watch<AttendanceProvider>();
    final profile = settings.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.xl,
      ),
      children: [
        SectionCard(
          title: 'School',
          icon: Icons.school_outlined,
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit school details',
            onPressed: () => editSchoolProfileFlow(context),
          ),
          children: [
            DetailRow(label: 'School', value: profile.schoolName),
            DetailRow(
              label: 'Class / section',
              value: profile.section.isEmpty ? 'Not set' : profile.section,
            ),
            DetailRow(
              label: 'Teacher',
              value: profile.teacher.isEmpty ? 'Not set' : profile.teacher,
            ),
            DetailRow(
              label: 'Period',
              value: profile.period.isEmpty ? 'Not set' : profile.period,
            ),
            DetailRow(
              label: 'Academic year',
              value: profile.academicYear.isEmpty
                  ? 'Not set'
                  : profile.academicYear,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Appearance',
          subtitle: 'Classic is the default look; Modern switches to '
              'Material 3 shapes and tones.',
          icon: Icons.palette_outlined,
          children: [
            _Label('Interface style'),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<AppStyle>(
              segments: [
                for (final style in AppStyle.values)
                  ButtonSegment<AppStyle>(
                    value: style,
                    label: Text(style.label),
                    icon: Icon(
                      style == AppStyle.classic
                          ? Icons.crop_square_rounded
                          : Icons.rounded_corner_rounded,
                    ),
                  ),
              ],
              selected: {settings.style},
              onSelectionChanged: (selection) =>
                  settings.setStyle(selection.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Label('Theme'),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_rounded),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_rounded),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_rounded),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (selection) =>
                  settings.setThemeMode(selection.first),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Attendance rules',
          icon: Icons.rule_folder_outlined,
          children: [
            const DetailRow(
              label: 'Late arrivals',
              value: 'Count as attended',
            ),
            const DetailRow(
              label: 'Excused absences',
              value: 'Excluded from the rate',
            ),
            DetailRow(
              label: 'Attention threshold',
              value: '${(AttendanceReport.attentionThreshold * 100).round()}%',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Data',
          subtitle: 'Tools to fill or clean the register',
          icon: Icons.storage_rounded,
          children: [
            _ActionTile(
              icon: Icons.auto_awesome_outlined,
              label: 'Load a sample class',
              description: 'Adds eight demo students',
              onTap: () => loadSampleClassFlow(context),
            ),
            const Divider(),
            _ActionTile(
              icon: Icons.restart_alt_rounded,
              label: 'Clear recorded lessons',
              description: 'Keeps the roster, drops every mark',
              onTap: () => clearHistoryFlow(context),
            ),
            const Divider(),
            _ActionTile(
              icon: Icons.delete_forever_rounded,
              label: 'Reset everything',
              description: 'Students, lessons and school details',
              destructive: true,
              onTap: () => resetEverythingFlow(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'About',
          icon: Icons.info_outline_rounded,
          children: [
            const DetailRow(label: 'App', value: 'School Attendance 1.0.0'),
            DetailRow(
              label: 'Students',
              value: '${attendance.totalStudents}',
            ),
            DetailRow(
              label: 'Lessons recorded',
              value: '${attendance.history.length}',
            ),
            DetailRow(
              label: 'Interface',
              value: '${settings.style.label} • '
                  '${settings.themeMode.name}',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Attendance stays on this device; nothing is uploaded.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}