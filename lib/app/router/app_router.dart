import 'package:flutter/material.dart';
import '../../features/patient/presentation/pages/active_medications_page.dart';
import '../../features/patient/presentation/pages/appointment_booking/appointment_booking_page.dart';
import '../../features/patient/presentation/pages/medical_history/medical_history_page.dart';
import '../../features/patient/presentation/pages/nfc_share/nfc_share_page.dart';
import '../../features/patient/presentation/pages/patient_home/patient_home_page.dart';
import '../../features/patient/presentation/pages/nearby_clinics/nearby_clinics_page.dart';
import '../../features/patient/presentation/pages/queue_status/queue_status_page.dart';
import '../../shared/entities/clinic.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.patientHome:
        return MaterialPageRoute(
          builder: (context) => const PatientHomePage(),
        );
      case RouteNames.nearbyClinics:
        return MaterialPageRoute(
          builder: (context) => const NearbyClinicsPage(),
        );
      case RouteNames.appointmentBooking:
        final clinic = settings.arguments as Clinic;
        return MaterialPageRoute(
          builder: (context) => AppointmentBookingPage(clinic: clinic),
        );
      case RouteNames.activeMedications:
        return MaterialPageRoute(
          builder: (context) => const ActiveMedicationsPage(),
        );
      case RouteNames.medicalHistory:
        return MaterialPageRoute(
          builder: (context) => const MedicalHistoryPage(),
        );
      case RouteNames.queueStatus:
        return MaterialPageRoute(
          builder: (context) => const QueueStatusPage(),
        );
      case RouteNames.nfcShare:
        return MaterialPageRoute(
          builder: (context) => const NfcSharePage(),
        );
      default:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }

  static Map<String, WidgetBuilder> get routes => {};
}
