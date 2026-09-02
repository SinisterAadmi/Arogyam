import 'package:dio/dio.dart';
import '../../security/token_manager.dart';

class RefreshTokenInterceptor extends Interceptor {
  final Dio _dio;

  RefreshTokenInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Guard against infinite retry loops
      if (err.requestOptions.headers.containsKey('x-retry')) {
        return handler.next(err);
      }

      try {
        final newToken = await TokenManager().refreshToken();
        if (newToken != null) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          options.headers['x-retry'] = 'true';
          
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (e) {
        // Refresh failed, propagate the original 401 error
        // The AuthProvider or a global listener should handle the logout/redirect
      }
    }
    return handler.next(err);
  }
}
