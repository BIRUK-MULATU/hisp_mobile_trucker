import '../entities/user_entity.dart';
import '../../../../core/errors/exceptions.dart';

abstract class AuthRepository {
  /// Authenticate user with DHIS2 credentials.
  /// Returns [UserEntity] on success, throws [Failure] on error.
  Future<UserEntity> login({
    required String username,
    required String password,
  });

  /// Clear stored credentials and log out.
  Future<void> logout();

  /// Check if user is currently authenticated.
  Future<bool> isAuthenticated();

  /// Get currently logged in user from local storage.
  Future<UserEntity?> getCurrentUser();
}
