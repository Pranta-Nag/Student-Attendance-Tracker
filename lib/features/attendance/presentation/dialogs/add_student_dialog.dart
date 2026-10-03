import 'package:flutter/material.dart';

import '../../domain/models/student.dart';

/// Modal that collects a student name and the section they belong to.
///
/// It owns only transient form state (controllers + validators); the roster is
/// never touched here. On success it pops with the trimmed values and the
/// caller hands them to the provider.
class AddStudentDialog extends StatefulWidget {
  const AddStudentDialog({
    this.initialName = '',
    this.initialClassName,
    this.classNames = const <String>[],
    this.title = 'Add student',
    this.submitLabel = 'Add',
    super.key,
  });

  /// Shows the dialog and resolves to the entered values, or `null` if
  /// dismissed.
  static Future<({String name, String className})?> show(
    BuildContext context, {
    List<String> classNames = const <String>[],
    String initialClassName = '',
    String initialName = '',
    String title = 'Add student',
    String submitLabel = 'Add',
  }) {
    return showDialog<({String name, String className})>(
      context: context,
      builder: (_) => AddStudentDialog(
        initialName: initialName,
        initialClassName: initialClassName,
        classNames: classNames,
        title: title,
        submitLabel: submitLabel,
      ),
    );
  }

  final String initialName;

  /// Pre-selected section; falls back to the general section when empty.
  final String? initialClassName;

  /// Sections already present in the roster, offered in the dropdown.
  final List<String> classNames;

  final String title;
  final String submitLabel;

  @override
  State<AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  static const String emptyNameMessage = 'Student name cannot be empty';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName;
    _selectedClass = _initialClass;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<String> get _options {
    final options = <String>{
      kDefaultClassName,
      ...widget.classNames,
      if (widget.initialClassName != null && widget.initialClassName!.isNotEmpty)
        widget.initialClassName!,
    }.toList()
      ..sort();
    return options;
  }

  String get _initialClass {
    final requested = widget.initialClassName ?? '';
    return _options.contains(requested) ? requested : kDefaultClassName;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      (name: _nameController.text.trim(), className: _selectedClass!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Student name',
                hintText: 'e.g. Ada Lovelace',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? emptyNameMessage : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedClass,
              decoration: const InputDecoration(
                labelText: 'Class',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              items: [
                for (final className in _options)
                  DropdownMenuItem<String>(
                    value: className,
                    child: Text(className, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _selectedClass = value ?? kDefaultClassName),
            ),
            const SizedBox(height: 8),
            Text(
              'The roll number is assigned automatically.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}