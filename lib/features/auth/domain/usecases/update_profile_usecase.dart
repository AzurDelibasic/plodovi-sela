import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call({
    String? fullName,
    String? farmName,
    String? bio,
    int? cityId,
    Uint8List? avatarBytes,
  }) {
    if (fullName != null && fullName.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Ime ne može biti prazno.')),
      );
    }
    return _repository.updateProfile(
      fullName: fullName?.trim(),
      farmName: farmName?.trim(),
      bio: bio,
      cityId: cityId,
      avatarBytes: avatarBytes,
    );
  }
}
