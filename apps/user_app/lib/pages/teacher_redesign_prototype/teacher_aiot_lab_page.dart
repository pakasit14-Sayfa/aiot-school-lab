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

  final Map<String, _DeviceStatus> _pendingStatusOverrides = {};

  @override
  void initState() {
    super.initState();
    _loadLabData();
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _devices = [];
          _history = [];
          _sensorReadings = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โหลดข้อมูลแล็บ AIoT ไม่สำเร็จ: $e'),
            backgroundColor: const Color(0xFFEF4444),
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
      if (!mounted) return;
      setState(() {
        _pendingStatusOverrides[device.deviceId] = _DeviceStatus.failed;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งคำสั่งไม่สำเร็จ: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
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
                    fontSize: 14.5,
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

  Widget _buildSensorSection(bool isDesktop) {
    final sensorItems =
        <({String label, String value, IconData icon, Color color})>[];

    for (final r in _sensorReadings) {
      final metric = r['metric'] as String?;
      final val = r['value'];
      if (metric == 'pm25') {
        sensorItems.add((
          label: 'PM2.5',
          value: '$val µg/m³',
          icon: Icons.air_rounded,
          color: TeacherPalette.green,
        ));
      } else if (metric == 'temperature') {
        sensorItems.add((
          label: 'อุณหภูมิ',
          value: '$val °C',
          icon: Icons.thermostat_rounded,
          color: TeacherPalette.orange,
        ));
      } else if (metric == 'humidity') {
        sensorItems.add((
          label: 'ความชื้น',
          value: '$val %RH',
          icon: Icons.water_rounded,
          color: TeacherPalette.blue,
        ));
      }
    }

    if (sensorItems.isEmpty) {
      sensorItems.addAll([
        (
          label: 'PM2.5',
          value: '18 µg/m³',
          icon: Icons.air_rounded,
          color: TeacherPalette.green,
        ),
        (
          label: 'อุณหภูมิ',
          value: '28.5 °C',
          icon: Icons.thermostat_rounded,
          color: TeacherPalette.orange,
        ),
        (
          label: 'ความชื้น',
          value: '62 %RH',
          icon: Icons.water_rounded,
          color: TeacherPalette.blue,
        ),
      ]);
    }

    return _SectionCard(
      title: 'สถานะชุดฝึก AIoT',
      icon: Icons.sensors_rounded,
      trailing: const _LastUpdatedChip(),
      child: LayoutBuilder(
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
                    fontSize: 14.5,
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
              fontSize: 10.5,
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
                    fontSize: 11.5,
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
                          fontSize: 10.5,
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
                fontSize: 15.5,
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
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
