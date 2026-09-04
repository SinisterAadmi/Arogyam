import '../../data/models/reception_queue_models.dart';

abstract class ReceptionRepository {
  Future<ReceptionLiveQueueResponse> getLiveQueue();
  Future<List<ReceptionUpcomingAppointment>> getUpcomingAppointments();
  Future<ReceptionQueueToken> updateTokenStatus(String tokenId, String status);
}
