import 'package:flutter/material.dart';

import 'app_style.dart';

export 'app_style.dart';

/// Spacing scale shared by every screen so padding stays consistent.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Horizontal margin used by cards, lists and headers.
  static const double gutter = 16;
}

/// Corner radii used by the two visual styles.
abstract final class AppRadius {
  static const double classic = 4;
  static const double modern = 18;
}

/// Attendance colours that must stay legible on both surfaces.
///
/// They ship as a [ThemeExtension] instead of constants so light and dark mode
/// get their own contrast-correct values.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.present,
    required this.presentSurface,
    required this.late,
    required this.lateSurface,
    required this.absent,
    required this.absentSurface,
    required this.excused,
    required this.excusedSurface,
  });

  factory StatusColors.light() => const StatusColors(
        present: Color(0xFF1B873F),
        presentSurface: Color(0xFFE3F5E9),
        late: Color(0xFFB26A00),
        lateSurface: Color(0xFFFFF1DC),
        absent: Color(0xFFC0392B),
        absentSurface: Color(0xFFFBE6E4),
        excused: Color(0xFF37568C),
        excusedSurface: Color(0xFFE7EEF9),
      );

  factory StatusColors.dark() => const StatusColors(
        present: Color(0xFF6FD98D),
        presentSurface: Color(0xFF13301D),
        late: Color(0xFFF2B457),
        lateSurface: Color(0xFF37250E),
        absent: Color(0xFFFF8F85),
        absentSurface: Color(0xFF3A1714),
        excused: Color(0xFFA6BCEC),
        excusedSurface: Color(0xFF1B2438),
      );

  final Color present;
  final Color presentSurface;
  final Color late;
  final Color lateSurface;
  final Color absent;
  final Color absentSurface;
  final Color excused;
  final Color excusedSurface;

  /// The palette for the active [ThemeData]; falls back to light when the
  /// extension is missing (for example in a bare `MaterialApp`).
  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ?? StatusColors.light();

  @override
  StatusColors copyWith({
    Color? present,
    Color? presentSurface,
    Color? late,
    Color? lateSurface,
    Color? absent,
    Color? absentSurface,
    Color? excused,
    Color? excusedSurface,
  }) {
    return StatusColors(
      present: present ?? this.present,
      presentSurface: presentSurface ?? this.presentSurface,
      late: late ?? this.late,
      lateSurface: lateSurface ?? this.lateSurface,
      absent: absent ?? this.absent,
      absentSurface: absentSurface ?? this.absentSurface,
      excused: excused ?? this.excused,
      excusedSurface: excusedSurface ?? this.excusedSurface,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      present: Color.lerp(present, other.present, t)!,
      presentSurface: Color.lerp(presentSurface, other.presentSurface, t)!,
      late: Color.lerp(late, other.late, t)!,
      lateSurface: Color.lerp(lateSurface, other.lateSurface, t)!,
      absent: Color.lerp(absent, other.absent, t)!,
      absentSurface: Color.lerp(absentSurface, other.absentSurface, t)!,
      excused: Color.lerp(excused, other.excused, t)!,
      excusedSurface: Color.lerp(excusedSurface, other.excusedSurface, t)!,
    );
  }
}

/// Centralised themes. Two complete visual languages are provided:
///
/// * [classicLight] / [classicDark] — the classic Material look.
/// * [modernLight] / [modernDark] — Material 3.
abstract final class AppTheme {
  static const Color classicSeed = Color(0xFF1565C0);
  static const Color modernSeed = Color(0xFF3D5AFE);

  /// Flat fills kept for widgets that are built outside a themed context.
  static const Color present = Color(0xFF1B873F);
  static const Color presentSurface = Color(0xFFE3F5E9);
  static const Color absent = Color(0xFFC0392B);
  static const Color absentSurface = Color(0xFFFBE6E4);

  static ThemeData get classicLight => _classic(Brightness.light);
  static ThemeData get classicDark => _classic(Brightness.dark);
  static ThemeData get modernLight => _modern(Brightness.light);
  static ThemeData get modernDark => _modern(Brightness.dark);

  /// Backwards compatible aliases: the classic theme is the default one.
  static ThemeData get light => classicLight;
  static ThemeData get dark => classicDark;

  static StatusColors statusColorsFor(Brightness brightness) =>
      brightness == Brightness.dark ? StatusColors.dark() : StatusColors.light();

  /// Resolves the theme pair matching a [style].
  static ({ThemeData light, ThemeData dark}) forStyle(AppStyle style) =>
      switch (style) {
        AppStyle.classic => (light: classicLight, dark: classicDark),
        AppStyle.modern => (light: modernLight, dark: modernDark),
      };

  static ThemeData _classic(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: classicSeed,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppRadius.classic);
    final border = BorderSide(color: scheme.outline);
    final statusColors = statusColorsFor(brightness);

    return ThemeData(
      useMaterial3: false,
      brightness: brightness,
      colorScheme: scheme,
      visualDensity: VisualDensity.compact,
      scaffoldBackgroundColor:
          isDark ? scheme.surface : const Color(0xFFEFF1F5),
      extensions: <ThemeExtension<dynamic>>[statusColors],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
        actionsIconTheme: IconThemeData(color: scheme.onPrimary),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 1 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: radius, borderSide: border),
        enabledBorder:
            OutlineInputBorder(borderRadius: radius, borderSide: border),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll<double>(1),
          shape: WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(
            borderRadius: radius,
          )),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(
            borderRadius: radius,
          )),
          side: WidgetStatePropertyAll<BorderSide>(border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(
            borderRadius: radius,
          )),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.primary,
        selectedItemColor: scheme.onPrimary,
        unselectedItemColor: scheme.onPrimary.withValues(alpha: 0.72),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        side: border,
        labelStyle: TextStyle(fontSize: 12, color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        side: BorderSide(color: scheme.outline),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(scheme.onPrimary),
        trackColor: WidgetStatePropertyAll<Color>(
          scheme.onPrimary.withValues(alpha: 0.3),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: radius),
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 500)),
    );
  }

  static ThemeData _modern(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: modernSeed,
      brightness: brightness,
    );
    final radius = BorderRadius.circular(AppRadius.modern);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: <ThemeExtension<dynamic>>[statusColorsFor(brightness)],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 48)),
          shape: WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(
            borderRadius: radius,
          )),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        elevation: 3,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(fontSize: 12, color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.classic * 6),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    );
  }
}