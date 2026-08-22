// เชื่อมกับ ParentBindingService จริงแล้ว (2026-08-16) — เดิม mock ล้วน
//
// STK-1: ผูกบัญชีผู้ปกครองกับนักเรียน (แบบ B ไม่มี self-signup) — ต้องมี
// Binding Code/QR จากโรงเรียนก่อนเสมอ ตามด้วยยืนยันอีเมลด้วย OTP แล้วจบที่
// สถานะ "รออนุมัติ" เท่านั้น (BR5: ก่อนอนุมัติ ผู้ปกครองยังเห็นข้อมูลบุตร
// ไม่ได้) — ต่อไปที่ STK-1a (สิทธิ์ครู/admin อนุมัติ ไม่ใช่หน้าฝั่งนี้)
//
// ⚠️ backend จริงต่างจาก mock เดิม 2 จุดสำคัญ:
// 1. RPC ตรวจรหัส+อีเมลพร้อมกันจุดเดียว (request-parent-binding-otp) ไม่มี
//    endpoint แยกไว้เช็คแค่รหัสอย่างเดียวก่อน — เพื่อกันการเดารหัส/สแกน
//    รายชื่อนักเรียน (BR3) จึงตอบข้อความเดียวกันเสมอไม่ว่ารหัส/อีเมลจะถูก
//    หรือผิด (anti-enumeration) — หน้านี้ยังคงแยกเป็น 2 หน้าจอเพื่อ UX แต่
//    ยิง API จริงตอนกรอกอีเมลเสร็จ (ไม่ใช่ตอนกรอกรหัสเสร็จแบบ mock เดิม)
// 2. confirm_parent_binding ไม่คืนข้อมูลนักเรียนกลับมาเลยแม้แต่ชื่อแบบปิดบัง
//    (คืนแค่ parent_link_id/status) และต้องกรอกข้อมูลผู้ปกครอง (ความ
//    สัมพันธ์/ชื่อ/รหัสผ่าน) มาพร้อม OTP ในคำขอเดียวกันเลย — ไม่ใช่แค่
//    "ยืนยัน OTP" เฉยๆ แล้วค่อยเห็นข้อมูลบุตรแบบปิดบังแบบที่ mock เดิมทำ
//    (หน้าจอ "ด.ช. ปุ** ใจ**" เดิมตัดออกเพราะไม่มีอะไรรองรับจริง)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'parent_shared_widgets.dart';

const _relationshipOptions = ['บิดา', 'มารดา', 'ผู้ปกครองตามกฎหมาย'];

class ParentBindingPage extends StatefulWidget {
  const ParentBindingPage({super.key});

  @override
  State<ParentBindingPage> createState() => _ParentBindingPageState();
}

class _ParentBindingPageState extends State<ParentBindingPage> {
  int _step = 0;
  final _codeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _relationship = _relationshipOptions.first;
  String? _codeError;
  String? _requestError;
  String? _confirmError;
  bool _requestingOtp = false;
  bool _confirming = false;
  String? _verificationToken;
  Timer? _otpTimer;
  int _otpSecondsLeft = 600;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _passwordCtrl.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  void _submitCode() {
    if (_codeCtrl.text.trim().isEmpty) {
      setState(() => _codeError = 'กรุณากรอกรหัสผูกบัญชี');
      return;
    }
    setState(() {
      _codeError = null;
      _step = 1;
    });
  }

  Future<void> _sendOtp() async {
    setState(() {
      _requestingOtp = true;
      _requestError = null;
    });
    try {
      final token = await ParentBindingService.requestParentBindingOtp(
        code: _codeCtrl.text,
        email: _emailCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _verificationToken = token;
        _requestingOtp = false;
        _step = 2;
        _otpSecondsLeft = 600;
        _confirmError = null;
      });
      _otpTimer?.cancel();
      _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_otpSecondsLeft <= 1) {
          timer.cancel();
          setState(() => _otpSecondsLeft = 0);
          return;
        }
        setState(() => _otpSecondsLeft -= 1);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _requestingOtp = false;
        // ระบบตอบข้อความเดียวกันเสมอ (BR3 anti-enumeration) ไม่บอกว่ารหัส
        // หรืออีเมลผิดจุดไหน — ข้อความนี้จึงเป็นข้อความกลางๆ ตั้งใจ
        _requestError =
            'ส่งคำขอไม่สำเร็จ กรุณาตรวจสอบรหัสและอีเมลอีกครั้ง หรือลองใหม่ภายหลัง';
      });
    }
  }

  Future<void> _confirm() async {
    if (_verificationToken == null) return;
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _confirmError = 'กรุณากรอกรหัส OTP ให้ครบ 6 หลัก');
      return;
    }
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty) {
      setState(() => _confirmError = 'กรุณากรอกชื่อ-นามสกุลของท่าน');
      return;
    }
    if (_passwordCtrl.text.trim().length < 8) {
      setState(() => _confirmError = 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
      return;
    }
    setState(() {
      _confirming = true;
      _confirmError = null;
    });
    try {
      await ParentBindingService.confirmParentBinding(
        verificationToken: _verificationToken!,
        otpCode: _otpCtrl.text,
        relationship: _relationship,
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
        password: _passwordCtrl.text,
      );
      _otpTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _step = 3;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _confirmError = e.toString().contains('too_many_attempts')
            ? 'กรอกผิดครบหลายครั้งแล้ว กรุณาขอรหัสใหม่'
            : 'รหัส OTP ไม่ถูกต้องหรือหมดอายุแล้ว กรุณาตรวจสอบอีกครั้ง';
      });
    }
  }

  String get _otpTimeLabel {
    final m = (_otpSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_otpSecondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ParentMockPageShell(
      title: 'ผูกบัญชีกับบุตร',
      builder: (context, isDesktop) {
        return switch (_step) {
          0 => _buildCodeStep(),
          1 => _buildEmailStep(),
          2 => _buildOtpAndProfileStep(),
          _ => _buildPendingStatus(),
        };
      },
    );
  }

  Widget _buildCodeStep() {
    return ParentGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.qr_code_2_rounded,
            size: 40,
            color: ParentTheme.primaryTeal,
          ),
          const SizedBox(height: 12),
          const Text(
            'กรอกรหัสผูกบัญชีจากโรงเรียน',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: ParentTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'รับรหัสนี้หรือ QR Code จากทางโรงเรียนเท่านั้น ระบบไม่รองรับการ'
            'สมัครบัญชีผู้ปกครองเอง',
            style: TextStyle(color: ParentTheme.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'รหัสผูกบัญชี (Binding Code)',
              hintText: 'เช่น SCH-AIOT-2026',
              errorText: _codeError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitCode,
              style: FilledButton.styleFrom(
                backgroundColor: ParentTheme.primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('ถัดไป'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return ParentGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 40,
            color: ParentTheme.primaryTeal,
          ),
          const SizedBox(height: 12),
          const Text(
            'ยืนยันตัวตนด้วยอีเมล',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: ParentTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ถ้ายังไม่เคยมีบัญชีในระบบ จะสร้างบัญชีให้อัตโนมัติหลังยืนยันอีเมลสำเร็จ',
            style: TextStyle(color: ParentTheme.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'อีเมล',
              hintText: 'parent@example.com',
              errorText: _requestError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _requestingOtp || _emailCtrl.text.trim().isEmpty
                  ? null
                  : _sendOtp,
              style: FilledButton.styleFrom(
                backgroundColor: ParentTheme.primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _requestingOtp
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('ส่งรหัส OTP'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpAndProfileStep() {
    final expired = _otpSecondsLeft <= 0;
    return ParentGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.password_rounded,
            size: 40,
            color: ParentTheme.primaryTeal,
          ),
          const SizedBox(height: 12),
          const Text(
            'กรอกรหัส OTP และข้อมูลผู้ปกครอง',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: ParentTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ส่งรหัส OTP ไปที่ ${_emailCtrl.text.trim()} แล้ว',
            style: const TextStyle(color: ParentTheme.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'รหัส OTP',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 14,
                color: expired ? ParentTheme.emergencyRed : ParentTheme.muted,
              ),
              const SizedBox(width: 4),
              Text(
                expired ? 'หมดเวลาแล้ว' : 'เหลือเวลา $_otpTimeLabel',
                style: TextStyle(
                  color: expired ? ParentTheme.emergencyRed : ParentTheme.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _requestingOtp ? null : _sendOtp,
                child: const Text('ขอรหัสใหม่'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 6),
          const Text(
            'ข้อมูลผู้ปกครอง (สำหรับสร้างบัญชี)',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: ParentTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _relationship,
            decoration: InputDecoration(
              labelText: 'ความสัมพันธ์กับนักเรียน',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _relationshipOptions
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _relationship = v!),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _firstNameCtrl,
            decoration: InputDecoration(
              labelText: 'ชื่อ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _lastNameCtrl,
            decoration: InputDecoration(
              labelText: 'นามสกุล',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'ตั้งรหัสผ่าน (อย่างน้อย 8 ตัวอักษร)',
              errorText: _confirmError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: expired || _confirming ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: ParentTheme.primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _confirming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('ยืนยันและส่งคำขอผูกบัญชี'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingStatus() {
    return ParentGlassCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ParentTheme.warningOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: ParentTheme.warningOrange,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'คำขอผูกบัญชีอยู่ระหว่างรออนุมัติ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: ParentTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ครูประจำชั้นหรือฝ่ายทะเบียนจะตรวจสอบและอนุมัติคำขอ — ระหว่างนี้'
            'ยังไม่สามารถดูข้อมูลของบุตรได้ จะแจ้งเตือนทันทีที่อนุมัติแล้ว',
            textAlign: TextAlign.center,
            style: TextStyle(color: ParentTheme.muted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
