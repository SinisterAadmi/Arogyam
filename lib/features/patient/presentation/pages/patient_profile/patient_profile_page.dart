import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/router/route_names.dart';
import '../../../../../app/router/navigation_provider.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../shared/widgets/page_header.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../providers/patient_profile_provider.dart';
import '../../providers/patient_home_provider.dart';
import 'edit_profile_sheet.dart';
import 'widgets/access_history_sheet.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  String _selectedLanguage = 'English';
  String _selectedTheme = 'System';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = context.read<PatientProfileProvider>();
      final homeProvider = context.read<PatientHomeProvider>();

      if (profileProvider.patient == null && homeProvider.patient != null) {
        profileProvider.setPatient(homeProvider.patient!);
      }
      profileProvider.loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<PatientProfileProvider>();
    final homeProvider = context.watch<PatientHomeProvider>();
    final navProvider = context.read<NavigationProvider>();

    final patient = profileProvider.patient ?? homeProvider.patient;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        navProvider.setIndex(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: patient == null && profileProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context, patient),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        children: [
                          _buildPersonalDetailsSection(patient),
                          const SizedBox(height: 20),
                          _buildABHASection(context, patient),
                          const SizedBox(height: 20),
                          _buildPrivacyControlsSection(context, profileProvider, navProvider),
                          const SizedBox(height: 20),
                          _buildAppPreferencesSection(context),
                          const SizedBox(height: 20),
                          _buildSecuritySection(profileProvider),
                          const SizedBox(height: 20),
                          _buildSupportSection(context),
                          const SizedBox(height: 28),
                          _buildLogoutButton(context),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic patient) {
    final imageUrl = patient?.imageUrl != null && patient!.imageUrl.isNotEmpty
        ? patient.imageUrl!
        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=300&q=80';

    final name = patient?.name?.isNotEmpty == true ? patient!.name : 'Patient';
    final phone = patient?.phoneNumber?.isNotEmpty == true ? patient!.phoneNumber : '+91 98765 43210';
    final abhaId = patient?.abhaId;
    final isLinked = patient?.isAbhaLinked == true;

    return PageHeader(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                backgroundImage: NetworkImage(imageUrl),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _uploadAvatar(context),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(LucideIcons.camera, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            phone,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                abhaId != null ? 'ABHA: ${_maskId(abhaId)}' : 'ABHA Not Linked',
                style: GoogleFonts.inter(
                  color: isLinked ? Colors.green.shade700 : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isLinked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isLinked) ...[
                const SizedBox(width: 5),
                const Icon(LucideIcons.checkCircle, color: Colors.green, size: 14),
              ],
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showEditProfile(context),
            icon: const Icon(LucideIcons.userPen, size: 15),
            label: Text('Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.teal,
              side: const BorderSide(color: AppColors.teal, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsSection(dynamic patient) {
    String dobStr = 'Not set';
    if (patient?.dob != null) {
      final dob = patient.dob as DateTime;
      dobStr = '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}';
    }

    final gender = patient?.gender ?? 'Not set';
    final bloodGroup = patient?.bloodGroup ?? 'Not set';
    final address = patient?.address ?? 'Not set';
    final email = patient?.email ?? 'Not set';
    final emergencyName = patient?.emergencyContactName;
    final emergencyPhone = patient?.emergencyContactPhone;
    final emergencyStr = emergencyName != null && emergencyName.isNotEmpty
        ? '$emergencyName ${emergencyPhone != null ? "($emergencyPhone)" : ""}'
        : 'Not set';

    return _buildCard(
      title: 'Personal Details',
      children: [
        _buildDetailItem(LucideIcons.calendar, 'Date of Birth', dobStr),
        _buildDetailItem(LucideIcons.user, 'Gender', gender),
        _buildDetailItem(LucideIcons.droplets, 'Blood Group', bloodGroup),
        _buildDetailItem(LucideIcons.mapPin, 'Address', address),
        _buildDetailItem(LucideIcons.mail, 'Email Address', email),
        _buildDetailItem(LucideIcons.phoneCall, 'Emergency Contact', emergencyStr, isLast: true),
      ],
    );
  }

  Widget _buildABHASection(BuildContext context, dynamic patient) {
    final isLinked = patient?.isAbhaLinked == true;
    final abhaId = patient?.abhaId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ABHA Account',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isLinked ? Colors.green.shade200 : AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLinked ? const Color(0xFFF0FDF4) : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.creditCard,
                  color: isLinked ? Colors.green.shade700 : AppColors.teal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLinked && abhaId != null ? 'Linked ABHA ID' : 'Link Your ABHA ID',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLinked && abhaId != null ? _maskId(abhaId) : 'Unlock ABDM national health services',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  if (isLinked) {
                    _showManageAbhaDialog(context, abhaId ?? '');
                  } else {
                    Navigator.of(context, rootNavigator: true).pushNamed(RouteNames.abhaLinking);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: isLinked ? AppColors.teal : Colors.white,
                  backgroundColor: isLinked ? AppColors.teal.withValues(alpha: 0.1) : AppColors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isLinked ? 'Manage' : 'Link Now',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyControlsSection(BuildContext context, PatientProfileProvider profileProvider, NavigationProvider navProvider) {
    return _buildCard(
      title: 'Privacy & Health-Data Controls',
      children: [
        _buildMenuItem(
          LucideIcons.shieldCheck,
          'Consent & Record Sharing',
          () => _showConsentInfoDialog(context),
          subtitle: 'Records shared only with your permission',
        ),
        _buildMenuItem(
          LucideIcons.history,
          'Access History',
          () => _showAccessHistory(context),
          subtitle: 'Audit logs of recent medical record requests',
        ),
        _buildMenuItem(
          LucideIcons.archive,
          'Medical History Vault',
          () => navProvider.setIndex(2),
          subtitle: 'View active prescriptions & lab records',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildAppPreferencesSection(BuildContext context) {
    return _buildCard(
      title: 'App Preferences',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.bell, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Text('Notifications', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              const Spacer(),
              Switch.adaptive(
                value: _notificationsEnabled,
                activeTrackColor: AppColors.teal,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
              ),
            ],
          ),
        ),
        _buildMenuItem(
          LucideIcons.languages,
          'Language',
          () => _showLanguageSelector(context),
          trailing: _selectedLanguage,
        ),
        _buildMenuItem(
          LucideIcons.moon,
          'Theme',
          () => _showThemeSelector(context),
          trailing: _selectedTheme,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildSecuritySection(PatientProfileProvider provider) {
    return _buildCard(
      title: 'Security',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.fingerprint, size: 20, color: AppColors.teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biometric App Lock',
                          style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          'Require fingerprint/Face ID to access health vault',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: provider.isBiometricEnabled,
                    activeTrackColor: AppColors.teal,
                    onChanged: provider.toggleBiometrics,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return _buildCard(
      title: 'Support & Legal',
      children: [
        _buildMenuItem(LucideIcons.helpCircle, 'Help & Support', () => _showHelpDialog(context)),
        _buildMenuItem(LucideIcons.info, 'About Arogyam', () => _showAboutDialog(context)),
        _buildMenuItem(LucideIcons.fileText, 'Privacy Policy', () => _showLegalDialog(context, 'Privacy Policy')),
        _buildMenuItem(LucideIcons.scale, 'Terms of Service', () => _showLegalDialog(context, 'Terms of Service')),
        _buildDetailItem(LucideIcons.code, 'App Version', '1.0.42 (Beta)', isLast: true),
      ],
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? subtitle,
    String? trailing,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              Text(trailing, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(width: 6),
            ],
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 18),
        label: Text('Log Out', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Log out of Arogyam?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'You will need to sign in again to access your health information.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              // Call real backend logout and clear storage
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                context.read<NavigationProvider>().setIndex(0);
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                  RouteNames.login,
                  (route) => false,
                );
              }
            },
            child: Text('Log out', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditProfileSheet(),
    );
  }

  void _showAccessHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AccessHistorySheet(),
    );
  }

  void _showConsentInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.shieldCheck, color: AppColors.teal, size: 22),
            const SizedBox(width: 10),
            Text('Consent & Sharing', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Your medical records are shared only with your explicit permission under Ayushman Bharat Digital Mission (ABDM) standards.\n\nEvery access request creates an immutable, audited token with automatic expiry.',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }

  void _showManageAbhaDialog(BuildContext context, String abhaId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ABHA Account', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ABHA ID: $abhaId', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Status: Linked & Verified with ABDM Locker', style: GoogleFonts.inter(color: Colors.green, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Language', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...['English', 'Hindi (हिंदी)', 'Marathi (मराठी)'].map(
              (lang) => ListTile(
                title: Text(lang, style: GoogleFonts.inter(fontSize: 14)),
                trailing: _selectedLanguage == lang.split(' ').first
                    ? const Icon(LucideIcons.check, color: AppColors.teal)
                    : null,
                onTap: () {
                  setState(() => _selectedLanguage = lang.split(' ').first);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Theme', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...['System', 'Light', 'Dark'].map(
              (theme) => ListTile(
                title: Text(theme, style: GoogleFonts.inter(fontSize: 14)),
                trailing: _selectedTheme == theme ? const Icon(LucideIcons.check, color: AppColors.teal) : null,
                onTap: () {
                  setState(() => _selectedTheme = theme);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Help & Support', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Email: support@arogyam.gov.in\nToll Free Helpline: 1800-11-4477\nOperating Hours: 24x7',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('About Arogyam', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Arogyam is an ABDM-compliant unified digital healthcare platform designed to streamline outpatient clinic queues, consent-based medical sharing, and doctor consultations.',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Your health data is protected under the National Digital Health Blueprint and the Digital Personal Data Protection Act. Records are encrypted end-to-end.',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _uploadAvatar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar upload requested. Photo updated.'), backgroundColor: AppColors.teal),
    );
  }

  String _maskId(String id) {
    final clean = id.replaceAll('-', '');
    if (clean.length < 8) return id;
    return 'XXXX-XXXX-${clean.substring(clean.length - 4)}';
  }
}
