import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/school_admin_palette.dart';

class SchoolScanPage extends StatefulWidget {
  const SchoolScanPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<SchoolScanPage> createState() => _SchoolScanPageState();
}

class _SchoolScanPageState extends State<SchoolScanPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
    ],
  );

  bool _torchOn = false;
  bool _cameraStarted = true;
  String? _lastCode;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;

    final String? value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty || value == _lastCode) return;

    setState(() {
      _lastCode = value;
    });

    _showScanResult(value);
  }

  Future<void> _showScanResult(String value) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: SchoolAdminPalette.primarySoft,
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        color: SchoolAdminPalette.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'พบข้อมูลจาก QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SchoolAdminPalette.border),
                      ),
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: SchoolAdminPalette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: value),
                              );
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                              _showMessage('คัดลอกข้อมูลแล้ว');
                            },
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('คัดลอก'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _showMessage('เปิดข้อมูลอุปกรณ์จาก $value');
                            },
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('เปิดข้อมูล'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (mounted) {
      setState(() {
        _lastCode = null;
      });
    }
  }

  Future<void> _toggleTorch() async {
    await _scannerController.toggleTorch();
    if (!mounted) return;

    setState(() {
      _torchOn = !_torchOn;
    });
  }

  Future<void> _switchCamera() async {
    await _scannerController.switchCamera();
  }

  Future<void> _enterCodeManually() async {
    final TextEditingController controller = TextEditingController();

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('กรอกรหัส'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'QR Code / Barcode / รหัสอุปกรณ์',
              prefixIcon: Icon(Icons.keyboard_rounded),
            ),
            onSubmitted: (String value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                final String value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              child: const Text('ค้นหา'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result != null && mounted) {
      _showScanResult(result);
    }
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ประวัติการสแกนล่าสุด',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    _ScanHistoryRow(
                      code: 'DEV-PM-0004',
                      detail: 'SPS30 • ห้อง B-101',
                      time: 'วันนี้ 10:30 น.',
                    ),
                    SizedBox(height: 8),
                    _ScanHistoryRow(
                      code: 'KIT-LAB1-01',
                      detail: 'ชุดฝึก AIoT • LAB-01',
                      time: 'วันนี้ 09:55 น.',
                    ),
                    SizedBox(height: 8),
                    _ScanHistoryRow(
                      code: 'DEV-AIR-0002',
                      detail: 'ENS160 • LAB-01',
                      time: 'เมื่อวาน 16:20 น.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool mobile = constraints.maxWidth < 700;

            return Container(
              color: const Color(0xFFFBF7F1),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  mobile ? 14 : 22,
                  12,
                  mobile ? 14 : 22,
                  110,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        _buildTopBar(),
                        SizedBox(height: mobile ? 28 : 34),
                        const Text(
                          'สแกน QR Code',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF18354A),
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'วาง QR Code หรือ Barcode ให้อยู่ภายในกรอบ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF71808E),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildScannerCard(mobile),
                        const SizedBox(height: 18),
                        _buildQuickActions(),
                        const SizedBox(height: 18),
                        const _ScanTipCard(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _RoundActionButton(
          icon: Icons.arrow_back_rounded,
          backgroundColor: const Color(0xFFF3EBDD),
          iconColor: const Color(0xFF27465C),
          onTap: () {
            if (widget.onBack != null) {
              widget.onBack!();
              return;
            }

            final NavigatorState navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            }
          },
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สแกนข้อมูล',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF18354A),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'AIoT Smart Lab',
                style: TextStyle(fontSize: 10, color: Color(0xFF71808E)),
              ),
            ],
          ),
        ),
        _RoundActionButton(
          icon: Icons.history_rounded,
          backgroundColor: const Color(0xFFEAF4FB),
          iconColor: const Color(0xFF1769AA),
          onTap: _showHistory,
        ),
      ],
    );
  }

  Widget _buildScannerCard(bool mobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: AspectRatio(
        aspectRatio: mobile ? 0.96 : 1.18,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: const Color(0xFF070D11)),
              if (_cameraStarted)
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleDetect,
                  errorBuilder:
                      (
                        BuildContext context,
                        MobileScannerException error,
                        Widget? child,
                      ) {
                        return _CameraUnavailable(
                          onRetry: () {
                            setState(() {
                              _cameraStarted = false;
                            });
                            Future<void>.delayed(
                              const Duration(milliseconds: 150),
                              () {
                                if (mounted) {
                                  setState(() {
                                    _cameraStarted = true;
                                  });
                                }
                              },
                            );
                          },
                        );
                      },
                )
              else
                const SizedBox.shrink(),
              const _ScannerDarkOverlay(),
              const _ScanCorners(),
              Positioned(
                left: 14,
                right: 14,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(170),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'ระบบกำลังค้นหารหัสอัตโนมัติ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: _ScanQuickAction(
                  icon: _torchOn
                      ? Icons.flashlight_on_rounded
                      : Icons.flashlight_off_rounded,
                  label: _torchOn ? 'ปิดไฟ' : 'เปิดไฟ',
                  onTap: _toggleTorch,
                ),
              ),
              Expanded(
                child: _ScanQuickAction(
                  icon: Icons.keyboard_rounded,
                  label: 'กรอกรหัส',
                  onTap: _enterCodeManually,
                ),
              ),
              Expanded(
                child: _ScanQuickAction(
                  icon: Icons.cameraswitch_rounded,
                  label: 'สลับกล้อง',
                  onTap: _switchCamera,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E171D),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF331C23),
            child: Icon(
              Icons.videocam_off_rounded,
              size: 42,
              color: Color(0xFFD53C46),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'ไม่สามารถเปิดกล้องได้',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'อนุญาตสิทธิ์กล้องให้แอป แล้วกลับมาเปิดหน้านี้อีกครั้ง',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF8B959B),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF52636D)),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('ลองอีกครั้ง'),
          ),
        ],
      ),
    );
  }
}

class _ScannerDarkOverlay extends StatelessWidget {
  const _ScannerDarkOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScannerOverlayPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 6),
      width: size.width * 0.68,
      height: size.height * 0.68,
    );

    final Path overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    final Paint paint = Paint()..color = Colors.black.withAlpha(105);

    canvas.drawPath(overlay, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanCorners extends StatelessWidget {
  const _ScanCorners();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.68,
          heightFactor: 0.68,
          child: CustomPaint(painter: _CornerPainter()),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFFFD400)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double length = 42;

    canvas.drawLine(const Offset(0, 0), const Offset(length, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, length), paint);

    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - length, 0),
      paint,
    );
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);

    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - length),
      paint,
    );

    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - length, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanQuickAction extends StatelessWidget {
  const _ScanQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFB7D4E8)),
              ),
              child: Icon(icon, color: const Color(0xFF1769AA), size: 25),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF28465A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanTipCard extends StatelessWidget {
  const _ScanTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFFFF3C9),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFF1974B6),
            ),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เคล็ดลับการสแกน',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF28465A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ถือโทรศัพท์ให้นิ่ง เว้นระยะจากรหัสประมาณ 15–25 ซม. '
                  'และเปิดไฟเมื่อบริเวณมืด',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: Color(0xFF71808E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}

class _ScanHistoryRow extends StatelessWidget {
  const _ScanHistoryRow({
    required this.code,
    required this.detail,
    required this.time,
  });

  final String code;
  final String detail;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: SchoolAdminPalette.primarySoft,
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 18,
              color: SchoolAdminPalette.primaryDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 8.5,
              color: SchoolAdminPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
