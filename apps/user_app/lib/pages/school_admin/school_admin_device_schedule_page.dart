import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../theme/school_admin_palette.dart';
import 'controllers/school_admin_async_state.dart';
import 'controllers/school_admin_device_schedule_controller.dart';

class SchoolAdminDeviceSchedulePage extends StatefulWidget {
  const SchoolAdminDeviceSchedulePage({
    super.key,
    this.controller,
    this.initialSchedules,
    this.initialDevices,
  });

  final SchoolAdminDeviceScheduleController? controller;
  final List<DeviceSchedule>? initialSchedules;
  final List<DeviceOption>? initialDevices;

  @override
  State<SchoolAdminDeviceSchedulePage> createState() =>
      _SchoolAdminDeviceSchedulePageState();
}

class _SchoolAdminDeviceSchedulePageState
    extends State<SchoolAdminDeviceSchedulePage> {
  late final SchoolAdminDeviceScheduleController _controller;
  late final bool _ownsController;
  List<DeviceSchedule> _schedules = [];
  List<DeviceOption> _devices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _loadError;
  String _actionFilter = 'ทั้งหมด'; // ทั้งหมด, เปิดเครื่อง, ปิดเครื่อง

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        SchoolAdminDeviceScheduleController(
          loadSchedules: DeviceScheduleService.listSchedules,
          loadDevices: LessonService.listSchoolDevices,
          createSchedule: DeviceScheduleService.createSchedule,
          toggleSchedule: DeviceScheduleService.toggleSchedule,
          deleteSchedule: DeviceScheduleService.deleteSchedule,
        );
    _controller.addListener(_syncFromController);
    if (widget.initialSchedules != null) {
      _schedules = widget.initialSchedules!;
      _devices = widget.initialDevices ?? [];
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (widget.initialSchedules != null) return;
    await _controller.load();
  }

  void _syncFromController() {
    if (!mounted) return;
    final state = _controller.state;
    SchoolAdminDeviceScheduleSnapshot? snapshot;
    var isLoading = false;
    String? loadError;

    if (state is SchoolAdminData<SchoolAdminDeviceScheduleSnapshot>) {
      snapshot = state.value;
    } else if (state is SchoolAdminLoading<SchoolAdminDeviceScheduleSnapshot>) {
      snapshot = state.previousData;
      isLoading = state.previousData == null;
    } else if (state is SchoolAdminError<SchoolAdminDeviceScheduleSnapshot>) {
      snapshot = state.previousData;
      loadError = state.message;
    }

    setState(() {
      _isLoading = isLoading;
      _loadError = loadError;
      if (snapshot != null) {
        _schedules = snapshot.schedules;
        _devices = snapshot.devices;
      }
    });
  }

  String _mutationError(String fallback) {
    final state = _controller.state;
    return state is SchoolAdminError<SchoolAdminDeviceScheduleSnapshot>
        ? state.message
        : fallback;
  }

  @override
  void dispose() {
    _controller.removeListener(_syncFromController);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  List<DeviceSchedule> get _filteredSchedules {
    return _schedules.where((s) {
      final query = _searchQuery.trim().toLowerCase();
      final matchQuery =
          query.isEmpty ||
          s.label.toLowerCase().contains(query) ||
          s.deviceName.toLowerCase().contains(query) ||
          s.deviceLocation.toLowerCase().contains(query);

      if (!matchQuery) return false;

      final isOn = s.actionLabel == 'เปิดเครื่อง';
      if (_actionFilter == 'เปิดเครื่อง') {
        return isOn;
      } else if (_actionFilter == 'ปิดเครื่อง') {
        return !isOn;
      }
      return true;
    }).toList();
  }

  int get _onCount =>
      _schedules.where((s) => s.actionLabel == 'เปิดเครื่อง').length;

  int get _offCount =>
      _schedules.where((s) => s.actionLabel == 'ปิดเครื่อง').length;

  void _showAddScheduleDialog() {
    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบรายการอุปกรณ์ในโรงเรียนที่สามารถตั้งเวลาได้'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    String selectedDeviceId = _devices.first.id;
    final labelController = TextEditingController();
    String selectedAction = 'on';
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    List<int> selectedDays = [1, 2, 3, 4, 5]; // Mon-Fri

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final formattedTime =
                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} น.';

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Icon(
                      Icons.alarm_add_rounded,
                      color: SchoolAdminPalette.primaryDark,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ตั้งเวลาอุปกรณ์อัตโนมัติ',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'สร้างตารางเปิด-ปิดอุปกรณ์ด้วย pg_cron Engine',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เลือกอุปกรณ์ที่ต้องการตั้งเวลา',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedDeviceId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        items: _devices.map((d) {
                          return DropdownMenuItem(
                            value: d.id,
                            child: Text(
                              '${d.name} (${d.location ?? "ไม่ระบุตำแหน่ง"})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setDialogState(
                          () => selectedDeviceId = v ?? selectedDeviceId,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ชื่อรายการ / จุดประสงค์',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: labelController,
                        decoration: InputDecoration(
                          hintText: 'เช่น เปิดแอร์ห้อง ม.4/1, ปิดไฟทางเดิน',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'การสั่งงาน (Action)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedAction,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'on',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.power_rounded,
                                  color: Color(0xFF16A34A),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text('เปิดเครื่อง (Power ON)'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'off',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.power_off_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text('ปิดเครื่อง (Power OFF)'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedAction = v ?? 'on'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'เวลาที่ต้องการสั่งงาน',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
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
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'เลือกวันทำงาน',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDayChip('จ.', 1, selectedDays, setDialogState),
                          _buildDayChip('อ.', 2, selectedDays, setDialogState),
                          _buildDayChip('พ.', 3, selectedDays, setDialogState),
                          _buildDayChip('พฤ.', 4, selectedDays, setDialogState),
                          _buildDayChip('ศ.', 5, selectedDays, setDialogState),
                          _buildDayChip('ส.', 6, selectedDays, setDialogState),
                          _buildDayChip('อา.', 7, selectedDays, setDialogState),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
                FilledButton.icon(
                  onPressed: selectedDays.isEmpty
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(dialogContext);
                          final label = labelController.text.trim();
                          if (label.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('กรุณาระบุชื่อรายการ'),
                              ),
                            );
                            return;
                          }
                          final timeStr =
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                          final succeeded = await _controller.create(
                            deviceId: selectedDeviceId,
                            label: label,
                            command: {'action': selectedAction},
                            daysOfWeek: selectedDays,
                            timeOfDay: timeStr,
                          );
                          if (!mounted) return;
                          if (succeeded) {
                            nav.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'บันทึกการตั้งเวลาอัตโนมัติสำเร็จ',
                                ),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  _mutationError('บันทึกตารางเวลาไม่สำเร็จ'),
                                ),
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('บันทึกตารางเวลา'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SchoolAdminPalette.primaryDark,
                    foregroundColor: Colors.white,
                  ),
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
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      selected: isSelected,
      selectedColor: SchoolAdminPalette.primaryDark,
      backgroundColor: const Color(0xFFF8FAFC),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? SchoolAdminPalette.primaryDark
              : const Color(0xFFE2E8F0),
        ),
      ),
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'ยืนยันลบตารางเวลา',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Text(
            'ต้องการลบการตั้งเวลา "${schedule.label.isNotEmpty ? schedule.label : schedule.deviceName}" หรือไม่?',
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(dialogContext);
                final succeeded = await _controller.delete(schedule.id);
                if (!mounted) return;
                if (succeeded) {
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('ลบตารางเวลาเรียบร้อยแล้ว'),
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(_mutationError('ลบตารางเวลาไม่สำเร็จ')),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete_rounded, size: 16),
              label: const Text('ลบตาราง'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  const SizedBox(height: 16),
                  _buildKpiSummaryGrid(),
                  const SizedBox(height: 16),
                  _buildCronInfoBanner(),
                  const SizedBox(height: 16),
                  if (_loadError != null) ...[
                    const SizedBox(height: 16),
                    _buildLoadErrorBanner(),
                  ],
                  _buildFilterBar(),
                  const SizedBox(height: 16),
                  _buildSchedulesList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadError!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _controller.isMutating ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleArea = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SchoolAdminPalette.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: SchoolAdminPalette.primaryDark,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'ตั้งเวลาอุปกรณ์อัตโนมัติ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: Text(
                            '${_schedules.length} ตารางเวลา',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7E22CE),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'บริหารจัดการตารางเวลาเปิด-ปิดอุปกรณ์ IoT อัตโนมัติด้วยระบบเบื้องหลัง pg_cron Engine',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionButtons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _controller.isMutating ? null : _loadData,
                tooltip: 'รีเฟรชข้อมูล',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _devices.isEmpty || _controller.isMutating
                    ? null
                    : _showAddScheduleDialog,
                icon: const Icon(Icons.alarm_add_rounded, size: 16),
                label: const Text('เพิ่มเวลาอัตโนมัติ'),
                style: FilledButton.styleFrom(
                  backgroundColor: SchoolAdminPalette.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 750) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleArea, const SizedBox(height: 14), actionButtons],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleArea),
              const SizedBox(width: 16),
              actionButtons,
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiSummaryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKpiCard(
              title: 'ตารางเวลาทั้งหมด',
              value: '${_schedules.length}',
              subtitle: 'Total Schedules',
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF7E22CE),
              bgColor: const Color(0xFFFAF5FF),
              borderColor: const Color(0xFFF3E8FF),
              width: isMobile
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4,
            ),
            _buildKpiCard(
              title: 'ตารางสั่งเปิดเครื่อง',
              value: '$_onCount',
              subtitle: 'Power ON Jobs',
              icon: Icons.power_rounded,
              color: const Color(0xFF16A34A),
              bgColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFFBBF7D0),
              width: isMobile
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4,
            ),
            _buildKpiCard(
              title: 'ตารางสั่งปิดเครื่อง',
              value: '$_offCount',
              subtitle: 'Power OFF Jobs',
              icon: Icons.power_off_rounded,
              color: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
              width: isMobile
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4,
            ),
            _buildKpiCard(
              title: 'อุปกรณ์ที่ควบคุมได้',
              value: '${_devices.length}',
              subtitle: 'Available Devices',
              icon: Icons.memory_rounded,
              color: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
              width: isMobile
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCronInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.schedule_send_rounded,
              color: Color(0xFF7E22CE),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ระบบเบื้องหลังการทำงาน (Background pg_cron Engine)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'คำสั่งเปิด-ปิดจะถูกประมวลผลและส่งไปยังอุปกรณ์ IoT โดยอัตโนมัติเมื่อถึงเวลาที่กำหนดผ่านระบบคลาวด์ แม้จะปิดแอปพลิเคชันหรือไม่มีผู้ใช้งานออนไลน์',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อรายการ, อุปกรณ์ หรือตำแหน่งที่ตั้ง...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButton<String>(
                value: _actionFilter,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                items: ['ทั้งหมด', 'เปิดเครื่อง', 'ปิดเครื่อง'].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (v) =>
                    setState(() => _actionFilter = v ?? 'ทั้งหมด'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null && _schedules.isEmpty) {
      return const SizedBox.shrink();
    }

    final filtered = _filteredSchedules;
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_off_outlined,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'ยังไม่มีข้อมูล',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _schedules.isEmpty
                  ? 'กดปุ่ม "เพิ่มเวลาอัตโนมัติ" เพื่อสร้างตารางเปิด-ปิดอุปกรณ์'
                  : 'ไม่พบรายการที่ตรงกับคำค้นหาหรือตัวกรอง',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final schedule = filtered[index];
        return _buildScheduleCard(schedule);
      },
    );
  }

  Widget _buildScheduleCard(DeviceSchedule schedule) {
    final isOn = schedule.actionLabel == 'เปิดเครื่อง';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isOn
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFFEF2F2),
            radius: 22,
            child: Icon(
              isOn ? Icons.power_rounded : Icons.power_off_rounded,
              color: isOn ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        schedule.label.isNotEmpty
                            ? schedule.label
                            : schedule.deviceName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isOn
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOn
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Text(
                        schedule.actionLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isOn
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${schedule.deviceName} • ${schedule.deviceLocation}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule.timeOfDay,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _buildDayBadge('จ.', 1, schedule.daysOfWeek),
                          _buildDayBadge('อ.', 2, schedule.daysOfWeek),
                          _buildDayBadge('พ.', 3, schedule.daysOfWeek),
                          _buildDayBadge('พฤ.', 4, schedule.daysOfWeek),
                          _buildDayBadge('ศ.', 5, schedule.daysOfWeek),
                          _buildDayBadge('ส.', 6, schedule.daysOfWeek),
                          _buildDayBadge('อา.', 7, schedule.daysOfWeek),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: schedule.enabled,
            onChanged: _controller.isMutating
                ? null
                : (enabled) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final succeeded = await _controller.toggle(
                      schedule.id,
                      enabled,
                    );
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          succeeded
                              ? (enabled
                                    ? 'เปิดใช้งานตารางเวลาแล้ว'
                                    : 'ปิดใช้งานตารางเวลาแล้ว')
                              : _mutationError(
                                  'เปลี่ยนสถานะตารางเวลาไม่สำเร็จ',
                                ),
                        ),
                        backgroundColor: succeeded
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFDC2626),
            ),
            tooltip: 'ลบตารางเวลา',
            onPressed: _controller.isMutating
                ? null
                : () => _confirmDeleteSchedule(schedule),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBadge(String label, int day, List<int> daysOfWeek) {
    final active = daysOfWeek.contains(day);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? SchoolAdminPalette.primaryDark
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
