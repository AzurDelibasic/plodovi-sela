import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class SetPasswordUseCase {
  const SetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call(String password) {
    if (password.length < 6) {
      return Future.value(
        const Left(
          ValidationFailure('Lozinka mora imati najmanje 6 karaktera.'),
        ),
      );
    }
    return _repository.setPassword(password);
  }
}
