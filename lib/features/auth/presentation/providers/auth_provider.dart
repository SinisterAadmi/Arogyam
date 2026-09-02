import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/models/user_model.dart';
import '../../../../app/config/environment.dart';
import '../../../../core/security/token_manager.dart';
import '../../../../core/storage/secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthRepositoryImpl _repository = AuthRepositoryImpl();

  UserModel? _user;
  bool _isLoading = false;
  String? _verificationId;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return 'Unable to connect to server. Please check backend connection.';
      }
      if (e.response?.data != null && e.response?.data is Map && e.response?.data['message'] != null) {
        return e.response!.data['message'].toString();
      }
    }
    if (e is FirebaseAuthException) {
      return e.message ?? 'Authentication failed';
    }
    return e.toString();
  }

  Future<void> sendOTP(String phoneNumber, {required Function(String) onCodeSent}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('[Auth] verificationFailed: ${e.code} - ${e.message}');
          _error = _getErrorMessage(e);
          _isLoading = false;
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e, stackTrace) {
      debugPrint('[Auth] error: $e\n$stackTrace');
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResponse?> verifyOTP(String smsCode) async {
    _isLoading = true;
    _error = null;
    if (_verificationId == null) {
      _error = 'Session expired. Please request a new OTP.';
      _isLoading = false;
      notifyListeners();
      return null;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      return await _signInWithCredential(credential);
    } catch (e, stackTrace) {
      debugPrint('[Auth] error: $e\n$stackTrace');
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<AuthResponse?> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken(true);

      if (idToken != null) {
        final response = await _repository.login(idToken);
        if (response.status == 'success' && response.user != null) {
          _user = response.user;
        }
        _isLoading = false;
        notifyListeners();
        return response;
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('[Auth] error: $e\n$stackTrace');
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<AuthResponse?> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Force refresh token to get latest custom claims
      final idToken = await userCredential.user?.getIdToken(true);

      if (idToken != null) {
        final response = await _repository.login(idToken);
        if (response.status == 'success' && response.user != null) {
          _user = response.user;
        }
        _isLoading = false;
        notifyListeners();
        return response;
      }
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] FirebaseAuthException: ${e.code} - ${e.message}');
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e, stackTrace) {
      debugPrint('[Auth] error: $e\n$stackTrace');
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> completeSignup({
    required String name,
    String? dob,
    String? gender,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final idToken = await _auth.currentUser?.getIdToken();
      if (idToken != null) {
        final response = await _repository.signup(
          idToken: idToken,
          name: name,
          dob: dob,
          gender: gender,
        );
        if (response.status == 'success' && response.user != null) {
          _user = response.user;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[Auth] error: $e\n$stackTrace');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      final idToken = await TokenManager().getAccessToken();
      if (idToken != null) {
        // Optional: Notify backend of logout
        final dio = Dio(BaseOptions(baseUrl: '${AppConfig.baseUrl}/auth'));
        await dio.post('/logout', options: Options(headers: {'Authorization': 'Bearer $idToken'}));
      }
    } catch (e, stackTrace) {
      debugPrint('[Auth] error: $e\n$stackTrace');
    }
    await TokenManager().clear();
    await SecureStorage().deleteAll();
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
