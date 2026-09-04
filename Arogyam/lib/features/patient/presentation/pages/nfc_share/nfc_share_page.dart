import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/router/navigation_provider.dart';
import '../../../../../shared/widgets/page_header.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../domain/usecases/start_nfc_session.dart';
import '../../../domain/usecases/share_medical_history.dart';

enum NfcShareStatus {
  idle,
  starting,
  active,
  shared,
  expired,
}

enum SharePresentationMode {
  nfc,
  qr,
  code,
}

class NfcSharePage extends StatefulWidget {
  const NfcSharePage({super.key});

  @override
  State<NfcSharePage> createState() => _NfcSharePageState();
}

class _NfcSharePageState extends State<NfcSharePage> with SingleTickerProviderStateMixin {
  NfcShareStatus _status = NfcShareStatus.idle;
  SharePresentationMode _selectedMode = SharePresentationMode.qr;
  bool _shareFullHistory = false;
  bool _selectedRecordsOnly = true;
  String? _consentToken;
  String? _sessionId;
  String? _shortCode;
  String? _qrToken;
  int _remainingSeconds = 0;
  int _codeRemainingSeconds = 0;
  Timer? _countdownTimer;
  Timer? _pollingTimer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  Future<void> _startSession() async {
    setState(() {
      _status = NfcShareStatus.starting;
      _consentToken = null;
    });

    try {
      final session = await StartNfcSession().createSession();
      final remaining = session.expiresAt.difference(DateTime.now()).inSeconds;
      _remainingSeconds = remaining > 0 ? remaining : 300;
      
      final codeRemaining = session.codeExpiresAt != null
          ? session.codeExpiresAt!.difference(DateTime.now()).inSeconds
          : 120;
      _codeRemainingSeconds = codeRemaining > 0 ? codeRemaining : 120;

      _sessionId = session.sessionId;
      _shortCode = session.shortCode ?? 'A7X92K';
      _qrToken = session.qrToken ?? session.sessionId;

      if (!mounted) return;
      setState(() {
        _status = NfcShareStatus.active;
      });

      _startTimers();
      _startStatusPolling();

      // Start hardware NFC beam listening
      StartNfcSession().execute(
        onTagDiscovered: (id) async {
          if (!mounted || _status != NfcShareStatus.active) return;
          final token = await ShareMedicalHistory().execute(
            id,
            _shareFullHistory ? ['all'] : ['prescriptions', 'reports'],
          );
          if (mounted) {
            setState(() {
              _consentToken = token;
              _status = NfcShareStatus.shared;
            });
            _stopTimers();
          }
        },
        onError: (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('NFC Error: $err')));
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = NfcShareStatus.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize session: $e')),
      );
    }
  }

  void _startTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds <= 1) {
          timer.cancel();
          _remainingSeconds = 0;
          _status = NfcShareStatus.expired;
          _consentToken = null;
          _stopTimers();
        } else {
          _remainingSeconds--;
        }

        if (_codeRemainingSeconds > 0) {
          _codeRemainingSeconds--;
        }
      });
    });
  }

  void _startStatusPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _sessionId == null || _status != NfcShareStatus.active) {
        timer.cancel();
        return;
      }
      try {
        final statusData = await StartNfcSession().getSessionStatus(_sessionId!);
        if (statusData != null && mounted) {
          final serverStatus = statusData['status'] as String?;
          if (serverStatus == 'used') {
            timer.cancel();
            setState(() {
              _status = NfcShareStatus.shared;
              _consentToken = statusData['usedMethod'] as String? ?? 'verified';
            });
            _stopTimers();
          } else if (serverStatus == 'expired' || serverStatus == 'revoked') {
            timer.cancel();
            setState(() {
              _status = NfcShareStatus.expired;
            });
            _stopTimers();
          }
        }
      } catch (_) {}
    });
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _stopSession() async {
    final activeId = _sessionId;
    _stopTimers();
    if (activeId != null) {
      // Notify backend to mark session as revoked server-side
      await StartNfcSession().revokeSession(activeId);
    }
    if (mounted) {
      setState(() {
        _status = NfcShareStatus.idle;
        _consentToken = null;
        _sessionId = null;
        _shortCode = null;
        _qrToken = null;
        _remainingSeconds = 0;
        _codeRemainingSeconds = 0;
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatShortCode(String? code) {
    if (code == null || code.isEmpty) return '--- ---';
    final clean = code.replaceAll('-', '').toUpperCase();
    if (clean.length >= 6) {
      return '${clean.substring(0, 3)} - ${clean.substring(3, 6)}';
    }
    return code;
  }

  @override
  void dispose() {
    _stopTimers();
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _handleBack() async {
    if (_status == NfcShareStatus.active || _status == NfcShareStatus.starting) {
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel secure sharing?'),
          content: const Text('This will stop the active session and revoke QR, NFC, and short code access on the server.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Sharing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel Sharing'),
            ),
          ],
        ),
      );
      if (shouldCancel == true) {
        await _stopSession();
        return true;
      }
      return false;
    }
    if (_status == NfcShareStatus.shared || _status == NfcShareStatus.expired) {
      await _stopSession();
      return true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = context.read<NavigationProvider>();
        final canSwitchTab = await _handleBack();
        if (canSwitchTab && mounted) {
          nav.setIndex(0);
        }
      },
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_status == NfcShareStatus.idle) ...[
                    _buildIdleHeroBanner(),
                    const SizedBox(height: 20),
                    _buildModeSelector(),
                    const SizedBox(height: 24),
                    _buildActionButton(),
                    const SizedBox(height: 24),
                    _buildConsentCard(),
                    const SizedBox(height: 24),
                    _buildDisclaimer(),
                  ] else if (_status == NfcShareStatus.starting) ...[
                    _buildStartingView(),
                  ] else if (_status == NfcShareStatus.active) ...[
                    _buildTimerBanner(),
                    const SizedBox(height: 16),
                    _buildModeSwitcherBar(),
                    const SizedBox(height: 16),
                    _buildSingleActiveModeCard(),
                    const SizedBox(height: 20),
                    _buildActionButton(),
                    const SizedBox(height: 24),
                    _buildConsentCard(),
                    const SizedBox(height: 24),
                    _buildDisclaimer(),
                  ] else if (_status == NfcShareStatus.shared) ...[
                    _buildSuccessView(),
                    const SizedBox(height: 20),
                    _buildActionButton(),
                    const SizedBox(height: 24),
                    _buildDisclaimer(),
                  ] else if (_status == NfcShareStatus.expired) ...[
                    _buildExpiredView(),
                    const SizedBox(height: 20),
                    _buildActionButton(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const PageHeader(
      child: Row(
        children: [
          SizedBox(width: 48),
          Text(
            'Instant Medical Share',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  // --- 1. IDLE VIEW WIDGETS ---

  Widget _buildIdleHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.shieldCheck, size: 28, color: AppColors.teal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temporary ABDM Access',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select how you want to share your health records with the clinic.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'CHOOSE SHARING METHOD',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.textMuted,
            ),
          ),
        ),
        _buildModeOptionCard(
          mode: SharePresentationMode.qr,
          title: 'QR Code',
          subtitle: 'Doctor or staff scans directly from your screen',
          badgeText: 'Recommended',
          icon: LucideIcons.qrCode,
        ),
        const SizedBox(height: 12),
        _buildModeOptionCard(
          mode: SharePresentationMode.nfc,
          title: 'NFC Tap',
          subtitle: 'Touch phone near the clinic\'s smart reader',
          badgeText: 'Fastest',
          icon: LucideIcons.radio,
        ),
        const SizedBox(height: 12),
        _buildModeOptionCard(
          mode: SharePresentationMode.code,
          title: 'Short Code',
          subtitle: 'Read a temporary 6-character code aloud',
          badgeText: 'Fallback',
          icon: LucideIcons.keyRound,
        ),
      ],
    );
  }

  Widget _buildModeOptionCard({
    required SharePresentationMode mode,
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;

    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDFA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.teal : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF0F172A) : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.teal.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.teal : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.teal : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? AppColors.teal : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. STARTING VIEW ---

  Widget _buildStartingView() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLoader(size: 44),
          const SizedBox(height: 16),
          Text(
            'Connecting ABDM Vault...',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.teal),
          ),
          const SizedBox(height: 6),
          Text(
            'Generating 5-minute encrypted session...',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // --- 3. ACTIVE VIEW WIDGETS ---

  Widget _buildModeSwitcherBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildSwitcherItem(SharePresentationMode.qr, 'QR Code', LucideIcons.qrCode),
          _buildSwitcherItem(SharePresentationMode.nfc, 'NFC Tap', LucideIcons.radio),
          _buildSwitcherItem(SharePresentationMode.code, 'Short Code', LucideIcons.keyRound),
        ],
      ),
    );
  }

  Widget _buildSwitcherItem(SharePresentationMode mode, String label, IconData icon) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_selectedMode != mode) {
            setState(() => _selectedMode = mode);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.teal : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0F172A) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleActiveModeCard() {
    switch (_selectedMode) {
      case SharePresentationMode.qr:
        return _buildQrActiveBlock();
      case SharePresentationMode.nfc:
        return _buildNfcActiveBlock();
      case SharePresentationMode.code:
        return _buildShortCodeActiveBlock();
    }
  }

  Widget _buildQrActiveBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.scanLine, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                'Show QR to Doctor or Staff',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: QrImageView(
              data: _qrToken ?? _sessionId ?? 'Arogyam-Consent-Session',
              version: QrVersions.auto,
              size: 200,
              gapless: true,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Keep this screen open while the clinic scanner reads your code.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNfcActiveBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildAnimatedRipple(80),
                _buildAnimatedRipple(120),
                _buildAnimatedRipple(160),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: const Icon(LucideIcons.radio, size: 40, color: AppColors.teal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ready to Tap NFC Reader',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.teal),
          ),
          const SizedBox(height: 8),
          Text(
            'Hold the back of your phone within 4 cm of the clinic\'s NFC smart reader to share records.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildShortCodeActiveBlock() {
    final isCodeExpired = _codeRemainingSeconds <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.keyRound, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                'Read Short Code Aloud',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: isCodeExpired ? const Color(0xFFF1F5F9) : const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCodeExpired ? const Color(0xFFCBD5E1) : AppColors.teal.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'TEMPORARY VERIFICATION CODE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isCodeExpired ? AppColors.textMuted : AppColors.teal,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatShortCode(_shortCode),
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 5,
                    color: isCodeExpired ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                    decoration: isCodeExpired ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 10),
                if (!isCodeExpired)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.timer, size: 14, color: Color(0xFFEA580C)),
                      const SizedBox(width: 5),
                      Text(
                        'Code valid for ${_formatDuration(_codeRemainingSeconds)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.info, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 5),
                      Text(
                        'Code expired — QR and NFC still active',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Doctor can enter this code in the Arogyam clinic portal to request instant consent.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // --- 4. SUCCESS & EXPIRED VIEWS ---

  Widget _buildSuccessView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.checkCircle, size: 54, color: Colors.green),
          const SizedBox(height: 12),
          Text(
            'Consent Shared Successfully!',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 6),
          Text(
            'The clinic has securely received your temporary records.${_consentToken != null ? ' (Method: $_consentToken)' : ''}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildTimerBanner(),
        ],
      ),
    );
  }

  Widget _buildExpiredView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.alertCircle, size: 54, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            'Session Expired / Revoked',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
          const SizedBox(height: 6),
          Text(
            'Session ended for your privacy. Start a new session whenever you are ready.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBanner() {
    final isWarning = _remainingSeconds <= 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFEE2E2) : const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isWarning ? Colors.redAccent : const Color(0xFFEA580C)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock, size: 14, color: isWarning ? Colors.redAccent : const Color(0xFFEA580C)),
          const SizedBox(width: 6),
          Text(
            _status == NfcShareStatus.shared
                ? 'Access active for: ${_formatDuration(_remainingSeconds)}'
                : 'Session active: ${_formatDuration(_remainingSeconds)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.redAccent : const Color(0xFFEA580C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_status == NfcShareStatus.idle) {
      String buttonLabel;
      IconData buttonIcon;
      switch (_selectedMode) {
        case SharePresentationMode.qr:
          buttonLabel = 'Show QR Code';
          buttonIcon = LucideIcons.qrCode;
          break;
        case SharePresentationMode.nfc:
          buttonLabel = 'Start NFC Tap';
          buttonIcon = LucideIcons.radio;
          break;
        case SharePresentationMode.code:
          buttonLabel = 'Generate Short Code';
          buttonIcon = LucideIcons.keyRound;
          break;
      }

      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _startSession,
          icon: Icon(buttonIcon, size: 18, color: Colors.white),
          label: Text(
            buttonLabel,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (_status == NfcShareStatus.active) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: _stopSession,
          icon: const Icon(LucideIcons.squareX, size: 18, color: Colors.redAccent),
          label: Text(
            'End Session / Revoke Access',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.redAccent),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (_status == NfcShareStatus.shared) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _stopSession,
          icon: const Icon(LucideIcons.check, size: 18, color: Colors.white),
          label: Text(
            'Done / Start New Session',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (_status == NfcShareStatus.expired) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _startSession,
          icon: const Icon(LucideIcons.refreshCw, size: 18, color: Colors.white),
          label: Text(
            'Start New Session',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildConsentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Consent Scope', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildConsentToggle('Share full medical history', _shareFullHistory, (v) => setState(() => _shareFullHistory = v)),
          const Divider(height: 24),
          _buildConsentToggle('Selected records only', _selectedRecordsOnly, (v) => setState(() => _selectedRecordsOnly = v)),
        ],
      ),
    );
  }

  Widget _buildConsentToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        Switch.adaptive(value: value, activeTrackColor: AppColors.teal, onChanged: onChanged),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Text(
      'Protected under ABDM framework. Consent self-destructs after use, expiry, or when revoked.',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
    );
  }

  Widget _buildAnimatedRipple(double size) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: size * _animationController.value,
          height: size * _animationController.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.teal.withValues(alpha: (1 - _animationController.value) * 0.3),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}


