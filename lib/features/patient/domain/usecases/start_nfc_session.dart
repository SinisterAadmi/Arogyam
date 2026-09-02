import '../../../../core/nfc/nfc_service.dart';

class StartNfcSession {
  final NfcService _nfcService;

  StartNfcSession({NfcService? nfcService}) : _nfcService = nfcService ?? NfcService();

  Future<NfcSessionModel> createSession() {
    return _nfcService.createSession();
  }

  Future<void> execute({
    required Function(String) onTagDiscovered,
    required Function(String) onError,
  }) {
    return _nfcService.startSession(onTagDiscovered: onTagDiscovered, onError: onError);
  }

  Future<void> revokeSession(String sessionId) {
    return _nfcService.revokeSession(sessionId);
  }

  Future<Map<String, dynamic>?> getSessionStatus(String sessionId) {
    return _nfcService.getSessionStatus(sessionId);
  }
}
