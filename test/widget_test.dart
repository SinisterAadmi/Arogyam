import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/main.dart';

void main() {
  testWidgets('Nearby clinics screen loads and displays headers', (WidgetTester tester) async {
    await tester.pumpWidget(const ArogyamApp());
    await tester.pumpAndSettle();

    expect(find.text('Clinics & Centers'), findsOneWidget);
    expect(find.text('Clinics Near You'), findsOneWidget);
    expect(find.text('City Family Health Clinic'), findsOneWidget);
  });
}
