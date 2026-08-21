import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_core/shared_core.dart';

import 'student_redesign_palette.dart';

enum _QrMode { display, scan }

class StudentQrLoginPage extends StatefulWidget {
  const StudentQrLoginPage({super.key, this.startInScanMode = false});

  final bool startInScanMode;

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

  // --- Scan-mode state ---
  MobileScannerController? _scannerController;
  bool _handled = false;
  bool _torchOn = false;

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
    try {
      final session = await TerminalPairingService.createPairingSession(
        terminalName: 'Lab Tablet Kiosk',
      );
      if (mounted) {
        setState(() {
          _pairingToken = session.pairingCode;
          _expiresAt = session.expiresAt;
          _remaining = _expiresAt.difference(DateTime.now());
        });
      }
    } catch (_) {
      // Fallback local random token if offline
      final random = Random.secure();
      final code = List.generate(
        24,
        (_) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[random.nextInt(36)],
      ).join();
      if (mounted) {
        setState(() {
          _pairingToken = 'aiot-school-pairing:$code';
          _expiresAt = DateTime.now().add(_validDuration);
          _remaining = _validDuration;
        });
      }
    }
  }

  Future<void> _checkClaimStatus() async {
    if (_pairingToken.isEmpty) return;
    try {
      final statusResult =
          await TerminalPairingService.checkPairingStatus(_pairingToken);
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
    } catch (_) {}
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

  Future<void> _handleScannedCode(String code) async {
    if (AuthService.sessionToken != null) {
      // Authenticated student claiming terminal
      try {
        final result = await TerminalPairingService.claimPairingSession(code);
        if (mounted) {
          _showResultSheet(
            title: result.success ? 'จับคู่เครื่องสำเร็จ' : 'ไม่สามารถจับคู่ได้',
            message: result.success
                ? 'เข้าสู่ระบบบนเครื่องแล็บสำเร็จแล้วสำหรับ ${result.studentName}'
                : result.message,
            isSuccess: result.success,
          );
        }
      } catch (e) {
        if (mounted) {
          _showResultSheet(
            title: 'เกิดข้อผิดพลาด',
            message: '$e',
            isSuccess: false,
          );
        }
      }
    } else {
      // Mock / Preview Mode
      _showResultSheet(
        title: 'สแกน QR สำเร็จ',
        message:
            'พร้อมเข้าสู่ระบบบนอุปกรณ์ที่แสดงรหัสนี้\n(${code.length > 40 ? '${code.substring(0, 40)}…' : code})',
        isSuccess: true,
      );
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
              const Text(
                'หน้าจอแท็บเล็ตแล็บพร้อมจับคู่',
                style: TextStyle(
                  color: SchoolPalette.deepGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
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
                child: _pairingToken.isNotEmpty
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
              'บนเว็บเบราว์เซอร์ กรุณาจำลองการสแกนหรือสแกนผ่านแอปบนโทรศัพท์มือถือ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SchoolPalette.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'จำลองสแกนรหัสสำเร็จ',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () => _handleScannedCode(
                'aiot-pairing:SAMPLETESTPAIRINGCODE1234',
              ),
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
      ],
    );
  }
}
