import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class SchoolAdminDeviceSchedulePage extends StatefulWidget {
  const SchoolAdminDeviceSchedulePage({super.key});

  @override
  State<SchoolAdminDeviceSchedulePage> createState() =>
      _SchoolAdminDeviceSchedulePageState();
}

class _SchoolAdminDeviceSchedulePageState
    extends State<SchoolAdminDeviceSchedulePage> {
  List<DeviceSchedule> _schedules = [];
  List<DeviceOption> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DeviceScheduleService.listSchedules(),
        LessonService.listSchoolDevices(),
      ]);

      if (mounted) {
        setState(() {
          _schedules = results[0] as List<DeviceSchedule>;
          _devices = results[1] as List<DeviceOption>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddScheduleDialog() {
    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบรายการอุปกรณ์ในโรงเรียนที่สามารถตั้งเวลาได้'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String selectedDeviceId = _devices.first.id;
    final labelController = TextEditingController(text: 'เปิดแอร์ก่อนเริ่มเรียน');
    String selectedAction = 'on';
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    List<int> selectedDays = [1, 2, 3, 4, 5]; // Mon-Fri

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final formattedTime =
                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} น.';

            return AlertDialog(
              title: const Text('ตั้งเวลาอุปกรณ์อัตโนมัติ'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('เลือกอุปกรณ์:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedDeviceId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _devices.map((d) {
                        return DropdownMenuItem(
                          value: d.id,
                          child: Text(
                            '${d.name} (${d.location})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedDeviceId = v);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('ชื่อตารางเวลา:'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'เช่น เปิดแอร์ห้อง 101, ปิดไฟทางเดิน',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('คำสั่งที่ต้องการให้ทำงาน:'),
                    const SizedBox(height: 6),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'on', label: Text('เปิดเครื่อง (ON)')),
                        ButtonSegment(value: 'off', label: Text('ปิดเครื่อง (OFF)')),
                      ],
                      selected: {selectedAction},
                      onSelectionChanged: (newSet) {
                        setDialogState(() => selectedAction = newSet.first);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('เวลาที่ให้ทำงาน (Asia/Bangkok):'),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(formattedTime, style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 14),
                    const Text('วันที่ต้องการให้ทำงาน:'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _buildDayChip('อา.', 0, selectedDays, setDialogState),
                        _buildDayChip('จ.', 1, selectedDays, setDialogState),
                        _buildDayChip('อ.', 2, selectedDays, setDialogState),
                        _buildDayChip('พ.', 3, selectedDays, setDialogState),
                        _buildDayChip('พฤ.', 4, selectedDays, setDialogState),
                        _buildDayChip('ศ.', 5, selectedDays, setDialogState),
                        _buildDayChip('ส.', 6, selectedDays, setDialogState),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: selectedDays.isEmpty
                      ? null
                      : () async {
                          final timeStr =
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';

                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(dialogContext);
                          await DeviceScheduleService.createSchedule(
                            deviceId: selectedDeviceId,
                            label: labelController.text.trim(),
                            command: {'action': selectedAction},
                            daysOfWeek: selectedDays,
                            timeOfDay: timeStr,
                          );

                          nav.pop();
                          if (!mounted) return;
                          _loadData();

                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('บันทึกการตั้งเวลาอัตโนมัติสำเร็จ'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDayChip(
    String label,
    int day,
    List<int> selectedDays,
    void Function(void Function()) setDialogState,
  ) {
    final isSelected = selectedDays.contains(day);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setDialogState(() {
          if (selected) {
            selectedDays.add(day);
          } else {
            selectedDays.remove(day);
          }
        });
      },
    );
  }

  void _confirmDeleteSchedule(DeviceSchedule schedule) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันลบตารางเวลา'),
          content: Text('ต้องการลบการตั้งเวลา "${schedule.label}" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(dialogContext);
                await DeviceScheduleService.deleteSchedule(scheduleId: schedule.id);

                nav.pop();
                if (!mounted) return;
                _loadData();

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('ลบตารางเวลาเรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งเวลาอุปกรณ์อัตโนมัติ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddScheduleDialog,
        icon: const Icon(Icons.add_alarm),
        label: const Text('เพิ่มเวลาอัตโนมัติ'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info banner
                  _buildCronInfoBanner(),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ตารางเวลาทั้งหมด (${_schedules.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_schedules.isEmpty)
                    _buildEmptyState()
                  else
                    ..._schedules.map((s) => _buildScheduleCard(s)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildCronInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.deepPurple.shade700),
              const SizedBox(width: 8),
              Text(
                'ระบบเบื้องหลัง (Background pg_cron Engine)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'คำสั่งจะถูกส่งไปยังอุปกรณ์โดยอัตโนมัติทุกนาทีเมื่อถึงเวลาที่กำหนด ไม่จำเป็นต้องเปิดแอปค้างไว้',
            style: TextStyle(
              fontSize: 13,
              color: Colors.deepPurple.shade900,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.timer_off_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'ยังไม่มีการตั้งเวลาอัตโนมัติ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'กดปุ่ม "เพิ่มเวลาอัตโนมัติ" เพื่อสร้างตารางเปิด-ปิดอุปกรณ์',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(DeviceSchedule schedule) {
    final isOn = schedule.actionLabel == 'เปิดเครื่อง';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      isOn ? Colors.green.shade100 : Colors.red.shade100,
                  radius: 20,
                  child: Icon(
                    isOn ? Icons.power : Icons.power_off,
                    color: isOn ? Colors.green.shade800 : Colors.red.shade800,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.label.isNotEmpty
                            ? schedule.label
                            : schedule.deviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${schedule.deviceName} • ${schedule.deviceLocation}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: schedule.enabled,
                  onChanged: (val) async {
                    await DeviceScheduleService.toggleSchedule(
                      scheduleId: schedule.id,
                      enabled: val,
                    );
                    _loadData();
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.purple),
                    const SizedBox(width: 6),
                    Text(
                      schedule.timeFormatted,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.calendar_today, size: 16, color: Colors.purple),
                    const SizedBox(width: 6),
                    Text(
                      schedule.daysFormatted,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'ลบตารางเวลา',
                  onPressed: () => _confirmDeleteSchedule(schedule),
                ),
              ],
            ),
            if (schedule.lastTriggeredAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'ทำงานล่าสุดเมื่อ: ${schedule.lastTriggeredAt!.hour.toString().padLeft(2, '0')}:${schedule.lastTriggeredAt!.minute.toString().padLeft(2, '0')} น.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
