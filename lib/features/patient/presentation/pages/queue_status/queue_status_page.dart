import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/router/navigation_provider.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../shared/widgets/page_header.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../providers/queue_provider.dart';
import '../../../../../core/widgets/app_refresh_progress_bar.dart';
import '../../../../../core/mixins/polling_mixin.dart';

class QueueStatusPage extends StatefulWidget {
  const QueueStatusPage({super.key});

  @override
  State<QueueStatusPage> createState() => _QueueStatusPageState();
}

class _QueueStatusPageState extends State<QueueStatusPage>
    with WidgetsBindingObserver, PollingMixin<QueueStatusPage> {
  @override
  Duration get pollingInterval => const Duration(seconds: 15);

  @override
  int? get tabIndex => null;

  @override
  Future<void> onPoll() async {
    if (mounted) {
      await context.read<QueueProvider>().refresh();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueProvider>().fetchStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Consumer<QueueProvider>(
                builder: (context, provider, _) =>
                    AppRefreshProgressBar(isRefreshing: provider.isRefreshing),
              ),
              _buildHeader(context),
              Expanded(
                child: Consumer<QueueProvider>(
                  builder: (context, provider, child) {
                    final status = provider.status;
                    if (provider.isLoading && status == null) {
                      return const Center(child: AppLoader());
                    }

                    if (status == null || !status.isInQueue) {
                      return _buildEmptyQueueView(context);
                    }

                    if (status.status == 'completed') {
                      return _buildCompletedView(context, status);
                    }

                    if (status.status == 'absent') {
                      return _buildAbsentView(context, status);
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildPositionCard(status),
                          const SizedBox(height: 20),
                          _buildCheckInSection(context, provider),
                          const SizedBox(height: 20),
                          _buildInfoRow(LucideIcons.building, 'At: ${status.clinicName} • Cabin 3'),
                          const SizedBox(height: 12),
                          _buildInfoRow(LucideIcons.clock, 'Estimated wait time is updated every minute'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedView(BuildContext context, dynamic status) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF86EFAC), width: 2),
              ),
              child: const Icon(LucideIcons.checkCircle, size: 48, color: Color(0xFF16A34A)),
            ),
            const SizedBox(height: 24),
            Text(
              'Consultation Complete!',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your visit for Token #${status.tokenNumber} at ${status.clinicName} has concluded.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Clinic', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                      Text(status.clinicName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Token Number', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                      Text('#${status.tokenNumber}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.teal)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Done',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _handleBack(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsentView(BuildContext context, dynamic status) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFECACA), width: 2),
              ),
              child: const Icon(LucideIcons.userX, size: 48, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 24),
            Text(
              'Marked Absent',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'You were marked absent for Token #${status.tokenNumber} at ${status.clinicName}.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  context.read<NavigationProvider>().setIndex(1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Browse Nearby Clinics'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueueView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.radio, size: 40, color: AppColors.teal),
            ),
            const SizedBox(height: 24),
            Text(
              "You're not currently in a queue",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Join a live queue from the nearby clinics list to track your token and estimated wait time in real-time.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  context.read<NavigationProvider>().setIndex(1); // Go to Clinics tab
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Browse Nearby Clinics'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.read<NavigationProvider>().setIndex(1); // Back to Clinics tab root
    }
  }

  Widget _buildHeader(BuildContext context) {
    return PageHeader(
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _handleBack(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(LucideIcons.chevronLeft, size: 16, color: AppColors.teal),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Live Queue Status',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionCard(dynamic status) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            'Your Position In Queue',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: 0.75,
                  strokeWidth: 10,
                  backgroundColor: AppColors.background,
                  color: AppColors.teal,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#${status.tokenNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${status.peopleAhead} ahead',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildMetric('Est. Wait', status.estimatedWaitTime),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _buildMetric('Now Serving', '#${status.currentlyServing}', isTeal: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, {bool isTeal = false}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isTeal ? AppColors.teal : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInSection(BuildContext context, QueueProvider provider) {
    if (provider.checkInStatus == CheckInStatus.checkedIn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.checkCircle, color: Colors.green),
            const SizedBox(width: 12),
            Text(
              'Successfully Checked-In',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF166534),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: provider.checkInStatus == CheckInStatus.nearby 
            ? const Color(0xFFFFF7ED) 
            : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: provider.checkInStatus == CheckInStatus.nearby 
              ? const Color(0xFFFFEDD5) 
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.mapPin, 
                size: 20, 
                color: provider.checkInStatus == CheckInStatus.nearby ? Colors.orange : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.checkInStatus == CheckInStatus.nearby 
                          ? 'You are near the clinic'
                          : 'Arriving soon?',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: provider.checkInStatus == CheckInStatus.nearby ? Colors.orange.shade900 : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      provider.checkInStatus == CheckInStatus.nearby 
                          ? 'Confirm check-in using clinic QR, NFC, or reception.'
                          : 'Geofence will detect when you are within 100m.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (provider.checkInStatus == CheckInStatus.nearby) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => provider.checkInViaQR('MOCK_QR'),
                icon: const Icon(LucideIcons.qrCode, size: 18),
                label: const Text('Scan QR to Check-In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ] else ...[
             const SizedBox(height: 12),
             TextButton(
               onPressed: () => provider.updateArrivedNearby(),
               child: const Text('Simulate Arrived Nearby (Mock)'),
             ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
