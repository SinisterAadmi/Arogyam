import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/validators.dart';
import '../../providers/patient_profile_provider.dart';
import '../../data/models/patient_model.dart';

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

  @override
  void initState() {
    super.initState();
    final patient = context.read<PatientProfileProvider>().patient;
    _nameController = TextEditingController(text: patient?.name);
    _emailController = TextEditingController(text: 'rajesh.kumar@example.com'); // Mock
    _phoneController = TextEditingController(text: '9876543210'); // Mock
    _addressController = TextEditingController(text: 'Sector 5, Dwarka, New Delhi'); // Mock
    _emergencyNameController = TextEditingController(text: 'Sunita Kumar'); // Mock
    _emergencyPhoneController = TextEditingController(text: '9876543211'); // Mock
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildField('Full Name', _nameController, Validators.validateRequired),
              const SizedBox(height: 16),
              _buildField('Email Address', _emailController, Validators.validateEmail, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildField('Phone Number', _phoneController, Validators.validatePhone, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField('Home Address', _addressController, Validators.validateRequired),
              const SizedBox(height: 24),
              Text(
                'Emergency Contact',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _buildField('Contact Name', _emergencyNameController, Validators.validateRequired),
              const SizedBox(height: 12),
              _buildField('Contact Number', _emergencyPhoneController, Validators.validatePhone, keyboardType: TextInputType.phone),
              const SizedBox(height: 32),
              _buildSaveButton(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String? Function(String?, String)? validator, {TextInputType? keyboardType}) {
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
          validator: (v) => validator?.call(v, label),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
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
      height: 52,
      child: ElevatedButton(
        onPressed: provider.isLoading ? null : () => _save(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: provider.isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _save(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<PatientProfileProvider>();
      final currentPatient = provider.patient!;
      
      final updated = PatientModel(
        id: currentPatient.id,
        name: _nameController.text,
        abhaId: currentPatient.abhaId,
        isAbhaLinked: currentPatient.isAbhaLinked,
        imageUrl: currentPatient.imageUrl,
      );
      
      await provider.updateProfile(updated);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      }
    }
  }
}
