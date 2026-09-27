/// Exceptions thrown by the data layer (datasources). Repository
/// implementations catch these and map them to a [Failure].
class ServerException implements Exception {
  const ServerException([this.message = 'Neočekivana greška na serveru.']);

  final String message;
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'Nema internet konekcije.']);

  final String message;
}
