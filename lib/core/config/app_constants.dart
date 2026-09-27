import 'package:flutter/foundation.dart';

/// App-wide constants that aren't secrets (those live in `.env`).
abstract final class AppConstants {
  /// Where Supabase redirects back to after an OAuth (Google) sign-in, or
  /// after a password-reset e-mail link.
  ///
  /// - Mobile: a custom deep link scheme (must match AndroidManifest.xml /
  ///   Info.plist).
  /// - Web: the app's own current URL — a real HTTPS page is what the
  ///   browser needs to land back on, not a mobile-only scheme. Computed
  ///   from `Uri.base` rather than hardcoded so it keeps working if the
  ///   site ever moves (custom domain, different GitHub Pages path, ...).
  ///
  /// Both forms must be added to Supabase Auth → URL Configuration →
  /// Redirect URLs, or Supabase will silently fall back to the project's
  /// default Site URL instead.
  static String get oauthRedirectUrl {
    if (kIsWeb) {
      return Uri.base.origin + Uri.base.path;
    }
    return 'plodovisela://login-callback';
  }
}
