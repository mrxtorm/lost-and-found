import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Neutral colours that change between light and dark mode.
class AppPalette {
  final Color bg;
  final Color surface;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color line;
  final Color track;
  final Color primarySoft;
  final Color foundSoft;
  final Color lostSoft;
  final Color warnSoft;
  final Color warnLine;
  final Color snack;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.line,
    required this.track,
    required this.primarySoft,
    required this.foundSoft,
    required this.lostSoft,
    required this.warnSoft,
    required this.warnLine,
    required this.snack,
  });

  static const light = AppPalette(
    bg: Color(0xFFF4F5F7),
    surface: Colors.white,
    ink: Color(0xFF14171F),
    inkSoft: Color(0xFF3B4250),
    // Darkened slightly from 6A7282 so small text meets 4.5:1 on white.
    muted: Color(0xFF5B6372),
    line: Color(0xFFE6E8EC),
    track: Color(0xFFE8EAEE),
    primarySoft: Color(0xFFEAF0FE),
    foundSoft: Color(0xFFE6F6EE),
    lostSoft: Color(0xFFFDECEC),
    warnSoft: Color(0xFFFEF3E2),
    warnLine: Color(0xFFF6D9A8),
    snack: Color(0xFF14171F),
  );

  static const dark = AppPalette(
    bg: Color(0xFF0F1115),
    surface: Color(0xFF1A1D24),
    ink: Color(0xFFE9EBEF),
    inkSoft: Color(0xFFC9CED6),
    // Meets 4.5:1 on both bg and surface.
    muted: Color(0xFF9CA3AF),
    line: Color(0xFF2D323C),
    track: Color(0xFF2A2F38),
    primarySoft: Color(0xFF1C2847),
    foundSoft: Color(0xFF13301F),
    lostSoft: Color(0xFF3A1A1C),
    warnSoft: Color(0xFF33260F),
    warnLine: Color(0xFF6B4D1C),
    snack: Color(0xFF2D323C),
  );
}

/// App colours. Brand/status colours are constant; the neutral ones are
/// read from the active [AppPalette], so they follow light/dark mode.
///
/// The active palette is switched by [ThemeController], which also forces
/// the whole widget tree to rebuild so every screen picks up the change.
class AppColors {
  AppColors._();

  static AppPalette _palette = AppPalette.light;
  static AppPalette get palette => _palette;
  static bool get isDark => identical(_palette, AppPalette.dark);

  static void usePalette(AppPalette palette) => _palette = palette;

  static Color get bg => _palette.bg;
  static Color get surface => _palette.surface;
  static Color get ink => _palette.ink;
  static Color get inkSoft => _palette.inkSoft;
  static Color get muted => _palette.muted;
  static Color get line => _palette.line;
  static Color get track => _palette.track;
  static Color get snack => _palette.snack;

  static const primary = Color(0xFF2F5BEA);
  static const lost = Color(0xFFE5484D);
  static const found = Color(0xFF1F9D68);
  static const warn = Color(0xFFD97706);

  // Soft tints for banners / highlighted rows.
  static Color get primarySoft => _palette.primarySoft;
  static Color get foundSoft => _palette.foundSoft;
  static Color get lostSoft => _palette.lostSoft;
  static Color get warnSoft => _palette.warnSoft;
  static Color get warnLine => _palette.warnLine;

  // Semantic feedback colours.
  static const success = found;
  static const error = lost;
  static const info = primary;
}

/// Spacing / radius scale so screens stop inventing their own numbers.
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;

  static const radiusSm = 10.0;
  static const radiusMd = 14.0;
  static const radiusLg = 18.0;
}

class AppTheme {
  AppTheme._();

  static const _minTap = Size(48, 52);

  static ThemeData get light => build(AppPalette.light, Brightness.light);
  static ThemeData get dark => build(AppPalette.dark, Brightness.dark);

  static ThemeData build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: p.surface,
      onSurface: p.ink,
      error: AppColors.error,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    );
    const buttonText = TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700);

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: p.bg,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: base.textTheme
          .apply(bodyColor: p.ink, displayColor: p.ink)
          .copyWith(
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: p.ink,
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
            bodyMedium: TextStyle(
              fontSize: 14.5,
              height: 1.4,
              color: p.ink,
            ),
            bodySmall: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: p.muted,
            ),
            labelLarge: buttonText,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: p.ink),
        titleTextStyle: TextStyle(
          color: p.ink,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : p.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : p.muted,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: _minTap,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: _minTap,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: _minTap,
          shape: buttonShape,
          textStyle: buttonText,
          side: BorderSide(color: p.line, width: 1.5),
          foregroundColor: p.ink,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        extendedTextStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: p.muted),
        labelStyle: TextStyle(color: p.muted),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
        border: border(p.line),
        enabledBorder: border(p.line),
        focusedBorder: border(AppColors.primary, 2),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        side: BorderSide(color: p.line),
        labelStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: p.ink,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: p.ink,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14.5,
          height: 1.45,
          color: p.ink,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: p.track,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.snack,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: const Color(0xFF9DB5FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.line,
        space: 1,
        thickness: 1,
      ),
    );
  }
}
