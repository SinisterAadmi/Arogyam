import 'package:flutter/material.dart';
import '../../features/patient/presentation/pages/appointment_booking/appointment_booking_page.dart';
import 'route_names.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    RouteNames.appointmentBooking: (context) => const AppointmentBookingPage(),
  };
}
