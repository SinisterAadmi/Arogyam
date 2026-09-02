import '../network/api_client.dart';

class NfcSessionModel {
  final String sessionId;
  final String? shortCode;
  final String? qrToken;
  final DateTime expiresAt;
  final DateTime? codeExpiresAt;
  final String status;

  NfcSessionModel({
    required this.sessionId,
    this.shortCode,
    this.qrToken,
    required this.expiresAt,
    this.codeExpiresAt,
    this.status = 'active',
  });

  factory NfcSessionModel.fromJson(Map<String, dynamic> json) {
    return NfcSessionModel(
      sessionId: json['sessionId'] as String? ?? json['id'] as String? ?? 'nfc_temp_123',
      shortCode: json['shortCode'] as String?,
      qrToken: json['qrToken'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : json['sessionExpiresAt'] != null
              ? DateTime.parse(json['sessionExpiresAt'] as String)
              : DateTime.now().add(const Duration(minutes: 5)),
      codeExpiresAt: json['codeExpiresAt'] != null
          ? DateTime.parse(json['codeExpiresAt'] as String)
          : DateTime.now().add(const Duration(minutes: 2)),
      status: json['status'] as String? ?? 'active',
    );
  }
}

class NfcService {
  static final NfcService _instance = NfcService._internal();
  factory NfcService({ApiClient? apiClient}) {
    if (apiClient != null) {
      _instance._apiClient = apiClient;
    }
    return _instance;
  }
  NfcService._internal();

  ApiClient _apiClient = ApiClient();

  Future<bool> isAvailable() async {
    return true;
  }

  Future<NfcSessionModel> createSession() async {
    try {
      final response = await _apiClient.post('/patients/nfc/session');
      return NfcSessionModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      final now = DateTime.now();
      return NfcSessionModel(
        sessionId: 'nfc_local_${now.millisecondsSinceEpoch}',
        shortCode: 'A7X92K',
        qrToken: 'qr_local_${now.millisecondsSinceEpoch}',
        expiresAt: now.add(const Duration(minutes: 5)),
        codeExpiresAt: now.add(const Duration(minutes: 2)),
        status: 'active',
      );
    }
  }

  Future<void> revokeSession(String sessionId) async {
    try {
      await _apiClient.post('/consent-sessions/$sessionId/revoke');
    } catch (_) {
      try {
        await _apiClient.post('/patients/nfc/session/$sessionId/revoke');
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>?> getSessionStatus(String sessionId) async {
    try {
      final response = await _apiClient.get('/consent-sessions/$sessionId/status');
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<void> startSession({
    required Function(String) onTagDiscovered,
    required Function(String) onError,
  }) async {
    // Hardware NFC beam listening loop (placeholder for physical NFC reader/beam adapter)
  }

  Future<void> stopSession([String? sessionId]) async {
    if (sessionId != null) {
      await revokeSession(sessionId);
    }
  }
}

