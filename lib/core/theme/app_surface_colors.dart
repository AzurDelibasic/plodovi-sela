import 'package:flutter/material.dart';

/// The subset of [AppColors] tokens that must actually invert between light
/// and dark mode (background/surface/outline/text). Registered on
/// [ThemeData.extensions] by `AppTheme` and read via `context.surfaceColors`
/// — this is what lets every widget that was hard-coding a light-mode grey
/// or near-black text color adapt correctly once dark mode ships.
///
/// Brand/accent tokens (the green seed, harvest gold, status colors) stay as
/// plain constants on [AppColors] — they read fine on both backgrounds as
/// alpha-blended chips/icons and don't need a dark variant.
@immutable
class AppSurfaceColors extends ThemeExtension<AppSurfaceColors> {
  const AppSurfaceColors({
    required this.background,
    required this.surface,
    required this.outline,
    required this.textPrimary,
    required this.textMuted,
  });

  final Color background;
  final Color surface;
  final Color outline;
  final Color textPrimary;
  final Color textMuted;

  /// Warm, off-white — matches the light theme's paper-like feel.
  static const light = AppSurfaceColors(
    background: Color(0xFFFAFAF7),
    surface: Color(0xFFFFFFFF),
    outline: Color(0xFFE8E8E3),
    textPrimary: Color(0xFF1B1D1B),
    textMuted: Color(0xFF6E7268),
  );

  /// A warm, soft-black charcoal (not pure black) with a faint green
  /// undertone — keeps the "earthy" feel in the dark instead of turning
  /// cold/neutral grey. Text/outline tones are tuned for AA contrast
  /// against [background] and [surface].
  static const dark = AppSurfaceColors(
    background: Color(0xFF12140F),
    surface: Color(0xFF1B1F16),
    outline: Color(0xFF333A2B),
    textPrimary: Color(0xFFF1F2EA),
    textMuted: Color(0xFFAEB3A2),
  );

  @override
  AppSurfaceColors copyWith({
    Color? background,
    Color? surface,
    Color? outline,
    Color? textPrimary,
    Color? textMuted,
  }) {
    return AppSurfaceColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  AppSurfaceColors lerp(ThemeExtension<AppSurfaceColors>? other, double t) {
    if (other is! AppSurfaceColors) return this;
    return AppSurfaceColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

extension AppSurfaceColorsContext on BuildContext {
  AppSurfaceColors get surfaceColors =>
      Theme.of(this).extension<AppSurfaceColors>() ?? AppSurfaceColors.light;
}
