// PROTOTYPE: Teacher AIoT Dashboard & Control Center (ศูนย์เฝ้าระวังและจัดการค่า AIoT ฝั่งครู)
// Wireframe MVP v1 Section 2.7.1 - 2.7.4
// Features: Real-time sensor metrics per classroom/device, Threshold settings, Abnormal alerts list with acknowledge action, and Data Export (CSV/Excel).

import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../utils/web_download.dart';
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart' show TeacherMockPageShell;

/// หน้านี้มี Threshold/Alert/Export ให้แก้ค่าจริงได้ — ตาม decision log
/// ("ครูดูข้อมูลตาม school/course scope และตั้งค่า Threshold หรือรับทราบ
/// Alert ได้ตาม Permission Matrix" / "นักเรียนดูได้แบบ read-only ไม่เห็น
/// เมนูตั้งค่า Threshold") สิทธิ์นี้เป็นของครู/แอดมินเท่านั้น เช็คที่ตัวหน้า
/// เองด้วย (ไม่พึ่งแค่การไม่มีลิงก์จากฝั่งนักเรียน) กันเผื่อวันหนึ่งมี
/// deep link หรือ route อื่นพาเข้ามาได้โดยไม่ผ่านเมนูที่ตั้งใจไว้
const _kAiotDashboardAllowedRoles = {
  UserRole.teacher,
  UserRole.schoolAdmin,
  UserRole.superAdmin,
};

/// Model ข้อมูลเซนเซอร์เรียลไทม์ต่ออุปกรณ์
class AiotDeviceModel {
  AiotDeviceModel({
    required this.id,
    required this.name,
    required this.location,
    required this.isOnline,
    required this.pm25,
    required this.temperature,
    required this.humidity,
    required this.lightLux,
    required this.relayActive,
    required this.lastUpdated,
    this.hasRealData = true,
  });

  String id;
  String name;
  String location;
  bool isOnline;
  double pm25;
  double temperature;
  double humidity;
  double lightLux;
  bool relayActive;
  String lastUpdated;

  /// False when this device has zero real sensor_readings rows yet (no
  /// gateway has reported for it) — the metric fields above are 0 in that
  /// case and must not be shown as if they were a real reading.
  bool hasRealData;
}

/// Model ข้อมูลการตั้งค่า Threshold
class ThresholdSettingModel {
  ThresholdSettingModel({
    required this.metricKey,
    required this.metricName,
    required this.unit,
    required this.minThreshold,
    required this.maxThreshold,
    required this.isAlertEnabled,
  });

  String metricKey;
  String metricName;
  String unit;
  double minThreshold;
  double maxThreshold;
  bool isAlertEnabled;
}

/// Model ข้อมูลแจ้งเตือน Alert ค่าผิดปกติ
class AiotAlertModel {
  AiotAlertModel({
    required this.id,
    required this.deviceName,
    required this.location,
    required this.metricName,
    required this.triggerValue,
    required this.thresholdLimit,
    required this.triggerTime,
    required this.isAcknowledged,
  });

  String id;
  String deviceName;
  String location;
  String metricName;
  String triggerValue;
  String thresholdLimit;
  String triggerTime;
  bool isAcknowledged;
}

class TeacherAiotDashboardPage extends StatefulWidget {
  const TeacherAiotDashboardPage({
    super.key,
    this.listSchoolDevices,
    this.getAllDeviceSensors,
    this.listDeviceRelayStates,
    this.listThresholds,
    this.setThreshold,
    this.listAlerts,
    this.acknowledgeAlert,
  });

  /// Read/write seams threaded to the corresponding LessonService/
  /// RealtimeService static calls in production.
  final Future<List<DeviceOption>> Function()? listSchoolDevices;
  final Future<Map<String, SensorModel>> Function()? getAllDeviceSensors;
  final Future<List<DeviceRelayState>> Function()? listDeviceRelayStates;
  final Future<List<Map<String, dynamic>>> Function()? listThresholds;
  final Future<void> Function({
    required String metric,
    required double min,
    required double max,
    bool isActive,
  })?
  setThreshold;
  final Future<List<Map<String, dynamic>>> Function({String? status})?
  listAlerts;
  final Future<void> Function(String alertId)? acknowledgeAlert;

  @override
  State<TeacherAiotDashboardPage> createState() =>
      _TeacherAiotDashboardPageState();
}

class _TeacherAiotDashboardPageState extends State<TeacherAiotDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // เดิม seed _devices/_thresholds/_alerts ด้วยข้อมูลตัวอย่างตอนเปิดหน้า
  // แล้วเขียนทับแค่ตอน `list.isNotEmpty` — โรงเรียนที่ไม่มีอุปกรณ์/threshold
  // จริงเลยจะเห็นข้อมูลตัวอย่างค้างอยู่ตลอดไปโดยไม่รู้ตัวว่าเป็นของปลอม
  // ตอนนี้เริ่มจากลิสต์ว่างจริง มี flag โหลดแยกให้ UI บอกสถานะตรงๆ
  List<AiotDeviceModel> _devices = const [];
  List<ThresholdSettingModel> _thresholds = const [];
  List<AiotAlertModel> _alerts = const [];
  bool _devicesLoading = true;
  bool _thresholdsLoading = true;
  bool _alertsLoading = true;

  /// ป้ายชื่อ/หน่วยของแต่ละ metric — ค่าคงที่ของ UI (เหมือน label ภาษา)
  /// ไม่ใช่ข้อมูลที่ต้องมาจาก backend แยกจากค่า min/max/isActive จริงที่มา
  /// จาก RealtimeService.listThresholds() เสมอ
  static const Map<String, (String, String)> _metricLabels = {
    'pm25': ('ฝุ่น PM2.5', 'µg/m³'),
    'temperature': ('อุณหภูมิห้องเรียน', '°C'),
    'humidity': ('ความชื้นสัมพัทธ์', '%RH'),
    'light_lux': ('ความเข้มแสง', 'lux'),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRealDevices();
    _loadRealThresholds();
    _loadRealAlerts();
  }

  Future<void> _loadRealDevices() async {
    try {
      final listDevices =
          widget.listSchoolDevices ?? LessonService.listSchoolDevices;
      final getSensors =
          widget.getAllDeviceSensors ?? RealtimeService.getAllDeviceSensors;
      final getRelayStates =
          widget.listDeviceRelayStates ??
          RealtimeService.listDeviceRelayStates;
      final list = await listDevices();
      if (!mounted) return;
      final sensorsByDevice = await getSensors();
      // A device with no row here has never acknowledged a relay command —
      // that's "unknown," not "off" (see DeviceRelayState's own doc
      // comment), but AiotDeviceModel.relayActive is a non-nullable bool,
      // so a missing row falls back to false as the closest honest
      // approximation available with the current model shape.
      final relayStates = await getRelayStates();
      final relayActiveByDevice = <String, bool>{
        for (final r in relayStates) r.deviceId: r.state,
      };
      setState(() {
        _devices = list.map((d) {
          final location = d.location != null
              ? '${d.name} (${d.location})'
              : d.name;
          // Same key logic as RealtimeService.modelsByDevice: prefer the
          // device's own location string, fall back to its name.
          final matchKey = (d.location?.trim().isNotEmpty ?? false)
              ? d.location!.trim()
              : d.name;
          final sensor = sensorsByDevice[matchKey];
          return AiotDeviceModel(
            id: d.id,
            name: d.name,
            location: location,
            isOnline: d.status == 'online',
            pm25: sensor?.pm25 ?? 0,
            temperature: sensor?.temperature ?? 0,
            humidity: sensor?.humidity ?? 0,
            lightLux: sensor?.lux ?? 0,
            relayActive: relayActiveByDevice[d.id] ?? false,
            hasRealData: sensor != null,
            lastUpdated: sensor?.updatedAt != null
                ? 'เมื่อ ${sensor!.updatedAt!.hour.toString().padLeft(2, '0')}:${sensor.updatedAt!.minute.toString().padLeft(2, '0')} น.'
                : 'ยังไม่มีข้อมูลเซนเซอร์',
          );
        }).toList();
        _devicesLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading real school devices: $e');
      if (mounted) setState(() => _devicesLoading = false);
    }
  }

  Future<void> _loadRealThresholds() async {
    try {
      final loadThresholds =
          widget.listThresholds ?? RealtimeService.listThresholds;
      final rows = await loadThresholds();
      if (!mounted) return;
      setState(() {
        _thresholds = rows.map((row) {
          final metric = row['metric']?.toString() ?? '';
          final label = _metricLabels[metric];
          return ThresholdSettingModel(
            metricKey: metric,
            metricName: label?.$1 ?? metric,
            unit: label?.$2 ?? '',
            minThreshold: (row['min_value'] as num?)?.toDouble() ?? 0,
            maxThreshold: (row['max_value'] as num?)?.toDouble() ?? 0,
            isAlertEnabled: row['is_active'] == true,
          );
        }).toList();
        _thresholdsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading real thresholds: $e');
    }
  }

  Future<void> _saveThresholds() async {
    try {
      final save = widget.setThreshold ?? RealtimeService.setThreshold;
      for (final th in _thresholds) {
        if (th.metricKey.isEmpty) continue;
        await save(
          metric: th.metricKey,
          min: th.minThreshold,
          max: th.maxThreshold,
          isActive: th.isAlertEnabled,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกการตั้งค่า Threshold เรียบร้อยแล้ว'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      await _loadRealThresholds();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _loadRealAlerts() async {
    try {
      final loadAlerts = widget.listAlerts ?? RealtimeService.listAlerts;
      final rows = await loadAlerts();
      if (!mounted) return;
      setState(() {
        _alerts = rows.map((row) {
          final ts = DateTime.tryParse(row['triggered_at']?.toString() ?? '');
          return AiotAlertModel(
            id: row['id'].toString(),
            deviceName: row['device_name']?.toString() ?? '-',
            location: row['device_code']?.toString() ?? '-',
            metricName: row['metric']?.toString() ?? '-',
            triggerValue: '${row['value']}',
            thresholdLimit: '-',
            triggerTime: ts != null
                ? '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')} น.'
                : '-',
            isAcknowledged: row['status'] != 'new',
          );
        }).toList();
        _alertsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading real alerts: $e');
      if (mounted) setState(() => _alertsLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _acknowledgeAlert(AiotAlertModel alert) async {
    try {
      final acknowledge =
          widget.acknowledgeAlert ?? RealtimeService.acknowledgeAlert;
      await acknowledge(alert.id);
      if (!mounted) return;
      setState(() => alert.isAcknowledged = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'รับทราบการแจ้งเตือนของ ${alert.deviceName} เรียบร้อยแล้ว',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รับทราบไม่สำเร็จ กรุณาลองใหม่'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  static const _exportMetricKeys = ['pm25', 'temperature', 'humidity', 'light_lux'];
  static const _exportMetricLabels = {
    'pm25': 'ฝุ่น PM2.5',
    'temperature': 'อุณหภูมิ',
    'humidity': 'ความชื้นสัมพัทธ์',
    'light_lux': 'ความเข้มแสง',
  };

  DateTime _exportRangeStart(String range) {
    final now = DateTime.now();
    switch (range) {
      case 'วันนี้':
        return DateTime(now.year, now.month, now.day);
      case '30 วันล่าสุด':
        return now.subtract(const Duration(days: 30));
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  Future<void> _exportCsv(String range) async {
    final from = _exportRangeStart(range);
    final to = DateTime.now();
    final rows = <List<dynamic>>[
      ['อุปกรณ์', 'ตำแหน่ง', 'ตัวชี้วัด', 'เวลา', 'ค่า'],
    ];
    for (final dev in _devices.where((d) => d.hasRealData)) {
      for (final metric in _exportMetricKeys) {
        final history = await RealtimeService.getSensorHistory(
          deviceId: dev.id,
          metric: metric,
          from: from,
          to: to,
        );
        for (final point in history) {
          rows.add([
            dev.name,
            dev.location,
            _exportMetricLabels[metric],
            point.ts.toLocal().toIso8601String(),
            point.value,
          ]);
        }
      }
    }

    if (!mounted) return;
    if (rows.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูลเซนเซอร์จริงในช่วงเวลาที่เลือก')),
      );
      return;
    }

    final csv = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
    downloadBytes(
      filename: 'aiot_metrics_$range.csv',
      bytes: bytes,
      mimeType: 'text/csv',
    );
  }

  Future<void> _exportExcel() async {
    final workbook = xls.Excel.createExcel();
    final sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
    final sheet = workbook[sheetName];
    sheet.appendRow([
      xls.TextCellValue('อุปกรณ์'),
      xls.TextCellValue('ตำแหน่ง'),
      xls.TextCellValue('ตัวชี้วัด'),
      xls.TextCellValue('ค่าปัจจุบัน'),
      xls.TextCellValue('หน่วย'),
      xls.TextCellValue('ช่วงปกติ'),
      xls.TextCellValue('สถานะ'),
      xls.TextCellValue('อัปเดตล่าสุด'),
    ]);

    var rowCount = 0;
    for (final dev in _devices.where((d) => d.hasRealData)) {
      for (final th in _thresholds) {
        final value = switch (th.metricKey) {
          'pm25' => dev.pm25,
          'temperature' => dev.temperature,
          'humidity' => dev.humidity,
          'light_lux' => dev.lightLux,
          _ => null,
        };
        if (value == null) continue;
        final inRange = value >= th.minThreshold && value <= th.maxThreshold;
        sheet.appendRow([
          xls.TextCellValue(dev.name),
          xls.TextCellValue(dev.location),
          xls.TextCellValue(th.metricName),
          xls.DoubleCellValue(value),
          xls.TextCellValue(th.unit),
          xls.TextCellValue('${th.minThreshold}-${th.maxThreshold}'),
          xls.TextCellValue(inRange ? 'ปกติ' : 'ผิดปกติ'),
          xls.TextCellValue(dev.lastUpdated),
        ]);
        rowCount++;
      }
    }

    if (!mounted) return;
    if (rowCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูลเซนเซอร์จริงให้สรุป')),
      );
      return;
    }

    // encode() (not save()) — save() has its own web-only side effect of
    // triggering a browser download itself using a default filename,
    // independent of downloadBytes() below; encode() just returns bytes.
    final bytes = workbook.encode();
    if (bytes == null) throw Exception('export_failed');
    downloadBytes(
      filename: 'aiot_summary.xlsx',
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  void _showExportDialog() {
    var selectedRange = '7 วันล่าสุด';
    var busy = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> run(Future<void> Function() action) async {
            setDialogState(() => busy = true);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await action();
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (_) {
              setDialogState(() => busy = false);
              messenger.showSnackBar(
                const SnackBar(content: Text('ส่งออกไฟล์ไม่สำเร็จ')),
              );
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.download_rounded, color: TeacherPalette.primary),
                SizedBox(width: 10),
                Text(
                  'ส่งออกข้อมูลเซนเซอร์ AIoT',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'เลือกช่วงเวลาและรูปแบบไฟล์ที่ต้องการดาวน์โหลด:',
                  style: TextStyle(fontSize: 12, color: TeacherPalette.muted),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedRange,
                  decoration: InputDecoration(
                    labelText: 'ช่วงเวลาขอบเขตข้อมูล (สำหรับ CSV)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'วันนี้', child: Text('วันนี้')),
                    DropdownMenuItem(
                      value: '7 วันล่าสุด',
                      child: Text('7 วันล่าสุด'),
                    ),
                    DropdownMenuItem(
                      value: '30 วันล่าสุด',
                      child: Text('30 วันล่าสุด'),
                    ),
                  ],
                  onChanged: busy
                      ? null
                      : (v) => setDialogState(() => selectedRange = v!),
                ),
                if (busy) ...[
                  const SizedBox(height: 14),
                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => run(() => _exportCsv(selectedRange)),
                icon: const Icon(Icons.table_chart_rounded, size: 16),
                label: const Text('ดาวน์โหลด CSV'),
              ),
              ElevatedButton.icon(
                onPressed: busy ? null : () => run(_exportExcel),
                icon: const Icon(Icons.description_rounded, size: 16),
                label: const Text('ดาวน์โหลด Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherPalette.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // หน้านี้อยู่ใน teacher_redesign_prototype ที่ยังไม่ผ่าน auth จริง —
    // currentUserModel จึงเป็น null เสมอตอนเดโม (ยังไม่ได้ login ผ่าน
    // Supabase) ห้าม block กรณี null เพราะจะทำให้เดโมพังทันที บล็อกเฉพาะ
    // กรณีที่ "รู้ชัด" ว่า login เข้ามาแล้วด้วย role ที่ไม่ใช่ครู/แอดมิน
    // เท่านั้น (เผื่ออนาคตต่อ auth จริงแล้วมี route/deep link เข้าถึงหน้านี้
    // ได้โดยไม่ผ่านเมนูที่ตั้งใจไว้)
    final role = currentUserModel?.role;
    if (role != null && !_kAiotDashboardAllowedRoles.contains(role)) {
      return const _AiotDashboardAccessDenied();
    }

    final unackAlertsCount = _alerts.where((a) => !a.isAcknowledged).length;

    return TeacherMockPageShell(
      title: 'ศูนย์เฝ้าระวังและจัดการ AIoT',
      activeMenuLabel: 'AIoT Dashboard',
      actions: [
        ElevatedButton.icon(
          onPressed: _showExportDialog,
          icon: const Icon(Icons.file_download_rounded, size: 18),
          label: const Text(
            'ส่งออกข้อมูล (Export)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
      builder: (context, isDesktop) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tab Navigation Header Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: TeacherPalette.primary,
                  unselectedLabelColor: TeacherPalette.muted,
                  indicatorColor: TeacherPalette.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                  tabs: [
                    const Tab(
                      icon: Icon(Icons.sensors_rounded, size: 18),
                      text: 'สถานะเรียลไทม์',
                    ),
                    const Tab(
                      icon: Icon(Icons.tune_rounded, size: 18),
                      text: 'ตั้งค่า Threshold',
                    ),
                    Tab(
                      icon: Badge(
                        isLabelVisible: unackAlertsCount > 0,
                        label: Text('$unackAlertsCount'),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                        ),
                      ),
                      text: 'แจ้งเตือน (Alerts)',
                    ),
                    const Tab(
                      icon: Icon(Icons.analytics_rounded, size: 18),
                      text: 'รายงาน & Export',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tab Views Container
              SizedBox(
                height: 620,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Real-time Sensors List
                    _buildRealtimeTab(),

                    // Tab 2: Threshold Settings
                    _buildThresholdTab(),

                    // Tab 3: Alerts List
                    _buildAlertsTab(),

                    // Tab 4: Export & Analytics Overview
                    _buildExportTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRealtimeTab() {
    if (_devicesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_devices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'ยังไม่มีอุปกรณ์ AIoT ที่ลงทะเบียนไว้ในระบบ',
            style: TextStyle(color: TeacherPalette.muted),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _devices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final dev = _devices[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: TeacherPalette.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Header Row
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dev.isOnline
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      dev.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: TeacherPalette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: dev.isOnline
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dev.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: dev.isOnline
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'อัปเดต: ${dev.lastUpdated}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: TeacherPalette.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dev.location,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TeacherPalette.muted,
                ),
              ),

              const SizedBox(height: 16),

              // Sensor Values Grid
              if (!dev.isOnline)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Color(0xFFDC2626)),
                      SizedBox(width: 10),
                      Text(
                        'อุปกรณ์ขาดการเชื่อมต่อ ไม่สามารถอ่านค่าสดได้ในขณะนี้',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                )
              else if (!dev.hasRealData)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sensors_off_rounded, color: Color(0xFF64748B)),
                      SizedBox(width: 10),
                      Text(
                        'ยังไม่มีข้อมูลเซนเซอร์จริงจากอุปกรณ์นี้',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    _buildMetricBox(
                      title: 'ฝุ่น PM2.5',
                      value: dev.pm25.toStringAsFixed(1),
                      unit: 'µg/m³',
                      icon: Icons.air_rounded,
                      color: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFE0F2FE),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricBox(
                      title: 'อุณหภูมิ',
                      value: dev.temperature.toStringAsFixed(1),
                      unit: '°C',
                      icon: Icons.thermostat_rounded,
                      color: const Color(0xFFEA580C),
                      bgColor: const Color(0xFFFFF7ED),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricBox(
                      title: 'ความชื้น',
                      value: dev.humidity.toStringAsFixed(1),
                      unit: '%RH',
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricBox(
                      title: 'ความเข้มแสง',
                      value: '${dev.lightLux.toInt()}',
                      unit: 'lux',
                      icon: Icons.wb_sunny_rounded,
                      color: const Color(0xFFCA8A04),
                      bgColor: const Color(0xFFFEFCE8),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricBox({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdTab() {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: TeacherPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ตั้งค่าขอบเขตความปลอดภัย (Safety Thresholds)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: TeacherPalette.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'เมื่อค่าเซนเซอร์เกินเกณฑ์สูงสุดที่กำหนด ระบบจะส่งสัญญาณ Alert และบันทึกประวัติการเฝ้าระวังอัตโนมัติ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TeacherPalette.muted,
                ),
              ),
              const SizedBox(height: 20),
              if (_thresholdsLoading)
                const Center(child: CircularProgressIndicator())
              else if (_thresholds.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'ยังไม่มีการตั้งค่า Threshold ในระบบ',
                    style: TextStyle(color: TeacherPalette.muted),
                  ),
                )
              else
                Column(
                children: _thresholds.map((th) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                th.metricName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: TeacherPalette.ink,
                                ),
                              ),
                              Text(
                                'หน่วย: ${th.unit}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: TeacherPalette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: '${th.minThreshold}',
                                  onChanged: (v) {
                                    final val = double.tryParse(v);
                                    if (val != null) th.minThreshold = val;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'ค่าต่ำสุด',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: '${th.maxThreshold}',
                                  onChanged: (v) {
                                    final val = double.tryParse(v);
                                    if (val != null) th.maxThreshold = val;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'ค่าสูงสุด',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Switch(
                          value: th.isAlertEnabled,
                          activeColor: TeacherPalette.primary,
                          onChanged: (val) =>
                              setState(() => th.isAlertEnabled = val),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _saveThresholds,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('บันทึกการตั้งค่า Threshold'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherPalette.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    if (_alertsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_alerts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'ยังไม่มีการแจ้งเตือนในระบบ',
            style: TextStyle(color: TeacherPalette.muted),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _alerts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: alert.isAcknowledged
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFFFECACA),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: alert.isAcknowledged
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  alert.isAcknowledged
                      ? Icons.check_circle_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: alert.isAcknowledged
                      ? const Color(0xFF64748B)
                      : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          alert.metricName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: TeacherPalette.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '(${alert.deviceName} - ${alert.location})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TeacherPalette.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ค่าที่ตรวจพบ: ${alert.triggerValue} (เกณฑ์ขอบเขต: ${alert.thresholdLimit}) • เวลา: ${alert.triggerTime}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TeacherPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (!alert.isAcknowledged)
                ElevatedButton.icon(
                  onPressed: () => _acknowledgeAlert(alert),
                  icon: const Icon(Icons.done_all_rounded, size: 15),
                  label: const Text('รับทราบ Alert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'รับทราบแล้ว',
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
      },
    );
  }

  Widget _buildExportTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายงานและการส่งออกข้อมูล (Export Data)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: TeacherPalette.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ดาวน์โหลดข้อมูลเซนเซอร์ย้อนหลังในรูปแบบ CSV หรือ Excel เพื่อนำไปใช้วิเคราะห์ต่อหรือจัดทำรายงานประจำภาคเรียน',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TeacherPalette.muted,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.table_chart_rounded,
                        size: 40,
                        color: Color(0xFF0EA5E9),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'ข้อมูลดิบ CSV (Raw Data)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ประกอบด้วย Timestamp, Device ID, PM2.5, Temp, Humidity, UV',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: TeacherPalette.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showExportDialog,
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('ดาวน์โหลด CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.description_rounded,
                        size: 40,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'รายงานสรุป Excel (Summary Report)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'สรุปค่าเฉลี่ยรายวัน ค่าสูงสุด-ต่ำสุด พร้อมกราฟสรุปประจำสัปดาห์',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: TeacherPalette.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showExportDialog,
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('ดาวน์โหลด Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiotDashboardAccessDenied extends StatelessWidget {
  const _AiotDashboardAccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherPalette.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: TeacherPalette.ink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ไม่มีสิทธิ์เข้าถึงหน้านี้',
                style: TextStyle(
                  color: TeacherPalette.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'AIoT Dashboard (ตั้งค่า Threshold/รับ Alert/Export ข้อมูล)\nเป็นสิทธิ์เฉพาะครูและแอดมินเท่านั้น',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
