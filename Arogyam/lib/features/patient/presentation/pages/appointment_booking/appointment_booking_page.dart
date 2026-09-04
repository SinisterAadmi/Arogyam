import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/widgets/page_header.dart';
import '../../../../../app/router/route_names.dart';
import '../../../../../app/router/navigation_provider.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../widgets/clinic_info_card.dart';
import '../../widgets/date_selector.dart';
import '../../widgets/slot_selector.dart';
import '../../providers/appointment_provider.dart';
import '../../../../../shared/entities/clinic.dart';

enum BookingStep { date, slot, reason, confirm }

class AppointmentBookingPage extends StatefulWidget {
  final Clinic clinic;

  const AppointmentBookingPage({
    super.key,
    required this.clinic,
  });

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  BookingStep _currentStep = BookingStep.date;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.clinic.doctors.isNotEmpty) {
        context.read<AppointmentProvider>().setDoctorId(widget.clinic.doctors.first.id);
      }
    });
  }

  Future<bool> _handleBack() async {
    switch (_currentStep) {
      case BookingStep.date:
        if (Navigator.of(context).canPop()) {
          return true;
        } else {
          // Deep link fallback
          context.read<NavigationProvider>().setIndex(1);
          Navigator.of(context).pushReplacementNamed(RouteNames.nearbyClinics);
          return false;
        }
      case BookingStep.slot:
        setState(() => _currentStep = BookingStep.date);
        return false;
      case BookingStep.reason:
        setState(() => _currentStep = BookingStep.slot);
        return false;
      case BookingStep.confirm:
        setState(() => _currentStep = BookingStep.reason);
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBack();
        if (shouldPop && mounted) {
          Navigator.of(this.context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClinicInfoCard(clinic: widget.clinic),
                      const SizedBox(height: 20),
                      _buildDoctorSelector(context),
                      if (_currentStep == BookingStep.date) const DateSelector(),
                      if (_currentStep == BookingStep.slot) const SlotSelector(),
                      if (_currentStep == BookingStep.reason) _buildReasonField(context),
                      if (_currentStep == BookingStep.confirm) _buildConfirmationSummary(),
                      const SizedBox(height: 32),
                      _buildActionButton(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorSelector(BuildContext context) {
    if (widget.clinic.doctors.isEmpty) return const SizedBox.shrink();
    final provider = context.watch<AppointmentProvider>();
    final selectedId = provider.selectedDoctorId ?? widget.clinic.doctors.first.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.stethoscope, size: 16, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                'Select Doctor',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: widget.clinic.doctors.any((d) => d.id == selectedId) ? selectedId : widget.clinic.doctors.first.id,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            items: widget.clinic.doctors.map((d) => DropdownMenuItem(
              value: d.id,
              child: Text(
                '${d.name} (${d.specialty})',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              ),
            )).toList(),
            onChanged: (id) {
              if (id != null) provider.setDoctorId(id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return PageHeader(
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final shouldPop = await _handleBack();
              if (shouldPop && mounted) Navigator.pop(this.context);
            },
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
            _getStepTitle(),
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

  String _getStepTitle() {
    switch (_currentStep) {
      case BookingStep.date: return 'Select Date';
      case BookingStep.slot: return 'Select Time Slot';
      case BookingStep.reason: return 'Reason for Visit';
      case BookingStep.confirm: return 'Confirm Appointment';
    }
  }

  Widget _buildReasonField(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reason for Visit (Optional)', style: AppTypography.h2),
        const SizedBox(height: 12),
        TextField(
          onChanged: provider.setReason,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Regular checkup, Fever, etc.',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationSummary() {
    final provider = context.watch<AppointmentProvider>();
    final doctor = widget.clinic.doctors.firstWhere(
      (d) => d.id == provider.selectedDoctorId,
      orElse: () => widget.clinic.doctors.isNotEmpty
          ? widget.clinic.doctors.first
          : const DoctorInfo(id: '', name: 'Assigned Physician', specialty: 'General'),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSummaryRow(LucideIcons.userCheck, 'Doctor', '${doctor.name} (${doctor.specialty})'),
          const Divider(height: 24),
          _buildSummaryRow(LucideIcons.calendar, 'Date', provider.selectedDate?.toString().split(' ')[0] ?? 'Not selected'),
          const Divider(height: 24),
          _buildSummaryRow(LucideIcons.clock, 'Time', provider.selectedSlot ?? 'Not selected'),
          if (provider.reason.isNotEmpty) ...[
            const Divider(height: 24),
            _buildSummaryRow(LucideIcons.fileText, 'Reason', provider.reason),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
            Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: provider.isLoading ? null : () => _onNext(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: provider.isLoading
            ? const AppLoader(size: 20, color: Colors.white)
            : Text(
                _currentStep == BookingStep.confirm ? 'Confirm Booking' : 'Next',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _onNext(AppointmentProvider provider) async {
    switch (_currentStep) {
      case BookingStep.date:
        if (provider.selectedDate != null) {
          setState(() => _currentStep = BookingStep.slot);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date')));
        }
        break;
      case BookingStep.slot:
        if (provider.selectedSlot != null) {
          setState(() => _currentStep = BookingStep.reason);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a time slot')));
        }
        break;
      case BookingStep.reason:
        setState(() => _currentStep = BookingStep.confirm);
        break;
      case BookingStep.confirm:
        final success = await provider.bookAppointment(widget.clinic);
        if (success && mounted) {
          _showSuccessDialog(context);
        }
        break;
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Icon(LucideIcons.checkCircle, color: Colors.green, size: 64),
            const SizedBox(height: 20),
            Text('Booking Confirmed!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Booking created — we\'ll call you shortly on your phone to confirm your appointment details.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Go to Home tab
                  context.read<NavigationProvider>().setIndex(0);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
