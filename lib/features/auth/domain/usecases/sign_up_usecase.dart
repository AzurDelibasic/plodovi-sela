import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
    String? fullName,
  }) {
    if (email.trim().isEmpty || password.length < 6) {
      return Future.value(
        const Left(
          ValidationFailure('E-mail je obavezan, lozinka min. 6 karaktera.'),
        ),
      );
    }
    return _repository.signUp(
      email: email.trim(),
      password: password,
      fullName: fullName?.trim(),
    );
  }
}
