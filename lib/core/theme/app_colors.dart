import 'package:flutter/material.dart';

/// App color tokens. Keep all raw color values here so the rest of the
/// codebase references semantic names instead of hex codes.
///
/// Palette: a muted forest green as the single accent, everything else
/// neutral — the restraint is deliberate (an accent used everywhere stops
/// reading as an accent).
abstract final class AppColors {
  static const seed = Color(0xFF2F6B4F);
  static const secondarySeed = Color(0xFFB8923D); // harvest gold, sparingly
  static const error = Color(0xFFBA1A1A);

  // Background/surface/outline/text tokens now live on [AppSurfaceColors]
  // (see app_surface_colors.dart) since those must invert for dark mode —
  // read them via `context.surfaceColors` instead.

  // Order status accents — muted, not primary-colored, so they read as
  // state rather than as calls to action.
  static const statusPending = Color(0xFFB8923D);
  static const statusConfirmed = Color(0xFF3B6EA8);
  static const statusReady = Color(0xFF7A5CA8);
  static const statusCancelled = Color(0xFF9A9A94);
}
