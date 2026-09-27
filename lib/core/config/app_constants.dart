/// App-wide constants that aren't secrets (those live in `.env`).
abstract final class AppConstants {
  /// Deep link Supabase redirects back to after an OAuth (Google) sign-in.
  /// Must match the scheme registered in AndroidManifest.xml / Info.plist,
  /// and be added as a Redirect URL in Supabase Auth settings.
  static const oauthRedirectUrl = 'plodovisela://login-callback';
}
