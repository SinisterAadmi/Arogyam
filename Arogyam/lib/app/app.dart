import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

class ArogyamApp extends StatelessWidget {
  const ArogyamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arogyam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // The screen is now accessible via RouteNames.appointmentBooking
      // but not shown as the primary home screen.
      home: const Scaffold(
        body: Center(
          child: Text('Arogyam Home Page'),
        ),
      ),
      routes: AppRouter.routes,
    );
  }
}
