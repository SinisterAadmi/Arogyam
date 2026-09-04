import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation_provider.dart';
import 'route_names.dart';

class NavigationHelper {
  static int getTabIndex(String routeName) {
    switch (routeName) {
      case RouteNames.patientHome:
      case RouteNames.abhaLinking:
        return 0;
      case RouteNames.nearbyClinics:
      case RouteNames.queueStatus:
        return 1;
      case RouteNames.medicalHistory:
      case RouteNames.activeMedications:
        return 2;
      case RouteNames.nfcShare:
        return 3;
      case RouteNames.patientProfile:
      case RouteNames.editProfile:
        return 4;
      default:
        return 0;
    }
  }

  static void switchTab(BuildContext context, int index) {
    context.read<NavigationProvider>().setIndex(index);
  }

  static Future<bool> showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Arogyam?'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
