class ShareMedicalHistory {
  Future<String> execute(String targetId, List<String> categories) async {
    // Simulate consent generation
    await Future.delayed(const Duration(seconds: 1));
    return 'CONSENT_TOKEN_XYZ';
  }
}
