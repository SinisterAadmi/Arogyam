import 'package:flutter/foundation.dart';
import '../../data/models/reception_queue_models.dart';
import '../../domain/repositories/reception_repository.dart';

class ReceptionQueueProvider extends ChangeNotifier {
  final ReceptionRepository repository;

  ReceptionLiveQueueResponse? _queueData;
  List<ReceptionUpcomingAppointment> _upcomingAppointments = [];
  bool _isLoading = false;
  bool _isLoadingUpcoming = false;
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'waiting', 'serving', 'done', 'absent'
  int _activeTab = 0; // 0: Today's Queue, 1: Upcoming Appointments

  ReceptionQueueProvider({required this.repository});

  ReceptionLiveQueueResponse? get queueData => _queueData;
  List<ReceptionUpcomingAppointment> get upcomingAppointments => _upcomingAppointments;
  bool get isLoading => _isLoading;
  bool get isLoadingUpcoming => _isLoadingUpcoming;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;
  int get activeTab => _activeTab;

  void setActiveTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

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

      final tokenSummaries = response.tokens
          .map((t) => '#${t.tokenNumber} ${t.patientName} (${t.status}, apptStatus: ${t.appointmentStatus ?? "none"})')
          .toList();
      debugPrint('[DIAGNOSTIC] [ReceptionQueueProvider] Queue refreshed. Currently displaying ${response.tokens.length} tokens for clinic "${response.clinicName}" (totalToday: ${response.stats.totalToday}, waiting: ${response.stats.waitingCount}): $tokenSummaries');

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[ReceptionQueueProvider] fetchQueue error: $e\n$stackTrace');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUpcomingAppointments({bool silent = false}) async {
    if (!silent && _upcomingAppointments.isEmpty) {
      _isLoadingUpcoming = true;
      notifyListeners();
    }

    try {
      _upcomingAppointments = await repository.getUpcomingAppointments();
      final upcomingSummaries = _upcomingAppointments
          .map((a) => '${a.patientName} - Dr. ${a.doctorName} (${a.status}, scheduled: ${a.scheduledAt.toIso8601String()})')
          .toList();
      debugPrint('[DIAGNOSTIC] [ReceptionQueueProvider] Upcoming appointments refreshed. Currently displaying ${_upcomingAppointments.length} upcoming appointments: $upcomingSummaries');
    } catch (e, stackTrace) {
      debugPrint('[ReceptionQueueProvider] fetchUpcomingAppointments error: $e\n$stackTrace');
    } finally {
      _isLoadingUpcoming = false;
      notifyListeners();
    }
  }

  Future<void> fetchAll({bool silent = false}) async {
    await Future.wait([
      fetchQueue(silent: silent),
      fetchUpcomingAppointments(silent: silent),
    ]);
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
