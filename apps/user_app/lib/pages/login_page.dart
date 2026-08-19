import 'dart:async';
import 'package:flutter/material.dart';

import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
import '../widgets/custom_text_field.dart';
import '../utils/app_validators.dart';
import 'accept_invitation_page.dart';
import 'redeem_binding_code_page.dart';
import 'role_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isLoading = false;
  String? errorMessage;
  Timer? _errorTimer;

  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    emailController.addListener(_clearErrorOnType);
    passwordController.addListener(_clearErrorOnType);
  }

  void _clearErrorOnType() {
    if (errorMessage != null) {
      _errorTimer?.cancel();
      setState(() => errorMessage = null);
    }
  }

  void login() async {
    if (!formKey.currentState!.validate()) return;

    _errorTimer?.cancel();
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await AuthService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      UserModel? user = result.user;
      final challenge = result.challenge;
      if (challenge != null) {
        user = await Navigator.of(context).push<UserModel>(
          MaterialPageRoute(
            builder: (otpContext) => LoginOtpPage(
              challenge: challenge,
              onVerified: (verifiedUser) {
                Navigator.of(otpContext).pop(verifiedUser);
              },
            ),
          ),
        );
        if (!mounted) return;
      }

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ยินดีต้อนรับ ${user.name}'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleRouter()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _errorTimer?.cancel();
      setState(() {
        errorMessage = _formatAuthErrorMessage(e);
      });
      _errorTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && errorMessage != null) {
          setState(() => errorMessage = null);
        }
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatAuthErrorMessage(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('429') ||
        msg.contains('rate_limited') ||
        msg.contains('too many requests')) {
      return 'คุณพยายามเข้าสู่ระบบถี่เกินไป กรุณารอ 1-2 นาทีแล้วลองใหม่อีกครั้ง';
    }
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('wrong password')) {
      return 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง กรุณาตรวจสอบและลองใหม่อีกครั้ง';
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('timeout')) {
      return 'ไม่สามารถเชื่อมต่อเครือข่ายได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
    }
    return 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ กรุณาลองใหม่อีกครั้ง';
  }

  Widget _buildInlineErrorBanner() {
    if (errorMessage == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => errorMessage = null),
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFF991B1B),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/school_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Form Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Logo area with scale animation
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _floatingController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  0,
                                  10 * _floatingController.value,
                                ),
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_library_outlined,
                                size: 64,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'EDUSMART',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Card with slide-up and fade-in animation
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please enter your credentials to continue',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInlineErrorBanner(),

                              CustomTextField(
                                controller: emailController,
                                labelText: '',
                                hintText: 'Username',
                                prefixIcon: Icons.person_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: AppValidators.email,
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                controller: passwordController,
                                labelText: '',
                                hintText: 'Password',
                                prefixIcon: Icons.lock_outline,
                                obscureText: isPasswordHidden,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordHidden
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () =>
                                          isPasswordHidden = !isPasswordHidden,
                                    );
                                  },
                                ),
                                validator: AppValidators.password,
                              ),

                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/forgot-password',
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2E7D32),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shadowColor: const Color(
                                      0xFF2E7D32,
                                    ).withValues(alpha: 0.5),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: isLoading ? null : login,
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Accept Invitation Link
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AcceptInvitationPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'มีรหัสเชิญจากโรงเรียน? สร้างบัญชี',
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              // Redeem Parent Binding Code Link
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RedeemBindingCodePage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'ผู้ปกครอง: มีรหัสผูกบัญชีจากโรงเรียน?',
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),
                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: Colors.grey.shade300),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'or login with',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: Colors.grey.shade300),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Social Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.g_mobiledata,
                                      size: 32,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.apple,
                                      size: 32,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
}
