// PROTOTYPE ONLY: "AIoT Lab Control" — UI mock for teachers to monitor and
// toggle the AIoT training-kit hardware (sensor board, relay, simulated
// water pump / lights) used to teach students. This is explicitly NOT a
// real building-management system — every device here is scoped to the
// lab kit, and every control action requires an explicit confirmation
// naming that scope. No backend/hardware is wired up; state lives only in
// this widget's memory.

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;

enum _DeviceStatus { on, off, pending, failed }

extension on _DeviceStatus {
  String get label => switch (this) {
    _DeviceStatus.on => 'เปิดอยู่',
    _DeviceStatus.off => 'ปิดอยู่',
    _DeviceStatus.pending => 'รอดำเนินการ',
    _DeviceStatus.failed => 'ล้มเหลว',
  };

  // "เปิดอยู่" ใช้ฟ้าเข้ม (ธีมหลัก) แทนเขียว — เดิมทั้งหน้าดูเขียวจัด
  // เพราะสถานะ "on" ของทั้ง 3 อุปกรณ์ใช้สีเดียวกับ semantic success ปกติ
  // ทำให้หลุดโทนฟ้าที่เหลือทั้งแอป ส่วน "ล้มเหลว" ยังคงเป็นแดงไว้เพราะ
  // เป็น semantic อันตรายที่ต้องเด่นแยกจากสีธีมเสมอ
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

class _LabDevice {
  _LabDevice({
    required this.name,
    required this.description,
    required this.icon,
    required this.status,
  });

  final String name;
  final String description;
  final IconData icon;
  _DeviceStatus status;
}

class _ControlLogEntry {
  const _ControlLogEntry({
    required this.deviceName,
    required this.action,
    required this.actor,
    required this.time,
    required this.result,
  });

  final String deviceName;
  final String action;
  final String actor;
  final String time;
  final _DeviceStatus result;
}

class TeacherAiotLabPage extends StatefulWidget {
  const TeacherAiotLabPage({super.key});

  @override
  State<TeacherAiotLabPage> createState() => _TeacherAiotLabPageState();
}

class _TeacherAiotLabPageState extends State<TeacherAiotLabPage> {
  final List<_LabDevice> _devices = [
    _LabDevice(
      name: 'ไฟชุดฝึก',
      description: 'ไฟ LED จำลองบนบอร์ดชุดฝึก AIoT',
      icon: Icons.lightbulb_rounded,
      status: _DeviceStatus.on,
    ),
    _LabDevice(
      name: 'ปั๊มน้ำจำลอง',
      description: 'ปั๊มน้ำขนาดเล็กสำหรับสาธิตระบบรดน้ำอัตโนมัติ',
      icon: Icons.water_drop_rounded,
      status: _DeviceStatus.off,
    ),
    _LabDevice(
      name: 'รีเลย์ควบคุม',
      description: 'รีเลย์ทดลองสำหรับสลับวงจรอุปกรณ์บนชุดฝึก',
      icon: Icons.toggle_on_rounded,
      status: _DeviceStatus.on,
    ),
  ];

  final List<_ControlLogEntry> _history = const [
    _ControlLogEntry(
      deviceName: 'ไฟชุดฝึก',
      action: 'เปิด',
      actor: 'ครูสมชาย สายวิทย์',
      time: 'วันนี้ 10:24 น.',
      result: _DeviceStatus.on,
    ),
    _ControlLogEntry(
      deviceName: 'รีเลย์ควบคุม',
      action: 'เปิด',
      actor: 'ครูสมชาย สายวิทย์',
      time: 'วันนี้ 09:58 น.',
      result: _DeviceStatus.on,
    ),
    _ControlLogEntry(
      deviceName: 'ปั๊มน้ำจำลอง',
      action: 'ปิด',
      actor: 'ครูวราภรณ์ เลิศคณิต',
      time: 'เมื่อวาน 15:10 น.',
      result: _DeviceStatus.off,
    ),
    _ControlLogEntry(
      deviceName: 'ปั๊มน้ำจำลอง',
      action: 'เปิด',
      actor: 'ครูวราภรณ์ เลิศคณิต',
      time: 'เมื่อวาน 15:09 น.',
      result: _DeviceStatus.failed,
    ),
  ];

  Future<void> _toggleDevice(_LabDevice device) async {
    final turningOn = device.status != _DeviceStatus.on;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) =>
          _LabConfirmDialog(deviceName: device.name, turningOn: turningOn),
    );
    if (confirmed != true || !mounted) return;

    setState(() => device.status = _DeviceStatus.pending);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      device.status = turningOn ? _DeviceStatus.on : _DeviceStatus.off;
      _history.insert(
        0,
        _ControlLogEntry(
          deviceName: device.name,
          action: turningOn ? 'เปิด' : 'ปิด',
          actor: 'ครูสมชาย สายวิทย์ (คุณ)',
          time: 'เมื่อสักครู่',
          result: device.status,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherPalette.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: TeacherPalette.ink,
        title: const Text(
          'AIoT Lab Control',
          style: TextStyle(
            color: TeacherPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 980 : 640),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Column(
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
                  ),
                ),
              );
            },
          ),
        ),
      ),
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
                  'โหมดชุดฝึก — ยังไม่ใช่ระบบควบคุมอาคารจริง',
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
    final sensors = [
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
      (
        label: 'UV',
        value: 'ระดับ 2',
        icon: Icons.wb_sunny_rounded,
        color: TeacherPalette.violet,
      ),
    ];

    return _SectionCard(
      title: 'สถานะชุดฝึก AIoT',
      icon: Icons.sensors_rounded,
      trailing: const _LastUpdatedChip(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = isDesktop ? 4 : 2;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              for (final s in sensors)
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

  // กลับมาเป็นลิสต์แถวแนวนอนแบบเดิม — ลอง grid ไทล์สี่เหลี่ยมตาม
  // reference แล้วแต่ละไทล์เหลือพื้นที่ว่างตรงกลางเยอะเกินไป (ไอคอนอยู่
  // บน label อยู่ล่างสุด ตรงกลางไม่มีอะไรเลย) ลิสต์แถวให้ข้อมูลแน่นกว่า
  // และไม่มีที่ว่างเหลือทิ้งขว้าง
  Widget _buildControlSection(bool isDesktop) {
    return _SectionCard(
      title: 'ควบคุมอุปกรณ์ชุดฝึก',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          for (var i = 0; i < _devices.length; i++) ...[
            _DeviceControlRow(
              device: _devices[i],
              onToggle: () => _toggleDevice(_devices[i]),
            ),
            if (i != _devices.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
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
          // จุดเขียวคงไว้ตั้งใจ — เป็น convention มาตรฐาน "online/live"
          // แยกจากสีธีมหลัก ไม่ใช่ค่าเริ่มต้นที่ลืมเปลี่ยน
          Icon(Icons.circle, size: 7, color: TeacherPalette.green),
          SizedBox(width: 5),
          Text(
            'อัปเดตล่าสุด 2 นาทีที่แล้ว',
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

/// การ์ดสี่เหลี่ยมที่พื้นเปลี่ยนเป็นสีทึบตอนเปิดอยู่ (ปรับจากไทล์
/// "Light/Water/Electric" ใน reference kit ที่ทีมส่งมา) แทนแถวยาวแบบเดิม
/// — กดที่ไทล์เพื่อสลับเปิด/ปิด ผ่าน dialog ยืนยันเหมือนเดิมทุกอย่าง
class _DeviceControlRow extends StatelessWidget {
  const _DeviceControlRow({required this.device, required this.onToggle});

  final _LabDevice device;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final status = device.status;
    final isBusy = status == _DeviceStatus.pending;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: status.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: status.color.withValues(alpha: 0.3)),
            ),
            child: Icon(device.icon, color: status.color, size: 20),
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
                  device.description,
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
                      color: status.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 12, color: status.color),
                      const SizedBox(width: 4),
                      Text(
                        status.label,
                        style: TextStyle(
                          color: status.color,
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
            value: status == _DeviceStatus.on,
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
        'คำสั่งนี้ใช้กับชุดฝึก AIoT เท่านั้น ไม่ใช่ระบบอาคารจริง',
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

  final _ControlLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final status = entry.result;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: status.bg, shape: BoxShape.circle),
          child: Icon(status.icon, size: 16, color: status.color),
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
                      text: '${entry.actor} ',
                      style: const TextStyle(
                        color: TeacherPalette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: '${entry.action}${entry.deviceName}',
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
                entry.time,
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
            color: status.bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
