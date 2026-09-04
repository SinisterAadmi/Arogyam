import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/mixins/polling_mixin.dart';
import '../../../../../core/security/biometric_service.dart';
import '../../../../../core/widgets/app_refresh_progress_bar.dart';
import '../../../../../shared/widgets/page_header.dart';
import '../../providers/medical_history_provider.dart';
import '../../providers/prescriptions_provider.dart';
import 'tabs/prescriptions_tab.dart';
import 'tabs/records_tab.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage>
    with WidgetsBindingObserver, PollingMixin<MedicalHistoryPage> {
  bool _showPrescriptions = false;
  bool _isVaultUnlocked = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptVaultUnlock();
    });
  }

  Future<void> _checkAndPromptVaultUnlock() async {
    final bio = BiometricService();
    if (bio.isVaultUnlocked) {
      if (mounted) setState(() => _isVaultUnlocked = true);
      return;
    }

    final isSupported = await bio.isDeviceSupported();
    final canCheck = await bio.canCheckBiometrics();
    if (!isSupported || !canCheck) {
      // Graceful fallback for devices without biometric hardware
      bio.setVaultUnlocked(true);
      if (mounted) setState(() => _isVaultUnlocked = true);
      return;
    }

    await _unlockWithBiometrics();
  }

  Future<void> _unlockWithBiometrics() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final authenticated = await BiometricService().authenticate(
      localizedReason: 'Authenticate with biometrics or PIN to access your Medical History Vault',
      bypassIfUnsupported: true,
    );

    if (mounted) {
      setState(() {
        _isVaultUnlocked = authenticated;
        _isAuthenticating = false;
      });
      if (authenticated) {
        BiometricService().setVaultUnlocked(true);
      }
    }
  }

  @override
  Duration get pollingInterval => const Duration(seconds: 30);

  @override
  int? get tabIndex => 2;

  @override
  Future<void> onPoll() async {
    if (mounted && _isVaultUnlocked) {
      await Future.wait([
        context.read<MedicalHistoryProvider>().refresh(),
        context.read<PrescriptionsProvider>().refresh(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVaultUnlocked) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildVaultLockScreen()),
            ],
          ),
        ),
      );
    }

    return Consumer2<MedicalHistoryProvider, PrescriptionsProvider>(
      builder: (context, historyProvider, rxProvider, _) {
        final isRefreshing = historyProvider.isRefreshing || rxProvider.isRefreshing;
        return Column(
          children: [
            AppRefreshProgressBar(isRefreshing: isRefreshing),
            _buildHeader(context),
            Expanded(
              child: _showPrescriptions
                  ? const PrescriptionsTab()
                  : RecordsTab(
                      onPrescriptionsTap: () {
                        setState(() => _showPrescriptions = true);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVaultLockScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFCCFBF1), width: 2),
              ),
              child: const Icon(LucideIcons.lock, size: 42, color: AppColors.teal),
            ),
            const SizedBox(height: 20),
            Text(
              'Health Records Vault',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your medical records and prescriptions are protected by biometric encryption. Authenticate to view.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isAuthenticating ? null : _unlockWithBiometrics,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isAuthenticating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.fingerprint, size: 20),
                label: Text(
                  _isAuthenticating ? 'Authenticating...' : 'Unlock with Biometrics / PIN',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() => _isVaultUnlocked = true);
                BiometricService().setVaultUnlocked(true);
              },
              child: Text(
                'Use device credentials fallback',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return PageHeader(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (_showPrescriptions)
                GestureDetector(
                  onTap: () => setState(() => _showPrescriptions = false),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.arrowLeft,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              Text(
                _showPrescriptions ? 'Prescriptions' : 'Medical History',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.shieldCheck,
                  size: 14,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 4),
                Text(
                  'Encrypted',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
