import 'package:flutter/material.dart';

import '../../domain/models/school_profile.dart';

/// Modal that edits the school profile shown on the register and in exports.
class SchoolProfileDialog extends StatefulWidget {
  const SchoolProfileDialog({this.initial = const SchoolProfile(), super.key});

  /// Shows the dialog and resolves to the edited profile, or `null` when
  /// dismissed.
  static Future<SchoolProfile?> show(
    BuildContext context, {
    SchoolProfile initial = const SchoolProfile(),
  }) {
    return showDialog<SchoolProfile>(
      context: context,
      builder: (_) => SchoolProfileDialog(initial: initial),
    );
  }

  final SchoolProfile initial;

  @override
  State<SchoolProfileDialog> createState() => _SchoolProfileDialogState();
}

class _SchoolProfileDialogState extends State<SchoolProfileDialog> {
  static const String emptySchoolMessage = 'School name cannot be empty';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _school;
  late final TextEditingController _section;
  late final TextEditingController _teacher;
  late final TextEditingController _year;
  late final TextEditingController _period;

  @override
  void initState() {
    super.initState();
    _school = TextEditingController(text: widget.initial.schoolName);
    _section = TextEditingController(text: widget.initial.section);
    _teacher = TextEditingController(text: widget.initial.teacher);
    _year = TextEditingController(text: widget.initial.academicYear);
    _period = TextEditingController(text: widget.initial.period);
  }

  @override
  void dispose() {
    _school.dispose();
    _section.dispose();
    _teacher.dispose();
    _year.dispose();
    _period.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      SchoolProfile(
        schoolName: _school.text.trim(),
        section: _section.text.trim(),
        teacher: _teacher.text.trim(),
        academicYear: _year.text.trim(),
        period: _period.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('School details'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _school,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'School name',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? emptySchoolMessage
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _section,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Class / section',
                    hintText: 'e.g. Grade 8 - B',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teacher,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Teacher',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _period,
                  decoration: const InputDecoration(
                    labelText: 'Period (optional)',
                    hintText: 'e.g. Period 3',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _year,
                  decoration: const InputDecoration(
                    labelText: 'Academic year (optional)',
                    hintText: 'e.g. 2026 / 2027',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}