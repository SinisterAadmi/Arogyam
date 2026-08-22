import 'package:flutter/foundation.dart';
import '../../../../shared/entities/clinic.dart';
import '../../domain/get_nearby_clinics_usecase.dart';

enum SortOption { distance, waitTime, rating, availability }

class NearbyClinicsProvider extends ChangeNotifier {
  final GetNearbyClinicsUseCase _getNearbyClinicsUseCase;

  List<Clinic> _allClinics = [];
  List<Clinic> _filteredClinics = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedClinicId;
  SortOption _currentSort = SortOption.distance;
  String _searchQuery = '';

  NearbyClinicsProvider({GetNearbyClinicsUseCase? getNearbyClinicsUseCase})
      : _getNearbyClinicsUseCase =
            getNearbyClinicsUseCase ?? GetNearbyClinicsUseCase() {
    fetchNearbyClinics();
  }

  List<Clinic> get clinics => _filteredClinics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedClinicId => _selectedClinicId;
  SortOption get currentSort => _currentSort;
  String get searchQuery => _searchQuery;

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

  Clinic? get selectedClinic => _filteredClinics.isEmpty
      ? null
      : _filteredClinics.firstWhere(
          (c) => c.id == _selectedClinicId,
          orElse: () => _filteredClinics.first,
        );

  void selectClinic(String id) {
    if (_selectedClinicId != id) {
      _selectedClinicId = id;
      notifyListeners();
    }
  }

  void searchClinics(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilterAndSort();
  }

  void sortBy(SortOption option) {
    _currentSort = option;
    _applyFilterAndSort();
  }

  void _applyFilterAndSort() {
    // 1. Filter
    if (_searchQuery.isEmpty) {
      _filteredClinics = List.from(_allClinics);
    } else {
      _filteredClinics = _allClinics.where((clinic) {
        final nameMatch = clinic.name.toLowerCase().contains(_searchQuery);
        final addressMatch = clinic.address.toLowerCase().contains(_searchQuery);
        // You could also add specialty if it was in the entity
        return nameMatch || addressMatch;
      }).toList();
    }

    // 2. Sort
    _sortClinics(_filteredClinics);
    
    notifyListeners();
  }

  void _sortClinics(List<Clinic> list) {
    switch (_currentSort) {
      case SortOption.distance:
        list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case SortOption.waitTime:
        list.sort((a, b) => a.waitTimeMinutes.compareTo(b.waitTimeMinutes));
        break;
      case SortOption.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating)); // Highest first
        break;
      case SortOption.availability:
        list.sort((a, b) {
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
      _allClinics = fetchedClinics.toList();
      _applyFilterAndSort();
      
      if (_filteredClinics.isNotEmpty && _selectedClinicId == null) {
        _selectedClinicId = _filteredClinics.first.id;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
