import 'package:flutter/material.dart';

/// Rounded progress bar used for every attendance rate in the app.
class MeterBar extends StatelessWidget {
  const MeterBar({
    required this.value,
    required this.color,
    this.height = 8,
    this.semanticLabel,
    super.key,
  });

  /// Progress in the `0..1` range; values outside are clamped.
  final double value;
  final Color color;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = value.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: clamped,
          minHeight: height,
          color: color,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}