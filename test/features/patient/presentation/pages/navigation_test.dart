import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:arogyam_flutter/app/router/app_router.dart';
import 'package:arogyam_flutter/app/router/route_names.dart';
import 'package:arogyam_flutter/app/router/navigation_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/patient_home_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/abha_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/appointment_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/queue_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/prescriptions_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/medical_history_provider.dart';
import 'package:arogyam_flutter/features/patient/presentation/providers/nearby_clinics_provider.dart';
import 'package:arogyam_flutter/core/widgets/app_bottom_navigation.dart';

void main() {
  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => PatientHomeProvider()),
        ChangeNotifierProvider(create: (_) => AbhaProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => QueueProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionsProvider()),
        ChangeNotifierProvider(create: (_) => MedicalHistoryProvider()),
        ChangeNotifierProvider(create: (_) => NearbyClinicsProvider()),
      ],
      child: MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: RouteNames.patientHome,
      ),
    );
  }

  testWidgets('Bottom navigation switches tabs and updates UI', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify initial state (Home tab)
    expect(find.text('Quick Actions'), findsOneWidget);
    
    // Tap Clinics tab
    await tester.tap(find.text('Clinics'));
    await tester.pumpAndSettle();
    expect(find.text('Nearby Clinics'), findsOneWidget);

    // Tap History tab
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Medical History'), findsOneWidget);

    // Tap Share tab
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.text('NFC Instant Share'), findsOneWidget);
    
    // Tap Home tab again
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Quick Actions'), findsOneWidget);
  });

  testWidgets('Back from non-home tab returns to home tab', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Go to Clinics tab
    await tester.tap(find.text('Clinics'));
    await tester.pumpAndSettle();
    expect(find.text('Nearby Clinics'), findsOneWidget);

    // Simulate system back button
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    // Should be back on Home tab
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
