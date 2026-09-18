import 'dart:async';
import 'package:flutter/material.dart';

import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
import '../utils/app_validators.dart';
import 'accept_invitation_page.dart';
import 'redeem_binding_code_page.dart';
import 'student_redesign_prototype/widgets/student_qr_login_page.dart';
import 'role_router.dart';
import '../utils/greeting.dart';

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

  // โทนใหม่ทั้งหมด — คราม (indigo) บนพื้นสว่าง ตรงกับหน้ากรอก OTP ที่เป็น
  // หน้าถัดไปทันที (`login_otp_page.dart` ใช้ #4F46E5/#6366F1) ของเดิมเป็น
  // เขียวเข้ม กดเข้าสู่ระบบแล้วสีกระโดดไปม่วงคนละโทนกลางทางล็อกอิน
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);
  static const Color _indigo = Color(0xFF4F46E5);
  static const Color _indigoLight = Color(0xFF6366F1);
  static const Color _sky = Color(0xFF38BDF8);

  String get _greeting => greetingForHour(DateTime.now().hour);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 940;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            _canvas(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 48 : 20,
                    vertical: 32,
                  ),
                  child: isWide
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 460),
                                child: _staggered(0, _hero()),
                              ),
                            ),
                            const SizedBox(width: 64),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Column(
                                children: [
                                  _staggered(1, _card()),
                                  const SizedBox(height: 14),
                                  _staggered(2, _helpFooter()),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _staggered(0, _wordmark(compact: true)),
                              const SizedBox(height: 20),
                              _staggered(1, _card()),
                              const SizedBox(height: 14),
                              _staggered(2, _helpFooter()),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _staggered(int order, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: _reduceMotion ? 1 : 520),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) {
        final d = ((v * 1.6) - order * 0.28).clamp(0.0, 1.0);
        return Opacity(
          opacity: d,
          child: Transform.translate(offset: Offset(0, 26 * (1 - d)), child: c),
        );
      },
      child: child,
    );
  }

  /// พื้นสว่าง + ตารางจุดจาง ๆ + ก้อนสีครามเบลอ 2 ก้อนที่ขยับช้าและขยับตาม
  /// เมาส์ — ไม่ใช้ภาพถ่ายโรงเรียนเป็นพื้นหลังแล้ว (นั่นคือสิ่งที่บังคับให้
  /// ทั้งหน้าต้องเป็นโทนเขียว)
  Widget _canvas() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, _) {
        final t = _ambient.value;
        final px = _pointer.dx * 26;
        final py = _pointer.dy * 26;
        return Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFDFDFF), Color(0xFFEEF2FF)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _DotGridPainter()),
            ),
            Positioned(
              left: -140 + px + 50 * t,
              top: -120 + py + 30 * t,
              child: _blob(360, _indigoLight.withValues(alpha: 0.26)),
            ),
            Positioned(
              right: -160 - px + 40 * (1 - t),
              bottom: -140 - py + 60 * (1 - t),
              child: _blob(420, _sky.withValues(alpha: 0.22)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double d, Color c) => IgnorePointer(
    child: Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
      ),
    ),
  );

  Widget _logoMark({double size = 52}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: const LinearGradient(
          colors: [_indigoLight, _indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _indigo.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.school_rounded,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }

  Widget _wordmark({required bool compact}) {
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        _logoMark(size: compact ? 48 : 56),
        SizedBox(height: compact ? 12 : 20),
        const Text(
          'EDUSMART',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.5,
            color: _ink,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'AIoT School Lab',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
      ],
    );
  }

  Widget _hero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _wordmark(compact: false),
        const SizedBox(height: 28),
        const Text(
          'ห้องเรียน อุปกรณ์ IoT\nและข้อมูลนักเรียน',
          style: TextStyle(
            fontSize: 38,
            height: 1.2,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_indigo, _sky],
          ).createShader(r),
          child: const Text(
            'รวมอยู่ในระบบเดียว',
            style: TextStyle(
              fontSize: 38,
              height: 1.2,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 26),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _HeroPoint(
              icon: Icons.sensors_rounded,
              title: 'เซนเซอร์เรียลไทม์',
              subtitle: 'ฝุ่น อุณหภูมิ ไฟฟ้า น้ำ จากอุปกรณ์จริงในโรงเรียน',
            ),
            SizedBox(height: 14),
            _HeroPoint(
              icon: Icons.verified_user_outlined,
              title: 'ยืนยันตัวตน 2 ชั้น',
              subtitle: 'รหัสผ่านและรหัส 6 หลักทางอีเมลทุกครั้งที่เข้าระบบ',
            ),
            SizedBox(height: 14),
            _HeroPoint(
              icon: Icons.groups_2_outlined,
              title: 'ครบ 6 บทบาท',
              subtitle: 'ผู้ดูแลระบบ โรงเรียน ผู้บริหาร ครู นักเรียน ผู้ปกครอง',
            ),
          ],
        ),
      ],
    );
  }

  Widget _card() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.07),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // ขอบบนไล่สี — ตัวเดียวกับปุ่มยืนยันในหน้ากรอก OTP
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_indigoLight, _sky]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
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
                              color: _indigo,
                              letterSpacing: 0.4,
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
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'ใช้บัญชีที่โรงเรียนออกให้ สำหรับครู นักเรียน ผู้ปกครอง และผู้ดูแลระบบ',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildInlineErrorBanner(),
                      _field(
                        controller: emailController,
                        focusNode: _emailFocus,
                        label: 'อีเมล',
                        hint: 'you@school.ac.th',
                        icon: Icons.alternate_email_rounded,
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
                        icon: Icons.key_rounded,
                        obscure: isPasswordHidden,
                        autofill: const [AutofillHints.password],
                        action: TextInputAction.done,
                        onSubmitted: (_) => isLoading ? null : login(),
                        validator: AppValidators.password,
                        suffix: IconButton(
                          tooltip: isPasswordHidden
                              ? 'แสดงรหัสผ่าน'
                              : 'ซ่อนรหัสผ่าน',
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              isPasswordHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              key: ValueKey<bool>(isPasswordHidden),
                              color: _muted,
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
                            foregroundColor: _indigo,
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
                      const SizedBox(height: 14),
                      _qrLoginEntry(),
                      const SizedBox(height: 14),
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
          ],
        ),
      ),
    );
  }

  /// ทางเข้าที่ 2 ที่มีอยู่จริง — เดิมช่องนี้เป็นปุ่ม Google/Apple ที่กดไม่ได้
  ///
  /// การจับคู่เครื่องแล็บ (kiosk pairing) มีครบทั้ง backend และหน้าจออยู่แล้ว
  /// แต่เดิมเข้าถึงได้จากเมนูในเชลล์นักเรียน **หลังล็อกอินแล้ว** เท่านั้น ทั้งที่
  /// คนที่ต้องใช้คือคนที่ยังไม่ได้ล็อกอินและยืนอยู่หน้าแท็บเล็ตในแล็บ —
  /// `create_terminal_pairing_session`/`check_terminal_pairing_status` ไม่รับ
  /// `p_token` อยู่แล้ว คือออกแบบให้เครื่องที่ยังไม่ล็อกอินเรียกได้ตั้งแต่แรก
  Widget _qrLoginEntry() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: _line)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'หรือ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const Expanded(child: Divider(color: _line)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentQrLoginPage()),
            ),
            icon: const Icon(Icons.qr_code_2_rounded, size: 20),
            label: const Text(
              'เข้าสู่ระบบด้วย QR (เครื่องแล็บ)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _indigo,
              backgroundColor: const Color(0xFFF5F3FF),
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: Color(0xFFDDD6FE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'เครื่องจะแสดงรหัส QR ให้นักเรียนที่ล็อกอินแล้วสแกนเพื่อเปิดเครื่องนี้ให้',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            height: 1.4,
            color: Colors.grey.shade500,
          ),
        ),
      ],
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
                  color: _indigo.withValues(alpha: 0.16),
                  blurRadius: 18,
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
        style: const TextStyle(fontWeight: FontWeight.w600, color: _ink),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: focused ? Colors.white : const Color(0xFFF8FAFC),
          prefixIcon: Icon(icon, color: focused ? _indigo : _muted, size: 20),
          suffixIcon: suffix,
          labelStyle: const TextStyle(color: _muted),
          floatingLabelStyle: const TextStyle(
            color: _indigo,
            fontWeight: FontWeight.w700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _indigo, width: 1.6),
          ),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return AnimatedScale(
      scale: isLoading ? 0.98 : 1,
      duration: const Duration(milliseconds: 160),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [_indigoLight, _indigo]),
            boxShadow: [
              BoxShadow(
                color: _indigo.withValues(alpha: isLoading ? 0.16 : 0.34),
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
                borderRadius: BorderRadius.circular(14),
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

  Widget _helpFooter() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ยังไม่มีบัญชี?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _muted,
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
      icon: Icon(icon, size: 17, color: _indigo),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
      style: TextButton.styleFrom(
        foregroundColor: _ink,
        minimumSize: const Size.fromHeight(46),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

/// ตารางจุดจาง ๆ เป็นพื้นผิว แทนภาพถ่ายโรงเรียนที่บังคับให้ทั้งหน้าเป็นเขียว
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x14475569);
    const gap = 26.0;
    for (double y = 0; y < size.height; y += gap) {
      for (double x = 0; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroPoint extends StatelessWidget {
  const _HeroPoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: _LoginPageState._indigo),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _LoginPageState._ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: _LoginPageState._muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
