import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class SendPasswordResetEmailUseCase {
  const SendPasswordResetEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call(String email) {
    if (email.trim().isEmpty || !email.contains('@')) {
      return Future.value(
        const Left(ValidationFailure('Unesite validan e-mail.')),
      );
    }
    return _repository.sendPasswordResetEmail(email.trim());
  }
}
