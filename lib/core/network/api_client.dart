import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import '../utils/app_logger.dart';
import 'interceptors/logging_interceptor.dart';

class ApiClient {
  ApiClient._internal() {
    _init();
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  /// Plugin-free instance for tests/CLI tools: fixed base URL + Basic
  /// auth header, NO AuthInterceptor (which needs flutter_secure_storage,
  /// a platform plugin unavailable in plain `flutter test`).
  ApiClient.withBasicAuth({
    required String baseUrl,
    required String username,
    required String password,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Authorization':
            'Basic ${AuthInterceptor.buildBasicToken(username, password)}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    if (kDebugMode) _dio.interceptors.add(_apiLogInterceptor());
  }

  /// Logs every request/response/error. NEVER logs headers — the
  /// Authorization header is a credential and must not reach logcat.
  static Interceptor _apiLogInterceptor() {
    final started = Expando<DateTime>();
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        started[options] = DateTime.now();
        log.i('--> ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        final t = started[response.requestOptions];
        final ms = t == null
            ? '?'
            : DateTime.now().difference(t).inMilliseconds.toString();
        final body = response.data.toString();
        log.i('<-- ${response.statusCode} ${response.requestOptions.uri} '
            '(${ms}ms, ${body.length} chars)');
        log.d(body.length > 600 ? '${body.substring(0, 600)} ...[cut]' : body);
        handler.next(response);
      },
      onError: (e, handler) {
        log.e('<-- FAILED ${e.requestOptions.uri}: '
            '${e.response?.statusCode ?? e.type} ${e.message}');
        handler.next(e);
      },
    );
  }

  late Dio _dio;

  Dio get dio => _dio;

  void _init({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.baseUrl,
        connectTimeout:
        const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout:
        const Duration(milliseconds: ApiConstants.receiveTimeout),
        sendTimeout:
        const Duration(milliseconds: ApiConstants.sendTimeout),
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
        },
      ),
    );

    // Decode large JSON responses on a background isolate so the
    // UI (and loading spinners) never freeze during big downloads.
    _dio.transformer = BackgroundTransformer();

    _dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  /// Update base URL dynamically
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// The server currently targeted (compiled default or Settings
  /// override) — reachability probes ping this.
  String get baseUrl => _dio.options.baseUrl;

  Future<Response> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
      String path, {
        dynamic data,
        Options? options,
      }) async {
    return await _dio.put(path, data: data, options: options);
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(path,
        queryParameters: queryParameters, options: options);
  }
}