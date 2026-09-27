import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/error/auth_error_translator.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<AppUser?> get authStateChanges => _remote.authStateChanges;

  @override
  AppUser? get currentUser => _remote.currentUser;

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.signIn(email: email, password: password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(translateAuthError(e.message)));
    } on supabase.AuthApiException catch (e) {
      return Left(AuthFailure(translateAuthError(e.message)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser>> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final user = await _remote.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(translateAuthError(e.message)));
    } on supabase.AuthApiException catch (e) {
      return Left(AuthFailure(translateAuthError(e.message)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remote.signOut();
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(translateAuthError(e.message)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> signInWithGoogle() async {
    try {
      await _remote.signInWithGoogle();
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(translateAuthError(e.message)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _remote.sendPasswordResetEmail(email);
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(translateAuthError(e.message)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> requestSellerUpgrade({String? note}) async {
    try {
      await _remote.requestSellerUpgrade(note: note);
      return const Right(unit);
    } on AuthException catch (e) {
      // These messages come straight from our own RPC (already
      // user-facing Bosnian text), so they're passed through as-is
      // instead of through translateAuthError.
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> setPassword(String password) async {
    try {
      await _remote.setPassword(password);
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(translateAuthError(e.message)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProfile({
    String? fullName,
    String? bio,
    int? cityId,
    Uint8List? avatarBytes,
  }) async {
    try {
      await _remote.updateProfile(
        fullName: fullName,
        bio: bio,
        cityId: cityId,
        avatarBytes: avatarBytes,
      );
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
