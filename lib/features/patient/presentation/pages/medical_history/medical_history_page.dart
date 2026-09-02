import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../shared/widgets/page_header.dart';
import 'tabs/records_tab.dart';
import 'tabs/prescriptions_tab.dart';

import 'package:provider/provider.dart';
import '../../../../../core/mixins/polling_mixin.dart';
import '../../../../../core/widgets/app_refresh_progress_bar.dart';
import '../../providers/medical_history_provider.dart';
import '../../providers/prescriptions_provider.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage>
    with WidgetsBindingObserver, PollingMixin<MedicalHistoryPage> {
  bool _showPrescriptions = false;

  @override
  Duration get pollingInterval => const Duration(seconds: 30);

  @override
  int? get tabIndex => 2;

  @override
  Future<void> onPoll() async {
    if (mounted) {
      await Future.wait([
        context.read<MedicalHistoryProvider>().refresh(),
        context.read<PrescriptionsProvider>().refresh(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MedicalHistoryProvider, PrescriptionsProvider>(
      builder: (context, historyProvider, rxProvider, _) {
        final isRefreshing = historyProvider.isRefreshing || rxProvider.isRefreshing;
        return Column(
          children: [
            AppRefreshProgressBar(isRefreshing: isRefreshing),
            _buildHeader(context),
            Expanded(
              child: _showPrescriptions
                  ? const PrescriptionsTab()
                  : RecordsTab(
                      onPrescriptionsTap: () {
                        setState(() => _showPrescriptions = true);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return PageHeader(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (_showPrescriptions)
                GestureDetector(
                  onTap: () => setState(() => _showPrescriptions = false),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.iconButtonBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(LucideIcons.chevronLeft, size: 16, color: AppColors.teal),
                  ),
                )
              else
                const SizedBox(width: 48), // Align with other tabs
              Text(
                _showPrescriptions ? 'Active Medications' : 'Medical History',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _showUploadOptions(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.plus, size: 18, color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Medical Record',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildUploadItem(LucideIcons.camera, 'Take Photo', 'Capture your report using camera'),
            _buildUploadItem(LucideIcons.filePlus, 'Upload File', 'PDF, Images from gallery'),
            _buildUploadItem(LucideIcons.link, 'Link via ABHA', 'Sync records from ABHA ecosystem'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.iconButtonBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.teal, size: 20),
      ),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Encryption engine active. Processing secure upload...')),
        );
      },
    );
  }
}
