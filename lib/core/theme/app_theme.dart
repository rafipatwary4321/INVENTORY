import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central Material 3 theme — clean, professional, mobile-first.
class AppTheme {
  AppTheme._();

  static const Color _brandBlue = Color(0xFF1565C0);
  static const Color _brandIndigo = Color(0xFF3949AB);
  static const Color _brandTeal = Color(0xFF00897B);
  static const Color _lightScaffold = Color(0xFFF4F7FB);
  static const Color _darkScaffold = Color(0xFF04070F);

  static PageTransitionsTheme _pageTransitions() {
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
      },
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = GoogleFonts.interTextTheme();
    final isDark = brightness == Brightness.dark;
    final bodyColor = isDark ? const Color(0xFFE9EEF7) : const Color(0xFF122033);
    final mutedColor = isDark ? const Color(0xFFBBC7DA) : const Color(0xFF4D5D78);
    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.35,
        color: bodyColor,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: bodyColor,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: bodyColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: bodyColor,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: bodyColor,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: bodyColor,
        height: 1.45,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: bodyColor,
        height: 1.42,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: mutedColor,
        height: 1.35,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static ThemeData _base(ColorScheme colorScheme, Color scaffoldBg) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      pageTransitionsTheme: _pageTransitions(),
      textTheme: _textTheme(colorScheme.brightness),
      dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.75)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        highlightElevation: 4,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.primaryContainer,
        backgroundColor: const Color(0xFF070C18),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandBlue,
      secondary: _brandIndigo,
      tertiary: _brandTeal,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFFDFDFF),
      onSurface: const Color(0xFF131C2B),
      onSurfaceVariant: const Color(0xFF4B5D79),
      outline: const Color(0xFF6D7D97),
      outlineVariant: const Color(0xFFC5CEE0),
      surfaceContainerHighest: const Color(0xFFE8ECF6),
    );
    return _base(colorScheme, _lightScaffold);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandBlue,
      secondary: _brandIndigo,
      tertiary: _brandTeal,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF64B5FF),
      onPrimary: const Color(0xFF001C39),
      primaryContainer: const Color(0xFF2C2CFF),
      onPrimaryContainer: const Color(0xFFE5E9FF),
      secondary: const Color(0xFF9B7BFF),
      tertiary: const Color(0xFF1DE2B0),
      surface: const Color(0xFF0A1020),
      onSurface: const Color(0xFFF6FAFF),
      onSurfaceVariant: const Color(0xFFAFC0DA),
      outline: const Color(0xFF7A8AA3),
      outlineVariant: const Color(0xFF2A3345),
      surfaceContainerHighest: const Color(0xFF151D31),
      inversePrimary: const Color(0xFF2D7CFF),
    );
    return _base(colorScheme, _darkScaffold);
  }
}
