import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:arogyam_flutter/app/theme/app_colors.dart';
import 'package:arogyam_flutter/app/theme/app_typography.dart';
import 'package:arogyam_flutter/features/patient/presentation/widgets/clinic_info_card.dart';
import 'package:arogyam_flutter/features/patient/presentation/widgets/date_selector.dart';
import 'package:arogyam_flutter/features/patient/presentation/widgets/slot_selector.dart';
import 'package:arogyam_flutter/features/patient/presentation/widgets/ai_callback_section.dart';

import 'package:arogyam_flutter/shared/entities/clinic.dart';

class AppointmentBookingPage extends StatelessWidget {
  final Clinic clinic;

  const AppointmentBookingPage({
    super.key,
    required this.clinic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        leading: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: IconButton(
              icon: SvgPicture.network(
                'https://www.figma.com/api/mcp/asset/a39cb157-b954-402d-8920-25c542be16a4.svg',
                width: 16,
                height: 16,
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: const Text(
          'Schedule Appointment',
          style: AppTypography.h1,
        ),
        actions: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: IconButton(
              icon: SvgPicture.network(
                'https://www.figma.com/api/mcp/asset/eed14e6d-9d33-4848-9506-b72a898d1280.svg',
                width: 18,
                height: 18,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClinicInfoCard(clinic: clinic),
            const SizedBox(height: 20),
            const DateSelector(),
            const SizedBox(height: 20),
            const SlotSelector(),
            const SizedBox(height: 20),
            const AICallbackSection(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appointment confirmed at ${clinic.name}'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Booking',
                  style: AppTypography.h2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
