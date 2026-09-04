import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/router/role_redirect.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';

enum LoginMode { patient, staff }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginMode _mode = LoginMode.patient;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _patientFormKey = GlobalKey<FormState>();
  final _staffFormKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSendOTP() {
    if (_patientFormKey.currentState?.validate() ?? false) {
      final phone = '+91${_phoneController.text.trim()}';
      context.read<AuthProvider>().sendOTP(
        phone,
        onCodeSent: (verificationId) {
          Navigator.pushNamed(
            context,
            RouteNames.otpVerification,
            arguments: phone,
          );
        },
      );
    }
  }

  Future<void> _onStaffLogin() async {
    if (_staffFormKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final response = await context.read<AuthProvider>().signInWithEmailAndPassword(email, password);

      if (response != null && response.status == 'success' && response.user != null && mounted) {
        RoleRedirect.redirect(context, response.user!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(LucideIcons.heartPulse, size: 36, color: AppColors.teal),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Arogyam',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                _mode == LoginMode.patient ? 'Patient Portal' : 'Hospital & Staff Portal',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _mode == LoginMode.patient
                    ? 'Enter your mobile number to receive a secure login OTP'
                    : 'Sign in with your hospital staff credentials to access reception and clinic tools',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Mode selector tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          authProvider.clearError();
                          setState(() => _mode = LoginMode.patient);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _mode == LoginMode.patient ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _mode == LoginMode.patient
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.user,
                                  size: 16,
                                  color: _mode == LoginMode.patient ? AppColors.teal : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Patient (OTP)',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: _mode == LoginMode.patient ? FontWeight.bold : FontWeight.w500,
                                    color: _mode == LoginMode.patient ? AppColors.teal : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          authProvider.clearError();
                          setState(() => _mode = LoginMode.staff);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _mode == LoginMode.staff ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _mode == LoginMode.staff
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.building2,
                                  size: 16,
                                  color: _mode == LoginMode.staff ? AppColors.teal : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Staff Login',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: _mode == LoginMode.staff ? FontWeight.bold : FontWeight.w500,
                                    color: _mode == LoginMode.staff ? AppColors.teal : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              if (_mode == LoginMode.patient) ...[
                Form(
                  key: _patientFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mobile Number',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '9876543210',
                          prefixText: '+91 ',
                          prefixIcon: const Icon(LucideIcons.phone, size: 18),
                          filled: true,
                          fillColor: Colors.white,
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
                        validator: Validators.validatePhone,
                      ),
                      if (authProvider.error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          authProvider.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _onSendOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Get OTP', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Form(
                  key: _staffFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Staff Email',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'reception.sunrise@arogyam.test',
                          prefixIcon: const Icon(LucideIcons.mail, size: 18),
                          filled: true,
                          fillColor: Colors.white,
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
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Password',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(LucideIcons.lock, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: Colors.white,
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
                        validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                      ),
                      if (authProvider.error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          authProvider.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _onStaffLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Staff Sign In', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
