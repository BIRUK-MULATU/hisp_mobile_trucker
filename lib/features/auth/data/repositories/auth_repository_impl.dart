import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorage _secureStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorage secureStorage,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage;

  @override
  Future<UserEntity> login({
    required String username,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.login(
        username: username,
        password: password,
      );
      return user;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearAll();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _secureStorage.isLoggedIn();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // The /me response is stored at login, so the session can be
    // restored without a network call (offline login).
    final data = await _secureStorage.getUserData();
    if (data == null) return null;
    try {
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
