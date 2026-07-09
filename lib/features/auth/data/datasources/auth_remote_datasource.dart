import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/interceptors/auth_interceptor.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String username,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;

  AuthRemoteDataSourceImpl({
    required ApiClient apiClient,
    required SecureStorage secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final token = AuthInterceptor.buildBasicToken(username, password);

      final response = await _apiClient.get(
        '/me',
        queryParameters: {
          'fields':
              'id,username,firstName,surname,email,phoneNumber,avatar,'
              'authorities,organisationUnits[id,displayName,shortName,code,level,path]',
        },
        options: Options(
          headers: {'Authorization': 'Basic $token'},
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final data = response.data;

      // Detect HTML response
      if (data is String && data.trimLeft().startsWith('<')) {
        throw const UnauthorizedException(
            message: 'Invalid server URL or credentials.');
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const UnauthorizedException();
      }

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        await _secureStorage.saveUsername(username);
        await _secureStorage.saveUserData(data);

        final orgUnits =
            (data['organisationUnits'] as List<dynamic>?)
                    ?.map((e) => e as Map<String, dynamic>)
                    .toList() ??
                [];
        await _secureStorage.saveOrgUnits(orgUnits);

        return UserModel.fromJson(data);
      }

      throw const ServerException(
          message: 'Unexpected response from server.');
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  Never _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw const TimeoutException();
      case DioExceptionType.connectionError:
        throw const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          throw const UnauthorizedException();
        }
        if (statusCode != null && statusCode >= 500) {
          throw ServerException(statusCode: statusCode);
        }
        throw ServerException(
          message: 'Request failed with status $statusCode',
          statusCode: statusCode,
        );
      default:
        throw ServerException(message: e.message ?? 'Unknown error');
    }
  }
}
