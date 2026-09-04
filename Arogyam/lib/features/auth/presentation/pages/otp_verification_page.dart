import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/router/role_redirect.dart';
import '../../../../app/theme/app_colors.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  const OtpVerificationPage({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _timerSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupFocusNodes();
  }

  void _setupFocusNodes() {
    for (int i = 0; i < 6; i++) {
      final index = i;
      _focusNodes[index].onKeyEvent = (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controllers[index].text.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
            _controllers[index - 1].clear();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerSeconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _verifyOTP();
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _controllers.map((c) => c.text).join();
    final response = await context.read<AuthProvider>().verifyOTP(otp);

    if (response != null && mounted) {
      if (response.status == 'success' && response.user != null) {
        RoleRedirect.redirect(context, response.user!);
      } else if (response.status == 'new_user') {
        Navigator.pushReplacementNamed(context, RouteNames.signup);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Phone',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to ${widget.phoneNumber}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) => _onOtpChanged(index, value),
                    ),
                  );
                }),
              ),
              if (authProvider.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  authProvider.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Text(
                      _timerSeconds > 0 ? 'Resend in ${_timerSeconds}s' : "Didn't receive code?",
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (_timerSeconds == 0)
                      TextButton(
                        onPressed: () {
                          context.read<AuthProvider>().sendOTP(widget.phoneNumber, onCodeSent: (_) {});
                          _startTimer();
                        },
                        child: const Text('Resend OTP', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
