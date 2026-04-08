// ── Exceptions (Data Layer) ────────────────────────────────────────────────
class AppException implements Exception {
  final String message;
  final int? statusCode;
  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException: $message (code: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({super.message = 'No internet connection.', super.statusCode});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({super.message = 'Invalid username or password.', super.statusCode = 401});
}

class ServerException extends AppException {
  const ServerException({super.message = 'Server error. Please try again.', super.statusCode});
}

class TimeoutException extends AppException {
  const TimeoutException({super.message = 'Connection timed out. Please try again.', super.statusCode});
}

class CacheException extends AppException {
  const CacheException({super.message = 'Local data error.', super.statusCode});
}

// ── Failures (Domain Layer) ────────────────────────────────────────────────
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Invalid username or password.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error. Please try again.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out. Please try again.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
