import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/validators.dart';
import '../../providers/patient_profile_provider.dart';
import '../../providers/patient_home_provider.dart';
import '../../../data/models/patient_model.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  DateTime? _selectedDob;
  String? _selectedGender;
  String? _selectedBloodGroup;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    final patient = context.read<PatientProfileProvider>().patient;
    _nameController = TextEditingController(text: patient?.name ?? '');
    _emailController = TextEditingController(text: patient?.email ?? '');
    _phoneController = TextEditingController(text: patient?.phoneNumber ?? '');
    _addressController = TextEditingController(text: patient?.address ?? '');
    _emergencyNameController = TextEditingController(text: patient?.emergencyContactName ?? '');
    _emergencyPhoneController = TextEditingController(text: patient?.emergencyContactPhone ?? '');
    _selectedDob = patient?.dob;
    _selectedGender = patient?.gender;
    _selectedBloodGroup = patient?.bloodGroup;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    final patient = context.read<PatientProfileProvider>().patient;
    return _nameController.text != (patient?.name ?? '') ||
        _emailController.text != (patient?.email ?? '') ||
        _addressController.text != (patient?.address ?? '') ||
        _emergencyNameController.text != (patient?.emergencyContactName ?? '') ||
        _emergencyPhoneController.text != (patient?.emergencyContactPhone ?? '') ||
        _selectedDob != patient?.dob ||
        _selectedGender != patient?.gender ||
        _selectedBloodGroup != patient?.bloodGroup;
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text('You have unsaved edits in your profile. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return shouldDiscard ?? false;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canClose = await _onWillPop();
        if (canClose && mounted) {
          Navigator.pop(this.context);
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.userPen, color: AppColors.teal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Edit Profile',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () async {
                      final canClose = await _onWillPop();
                      if (canClose && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(LucideIcons.x, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField('Full Name', _nameController, (v) => Validators.validateRequired(v, 'Full Name')),
                      const SizedBox(height: 16),
                      
                      // DOB and Gender row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date of Birth',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickDob,
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.calendar, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 8),
                                        Text(
                                          _selectedDob != null
                                              ? '${_selectedDob!.day.toString().padLeft(2, '0')}/${_selectedDob!.month.toString().padLeft(2, '0')}/${_selectedDob!.year}'
                                              : 'Select Date',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: _selectedDob != null ? AppColors.textPrimary : AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gender',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedGender,
                                      hint: Text('Select', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                                      isExpanded: true,
                                      items: _genders
                                          .map((g) => DropdownMenuItem(value: g, child: Text(g, style: GoogleFonts.inter(fontSize: 13))))
                                          .toList(),
                                      onChanged: (val) => setState(() => _selectedGender = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Blood Group and Phone row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Blood Group',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedBloodGroup,
                                      hint: Text('Select', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                                      isExpanded: true,
                                      items: _bloodGroups
                                          .map((bg) => DropdownMenuItem(value: bg, child: Text(bg, style: GoogleFonts.inter(fontSize: 13))))
                                          .toList(),
                                      onChanged: (val) => setState(() => _selectedBloodGroup = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: _buildField('Phone Number', _phoneController, null, keyboardType: TextInputType.phone, readOnly: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildField('Email Address', _emailController, (v) => v != null && v.isNotEmpty ? Validators.validateEmail(v) : null, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildField('Residential Address', _addressController, null),
                      const SizedBox(height: 20),

                      Text(
                        'Emergency Contact',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      _buildField('Contact Person Name', _emergencyNameController, null),
                      const SizedBox(height: 12),
                      _buildField('Emergency Phone Number', _emergencyPhoneController, (v) => v != null && v.isNotEmpty ? Validators.validatePhone(v) : null, keyboardType: TextInputType.phone),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildSaveButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String? Function(String?)? validator, {
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14, color: readOnly ? AppColors.textSecondary : AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? const Color(0xFFF3F4F6) : AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Widget _buildSaveButton(BuildContext context) {
    final provider = context.watch<PatientProfileProvider>();
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: provider.isLoading ? null : () => _save(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: provider.isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<PatientProfileProvider>();
      final homeProvider = context.read<PatientHomeProvider>();
      final currentPatient = provider.patient;

      final updated = PatientModel(
        id: currentPatient?.id ?? '',
        name: _nameController.text.trim(),
        abhaId: currentPatient?.abhaId,
        isAbhaLinked: currentPatient?.isAbhaLinked ?? false,
        imageUrl: currentPatient?.imageUrl,
        dob: _selectedDob,
        gender: _selectedGender,
        bloodGroup: _selectedBloodGroup,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        emergencyContactName: _emergencyNameController.text.trim().isNotEmpty ? _emergencyNameController.text.trim() : null,
        emergencyContactPhone: _emergencyPhoneController.text.trim().isNotEmpty ? _emergencyPhoneController.text.trim() : null,
      );

      try {
        await provider.updateProfile(updated);
        // Synchronize updated patient to Home dashboard provider
        homeProvider.setPatient(updated);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.teal,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}
