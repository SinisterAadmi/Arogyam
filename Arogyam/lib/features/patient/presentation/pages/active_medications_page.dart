import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../app/router/navigation_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/page_header.dart';
import '../providers/prescriptions_provider.dart';
import '../widgets/prescription_card.dart';
import '../../../../core/widgets/app_refresh_progress_bar.dart';
import '../../../../core/mixins/polling_mixin.dart';

class ActiveMedicationsPage extends StatefulWidget {
  const ActiveMedicationsPage({super.key});

  @override
  State<ActiveMedicationsPage> createState() => _ActiveMedicationsPageState();
}

class _ActiveMedicationsPageState extends State<ActiveMedicationsPage>
    with WidgetsBindingObserver, PollingMixin<ActiveMedicationsPage> {
  @override
  Duration get pollingInterval => const Duration(seconds: 30);

  @override
  int? get tabIndex => null;

  @override
  Future<void> onPoll() async {
    if (mounted) {
      await context.read<PrescriptionsProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<PrescriptionsProvider>(
            builder: (context, provider, _) =>
                AppRefreshProgressBar(isRefreshing: provider.isRefreshing),
          ),
          _buildHeader(context),
          _buildInfoBanner(),
          Expanded(
            child: Consumer<PrescriptionsProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.prescriptions.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.teal));
                }

                if (provider.errorMessage != null) {
                  return Center(child: Text('Error: ${provider.errorMessage}', style: GoogleFonts.inter(color: AppColors.warning)));
                }

                if (provider.prescriptions.isEmpty) {
                  return const Center(child: Text('No active medications found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: provider.prescriptions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return PrescriptionCard(prescription: provider.prescriptions[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.read<NavigationProvider>().setIndex(2); // Back to History tab
    }
  }

  Widget _buildHeader(BuildContext context) {
    return PageHeader(
      border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 12),
      child: Row(
        children: [
          _buildCircleButton(
            icon: LucideIcons.chevronLeft,
            onTap: () => _handleBack(context),
          ),
          const SizedBox(width: 12),
          Text(
            'Active Medications',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: AppColors.iconButtonBg, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: AppColors.teal),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'Your digital verified prescriptions under ABHA. Show QR or code to any pharmacy.',
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      ),
    );
  }
}
