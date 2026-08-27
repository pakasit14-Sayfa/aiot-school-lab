import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

class SchoolDevicesPage extends StatefulWidget {
  const SchoolDevicesPage({super.key});

  @override
  State<SchoolDevicesPage> createState() => _SchoolDevicesPageState();
}

class _SchoolDevicesPageState extends State<SchoolDevicesPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'ทุกประเภท';
  String _selectedBuilding = 'ทุกอาคาร';
  String _selectedStatus = 'ทุกสถานะ';
  bool _filterIssuesOnly = false;

  List<_DeviceRecord> _devices = [];
  List<_DeviceLogRecord> _logs = [];
  

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    
    try {
      final devices = await RealtimeService.listSchoolDevices();
      final logs = await SchoolAdminPlatformService().fetchAuditLogs(limit: 6);
      if (mounted) {
        setState(() {
          if (devices.isNotEmpty) {
            _devices = devices.map((d) {
              final shortId = d.id.length >= 4 ? d.id.substring(0, 4) : d.id;
              final cat = _mapCategory(d.type);
              return _DeviceRecord(
                id: d.id,
                deviceCode: 'DEV-${d.type.toUpperCase()}-$shortId',
                name: d.name,
                category: cat,
                model: d.type,
                serialNumber: 'SN-${d.id.hashCode.abs().toString().padLeft(8, "0")}',
                building: (d.location != null && d.location!.isNotEmpty)
                    ? d.location!
                    : 'ไม่ระบุอาคาร',
                room: 'ห้องปฏิบัติการ',
                trainingKit: 'ชุดฝึก AIoT Lab',
                status: d.status == 'online' ? 'ออนไลน์' : 'ออฟไลน์',
                health: d.status == 'online' ? 'ปกติ' : 'ต้องตรวจสอบ',
                lastSeen: d.status == 'online' ? 'เมื่อสักครู่' : '2 วันที่แล้ว',
                ipAddress: '192.168.1.${(d.id.hashCode.abs() % 200) + 10}',
                firmware: 'v2.4.1',
                calibration: 'ปกติ (30 วัน)',
                installedDate: '15 พ.ค. 2568',
                owner: 'ผู้ดูแลโรงเรียน',
                note: 'ตำแหน่งติดตั้ง: ${d.location ?? "-"}',
                rssi: d.status == 'online' ? -58 : -95,
                batteryPercent: 100,
              );
            }).toList();
          } else {
            _devices = [];
          }

          _logs = logs
              .map(
                (l) => _DeviceLogRecord(
                  time:
                      '${l.createdAt.hour.toString().padLeft(2, "0")}:${l.createdAt.minute.toString().padLeft(2, "0")} น.',
                  action: l.action,
                  target: l.target,
                  detail: l.detail.isNotEmpty ? l.detail : l.target,
                  by: l.actorName,
                  type: 'success',
                ),
              )
              .toList();
          
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _devices = [];
          _logs = [];
          
        });
      }
    }
  }

  static String _mapCategory(String type) {
    switch (type.toLowerCase()) {
      case 'camera':
      case 'cctv':
        return 'กล้อง';
      case 'meter':
      case 'energy_meter':
        return 'มิเตอร์ไฟฟ้า';
      case 'water_meter':
        return 'มิเตอร์น้ำ';
      case 'gateway':
        return 'Gateway';
      case 'controller':
      case 'relay':
        return 'อุปกรณ์ควบคุม';
      default:
        return 'เซนเซอร์';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_DeviceRecord> get _filteredDevices {
    final String keyword = _searchController.text.trim().toLowerCase();

    return _devices.where((_DeviceRecord device) {
      final bool matchesSearch =
          keyword.isEmpty ||
          device.deviceCode.toLowerCase().contains(keyword) ||
          device.name.toLowerCase().contains(keyword) ||
          device.serialNumber.toLowerCase().contains(keyword) ||
          device.building.toLowerCase().contains(keyword) ||
          device.room.toLowerCase().contains(keyword) ||
          device.category.toLowerCase().contains(keyword);

      final bool matchesCategory =
          _selectedCategory == 'ทุกประเภท' ||
          device.category == _selectedCategory;

      final bool matchesBuilding =
          _selectedBuilding == 'ทุกอาคาร' ||
          device.building == _selectedBuilding;

      final bool matchesStatus;
      if (_filterIssuesOnly) {
        matchesStatus = device.status == 'ออฟไลน์' ||
            device.status == 'ปิดใช้งาน' ||
            device.health == 'ต้องตรวจสอบ' ||
            device.health == 'คำเตือน';
      } else {
        matchesStatus =
            _selectedStatus == 'ทุกสถานะ' || device.status == _selectedStatus;
      }

      return matchesSearch &&
          matchesCategory &&
          matchesBuilding &&
          matchesStatus;
    }).toList();
  }

  int get _onlineCount =>
      _devices.where((device) => device.status == 'ออนไลน์').length;

  int get _offlineCount =>
      _devices.where((device) => device.status == 'ออฟไลน์').length;

  int get _attentionCount => _devices.where((device) {
        return device.health == 'ต้องตรวจสอบ' ||
            device.health == 'คำเตือน' ||
            device.status == 'ออฟไลน์' ||
            device.status == 'ปิดใช้งาน';
      }).length;

  int get _assignedCount =>
      _devices.where((device) => device.building != 'ไม่ระบุอาคาร').length;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'ทุกประเภท';
      _selectedBuilding = 'ทุกอาคาร';
      _selectedStatus = 'ทุกสถานะ';
      _filterIssuesOnly = false;
    });
  }

  Future<void> _openDeviceForm({_DeviceRecord? device}) async {
    final bool editing = device != null;

    final TextEditingController codeController = TextEditingController(
      text: device?.deviceCode ?? 'DEV-SEN-${DateTime.now().millisecond.toString().padLeft(4, "0")}',
    );
    final TextEditingController nameController = TextEditingController(
      text: device?.name ?? '',
    );
    final TextEditingController modelController = TextEditingController(
      text: device?.model ?? 'SPS30-PM2.5',
    );
    final TextEditingController serialController = TextEditingController(
      text: device?.serialNumber ?? 'SN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
    );
    final TextEditingController buildingController = TextEditingController(
      text: device?.building == 'ไม่ระบุอาคาร' ? 'อาคารเรียน A' : (device?.building ?? 'อาคารเรียน A'),
    );
    final TextEditingController roomController = TextEditingController(
      text: device?.room ?? 'A-101',
    );
    final TextEditingController ipController = TextEditingController(
      text: device?.ipAddress ?? '192.168.1.105',
    );
    final TextEditingController noteController = TextEditingController(
      text: device?.note ?? '',
    );

    String category = device?.category ?? 'เซนเซอร์';
    String status = device?.status ?? 'ออนไลน์';
    String health = device?.health ?? 'ปกติ';

    final _DeviceRecord? result = await showDialog<_DeviceRecord>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              title: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: SchoolAdminPalette.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      editing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                      color: SchoolAdminPalette.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editing ? 'แก้ไขข้อมูลอุปกรณ์' : 'ลงทะเบียนอุปกรณ์ใหม่',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          editing
                              ? 'รหัส: ${device.deviceCode}'
                              : 'เพิ่มอุปกรณ์ IoT หรือมิเตอร์เข้าสู่ระบบโรงเรียน',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 700,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: codeController,
                              decoration: _inputDecoration('รหัสอุปกรณ์', Icons.qr_code_2_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              decoration: _inputDecoration('ชื่ออุปกรณ์ (เช่น เซนเซอร์ PM2.5 ชั้น 1)', Icons.memory_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: category,
                              decoration: _inputDecoration('ประเภทอุปกรณ์', Icons.category_rounded),
                              items: const [
                                DropdownMenuItem(value: 'เซนเซอร์', child: Text('เซนเซอร์ (Sensor)')),
                                DropdownMenuItem(value: 'มิเตอร์ไฟฟ้า', child: Text('มิเตอร์ไฟฟ้า (Energy Meter)')),
                                DropdownMenuItem(value: 'มิเตอร์น้ำ', child: Text('มิเตอร์น้ำ (Water Meter)')),
                                DropdownMenuItem(value: 'กล้อง', child: Text('กล้อง CCTV')),
                                DropdownMenuItem(value: 'Gateway', child: Text('เกตเวย์ (Gateway)')),
                                DropdownMenuItem(value: 'อุปกรณ์ควบคุม', child: Text('อุปกรณ์ควบคุม (Controller)')),
                              ],
                              onChanged: (v) {
                                if (v != null) setDialogState(() => category = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: modelController,
                              decoration: _inputDecoration('รุ่น / โมเดล', Icons.tag_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: buildingController,
                              decoration: _inputDecoration('อาคารที่ติดตั้ง', Icons.apartment_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: roomController,
                              decoration: _inputDecoration('ห้อง / จุดติดตั้ง', Icons.meeting_room_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: serialController,
                              decoration: _inputDecoration('Serial Number', Icons.confirmation_number_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: ipController,
                              decoration: _inputDecoration('IP Address / MAC', Icons.router_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: status,
                              decoration: _inputDecoration('สถานะเริ่มต้น', Icons.sensors_rounded),
                              items: const [
                                DropdownMenuItem(value: 'ออนไลน์', child: Text('ออนไลน์ (Online)')),
                                DropdownMenuItem(value: 'ออฟไลน์', child: Text('ออฟไลน์ (Offline)')),
                                DropdownMenuItem(value: 'ปิดใช้งาน', child: Text('ปิดใช้งาน (Disabled)')),
                              ],
                              onChanged: (v) {
                                if (v != null) setDialogState(() => status = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: health,
                              decoration: _inputDecoration('สุขภาพอุปกรณ์', Icons.health_and_safety_rounded),
                              items: const [
                                DropdownMenuItem(value: 'ปกติ', child: Text('ปกติ (Good)')),
                                DropdownMenuItem(value: 'คำเตือน', child: Text('คำเตือน (Warning)')),
                                DropdownMenuItem(value: 'ต้องตรวจสอบ', child: Text('ต้องตรวจสอบ (Attention)'))
                              ],
                              onChanged: (v) {
                                if (v != null) setDialogState(() => health = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: _inputDecoration('หมายเหตุเพิ่มเติม', Icons.notes_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF475569))),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอกชื่ออุปกรณ์')),
                      );
                      return;
                    }
                    final record = _DeviceRecord(
                      id: device?.id ?? 'dev-${DateTime.now().millisecondsSinceEpoch}',
                      deviceCode: codeController.text.trim(),
                      name: name,
                      category: category,
                      model: modelController.text.trim(),
                      serialNumber: serialController.text.trim(),
                      building: buildingController.text.trim(),
                      room: roomController.text.trim(),
                      trainingKit: 'ชุดฝึก AIoT Lab',
                      status: status,
                      health: health,
                      lastSeen: 'เมื่อสักครู่',
                      ipAddress: ipController.text.trim(),
                      firmware: device?.firmware ?? 'v2.4.1',
                      calibration: 'ปกติ',
                      installedDate: device?.installedDate ?? 'วันนี้',
                      owner: 'ผู้ดูแลโรงเรียน',
                      note: noteController.text.trim(),
                      rssi: -60,
                      batteryPercent: 100,
                    );
                    Navigator.of(dialogContext).pop(record);
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(editing ? 'บันทึกการแก้ไข' : 'บันทึกอุปกรณ์'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SchoolAdminPalette.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      if (editing) {
        final index = _devices.indexWhere((item) => item.id == result.id);
        if (index >= 0) _devices[index] = result;
        _logs.insert(
          0,
          _DeviceLogRecord(
            time: 'เมื่อสักครู่',
            action: 'แก้ไขข้อมูล',
            target: result.deviceCode,
            detail: '${result.name} (${result.building})',
            by: 'ผู้ดูแลโรงเรียน',
            type: 'update',
          ),
        );
      } else {
        _devices.insert(0, result);
        _logs.insert(
          0,
          _DeviceLogRecord(
            time: 'เมื่อสักครู่',
            action: 'ลงทะเบียนใหม่',
            target: result.deviceCode,
            detail: '${result.name} • ${result.building}',
            by: 'ผู้ดูแลโรงเรียน',
            type: 'success',
          ),
        );
      }
    });

    _showMessage(editing ? 'แก้ไขข้อมูล ${result.deviceCode} สำเร็จ' : 'ลงทะเบียนอุปกรณ์ใหม่เรียบร้อยแล้ว');
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SchoolAdminPalette.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  void _testDevice(_DeviceRecord device) {
    setState(() {
      _logs.insert(
        0,
        _DeviceLogRecord(
          time: 'เมื่อสักครู่',
          action: 'ทดสอบสัญญาณ (Ping)',
          target: device.deviceCode,
          detail: 'Ping ${device.ipAddress} ตอบสนองใน 12ms',
          by: 'ผู้ดูแลโรงเรียน',
          type: 'success',
        ),
      );
    });
    _showMessage('ทดสอบ ${device.name} (${device.deviceCode}): สัญญาณปกติ ตอบสนอง 12ms');
  }

  void _toggleDevice(_DeviceRecord device) {
    final int index = _devices.indexWhere((item) => item.id == device.id);
    if (index < 0) return;

    final String nextStatus = device.status == 'ปิดใช้งาน' ? 'ออนไลน์' : 'ปิดใช้งาน';
    final String nextHealth = nextStatus == 'ปิดใช้งาน' ? 'คำเตือน' : 'ปกติ';

    setState(() {
      _devices[index] = device.copyWith(
        status: nextStatus,
        health: nextHealth,
        lastSeen: 'เมื่อสักครู่',
      );

      _logs.insert(
        0,
        _DeviceLogRecord(
          time: 'เมื่อสักครู่',
          action: nextStatus == 'ปิดใช้งาน' ? 'ปิดใช้งานอุปกรณ์' : 'เปิดใช้งานอุปกรณ์',
          target: device.deviceCode,
          detail: device.name,
          by: 'ผู้ดูแลโรงเรียน',
          type: nextStatus == 'ปิดใช้งาน' ? 'danger' : 'success',
        ),
      );
    });

    _showMessage(
      nextStatus == 'ปิดใช้งาน'
          ? 'ปิดการทำงานของ ${device.deviceCode} แล้ว'
          : 'เปิดใช้งาน ${device.deviceCode} เรียบร้อยแล้ว',
    );
  }

  void _showQrDialog(_DeviceRecord device) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SchoolAdminPalette.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: SchoolAdminPalette.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR Code ประจำอุปกรณ์',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      device.deviceCode,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 200,
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 165,
                          color: Color(0xFF0F172A),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: SchoolAdminPalette.primary, width: 2),
                          ),
                          child: const Icon(
                            Icons.sensors_rounded,
                            size: 20,
                            color: SchoolAdminPalette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  device.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${device.building} • ${device.room}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'สแกน QR นี้เพื่อดู Telemetry หรือจับคู่อุปกรณ์เข้ากับชุดฝึก',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ปิด'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showMessage('พิมพ์ QR Code สำหรับติดประจำอุปกรณ์ ${device.deviceCode} สำเร็จ');
              },
              icon: const Icon(Icons.print_rounded, size: 18),
              label: const Text('พิมพ์สติกเกอร์ QR'),
              style: FilledButton.styleFrom(
                backgroundColor: SchoolAdminPalette.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeviceDetail(_DeviceRecord device) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 750),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2A000000),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
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
                        _DeviceCategoryIconBox(category: device.category, size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.name,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      device.deviceCode,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    device.category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _DetailStatusBox(
                            label: 'สถานะการเชื่อมต่อ',
                            value: device.status,
                            icon: device.status == 'ออนไลน์' ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                            color: _statusColor(device.status),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DetailStatusBox(
                            label: 'สุขภาพระบบ',
                            value: device.health,
                            icon: Icons.health_and_safety_rounded,
                            color: _healthColor(device.health),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DetailStatusBox(
                            label: 'ความแรงสัญญาณ',
                            value: '${device.rssi} dBm',
                            icon: Icons.signal_cellular_alt_rounded,
                            color: device.rssi > -70 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ข้อมูลทางเทคนิคและจุดติดตั้ง',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(icon: Icons.tag_rounded, label: 'โมเดล / รุ่น', value: device.model),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _DetailRow(icon: Icons.confirmation_number_rounded, label: 'Serial Number', value: device.serialNumber),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _DetailRow(icon: Icons.apartment_rounded, label: 'อาคารที่ตั้ง', value: device.building),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _DetailRow(icon: Icons.meeting_room_rounded, label: 'ห้อง / จุดติดตั้ง', value: device.room),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _DetailRow(icon: Icons.router_rounded, label: 'IP Address', value: device.ipAddress),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _DetailRow(icon: Icons.system_update_rounded, label: 'Firmware Version', value: device.firmware),
                          const Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _DetailRow(icon: Icons.access_time_rounded, label: 'ตอบสนองล่าสุด', value: device.lastSeen),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _testDevice(device);
                            },
                            icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                            label: const Text('ทดสอบเชื่อมต่อ (Ping)'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _showQrDialog(device);
                            },
                            icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                            label: const Text('ดู QR Code'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _openDeviceForm(device: device);
                            },
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('แก้ไขข้อมูล'),
                            style: FilledButton.styleFrom(
                              backgroundColor: SchoolAdminPalette.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
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
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ออนไลน์':
        return const Color(0xFF16A34A);
      case 'ออฟไลน์':
        return const Color(0xFFDC2626);
      case 'ปิดใช้งาน':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFFD97706);
    }
  }

  Color _healthColor(String health) {
    switch (health) {
      case 'ปกติ':
        return const Color(0xFF16A34A);
      case 'คำเตือน':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_DeviceRecord> devices = _filteredDevices;

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
                  _buildQuickActions(),
                  const SizedBox(height: 18),
                  _buildHealthOverview(),
                  const SizedBox(height: 18),
                  _buildFilters(),
                  const SizedBox(height: 18),
                  _buildDeviceList(devices),
                  const SizedBox(height: 18),
                  _buildMaintenanceAndAlerts(),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget title = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9E401A), Color(0xFF6E280C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x289E401A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.memory_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
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
                      'ตรวจสอบสถานะออนไลน์ ควบคุม สั่งการ และกำหนดจุดติดตั้งอุปกรณ์ทั่วสถานศึกษา',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
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
                onPressed: _loadDevices,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('รีเฟรช'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: const Color(0xFF334155),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _showMessage('เตรียมข้อมูลส่งออกเป็นไฟล์ Excel/CSV เรียบร้อย');
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('ส่งออก'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: const Color(0xFF334155),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openDeviceForm(),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('เพิ่มอุปกรณ์'),
                style: FilledButton.styleFrom(
                  backgroundColor: SchoolAdminPalette.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
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
              Expanded(child: title),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary() {
    final List<_DeviceSummaryData> items = [
      _DeviceSummaryData(
        title: 'อุปกรณ์ทั้งหมด',
        value: '${_devices.length}',
        detail: 'ลงทะเบียนในระบบแล้ว',
        icon: Icons.memory_rounded,
        color: const Color(0xFF0284C7),
      ),
      _DeviceSummaryData(
        title: 'ออนไลน์พร้อมใช้งาน',
        value: '$_onlineCount',
        detail: _devices.isEmpty ? 'ไม่มีอุปกรณ์' : '${((_onlineCount / _devices.length) * 100).toStringAsFixed(0)}% ของระบบ',
        icon: Icons.wifi_rounded,
        color: const Color(0xFF16A34A),
      ),
      _DeviceSummaryData(
        title: 'ออฟไลน์ / ขาดการติดต่อ',
        value: '$_offlineCount',
        detail: 'สัญญาณขาดหาย',
        icon: Icons.wifi_off_rounded,
        color: const Color(0xFFDC2626),
      ),
      _DeviceSummaryData(
        title: 'ควรตรวจสอบ / คำเตือน',
        value: '$_attentionCount',
        detail: 'ต้องการการดูแล',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFD97706),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1050) columns = 2;
        if (constraints.maxWidth < 520) columns = 1;

        const double spacing = 14;
        final double width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((_DeviceSummaryData item) {
            return SizedBox(
              width: width,
              child: _DeviceSummaryCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final List<_DeviceQuickActionData> actions = [
      _DeviceQuickActionData(
        title: 'เพิ่มอุปกรณ์ใหม่',
        subtitle: 'ลงทะเบียนมิเตอร์หรือเซนเซอร์',
        icon: Icons.add_circle_outline_rounded,
        color: const Color(0xFF9E401A),
        onTap: () => _openDeviceForm(),
      ),
      _DeviceQuickActionData(
        title: 'สแกน QR Code',
        subtitle: 'เปิดดูข้อมูลจากสติกเกอร์ประจำเครื่อง',
        icon: Icons.qr_code_scanner_rounded,
        color: const Color(0xFF0284C7),
        onTap: () => _showMessage('เปิดโหมดสแกน QR อุปกรณ์'),
      ),
      _DeviceQuickActionData(
        title: 'ทดสอบสัญญาณรวม',
        subtitle: 'ส่ง Ping ตรวจสถานะ Gateway & Nodes',
        icon: Icons.network_ping_rounded,
        color: const Color(0xFF16A34A),
        onTap: () => _showMessage('กำลังส่งคำสั่ง Ping ทดสอบทุกอุปกรณ์ในระบบ...'),
      ),
      _DeviceQuickActionData(
        title: 'กรองอุปกรณ์มีปัญหา',
        subtitle: 'ดูเฉพาะออฟไลน์และสถานะคำเตือน',
        icon: Icons.filter_alt_rounded,
        color: const Color(0xFFD97706),
        onTap: () {
          setState(() {
            _filterIssuesOnly = !_filterIssuesOnly;
          });
        },
      ),
    ];

    return _ModernSectionCard(
      title: 'งานที่ใช้บ่อย (Quick Operations)',
      subtitle: 'เข้าถึงคำสั่งจัดการอุปกรณ์และฟังก์ชันตรวจสอบได้ทันที',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          int columns = 4;
          if (constraints.maxWidth < 980) columns = 2;
          if (constraints.maxWidth < 520) columns = 1;

          const double spacing = 12;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: actions.map((_DeviceQuickActionData item) {
              return SizedBox(
                width: width,
                child: _DeviceQuickActionCard(data: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildHealthOverview() {
    final double assignedRatio = _devices.isEmpty ? 0 : (_assignedCount / _devices.length);

    final List<_DeviceHealthData> items = [
      _DeviceHealthData(
        title: 'ระบุจุดติดตั้งแล้ว',
        value: '$_assignedCount / ${_devices.length}',
        detail: 'ระบุอาคารและห้องครบถ้วน',
        progress: assignedRatio,
        icon: Icons.location_on_rounded,
        color: const Color(0xFF0284C7),
      ),
      const _DeviceHealthData(
        title: 'Firmware เป็นเวอร์ชันล่าสุด',
        value: '100%',
        detail: 'ไม่มีอัปเดตคงค้าง',
        progress: 1.0,
        icon: Icons.system_update_rounded,
        color: Color(0xFF16A34A),
      ),
      const _DeviceHealthData(
        title: 'การสอบเทียบตามกำหนด (Calibration)',
        value: 'ผ่านเกณฑ์',
        detail: 'เซนเซอร์สภาพแวดล้อมพร้อมใช้งาน',
        progress: 0.95,
        icon: Icons.tune_rounded,
        color: Color(0xFF9E401A),
      ),
    ];

    return _ModernSectionCard(
      title: 'ความพร้อมและสุขภาพของระบบ (System Health)',
      subtitle: 'ติดตามมาตรฐานการติดตั้ง Firmware และความสมบูรณ์ของเครือข่ายเซนเซอร์',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          int columns = 3;
          if (constraints.maxWidth < 860) columns = 1;

          const double spacing = 12;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: items.map((_DeviceHealthData item) {
              return SizedBox(
                width: width,
                child: _DeviceHealthCard(data: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
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
                    hintText: 'ค้นหาด้วยชื่ออุปกรณ์, รหัส DEV-, Serial หรืออาคาร...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: SchoolAdminPalette.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                selected: _filterIssuesOnly,
                onSelected: (val) {
                  setState(() => _filterIssuesOnly = val);
                },
                avatar: Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: _filterIssuesOnly ? Colors.white : const Color(0xFFD97706),
                ),
                label: const Text('⚠️ ดูอุปกรณ์ที่มีปัญหา'),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _filterIssuesOnly ? Colors.white : const Color(0xFF0F172A),
                ),
                backgroundColor: const Color(0xFFFEF3C7),
                selectedColor: const Color(0xFFD97706),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _filterIssuesOnly ? const Color(0xFFD97706) : const Color(0xFFFDE68A),
                  ),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'หมวดหมู่:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              ...[
                'ทุกประเภท',
                'เซนเซอร์',
                'มิเตอร์ไฟฟ้า',
                'มิเตอร์น้ำ',
                'กล้อง',
                'Gateway',
                'อุปกรณ์ควบคุม',
              ].map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = category);
                  },
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                  selectedColor: SchoolAdminPalette.primary,
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? SchoolAdminPalette.primary : const Color(0xFFE2E8F0),
                    ),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                );
              }),
              const SizedBox(width: 8),
              if (_selectedCategory != 'ทุกประเภท' ||
                  _selectedBuilding != 'ทุกอาคาร' ||
                  _selectedStatus != 'ทุกสถานะ' ||
                  _filterIssuesOnly ||
                  _searchController.text.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                  label: const Text('ล้างตัวกรอง'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(List<_DeviceRecord> devices) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
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
                        'ตารางแสดงอุปกรณ์ IoT, สถานะออนไลน์, และการตั้งค่าประจำสถานศึกษา',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          if (devices.isEmpty)
            const _DeviceEmptyState()
          else
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth >= 1050) {
                  return Table(
                    border: const TableBorder(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      horizontalInside: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2.6),
                      1: FlexColumnWidth(1.3),
                      2: FlexColumnWidth(1.6),
                      3: FlexColumnWidth(1.2),
                      4: FlexColumnWidth(1.2),
                      5: FlexColumnWidth(1.2),
                      6: FlexColumnWidth(0.7),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          ),
                        ),
                        children: [
                          _DeviceTableHeader(text: 'ชื่ออุปกรณ์ / รหัส', align: TextAlign.left),
                          _DeviceTableHeader(text: 'หมวดหมู่'),
                          _DeviceTableHeader(text: 'จุดติดตั้ง'),
                          _DeviceTableHeader(text: 'สถานะเชื่อมต่อ'),
                          _DeviceTableHeader(text: 'สุขภาพ / สัญญาณ'),
                          _DeviceTableHeader(text: 'ตอบสนองล่าสุด'),
                          _DeviceTableHeader(text: 'จัดการ'),
                        ],
                      ),
                      ...devices.map((_DeviceRecord device) {
                        return TableRow(
                          children: [
                            _DeviceTableNameCell(
                              device: device,
                              onTap: () => _showDeviceDetail(device),
                            ),
                            _DeviceTableCell(
                              child: _DeviceCategoryBadge(value: device.category),
                            ),
                            _DeviceTableCell(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    device.building,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    device.room,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _DeviceTableCell(
                              child: _DeviceStatusBadge(value: device.status),
                            ),
                            _DeviceTableCell(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _DeviceHealthBadge(value: device.health),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${device.rssi} dBm',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _DeviceTableCell(
                              child: Text(
                                device.lastSeen,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            _DeviceTableCell(
                              child: PopupMenuButton<String>(
                                tooltip: 'จัดการ',
                                color: Colors.white,
                                surfaceTintColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                elevation: 6,
                                shadowColor: const Color(0x1A000000),
                                onSelected: (String value) {
                                  switch (value) {
                                    case 'view':
                                      _showDeviceDetail(device);
                                      break;
                                    case 'edit':
                                      _openDeviceForm(device: device);
                                      break;
                                    case 'qr':
                                      _showQrDialog(device);
                                      break;
                                    case 'test':
                                      _testDevice(device);
                                      break;
                                    case 'toggle':
                                      _toggleDevice(device);
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  return [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF475569)),
                                          SizedBox(width: 10),
                                          Text('ดูรายละเอียด & Telemetry'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
                                          SizedBox(width: 10),
                                          Text('แก้ไขข้อมูล'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'qr',
                                      child: Row(
                                        children: [
                                          Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFF475569)),
                                          SizedBox(width: 10),
                                          Text('พิมพ์ QR Code'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'test',
                                      child: Row(
                                        children: [
                                          Icon(Icons.network_ping_rounded, size: 18, color: Color(0xFF475569)),
                                          SizedBox(width: 10),
                                          Text('ทดสอบการเชื่อมต่อ (Ping)'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(
                                            device.status == 'ปิดใช้งาน'
                                                ? Icons.power_settings_new_rounded
                                                : Icons.power_off_rounded,
                                            size: 18,
                                            color: device.status == 'ปิดใช้งาน'
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFDC2626),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            device.status == 'ปิดใช้งาน' ? 'เปิดใช้งาน' : 'ปิดใช้งานอุปกรณ์',
                                            style: TextStyle(
                                              color: device.status == 'ปิดใช้งาน'
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFFDC2626),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: devices.map((_DeviceRecord device) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DeviceMobileCard(
                          device: device,
                          onView: () => _showDeviceDetail(device),
                          onEdit: () => _openDeviceForm(device: device),
                          onTest: () => _testDevice(device),
                          onQr: () => _showQrDialog(device),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceAndAlerts() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const Widget alerts = _ModernSectionCard(
          title: 'รายการที่ควรตรวจสอบ (Device Alerts)',
          subtitle: 'อุปกรณ์ที่ตรวจพบสัญญาณขาดหาย หรือค่าตรวจวัดผิดปกติ',
          child: Column(
            children: [
              _ModernAlertTile(
                icon: Icons.wifi_off_rounded,
                title: 'เซนเซอร์ PM2.5 (SPS30) ไม่ตอบสนอง',
                detail: 'DEV-SEN-0004 • อาคารเรียน B (ห้อง B-101) • ออฟไลน์ 28 นาที',
                status: 'เร่งด่วน',
                color: Color(0xFFDC2626),
              ),
              SizedBox(height: 10),
              _ModernAlertTile(
                icon: Icons.water_drop_rounded,
                title: 'Water Flow Meter อัตราการไหลสูงผิดปกติ',
                detail: 'DEV-WTR-0006 • อาคารปฏิบัติการ • ตรวจพบการใช้น้ำนอกเวลา',
                status: 'ตรวจสอบ',
                color: Color(0xFFD97706),
              ),
              SizedBox(height: 10),
              _ModernAlertTile(
                icon: Icons.videocam_off_rounded,
                title: 'กล้อง CCTV LAB-02 สัญญาณขาดหายเป็นระยะ',
                detail: 'DEV-CAM-0007 • โรงฝึกงาน AIoT • เฟรมเรตลดลง',
                status: 'ติดตาม',
                color: Color(0xFF0284C7),
              ),
            ],
          ),
        );

        const Widget maintenance = _ModernSectionCard(
          title: 'แผนการบำรุงรักษา (Maintenance Schedule)',
          subtitle: 'กำหนดการตรวจเช็ก ซ่อมบำรุง และสอบเทียบความแม่นยำเซนเซอร์',
          child: Column(
            children: [
              _ModernMaintenanceTile(
                title: 'ทำความสะอาดหัวตรวจ SPS30 Optical',
                detail: 'DEV-SEN-0004 • ครบกำหนดบำรุงรักษาประจำเดือน',
                icon: Icons.build_circle_rounded,
                color: Color(0xFFDC2626),
                deadline: 'วันนี้',
              ),
              SizedBox(height: 10),
              _ModernMaintenanceTile(
                title: 'สอบเทียบเซนเซอร์ก๊าซ MQ-2 Sensor',
                detail: 'DEV-SEN-0001 • ตรวจความเที่ยงตรงตามรอบ 90 วัน',
                icon: Icons.tune_rounded,
                color: Color(0xFFD97706),
                deadline: 'อีก 6 วัน',
              ),
              SizedBox(height: 10),
              _ModernMaintenanceTile(
                title: 'อัปเกรด Firmware กล้องตรวจจับการเคลื่อนไหว',
                detail: 'DEV-CAM-0007 • แพตช์ความปลอดภัย v2.4.2',
                icon: Icons.system_update_rounded,
                color: Color(0xFF0284C7),
                deadline: 'อีก 12 วัน',
              ),
            ],
          ),
        );

        if (constraints.maxWidth < 950) {
          return const Column(
            children: [alerts, SizedBox(height: 16), maintenance],
          );
        }

        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: alerts),
            SizedBox(width: 16),
            Expanded(flex: 4, child: maintenance),
          ],
        );
      },
    );
  }

  Widget _buildLogs() {
    return _ModernSectionCard(
      title: 'ประวัติการจัดการอุปกรณ์ (Audit Logs)',
      subtitle: 'บันทึกคำสั่ง การเปิด/ปิด การตั้งค่า และกิจกรรมที่เกิดขึ้นในระบบ',
      child: _logs.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: const Text(
                'ยังไม่มีประวัติการจัดการอุปกรณ์',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            )
          : Column(
              children: _logs.take(6).map((_DeviceLogRecord log) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ModernDeviceLogRow(log: log),
                );
              }).toList(),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable Modern Widgets
// ---------------------------------------------------------------------------

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DeviceSummaryCard extends StatelessWidget {
  const _DeviceSummaryCard({required this.data});

  final _DeviceSummaryData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: data.color,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _DeviceQuickActionCard extends StatelessWidget {
  const _DeviceQuickActionCard({required this.data});

  final _DeviceQuickActionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: data.color.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
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
  }
}

class _DeviceHealthCard extends StatelessWidget {
  const _DeviceHealthCard({required this.data});

  final _DeviceHealthData data;

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
              Icon(data.icon, color: data.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: data.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: data.progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(data.color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.detail,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTableHeader extends StatelessWidget {
  const _DeviceTableHeader({required this.text, this.align = TextAlign.center});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF475569),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _DeviceTableCell extends StatelessWidget {
  const _DeviceTableCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Center(child: child),
    );
  }
}

class _DeviceTableNameCell extends StatelessWidget {
  const _DeviceTableNameCell({required this.device, required this.onTap});

  final _DeviceRecord device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _DeviceCategoryIconBox(category: device.category, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${device.deviceCode} • ${device.model}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCategoryIconBox extends StatelessWidget {
  const _DeviceCategoryIconBox({required this.category, this.size = 40});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (category) {
      case 'มิเตอร์ไฟฟ้า':
        icon = Icons.bolt_rounded;
        color = const Color(0xFFD97706);
        break;
      case 'มิเตอร์น้ำ':
        icon = Icons.water_drop_rounded;
        color = const Color(0xFF0284C7);
        break;
      case 'กล้อง':
        icon = Icons.videocam_rounded;
        color = const Color(0xFF7C3AED);
        break;
      case 'Gateway':
        icon = Icons.router_rounded;
        color = const Color(0xFF475569);
        break;
      case 'อุปกรณ์ควบคุม':
        icon = Icons.settings_remote_rounded;
        color = const Color(0xFF059669);
        break;
      default:
        icon = Icons.sensors_rounded;
        color = const Color(0xFF9E401A);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class _DeviceCategoryBadge extends StatelessWidget {
  const _DeviceCategoryBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (value) {
      case 'มิเตอร์ไฟฟ้า':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'มิเตอร์น้ำ':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        break;
      case 'กล้อง':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF6D28D9);
        break;
      case 'Gateway':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF334155);
        break;
      case 'อุปกรณ์ควบคุม':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        break;
      default:
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFC2410C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _DeviceStatusBadge extends StatelessWidget {
  const _DeviceStatusBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color dot;

    switch (value) {
      case 'ออนไลน์':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        dot = const Color(0xFF16A34A);
        break;
      case 'ออฟไลน์':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        dot = const Color(0xFFDC2626);
        break;
      case 'ปิดใช้งาน':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        dot = const Color(0xFF94A3B8);
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        dot = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceHealthBadge extends StatelessWidget {
  const _DeviceHealthBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    Color fg;
    switch (value) {
      case 'ปกติ':
        fg = const Color(0xFF16A34A);
        break;
      case 'คำเตือน':
        fg = const Color(0xFFD97706);
        break;
      default:
        fg = const Color(0xFFDC2626);
    }

    return Text(
      value,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: fg,
      ),
    );
  }
}

class _DeviceMobileCard extends StatelessWidget {
  const _DeviceMobileCard({
    required this.device,
    required this.onView,
    required this.onEdit,
    required this.onTest,
    required this.onQr,
  });

  final _DeviceRecord device;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onTest;
  final VoidCallback onQr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DeviceCategoryIconBox(category: device.category, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${device.deviceCode} • ${device.model}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              _DeviceStatusBadge(value: device.status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${device.building} • ${device.room}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Text(
                  'สุขภาพ: ${device.health}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('ดูข้อมูล'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onQr,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 18),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onTest,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.network_ping_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernAlertTile extends StatelessWidget {
  const _ModernAlertTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernMaintenanceTile extends StatelessWidget {
  const _ModernMaintenanceTile({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    required this.deadline,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final String deadline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              deadline,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernDeviceLogRow extends StatelessWidget {
  const _ModernDeviceLogRow({required this.log});

  final _DeviceLogRecord log;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              log.time,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      log.action,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.target,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  log.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            log.by,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatusBox extends StatelessWidget {
  const _DetailStatusBox({
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
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _DeviceEmptyState extends StatelessWidget {
  const _DeviceEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 12),
          Text(
            'ไม่พบอุปกรณ์',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'ลองเปลี่ยนคำค้นหาหรือล้างตัวกรองหมวดหมู่',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

class _DeviceSummaryData {
  const _DeviceSummaryData({
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

class _DeviceQuickActionData {
  const _DeviceQuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _DeviceHealthData {
  const _DeviceHealthData({
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
  final double progress;
  final IconData icon;
  final Color color;
}

class _DeviceRecord {
  const _DeviceRecord({
    required this.id,
    required this.deviceCode,
    required this.name,
    required this.category,
    required this.model,
    required this.serialNumber,
    required this.building,
    required this.room,
    required this.trainingKit,
    required this.status,
    required this.health,
    required this.lastSeen,
    required this.ipAddress,
    required this.firmware,
    required this.calibration,
    required this.installedDate,
    required this.owner,
    required this.note,
    this.rssi = -60,
    this.batteryPercent = 100,
  });

  final String id;
  final String deviceCode;
  final String name;
  final String category;
  final String model;
  final String serialNumber;
  final String building;
  final String room;
  final String trainingKit;
  final String status;
  final String health;
  final String lastSeen;
  final String ipAddress;
  final String firmware;
  final String calibration;
  final String installedDate;
  final String owner;
  final String note;
  final int rssi;
  final int batteryPercent;

  _DeviceRecord copyWith({
    String? status,
    String? health,
    String? lastSeen,
  }) {
    return _DeviceRecord(
      id: id,
      deviceCode: deviceCode,
      name: name,
      category: category,
      model: model,
      serialNumber: serialNumber,
      building: building,
      room: room,
      trainingKit: trainingKit,
      status: status ?? this.status,
      health: health ?? this.health,
      lastSeen: lastSeen ?? this.lastSeen,
      ipAddress: ipAddress,
      firmware: firmware,
      calibration: calibration,
      installedDate: installedDate,
      owner: owner,
      note: note,
      rssi: rssi,
      batteryPercent: batteryPercent,
    );
  }
}

class _DeviceLogRecord {
  const _DeviceLogRecord({
    required this.time,
    required this.action,
    required this.target,
    required this.detail,
    required this.by,
    required this.type,
  });

  final String time;
  final String action;
  final String target;
  final String detail;
  final String by;
  final String type;
}
