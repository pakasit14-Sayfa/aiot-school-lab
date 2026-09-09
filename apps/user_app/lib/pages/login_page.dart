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

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isLoading = false;
  String? errorMessage;
  Timer? _errorTimer;

  /// กด Enter จากช่องอีเมลแล้วเด้งมาช่องรหัสผ่าน · กด Enter ที่ช่องรหัสผ่าน
  /// แล้วส่งฟอร์มเลย — เดิมกด Enter ไม่มีอะไรเกิดขึ้น ต้องเอื้อมไปกดปุ่ม
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
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
      final roleSelection = result.roleSelection;
      if (roleSelection != null) {
        user = await Navigator.of(context).push<UserModel>(
          MaterialPageRoute(
            builder: (roleContext) => RoleSelectionPage(
              challenge: roleSelection,
              onSelected: (selectedUser) {
                Navigator.of(roleContext).pop(selectedUser);
              },
            ),
          ),
        );
        if (!mounted) return;
      }

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
    _passwordFocus.dispose();
    super.dispose();
  }

  static const Color _brand = Color(0xFF2E7D32);
  static const Color _brandDark = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/school_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // ผ้าคลุมบาง ๆ ทับภาพพื้นหลัง — ภาพโรงเรียนมีทั้งส่วนสว่างจัดและ
          // ส่วนมืด ตัวหนังสือนอกการ์ด (ชื่อระบบ) เลยอ่านยากในบางจอ
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(0, 24 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _brandHeader(),
                        const SizedBox(height: 24),
                        _loginCard(),
                        const SizedBox(height: 20),
                        _helpFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _brand.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_library_outlined,
            size: 44,
            color: _brand,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'EDUSMART',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: _brandDark,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'AIoT School Lab',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }

  Widget _loginCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // เดิมหัวการ์ดเป็นอังกฤษ ("Welcome back / Please enter your
              // credentials") ทั้งที่ทั้งแอปเป็นไทย รวมถึงช่องกรอกและปุ่ม
              const Text(
                'เข้าสู่ระบบ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ใช้บัญชีที่โรงเรียนออกให้ สำหรับครู นักเรียน ผู้ปกครอง และผู้ดูแลระบบ',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 18),
              _buildInlineErrorBanner(),

              // เดิม labelText เป็นสตริงว่าง เหลือแต่ hint ซึ่งหายไปทันทีที่
              // เริ่มพิมพ์ — พอกรอกผิดช่องจะไม่มีอะไรบอกว่าช่องไหนคืออะไร
              CustomTextField(
                controller: emailController,
                labelText: 'อีเมล',
                hintText: 'you@school.ac.th',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                validator: AppValidators.email,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: passwordController,
                focusNode: _passwordFocus,
                labelText: 'รหัสผ่าน',
                hintText: 'กรอกรหัสผ่าน',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: isPasswordHidden,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => isLoading ? null : login(),
                suffixIcon: IconButton(
                  tooltip: isPasswordHidden ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                  icon: Icon(
                    isPasswordHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF6B7280),
                  ),
                  onPressed: () =>
                      setState(() => isPasswordHidden = !isPasswordHidden),
                ),
                validator: AppValidators.password,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  style: TextButton.styleFrom(
                    foregroundColor: _brand,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'ลืมรหัสผ่าน?',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _brand.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isLoading ? null : login,
                  // เดิมตอนโหลดเหลือแค่วงกลมหมุน ไม่บอกว่ากำลังทำอะไรอยู่
                  child: isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'กำลังเข้าสู่ระบบ…',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'ระบบจะส่งรหัสยืนยัน 6 หลักไปที่อีเมลของคุณหลังกดเข้าสู่ระบบ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// เดิม 2 ลิงก์นี้เป็น TextButton สีเขียวตัวหนาขนาดเท่าปุ่มหลัก วางต่อกัน
  /// ใต้ปุ่มเข้าสู่ระบบ แข่งความสนใจกันเองจนไม่รู้ว่าควรกดอันไหน — จัดเป็น
  /// กล่อง "ยังไม่มีบัญชี?" แยกออกมาจากการ์ดหลัก และลบปุ่ม Google/Apple ที่
  /// เป็นไอคอนเปล่า ไม่มี onTap และทำงานไม่ได้อยู่แล้วเพราะระบบนี้ไม่ได้ใช้
  /// Supabase Auth (ใช้ session token ของตัวเอง — hard rule 1 ใน CLAUDE.md)
  Widget _helpFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Text(
            'ยังไม่มีบัญชี?',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          _footerAction(
            icon: Icons.confirmation_number_outlined,
            label: 'มีรหัสเชิญจากโรงเรียน — สร้างบัญชี',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AcceptInvitationPage()),
            ),
          ),
          _footerAction(
            icon: Icons.family_restroom_rounded,
            label: 'ผู้ปกครอง — มีรหัสผูกบัญชีนักเรียน',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RedeemBindingCodePage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: _brand),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      style: TextButton.styleFrom(
        foregroundColor: _brandDark,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
