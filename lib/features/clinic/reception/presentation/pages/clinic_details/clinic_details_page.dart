import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/router/route_names.dart';
import '../../providers/clinic_details_provider.dart';

class ClinicDetailsPage extends StatefulWidget {
  const ClinicDetailsPage({super.key});

  @override
  State<ClinicDetailsPage> createState() => _ClinicDetailsPageState();
}

class _ClinicDetailsPageState extends State<ClinicDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _operatingHoursController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClinic();
    });
  }

  Future<void> _loadClinic() async {
    final provider = context.read<ClinicDetailsProvider>();
    await provider.fetchClinicDetails();
    if (provider.clinic != null && mounted) {
      _populateFields();
    }
  }

  void _populateFields() {
    final clinic = context.read<ClinicDetailsProvider>().clinic;
    if (clinic == null) return;
    _nameController.text = clinic.name;
    _addressController.text = clinic.address;
    _phoneController.text = clinic.phone ?? '';
    _specialtyController.text = clinic.specialty ?? '';
    _operatingHoursController.text = clinic.operatingHours ?? '';
    _descriptionController.text = clinic.description ?? '';
    _isInitialized = true;
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _operatingHoursController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ClinicDetailsProvider>();
    final success = await provider.saveClinicDetails(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      specialty: _specialtyController.text.trim(),
      operatingHours: _operatingHoursController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clinic details updated successfully!'),
          backgroundColor: Color(0xFF0D9488),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to update clinic details.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClinicDetailsProvider>(
      builder: (context, provider, child) {
        final clinic = provider.clinic;

        if (provider.isLoading && clinic == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            ),
          );
        }

        if (clinic != null && !_isInitialized) {
          _populateFields();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Clinic Profile & Details',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _loadClinic,
                icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.teal),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System Badges Card (Read-only / Non-editable)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDFA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(LucideIcons.shieldCheck, color: AppColors.teal, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clinic?.name ?? 'Clinic Details',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'System Status & Verified Ratings',
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
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            // Rating Badge
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${clinic?.rating.toStringAsFixed(1) ?? '4.8'} (${clinic?.reviewCount ?? 0})',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Queue Status Badge
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: (clinic?.isLiveQueueActive ?? true)
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      (clinic?.isLiveQueueActive ?? true)
                                          ? LucideIcons.checkCircle2
                                          : LucideIcons.clock,
                                      size: 14,
                                      color: (clinic?.isLiveQueueActive ?? true)
                                          ? const Color(0xFF15803D)
                                          : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (clinic?.isLiveQueueActive ?? true) ? 'Queue Active' : 'Inactive',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: (clinic?.isLiveQueueActive ?? true)
                                            ? const Color(0xFF15803D)
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ℹ Rating and Live Queue status are system-computed and cannot be self-reported.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Location Card with quick link to map pin editor
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.mapPin, color: AppColors.teal, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Map Coordinates',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${clinic?.latitude.toStringAsFixed(4) ?? '28.5921'}, ${clinic?.longitude.toStringAsFixed(4) ?? '77.0460'}',
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 12,
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, RouteNames.receptionClinicEdit).then((_) {
                              _loadClinic();
                            });
                          },
                          icon: const Icon(LucideIcons.map, size: 14),
                          label: const Text('Edit Pin'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.teal,
                            side: const BorderSide(color: AppColors.teal),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Editable Clinic Information',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Clinic Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Clinic Name',
                    hint: 'e.g. Sunrise Medical Center',
                    icon: LucideIcons.building,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Clinic name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Street Address
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address / Street Location',
                    hint: 'e.g. Sector 12, Dwarka, New Delhi',
                    icon: LucideIcons.mapPinned,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Contact Phone
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Contact Phone Number',
                    hint: 'e.g. +91 22 2700 3300',
                    icon: LucideIcons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Primary Specialty
                  _buildTextField(
                    controller: _specialtyController,
                    label: 'Clinical Specialty',
                    hint: 'e.g. Orthopedics & Multi-Specialty',
                    icon: LucideIcons.stethoscope,
                  ),
                  const SizedBox(height: 16),

                  // Operating Hours
                  _buildTextField(
                    controller: _operatingHoursController,
                    label: 'Operating Hours',
                    hint: 'e.g. Mon-Sat 9:00 AM - 9:00 PM',
                    icon: LucideIcons.clock,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Clinic Description & Facilities',
                    hint: 'Describe services, queuing policies, and facilities...',
                    icon: LucideIcons.fileText,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 28),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: provider.isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: provider.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.check, size: 20),
                      label: Text(
                        provider.isSaving ? 'Saving Changes...' : 'Save Clinic Details',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: Icon(icon, size: 18, color: AppColors.teal),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
