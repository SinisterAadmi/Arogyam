import 'package:flutter/material.dart';
import '../../features/patient/presentation/pages/appointment_booking/appointment_booking_page.dart';
import '../../shared/entities/clinic.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.appointmentBooking:
        final clinic = settings.arguments as Clinic;
        return MaterialPageRoute(
          builder: (context) => AppointmentBookingPage(clinic: clinic),
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
