import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shared_core/models/login_otp_challenge.dart';
import 'package:shared_core/models/user_model.dart';
import 'package:shared_core/services/auth_service.dart';

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
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (mounted) setState(() {});
  }

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

  void _autofillDevCode() {
    if (widget.challenge.devOtpCode != null) {
      _codeController.text = widget.challenge.devOtpCode!;
      setState(() {
        _errorText = null;
      });
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expiresAt = widget.challenge.expiresAt.toLocal();
    final expiresText =
        '${expiresAt.hour.toString().padLeft(2, '0')}:'
        '${expiresAt.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'ยืนยันการเข้าสู่ระบบ',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Color(0x0E0F172A),
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Security Gradient Badge Icon
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x334F46E5),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'กรอกรหัส 6 หลักจากอีเมล',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'รหัสใช้ได้ครั้งเดียวและหมดอายุเวลา $expiresText น.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Local Dev Mode Card with Autofill Action
                    if (widget.challenge.devOtpCode != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFFDE68A),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDE68A),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.code_rounded,
                                        size: 13,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'โหมดพัฒนา (local dev)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: _autofillDevCode,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.touch_app_rounded,
                                          size: 13,
                                          color: Color(0xFF92400E),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'กรอกอัตโนมัติ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF92400E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.challenge.devOtpCode!,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF92400E),
                                letterSpacing: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Visual 6-Digit PIN Boxes with underlying TextField
                    GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      behavior: HitTestBehavior.opaque,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 6 Digit Visual Boxes
                          Row(
                            children: List.generate(6, (index) {
                              final text = _codeController.text;
                              final char =
                                  index < text.length ? text[index] : '';
                              final isCurrent = _focusNode.hasFocus &&
                                  (index == text.length ||
                                      (index == 5 && text.length == 6));
                              final isFilled = char.isNotEmpty;

                              return Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: isFilled
                                        ? const Color(0xFFF8FAFC)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isCurrent
                                          ? const Color(0xFF4F46E5)
                                          : isFilled
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFFCBD5E1),
                                      width: isCurrent ? 2.0 : 1.2,
                                    ),
                                    boxShadow: isCurrent
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x284F46E5),
                                              blurRadius: 10,
                                              offset: Offset(0, 3),
                                            ),
                                          ]
                                        : const [
                                            BoxShadow(
                                              color: Color(0x040F172A),
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      char,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          // Real TextField (Transparent Overlay for typing, paste & testing)
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.0,
                              child: TextField(
                                key: const Key('login-otp-code'),
                                controller: _codeController,
                                focusNode: _focusNode,
                                autofocus: true,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                maxLength: 6,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) =>
                                    _isLoading ? null : _submit(),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Error Alert Box
                    if (_errorText != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit Button
                    FilledButton(
                      key: const Key('login-otp-submit'),
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'ยืนยันและเข้าสู่ระบบ',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),

                    // Back to Login Button
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      label: const Text(
                        'กลับไปยังหน้าเข้าสู่ระบบ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Security Footer Note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'หากไม่ได้พยายามเข้าสู่ระบบ กรุณากลับไปและแจ้งผู้ดูแลโรงเรียน',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
