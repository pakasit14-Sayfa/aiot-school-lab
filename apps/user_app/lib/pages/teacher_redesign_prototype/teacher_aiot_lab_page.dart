// "AIoT Lab Control" — Teacher UI for monitoring and controlling AIoT
// training-kit hardware (sensor board, relay, simulated water pump / lights)
// used to teach students. Every device here is scoped to classroom teaching kits.

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

enum _DeviceStatus { on, off, pending, failed }

extension on _DeviceStatus {
  String get label => switch (this) {
    _DeviceStatus.on => 'เปิดอยู่',
    _DeviceStatus.off => 'ปิดอยู่',
    _DeviceStatus.pending => 'รอดำเนินการ',
    _DeviceStatus.failed => 'ล้มเหลว',
  };

  Color get color => switch (this) {
    _DeviceStatus.on => TeacherPalette.primary,
    _DeviceStatus.off => TeacherPalette.muted,
    _DeviceStatus.pending => TeacherPalette.skySoft,
    _DeviceStatus.failed => TeacherPalette.red,
  };

  Color get bg => switch (this) {
    _DeviceStatus.on => const Color(0xFFE3F1FA),
    _DeviceStatus.off => const Color(0xFFF1F5F9),
    _DeviceStatus.pending => const Color(0xFFEFF9FF),
    _DeviceStatus.failed => const Color(0xFFFEF2F2),
  };

  IconData get icon => switch (this) {
    _DeviceStatus.on => Icons.check_circle_rounded,
    _DeviceStatus.off => Icons.radio_button_unchecked_rounded,
    _DeviceStatus.pending => Icons.hourglass_top_rounded,
    _DeviceStatus.failed => Icons.error_rounded,
  };
}

class TeacherAiotLabPage extends StatefulWidget {
  const TeacherAiotLabPage({super.key});

  @override
  State<TeacherAiotLabPage> createState() => _TeacherAiotLabPageState();
}

class _TeacherAiotLabPageState extends State<TeacherAiotLabPage> {
  bool _isLoading = true;
  List<AiotLabDeviceItem> _devices = [];
  List<AiotCommandHistoryItem> _history = [];
  List<Map<String, dynamic>> _sensorReadings = [];
  List<WiringGroupItem> _wiringGroups = [];
  bool _loadingGroups = false;

  final Map<String, _DeviceStatus> _pendingStatusOverrides = {};

  @override
  void initState() {
    super.initState();
    _loadLabData();
  }

  List<String> get _courseIds =>
      _devices.map((d) => d.courseId).toSet().toList();

  Future<void> _loadWiringGroups() async {
    setState(() => _loadingGroups = true);
    try {
      final groups = <WiringGroupItem>[];
      for (final courseId in _courseIds) {
        groups.addAll(await WiringGroupService.listWiringGroups(courseId));
      }
      if (!mounted) return;
      setState(() {
        _wiringGroups = groups;
        _loadingGroups = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingGroups = false);
    }
  }

  Future<void> _loadLabData() async {
    setState(() => _isLoading = true);
    try {
      final devices = await AiotLabService.listTeachingKitDevices();
      final history = await AiotLabService.listTeachingKitCommandHistory();
      final sensors = await AiotLabService.getLatestSensorReadings();

      if (mounted) {
        setState(() {
          _devices = devices;
          _history = history;
          _sensorReadings = sensors;
          _isLoading = false;
        });
      }
      await _loadWiringGroups();
    } catch (e) {
      debugPrint('Error loading AIoT lab data: $e');
      if (mounted) {
        setState(() {
          _devices = [];
          _history = [];
          _sensorReadings = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('โหลดข้อมูลแล็บ AIoT ไม่สำเร็จ'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _toggleDevice(AiotLabDeviceItem device) async {
    final currentOverride = _pendingStatusOverrides[device.deviceId];
    final isCurrentlyOn =
        currentOverride == _DeviceStatus.on ||
        (currentOverride == null && device.status == 'online');
    final turningOn = !isCurrentlyOn;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) =>
          _LabConfirmDialog(deviceName: device.name, turningOn: turningOn),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _pendingStatusOverrides[device.deviceId] = _DeviceStatus.pending;
    });

    try {
      await AiotLabService.queueTeachingKitCommand(
        deviceId: device.deviceId,
        command: {'relay': 1, 'action': turningOn ? 'turn_on' : 'turn_off'},
      );

      if (!mounted) return;
      setState(() {
        _pendingStatusOverrides[device.deviceId] = turningOn
            ? _DeviceStatus.on
            : _DeviceStatus.off;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ส่งคำสั่ง ${turningOn ? "เปิด" : "ปิด"} ${device.name} ไปยังชุดฝึกเรียบร้อย',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      _loadLabData();
    } catch (e) {
      debugPrint('Error sending device command: $e');
      if (!mounted) return;
      setState(() {
        _pendingStatusOverrides[device.deviceId] = _DeviceStatus.failed;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ส่งคำสั่งไม่สำเร็จ'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _openCreateGroupDialog() async {
    final kitCodes = _devices
        .map((d) => d.kitCode)
        .whereType<String>()
        .toSet()
        .toList();
    if (kitCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีชุดฝึกที่กำหนดรหัสไว้')),
      );
      return;
    }

    final result = await showDialog<({String kitCode, String name})>(
      context: context,
      builder: (dialogContext) => _CreateWiringGroupDialog(kitCodes: kitCodes),
    );
    if (result == null || !mounted) return;

    final device = _devices.firstWhere((d) => d.kitCode == result.kitCode);
    try {
      await WiringGroupService.createWiringGroup(
        courseId: device.courseId,
        kitCode: result.kitCode,
        name: result.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('สร้างกลุ่มต่อสายแล้ว')));
      await _loadWiringGroups();
    } catch (e) {
      debugPrint('Error creating wiring group: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('สร้างกลุ่มไม่สำเร็จ')));
    }
  }

  Future<void> _changeGroupStatus(WiringGroupItem group, String status) async {
    try {
      await WiringGroupService.setWiringGroupStatus(
        groupId: group.groupId,
        status: status,
      );
      await _loadWiringGroups();
    } catch (e) {
      debugPrint('Error changing wiring group status: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เปลี่ยนสถานะไม่สำเร็จ')));
    }
  }

  Future<void> _deleteGroup(WiringGroupItem group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบกลุ่มต่อสาย'),
        content: Text('ต้องการลบ "${group.name}" ใช่หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: TeacherPalette.red,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await WiringGroupService.deleteWiringGroup(group.groupId);
      await _loadWiringGroups();
    } catch (e) {
      debugPrint('Error deleting wiring group: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบไม่สำเร็จ')));
    }
  }

  Future<void> _openMembersSheet(WiringGroupItem group) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          _WiringGroupMembersSheet(group: group, courseId: group.courseId),
    );
    await _loadWiringGroups();
  }

  Widget _buildWiringGroupsSection() {
    return _SectionCard(
      title: 'กลุ่มต่อสาย (Wiring Groups)',
      icon: Icons.groups_2_rounded,
      trailing: TextButton.icon(
        onPressed: _openCreateGroupDialog,
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('สร้างกลุ่ม'),
        style: TextButton.styleFrom(foregroundColor: TeacherPalette.primary),
      ),
      child: _loadingGroups
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: TeacherPalette.primary),
              ),
            )
          : _wiringGroups.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: const Column(
                children: [
                  Icon(
                    Icons.cable_rounded,
                    size: 36,
                    color: TeacherPalette.muted,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ยังไม่มีกลุ่มต่อสาย — สร้างกลุ่มแรกของคุณ',
                    style: TextStyle(
                      fontSize: 13,
                      color: TeacherPalette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < _wiringGroups.length; i++) ...[
                  _WiringGroupCard(
                    group: _wiringGroups[i],
                    onStatusChange: (status) =>
                        _changeGroupStatus(_wiringGroups[i], status),
                    onManageMembers: () =>
                        _openMembersSheet(_wiringGroups[i]),
                    onDelete: () => _deleteGroup(_wiringGroups[i]),
                  ),
                  if (i != _wiringGroups.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'AIoT Lab Control',
      activeMenuLabel: 'Wiring Lab',
      builder: (context, isDesktop) {
        if (_isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabModeBanner(),
            const SizedBox(height: 16),
            _buildSensorSection(isDesktop),
            const SizedBox(height: 16),
            _buildControlSection(isDesktop),
            const SizedBox(height: 16),
            _buildWiringGroupsSection(),
            const SizedBox(height: 16),
            _buildHistorySection(),
          ],
        );
      },
    );
  }

  Widget _buildLabModeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TeacherPalette.primary, TeacherPalette.primary2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.science_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lab Mode — ใช้สำหรับชุดฝึก AIoT เท่านั้น',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'โหมดชุดฝึก — ผูกกับรายวิชาที่สอน ควบคุมเฉพาะอุปกรณ์ชุดคิตห้องเรียน',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // อัปเดตค่าล่าสุดต่อ metric เดียว — sensor_latest คืนแถวล่าสุดต่อ (device,
  // metric) อยู่แล้ว แต่ถ้ามีหลายอุปกรณ์ส่ง metric เดียวกันซ้ำ เอาแถวที่มี ts
  // ใหม่สุดของแต่ละ metric มาโชว์
  Map<String, dynamic> get _latestByMetric {
    final byMetric = <String, Map<String, dynamic>>{};
    for (final r in _sensorReadings) {
      final metric = r['metric'] as String?;
      if (metric == null) continue;
      final ts = DateTime.tryParse(r['ts'] as String? ?? '');
      final prev = byMetric[metric];
      final prevTs = prev == null
          ? null
          : DateTime.tryParse(prev['ts'] as String? ?? '');
      if (prev == null || (ts != null && (prevTs == null || ts.isAfter(prevTs)))) {
        byMetric[metric] = r;
      }
    }
    return byMetric.map((k, v) => MapEntry(k, v['value']));
  }

  static String _fmt(dynamic v, {int decimals = 1}) {
    if (v is num) return v.toStringAsFixed(decimals);
    return '$v';
  }

  Widget _buildSensorSection(bool isDesktop) {
    final latest = _latestByMetric;
    final sensorItems =
        <({String label, String value, IconData icon, Color color})>[];

    void addIfPresent(
      String metric,
      String label,
      String Function(dynamic val) formatValue,
      IconData icon,
      Color color,
    ) {
      if (!latest.containsKey(metric)) return;
      sensorItems.add((
        label: label,
        value: formatValue(latest[metric]),
        icon: icon,
        color: color,
      ));
    }

    addIfPresent(
      'pm25',
      'PM2.5',
      (v) => '${_fmt(v)} µg/m³',
      Icons.air_rounded,
      TeacherPalette.green,
    );
    addIfPresent(
      'temperature',
      'อุณหภูมิ',
      (v) => '${_fmt(v)} °C',
      Icons.thermostat_rounded,
      TeacherPalette.orange,
    );
    addIfPresent(
      'humidity',
      'ความชื้น',
      (v) => '${_fmt(v)} %RH',
      Icons.water_rounded,
      TeacherPalette.blue,
    );
    addIfPresent(
      'light_lux',
      'ความสว่าง',
      (v) => '${_fmt(v)} lux',
      Icons.wb_sunny_rounded,
      TeacherPalette.sky,
    );
    addIfPresent(
      'aqi',
      'ดัชนีคุณภาพอากาศ (AQI)',
      (v) => _fmt(v, decimals: 0),
      Icons.eco_rounded,
      TeacherPalette.primary,
    );
    // ห้ามแสดงเป็น "แก๊ส X%" — ค่านี้คือ % ช่วง ADC ของ MQ-2 ไม่ใช่ %ความเข้ม
    // ของแก๊ส จนกว่าจะ calibrate เป็น ppm จริง (ดู
    // docs handoff / hardware integration spec ข้อ 20.1 และ 28.9)
    addIfPresent(
      'gas_mq2_percent',
      'MQ-2 (ระดับสัญญาณ ADC)',
      (v) => '${_fmt(v)} %',
      Icons.warning_amber_rounded,
      TeacherPalette.red,
    );
    addIfPresent(
      'water_flow_lmin',
      'อัตราการไหลน้ำ',
      (v) => '${_fmt(v)} L/min',
      Icons.water_drop_rounded,
      TeacherPalette.skyDeep,
    );
    addIfPresent(
      'water_volume_l',
      'ปริมาตรน้ำสะสม',
      (v) => '${_fmt(v)} L',
      Icons.opacity_rounded,
      TeacherPalette.skyBright,
    );

    return _SectionCard(
      title: 'สถานะชุดฝึก AIoT',
      icon: Icons.sensors_rounded,
      trailing: sensorItems.isEmpty ? null : const _LastUpdatedChip(),
      child: sensorItems.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: const Column(
                children: [
                  Icon(
                    Icons.sensors_off_rounded,
                    size: 36,
                    color: TeacherPalette.muted,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ยังไม่มีข้อมูลเซนเซอร์จากชุดฝึก',
                    style: TextStyle(
                      fontSize: 13,
                      color: TeacherPalette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = isDesktop ? 3 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    for (final s in sensorItems)
                      _SensorTile(
                        label: s.label,
                        value: s.value,
                        icon: s.icon,
                        color: s.color,
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildControlSection(bool isDesktop) {
    if (_devices.isEmpty) {
      return _SectionCard(
        title: 'ควบคุมอุปกรณ์ชุดฝึก',
        icon: Icons.tune_rounded,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: const Column(
            children: [
              Icon(
                Icons.devices_other_rounded,
                size: 36,
                color: TeacherPalette.muted,
              ),
              SizedBox(height: 8),
              Text(
                'ไม่พบอุปกรณ์ชุดฝึกที่ลงทะเบียนในรายวิชานี้',
                style: TextStyle(
                  fontSize: 13,
                  color: TeacherPalette.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _SectionCard(
      title: 'ควบคุมอุปกรณ์ชุดฝึก',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          for (var i = 0; i < _devices.length; i++) ...[
            _DeviceControlRow(
              device: _devices[i],
              statusOverride: _pendingStatusOverrides[_devices[i].deviceId],
              onToggle: () => _toggleDevice(_devices[i]),
            ),
            if (i != _devices.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) {
      return _SectionCard(
        title: 'ประวัติการควบคุมล่าสุด',
        icon: Icons.history_rounded,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              'ยังไม่มีประวัติการควบคุมชุดฝึก',
              style: TextStyle(
                fontSize: 13,
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return _SectionCard(
      title: 'ประวัติการควบคุมล่าสุด',
      icon: Icons.history_rounded,
      child: Column(
        children: [
          for (var i = 0; i < _history.length; i++) ...[
            _HistoryRow(entry: _history[i]),
            if (i != _history.length - 1)
              const Divider(height: 18, color: Color(0xFFE8EEF3)),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: TeacherPalette.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LastUpdatedChip extends StatelessWidget {
  const _LastUpdatedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F1FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: TeacherPalette.green),
          SizedBox(width: 5),
          Text(
            'ข้อมูลสด (Live)',
            style: TextStyle(
              color: TeacherPalette.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorTile extends StatelessWidget {
  const _SensorTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: TeacherPalette.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: TeacherPalette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceControlRow extends StatelessWidget {
  const _DeviceControlRow({
    required this.device,
    required this.onToggle,
    this.statusOverride,
  });

  final AiotLabDeviceItem device;
  final VoidCallback onToggle;
  final _DeviceStatus? statusOverride;

  @override
  Widget build(BuildContext context) {
    final effectiveStatus =
        statusOverride ??
        (device.status == 'online' ? _DeviceStatus.on : _DeviceStatus.off);
    final isBusy = effectiveStatus == _DeviceStatus.pending;

    final IconData iconData = switch (device.type) {
      'relay' => Icons.toggle_on_rounded,
      'pm25_sensor' => Icons.air_rounded,
      _ => Icons.lightbulb_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: effectiveStatus.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: effectiveStatus.color.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: effectiveStatus.color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(iconData, color: effectiveStatus.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${device.location} · ${device.courseName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: effectiveStatus.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        effectiveStatus.icon,
                        size: 12,
                        color: effectiveStatus.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        effectiveStatus.label,
                        style: TextStyle(
                          color: effectiveStatus.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: effectiveStatus == _DeviceStatus.on,
            onChanged: isBusy ? null : (_) => onToggle(),
            activeTrackColor: TeacherPalette.primary,
          ),
        ],
      ),
    );
  }
}

class _LabConfirmDialog extends StatelessWidget {
  const _LabConfirmDialog({required this.deviceName, required this.turningOn});

  final String deviceName;
  final bool turningOn;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: TeacherPalette.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              turningOn
                  ? 'ยืนยันเปิด "$deviceName"'
                  : 'ยืนยันปิด "$deviceName"',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: TeacherPalette.ink,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'คำสั่งนี้ใช้กับชุดฝึก AIoT เท่านั้น ไม่ใช่อุปกรณ์อาคารจริง',
        style: TextStyle(
          color: TeacherPalette.muted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: TeacherPalette.muted),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: TeacherPalette.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('ยืนยัน'),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final AiotCommandHistoryItem entry;

  @override
  Widget build(BuildContext context) {
    final actionStr = (entry.command['action'] as String?) == 'turn_off'
        ? 'ปิด'
        : 'เปิด';
    final timeStr =
        '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')} น.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFE3F1FA),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: TeacherPalette.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${entry.createdByName} ',
                      style: const TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: '$actionStr${entry.deviceName}',
                      style: const TextStyle(
                        color: TeacherPalette.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: const TextStyle(
                  color: TeacherPalette.softText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F1FA),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            actionStr,
            style: const TextStyle(
              color: TeacherPalette.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// สถานะกลุ่มต่อสาย ต้องตรงกับ state machine ฝั่ง SQL ใน
// set_wiring_group_status ทุกประการ (ไม่งั้นปุ่มที่โชว์ในนี้จะเสนอ
// การเปลี่ยนสถานะที่ server จะปฏิเสธ):
// wiring -> passed|failed, failed -> wiring|passed,
// passed -> running|wiring|failed, running -> wiring
const Map<String, List<String>> _wiringLegalTransitions = {
  'wiring': ['passed', 'failed'],
  'failed': ['wiring', 'passed'],
  'passed': ['running', 'wiring', 'failed'],
  'running': ['wiring'],
};

const Map<String, String> _wiringStatusLabel = {
  'wiring': 'กำลังต่อสาย',
  'passed': 'ผ่านการตรวจ',
  'failed': 'ต้องตรวจสอบ',
  'running': 'กำลังรันระบบจริง',
};

const Map<String, Color> _wiringStatusColor = {
  'wiring': TeacherPalette.skyMid,
  'passed': TeacherPalette.green,
  'failed': TeacherPalette.red,
  'running': TeacherPalette.primary,
};

class _WiringGroupCard extends StatelessWidget {
  const _WiringGroupCard({
    required this.group,
    required this.onStatusChange,
    required this.onManageMembers,
    required this.onDelete,
  });

  final WiringGroupItem group;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onManageMembers;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _wiringStatusColor[group.status] ?? TeacherPalette.muted;
    final legalNext = _wiringLegalTransitions[group.status] ?? const [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'ชุดฝึก ${group.kitCode} · ${group.kitOnlineCount}/${group.kitDeviceCount} ออนไลน์',
                      style: const TextStyle(
                        color: TeacherPalette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _wiringStatusLabel[group.status] ?? group.status,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: TeacherPalette.muted,
                tooltip: 'ลบกลุ่ม',
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onManageMembers,
            borderRadius: BorderRadius.circular(12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in group.members)
                  Chip(
                    label: Text(
                      m.studentName,
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: TeacherPalette.skyLight,
                  ),
                ActionChip(
                  label: const Text(
                    'จัดการสมาชิก',
                    style: TextStyle(fontSize: 11),
                  ),
                  avatar: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                  onPressed: onManageMembers,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          if (legalNext.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                for (final next in legalNext)
                  OutlinedButton(
                    onPressed: () => onStatusChange(next),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _wiringStatusColor[next],
                      side: BorderSide(
                        color:
                            (_wiringStatusColor[next] ?? TeacherPalette.muted)
                                .withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'เปลี่ยนเป็น ${_wiringStatusLabel[next]}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
          if (group.inspectionNote != null &&
              group.inspectionNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'บันทึกการตรวจ: ${group.inspectionNote}',
              style: const TextStyle(
                color: TeacherPalette.softText,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateWiringGroupDialog extends StatefulWidget {
  const _CreateWiringGroupDialog({required this.kitCodes});

  final List<String> kitCodes;

  @override
  State<_CreateWiringGroupDialog> createState() =>
      _CreateWiringGroupDialogState();
}

class _CreateWiringGroupDialogState extends State<_CreateWiringGroupDialog> {
  String? _kitCode;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _kitCode = widget.kitCodes.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'สร้างกลุ่มต่อสาย',
        style: TextStyle(fontWeight: FontWeight.w900, color: TeacherPalette.ink),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _kitCode,
            decoration: const InputDecoration(labelText: 'ชุดฝึก (kit)'),
            items: widget.kitCodes
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
            onChanged: (v) => setState(() => _kitCode = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'ชื่อกลุ่ม'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (_kitCode == null || name.isEmpty) return;
            Navigator.pop(context, (kitCode: _kitCode!, name: name));
          },
          style: FilledButton.styleFrom(backgroundColor: TeacherPalette.primary),
          child: const Text('สร้าง'),
        ),
      ],
    );
  }
}

class _WiringGroupMembersSheet extends StatefulWidget {
  const _WiringGroupMembersSheet({required this.group, required this.courseId});

  final WiringGroupItem group;
  final String courseId;

  @override
  State<_WiringGroupMembersSheet> createState() =>
      _WiringGroupMembersSheetState();
}

class _WiringGroupMembersSheetState extends State<_WiringGroupMembersSheet> {
  List<CourseStudent>? _roster;
  late Set<String> _memberIds;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _memberIds = widget.group.members.map((m) => m.studentId).toSet();
    _load();
  }

  Future<void> _load() async {
    try {
      final roster = await CourseService.listCourseStudents(widget.courseId);
      if (!mounted) return;
      setState(() => _roster = roster);
    } catch (_) {
      if (!mounted) return;
      setState(() => _roster = []);
    }
  }

  Future<void> _toggle(String studentId, bool isMember) async {
    setState(() => _busy = true);
    try {
      if (isMember) {
        await WiringGroupService.removeWiringGroupMember(
          groupId: widget.group.groupId,
          studentId: studentId,
        );
        _memberIds.remove(studentId);
      } else {
        await WiringGroupService.addWiringGroupMember(
          groupId: widget.group.groupId,
          studentId: studentId,
        );
        _memberIds.add(studentId);
      }
    } catch (e) {
      // เดิมเงียบสนิท — ครูกดเพิ่ม/เอานักเรียนออกจากกลุ่มแล้วชีตตอบสนอง
      // เหมือนสำเร็จ ทั้งที่ RPC พัง กว่าจะรู้ก็ตอนโหลดใหม่หลังปิดชีต
      debugPrint('teacher_aiot_lab_page: toggle wiring group member failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMember
                  ? 'นำนักเรียนออกจากกลุ่มไม่สำเร็จ กรุณาลองใหม่'
                  : 'เพิ่มนักเรียนเข้ากลุ่มไม่สำเร็จ กรุณาลองใหม่',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roster = _roster;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: TeacherPalette.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(
            'สมาชิกกลุ่ม "${widget.group.name}"',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: TeacherPalette.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (roster == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (roster.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'ยังไม่มีนักเรียนลงทะเบียนในวิชานี้',
                style: TextStyle(color: TeacherPalette.muted),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: roster.length,
                itemBuilder: (context, index) {
                  final student = roster[index];
                  final isMember = _memberIds.contains(student.studentId);
                  return CheckboxListTile(
                    value: isMember,
                    onChanged: _busy
                        ? null
                        : (_) => _toggle(student.studentId, isMember),
                    title: Text('${student.firstName} ${student.lastName}'),
                    activeColor: TeacherPalette.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
