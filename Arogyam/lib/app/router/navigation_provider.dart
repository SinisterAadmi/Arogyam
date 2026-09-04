import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isBottomNavVisible = true;
  bool _isRouteActive = true;

  int get currentIndex => _currentIndex;
  bool get isBottomNavVisible => _isBottomNavVisible;
  bool get isRouteActive => _isRouteActive;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void setBottomNavVisible(bool visible) {
    if (_isBottomNavVisible != visible) {
      _isBottomNavVisible = visible;
      notifyListeners();
    }
  }

  void setRouteActive(bool active) {
    if (_isRouteActive != active) {
      _isRouteActive = active;
      notifyListeners();
    }
  }
}
