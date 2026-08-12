// PROTOTYPE: Teacher AIoT Dashboard & Control Center (ศูนย์เฝ้าระวังและจัดการค่า AIoT ฝั่งครู)
// Wireframe MVP v1 Section 2.7.1 - 2.7.4
// Features: Real-time sensor metrics per classroom/device, Threshold settings, Abnormal alerts list with acknowledge action, and Data Export (CSV/Excel).

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

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
    required this.uvIndex,
    required this.relayActive,
    required this.lastUpdated,
  });

  String id;
  String name;
  String location;
  bool isOnline;
  double pm25;
  double temperature;
  double humidity;
  double uvIndex;
  bool relayActive;
  String lastUpdated;
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
  const TeacherAiotDashboardPage({super.key});

  @override
  State<TeacherAiotDashboardPage> createState() =>
      _TeacherAiotDashboardPageState();
}

class _TeacherAiotDashboardPageState extends State<TeacherAiotDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late List<AiotDeviceModel> _devices;
  late List<ThresholdSettingModel> _thresholds;
  late List<AiotAlertModel> _alerts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _devices = _getMockDevices();
    _thresholds = _getMockThresholds();
    _alerts = _getMockAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AiotDeviceModel> _getMockDevices() {
    return [
      AiotDeviceModel(
        id: 'dev-01',
        name: 'AIoT-Node-01',
        location: 'ห้องเรียน ม.5/2 (อาคารเรียน 5 ชั้น 3)',
        isOnline: true,
        pm25: 18.5,
        temperature: 28.5,
        humidity: 62.0,
        uvIndex: 6.0,
        relayActive: true,
        lastUpdated: 'เมื่อสักครู่',
      ),
      AiotDeviceModel(
        id: 'dev-02',
        name: 'AIoT-Node-02',
        location: 'ห้องปฏิบัติการคอมพิวเตอร์ 2 (อาคาร 3)',
        isOnline: true,
        pm25: 12.0,
        temperature: 25.0,
        humidity: 55.0,
        uvIndex: 2.0,
        relayActive: false,
        lastUpdated: '1 นาทีที่แล้ว',
      ),
      AiotDeviceModel(
        id: 'dev-03',
        name: 'AIoT-Node-03',
        location: 'ห้องเรียน ม.4/1 (อาคารเรียน 4)',
        isOnline: false,
        pm25: 0.0,
        temperature: 0.0,
        humidity: 0.0,
        uvIndex: 0.0,
        relayActive: false,
        lastUpdated: 'ขาดการเชื่อมต่อ (10 นาทีที่แล้ว)',
      ),
    ];
  }

  List<ThresholdSettingModel> _getMockThresholds() {
    return [
      ThresholdSettingModel(
        metricKey: 'pm25',
        metricName: 'ฝุ่น PM2.5',
        unit: 'µg/m³',
        minThreshold: 0,
        maxThreshold: 37.5,
        isAlertEnabled: true,
      ),
      ThresholdSettingModel(
        metricKey: 'temperature',
        metricName: 'อุณหภูมิห้องเรียน',
        unit: '°C',
        minThreshold: 20,
        maxThreshold: 33.0,
        isAlertEnabled: true,
      ),
      ThresholdSettingModel(
        metricKey: 'humidity',
        metricName: 'ความชื้นสัมพัทธ์',
        unit: '%RH',
        minThreshold: 40,
        maxThreshold: 75.0,
        isAlertEnabled: true,
      ),
      ThresholdSettingModel(
        metricKey: 'uvIndex',
        metricName: 'ดัชนีรังสี UV',
        unit: 'Index',
        minThreshold: 0,
        maxThreshold: 5.0,
        isAlertEnabled: true,
      ),
    ];
  }

  List<AiotAlertModel> _getMockAlerts() {
    return [
      AiotAlertModel(
        id: 'alert-01',
        deviceName: 'AIoT-Node-01',
        location: 'ห้องเรียน ม.5/2',
        metricName: 'ดัชนีรังสี UV สูงเกินมาตรฐาน',
        triggerValue: 'UV 6',
        thresholdLimit: 'สูงสุดไม่เกิน UV 5',
        triggerTime: '13:45 น. (วันนี้)',
        isAcknowledged: false,
      ),
      AiotAlertModel(
        id: 'alert-02',
        deviceName: 'AIoT-Node-03',
        location: 'ห้องเรียน ม.4/1',
        metricName: 'เซนเซอร์ขาดการติดต่อ (Offline)',
        triggerValue: 'No Signal',
        thresholdLimit: 'Heartbeat Timeout 5 min',
        triggerTime: '13:20 น. (วันนี้)',
        isAcknowledged: true,
      ),
    ];
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: TeacherPalette.primary),
            SizedBox(width: 10),
            Text(
              'ส่งออกข้อมูลเซนเซอร์ AIoT',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เลือกช่วงเวลาและรูปแบบไฟล์ที่ต้องการดาวน์โหลด:',
              style: TextStyle(fontSize: 12.5, color: TeacherPalette.muted),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: '7 วันล่าสุด',
              decoration: InputDecoration(
                labelText: 'ช่วงเวลาขอบเขตข้อมูล',
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
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('กำลังดาวน์โหลดไฟล์ CSV (aiot_metrics.csv)...'),
                  backgroundColor: Color(0xFF0EA5E9),
                ),
              );
            },
            icon: const Icon(Icons.table_chart_rounded, size: 16),
            label: const Text('ดาวน์โหลด CSV'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'กำลังดาวน์โหลดไฟล์ Excel (aiot_metrics.xlsx)...',
                  ),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            icon: const Icon(Icons.description_rounded, size: 16),
            label: const Text('ดาวน์โหลด Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
                  Text(
                    dev.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: TeacherPalette.ink,
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
                      fontSize: 11.5,
                      color: TeacherPalette.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dev.location,
                style: const TextStyle(
                  fontSize: 12.5,
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
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
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
                      value: '${dev.pm25}',
                      unit: 'µg/m³',
                      icon: Icons.air_rounded,
                      color: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFE0F2FE),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricBox(
                      title: 'อุณหภูมิ',
                      value: '${dev.temperature}',
                      unit: '°C',
                      icon: Icons.thermostat_rounded,
                      color: const Color(0xFFEA580C),
                      bgColor: const Color(0xFFFFF7ED),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricBox(
                      title: 'ความชื้น',
                      value: '${dev.humidity}',
                      unit: '%RH',
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricBox(
                      title: 'ดัชนี UV',
                      value: 'UV ${dev.uvIndex.toInt()}',
                      unit: dev.uvIndex > 5 ? 'อันตราย' : 'ปกติ',
                      icon: Icons.wb_sunny_rounded,
                      color: dev.uvIndex > 5
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF059669),
                      bgColor: dev.uvIndex > 5
                          ? const Color(0xFFFFF1F2)
                          : const Color(0xFFECFDF5),
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
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10.5,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: TeacherPalette.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'เมื่อค่าเซนเซอร์เกินเกณฑ์สูงสุดที่กำหนด ระบบจะส่งสัญญาณ Alert และบันทึกประวัติการเฝ้าระวังอัตโนมัติ',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: TeacherPalette.muted,
                ),
              ),
              const SizedBox(height: 20),
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
                                  fontSize: 11.5,
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'บันทึกการตั้งค่า Threshold เรียบร้อยแล้ว',
                        ),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
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
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: TeacherPalette.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${alert.deviceName} - ${alert.location})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TeacherPalette.muted,
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
                  onPressed: () {
                    setState(() => alert.isAcknowledged = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'รับทราบการแจ้งเตือนของ ${alert.deviceName} เรียบร้อยแล้ว',
                        ),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
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
                      fontSize: 11.5,
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
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: TeacherPalette.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ดาวน์โหลดข้อมูลเซนเซอร์ย้อนหลังในรูปแบบ CSV หรือ Excel เพื่อนำไปใช้วิเคราะห์ต่อหรือจัดทำรายงานประจำภาคเรียน',
            style: TextStyle(
              fontSize: 12.5,
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
                          fontSize: 11.5,
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
                          fontSize: 11.5,
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
