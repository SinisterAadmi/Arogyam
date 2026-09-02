import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/router/route_names.dart';
import '../../../../../app/router/navigation_provider.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../patient_home/patient_home_page.dart';
import '../../providers/patient_profile_provider.dart';
import '../../providers/patient_home_provider.dart';
import 'edit_profile_sheet.dart';

class PatientProfilePage extends StatelessWidget {
  const PatientProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<PatientProfileProvider>();
    final homeProvider = context.read<PatientHomeProvider>();
    
    // Sync patient from home provider if not set in profile
    if (profileProvider.patient == null && homeProvider.patient != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        profileProvider.setPatient(homeProvider.patient!);
      });
    }

    final patient = profileProvider.patient;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: patient == null 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, patient),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSection('Personal Details', [
                        _buildDetailItem(LucideIcons.user, 'Gender', 'Male'),
                        _buildDetailItem(LucideIcons.calendar, 'DOB', '15 Aug 1990'),
                        _buildDetailItem(LucideIcons.droplets, 'Blood Group', 'O+'),
                        _buildDetailItem(LucideIcons.mapPin, 'Address', 'Sector 5, Dwarka, New Delhi'),
                        _buildDetailItem(LucideIcons.mail, 'Email', 'rajesh.kumar@example.com'),
                      ]),
                      const SizedBox(height: 20),
                      _buildABHASection(context, patient),
                      const SizedBox(height: 20),
                      _buildSection('Privacy & Security', [
                        _buildMenuItem(LucideIcons.shield, 'Consent & Record Sharing', () {}),
                        _buildMenuItem(LucideIcons.history, 'Access History', () {}),
                        _buildSecurityToggle(profileProvider),
                      ]),
                      const SizedBox(height: 20),
                      _buildSection('App Preferences', [
                        _buildMenuItem(LucideIcons.languages, 'Language', () {}, trailing: 'English'),
                        _buildMenuItem(LucideIcons.moon, 'Theme', () {}, trailing: 'System'),
                      ]),
                      const SizedBox(height: 20),
                      _buildSection('Support', [
                        _buildMenuItem(LucideIcons.helpCircle, 'Help & Support', () {}),
                        _buildMenuItem(LucideIcons.info, 'About Arogyam', () {}),
                        _buildDetailItem(LucideIcons.code, 'App Version', '1.0.42 (Beta)', isLast: true),
                      ]),
                      const SizedBox(height: 32),
                      _buildLogoutButton(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic patient) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(patient.imageUrl ?? ''),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showEditProfile(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            patient.name,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ABHA: ${_maskId(patient.abhaId)}',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
              ),
              if (patient.isAbhaLinked) ...[
                const SizedBox(width: 6),
                const Icon(LucideIcons.checkCircle, color: Colors.green, size: 14),
              ],
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _showEditProfile(context),
            icon: const Icon(LucideIcons.edit3, size: 16),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.teal,
              side: const BorderSide(color: AppColors.teal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {String? trailing, bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (trailing != null) 
              Text(trailing, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityToggle(PatientProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(LucideIcons.fingerprint, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text('Biometric Lock', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          const Spacer(),
          Switch.adaptive(
            value: provider.isBiometricEnabled,
            activeTrackColor: AppColors.teal,
            onChanged: provider.toggleBiometrics,
          ),
        ],
      ),
    );
  }

  Widget _buildABHASection(BuildContext context, dynamic patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ABHA Account',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.creditCard, color: AppColors.teal),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.isAbhaLinked ? 'Linked ABHA ID' : 'Link your ABHA ID',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      patient.isAbhaLinked ? _maskId(patient.abhaId) : 'Unlock digital health services',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  if (patient.isAbhaLinked) {
                    // Manage
                  } else {
                    Navigator.of(context, rootNavigator: true).pushNamed(RouteNames.abhaLinking);
                  }
                },
                child: Text(patient.isAbhaLinked ? 'Manage' : 'Link Now'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(LucideIcons.logOut, color: Colors.red),
        label: Text('Log Out', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out of Arogyam?'),
        content: const Text('You will need to sign in again to access your health information.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Log out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const EditProfileSheet(),
    );
  }

  String _maskId(String id) {
    final clean = id.replaceAll('-', '');
    if (clean.length < 12) return id;
    return 'XXXX-XXXX-${clean.substring(clean.length - 4)}';
  }
}
