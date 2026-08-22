import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:arogyam_flutter/app/theme/app_colors.dart';
import 'package:arogyam_flutter/app/theme/app_typography.dart';
import 'package:arogyam_flutter/features/patient/presentation/widgets/clinic_info_card.dart';
import 'package:arogyam_flutter/features/patient/presentation/widgets/date_selector.dart';
import 'package:arogyam_flutter/features/patient/presentation/widgets/slot_selector.dart';
import 'package:arogyam_flutter/features/patient/presentation/widgets/ai_callback_section.dart';

class AppointmentBookingPage extends StatelessWidget {
  const AppointmentBookingPage({super.key});

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
            const ClinicInfoCard(),
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
                onPressed: () {},
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
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('Home', 'https://www.figma.com/api/mcp/asset/4cedf445-6694-4780-84b8-56691bfa0d12.svg', false),
            _buildNavItem('Clinics', 'https://www.figma.com/api/mcp/asset/c088cc17-9240-4e56-a258-afa7f18bb565.svg', true),
            _buildNavItem('History', 'https://www.figma.com/api/mcp/asset/7cfbc9ee-3ef8-449d-83f9-0e10fe36b2ea.svg', false),
            _buildNavItem('Share', 'https://www.figma.com/api/mcp/asset/85f46f87-ce04-4a18-887d-f8ce2d24bbc6.svg', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, String iconUrl, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.iconBg : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SvgPicture.network(
            iconUrl,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              isSelected ? AppColors.primary : AppColors.textSecondary,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: isSelected
              ? AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)
              : AppTypography.labelSmall,
        ),
      ],
    );
  }
}
