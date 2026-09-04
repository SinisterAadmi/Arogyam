import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arogyam_flutter/app/theme/app_colors.dart';
import '../../../ai_callback/presentation/providers/ai_callback_provider.dart';
import '../providers/appointment_provider.dart';

class AICallbackSection extends StatefulWidget {
  final String? clinicId;
  final String? doctorId;
  final String? scheduledAt;

  const AICallbackSection({
    super.key,
    this.clinicId,
    this.doctorId,
    this.scheduledAt,
  });

  @override
  State<AICallbackSection> createState() => _AICallbackSectionState();
}

class _AICallbackSectionState extends State<AICallbackSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null && mounted) {
        context.read<AiCallbackProvider>().setupSocketAuth(token);
      }
    });
  }

  Future<void> _handleTriggerCall() async {
    final callbackProvider = context.read<AiCallbackProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();

    final clinicId = widget.clinicId ?? 'e122d8ec-bad0-4407-9691-6a82190598b0';
    final doctorId = widget.doctorId ?? appointmentProvider.selectedDoctorId;
    final scheduledAt = widget.scheduledAt ?? appointmentProvider.selectedDate?.toIso8601String();

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();

    try {
      await callbackProvider.triggerVapiCall(
        clinicId: clinicId,
        doctorId: doctorId,
        scheduledAt: scheduledAt,
        token: token,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              callbackProvider.errorMessage ?? 'Unable to initiate AI call: $e',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[AICallbackSection] Failed to launch dialer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final callbackProvider = context.watch<AiCallbackProvider>();
    final isCalling = callbackProvider.isCalling;
    final outcome = callbackProvider.outcome;
    final isLoading = callbackProvider.isLoading;

    // Terminal states check
    if (outcome == 'confirmed') {
      return _buildConfirmedCard(callbackProvider);
    } else if (outcome == 'reschedule_requested' || outcome == 'cancel_requested') {
      return _buildRescheduleOrCancelCard(callbackProvider);
    } else if (outcome == 'no_answer' || outcome == 'unclear') {
      return _buildRetryCard(callbackProvider);
    } else if (isCalling || outcome == 'calling' || callbackProvider.status == 'pending') {
      return _buildCallingInProgressCard(callbackProvider);
    }

    // Default: Initial Request Call state
    return _buildInitialStateCard(isLoading);
  }

  Widget _buildInitialStateCard(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCFBF1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.phoneCall, size: 20, color: AppColors.teal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Voice Booking Assistant',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Confirm or reschedule slot over an automated voice call',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Can’t decide on a time slot? Our AI coordinator will call your phone right now to finalize appointment details in Hindi or English.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _handleTriggerCall,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.phoneOutgoing, size: 18),
              label: Text(
                isLoading ? 'Initiating Call...' : 'Request AI Callback',
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallingInProgressCard(AiCallbackProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.phoneIncoming, size: 22, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calling you now…',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E40AF),
                      ),
                    ),
                    Text(
                      'आपको कॉल किया जा रहा है…',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertCircle, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Appointment is NOT booked yet. Please answer the call to confirm your time slot.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => provider.cancelCallback(),
                child: Text(
                  'Cancel Request',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmedCard(AiCallbackProvider provider) {
    final dateStr = provider.scheduledAt != null
        ? DateFormat('EEEE, MMM d, yyyy • h:mm a').format(provider.scheduledAt!)
        : 'Tomorrow 10:00 AM';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.checkCircle2, size: 24, color: Color(0xFF16A34A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment Confirmed via AI Call!',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF166534),
                      ),
                    ),
                    Text(
                      'Booking has been confirmed by our voice agent',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildDetailRow(LucideIcons.user, 'Doctor', provider.doctorName ?? 'Attending Specialist'),
          const SizedBox(height: 8),
          _buildDetailRow(LucideIcons.calendar, 'Scheduled Slot', dateStr),
          const SizedBox(height: 8),
          _buildDetailRow(LucideIcons.building2, 'Clinic', provider.clinicName ?? 'Sunrise Medical Center'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () {
                provider.reset();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF166534),
                side: const BorderSide(color: Color(0xFF86EFAC)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Done • View in Appointments',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRescheduleOrCancelCard(AiCallbackProvider provider) {
    final isReschedule = provider.outcome == 'reschedule_requested';
    final clinicPhone = provider.clinicPhone ?? '+919876543210';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.phoneCall, size: 22, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReschedule ? 'Reschedule Requested' : 'Cancellation Requested',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    Text(
                      'Call ended with request for manual scheduling',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You indicated during the call that you would like to ${isReschedule ? 'reschedule to another time' : 'cancel this booking'}. Our clinic reception desk has been notified. Please call the clinic directly to coordinate immediately:',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _makePhoneCall(clinicPhone),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(LucideIcons.phone, size: 16),
              label: Text(
                'Call Clinic: $clinicPhone',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => provider.reset(),
              child: Text(
                'Dismiss / Try Again',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryCard(AiCallbackProvider provider) {
    final isNoAnswer = provider.outcome == 'no_answer';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.phoneMissed, size: 22, color: Color(0xFFDC2626)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNoAnswer ? 'No Answer on Call' : 'Call Unclear',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                    Text(
                      isNoAnswer
                          ? 'We could not reach your phone'
                          : 'Could not capture booking confirmation',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB91C1C)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We were unable to confirm your booking during the voice call. You can retry the callback or proceed to book manually.',
            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _handleTriggerCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(LucideIcons.rotateCcw, size: 16),
                    label: Text(
                      'Retry Callback',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => provider.reset(),
                child: Text(
                  'Dismiss',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.teal),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
