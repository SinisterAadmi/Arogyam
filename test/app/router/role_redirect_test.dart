import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/app/router/role_redirect.dart';
import 'package:arogyam_flutter/app/router/route_names.dart';
import 'package:arogyam_flutter/features/auth/data/models/user_model.dart';

void main() {
  group('RoleRedirect Tests', () {
    test('routes patient to patientHome', () {
      final user = UserModel(
        id: '1',
        firebaseUid: 'uid1',
        role: 'patient',
      );
      expect(RoleRedirect.getInitialRoute(user), RouteNames.patientHome);
    });

    test('routes reception to receptionHome', () {
      final user = UserModel(
        id: '2',
        firebaseUid: 'uid2',
        role: 'reception',
      );
      expect(RoleRedirect.getInitialRoute(user), RouteNames.receptionHome);
    });

    test('routes unknown roles to patientHome fallback', () {
      final user = UserModel(
        id: '3',
        firebaseUid: 'uid3',
        role: 'unknown',
      );
      expect(RoleRedirect.getInitialRoute(user), RouteNames.patientHome);
    });
  });
}
