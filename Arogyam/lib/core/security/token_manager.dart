import 'package:firebase_auth/firebase_auth.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  String? _abhaId;

  Future<void> saveAbhaId(String id) async {
    _abhaId = id;
  }

  Future<String?> getAbhaId() async {
    return _abhaId;
  }

  Future<String?> getAccessToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<String?> refreshToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken(true);
  }

  Future<void> clear() async {
    _abhaId = null;
    await FirebaseAuth.instance.signOut();
  }
}
