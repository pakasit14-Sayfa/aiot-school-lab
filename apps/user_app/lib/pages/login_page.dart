import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
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

  /// กด Enter จากช่องอีเมลแล้วเด้งมาช่องรหัสผ่าน · กด Enter ที่ช่องรหัสผ่าน
  /// แล้วส่งฟอร์มเลย — เดิมกด Enter ไม่มีอะไรเกิดขึ้น ต้องเอื้อมไปกดปุ่ม
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  /// พื้นหลังไล่สีที่ค่อย ๆ เคลื่อน — หยุดสนิทเมื่อเครื่องตั้ง "ลดการ
  /// เคลื่อนไหว" (didChangeDependencies ด้านล่าง) ต่างจากโลโก้ลอยของเดิมที่
  /// วนไม่จบไม่ว่าผู้ใช้จะตั้งค่าอะไรไว้
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  /// เมาส์ขยับแล้วแสงพื้นหลังขยับตาม (เดสก์ท็อปเท่านั้น — บนจอสัมผัสไม่มี
  /// pointer ลอยอยู่แล้ว ค่าเลยคงที่ 0 ไม่มีอะไรกระตุก)
  Offset _pointer = Offset.zero;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_clearErrorOnType);
    passwordController.addListener(_clearErrorOnType);
    _emailFocus.addListener(_onFocusChanged);
    _passwordFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    if (reduce) {
      _ambient.stop();
      _ambient.value = 0.35;
    } else {
      _ambient.repeat(reverse: true);
    }
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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _ambient.dispose();
    super.dispose();
  }

  static const Color _brand = Color(0xFF2E7D32);
  static const Color _brandDark = Color(0xFF1B5E20);
  static const Color _accent = Color(0xFF14B8A6);

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'สวัสดีตอนเช้า';
    if (h < 17) return 'สวัสดีตอนบ่าย';
    return 'สวัสดีตอนเย็น';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0B3B25),
      body: MouseRegion(
        onHover: (event) {
          if (_reduceMotion) return;
          final s = MediaQuery.sizeOf(context);
          setState(() {
            _pointer = Offset(
              (event.position.dx / s.width - 0.5) * 2,
              (event.position.dy / s.height - 0.5) * 2,
            );
          });
        },
        child: Stack(
          children: [
            _ambientBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 40 : 20,
                    vertical: 28,
                  ),
                  child: isWide
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 420),
                                child: _staggered(0, _brandPanel(wide: true)),
                              ),
                            ),
                            const SizedBox(width: 56),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: _staggered(1, _glassCard()),
                            ),
                          ],
                        )
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _staggered(0, _brandPanel(wide: false)),
                              const SizedBox(height: 22),
                              _staggered(1, _glassCard()),
                              const SizedBox(height: 16),
                              _staggered(2, _helpFooter()),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            if (isWide)
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(child: _staggered(2, _helpFooter())),
              ),
          ],
        ),
      ),
    );
  }

  /// เข้าหน้าทีละชิ้นไล่กัน แทนที่จะโผล่พร้อมกันทั้งหน้า — เล่นครั้งเดียว
  /// ตอนเปิด ไม่วนซ้ำ
  Widget _staggered(int order, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: _reduceMotion ? 1 : 520),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) {
        final delayed = ((v * 1.6) - order * 0.3).clamp(0.0, 1.0);
        return Opacity(
          opacity: delayed,
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - delayed)),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  /// แสงสองก้อนลอยอยู่หลังกระจก ขยับช้ามากตามเวลา + ขยับตามเมาส์เล็กน้อย
  Widget _ambientBackground() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, _) {
        final t = _ambient.value;
        final px = _pointer.dx * 18;
        final py = _pointer.dy * 18;
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B3B25), Color(0xFF11543A), Color(0xFF0A2E20)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.16,
                child: Image.asset(
                  'assets/images/school_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              left: -120 + px + 60 * t,
              top: -80 + py + 40 * t,
              child: _glow(320, _accent.withValues(alpha: 0.42)),
            ),
            Positioned(
              right: -140 - px + 40 * (1 - t),
              bottom: -100 - py + 70 * (1 - t),
              child: _glow(380, const Color(0xFF84CC16).withValues(alpha: 0.30)),
            ),
          ],
        );
      },
    );
  }

  Widget _glow(double d, Color c) => IgnorePointer(
    child: Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
      ),
    ),
  );

  Widget _brandPanel({required bool wide}) {
    final logo = Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF34D399), _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.45),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_library_outlined,
        size: 40,
        color: Colors.white,
      ),
    );

    return Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        logo,
        const SizedBox(height: 16),
        const Text(
          'EDUSMART',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AIoT School Lab',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
        if (wide) ...[
          const SizedBox(height: 26),
          Text(
            'ห้องเรียน อุปกรณ์ IoT และข้อมูลนักเรียน\nรวมอยู่ในระบบเดียว',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _Chip(icon: Icons.sensors_rounded, label: 'เซนเซอร์เรียลไทม์'),
              _Chip(icon: Icons.shield_moon_outlined, label: 'ยืนยัน 2 ชั้น'),
              _Chip(icon: Icons.groups_2_outlined, label: '6 บทบาทผู้ใช้'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _glassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.93),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _greeting,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ใช้บัญชีที่โรงเรียนออกให้ สำหรับครู นักเรียน ผู้ปกครอง และผู้ดูแลระบบ',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildInlineErrorBanner(),
                  _field(
                    controller: emailController,
                    focusNode: _emailFocus,
                    label: 'อีเมล',
                    hint: 'you@school.ac.th',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    autofill: const [AutofillHints.username],
                    action: TextInputAction.next,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    validator: AppValidators.email,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: passwordController,
                    focusNode: _passwordFocus,
                    label: 'รหัสผ่าน',
                    hint: 'กรอกรหัสผ่าน',
                    icon: Icons.lock_outline_rounded,
                    obscure: isPasswordHidden,
                    autofill: const [AutofillHints.password],
                    action: TextInputAction.done,
                    onSubmitted: (_) => isLoading ? null : login(),
                    validator: AppValidators.password,
                    suffix: IconButton(
                      tooltip:
                          isPasswordHidden ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isPasswordHidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          key: ValueKey<bool>(isPasswordHidden),
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      onPressed: () => setState(
                        () => isPasswordHidden = !isPasswordHidden,
                      ),
                    ),
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
                  const SizedBox(height: 6),
                  _submitButton(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'ระบบจะส่งรหัสยืนยัน 6 หลักไปที่อีเมลของคุณ',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ช่องกรอกเรืองขอบตอนโฟกัส — ตอบสนองตอนผู้ใช้แตะ ไม่ใช่ขยับเอง
  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    List<String>? autofill,
    TextInputAction? action,
    void Function(String)? onSubmitted,
  }) {
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscure,
        autofillHints: autofill,
        textInputAction: action,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: focused ? Colors.white : const Color(0xFFF8FAFC),
          prefixIcon: Icon(
            icon,
            color: focused ? _accent : const Color(0xFF94A3B8),
          ),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.6),
          ),
        ),
      ),
    );
  }

  /// ปุ่มยุบลงเล็กน้อยตอนกด แล้วเปลี่ยนเป็นสถานะกำลังทำงาน
  Widget _submitButton() {
    return AnimatedScale(
      scale: isLoading ? 0.98 : 1,
      duration: const Duration(milliseconds: 160),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              colors: [_brandDark, _brand, _accent],
            ),
            boxShadow: [
              BoxShadow(
                color: _brand.withValues(alpha: isLoading ? 0.18 : 0.38),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: isLoading ? null : login,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isLoading
                  ? const Row(
                      key: ValueKey('busy'),
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
                  : const Row(
                      key: ValueKey('idle'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// ปุ่ม Google/Apple เดิมเป็นไอคอนเปล่าไม่มี onTap และทำงานไม่ได้อยู่แล้ว
  /// (ระบบไม่ได้ใช้ Supabase Auth — hard rule 1) ตรงนี้เหลือเฉพาะทางเข้าจริง
  Widget _helpFooter() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ยังไม่มีบัญชี?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
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
                MaterialPageRoute(
                  builder: (_) => const RedeemBindingCodePage(),
                ),
              ),
            ),
          ],
        ),
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
      icon: Icon(icon, size: 17, color: Colors.white.withValues(alpha: 0.9)),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(46),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}
