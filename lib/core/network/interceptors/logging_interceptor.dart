import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
      if (sanitizedHeaders.containsKey('Authorization')) {
        sanitizedHeaders['Authorization'] = '[REDACTED]';
      }

      print('REQUEST[${options.method}] => PATH: ${options.path}');
      print('HEADERS: $sanitizedHeaders');
      if (options.data != null) {
        print('BODY: ${_redactSensitiveData(options.data)}');
      }
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      if (response.data != null) {
        print('BODY: ${_redactSensitiveData(response.data)}');
      }
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      print('MESSAGE: ${err.message}');
    }
    return handler.next(err);
  }

  dynamic _redactSensitiveData(dynamic data) {
    if (data is Map) {
      final redacted = Map<String, dynamic>.from(data);
      const sensitiveKeys = ['token', 'abhaId', 'otp', 'password', 'medicalRecords', 'prescriptions'];
      for (var key in sensitiveKeys) {
        if (redacted.containsKey(key)) {
          redacted[key] = '[REDACTED]';
        }
      }
      return redacted;
    }
    return data;
  }
}
