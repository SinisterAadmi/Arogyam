import '../../data/models/reception_queue_models.dart';

abstract class ReceptionRepository {
  Future<ReceptionLiveQueueResponse> getLiveQueue();
  Future<ReceptionQueueToken> updateTokenStatus(String tokenId, String status);
}
