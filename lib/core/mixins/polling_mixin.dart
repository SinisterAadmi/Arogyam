import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/router/navigation_provider.dart';

/// A reusable mixin that provides periodic polling and refresh-on-focus
/// for data-driven screens in the Arogyam patient app.
///
/// Features:
/// 1. Runs [Timer.periodic] with [pollingInterval] only while the screen is visible.
/// 2. Stops and cancels timers immediately when the screen is hidden, disposed, or the app is backgrounded.
/// 3. Supports bottom-navigation tab screens inside IndexedStack via [tabIndex].
/// 4. Guards against overlapping calls with [_isPollInProgress].
/// 5. Automatically refreshes on focus (tab change, route pop back, or app foreground).
mixin PollingMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  /// The duration between periodic poll ticks while this screen is active.
  Duration get pollingInterval;

  /// The async operation to perform on each poll tick or on gaining focus.
  Future<void> onPoll();

  /// If this screen is a tab inside [PatientMainScreen], return its tab index
  /// (e.g. 0 for Home, 1 for Clinics, 2 for History). Return null for standalone pushed routes.
  int? get tabIndex => null;

  Timer? _pollingTimer;
  bool _isPollInProgress = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _isTabActive = true;
  bool _isRouteActive = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial evaluation happens in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDisposed) return;

    if (tabIndex != null) {
      final nav = Provider.of<NavigationProvider>(context, listen: true);
      final isNowTabActive = nav.currentIndex == tabIndex;
      final isNowRouteActive = nav.isRouteActive;

      final wasVisible = _isTabActive && _isRouteActive && _lifecycleState == AppLifecycleState.resumed;
      _isTabActive = isNowTabActive;
      _isRouteActive = isNowRouteActive;
      final isNowVisible = _isTabActive && _isRouteActive && _lifecycleState == AppLifecycleState.resumed;

      if (!wasVisible && isNowVisible) {
        _onGainedVisibility();
      } else if (wasVisible && !isNowVisible) {
        _onLostVisibility();
      } else if (isNowVisible && _pollingTimer == null) {
        _startTimer();
      }
    } else {
      final route = ModalRoute.of(context);
      final isCurrent = route?.isCurrent ?? true;
      final wasVisible = _isRouteActive && _lifecycleState == AppLifecycleState.resumed;
      _isRouteActive = isCurrent;
      final isNowVisible = _isRouteActive && _lifecycleState == AppLifecycleState.resumed;

      if (!wasVisible && isNowVisible) {
        _onGainedVisibility();
      } else if (wasVisible && !isNowVisible) {
        _onLostVisibility();
      } else if (isNowVisible && _pollingTimer == null) {
        _startTimer();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      if (_isScreenVisible) {
        _onGainedVisibility();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _onLostVisibility();
    }
  }

  bool get _isScreenVisible {
    if (!mounted || _isDisposed) return false;
    if (_lifecycleState != AppLifecycleState.resumed) return false;
    if (tabIndex != null) {
      return _isTabActive && _isRouteActive;
    }
    return _isRouteActive;
  }

  void _onGainedVisibility() {
    _startTimer();
    // Schedule initial poll post-frame to prevent "setState() or markNeedsBuild() called during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isScreenVisible && mounted && !_isDisposed) {
        triggerPoll();
      }
    });
  }

  void _onLostVisibility() {
    _stopTimer();
  }

  void _startTimer() {
    _stopTimer();
    if (!_isScreenVisible) return;
    _pollingTimer = Timer.periodic(pollingInterval, (_) {
      triggerPoll();
    });
  }

  void _stopTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Triggers a poll execution if visible and no poll is currently in-flight.
  Future<void> triggerPoll() async {
    if (!mounted || _isDisposed || !_isScreenVisible) return;

    if (_isPollInProgress) {
      debugPrint('[$runtimeType] Poll skipped: previous poll still in progress');
      return;
    }

    _isPollInProgress = true;
    try {
      await onPoll();
    } catch (e, stackTrace) {
      debugPrint('[$runtimeType] Poll error: $e\n$stackTrace');
    } finally {
      if (mounted && !_isDisposed) {
        _isPollInProgress = false;
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
