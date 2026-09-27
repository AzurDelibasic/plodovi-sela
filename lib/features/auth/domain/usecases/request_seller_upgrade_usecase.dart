import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class RequestSellerUpgradeUseCase {
  const RequestSellerUpgradeUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call({String? note}) {
    return _repository.requestSellerUpgrade(note: note);
  }
}
