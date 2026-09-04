import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../providers/prescriptions_provider.dart';
import '../../../widgets/prescription_card.dart';

class PrescriptionsTab extends StatelessWidget {
  const PrescriptionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Your digital verified prescriptions under ABHA. Show QR or code to any pharmacy.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Consumer<PrescriptionsProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.prescriptions.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                );
              }

              if (provider.errorMessage != null) {
                return Center(
                  child: Text(
                    'Error: ${provider.errorMessage}',
                    style: GoogleFonts.inter(color: AppColors.warning),
                  ),
                );
              }

              if (provider.prescriptions.isEmpty) {
                return const Center(
                  child: Text('No active medications found.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                itemCount: provider.prescriptions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return PrescriptionCard(prescription: provider.prescriptions[index]);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
