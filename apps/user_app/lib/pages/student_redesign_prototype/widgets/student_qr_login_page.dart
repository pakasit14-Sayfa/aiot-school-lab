import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_core/shared_core.dart';

import 'student_redesign_palette.dart';

enum _QrMode { display, scan }

class StudentQrLoginPage extends StatefulWidget {
  const StudentQrLoginPage({
    super.key,
    this.startInScanMode = false,
    this.createSession,
    this.peekPairing,
    this.claimPairing,
    this.hasSession,
  });

  /// Scan-mode seams: peek/claim a scanned pairing code, and whether a
  /// signed-in session exists (production reads `AuthService.sessionToken`).
  final Future<TerminalPairingPeek> Function(String code)? peekPairing;
  final Future<({bool success, String studentName, String message})> Function(
    String code,
  )?
  claimPairing;
  final bool Function()? hasSession;

  final bool startInScanMode;

  /// Injectable seam, same pattern as the rest of this app. Production
  /// passes nothing and the real service is used; tests supply this to
  /// drive the success/failure paths deterministically.
  final Future<({String pairingCode, DateTime expiresAt})> Function({
    String? terminalName,
  })?
  createSession;

  @override
  State<StudentQrLoginPage> createState() => _StudentQrLoginPageState();
}

class _StudentQrLoginPageState extends State<StudentQrLoginPage> {
  static const _validDuration = Duration(minutes: 5);

  late _QrMode _mode;

  // --- Display-mode state ---
  String _pairingToken = '';
  DateTime _expiresAt = DateTime.now().add(_validDuration);
  Duration _remaining = _validDuration;
  Timer? _tickTimer;
  Timer? _pollTimer;
  bool _sessionFailed = false;

  /// checkPairingStatus ล้มติดต่อกัน — เดิม `catch (_) {}` ทำให้แท็บเล็ตที่
  /// เน็ตหลุดโชว์ QR ที่ดูปกติทุกอย่างแต่สแกนแล้วไม่มีวันเข้าได้
  bool _pollFailed = false;

  // --- Scan-mode state ---
  MobileScannerController? _scannerController;
  bool _handled = false;
  bool _torchOn = false;
  // Web has no camera scanner; the code printed under the QR on the lab
  // tablet is typed here instead (replaces the old "จำลองสแกนรหัสสำเร็จ"
  // button that fed a fixed sample code into the flow).
  final _manualCodeController = TextEditingController();

  bool get _signedIn =>
      (widget.hasSession ?? () => AuthService.sessionToken != null)();

  @override
  void initState() {
    super.initState();
    _mode = widget.startInScanMode ? _QrMode.scan : _QrMode.display;
    if (_mode == _QrMode.display) {
      _startDisplayMode();
    } else {
      _startScanMode();
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _pollTimer?.cancel();
    _scannerController?.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _switchMode(_QrMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      if (mode == _QrMode.display) {
        _scannerController?.dispose();
        _scannerController = null;
        _startDisplayMode();
      } else {
        _tickTimer?.cancel();
        _pollTimer?.cancel();
        _handled = false;
        _startScanMode();
      }
    });
  }

  void _startDisplayMode() {
    _initPairingSession();
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _expiresAt.difference(DateTime.now());
      if (left.isNegative) {
        _initPairingSession();
      } else {
        setState(() => _remaining = left);
      }
    });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkClaimStatus();
    });
  }

  Future<void> _initPairingSession() async {
    if (mounted) {
      setState(() {
        _pairingToken = '';
        _sessionFailed = false;
      });
    }
    try {
      final createSession =
          widget.createSession ?? TerminalPairingService.createPairingSession;
      final session = await createSession(
        terminalName: 'แท็บเล็ตประจำโต๊ะแล็บ AIoT',
      );
      if (mounted) {
        setState(() {
          _pairingToken = session.pairingCode;
          _expiresAt = session.expiresAt;
          _remaining = _expiresAt.difference(DateTime.now());
        });
      }
    } catch (e) {
      debugPrint('StudentQrLoginPage: failed to create pairing session: $e');
      // A QR code that looks real but can never be claimed is worse than an
      // honest error — the student would scan it and get stuck with no clue
      // why. Show a real failure state instead of a fabricated token.
      if (mounted) {
        setState(() => _sessionFailed = true);
      }
    }
  }

  Future<void> _checkClaimStatus() async {
    if (_pairingToken.isEmpty) return;
    try {
      final statusResult =
          await TerminalPairingService.checkPairingStatus(_pairingToken);
      if (mounted && _pollFailed) setState(() => _pollFailed = false);
      if (statusResult.isClaimed && mounted) {
        _pollTimer?.cancel();
        _tickTimer?.cancel();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ยืนยันตัวตนสำเร็จ! กำลังเข้าสู่ระบบสำหรับ ${statusResult.studentName}',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (statusResult.sessionToken != null) {
          await SessionTokenStorage().write(statusResult.sessionToken!);
          await AuthService.initialize();
        }

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
        }
      }
    } catch (e) {
      debugPrint('StudentQrLoginPage: ตรวจสถานะการจับคู่ไม่สำเร็จ — $e');
      if (mounted && !_pollFailed) setState(() => _pollFailed = true);
    }
  }

  void _startScanMode() {
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  String get _remainingLabel {
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;
    _handled = true;
    _handleScannedCode(value);
  }

  /// BR3: Scan -> Peek context -> Show confirmation sheet -> User taps confirm -> Claim
  Future<void> _handleScannedCode(String code) async {
    // There used to be an else-branch here for "no session" that showed a
    // fabricated valid device ("แท็บเล็ตประจำโต๊ะแล็บ AIoT #01") and then a
    // "เข้าสู่ระบบสำเร็จ (ตัวอย่าง)" sheet. Scan mode is only reachable from a
    // signed-in student shell, so that branch was dead — and if it ever ran
    // it lied. A missing session is now an error.
    if (!_signedIn) {
      _showResultSheet(
        title: 'ยังไม่ได้เข้าสู่ระบบ',
        message: 'เข้าสู่ระบบด้วยบัญชีนักเรียนก่อน แล้วจึงสแกนรหัสบนเครื่องแล็บ',
        isSuccess: false,
      );
      return;
    }
    try {
      final peek =
          await (widget.peekPairing ?? TerminalPairingService.peekPairingSession)(code);
      if (!mounted) return;

      if (!peek.isValid) {
        _showResultSheet(
          title: 'รหัสไม่ถูกต้องหรือหมดอายุ',
          message: 'กรุณาตรวจสอบว่ารหัส QR บนหน้าจอเครื่องแล็บยังไม่หมดอายุ',
          isSuccess: false,
        );
        return;
      }

      // Show Pre-Confirmation Sheet with Device Context (Anti-Relay)
      _showDeviceConfirmationSheet(code: code, peek: peek);
    } catch (e) {
      debugPrint('StudentQrLoginPage: peek failed — $e');
      if (mounted) {
        _showResultSheet(
          title: 'ตรวจสอบรหัสไม่สำเร็จ',
          message: 'เชื่อมต่อระบบไม่ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง',
          isSuccess: false,
        );
      }
    }
  }

  /// AUTH-5 BR3: Pre-Confirmation Sheet displaying device context before claiming
  Future<void> _showDeviceConfirmationSheet({
    required String code,
    required TerminalPairingPeek peek,
  }) async {
    final timeStr = peek.createdAt != null
        ? DateFormat('HH:mm:ss').format(peek.createdAt!)
        : DateFormat('HH:mm:ss').format(DateTime.now());

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x290F172A),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: SchoolPalette.softGreenBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.devices_rounded,
                        color: SchoolPalette.deepGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ยืนยันการเข้าสู่ระบบ',
                            style: TextStyle(
                              color: SchoolPalette.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ตรวจสอบบริบทอุปกรณ์ก่อนกดยืนยัน',
                            style: TextStyle(
                              color: SchoolPalette.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.laptop_chromebook_rounded,
                            size: 18,
                            color: SchoolPalette.deepGreen,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'อุปกรณ์เป้าหมาย:',
                            style: TextStyle(
                              color: SchoolPalette.muted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            peek.terminalName,
                            style: const TextStyle(
                              color: SchoolPalette.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: SchoolPalette.muted,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'เวลาที่ร้องขอ:',
                            style: TextStyle(
                              color: SchoolPalette.muted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              color: SchoolPalette.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Session นี้จะหมดอายุอัตโนมัติเมื่อหมดคาบเรียน (4 ชม.)',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          setState(() => _handled = false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('ยกเลิก'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('ยืนยันเข้าสู่ระบบ'),
                        style: FilledButton.styleFrom(
                          backgroundColor: SchoolPalette.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _executeClaim(code);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _executeClaim(String code) async {
    // The old else-branch ("เข้าสู่ระบบสำเร็จ (ตัวอย่าง)") reported success
    // without calling anything. Gone — see _handleScannedCode.
    if (!_signedIn) return;
    try {
      final result =
          await (widget.claimPairing ?? TerminalPairingService.claimPairingSession)(code);
      if (mounted) {
        _showResultSheet(
          title: result.success ? 'เข้าสู่ระบบสำเร็จ' : 'ไม่สามารถเข้าสู่ระบบได้',
          message: result.success
              ? 'เข้าสู่ระบบบนเครื่องแล็บสำเร็จแล้วสำหรับ ${result.studentName}'
              : result.message,
          isSuccess: result.success,
        );
      }
    } catch (e) {
      debugPrint('StudentQrLoginPage: claim failed — $e');
      if (mounted) {
        _showResultSheet(
          title: 'เกิดข้อผิดพลาด',
          message: e.toString().contains('forbidden')
              ? 'เฉพาะบัญชีนักเรียนเท่านั้นที่สามารถจับคู่เข้าสู่ระบบเครื่องแล็บได้'
              : 'เชื่อมต่อระบบไม่ได้ในขณะนี้ กรุณาลองใหม่อีกครั้ง',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _showResultSheet({
    required String title,
    required String message,
    required bool isSuccess,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x290F172A),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? SchoolPalette.softGreenBg
                        : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_rounded : Icons.close_rounded,
                    color: isSuccess
                        ? SchoolPalette.deepGreen
                        : const Color(0xFFEF4444),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: SchoolPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'เสร็จสิ้น',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    setState(() => _handled = false);
                  },
                  child: const Text(
                    'สแกนใหม่',
                    style: TextStyle(
                      color: SchoolPalette.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SchoolPalette.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'เข้าสู่ระบบด้วย QR',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  _buildSegmentedControl(),
                  const SizedBox(height: 22),
                  if (_mode == _QrMode.display)
                    _buildDisplayBody()
                  else
                    _buildScanBody(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    Widget segment(String label, IconData icon, _QrMode mode) {
      final selected = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => _switchMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? SchoolPalette.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : SchoolPalette.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : SchoolPalette.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SchoolPalette.softGreenBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SchoolPalette.glassBorder),
      ),
      child: Row(
        children: [
          segment('แสดง QR Code', Icons.qr_code_rounded, _QrMode.display),
          segment('สแกน QR Code', Icons.qr_code_scanner_rounded, _QrMode.scan),
        ],
      ),
    );
  }

  Widget _buildDisplayBody() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: SchoolPalette.softGreenBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: SchoolPalette.mint.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: SchoolPalette.deepGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: const Text(
                  'หน้าจอแท็บเล็ตแล็บพร้อมจับคู่',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SchoolPalette.deepGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'ใช้มือถือสแกนเพื่อเข้าสู่ระบบ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'เปิดแอปบนมือถือที่ล็อกอินแล้ว เลือกแท็บ "สแกน QR" เพื่อล็อกอินเข้าใช้งานบนเครื่องแล็บนี้',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SchoolPalette.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: SchoolPalette.glassBorder, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _sessionFailed
                    ? SizedBox(
                        width: 220,
                        height: 220,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 36,
                              color: SchoolPalette.muted,
                            ),
                            const SizedBox(height: 10),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'สร้างรหัส QR ไม่สำเร็จ\nกรุณาลองใหม่',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: SchoolPalette.muted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _initPairingSession,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('ลองใหม่'),
                            ),
                          ],
                        ),
                      )
                    : _pairingToken.isNotEmpty
                    ? QrImageView(
                        data: _pairingToken,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: SchoolPalette.ink,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: SchoolPalette.ink,
                        ),
                      )
                    : const SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: SchoolPalette.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'หมดอายุใน $_remainingLabel',
                    style: const TextStyle(
                      color: SchoolPalette.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (_pollFailed) ...[
                const SizedBox(height: 6),
                const Text(
                  'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ชั่วคราว — กำลังลองใหม่ทุก 3 วินาที',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: Color(0xFF64748B)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'รหัสจะรีเฟรชใหม่อัตโนมัติทุก 5 นาที เพื่อความปลอดภัย',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _initPairingSession,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('สร้างรหัส QR ใหม่'),
          style: OutlinedButton.styleFrom(
            foregroundColor: SchoolPalette.ink,
            side: const BorderSide(color: SchoolPalette.glassBorder),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  void _submitManualCode() {
    final code = _manualCodeController.text.trim();
    if (code.isEmpty) return;
    _handleScannedCode(code);
  }

  Widget _buildScanBody() {
    if (kIsWeb) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: SchoolPalette.softGreenBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SchoolPalette.glassBorder),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: SchoolPalette.muted,
            ),
            const SizedBox(height: 14),
            const Text(
              'กล้องสแกนสำหรับมือถือ',
              style: TextStyle(
                color: SchoolPalette.ink,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'บนเว็บเบราว์เซอร์ไม่มีกล้องสแกน — พิมพ์รหัสที่แสดงใต้ QR บนเครื่องแล็บ '
              'หรือสแกนผ่านแอปบนโทรศัพท์มือถือ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SchoolPalette.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualCodeController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'รหัสจับคู่จากเครื่องแล็บ',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submitManualCode(),
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'ตรวจสอบรหัส',
              icon: Icons.check_circle_outline_rounded,
              onPressed: _submitManualCode,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        const Text(
          'จัด QR Code ให้อยู่ในกรอบ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'สแกน QR Code ที่แสดงบนหน้าจอแท็บเล็ตแล็บเพื่อเข้าสู่ระบบ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SchoolPalette.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 320,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_scannerController != null)
                  MobileScanner(
                    controller: _scannerController!,
                    onDetect: _onDetect,
                  ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: SchoolPalette.mint.withValues(alpha: 0.8),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _scannerController?.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                    icon: Icon(
                      _torchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Camera-less fallback (broken camera, denied permission): the same
        // code is printed under the QR on the lab tablet.
        TextField(
          controller: _manualCodeController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            labelText: 'หรือพิมพ์รหัสจับคู่ที่แสดงใต้ QR',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitManualCode(),
        ),
        const SizedBox(height: 10),
        GradientButton(
          label: 'ตรวจสอบรหัส',
          icon: Icons.check_circle_outline_rounded,
          onPressed: _submitManualCode,
        ),
      ],
    );
  }
}
