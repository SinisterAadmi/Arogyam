import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_client.dart';
import '../models/reception_queue_models.dart';

class ReceptionRemoteDataSource {
  final ApiClient _apiClient;

  ReceptionRemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<ReceptionLiveQueueResponse> getLiveQueue() async {
    try {
      final response = await _apiClient.get('/reception/queue');
      return ReceptionLiveQueueResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('[ReceptionRemoteDataSource] getLiveQueue error: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<List<ReceptionUpcomingAppointment>> getUpcomingAppointments() async {
    try {
      final response = await _apiClient.get('/reception/queue/upcoming');
      return (response.data as List)
          .map((item) => ReceptionUpcomingAppointment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('[ReceptionRemoteDataSource] getUpcomingAppointments error: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<ReceptionQueueToken> updateTokenStatus(String tokenId, String status) async {
    try {
      final response = await _apiClient.patch(
        '/reception/queue/$tokenId/status',
        data: {'status': status},
      );
      return ReceptionQueueToken.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('[ReceptionRemoteDataSource] updateTokenStatus error: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<ConsentVerificationResult> verifyShortCode(String code) async {
    try {
      final response = await _apiClient.post(
        '/consent-sessions/verify-code',
        data: {'code': code},
      );
      return ConsentVerificationResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('[ReceptionRemoteDataSource] verifyShortCode error: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<ConsentVerificationResult> verifyQrToken(String qrToken) async {
    try {
      final response = await _apiClient.post(
        '/consent-sessions/verify-qr',
        data: {'qrToken': qrToken},
      );
      return ConsentVerificationResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('[ReceptionRemoteDataSource] verifyQrToken error: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<List<AiCallbackItem>> getAiCallbacks() async {
    try {
      final response = await _apiClient.get('/reception/ai-callbacks');
      final list = response.data as List<dynamic>? ?? [];
      return list.map((item) => AiCallbackItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      debugPrint('[ReceptionRemoteDataSource] getAiCallbacks error: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> resolveAiCallback(String id) async {
    try {
      await _apiClient.patch('/reception/ai-callbacks/$id/resolve');
    } catch (e, stackTrace) {
      debugPrint('[ReceptionRemoteDataSource] resolveAiCallback error: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<ClinicAnalytics> getAnalytics() async {
    try {
      final response = await _apiClient.get('/reception/analytics');
      return ClinicAnalytics.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('[ReceptionRemoteDataSource] getAnalytics error: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<ReceptionClinicModel> getClinic() async {
    try {
      final response = await _apiClient.get('/reception/clinic');
      return ReceptionClinicModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('[ReceptionRemoteDataSource] getClinic error: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<ReceptionClinicModel> updateClinic({
    String? name,
    String? address,
    String? phone,
    String? specialty,
    String? operatingHours,
    String? description,
    double? latitude,
    double? longitude,
    bool? isOpen,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (address != null) data['address'] = address;
      if (phone != null) data['phone'] = phone;
      if (specialty != null) data['specialty'] = specialty;
      if (operatingHours != null) data['operatingHours'] = operatingHours;
      if (description != null) data['description'] = description;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (isOpen != null) data['isOpen'] = isOpen;

      final response = await _apiClient.patch('/reception/clinic', data: data);
      return ReceptionClinicModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('[ReceptionRemoteDataSource] updateClinic error: $e\n$stackTrace');
      rethrow;
    }
  }
}
