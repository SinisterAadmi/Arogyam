import 'package:flutter/foundation.dart';
import '../../../../shared/entities/clinic.dart';
import '../../domain/get_nearby_clinics_usecase.dart';

enum SortOption { distance, waitTime, rating, availability }

class NearbyClinicsProvider extends ChangeNotifier {
  final GetNearbyClinicsUseCase _getNearbyClinicsUseCase;

  List<Clinic> _clinics = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedClinicId;
  SortOption _currentSort = SortOption.distance;

  NearbyClinicsProvider({GetNearbyClinicsUseCase? getNearbyClinicsUseCase})
      : _getNearbyClinicsUseCase =
            getNearbyClinicsUseCase ?? GetNearbyClinicsUseCase() {
    fetchNearbyClinics();
  }

  List<Clinic> get clinics => _clinics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedClinicId => _selectedClinicId;
  SortOption get currentSort => _currentSort;

  String get currentSortLabel {
    switch (_currentSort) {
      case SortOption.distance:
        return 'distance';
      case SortOption.waitTime:
        return 'wait time';
      case SortOption.rating:
        return 'rating';
      case SortOption.availability:
        return 'availability';
    }
  }

  Clinic? get selectedClinic => _clinics.isEmpty
      ? null
      : _clinics.firstWhere(
          (c) => c.id == _selectedClinicId,
          orElse: () => _clinics.first,
        );

  void selectClinic(String id) {
    if (_selectedClinicId != id) {
      _selectedClinicId = id;
      notifyListeners();
    }
  }

  void sortBy(SortOption option) {
    _currentSort = option;
    _sortClinics();
    notifyListeners();
  }

  void _sortClinics() {
    switch (_currentSort) {
      case SortOption.distance:
        _clinics.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case SortOption.waitTime:
        _clinics.sort((a, b) => a.waitTimeMinutes.compareTo(b.waitTimeMinutes));
        break;
      case SortOption.rating:
        _clinics.sort((a, b) => b.rating.compareTo(a.rating)); // Highest first
        break;
      case SortOption.availability:
        // Live queue active first
        _clinics.sort((a, b) {
          if (a.isLiveQueueActive == b.isLiveQueueActive) return 0;
          return a.isLiveQueueActive ? -1 : 1;
        });
        break;
    }
  }

  Future<void> fetchNearbyClinics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedClinics = await _getNearbyClinicsUseCase();
      _clinics = fetchedClinics.toList(); // Create a mutable copy
      _sortClinics(); // Initial sort
      if (_clinics.isNotEmpty && _selectedClinicId == null) {
        _selectedClinicId = _clinics.first.id;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
