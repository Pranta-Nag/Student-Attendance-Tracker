import 'package:flutter/material.dart';

import '../../domain/models/student.dart';

/// Modal that takes a whole class at once: one name per line, pasted straight
/// from a register or a message.
class BulkAddStudentsDialog extends StatefulWidget {
  const BulkAddStudentsDialog({
    this.classNames = const <String>[],
    this.initialClassName = '',
    super.key,
  });

/// Shows the dialog and resolves to the parsed entries as `(name, className)`
  /// pairs, or `null` when dismissed.
  static Future<List<(String, String)>?> show(
    BuildContext context, {
    List<String> classNames = const <String>[],
    String initialClassName = '',
  }) {
    return showDialog<List<(String, String)>>(
      context: context,
      builder: (_) => BulkAddStudentsDialog(
        classNames: classNames,
        initialClassName: initialClassName,
      ),
    );
  }

  final List<String> classNames;
  final String initialClassName;

  @override
  State<BulkAddStudentsDialog> createState() =>
      _BulkAddStudentsDialogState();
}

class _BulkAddStudentsDialogState extends State<BulkAddStudentsDialog> {
  final _namesController = TextEditingController();
  String _className = kDefaultClassName;

  @override
  void initState() {
    super.initState();
    _className = _options.contains(widget.initialClassName)
        ? widget.initialClassName
        : kDefaultClassName;
  }

  @override
  void dispose() {
    _namesController.dispose();
    super.dispose();
  }

  List<String> get _options {
    final options = <String>{kDefaultClassName, ...widget.classNames}.toList()
      ..sort();
    return options;
  }

  /// Non empty, trimmed lines in the order they were typed.
  List<String> get _parsedNames => _namesController.text
      .split(RegExp(r'[\n,;]'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  void _submit() {
    final names = _parsedNames;
    if (names.isEmpty) return;
    Navigator.of(context).pop([
      for (final name in names) (name: name, className: _className),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _parsedNames.length;

    return AlertDialog(
      title: const Text('Add several students'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _namesController,
              onChanged: (_) => setState(() {}),
              maxLines: 6,
              minLines: 4,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'One name per line',
                hintText: 'Ada Lovelace\nGrace Hopper',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _className,
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
              onChanged: (value) => setState(
                () => _className = value ?? kDefaultClassName,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              count == 0
                  ? 'No names detected yet.'
                  : '$count student${count == 1 ? '' : 's'} ready to add.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: count == 0
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
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
          onPressed: count == 0 ? null : _submit,
          child: const Text('Add students'),
        ),
      ],
    );
  }
}