import 'dart:convert';
import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Basic $token';
    }
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired — clear storage (router will redirect to login)
      _secureStorage.clearAll();
    }
    handler.next(err);
  }

  /// Build Basic Auth token from username and password
  static String buildBasicToken(String username, String password) {
    final credentials = '$username:$password';
    return base64Encode(utf8.encode(credentials));
  }
}
