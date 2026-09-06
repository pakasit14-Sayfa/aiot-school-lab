import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

/// หน้า "จัดการอุปกรณ์ IoT & มิเตอร์" ของ School Admin
///
/// สิ่งที่ backend ให้ได้จริงกับ role `school_admin` มีแค่สองตัว และทั้งคู่รับ
/// `p_token` (ตรวจกับฐานข้อมูลที่รันอยู่ ไม่ใช่ไฟล์ migration):
///
///   * `list_school_devices(p_token text)` → คืนแค่ 5 คอลัมน์:
///     `id, name, type, location, status` เท่านั้น
///   * `list_school_admin_audit_logs(p_token text, p_limit int)`
///
/// ของเดิมในไฟล์นี้แต่งข้อมูลที่ RPC ไม่เคยคืนมาเลยขึ้นมาเองทั้งหมด:
/// `deviceCode` (`DEV-<TYPE>-<4 ตัวแรกของ uuid>`), `serialNumber`
/// (`SN-<hashCode>`), `ipAddress` (`192.168.1.<hashCode % 200 + 10>`),
/// `firmware: 'v2.4.1'`, `calibration: 'ปกติ (30 วัน)'`,
/// `installedDate: '15 พ.ค. 2568'`, `room: 'ห้องปฏิบัติการ'`,
/// `trainingKit: 'ชุดฝึก AIoT Lab'`, `batteryPercent: 100`,
/// `rssi: -58 / -95`, `lastSeen: 'เมื่อสักครู่' / '2 วันที่แล้ว'` และ
/// `building: 'ไม่ระบุอาคาร'` — ค่าพวกนี้ดูเหมือนค่าจริงทั้งหมดแต่ไม่มีอันไหน
/// มาจากฐานข้อมูล นอกจากนี้ยังมีบล็อก "Device Alerts" กับ
/// "Maintenance Schedule" ที่ hardcode ทั้งก้อน (อ้างอิงรหัสอุปกรณ์ที่ไม่มีอยู่
/// จริงอย่าง `DEV-SEN-0004`) และการ์ด System Health ที่ประกาศว่า Firmware
/// อัปเดตครบ 100% ทั้งที่ระบบไม่เคยเก็บเวอร์ชัน firmware มาแสดง
///
/// ปุ่มที่เคย "ทำงาน" ก็แก้แค่ state ในหน่วยความจำ: เพิ่ม/แก้ไขอุปกรณ์,
/// เปิด/ปิดอุปกรณ์, ทดสอบ Ping ("ตอบสนอง 12ms" เป็นข้อความคงที่), พิมพ์ QR,
/// ส่งออกไฟล์ — รีเฟรชหน้าแล้วหายหมด ตอนนี้ปิดการใช้งานพร้อมบอกเหตุผลแทน
///
/// - `register_device(p_token, ...)` มีอยู่จริงและ school_admin เรียกได้ แต่
///   ยังไม่มีเมธอดใน `packages/shared_core/lib/services/` และหน้าเพจห้ามเรียก
///   `supabase.rpc(...)` ตรง ๆ (hard rule 4) → ปุ่มเพิ่ม/แก้ไขจึงถูก disable
/// - `register_device_for_super_admin` เรียกไม่ได้: gate เป็น
///   `role != 'super_admin' → forbidden`
/// - `archive_school_device(p_device_id)` **ไม่มี `p_token`** = RPC ของ
///   `aiot_dev_dashboard` เรียกจากแอปนี้แล้ว actor เป็น null เงียบ ๆ
/// - การสั่งเปิด/ปิดจริงอยู่ที่หน้า "ควบคุมอุปกรณ์"
///   (`queue_device_command` + ยืนยันผ่าน `list_device_relay_states`)
///   หน้านี้เป็นทะเบียนอุปกรณ์อย่างเดียว ไม่ทำ mutation ซ้ำอีกเลน
class SchoolDevicesPage extends StatefulWidget {
  const SchoolDevicesPage({super.key, this.loadDevices, this.loadLogs});

  /// Seam สำหรับเทสต์ (แบบเดียวกับ `school_resources_page`) — production
  /// ไม่ส่งอะไรมาแล้วใช้ service จริง เทสต์ส่งเข้ามาเพื่อขับ
  /// loading / data / empty / error โดยไม่ต้องมี Supabase จริง
  final Future<List<DeviceOption>> Function()? loadDevices;
  final Future<List<SchoolAdminAuditLog>> Function()? loadLogs;

  @override
  State<SchoolDevicesPage> createState() => _SchoolDevicesPageState();
}

/// สถานะการโหลดของแต่ละส่วน แยก loading / data / empty / error ออกจากกัน
enum _LoadPhase { loading, data, error }

class _SchoolDevicesPageState extends State<SchoolDevicesPage> {
  final TextEditingController _searchController = TextEditingController();

  static const String _allCategories = 'ทุกประเภท';
  static const String _allLocations = 'ทุกจุดติดตั้ง';
  static const String _allStatuses = 'ทุกสถานะ';
  static const String _noData = 'ยังไม่มีข้อมูล';

  String _selectedCategory = _allCategories;
  String _selectedLocation = _allLocations;
  String _selectedStatus = _allStatuses;
  bool _filterIssuesOnly = false;

  _LoadPhase _devicesPhase = _LoadPhase.loading;
  String? _devicesError;
  List<DeviceOption> _devices = const [];

  _LoadPhase _logsPhase = _LoadPhase.loading;
  String? _logsError;
  List<SchoolAdminAuditLog> _logs = const [];

  Future<List<DeviceOption>> get _deviceLoader =>
      (widget.loadDevices ?? RealtimeService.listSchoolDevices)();

  Future<List<SchoolAdminAuditLog>> get _logLoader =>
      (widget.loadLogs ??
      () => SchoolAdminPlatformService().fetchAuditLogs(limit: 6))();

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _devicesPhase = _LoadPhase.loading;
      _devicesError = null;
    });
    try {
      final devices = await _deviceLoader;
      if (!mounted) return;
      setState(() {
        _devices = List<DeviceOption>.unmodifiable(devices);
        _devicesPhase = _LoadPhase.data;
        // ตัวเลือกในตัวกรองสร้างจากข้อมูลจริง ค่าที่เลือกค้างไว้แล้วหายไป
        // จากชุดข้อมูลใหม่ต้องรีเซ็ต ไม่งั้นตัวกรองจะกรองจนว่างโดยไม่มีเหตุผล
        if (!_categoryOptions.contains(_selectedCategory)) {
          _selectedCategory = _allCategories;
        }
        if (!_locationOptions.contains(_selectedLocation)) {
          _selectedLocation = _allLocations;
        }
        if (!_statusOptions.contains(_selectedStatus)) {
          _selectedStatus = _allStatuses;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        // ไม่แสดง `$e` ดิบบนจอ — ข้อความคงที่ + ปุ่มลองใหม่
        _devicesPhase = _LoadPhase.error;
        _devicesError = 'โหลดรายการอุปกรณ์ไม่สำเร็จ';
        _devices = const [];
      });
    }
  }

  Future<void> _loadLogs() async {
    setState(() {
      _logsPhase = _LoadPhase.loading;
      _logsError = null;
    });
    try {
      final logs = await _logLoader;
      if (!mounted) return;
      setState(() {
        _logs = List<SchoolAdminAuditLog>.unmodifiable(logs);
        _logsPhase = _LoadPhase.data;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _logsPhase = _LoadPhase.error;
        _logsError = 'โหลดประวัติการจัดการอุปกรณ์ไม่สำเร็จ';
        _logs = const [];
      });
    }
  }

  Future<void> _reloadAll() async {
    await Future.wait([_loadDevices(), _loadLogs()]);
  }

  // ---------------------------------------------------------------------
  // การแปลงค่าที่ backend คืนมาเป็นภาษาไทย — ไม่ใช่การเติมข้อมูลใหม่
  // ค่าที่ไม่รู้จักคืนค่าดิบกลับไป ไม่จับยัดหมวด "เซนเซอร์" แบบของเดิม
  // ---------------------------------------------------------------------

  /// ค่าใน enum `device_type` ของฐานข้อมูลจริง (11 ค่า)
  static const Map<String, String> _typeLabels = {
    'mini_pc': 'มินิพีซี',
    'aiot_gateway': 'เกตเวย์ AIoT',
    'pm25_sensor': 'เซนเซอร์ PM2.5',
    'air_quality_sensor': 'เซนเซอร์คุณภาพอากาศ',
    'light_sensor': 'เซนเซอร์แสง',
    'energy_meter': 'มิเตอร์ไฟฟ้า',
    'camera': 'กล้องวงจรปิด',
    'relay': 'รีเลย์ควบคุม',
    'emergency_button': 'ปุ่มฉุกเฉิน',
    'warning_light': 'ไฟเตือน',
    'water_meter': 'มิเตอร์น้ำ',
  };

  /// ค่าใน enum `device_status` ของฐานข้อมูลจริง (4 ค่า)
  static const Map<String, String> _statusLabels = {
    'online': 'ออนไลน์',
    'offline': 'ออฟไลน์',
    'error': 'ผิดปกติ',
    'maintenance': 'ซ่อมบำรุง',
  };

  static String _typeLabel(String type) =>
      _typeLabels[type.toLowerCase()] ?? (type.isEmpty ? _noData : type);

  static String _statusLabel(String status) =>
      _statusLabels[status.toLowerCase()] ??
      (status.isEmpty ? _noData : status);

  static IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'camera':
        return Icons.videocam_rounded;
      case 'energy_meter':
        return Icons.bolt_rounded;
      case 'water_meter':
        return Icons.water_drop_rounded;
      case 'aiot_gateway':
      case 'mini_pc':
        return Icons.router_rounded;
      case 'relay':
        return Icons.toggle_on_rounded;
      case 'emergency_button':
        return Icons.emergency_rounded;
      case 'warning_light':
        return Icons.lightbulb_rounded;
      default:
        return Icons.sensors_rounded;
    }
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return SchoolAdminPalette.green;
      case 'offline':
        return SchoolAdminPalette.red;
      case 'error':
        return SchoolAdminPalette.red;
      case 'maintenance':
        return SchoolAdminPalette.yellow;
      default:
        return SchoolAdminPalette.textMuted;
    }
  }

  static String _locationOf(DeviceOption device) {
    final value = device.location?.trim() ?? '';
    return value.isEmpty ? _noData : value;
  }

  // ---------------------------------------------------------------------
  // ตัวเลือกในตัวกรอง — สร้างจากข้อมูลที่ backend คืนมาจริงทุกตัว
  // ของเดิมเป็นรายการเขียนมือ 6 หมวดที่ไม่ตรงกับ enum จริงสักค่า
  // ---------------------------------------------------------------------

  List<String> get _categoryOptions {
    final set = _devices.map((d) => _typeLabel(d.type)).toSet().toList()
      ..sort();
    return [_allCategories, ...set];
  }

  List<String> get _locationOptions {
    final set = _devices.map(_locationOf).toSet().toList()..sort();
    return [_allLocations, ...set];
  }

  List<String> get _statusOptions {
    final set = _devices.map((d) => _statusLabel(d.status)).toSet().toList()
      ..sort();
    return [_allStatuses, ...set];
  }

  List<DeviceOption> get _filteredDevices {
    final keyword = _searchController.text.trim().toLowerCase();

    return _devices.where((device) {
      final matchesSearch =
          keyword.isEmpty ||
          device.name.toLowerCase().contains(keyword) ||
          device.type.toLowerCase().contains(keyword) ||
          _typeLabel(device.type).toLowerCase().contains(keyword) ||
          (device.location ?? '').toLowerCase().contains(keyword);

      final matchesCategory =
          _selectedCategory == _allCategories ||
          _typeLabel(device.type) == _selectedCategory;

      final matchesLocation =
          _selectedLocation == _allLocations ||
          _locationOf(device) == _selectedLocation;

      final bool matchesStatus;
      if (_filterIssuesOnly) {
        matchesStatus = device.status.toLowerCase() != 'online';
      } else {
        matchesStatus =
            _selectedStatus == _allStatuses ||
            _statusLabel(device.status) == _selectedStatus;
      }

      return matchesSearch &&
          matchesCategory &&
          matchesLocation &&
          matchesStatus;
    }).toList(growable: false);
  }

  int _countWithStatus(String status) =>
      _devices.where((d) => d.status.toLowerCase() == status).length;

  int get _onlineCount => _countWithStatus('online');
  int get _offlineCount => _countWithStatus('offline');
  int get _attentionCount =>
      _devices.where((d) {
        final s = d.status.toLowerCase();
        return s == 'error' || s == 'maintenance';
      }).length;

  /// อุปกรณ์ที่มี `location` จริงในฐานข้อมูล — ใช้แยก "มี 0 เครื่องที่ระบุ
  /// ตำแหน่ง" ออกจาก "ยังไม่มีอุปกรณ์เลย" (บทเรียนเดียวกับ energy page:
  /// เลข 0 ที่มีตัวหารเป็น 0 ไม่ใช่ผลการวัด)
  int get _locatedCount =>
      _devices.where((d) => (d.location ?? '').trim().isNotEmpty).length;

  bool get _hasFilters =>
      _selectedCategory != _allCategories ||
      _selectedLocation != _allLocations ||
      _selectedStatus != _allStatuses ||
      _filterIssuesOnly ||
      _searchController.text.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = _allCategories;
      _selectedLocation = _allLocations;
      _selectedStatus = _allStatuses;
      _filterIssuesOnly = false;
    });
  }

  // ---------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildSummary(),
                  const SizedBox(height: 18),
                  _buildUnavailableActions(),
                  const SizedBox(height: 18),
                  _buildCoverage(),
                  const SizedBox(height: 18),
                  _buildFilters(),
                  const SizedBox(height: 18),
                  _buildDeviceList(),
                  const SizedBox(height: 18),
                  _buildLogs(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return _SectionShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const Widget title = Row(
            children: [
              _HeaderBadge(),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'จัดการอุปกรณ์ IoT & มิเตอร์',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'ทะเบียนอุปกรณ์ของสถานศึกษา แสดงเฉพาะข้อมูลที่ระบบเก็บจริง '
                      '(ชื่อ ประเภท จุดติดตั้ง และสถานะเชื่อมต่อ)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _reloadAll,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('รีเฟรช'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: const Color(0xFF334155),
                ),
              ),
              // ไม่มี RPC ส่งออกไฟล์ในระบบ — ปิดปุ่มพร้อมบอกเหตุผล
              // ของเดิมกดแล้วขึ้น "เตรียมข้อมูลส่งออกเป็นไฟล์ Excel/CSV
              // เรียบร้อย" ทั้งที่ไม่มีไฟล์ใดถูกสร้าง
              const _DisabledAction(
                icon: Icons.download_rounded,
                label: 'ส่งออก',
                reason: 'ยังไม่มีระบบส่งออกไฟล์อุปกรณ์ในเวอร์ชันนี้',
              ),
              // `register_device` มีจริงแต่ยังไม่มีเมธอดใน shared_core และ
              // หน้าเพจเรียก supabase.rpc ตรง ๆ ไม่ได้ (hard rule 4)
              const _DisabledAction(
                icon: Icons.add_rounded,
                label: 'เพิ่มอุปกรณ์',
                reason: 'การลงทะเบียนอุปกรณ์ยังไม่เปิดใช้งานในหน้านี้',
              ),
            ],
          );

          if (constraints.maxWidth < 860) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 16), actions],
            );
          }

          return Row(
            children: [
              const Expanded(child: title),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }

  /// ข้อความประกอบตัวเลขสรุป — บอกให้ชัดว่าเลขนั้นคือผลการวัดจริง
  /// (`จากอุปกรณ์ N เครื่อง`) หรือยังไม่มีอะไรให้วัดเลย
  String _summaryDetail(int total) =>
      total == 0 ? 'ยังไม่มีอุปกรณ์ในระบบ' : 'จากอุปกรณ์ $total เครื่อง';

  Widget _buildSummary() {
    final loading = _devicesPhase == _LoadPhase.loading;
    final failed = _devicesPhase == _LoadPhase.error;
    final total = _devices.length;

    String value(int count) {
      if (loading) return '—';
      if (failed) return '—';
      return '$count';
    }

    String detail(String ok) {
      if (loading) return 'กำลังโหลด…';
      if (failed) return 'โหลดไม่สำเร็จ';
      return ok;
    }

    final items = <_SummaryData>[
      _SummaryData(
        title: 'อุปกรณ์ทั้งหมด',
        value: value(total),
        detail: detail(
          total == 0 ? 'ยังไม่มีอุปกรณ์ในระบบ' : 'ลงทะเบียนในระบบแล้ว',
        ),
        icon: Icons.memory_rounded,
        color: SchoolAdminPalette.blue,
      ),
      _SummaryData(
        title: 'ออนไลน์',
        value: value(_onlineCount),
        detail: detail(_summaryDetail(total)),
        icon: Icons.wifi_rounded,
        color: SchoolAdminPalette.green,
      ),
      _SummaryData(
        title: 'ออฟไลน์',
        value: value(_offlineCount),
        detail: detail(_summaryDetail(total)),
        icon: Icons.wifi_off_rounded,
        color: SchoolAdminPalette.red,
      ),
      _SummaryData(
        title: 'ผิดปกติ / ซ่อมบำรุง',
        value: value(_attentionCount),
        detail: detail(_summaryDetail(total)),
        icon: Icons.warning_amber_rounded,
        color: SchoolAdminPalette.yellow,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1050) columns = 2;
        if (constraints.maxWidth < 520) columns = 1;
        const spacing = 14.0;
        final width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(width: width, child: _SummaryCard(data: item)),
          ],
        );
      },
    );
  }

  /// รวมทุกคำสั่งที่ "ไม่มี backend" ไว้ที่เดียว แทนที่จะเป็นการ์ดกดได้ที่
  /// ขึ้น snackbar ขอโทษ ตาม DoD: ปุ่มที่ไม่มี backend = disable + บอกเหตุผล
  Widget _buildUnavailableActions() {
    return const _ModernSectionCard(
      title: 'คำสั่งที่ยังไม่เปิดใช้งาน',
      subtitle:
          'รายการต่อไปนี้ยังไม่มีคำสั่งฝั่งเซิร์ฟเวอร์รองรับ จึงปิดไว้แทนการแสดงผลลัพธ์ที่ไม่ได้เกิดขึ้นจริง',
      child: Column(
        children: [
          _UnavailableRow(
            icon: Icons.add_circle_outline_rounded,
            title: 'ลงทะเบียน / แก้ไขข้อมูลอุปกรณ์',
            reason: 'ยังไม่มีช่องทางบันทึกข้อมูลอุปกรณ์จากหน้านี้',
          ),
          SizedBox(height: 10),
          _UnavailableRow(
            icon: Icons.network_ping_rounded,
            title: 'ทดสอบสัญญาณ (Ping)',
            reason: 'ระบบไม่มีคำสั่งทดสอบสัญญาณอุปกรณ์',
          ),
          SizedBox(height: 10),
          _UnavailableRow(
            icon: Icons.qr_code_2_rounded,
            title: 'QR Code ประจำอุปกรณ์',
            reason: 'ระบบยังไม่ได้ออกรหัส QR ให้อุปกรณ์',
          ),
          SizedBox(height: 10),
          _UnavailableRow(
            icon: Icons.power_settings_new_rounded,
            title: 'เปิด / ปิดอุปกรณ์',
            reason: 'สั่งงานอุปกรณ์ได้ที่หน้า "ควบคุมอุปกรณ์"',
          ),
          SizedBox(height: 10),
          _UnavailableRow(
            icon: Icons.build_circle_rounded,
            title: 'แผนการบำรุงรักษาและการสอบเทียบ',
            reason: 'ระบบยังไม่เก็บกำหนดการบำรุงรักษาอุปกรณ์',
          ),
        ],
      ),
    );
  }

  Widget _buildCoverage() {
    final loading = _devicesPhase == _LoadPhase.loading;
    final failed = _devicesPhase == _LoadPhase.error;
    final total = _devices.length;

    final String locatedValue;
    final String locatedDetail;
    if (loading) {
      locatedValue = '—';
      locatedDetail = 'กำลังโหลด…';
    } else if (failed) {
      locatedValue = '—';
      locatedDetail = 'โหลดไม่สำเร็จ';
    } else if (total == 0) {
      locatedValue = '—';
      locatedDetail = 'ยังไม่มีอุปกรณ์ในระบบ';
    } else {
      locatedValue = '$_locatedCount / $total';
      locatedDetail = 'อุปกรณ์ที่มีข้อมูลจุดติดตั้งในฐานข้อมูล';
    }

    final items = <_CoverageData>[
      _CoverageData(
        title: 'ระบุจุดติดตั้งแล้ว',
        value: locatedValue,
        detail: locatedDetail,
        progress: (loading || failed || total == 0)
            ? null
            : _locatedCount / total,
        icon: Icons.location_on_rounded,
        color: SchoolAdminPalette.blue,
      ),
      // ของเดิมประกาศ "Firmware เป็นเวอร์ชันล่าสุด 100% / ไม่มีอัปเดตคงค้าง"
      // ทั้งที่ RPC ไม่คืนคอลัมน์ firmware_version มาเลย
      const _CoverageData(
        title: 'เวอร์ชันเฟิร์มแวร์',
        value: '—',
        detail: 'ยังไม่มีข้อมูล ระบบไม่ได้ส่งเวอร์ชันเฟิร์มแวร์มาแสดง',
        progress: null,
        icon: Icons.system_update_rounded,
        color: SchoolAdminPalette.textMuted,
      ),
      // เช่นเดียวกับ "การสอบเทียบตามกำหนด: ผ่านเกณฑ์ 95%" ที่ไม่มีที่มา
      const _CoverageData(
        title: 'การสอบเทียบเซนเซอร์',
        value: '—',
        detail: 'ยังไม่มีข้อมูล ระบบไม่ได้เก็บรอบการสอบเทียบ',
        progress: null,
        icon: Icons.tune_rounded,
        color: SchoolAdminPalette.textMuted,
      ),
    ];

    return _ModernSectionCard(
      title: 'ความครบถ้วนของทะเบียนอุปกรณ์',
      subtitle:
          'นับจากข้อมูลที่ระบบเก็บจริงเท่านั้น ช่องที่ระบบไม่ได้เก็บจะขึ้นว่ายังไม่มีข้อมูล',
      child: LayoutBuilder(
        builder: (context, constraints) {
          int columns = 3;
          if (constraints.maxWidth < 860) columns = 1;
          const spacing = 12.0;
          final width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final item in items)
                SizedBox(width: width, child: _CoverageCard(data: item)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return _SectionShell(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'ค้นหาด้วยชื่ออุปกรณ์ ประเภท หรือจุดติดตั้ง...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                selected: _filterIssuesOnly,
                onSelected: (value) =>
                    setState(() => _filterIssuesOnly = value),
                label: const Text('เฉพาะที่ไม่ออนไลน์'),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _filterIssuesOnly
                      ? Colors.white
                      : const Color(0xFF0F172A),
                ),
                backgroundColor: const Color(0xFFFEF3C7),
                selectedColor: SchoolAdminPalette.yellow,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FilterChipRow(
            label: 'ประเภท:',
            options: _categoryOptions,
            selected: _selectedCategory,
            onSelected: (value) => setState(() => _selectedCategory = value),
          ),
          const SizedBox(height: 10),
          _FilterChipRow(
            label: 'จุดติดตั้ง:',
            options: _locationOptions,
            selected: _selectedLocation,
            onSelected: (value) => setState(() => _selectedLocation = value),
          ),
          const SizedBox(height: 10),
          _FilterChipRow(
            label: 'สถานะ:',
            options: _statusOptions,
            selected: _selectedStatus,
            onSelected: (value) => setState(() => _selectedStatus = value),
            enabled: !_filterIssuesOnly,
          ),
          if (_hasFilters) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('ล้างตัวกรอง'),
                style: TextButton.styleFrom(
                  foregroundColor: SchoolAdminPalette.red,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    final devices = _filteredDevices;

    return _SectionShell(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รายการอุปกรณ์ทั้งหมด',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ข้อมูลจาก list_school_devices — ชื่อ ประเภท จุดติดตั้ง และสถานะเชื่อมต่อ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_devicesPhase == _LoadPhase.data)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'พบ ${devices.length} รายการ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_devicesPhase == _LoadPhase.loading)
            const _LoadingBlock(label: 'กำลังโหลดรายการอุปกรณ์…')
          else if (_devicesPhase == _LoadPhase.error)
            _ErrorBlock(
              message: _devicesError ?? 'โหลดรายการอุปกรณ์ไม่สำเร็จ',
              onRetry: _loadDevices,
            )
          else if (devices.isEmpty)
            _EmptyBlock(
              // แยกให้ชัดว่า "ไม่มีอุปกรณ์เลย" หรือ "ตัวกรองคัดออกหมด"
              title: 'ไม่พบอุปกรณ์',
              detail: _devices.isEmpty
                  ? 'ยังไม่มีอุปกรณ์ที่ลงทะเบียนกับสถานศึกษานี้'
                  : 'ไม่มีอุปกรณ์ที่ตรงกับตัวกรองที่เลือก',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return Table(
                    border: const TableBorder(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                      horizontalInside: BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2.8),
                      1: FlexColumnWidth(1.6),
                      2: FlexColumnWidth(1.8),
                      3: FlexColumnWidth(1.3),
                      4: FlexColumnWidth(0.9),
                    },
                    defaultVerticalAlignment:
                        TableCellVerticalAlignment.middle,
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                        children: [
                          _TableHeader(
                            text: 'ชื่ออุปกรณ์',
                            align: TextAlign.left,
                          ),
                          _TableHeader(text: 'ประเภท'),
                          _TableHeader(text: 'จุดติดตั้ง'),
                          _TableHeader(text: 'สถานะเชื่อมต่อ'),
                          _TableHeader(text: 'จัดการ'),
                        ],
                      ),
                      for (final device in devices)
                        TableRow(
                          children: [
                            _TableCell(
                              align: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  _TypeIconBox(type: device.type),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      device.name.trim().isEmpty
                                          ? _noData
                                          : device.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _TableCell(
                              child: Text(
                                _typeLabel(device.type),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            _TableCell(
                              child: Text(
                                _locationOf(device),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _locationOf(device) == _noData
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            _TableCell(
                              child: _StatusBadge(
                                label: _statusLabel(device.status),
                                color: _statusColor(device.status),
                              ),
                            ),
                            _TableCell(
                              child: TextButton(
                                onPressed: () => _showDeviceDetail(device),
                                child: const Text('รายละเอียด'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (final device in devices)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DeviceMobileCard(
                            name: device.name.trim().isEmpty
                                ? _noData
                                : device.name,
                            type: _typeLabel(device.type),
                            location: _locationOf(device),
                            status: _statusLabel(device.status),
                            statusColor: _statusColor(device.status),
                            icon: _typeIcon(device.type),
                            onView: () => _showDeviceDetail(device),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showDeviceDetail(DeviceOption device) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 720),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _TypeIconBox(type: device.type, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name.trim().isEmpty
                                    ? _noData
                                    : device.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _typeLabel(device.type),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ข้อมูลที่ระบบเก็บไว้',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DetailBox(
                      rows: [
                        _DetailRowData(
                          icon: Icons.category_rounded,
                          label: 'ประเภทอุปกรณ์',
                          value: _typeLabel(device.type),
                        ),
                        _DetailRowData(
                          icon: Icons.place_rounded,
                          label: 'จุดติดตั้ง',
                          value: _locationOf(device),
                        ),
                        _DetailRowData(
                          icon: Icons.sensors_rounded,
                          label: 'สถานะเชื่อมต่อ',
                          value: _statusLabel(device.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ข้อมูลที่ระบบยังไม่ได้เก็บ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // ของเดิมโชว์ค่าพวกนี้เป็นตัวเลข/ข้อความที่ดูจริงทั้งหมด
                    // ทั้งที่ไม่มีค่าไหนมาจากฐานข้อมูล
                    const _DetailBox(
                      rows: [
                        _DetailRowData(
                          icon: Icons.confirmation_number_rounded,
                          label: 'Serial Number',
                          value: _noData,
                        ),
                        _DetailRowData(
                          icon: Icons.meeting_room_rounded,
                          label: 'ห้อง',
                          value: _noData,
                        ),
                        _DetailRowData(
                          icon: Icons.router_rounded,
                          label: 'IP Address',
                          value: _noData,
                        ),
                        _DetailRowData(
                          icon: Icons.system_update_rounded,
                          label: 'เวอร์ชันเฟิร์มแวร์',
                          value: _noData,
                        ),
                        _DetailRowData(
                          icon: Icons.access_time_rounded,
                          label: 'ตอบสนองล่าสุด',
                          value: _noData,
                        ),
                        _DetailRowData(
                          icon: Icons.signal_cellular_alt_rounded,
                          label: 'ความแรงสัญญาณ',
                          value: _noData,
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
  }

  Widget _buildLogs() {
    final Widget body;
    if (_logsPhase == _LoadPhase.loading) {
      body = const _LoadingBlock(label: 'กำลังโหลดประวัติการจัดการอุปกรณ์…');
    } else if (_logsPhase == _LoadPhase.error) {
      body = _ErrorBlock(
        message: _logsError ?? 'โหลดประวัติการจัดการอุปกรณ์ไม่สำเร็จ',
        onRetry: _loadLogs,
      );
    } else if (_logs.isEmpty) {
      body = const _EmptyBlock(title: 'ยังไม่มีประวัติการจัดการอุปกรณ์');
    } else {
      body = Column(
        children: [
          for (final log in _logs.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LogRow(log: log),
            ),
        ],
      );
    }

    return _ModernSectionCard(
      title: 'ประวัติการจัดการอุปกรณ์ (Audit Logs)',
      subtitle:
          'บันทึกกิจกรรมของผู้ดูแลจาก list_school_admin_audit_logs — เวลาแสดงตามที่ระบบบันทึกไว้',
      child: body,
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: SchoolAdminPalette.heroGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.memory_rounded, color: Colors.white, size: 28),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _ModernSectionCard extends StatelessWidget {
  const _ModernSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SummaryData {
  const _SummaryData({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withAlpha(22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ค่าตัวใหญ่ต้องสั้นเสมอ (ตัวเลขหรือ "—") ข้อความยาว ๆ
                // ไปอยู่ในบรรทัด detail ไม่งั้นการ์ดล้น
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
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

class _CoverageData {
  const _CoverageData({
    required this.title,
    required this.value,
    required this.detail,
    required this.progress,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final double? progress;
  final IconData icon;
  final Color color;
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({required this.data});

  final _CoverageData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 20, color: data.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          if (data.progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: data.progress!.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(data.color),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            data.detail,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _DisabledAction extends StatelessWidget {
  const _DisabledAction({
    required this.icon,
    required this.label,
    required this.reason,
  });

  final IconData icon;
  final String label;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: reason,
      child: OutlinedButton.icon(
        onPressed: null,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _UnavailableRow extends StatelessWidget {
  const _UnavailableRow({
    required this.icon,
    required this.title,
    required this.reason,
  });

  final IconData icon;
  final String title;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ปิดใช้งาน',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        if (options.length <= 1)
          const Text(
            'ยังไม่มีข้อมูล',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          )
        else
          for (final option in options)
            ChoiceChip(
              label: Text(option),
              selected: selected == option,
              onSelected: enabled
                  ? (isSelected) {
                      if (isSelected) onSelected(option);
                    }
                  : null,
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: selected == option
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: selected == option
                    ? Colors.white
                    : const Color(0xFF475569),
              ),
              selectedColor: SchoolAdminPalette.primary,
              backgroundColor: const Color(0xFFF1F5F9),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.title, this.detail});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.inbox_rounded,
            size: 34,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF0EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3C9C2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: SchoolAdminPalette.red,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: SchoolAdminPalette.red,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => onRetry(),
            style: OutlinedButton.styleFrom(
              foregroundColor: SchoolAdminPalette.red,
              side: const BorderSide(color: SchoolAdminPalette.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.text, this.align = TextAlign.center});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.child, this.align = Alignment.center});

  final Widget child;
  final Alignment align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Align(alignment: align, child: child),
    );
  }
}

class _TypeIconBox extends StatelessWidget {
  const _TypeIconBox({required this.type, this.size = 36});

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SchoolAdminPalette.primarySoft,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(
        _SchoolDevicesPageState._typeIcon(type),
        size: size * 0.5,
        color: SchoolAdminPalette.primaryDark,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _DeviceMobileCard extends StatelessWidget {
  const _DeviceMobileCard({
    required this.name,
    required this.type,
    required this.location,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.onView,
  });

  final String name;
  final String type;
  final String location;
  final String status;
  final Color statusColor;
  final IconData icon;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: SchoolAdminPalette.primaryDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$type • $location',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _StatusBadge(label: status, color: statusColor),
          ],
        ),
      ),
    );
  }
}

class _DetailRowData {
  const _DetailRowData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _DetailBox extends StatelessWidget {
  const _DetailBox({required this.rows});

  final List<_DetailRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 16, color: Color(0xFFE2E8F0)),
            Row(
              children: [
                Icon(rows[i].icon, size: 17, color: const Color(0xFF94A3B8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rows[i].label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    rows[i].value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: rows[i].value == 'ยังไม่มีข้อมูล'
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log});

  final SchoolAdminAuditLog log;

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final time =
        '${_two(log.createdAt.hour)}:${_two(log.createdAt.minute)} น.';
    final action = log.action.trim().isEmpty ? 'ยังไม่มีข้อมูล' : log.action;
    final detail = log.detail.trim().isNotEmpty
        ? log.detail
        : (log.target.trim().isNotEmpty ? log.target : 'ยังไม่มีข้อมูล');
    final actor = log.actorName.trim().isEmpty
        ? 'ยังไม่มีข้อมูล'
        : log.actorName;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.history_rounded,
            size: 18,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'โดย $actor • $time',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
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
