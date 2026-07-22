import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/login_otp_challenge.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

typedef LoginOtpVerifier =
    Future<UserModel> Function({
      required String otpToken,
      required String otpCode,
    });

class LoginOtpPage extends StatefulWidget {
  const LoginOtpPage({
    super.key,
    required this.challenge,
    required this.onVerified,
    this.verifyOtp,
  });

  final LoginOtpChallenge challenge;
  final ValueChanged<UserModel> onVerified;
  final LoginOtpVerifier? verifyOtp;

  @override
  State<LoginOtpPage> createState() => _LoginOtpPageState();
}

class _LoginOtpPageState extends State<LoginOtpPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _errorText = 'กรุณากรอกรหัสตัวเลข 6 หลัก');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final verifier = widget.verifyOtp ?? AuthService.verifyLoginOtp;
      final user = await verifier(
        otpToken: widget.challenge.token,
        otpCode: code,
      );
      if (!mounted) return;
      widget.onVerified(user);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'รหัสไม่ถูกต้อง หมดอายุ หรือถูกใช้แล้ว';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expiresAt = widget.challenge.expiresAt.toLocal();
    final expiresText =
        '${expiresAt.hour.toString().padLeft(2, '0')}:'
        '${expiresAt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันการเข้าสู่ระบบ')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.mark_email_read_outlined, size: 56),
                      const SizedBox(height: 16),
                      const Text(
                        'กรอกรหัส 6 หลักจากอีเมล',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'รหัสใช้ได้ครั้งเดียวและหมดอายุเวลา $expiresText น.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        key: const Key('login-otp-code'),
                        controller: _codeController,
                        autofocus: true,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onSubmitted: (_) => _isLoading ? null : _submit(),
                        decoration: InputDecoration(
                          labelText: 'รหัส OTP',
                          errorText: _errorText,
                          border: const OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('login-otp-submit'),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('ยืนยันและเข้าสู่ระบบ'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'หากไม่ได้พยายามเข้าสู่ระบบ กรุณากลับไปและแจ้งผู้ดูแลโรงเรียน',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
