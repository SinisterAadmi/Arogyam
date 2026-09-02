import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/router/navigation_provider.dart';
import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../widgets/user_hero_section.dart';
import '../../widgets/upcoming_appointment_card.dart';
import '../../widgets/prescriptions_banner.dart';
import '../../widgets/quick_action_card.dart';
import '../../widgets/queue_status_card.dart';
import '../../providers/patient_home_provider.dart';
import '../../../../../core/widgets/app_refresh_progress_bar.dart';
import '../../../../../core/mixins/polling_mixin.dart';
import 'package:arogyam_flutter/features/ai_callback/presentation/providers/ai_callback_provider.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage>
    with WidgetsBindingObserver, PollingMixin<PatientHomePage> {
  @override
  Duration get pollingInterval => const Duration(seconds: 30);

  @override
  int? get tabIndex => 0;

  @override
  Future<void> onPoll() async {
    if (mounted) {
      await context.read<PatientHomeProvider>().refresh();
      if (!mounted) return;
      final aiCallback = context.read<AiCallbackProvider>();
      if (aiCallback.isRequested) {
        await aiCallback.fetchStatus();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientHomeProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PatientHomeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.patient == null) {
          return const Center(child: AppLoader());
        }

        if (provider.errorMessage != null && provider.patient == null) {
          return AppErrorView(
            message: provider.errorMessage!,
            onRetry: () => provider.loadDashboardData(),
          );
        }

        final patient = provider.patient;
        if (patient == null) {
          return const Center(child: Text('No patient data found'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRefreshProgressBar(isRefreshing: provider.isRefreshing),
                UserHeroSection(
                  userName: patient.name,
                  abhaId: patient.abhaId,
                  imageUrl: patient.imageUrl ?? 'https://www.figma.com/api/mcp/asset/4bfd7ea4-6c80-4455-83a6-0509e9bb2b94.png',
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (provider.queueStatus != null && provider.queueStatus!.isInQueue) ...[
                        GestureDetector(
                          onTap: () => _navigateToQueueStatus(context),
                          child: QueueStatusCard(
                            clinicName: provider.queueStatus!.clinicName,
                            tokenNumber: provider.queueStatus!.tokenNumber,
                            peopleAhead: provider.queueStatus!.peopleAhead,
                            currentlyServing: provider.queueStatus!.currentlyServing,
                            waitTime: provider.queueStatus!.estimatedWaitTime,
                            status: provider.queueStatus!.status,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (provider.upcomingAppointment != null) ...[
                        InkWell(
                          onTap: () => _navigateToQueueStatus(context),
                          borderRadius: BorderRadius.circular(16),
                          child: UpcomingAppointmentCard(
                            doctorName: provider.upcomingAppointment!.doctorName,
                            specialty: provider.upcomingAppointment!.specialty,
                            clinicName: provider.upcomingAppointment!.clinicName,
                            appointmentTime: provider.upcomingAppointment!.appointmentTime,
                            tokenNumber: provider.upcomingAppointment!.tokenNumber,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      PrescriptionsBanner(
                        count: provider.activePrescriptionsCount,
                        subtext: 'Check your active medications',
                        onTap: () {
                          context.read<NavigationProvider>().setIndex(2); // History
                        },
                      ),
                      const SizedBox(height: 20),
                      Consumer<AiCallbackProvider>(
                        builder: (context, aiCallback, _) {
                          if (!aiCallback.isRequested) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAiCallbackBanner(context, aiCallback),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                      _buildQuickActions(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiCallbackBanner(BuildContext context, AiCallbackProvider aiCallback) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.phoneIncoming, size: 20, color: Colors.green.shade800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Voice Callback Pending',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                Text(
                  'Coordinator will call within 15 mins',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await aiCallback.cancelCallback();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI Callback cancelled')),
                );
              }
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToQueueStatus(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(RouteNames.queueStatus);
  }

  Widget _buildQuickActions(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            QuickActionCard(
              title: 'Live Queue',
              icon: LucideIcons.radio,
              iconBgColor: const Color(0xFFE0F2FE),
              onTap: () => _navigateToQueueStatus(context),
            ),
            QuickActionCard(
              title: 'Health Vault',
              icon: LucideIcons.fileText,
              iconBgColor: const Color(0xFFDCFCE7),
              onTap: () => nav.setIndex(2),
            ),
            QuickActionCard(
              title: 'Nearby Clinics',
              icon: LucideIcons.navigation,
              iconBgColor: const Color(0xFFFFEDD5),
              onTap: () => nav.setIndex(1),
            ),
            QuickActionCard(
              title: 'NFC Share',
              icon: LucideIcons.wifi,
              iconBgColor: const Color(0xFFF3E8FF),
              onTap: () => nav.setIndex(3),
            ),
          ],
        ),
      ],
    );
  }
}
