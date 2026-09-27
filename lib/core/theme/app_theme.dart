import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_surface_colors.dart';

/// Light/dark [ThemeData] built from a single Material 3 color scheme seed.
///
/// Design intent: flat, neutral surfaces (no gradient hero blocks inside
/// the app shell — those are reserved for the auth/onboarding screens),
/// soft shadow-based elevation instead of borders, generous spacing, and
/// one restrained accent color.
abstract final class AppTheme {
  static ThemeData light() => _themeFrom(Brightness.light);

  static ThemeData dark() => _themeFrom(Brightness.dark);

  static ThemeData _themeFrom(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surfaceColors = isDark
        ? AppSurfaceColors.dark
        : AppSurfaceColors.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
      surface: surfaceColors.surface,
    );
    final baseTextTheme = GoogleFonts.manropeTextTheme();
    // GoogleFonts.manropeTextTheme() carries fixed light-mode colors (it's
    // not derived from our colorScheme) — .apply() re-tints every style to
    // the current brightness so headings don't render as dark-on-dark once
    // dark mode is on.
    final textTheme = baseTextTheme
        .copyWith(
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleSmall: baseTextTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 1.35),
          bodySmall: baseTextTheme.bodySmall?.copyWith(height: 1.3),
        )
        .apply(
          bodyColor: surfaceColors.textPrimary,
          displayColor: surfaceColors.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: [surfaceColors],
      scaffoldBackgroundColor: surfaceColors.background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColors.background,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: surfaceColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : surfaceColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.transparent : surfaceColors.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.transparent : surfaceColors.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
        hintStyle: TextStyle(color: surfaceColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: surfaceColors.outline,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColors.surface,
        elevation: 0,
        height: 68,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colorScheme.primary : surfaceColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.primary : surfaceColors.textMuted,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColors.background,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}
