import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/app_palette.dart';
import 'widgets/dev_ui.dart';

/// Real device scanner for Super Admin — scans a device's QR code
/// (the same device_code encoded by SuperAdminDevicesPage) and looks it
/// up against the already-real device list, showing genuine device
/// info instead of a snackbar. Session-only scan history starts empty
/// (no seeded fake rows).
class SuperAdminScanPage extends StatefulWidget {
  const SuperAdminScanPage({
    super.key,
    this.embedded = false,
    this.loadDevices,
  });

  /// True when embedded in [SuperAdminNavigationShell]'s desktop sidebar
  /// layout — suppresses this page's own AppBar since the sidebar
  /// already shows which page is selected.
  final bool embedded;

  final Future<DeviceControlDataModel> Function()? loadDevices;

  @override
  State<SuperAdminScanPage> createState() => _SuperAdminScanPageState();
}

class _ScanHistoryEntry {
  final String code;
  final String detail;
  final DateTime time;

  const _ScanHistoryEntry({
    required this.code,
    required this.detail,
    required this.time,
  });
}

class _SuperAdminScanPageState extends State<SuperAdminScanPage> {
  final SchoolAdminPlatformService _service = SchoolAdminPlatformService();
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

  bool _isLoadingDevices = true;

  /// เดิม `catch (_)` แค่ปิดสถานะโหลด — รายการอุปกรณ์ที่โหลดพังจึงดูเหมือน
  /// "โรงเรียนนี้ยังไม่มีอุปกรณ์" ทำให้สแกน QR แล้วขึ้น "ไม่พบอุปกรณ์" ทั้งที่
  /// อุปกรณ์มีจริงแต่ระบบอ่านรายการไม่ได้
  bool _devicesFailed = false;
  List<DeviceControlItemRecord> _devices = [];
  final List<_ScanHistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    try {
      final data =
          await (widget.loadDevices ?? _service.fetchDeviceControlData)();
      if (!mounted) return;
      setState(() {
        _devices = data.devices;
        _devicesFailed = false;
        _isLoadingDevices = false;
      });
    } catch (e) {
      debugPrint('SuperAdminScanPage: fetchDeviceControlData failed: $e');
      if (mounted) {
        setState(() {
          _devicesFailed = true;
          _isLoadingDevices = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty || value == _lastCode) return;

    setState(() => _lastCode = value);
    _showScanResult(value);
  }

  DeviceControlItemRecord? _matchDevice(String value) {
    for (final d in _devices) {
      if (d.deviceCode == value || d.databaseId == value) return d;
    }
    return null;
  }

  Future<void> _showScanResult(String rawValue) async {
    final device = _matchDevice(rawValue);

    if (device != null) {
      _history.insert(
        0,
        _ScanHistoryEntry(
          code: device.deviceCode,
          detail: '${device.name} • ${device.schoolName}',
          time: DateTime.now(),
        ),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: device != null
                          ? AppPalette.gardenGreen.withAlpha(30)
                          : AppPalette.carnivalRed.withAlpha(30),
                      child: Icon(
                        device != null
                            ? Icons.check_circle_rounded
                            : Icons.help_outline_rounded,
                        color: device != null
                            ? AppPalette.gardenGreen
                            : AppPalette.carnivalRed,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      device != null ? 'พบอุปกรณ์ในระบบ' : 'ไม่พบอุปกรณ์นี้ในระบบ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (device != null) ...[
                      _deviceInfoRow('ชื่ออุปกรณ์', device.name),
                      _deviceInfoRow('โรงเรียน', device.schoolName),
                      _deviceInfoRow(
                        'ตำแหน่ง',
                        '${device.building} / ${device.room}',
                      ),
                      _deviceInfoRow(
                        'สถานะ',
                        device.online ? 'ออนไลน์' : 'ออฟไลน์',
                      ),
                    ] else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppPalette.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          rawValue,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.textPrimary,
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
                                ClipboardData(text: rawValue),
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
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text('สแกนต่อ'),
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

    if (mounted) setState(() => _lastCode = null);
  }

  Widget _deviceInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppPalette.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTorch() async {
    await _scannerController.toggleTorch();
    if (!mounted) return;
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _switchCamera() async {
    await _scannerController.switchCamera();
  }

  Future<void> _enterCodeManually() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('กรอกรหัสอุปกรณ์'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'รหัสอุปกรณ์ (device code)',
            prefixIcon: Icon(Icons.keyboard_rounded),
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.of(dialogContext).pop(v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) Navigator.of(dialogContext).pop(v);
            },
            child: const Text('ค้นหา'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && mounted) _showScanResult(result);
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ประวัติการสแกนในเซสชันนี้',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_history.isEmpty)
                      const Text(
                        'ยังไม่มีการสแกนในเซสชันนี้',
                        style: TextStyle(color: AppPalette.textSecondary),
                      )
                    else
                      ..._history.map(
                        (h) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppPalette.softBeige,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        h.code,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        h.detail,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          color: AppPalette.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${h.time.hour.toString().padLeft(2, '0')}:${h.time.minute.toString().padLeft(2, '0')} น.',
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    color: AppPalette.textSecondary,
                                  ),
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
        );
      },
    );
  }

  String get _myQrPayload {
    final user = currentUserModel;
    return jsonEncode({
      'app': 'aiot-school-lab',
      'version': 1,
      'type': 'user_card',
      'user_id': user?.uid ?? '',
      'display_name': user?.name ?? '',
      'role': user?.role.name ?? '',
      'school_id': user?.schoolId ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppPalette.background,
        appBar: widget.embedded
            ? AppBar(
                toolbarHeight: 0,
                automaticallyImplyLeading: false,
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'สแกน'),
                    Tab(text: 'QR ของฉัน'),
                  ],
                ),
              )
            : AppBar(
                title: const Text(
                  'สแกนอุปกรณ์ (Device Scan)',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                actions: [
                  IconButton(
                    tooltip: 'ประวัติการสแกน',
                    icon: const Icon(Icons.history_rounded),
                    onPressed: _showHistory,
                  ),
                ],
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'สแกน'),
                    Tab(text: 'QR ของฉัน'),
                  ],
                ),
              ),
        body: TabBarView(
          children: [
            _buildScanTab(),
            _buildMyQrTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 700;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(mobile ? 14 : 22, 16, mobile ? 14 : 22, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  if (_isLoadingDevices)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(),
                    )
                  else if (_devicesFailed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppPalette.carnivalRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'โหลดรายการอุปกรณ์ไม่สำเร็จ — ผลการสแกนอาจขึ้นว่า'
                              'ไม่พบอุปกรณ์ทั้งที่มีอยู่จริง',
                              style: TextStyle(
                                color: AppPalette.carnivalRed,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoadingDevices = true;
                                _devicesFailed = false;
                              });
                              _loadDevices();
                            },
                            child: const Text('ลองใหม่'),
                          ),
                        ],
                      ),
                    ),
                  _buildScannerCard(mobile),
                  const SizedBox(height: 18),
                  AppPanel(
                    title: 'เครื่องมือด่วน',
                    child: Row(
                      children: [
                        Expanded(
                          child: _quickAction(
                            icon: _torchOn
                                ? Icons.flashlight_on_rounded
                                : Icons.flashlight_off_rounded,
                            label: _torchOn ? 'ปิดไฟ' : 'เปิดไฟ',
                            onTap: _toggleTorch,
                          ),
                        ),
                        Expanded(
                          child: _quickAction(
                            icon: Icons.keyboard_rounded,
                            label: 'กรอกรหัส',
                            onTap: _enterCodeManually,
                          ),
                        ),
                        Expanded(
                          child: _quickAction(
                            icon: Icons.cameraswitch_rounded,
                            label: 'สลับกล้อง',
                            onTap: _switchCamera,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
                color: AppPalette.blueSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppPalette.bluePrimary.withAlpha(80)),
              ),
              child: Icon(icon, color: AppPalette.bluePrimary, size: 25),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppPalette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerCard(bool mobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppPalette.cardShadow,
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
                  errorBuilder: (context, error, child) {
                    return Container(
                      color: const Color(0xFF0E171D),
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.videocam_off_rounded,
                            size: 42,
                            color: Color(0xFFD53C46),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'ไม่สามารถเปิดกล้องได้',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _cameraStarted = false);
                              Future<void>.delayed(
                                const Duration(milliseconds: 150),
                                () {
                                  if (mounted) {
                                    setState(() => _cameraStarted = true);
                                  }
                                },
                              );
                            },
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
                  },
                ),
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
                    'วาง QR Code หรือ Barcode ของอุปกรณ์ในกรอบ',
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

  Widget _buildMyQrTab() {
    final user = currentUserModel;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AppPanel(
            title: 'QR ประจำตัวของฉัน',
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppPalette.softBeige),
                  ),
                  child: QrImageView(
                    data: _myQrPayload,
                    version: QrVersions.auto,
                    size: 220,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                StatusBadge(
                  label: user?.role.name ?? '',
                  color: AppPalette.bluePrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
