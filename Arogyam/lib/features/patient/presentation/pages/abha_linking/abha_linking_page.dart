import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/router/navigation_provider.dart';
import '../../../../../shared/widgets/page_header.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../providers/abha_provider.dart';

class AbhaLinkingPage extends StatefulWidget {
  const AbhaLinkingPage({super.key});

  @override
  State<AbhaLinkingPage> createState() => _AbhaLinkingPageState();
}

class _AbhaLinkingPageState extends State<AbhaLinkingPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<bool> _handleBack(AbhaProvider provider) async {
    if (provider.abhaId.isNotEmpty || provider.otpSent) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard details?'),
          content: const Text('Are you sure you want to stop the ABHA linking process?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continue')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
          ],
        ),
      );
      return shouldDiscard ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AbhaProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBack(provider);
        if (shouldPop && mounted) {
           this.context.read<NavigationProvider>().setIndex(0);
           Navigator.of(this.context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, provider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                      _buildStep1(provider),
                      if (provider.otpSent) ...[
                        const SizedBox(height: 32),
                        _buildStep2(provider),
                      ],
                      const SizedBox(height: 32),
                      _buildPrivacyNotice(),
                      const SizedBox(height: 32),
                      _buildActionButton(context, provider),
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

  Widget _buildHeader(BuildContext context, AbhaProvider provider) {
    return PageHeader(
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (await _handleBack(provider)) {
                if (mounted) {
                  this.context.read<NavigationProvider>().setIndex(0);
                  Navigator.pop(this.context);
                }
              }
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
            'Link ABHA Account',
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCFBF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.helpCircle, size: 20, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                'What is ABHA?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The Ayushman Bharat Health Account (ABHA) is a unique 14-digit ID that allows you to share your health records with verified doctors and hospitals digitally.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(AbhaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Enter your 14-digit ABHA ID',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _idController,
          enabled: !provider.otpSent && !provider.isLoading,
          onChanged: provider.setAbhaId,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'e.g. 91-8273-1284-9102',
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.teal, width: 2),
            ),
          ),
        ),
        if (provider.error != null && !provider.otpSent) ...[
          const SizedBox(height: 8),
          Text(
            provider.error!,
            style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2(AbhaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Enter 6-digit OTP',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sent to your registered mobile number',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _otpController,
          onChanged: provider.setOtp,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: 'Enter OTP',
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        if (provider.error != null && provider.otpSent) ...[
          const SizedBox(height: 8),
          Text(
            provider.error!,
            style: GoogleFonts.inter(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildPrivacyNotice() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(LucideIcons.shieldCheck, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Your data is secure. By linking, you agree to share your basic health profile with Arogyam in accordance with NHA guidelines.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, AbhaProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: provider.isLoading
            ? null
            : () async {
                if (!provider.otpSent) {
                  await provider.sendOtp();
                } else {
                  final success = await provider.verifyOtpAndLink();
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ABHA ID linked successfully!')),
                    );
                    context.read<NavigationProvider>().setIndex(0);
                    Navigator.pop(context);
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: provider.isLoading
            ? const AppLoader(size: 20, color: Colors.white)
            : Text(
                provider.otpSent ? 'Verify & Link' : 'Get OTP',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
