/// The visual language the app is rendered with.
///
/// [AppStyle.classic] reproduces the classic Material look (solid app bar,
/// square cards, filled bottom navigation) while [AppStyle.modern] uses the
/// Material 3 surfaces and shapes. The choice is exposed in the settings screen
/// so the same build can serve both audiences.
enum AppStyle {
  classic(
    label: 'Classic',
    description: 'Solid surfaces, square cards and a filled bottom bar.',
  ),
  modern(
    label: 'Modern',
    description: 'Material 3 tones, rounded cards and a pill bottom bar.',
  );

  const AppStyle({required this.label, required this.description});

  /// Short name rendered next to the switch.
  final String label;

  /// One line explanation shown under the switch.
  final String description;

  /// Resolves a persisted/serialised value, falling back to [classic].
  static AppStyle fromName(String? value) {
    for (final style in AppStyle.values) {
      if (style.name == value) return style;
    }
    return AppStyle.classic;
  }
}