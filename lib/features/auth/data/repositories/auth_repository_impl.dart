import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl {
  final AuthRemoteDataSource _remoteDataSource = AuthRemoteDataSource();

  Future<AuthResponse> login(String idToken) async {
    return await _remoteDataSource.login(idToken);
  }

  Future<AuthResponse> signup({
    required String idToken,
    required String name,
    String? dob,
    String? gender,
  }) async {
    return await _remoteDataSource.signup(
      idToken: idToken,
      name: name,
      dob: dob,
      gender: gender,
    );
  }
}
