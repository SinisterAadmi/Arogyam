import '../../domain/repositories/reception_repository.dart';
import '../datasources/reception_remote_datasource.dart';
import '../models/reception_queue_models.dart';

class ReceptionRepositoryImpl implements ReceptionRepository {
  final ReceptionRemoteDataSource _remoteDataSource;

  ReceptionRepositoryImpl({ReceptionRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ReceptionRemoteDataSource();

  @override
  Future<ReceptionLiveQueueResponse> getLiveQueue() => _remoteDataSource.getLiveQueue();

  @override
  Future<ReceptionQueueToken> updateTokenStatus(String tokenId, String status) =>
      _remoteDataSource.updateTokenStatus(tokenId, status);
}
