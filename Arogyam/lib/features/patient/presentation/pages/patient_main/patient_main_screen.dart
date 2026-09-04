import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../app/router/navigation_helper.dart';
import '../../../../../app/router/navigation_provider.dart';
import '../../../../../app/router/route_names.dart';
import '../../../../../core/widgets/app_bottom_navigation.dart';
import '../patient_home/patient_home_page.dart';
import '../nearby_clinics/nearby_clinics_page.dart';
import '../medical_history/medical_history_page.dart';
import '../nfc_share/nfc_share_page.dart';
import '../patient_profile/patient_profile_page.dart';
import '../abha_linking/abha_linking_page.dart';
import '../queue_status/queue_status_page.dart';
import '../active_medications_page.dart';
import '../appointment_booking/appointment_booking_page.dart';
import '../appointment_details/appointment_details_page.dart';
import '../../../../../shared/entities/clinic.dart';

import '../../../../../app/router/app_router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/security/biometric_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/patient_home_provider.dart';
import '../../providers/nearby_clinics_provider.dart';
import '../../providers/medical_history_provider.dart';
import '../../providers/prescriptions_provider.dart';
import '../../providers/patient_profile_provider.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen>
    with RouteAware, WidgetsBindingObserver {
  final Map<int, GlobalKey<NavigatorState>> _navigatorKeys = {
    0: GlobalKey<NavigatorState>(),
    1: GlobalKey<NavigatorState>(),
    2: GlobalKey<NavigatorState>(),
    3: GlobalKey<NavigatorState>(),
    4: GlobalKey<NavigatorState>(),
  };

  bool _isAppLocked = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (BiometricService().isAppLockEnabled) {
        setState(() => _isAppLocked = true);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isAppLocked) {
        _unlockApp();
      }
    }
  }

  Future<void> _unlockApp() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final success = await BiometricService().authenticate(
      localizedReason: 'Authenticate with biometrics or PIN to unlock Arogyam',
      bypassIfUnsupported: true,
    );

    if (mounted) {
      setState(() {
        _isAppLocked = !success;
        _isAuthenticating = false;
      });
    }
  }

  @override
  void didPushNext() {
    // Sub-route was pushed on top of the main navigation shell
    if (mounted) {
      context.read<NavigationProvider>().setRouteActive(false);
    }
  }

  @override
  void didPopNext() {
    // Returned to main navigation shell from a pushed route (e.g. booked appointment)
    if (mounted) {
      final navProvider = context.read<NavigationProvider>();
      navProvider.setRouteActive(true);
      _refreshActiveTab(navProvider.currentIndex);
    }
  }

  void _onItemTapped(int index, NavigationProvider navProvider) {
    if (navProvider.currentIndex == index) {
      final navState = _navigatorKeys[index]?.currentState;
      if (navState != null && navState.canPop()) {
        navState.popUntil((route) => route.isFirst);
      }
      _refreshActiveTab(index);
    } else {
      navProvider.setIndex(index);
    }
  }

  void _refreshActiveTab(int index) {
    if (!mounted) return;
    switch (index) {
      case 0:
        context.read<PatientHomeProvider>().refresh();
        break;
      case 1:
        context.read<NearbyClinicsProvider>().refresh();
        break;
      case 2:
        context.read<MedicalHistoryProvider>().refresh();
        context.read<PrescriptionsProvider>().refresh();
        break;
      case 4:
        context.read<PatientProfileProvider>().loadProfile();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            
            final currentNavigatorState = _navigatorKeys[navProvider.currentIndex]!.currentState;
            
            if (currentNavigatorState != null && currentNavigatorState.canPop()) {
              currentNavigatorState.pop();
              return;
            }

            if (navProvider.currentIndex != 0) {
              navProvider.setIndex(0);
              return;
            }
            
            final shouldExit = await NavigationHelper.showExitConfirmation(context);
            if (shouldExit && mounted) {
              Navigator.of(this.context).pop();
            }
          },
          child: Stack(
            children: [
              Scaffold(
                body: IndexedStack(
                  index: navProvider.currentIndex,
                  children: [
                    _buildNavigator(0, RouteNames.patientHome),
                    _buildNavigator(1, RouteNames.nearbyClinics),
                    _buildNavigator(2, RouteNames.medicalHistory),
                    _buildNavigator(3, RouteNames.nfcShare),
                    _buildNavigator(4, RouteNames.patientProfile),
                  ],
                ),
                bottomNavigationBar: navProvider.isBottomNavVisible
                    ? AppBottomNavigation(
                        currentIndex: navProvider.currentIndex,
                        onTap: (index) => _onItemTapped(index, navProvider),
                      )
                    : null,
              ),
              if (_isAppLocked) _buildAppLockOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigator(int index, String rootRoute) {
    return Navigator(
      key: _navigatorKeys[index],
      initialRoute: rootRoute,
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          _generateRoute(RouteSettings(name: initialRoute)),
        ];
      },
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/':
      case RouteNames.patientHome:
        page = const PatientHomePage();
        break;
      case RouteNames.nearbyClinics:
        page = const NearbyClinicsPage();
        break;
      case RouteNames.medicalHistory:
        page = const MedicalHistoryPage();
        break;
      case RouteNames.nfcShare:
        page = const NfcSharePage();
        break;
      case RouteNames.patientProfile:
        page = const PatientProfilePage();
        break;
      case RouteNames.abhaLinking:
        page = const AbhaLinkingPage();
        break;
      case RouteNames.queueStatus:
        page = const QueueStatusPage();
        break;
      case RouteNames.activeMedications:
        page = const ActiveMedicationsPage();
        break;
      case RouteNames.appointmentBooking:
        final clinic = settings.arguments as Clinic;
        page = AppointmentBookingPage(clinic: clinic);
        break;
      case RouteNames.appointmentDetails:
        final appointmentId = settings.arguments as String;
        page = AppointmentDetailsPage(appointmentId: appointmentId);
        break;
      default:
        page = const Scaffold(body: Center(child: Text('Page not found')));
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  Widget _buildAppLockOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFCCFBF1), width: 2),
                    ),
                    child: const Icon(LucideIcons.fingerprint, size: 48, color: AppColors.teal),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Arogyam Quick Unlock',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'App was backgrounded and locked to protect your health records. Authenticate to resume.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isAuthenticating ? null : _unlockApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isAuthenticating ? 'Authenticating...' : 'Unlock with Biometrics / PIN',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
