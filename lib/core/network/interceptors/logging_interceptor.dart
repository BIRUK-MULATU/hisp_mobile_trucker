import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.i(
        '→ ${options.method} ${options.uri}\n'
        'Headers: ${_sanitizeHeaders(options.headers)}\n'
        'Data: ${_preview(options.data)}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.d(
        '← ${response.statusCode} ${response.requestOptions.uri}\n'
        'Data: ${_preview(response.data)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      '✗ ${err.response?.statusCode} ${err.requestOptions.uri}\n'
      'Message: ${err.message}\n'
      'Response: ${err.response?.data}',
    );
    handler.next(err);
  }

  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      sanitized['Authorization'] = '***REDACTED***';
    }
    return sanitized;
  }

  // Never stringifies whole collections — large payloads would
  // block the UI isolate just to be truncated afterwards.
  String _preview(dynamic data) {
    if (data == null) return 'null';
    if (data is List) return 'List(${data.length} items)';
    if (data is Map) return 'Map(keys: ${data.keys.join(', ')})';
    final text = data.toString();
    return text.length > 500 ? '${text.substring(0, 500)}…' : text;
  }
}
