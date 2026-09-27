import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/config/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_role.dart';
import '../models/app_user_model.dart';

/// Talks directly to the Supabase Auth SDK (+ the `public.profiles` table
/// for role info). Throws [AuthException] / [ServerException] on failure;
/// never returns a [Failure] itself — that mapping happens one layer up, in
/// the repository implementation.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client) {
    // One shared subscription does the (potentially slow) profile fetch;
    // every caller of `authStateChanges` gets its own view over the cached
    // result instead of triggering a fresh DB round-trip.
    _client.auth.onAuthStateChange.asyncMap(_toAppUserModel).listen((user) {
      _cachedUser = user;
      _hasEmittedOnce = true;
      _controller.add(user);
    });
  }

  final supabase.SupabaseClient _client;
  final _controller = StreamController<AppUserModel?>.broadcast();
  AppUserModel? _cachedUser;
  bool _hasEmittedOnce = false;

  AppUserModel? get currentUser => _cachedUser;

  /// Replays the latest known auth state to every new listener before
  /// forwarding live updates — a plain broadcast stream only delivers
  /// events emitted *after* you subscribe, which would leave a screen
  /// that starts watching this late (e.g. right after an OAuth redirect
  /// already flipped the router to the home route) stuck with no user.
  Stream<AppUserModel?> get authStateChanges async* {
    if (_hasEmittedOnce) yield _cachedUser;
    yield* _controller.stream;
  }

  Future<AppUserModel?> _toAppUserModel(supabase.AuthState event) {
    final user = event.session?.user;
    return user == null ? Future.value(null) : _fetchProfile(user);
  }

  /// Reads (and, if missing, creates) the `public.profiles` row for [user]
  /// via the `ensure_profile()` RPC — deliberately not a plain `SELECT`,
  /// since this app doesn't rely on the `auth.users` trigger to have
  /// created that row already (triggers directly on `auth.users` have
  /// been known to get silently wiped by Supabase's own managed upgrades).
  /// Falls back to the 'kupac' default if even that fails (e.g. offline)
  /// rather than failing the whole sign-in.
  Future<AppUserModel> _fetchProfile(supabase.User user) async {
    try {
      final rows = await _client.rpc('ensure_profile') as List;
      final row = rows.first as Map<String, dynamic>;
      return AppUserModel(
        id: user.id,
        email: user.email ?? '',
        role: AppRole.fromDb(row['role'] as String),
        hasPasswordIdentity: row['has_password'] as bool,
        fullName:
            row['full_name'] as String? ??
            user.userMetadata?['full_name'] as String?,
      );
    } catch (_) {
      return AppUserModel.fromSupabaseUser(user, role: AppRole.kupac);
    }
  }

  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException('Prijava nije uspjela.');
      }
      return _fetchProfile(user);
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Right after sign-up there is no active session yet when the project
  /// requires e-mail confirmation, so the (RLS-protected) profile can't be
  /// read — but every new account always starts as 'kupac' by design, so
  /// that's returned directly without a DB round-trip.
  Future<AppUserModel> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: fullName == null ? null : {'full_name': fullName},
        emailRedirectTo: AppConstants.oauthRedirectUrl,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException('Registracija nije uspjela.');
      }
      // Supabase deliberately returns a "successful" response with no
      // identities (and sends no e-mail) when signUp() is called with an
      // address that's already registered and confirmed — to avoid leaking
      // which e-mails exist in the system. Surface that as the same
      // "already registered" error translateAuthError already handles,
      // instead of pretending a new account was created.
      if (user.identities?.isEmpty ?? false) {
        throw const AuthException('User already registered');
      }
      return AppUserModel(
        id: user.id,
        email: user.email ?? '',
        role: AppRole.kupac,
        hasPasswordIdentity: true, // just signed up with a password
        fullName: fullName,
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: AppConstants.oauthRedirectUrl,
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: AppConstants.oauthRedirectUrl,
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Adds an e-mail/password identity to the currently signed-in user
  /// (requires an active session). This is how a Google-only account gets
  /// a password — same `user.id`, no new account, no old password needed.
  ///
  /// Explicitly re-fetches and re-broadcasts the profile afterwards instead
  /// of relying solely on the `USER_UPDATED` event Supabase's SDK fires on
  /// its own: that event can race ahead of the `mark_password_set()` RPC
  /// below, so the profile it would read might still say `has_password =
  /// false` for a moment. This call is the one guaranteed to be correct.
  Future<void> setPassword(String password) async {
    try {
      await _client.auth.updateUser(
        supabase.UserAttributes(password: password),
      );
      await _client.rpc('mark_password_set');

      final user = _client.auth.currentUser;
      if (user != null) {
        final refreshed = await _fetchProfile(user);
        _cachedUser = refreshed;
        _hasEmittedOnce = true;
        _controller.add(refreshed);
      }
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } on supabase.PostgrestException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<String> requestSellerUpgrade({String? note}) async {
    try {
      final id = await _client.rpc(
        'request_seller_upgrade',
        params: {'note': note},
      );
      return id as String;
    } on supabase.PostgrestException catch (e) {
      throw AuthException(e.message);
    }
  }
}
