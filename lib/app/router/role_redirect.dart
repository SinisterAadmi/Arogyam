import 'package:flutter/material.dart';
import '../../features/auth/data/models/user_model.dart';
import 'route_names.dart';

class RoleRedirect {
  static String getInitialRoute(UserModel user) {
    switch (user.role.toLowerCase()) {
      case 'reception':
        return RouteNames.receptionHome;
      case 'patient':
      default:
        return RouteNames.patientHome;
    }
  }

  static void redirect(BuildContext context, UserModel user) {
    final route = getInitialRoute(user);
    Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
  }
}
