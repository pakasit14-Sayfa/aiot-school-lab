// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// STK-1: ผูกบัญชีผู้ปกครองกับนักเรียน (แบบ B ไม่มี self-signup) — ต้องมี
// Binding Code/QR จากโรงเรียนก่อนเสมอ ตามด้วยยืนยันอีเมลด้วย OTP แล้วจบที่
// สถานะ "รออนุมัติ" เท่านั้น (BR5: ก่อนอนุมัติ ผู้ปกครองยังเห็นข้อมูลบุตร
// ไม่ได้) — ต่อไปที่ STK-1a (สิทธิ์ครู/admin อนุมัติ ไม่ใช่หน้าฝั่งนี้)

import 'dart:async';
import 'package:flutter/material.dart';

import 'parent_shared_widgets.dart';

const _validDemoCode = 'SCH-AIOT-2026';

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
  String? _codeError;
  String? _otpError;
  int _otpAttempts = 0;
  Timer? _otpTimer;
  int _otpSecondsLeft = 600;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  void _submitCode() {
    // Exception Flow 1: รหัสผิด → ตอบกลางๆ ไม่เจาะจงว่าผิดตรงไหน กัน brute
    // force เดาข้อมูลเด็ก
    if (_codeCtrl.text.trim().toUpperCase() != _validDemoCode) {
      setState(
        () => _codeError =
            'รหัสไม่ถูกต้อง กรุณาตรวจสอบอีกครั้งหรือติดต่อโรงเรียน',
      );
      return;
    }
    setState(() {
      _codeError = null;
      _step = 1;
    });
  }

  void _sendOtp() {
    setState(() {
      _step = 2;
      _otpSecondsLeft = 600;
      _otpAttempts = 0;
      _otpError = null;
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
  }

  void _verifyOtp() {
    if (_otpSecondsLeft <= 0) {
      setState(() => _otpError = 'OTP หมดอายุแล้ว กรุณาขอรหัสใหม่');
      return;
    }
    // mock: รหัสถูกต้องคือ 111111 เท่านั้น
    if (_otpCtrl.text.trim() != '111111') {
      _otpAttempts += 1;
      if (_otpAttempts >= 5) {
        _otpTimer?.cancel();
        setState(() {
          _otpError =
              'กรอกผิดครบ 5 ครั้งแล้ว OTP ชุดนี้ถูกยกเลิก กรุณาขอรหัสใหม่';
          _otpSecondsLeft = 0;
        });
        return;
      }
      setState(
        () => _otpError =
            'รหัส OTP ไม่ถูกต้อง (ลองผิดแล้ว $_otpAttempts/5 ครั้ง)',
      );
      return;
    }
    _otpTimer?.cancel();
    setState(() {
      _otpError = null;
      _step = 3;
    });
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
          2 => _buildOtpStep(),
          _ => _buildConfirmStep(),
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
              labelText: 'Binding Code',
              hintText: 'เช่น SCH-AIOT-2026',
              errorText: _codeError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              // mock สแกน QR — เติมรหัสเดโมให้เลย
              _codeCtrl.text = _validDemoCode;
            },
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: const Text('สแกน QR Code แทน'),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _emailCtrl.text.trim().isEmpty ? null : _sendOtp,
              style: FilledButton.styleFrom(
                backgroundColor: ParentTheme.primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('ส่งรหัส OTP'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
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
          Text(
            'กรอกรหัส OTP 6 หลัก',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: ParentTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ส่งไปที่ ${_emailCtrl.text.trim()} แล้ว (เดโม: 111111)',
            style: const TextStyle(color: ParentTheme.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'รหัส OTP',
              errorText: _otpError,
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
              TextButton(onPressed: _sendOtp, child: const Text('ขอรหัสใหม่')),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: expired ? null : _verifyOtp,
              style: FilledButton.styleFrom(
                backgroundColor: ParentTheme.primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('ยืนยัน'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      children: [
        ParentGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ตรวจสอบข้อมูลก่อนยืนยัน',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: ParentTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                // BR3: QR/Code ห้ามฝัง PII — ระบบจึงปิดบังข้อมูลบางส่วนไว้
                // ให้ผู้ปกครองยืนยันเองว่าใช่บุตรจริงก่อนส่งคำขอ
                'ระบบปิดบังข้อมูลบางส่วนไว้เพื่อความปลอดภัย โปรดตรวจสอบว่าถูกต้อง',
                style: TextStyle(color: ParentTheme.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ParentTheme.lightTealBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ParentTheme.tealBorder),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ด.ช. ปุ**  ใจ**',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: ParentTheme.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ม.5/2 · โรงเรียนสาธิต AIoT',
                      style: TextStyle(
                        color: ParentTheme.softText,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => setState(() => _step = 4),
            style: FilledButton.styleFrom(
              backgroundColor: ParentTheme.primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('ใช่ นี่คือบุตรของฉัน — ส่งคำขอผูกบัญชี'),
          ),
        ),
        if (_step == 4) ...[const SizedBox(height: 20), _buildPendingStatus()],
      ],
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
