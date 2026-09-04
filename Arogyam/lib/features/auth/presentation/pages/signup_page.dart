import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  final _formKey = GlobalKey<FormState>();

  final List<String> _genders = ['Male', 'Female', 'Other'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onCompleteProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      await context.read<AuthProvider>().completeSignup(
        name: _nameController.text.trim(),
        dob: _selectedDate?.toIso8601String(),
        gender: _selectedGender,
      );
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        Navigator.pushNamedAndRemoveUntil(context, RouteNames.patientHome, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Complete Profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Just a few more details to get you started',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(LucideIcons.user),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth (Optional)',
                      prefixIcon: Icon(LucideIcons.calendar),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _selectedDate == null ? 'Select Date' : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender (Optional)',
                    prefixIcon: Icon(LucideIcons.users),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (value) => setState(() => _selectedGender = value),
                ),
                if (authProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    authProvider.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _onCompleteProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Complete Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
