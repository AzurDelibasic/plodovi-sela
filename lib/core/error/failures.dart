import 'package:equatable/equatable.dart';

/// Base type for all domain-level failures.
///
/// Repositories never throw raw exceptions to the domain/presentation
/// layers; they catch data-layer exceptions and return a [Failure] via
/// `Either<Failure, T>` (see `fpdart`) instead.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Neočekivana greška na serveru.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Nema internet konekcije.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Traženi resurs nije pronađen.']);
}
