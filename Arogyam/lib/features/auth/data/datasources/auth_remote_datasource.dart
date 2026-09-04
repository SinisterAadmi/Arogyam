import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../../../app/config/environment.dart';

class AuthRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(baseUrl: '${AppConfig.baseUrl}/auth'));

  Future<AuthResponse> login(String idToken) async {
    try {
      final response = await _dio.post('/login', data: {'idToken': idToken});
      return AuthResponse.fromJson(response.data);
    } catch (e, stackTrace) {
      debugPrint('[Auth] error: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<AuthResponse> signup({
    required String idToken,
    required String name,
    String? dob,
    String? gender,
  }) async {
    try {
      final response = await _dio.post('/signup', data: {
        'idToken': idToken,
        'name': name,
        'dob': dob,
        'gender': gender,
      });
      return AuthResponse.fromJson(response.data);
    } catch (e, stackTrace) {
      debugPrint('[Auth] error: $e\n$stackTrace');
      rethrow;
    }
  }
}
