import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// A single, testable unit of business logic — "log the user in".
///
/// Kept as its own class (rather than calling the repository directly from
/// the UI) so validation/business rules have one obvious place to live as
/// the app grows.
class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty || password.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Unesite e-mail i lozinku.')),
      );
    }
    return _repository.signIn(email: email.trim(), password: password);
  }
}
