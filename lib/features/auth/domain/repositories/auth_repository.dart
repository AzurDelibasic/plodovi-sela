import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

/// Contract the data layer must fulfill. The presentation layer only ever
/// talks to this interface, never to Supabase directly.
abstract interface class AuthRepository {
  /// Emits the current user whenever the auth session changes, and `null`
  /// when signed out.
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, AppUser>> signUp({
    required String email,
    required String password,
    String? fullName,
  });

  Future<Either<Failure, Unit>> signOut();

  /// Starts the Google OAuth browser flow. On success, [authStateChanges]
  /// emits the signed-in user once the app receives the redirect deep link
  /// — this method itself does not resolve to a user.
  Future<Either<Failure, Unit>> signInWithGoogle();

  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  /// Submits a request for the current (kupac) user to become a prodavac.
  /// The server (RPC) re-validates the role and rejects duplicate pending
  /// requests — the client-side check is only for a snappier UI.
  Future<Either<Failure, Unit>> requestSellerUpgrade({String? note});

  /// Adds an e-mail/password sign-in method to the current (Google-only)
  /// account. See [AppUser.hasPasswordIdentity].
  Future<Either<Failure, Unit>> setPassword(String password);
}
