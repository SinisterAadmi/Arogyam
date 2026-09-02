import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../app/router/navigation_helper.dart';
import '../../../../../app/router/navigation_provider.dart';
import '../../../../../core/widgets/app_bottom_navigation.dart';
import '../patient_home/patient_home_page.dart';
import '../nearby_clinics/nearby_clinics_page.dart';
import '../medical_history/medical_history_page.dart';
import '../nfc_share/nfc_share_page.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  final List<Widget> _pages = [
    const PatientHomePage(),
    const NearbyClinicsPage(),
    const MedicalHistoryPage(),
    const NfcSharePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            
            if (navProvider.currentIndex != 0) {
              navProvider.setIndex(0);
              return;
            }
            
            final shouldExit = await NavigationHelper.showExitConfirmation(context);
            if (shouldExit && mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            body: IndexedStack(
              index: navProvider.currentIndex,
              children: _pages,
            ),
            bottomNavigationBar: navProvider.isBottomNavVisible
                ? AppBottomNavigation(
                    currentIndex: navProvider.currentIndex,
                    onTap: (index) => navProvider.setIndex(index),
                  )
                : null,
          ),
        );
      },
    );
  }
}
