import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../core/mixins/polling_mixin.dart';
import '../../../../../../core/socket/socket_service.dart';
import '../../../../../../core/widgets/app_refresh_progress_bar.dart';
import '../../providers/reception_stats_provider.dart';
import '../../../data/models/reception_queue_models.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with WidgetsBindingObserver, PollingMixin<StatsPage> {
  StreamSubscription? _queueUpdatedSubscription;

  @override
  Duration get pollingInterval => const Duration(seconds: 15);

  @override
  int? get tabIndex => null; // Use unconstrained visibility polling for standalone reliability

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceptionStatsProvider>().fetchAnalytics();
    });

    // Real-time socket sync: whenever queue updates (token issued, served, completed), refresh analytics
    _queueUpdatedSubscription = SocketService().receptionQueueUpdatedStream.listen((_) {
      if (mounted) {
        context.read<ReceptionStatsProvider>().fetchAnalytics(isSilent: true);
      }
    });
  }

  @override
  void dispose() {
    _queueUpdatedSubscription?.cancel();
    super.dispose();
  }

  @override
  Future<void> onPoll() async {
    if (mounted) {
      await context.read<ReceptionStatsProvider>().fetchAnalytics(isSilent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceptionStatsProvider>();
    final analytics = provider.analytics;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppRefreshProgressBar(isRefreshing: provider.isRefreshing),
          Expanded(
            child: provider.isLoading && analytics == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<ReceptionStatsProvider>().fetchAnalytics(),
                    color: AppColors.teal,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        _buildHeader(analytics?.clinicName ?? 'Sunrise Medical Center'),
                        const SizedBox(height: 20),

                        // Metric Cards Grid
                        _buildMetricsGrid(analytics),
                        const SizedBox(height: 24),

                        // Hourly Patient Flow Chart
                        _buildHourlyFlowCard(analytics?.hourlyFlow ?? []),
                        const SizedBox(height: 24),

                        // Clinic operational note
                        _buildOperationalInfoCard(),
                      ],
                    ),
              
                  ),
          ),)
        ],
      ),
    );
  }

  Widget _buildHeader(String clinicName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Clinic Performance',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                'Live Today',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Operational queue metrics and patient turnaround for $clinicName.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(ClinicAnalytics? data) {
    final served = data?.patientsServedToday ?? 0;
    final waiting = data?.currentlyWaiting ?? 0;
    final avgWait = data?.averageWaitTimeMinutes ?? 0;
    final appointments = data?.totalAppointmentsToday ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Avg Wait Time',
                value: '$avgWait mins',
                icon: LucideIcons.clock,
                color: AppColors.warning,
                bgColor: const Color(0xFFFEF3C7),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricTile(
                title: 'Patients Served',
                value: '$served done',
                icon: LucideIcons.checkCircle2,
                color: const Color(0xFF16A34A),
                bgColor: const Color(0xFFDCFCE7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Currently Waiting',
                value: '$waiting active',
                icon: LucideIcons.users,
                color: AppColors.teal,
                bgColor: const Color(0xFFF0FDFA),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricTile(
                title: 'Appointments',
                value: '$appointments today',
                icon: LucideIcons.calendarCheck,
                color: const Color(0xFF6366F1),
                bgColor: const Color(0xFFEEF2FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyFlowCard(List<HourlyFlowItem> flow) {
    final maxCount = flow.fold<int>(1, (max, item) => item.count > max ? item.count : max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hourly Patient Flow',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '08:00 – 18:00',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Distribution of queue registrations throughout the day.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Custom visual bar chart
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: flow.map((item) {
                final heightFactor = maxCount > 0 ? (item.count / maxCount) : 0.0;
                final barHeight = 8.0 + (heightFactor * 75.0);
                final hasCount = item.count > 0;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hasCount)
                        Text(
                          '${item.count}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.teal,
                          ),
                        )
                      else
                        const SizedBox(height: 12),
                      const SizedBox(height: 4),
                      Container(
                        width: 14,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: hasCount ? AppColors.teal : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.hour.split(':')[0],
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: hasCount ? AppColors.textPrimary : AppColors.textMuted,
                          fontWeight: hasCount ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Refresh Notice',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Analytics update automatically on background poll. Wait times are calculated from actual time elapsed between walk-in registration and consultation start.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
