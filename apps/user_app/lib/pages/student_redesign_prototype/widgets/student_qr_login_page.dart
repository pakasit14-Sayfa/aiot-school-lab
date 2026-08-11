import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'student_redesign_palette.dart';

enum _QrMode { display, scan }

/// Combined "connect a device via QR" page — one screen with a segmented
/// toggle between showing a scannable QR (for another device to scan) and
/// opening the camera to scan one (previously two separate pages). Merged
/// per explicit request: same feature from the user's point of view, just
/// two roles, so it shouldn't feel like two different places in the app.
///
/// UI-only: the QR is real and scans with a real camera, but nothing
/// actually pairs the two devices or signs anyone in yet — that needs a
/// real backend pairing-session flow (briefed separately).
class StudentQrLoginPage extends StatefulWidget {
  const StudentQrLoginPage({super.key, this.startInScanMode = false});

  /// Opens straight into the camera-scan tab instead of the default
  /// "show QR" tab — used by the mobile drawer's "สแกน QR" entry so it
  /// doesn't force an extra tap to switch modes.
  final bool startInScanMode;

  @override
  State<StudentQrLoginPage> createState() => _StudentQrLoginPageState();
}

class _StudentQrLoginPageState extends State<StudentQrLoginPage> {
  static const _validDuration = Duration(minutes: 2);

  late _QrMode _mode;

  // --- Display-mode state ---
  late String _pairingToken;
  late DateTime _expiresAt;
  Duration _remaining = _validDuration;
  Timer? _tickTimer;

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
        _handled = false;
        _startScanMode();
      }
    });
  }

  void _startDisplayMode() {
    _generateToken();
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _expiresAt.difference(DateTime.now());
      if (left.isNegative) {
        _generateToken();
      } else {
        setState(() => _remaining = left);
      }
    });
  }

  void _startScanMode() {
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  void _generateToken() {
    final random = Random.secure();
    final code = List.generate(
      24,
      (_) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[random.nextInt(36)],
    ).join();
    setState(() {
      _pairingToken = 'aiot-school-pairing:$code';
      _expiresAt = DateTime.now().add(_validDuration);
      _remaining = _validDuration;
    });
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
    _showResultSheet(value);
  }

  Future<void> _showResultSheet(String value) async {
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
                  decoration: const BoxDecoration(
                    color: SchoolPalette.softGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: SchoolPalette.deepGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'สแกน QR สำเร็จ',
                  style: TextStyle(
                    color: SchoolPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'พร้อมเข้าสู่ระบบบนอุปกรณ์ที่แสดงรหัสนี้\n(${value.length > 40 ? '${value.substring(0, 40)}…' : value})',
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
        // Align(topCenter) not Center() — Center() vertically centers the
        // whole scroll view when content is shorter than the viewport,
        // making the page look like it "shrinks to the middle" instead of
        // staying pinned to the top.
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
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          segment('แสดง QR', Icons.qr_code_2_rounded, _QrMode.display),
          segment('สแกน QR', Icons.qr_code_scanner_rounded, _QrMode.scan),
        ],
      ),
    );
  }

  Widget _buildDisplayBody() {
    return Column(
      children: [
        const Text(
          'เปิดแอปนี้บนอุปกรณ์ใหม่ แล้วสแกน QR นี้',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'ไปที่แท็บ "สแกน QR" บนอุปกรณ์ที่ต้องการเพิ่ม แล้วส่องกล้องมาที่นี่',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SchoolPalette.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        SoftCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: QrImageView(
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
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: SchoolPalette.softGreenBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: SchoolPalette.deepGreen,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'หมดอายุใน $_remainingLabel นาที',
                      style: const TextStyle(
                        color: SchoolPalette.deepGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: _generateToken,
          icon: const Icon(
            Icons.refresh_rounded,
            size: 18,
            color: SchoolPalette.muted,
          ),
          label: const Text(
            'สร้าง QR ใหม่',
            style: TextStyle(
              color: SchoolPalette.muted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildDisclaimer(
          '🧪 QR สแกนได้จริง แต่ยังไม่เชื่อมระบบเข้าสู่ระบบจริง',
        ),
      ],
    );
  }

  Widget _buildScanBody() {
    final controller = _scannerController;
    if (controller == null) return const SizedBox.shrink();
    return Column(
      children: [
        const Text(
          'วางกล้องให้ตรงกับ QR ที่แสดงบนหน้าจออุปกรณ์ที่ต้องการเข้าสู่ระบบ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SchoolPalette.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 380,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                  placeholderBuilder: (context, child) => const ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: SchoolPalette.mint,
                      ),
                    ),
                  ),
                  errorBuilder: (context, error, child) =>
                      _buildCameraError(error),
                ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SchoolPalette.mint, width: 3),
                      ),
                    ),
                  ),
                ),
                if (!kIsWeb)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.black38,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          _torchOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () async {
                          await controller.toggleTorch();
                          setState(() => _torchOn = !_torchOn);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildDisclaimer(
          '🧪 ตัวอย่างหน้าตาเท่านั้น ยังไม่เชื่อมระบบเข้าสู่ระบบจริง',
        ),
      ],
    );
  }

  Widget _buildCameraError(MobileScannerException error) {
    final isPermissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_rounded,
                color: Colors.white70,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                isPermissionDenied
                    ? 'ไม่ได้รับสิทธิ์เข้าถึงกล้อง'
                    : 'ไม่สามารถเปิดกล้องได้',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _scannerController?.start(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('ลองใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimer(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFD97706),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
