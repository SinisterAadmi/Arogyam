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
import '../../../../../shared/entities/clinic.dart';

import '../../../../../app/router/app_router.dart';
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

class _PatientMainScreenState extends State<PatientMainScreen> with RouteAware {
  final Map<int, GlobalKey<NavigatorState>> _navigatorKeys = {
    0: GlobalKey<NavigatorState>(),
    1: GlobalKey<NavigatorState>(),
    2: GlobalKey<NavigatorState>(),
    3: GlobalKey<NavigatorState>(),
    4: GlobalKey<NavigatorState>(),
  };

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
    AppRouter.routeObserver.unsubscribe(this);
    super.dispose();
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
          child: Scaffold(
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
      default:
        page = const Scaffold(body: Center(child: Text('Page not found')));
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
