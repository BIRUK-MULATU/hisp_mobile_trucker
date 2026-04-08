import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  Future<UserEntity> call({
    required String username,
    required String password,
  }) async {
    // Trim whitespace — common user input mistake
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty) {
      throw Exception('Username cannot be empty.');
    }
    if (cleanPassword.isEmpty) {
      throw Exception('Password cannot be empty.');
    }

    return await _repository.login(
      username: cleanUsername,
      password: cleanPassword,
    );
  }
}
