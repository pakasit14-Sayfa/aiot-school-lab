import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/app_palette.dart';

class SuperAdminDeviceTestPage extends StatefulWidget {
  const SuperAdminDeviceTestPage({super.key});

  @override
  State<SuperAdminDeviceTestPage> createState() =>
      _SuperAdminDeviceTestPageState();
}

typedef DeviceTestPage = SuperAdminDeviceTestPage;

class _SuperAdminDeviceTestPageState extends State<SuperAdminDeviceTestPage> {
  final SchoolAdminPlatformService _service = SchoolAdminPlatformService();

  bool _isLoading = true;
  String? _loadError;
  bool _isRunningTests = false;

  final List<DeviceControlSchoolRecord> _schools = [];
  final List<DeviceControlItemRecord> _devices = [];

  String? _selectedSchoolId;
  String? _selectedDeviceId;

  final List<_DiagnosticCheck> _checks = [
    _DiagnosticCheck(
      name: 'Supabase Database & Realtime API',
      target: 'Public Cloud Endpoint',
      status: _CheckStatus.idle,
      latencyMs: null,
      detail: 'ยังไม่ได้ทดสอบ (กด "เริ่มทดสอบระบบ" ด้านบนเพื่อวัดเวลาตอบสนองจริง)',
    ),
    _DiagnosticCheck(
      name: 'Session Token & Authentication RPC',
      target: 'Auth Service',
      status: _CheckStatus.idle,
      latencyMs: null,
      detail: 'ยังไม่ได้ทดสอบ (กด "เริ่มทดสอบระบบ" ด้านบนเพื่อวัดเวลาตอบสนองจริง)',
    ),
    _DiagnosticCheck(
      name: 'Telemetry & Ingestion Pipeline',
      target: 'Sensor Stream',
      status: _CheckStatus.idle,
      latencyMs: null,
      detail: 'ยังไม่ได้ทดสอบ (กด "เริ่มทดสอบระบบ" ด้านบนเพื่อวัดเวลาตอบสนองจริง)',
    ),
    _DiagnosticCheck(
      name: 'MQTT Gateway Direct Probe',
      target: 'Local Gateway / Edge Node',
      status: _CheckStatus.idle,
      latencyMs: null,
      detail: 'ยังไม่สามารถวัดได้ (ยังไม่มีการเชื่อมต่อกับ Local Gateway Hardware)',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDevicesAndSchools();
  }

  Future<void> _loadDevicesAndSchools({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final DeviceControlDataModel data = await _service.fetchDeviceControlData();

      if (!mounted) return;

      setState(() {
        _schools
          ..clear()
          ..addAll(data.schools);

        _devices
          ..clear()
          ..addAll(data.devices);

        if (_schools.isNotEmpty && _selectedSchoolId == null) {
          _selectedSchoolId = _schools.first.databaseId;
        }

        if (_devices.isNotEmpty && _selectedDeviceId == null) {
          _selectedDeviceId = _devices.first.databaseId;
        }

        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  Future<void> _runAllTests() async {
    setState(() => _isRunningTests = true);

    // 1. Check 0: Measure real execution time of fetchDeviceControlData
    final sw0 = Stopwatch()..start();
    try {
      final data = await _service.fetchDeviceControlData();
      sw0.stop();
      _checks[0].status = _CheckStatus.passed;
      _checks[0].latencyMs = sw0.elapsedMilliseconds;
      _checks[0].detail =
          'เชื่อมต่อฐานข้อมูลหลักสำเร็จ (ดึงข้อมูล ${data.devices.length} เครื่อง, ${data.schools.length} โรงเรียน)';
    } catch (e) {
      sw0.stop();
      _checks[0].status = _CheckStatus.failed;
      _checks[0].latencyMs = sw0.elapsedMilliseconds;
      _checks[0].detail = 'เชื่อมต่อฐานข้อมูลล้มเหลว: $e';
    }

    // 2. Check 1: Measure real execution time of session auth RPC
    final sw1 = Stopwatch()..start();
    try {
      await _service.fetchAuditLogs(limit: 1);
      sw1.stop();
      _checks[1].status = _CheckStatus.passed;
      _checks[1].latencyMs = sw1.elapsedMilliseconds;
      _checks[1].detail = 'เซสชัน Super Admin ได้รับการยืนยันสิทธิ์สำเร็จ';
    } catch (e) {
      sw1.stop();
      _checks[1].status = _CheckStatus.failed;
      _checks[1].latencyMs = sw1.elapsedMilliseconds;
      _checks[1].detail = 'การยืนยันสิทธิ์ล้มเหลว: $e';
    }

    // 3. Check 2: Measure telemetry & sensor alert pipeline
    final sw2 = Stopwatch()..start();
    try {
      final alerts = await IncidentService.listSchoolAlerts();
      sw2.stop();
      _checks[2].status = _CheckStatus.passed;
      _checks[2].latencyMs = sw2.elapsedMilliseconds;
      _checks[2].detail = alerts.isEmpty
          ? 'ท่อส่งข้อมูลพร้อมใช้งาน (ไม่พบการแจ้งเตือนตกค้าง)'
          : 'ท่อส่งข้อมูลพร้อมใช้งาน (พบ ${alerts.length} การแจ้งเตือนในระบบ)';
    } catch (e) {
      sw2.stop();
      _checks[2].status = _CheckStatus.failed;
      _checks[2].latencyMs = sw2.elapsedMilliseconds;
      _checks[2].detail = 'ไม่สามารถตรวจสอบท่อส่งข้อมูลได้: $e';
    }

    // 4. Check 3: Honest unmeasured hardware check
    _checks[3].status = _CheckStatus.idle;
    _checks[3].latencyMs = null;
    _checks[3].detail = 'ยังไม่สามารถวัดได้ (ยังไม่มีการเชื่อมต่อกับ Local Gateway Hardware)';

    if (mounted) {
      setState(() {
        _isRunningTests = false;
      });
      _message('ทดสอบและจับเวลาการเชื่อมต่อจริงเรียบร้อยแล้ว');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text(
          'ทดสอบอุปกรณ์และระบบ (Device Diagnostics)',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'รีเฟรชข้อมูล',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadDevicesAndSchools(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _schools.isEmpty && _loadError == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => _loadDevicesAndSchools(showLoading: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _buildTierBDisclosureBanner(),
          const SizedBox(height: 16),
          if (_loadError != null && _schools.isEmpty) ...[
            _buildErrorNotice(),
            const SizedBox(height: 16),
          ],
          _buildHeroCard(),
          const SizedBox(height: 18),
          _buildDeviceSelectionPanel(),
          const SizedBox(height: 18),
          _buildDiagnosticResultsPanel(),
        ],
      ),
    );
  }

  Widget _buildErrorNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.carnivalRed.withAlpha(20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.carnivalRed.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppPalette.carnivalRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ไม่สามารถโหลดข้อมูลอุปกรณ์จากฐานข้อมูลได้ (${_loadError ?? "Offline"})',
              style: const TextStyle(
                fontSize: 12,
                color: AppPalette.carnivalRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            onPressed: () => _loadDevicesAndSchools(),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBDisclosureBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECDCA)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFD92D20), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'หมายเหตุ: ระบบทดสอบฮาร์ดแวร์จริงยังอยู่ระหว่างการพัฒนา การทดสอบนี้เป็นการตรวจสอบความพร้อมของ API และสถานะระบบส่วนกลาง',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFFB42318),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppPalette.deepBlue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge('เครื่องมือตรวจวินิจฉัยระบบ', AppPalette.circusYellow),
              _badge('Diagnostic Tools', Colors.white.withAlpha(50)),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'ตรวจสอบสถานะการเชื่อมต่อและความพร้อมของอุปกรณ์',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ทดสอบความเร็วในการตอบสนอง (Latency) การส่งสัญญาณเซนเซอร์ และสถานะเครือข่าย',
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isRunningTests ? null : _runAllTests,
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.circusYellow,
              foregroundColor: AppPalette.textPrimary,
            ),
            icon: _isRunningTests
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(
              _isRunningTests ? 'กำลังทดสอบ...' : 'เริ่มทดสอบระบบทั้งหมด',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSelectionPanel() {
    return _panel(
      title: 'เลือกอุปกรณ์ที่ต้องการทดสอบ',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedSchoolId,
            decoration: const InputDecoration(
              labelText: 'โรงเรียน',
              prefixIcon: Icon(Icons.apartment_rounded),
            ),
            items: _schools
                .map(
                  (s) => DropdownMenuItem<String>(
                    value: s.databaseId,
                    child: Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedSchoolId = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedDeviceId,
            decoration: const InputDecoration(
              labelText: 'อุปกรณ์',
              prefixIcon: Icon(Icons.memory_rounded),
            ),
            items: _devices
                .map(
                  (d) => DropdownMenuItem<String>(
                    value: d.databaseId,
                    child: Text(
                      '${d.name} (${d.deviceCode})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedDeviceId = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticResultsPanel() {
    return _panel(
      title: 'ผลการตรวจวินิจฉัยระบบ (Diagnostic Checks)',
      trailing: TextButton.icon(
        onPressed: _isRunningTests ? null : _runAllTests,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('ทดสอบใหม่'),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _checks.length; i++) ...[
            _diagnosticRow(_checks[i]),
            if (i < _checks.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _diagnosticRow(_DiagnosticCheck check) {
    Color color;
    IconData icon;

    switch (check.status) {
      case _CheckStatus.passed:
        color = AppPalette.gardenGreen;
        icon = Icons.check_circle_rounded;
        break;
      case _CheckStatus.warning:
        color = AppPalette.circusYellow;
        icon = Icons.warning_amber_rounded;
        break;
      case _CheckStatus.failed:
        color = AppPalette.carnivalRed;
        icon = Icons.cancel_rounded;
        break;
      case _CheckStatus.idle:
        color = AppPalette.textSecondary;
        icon = Icons.hourglass_empty_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withAlpha(25),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        check.name,
                        style: const TextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (check.latencyMs != null)
                      Text(
                        '${check.latencyMs} ms',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    else if (check.status == _CheckStatus.idle)
                      const Text(
                        'ยังไม่วัด',
                        style: TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  check.detail,
                  style: const TextStyle(
                    color: AppPalette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  Widget _panel({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: _shadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  List<BoxShadow> get _shadow => [
        BoxShadow(
          color: Colors.black.withAlpha(12),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
}

enum _CheckStatus { passed, warning, failed, idle }

class _DiagnosticCheck {
  final String name;
  final String target;
  _CheckStatus status;
  int? latencyMs;
  String detail;

  _DiagnosticCheck({
    required this.name,
    required this.target,
    required this.status,
    required this.latencyMs,
    required this.detail,
  });
}
