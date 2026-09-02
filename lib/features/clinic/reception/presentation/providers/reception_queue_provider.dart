import 'package:flutter/foundation.dart';
import '../../data/models/reception_queue_models.dart';
import '../../domain/repositories/reception_repository.dart';

class ReceptionQueueProvider extends ChangeNotifier {
  final ReceptionRepository repository;

  ReceptionLiveQueueResponse? _queueData;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'waiting', 'serving', 'done', 'absent'

  ReceptionQueueProvider({required this.repository});

  ReceptionLiveQueueResponse? get queueData => _queueData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;

  List<ReceptionQueueToken> get allTokens => _queueData?.tokens ?? [];

  List<ReceptionQueueToken> get filteredTokens {
    if (_queueData == null) return [];
    if (_selectedFilter == 'all') return _queueData!.tokens;
    return _queueData!.tokens.where((t) => t.status == _selectedFilter).toList();
  }

  String get clinicName => _queueData?.clinicName ?? 'Sunrise Medical Center';
  int get totalToday => _queueData?.stats.totalToday ?? 0;
  int get waitingCount => _queueData?.stats.waitingCount ?? 0;
  int? get currentlyServing => _queueData?.stats.currentlyServing;

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> fetchQueue({bool silent = false}) async {
    if (!silent && _queueData == null) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      final response = await repository.getLiveQueue();
      _queueData = response;
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[ReceptionQueueProvider] fetchQueue error: $e\n$stackTrace');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String tokenId, String newStatus) async {
    try {
      final updatedToken = await repository.updateTokenStatus(tokenId, newStatus);
      if (_queueData != null) {
        final index = _queueData!.tokens.indexWhere((t) => t.id == tokenId);
        if (index != -1) {
          final updatedTokens = List<ReceptionQueueToken>.from(_queueData!.tokens);
          updatedTokens[index] = updatedToken;

          final waiting = updatedTokens.where((t) => t.status == 'waiting').length;
          final serving = updatedTokens.where((t) => t.status == 'serving').isNotEmpty
              ? updatedTokens.firstWhere((t) => t.status == 'serving').tokenNumber
              : null;

          _queueData = ReceptionLiveQueueResponse(
            clinicId: _queueData!.clinicId,
            clinicName: _queueData!.clinicName,
            isLiveQueueActive: _queueData!.isLiveQueueActive,
            stats: ReceptionClinicStats(
              totalToday: updatedTokens.length,
              waitingCount: waiting,
              currentlyServing: serving,
            ),
            tokens: updatedTokens,
          );
          notifyListeners();
        }
      }
      return true;
    } catch (e, stackTrace) {
      debugPrint('[ReceptionQueueProvider] updateStatus error: $e\n$stackTrace');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
