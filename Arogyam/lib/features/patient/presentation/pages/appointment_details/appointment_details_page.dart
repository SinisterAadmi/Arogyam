import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../providers/appointment_details_provider.dart';
import '../../providers/patient_home_provider.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsPage({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentDetailsProvider>().fetchAppointment(widget.appointmentId);
    });
  }

  String _formatAppointmentTime(String timeStr) {
    final parsed = DateTime.tryParse(timeStr);
    if (parsed == null) return timeStr;
    final local = parsed.toLocal();
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${local.day} ${months[local.month - 1]} ${local.year} • $hour:$minute $period';
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'confirmed':
        return const Color(0xFFDCFCE7);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      case 'reschedule_requested':
        return const Color(0xFFFEF3C7);
      case 'pending':
      default:
        return const Color(0xFFE0E7FF);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'confirmed':
        return const Color(0xFF166534);
      case 'cancelled':
        return const Color(0xFF991B1B);
      case 'reschedule_requested':
        return const Color(0xFF92400E);
      case 'pending':
      default:
        return const Color(0xFF3730A3);
    }
  }

  void _showCancelConfirmationDialog(BuildContext context, AppointmentDetailsProvider provider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Appointment',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to cancel this appointment?',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'No, Keep It',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final homeProvider = context.read<PatientHomeProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);

              Navigator.pop(dialogCtx);
              final success = await provider.cancelAppointment(widget.appointmentId);
              if (!mounted) return;

              if (success) {
                // Refresh upcoming appointments on PatientHomeProvider
                homeProvider.loadDashboardData(isRefresh: true);

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Appointment cancelled successfully'),
                    backgroundColor: AppColors.teal,
                  ),
                );
                nav.pop();
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Failed to cancel appointment'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentDetailsProvider>();
    final appointment = provider.appointment;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Appointment Details',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: provider.isLoading && appointment == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : provider.errorMessage != null && appointment == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(provider.errorMessage!, style: GoogleFonts.inter(color: Colors.redAccent)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => provider.fetchAppointment(widget.appointmentId),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : appointment == null
                  ? const Center(child: Text('Appointment not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _getStatusBgColor(appointment.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  appointment.status.toLowerCase() == 'cancelled'
                                      ? LucideIcons.xCircle
                                      : LucideIcons.checkCircle,
                                  color: _getStatusTextColor(appointment.status),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  appointment.status.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _getStatusTextColor(appointment.status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Doctor & Clinic Information Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF0FDFA),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.stethoscope, color: AppColors.teal, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appointment.doctorName,
                                            style: GoogleFonts.inter(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            appointment.specialty,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 28, color: Color(0xFFE2E8F0)),
                                _buildDetailRow(
                                  icon: LucideIcons.building,
                                  label: 'Clinic / Facility',
                                  value: appointment.clinicName,
                                ),
                                const SizedBox(height: 14),
                                _buildDetailRow(
                                  icon: LucideIcons.calendar,
                                  label: 'Scheduled Time',
                                  value: _formatAppointmentTime(appointment.appointmentTime),
                                ),
                                if (appointment.tokenNumber.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  _buildDetailRow(
                                    icon: LucideIcons.ticket,
                                    label: 'Queue Token',
                                    value: '#${appointment.tokenNumber}',
                                    valueColor: AppColors.teal,
                                    isBold: true,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Cancel Appointment Action (Visible only for scheduled / pending)
                          if (appointment.status.toLowerCase() == 'scheduled' ||
                              appointment.status.toLowerCase() == 'pending') ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: provider.isCancelling
                                    ? null
                                    : () => _showCancelConfirmationDialog(context, provider),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: provider.isCancelling
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                      )
                                    : const Icon(LucideIcons.trash2, size: 18),
                                label: Text(
                                  provider.isCancelling ? 'Cancelling...' : 'Cancel Appointment',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
