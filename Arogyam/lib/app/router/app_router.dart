import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/patient/presentation/pages/appointment_booking/appointment_booking_page.dart';
import '../../features/patient/presentation/pages/appointment_details/appointment_details_page.dart';
import '../../features/patient/presentation/pages/active_medications_page.dart';
import '../../features/patient/presentation/pages/queue_status/queue_status_page.dart';
import '../../features/patient/presentation/pages/patient_main/patient_main_screen.dart';
import '../../shared/entities/clinic.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/clinic/reception/presentation/pages/reception_main/reception_main_screen.dart';
import '../../features/clinic/reception/presentation/pages/clinic_details/edit_clinic_page.dart';
import '../../features/clinic/reception/presentation/pages/clinic_details/clinic_details_page.dart';
import 'route_names.dart';
import 'navigation_provider.dart';

class AppRouter {
  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.patientHome:
        return _patientMainRoute(0);
      case RouteNames.nearbyClinics:
        return _patientMainRoute(1);
      case RouteNames.medicalHistory:
        return _patientMainRoute(2);
      case RouteNames.nfcShare:
        return _patientMainRoute(3);
      case RouteNames.patientProfile:
        return _patientMainRoute(4);
        
      case RouteNames.appointmentBooking:
        final clinic = settings.arguments as Clinic;
        return MaterialPageRoute(
          builder: (context) => AppointmentBookingPage(clinic: clinic),
          settings: settings,
        );

      case RouteNames.appointmentDetails:
        final appointmentId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => AppointmentDetailsPage(appointmentId: appointmentId),
          settings: settings,
        );

      case RouteNames.activeMedications:
        return MaterialPageRoute(
          builder: (context) => const ActiveMedicationsPage(),
          settings: settings,
        );
        
      case RouteNames.abhaLinking:
        // For ABHA linking, we might want to push it on the Home tab if it should show bottom nav
        return _patientSubRoute(0, settings);
        
      case RouteNames.queueStatus:
        return MaterialPageRoute(
          builder: (context) => const QueueStatusPage(),
          settings: settings,
        );

      case RouteNames.login:
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
          settings: settings,
        );
      case RouteNames.otpVerification:
        final phoneNumber = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => OtpVerificationPage(phoneNumber: phoneNumber),
          settings: settings,
        );
      case RouteNames.signup:
        return MaterialPageRoute(
          builder: (context) => const SignupPage(),
          settings: settings,
        );
      case RouteNames.receptionHome:
        return MaterialPageRoute(
          builder: (context) => const ReceptionMainScreen(),
          settings: settings,
        );
      case RouteNames.receptionClinicDetails:
        return MaterialPageRoute(
          builder: (context) => const ClinicDetailsPage(),
          settings: settings,
        );
      case RouteNames.receptionClinicEdit:
        return MaterialPageRoute(
          builder: (context) => const EditClinicPage(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }

  static MaterialPageRoute _patientMainRoute(int index) {
    return MaterialPageRoute(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<NavigationProvider>().setIndex(index);
        });
        return const PatientMainScreen();
      },
    );
  }

  static MaterialPageRoute _patientSubRoute(int index, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final nav = context.read<NavigationProvider>();
          nav.setIndex(index);
          // If we want to push the specific page on the tab's navigator,
          // we'd need a more complex mechanism. 
          // For now, sub-routes that SHOULD show bottom nav will be handled 
          // by PatientMainScreen's onGenerateRoute if they are root tab children.
        });
        return const PatientMainScreen();
      },
    );
  }

  static Map<String, WidgetBuilder> get routes => {};
}
