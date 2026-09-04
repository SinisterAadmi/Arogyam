import '../../data/models/abha_model.dart';

abstract class AbhaRepository {
  Future<AbhaModel> getAbhaStatus();
  Future<void> linkAbha(String abhaId, String otp);
}
