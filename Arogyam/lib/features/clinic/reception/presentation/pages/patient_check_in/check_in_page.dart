import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../core/mixins/polling_mixin.dart';
import '../../../../../../core/widgets/app_refresh_progress_bar.dart';
import '../../providers/checkin_provider.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage>
    with WidgetsBindingObserver, PollingMixin<CheckInPage> {
  int _modeIndex = 0; // 0 = Manual Code, 1 = QR Scanner
  final TextEditingController _codeController = TextEditingController();
  MobileScannerController? _scannerController;
  bool _isTorchOn = false;

  @override
  Duration get pollingInterval => const Duration(seconds: 15);

  @override
  int? get tabIndex => 1;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckInProvider>().fetchAiCallbacks();
    });
  }

  @override
  Future<void> onPoll() async {
    if (mounted) {
      await context.read<CheckInProvider>().fetchAiCallbacks(isSilent: true);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _handleCodeSubmit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    final provider = context.read<CheckInProvider>();
    final success = await provider.verifyShortCode(code);
    if (success && mounted) {
      _codeController.clear();
    }
  }

  void _handleQrDetected(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    final provider = context.read<CheckInProvider>();
    if (provider.isVerifying || provider.verifiedResult != null) return;

    await provider.verifyQrData(rawValue);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckInProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppRefreshProgressBar(isRefreshing: provider.isRefreshingCallbacks),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),

                  if (provider.verifiedResult != null)
                    _buildSuccessView(provider)
                  else ...[
                    _buildModeToggle(),
                    const SizedBox(height: 16),
                    if (provider.errorMessage != null) ...[
                      _buildErrorBanner(provider.errorMessage!),
                      const SizedBox(height: 14),
                    ],
                    if (_modeIndex == 0)
                      _buildManualCodeCard(provider)
                    else
                      _buildQrScannerCard(provider),
                  ],

                  const SizedBox(height: 28),
                  _buildAiCallbacksSection(provider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Patient Check-In Desk',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ABDM Desk Online',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Verify patient consent short code or scan QR code to grant clinical access.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _modeIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _modeIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _modeIndex == 0
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.keyRound,
                      size: 16,
                      color: _modeIndex == 0 ? AppColors.teal : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Manual 6-Digit Code',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: _modeIndex == 0 ? FontWeight.bold : FontWeight.w500,
                        color: _modeIndex == 0 ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _modeIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _modeIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _modeIndex == 1
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.qrCode,
                      size: 16,
                      color: _modeIndex == 1 ? AppColors.teal : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scan Patient QR',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: _modeIndex == 1 ? FontWeight.bold : FontWeight.w500,
                        color: _modeIndex == 1 ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.alertCircle, size: 18, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualCodeCard(CheckInProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Patient Consent Code',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask the patient for the 6-character code shown on their Arogyam app.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            ],
            style: GoogleFonts.sourceCodePro(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 10,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: '• • • • • •',
              hintStyle: GoogleFonts.sourceCodePro(
                fontSize: 24,
                letterSpacing: 8,
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.teal, width: 2),
              ),
            ),
            onSubmitted: (_) => _handleCodeSubmit(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: provider.isVerifying ? null : _handleCodeSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: provider.isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.shieldCheck, size: 18),
              label: Text(
                provider.isVerifying ? 'Verifying Code...' : 'Verify & Grant Consent',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrScannerCard(CheckInProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 260,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController!,
                  onDetect: _handleQrDetected,
                ),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.teal, width: 2.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _scannerController?.toggleTorch();
                      setState(() => _isTorchOn = !_isTorchOn);
                    },
                    icon: Icon(
                      _isTorchOn ? LucideIcons.zap : LucideIcons.zapOff,
                      size: 18,
                    ),
                  ),
                ),
                if (provider.isVerifying)
                  Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.teal),
                          const SizedBox(height: 12),
                          Text(
                            'Verifying QR Token...',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Point the camera at the QR code displayed on the patient\'s app.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(CheckInProvider provider) {
    final result = provider.verifiedResult!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.checkCheck, size: 40, color: Color(0xFF16A34A)),
          ),
          const SizedBox(height: 16),
          Text(
            'Medical Consent Verified!',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Secure ABDM record access granted for this consultation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildSuccessDetailRow('Patient Name', result.patientName, isBold: true),
                const Divider(height: 16),
                _buildSuccessDetailRow(
                  'ABHA ID',
                  result.abhaId ?? 'Not Linked (Auto-Generated)',
                  isTag: result.isAbhaLinked,
                ),
                const Divider(height: 16),
                _buildSuccessDetailRow('Method', result.usedMethod.toUpperCase()),
                const Divider(height: 16),
                _buildSuccessDetailRow('Verified At', '${result.usedAt.toLocal().hour}:${result.usedAt.toLocal().minute.toString().padLeft(2, '0')} IST'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => provider.resetVerification(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(LucideIcons.userPlus, size: 18),
              label: const Text('Next Check-In / Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDetailRow(String label, String value, {bool isBold = false, bool isTag = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        if (isTag)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
      ],
    );
  }

  Widget _buildAiCallbacksSection(CheckInProvider provider) {
    final callbacks = provider.aiCallbacks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(LucideIcons.phoneCall, size: 18, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pending AI Callback Requests',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: callbacks.isEmpty ? const Color(0xFFF1F5F9) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${callbacks.length} Pending',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: callbacks.isEmpty ? AppColors.textMuted : const Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.isLoadingCallbacks && callbacks.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (callbacks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.checkCircle2, size: 32, color: Color(0xFF16A34A)),
                const SizedBox(height: 8),
                Text(
                  'No pending callback requests',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  'When patients request automated assistance, they will appear here.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: callbacks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final cb = callbacks[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.phoneIncoming, size: 18, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cb.patientName,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Phone: ${cb.phone}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Builder(
                            builder: (context) {
                              final slotLocal = cb.requestedSlot.toLocal();
                              final hour = slotLocal.hour > 12 ? slotLocal.hour - 12 : (slotLocal.hour == 0 ? 12 : slotLocal.hour);
                              final minute = slotLocal.minute.toString().padLeft(2, '0');
                              final period = slotLocal.hour >= 12 ? 'PM' : 'AM';
                              return Text(
                                'Requested: $hour:$minute $period',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final ok = await provider.resolveCallback(cb.id);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Marked callback for ${cb.patientName} as handled'),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0FDF4),
                        foregroundColor: const Color(0xFF166534),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFFBBF7D0)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Resolve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
