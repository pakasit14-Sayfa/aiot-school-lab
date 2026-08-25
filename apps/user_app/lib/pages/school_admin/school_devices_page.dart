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
          _devices = devices.map((d) {
            final shortId = d.id.length >= 4 ? d.id.substring(0, 4) : d.id;
            return _DeviceRecord(
              id: d.id,
              deviceCode: 'DEV-${d.type.toUpperCase()}-$shortId',
              name: d.name,
              category: d.type == 'camera' ? 'กล้อง' : (d.type == 'meter' ? 'มิเตอร์' : 'เซนเซอร์'),
              model: d.type,
              serialNumber: d.id,
              building: (d.location != null && d.location!.isNotEmpty) ? d.location! : 'ไม่ระบุ',
              room: '-',
              trainingKit: '-',
              status: d.status == 'online' ? 'ออนไลน์' : 'ออฟไลน์',
              health: 'ปกติ',
              lastSeen: 'เมื่อสักครู่',
              ipAddress: '-',
              firmware: 'v1.0.0',
              calibration: '-',
              installedDate: '-',
              owner: 'แอดมินโรงเรียน',
              note: 'ตำแหน่ง: ${d.location ?? '-'}',
            );
          }).toList();

          _logs = logs.map((l) => _DeviceLogRecord(
            time: '${l.createdAt.hour.toString().padLeft(2, '0')}:${l.createdAt.minute.toString().padLeft(2, '0')} น.',
            action: l.action,
            target: l.target,
            detail: l.detail.isNotEmpty ? l.detail : l.target,
            by: l.actorName,
            type: 'success',
          )).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_DeviceRecord> get _filteredDevices {
    final String keyword = _searchController.text.trim().toLowerCase();

    return _devices.where((_DeviceRecord device) {
      final bool matchesSearch = keyword.isEmpty ||
          device.deviceCode.toLowerCase().contains(keyword) ||
          device.name.toLowerCase().contains(keyword) ||
          device.serialNumber.toLowerCase().contains(keyword) ||
          device.room.toLowerCase().contains(keyword) ||
          device.trainingKit.toLowerCase().contains(keyword);

      final bool matchesCategory = _selectedCategory == 'ทุกประเภท' ||
          device.category == _selectedCategory;

      final bool matchesBuilding = _selectedBuilding == 'ทุกอาคาร' ||
          device.building == _selectedBuilding;

      final bool matchesStatus =
          _selectedStatus == 'ทุกสถานะ' || device.status == _selectedStatus;

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
            device.status == 'ตรวจสอบ';
      }).length;

  int get _assignedCount =>
      _devices.where((device) => device.room != '-').length;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'ทุกประเภท';
      _selectedBuilding = 'ทุกอาคาร';
      _selectedStatus = 'ทุกสถานะ';
    });
  }

  Future<void> _openDeviceForm({_DeviceRecord? device}) async {
    final bool editing = device != null;

    final TextEditingController codeController = TextEditingController(
      text: device?.deviceCode ?? '',
    );
    final TextEditingController nameController = TextEditingController(
      text: device?.name ?? '',
    );
    final TextEditingController modelController = TextEditingController(
      text: device?.model ?? '',
    );
    final TextEditingController serialController = TextEditingController(
      text: device?.serialNumber ?? '',
    );
    final TextEditingController ipController = TextEditingController(
      text: device?.ipAddress ?? '',
    );
    final TextEditingController firmwareController = TextEditingController(
      text: device?.firmware ?? '',
    );
    final TextEditingController ownerController = TextEditingController(
      text: device?.owner ?? '',
    );
    final TextEditingController noteController = TextEditingController(
      text: device?.note ?? '',
    );

    String category = device?.category ?? 'เซนเซอร์';
    String building = device?.building ?? 'อาคารเรียน A';
    String room = device?.room ?? 'A-101';
    String trainingKit = device?.trainingKit ?? '-';
    String status = device?.status ?? 'ออนไลน์';
    String health = device?.health ?? 'ปกติ';

    final _DeviceRecord? result = await showDialog<_DeviceRecord>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            return AlertDialog(
              insetPadding: const EdgeInsets.all(16),
              title: Text(
                editing ? 'แก้ไขข้อมูลอุปกรณ์' : 'เพิ่มอุปกรณ์ใหม่',
              ),
              content: SizedBox(
                width: 820,
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (
                      BuildContext context,
                      BoxConstraints constraints,
                    ) {
                      final bool oneColumn = constraints.maxWidth < 640;
                      final double fieldWidth = oneColumn
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: codeController,
                              decoration: const InputDecoration(
                                labelText: 'รหัสอุปกรณ์',
                                hintText: 'เช่น DEV-SEN-0009',
                                prefixIcon: Icon(Icons.qr_code_2_rounded),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'ชื่ออุปกรณ์',
                                prefixIcon: Icon(Icons.memory_rounded),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _DeviceDialogDropdown(
                              label: 'ประเภทอุปกรณ์',
                              icon: Icons.category_rounded,
                              value: category,
                              items: const [
                                'เซนเซอร์',
                                'มิเตอร์ไฟฟ้า',
                                'มิเตอร์น้ำ',
                                'กล้อง',
                                'อุปกรณ์ควบคุม',
                                'Gateway',
                                'อื่น ๆ',
                              ],
                              onChanged: (String value) {
                                setDialogState(() => category = value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: modelController,
                              decoration: const InputDecoration(
                                labelText: 'รุ่น / Model',
                                prefixIcon: Icon(Icons.info_outline_rounded),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: serialController,
                              decoration: const InputDecoration(
                                labelText: 'Serial Number',
                                prefixIcon:
                                    Icon(Icons.confirmation_number_rounded),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _DeviceDialogDropdown(
                              label: 'อาคาร',
                              icon: Icons.apartment_rounded,
                              value: building,
                              items: const [
                                'อาคารเรียน A',
                                'อาคารเรียน B',
                                'อาคารปฏิบัติการ',
                                'อาคารอำนวยการ',
                                'อาคารกีฬา',
                              ],
                              onChanged: (String value) {
                                setDialogState(() => building = value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _DeviceDialogDropdown(
                              label: 'ห้อง / จุดติดตั้ง',
                              icon: Icons.meeting_room_rounded,
                              value: room,
                              items: const [
                                'A-101',
                                'A-102',
                                'A-201',
                                'B-101',
                                'LAB-01',
                                'LAB-02',
                                'MDB-LAB',
                                'ระบบน้ำหลัก',
                              ],
                              onChanged: (String value) {
                                setDialogState(() => room = value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _DeviceDialogDropdown(
                              label: 'ชุดฝึก',
                              icon: Icons.handyman_rounded,
                              value: trainingKit,
                              items: const [
                                '-',
                                'KIT-A101-01',
                                'KIT-A102-01',
                                'KIT-LAB1-01',
                                'KIT-LAB2-02',
                              ],
                              onChanged: (String value) {
                                setDialogState(() => trainingKit = value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: ipController,
                              decoration: const InputDecoration(
                                labelText: 'IP Address',
                                prefixIcon: Icon(Icons.lan_rounded),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: firmwareController,
                              decoration: const InputDecoration(
                                labelText: 'Firmware',
                                prefixIcon: Icon(Icons.system_update_rounded),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: ownerController,
                              decoration: const InputDecoration(
                                labelText: 'ผู้รับผิดชอบ',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _DeviceDialogDropdown(
                              label: 'สถานะเชื่อมต่อ',
                              icon: Icons.wifi_rounded,
                              value: status,
                              items: const [
                                'ออนไลน์',
                                'ออฟไลน์',
                                'ตรวจสอบ',
                                'ปิดใช้งาน',
                              ],
                              onChanged: (String value) {
                                setDialogState(() => status = value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _DeviceDialogDropdown(
                              label: 'สุขภาพอุปกรณ์',
                              icon: Icons.health_and_safety_rounded,
                              value: health,
                              items: const [
                                'ปกติ',
                                'คำเตือน',
                                'ต้องตรวจสอบ',
                              ],
                              onChanged: (String value) {
                                setDialogState(() => health = value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: TextField(
                              controller: noteController,
                              minLines: 2,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'หมายเหตุ',
                                prefixIcon: Icon(Icons.notes_rounded),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final String code = codeController.text.trim();
                    final String name = nameController.text.trim();
                    final String serial = serialController.text.trim();

                    if (code.isEmpty || name.isEmpty || serial.isEmpty) {
                      _showMessage(
                        'กรุณากรอกรหัส ชื่อ และ Serial Number ให้ครบ',
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      _DeviceRecord(
                        id: device?.id ??
                            'device-${DateTime.now().millisecondsSinceEpoch}',
                        deviceCode: code,
                        name: name,
                        category: category,
                        model: modelController.text.trim().isEmpty
                            ? '-'
                            : modelController.text.trim(),
                        serialNumber: serial,
                        building: building,
                        room: room,
                        trainingKit: trainingKit,
                        status: status,
                        health: health,
                        lastSeen: device?.lastSeen ?? 'ยังไม่เคยเชื่อมต่อ',
                        ipAddress: ipController.text.trim().isEmpty
                            ? '-'
                            : ipController.text.trim(),
                        firmware: firmwareController.text.trim().isEmpty
                            ? '-'
                            : firmwareController.text.trim(),
                        calibration: device?.calibration ?? '-',
                        installedDate: device?.installedDate ?? '10 ส.ค. 2569',
                        owner: ownerController.text.trim().isEmpty
                            ? 'ยังไม่กำหนด'
                            : ownerController.text.trim(),
                        note: noteController.text.trim().isEmpty
                            ? 'ไม่มีหมายเหตุ'
                            : noteController.text.trim(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    editing ? 'บันทึกการแก้ไข' : 'เพิ่มอุปกรณ์',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    codeController.dispose();
    nameController.dispose();
    modelController.dispose();
    serialController.dispose();
    ipController.dispose();
    firmwareController.dispose();
    ownerController.dispose();
    noteController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      if (editing) {
        final int index = _devices.indexWhere((item) => item.id == result.id);
        if (index >= 0) {
          _devices[index] = result;
        }

        _logs.insert(
          0,
          _DeviceLogRecord(
            time: 'เมื่อสักครู่',
            action: 'แก้ไขอุปกรณ์',
            target: result.deviceCode,
            detail: '${result.name} • ${result.room}',
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
            action: 'เพิ่มอุปกรณ์',
            target: result.deviceCode,
            detail: '${result.name} • ${result.room}',
            by: 'ผู้ดูแลโรงเรียน',
            type: 'success',
          ),
        );
      }
    });

    _showMessage(
      editing ? 'บันทึกข้อมูลอุปกรณ์แล้ว' : 'เพิ่มอุปกรณ์ใหม่แล้ว',
    );
  }

  void _testDevice(_DeviceRecord device) {
    setState(() {
      _logs.insert(
        0,
        _DeviceLogRecord(
          time: 'เมื่อสักครู่',
          action: 'ทดสอบอุปกรณ์',
          target: device.deviceCode,
          detail: 'ส่งคำสั่งทดสอบ ${device.name}',
          by: 'ผู้ดูแลโรงเรียน',
          type: 'success',
        ),
      );
    });

    _showMessage('${device.name}: ทดสอบการเชื่อมต่อผ่าน');
  }

  void _toggleDevice(_DeviceRecord device) {
    final int index = _devices.indexWhere((item) => item.id == device.id);
    if (index < 0) return;

    final String nextStatus =
        device.status == 'ปิดใช้งาน' ? 'ออนไลน์' : 'ปิดใช้งาน';

    setState(() {
      _devices[index] = device.copyWith(
        status: nextStatus,
        health: nextStatus == 'ปิดใช้งาน' ? 'คำเตือน' : 'ปกติ',
        lastSeen: 'เมื่อสักครู่',
      );

      _logs.insert(
        0,
        _DeviceLogRecord(
          time: 'เมื่อสักครู่',
          action: nextStatus == 'ปิดใช้งาน'
              ? 'ปิดใช้งานอุปกรณ์'
              : 'เปิดใช้งานอุปกรณ์',
          target: device.deviceCode,
          detail: device.name,
          by: 'ผู้ดูแลโรงเรียน',
          type: nextStatus == 'ปิดใช้งาน' ? 'danger' : 'success',
        ),
      );
    });

    _showMessage(
      nextStatus == 'ปิดใช้งาน'
          ? 'ปิดใช้งาน ${device.deviceCode} แล้ว'
          : 'เปิดใช้งาน ${device.deviceCode} แล้ว',
    );
  }

  void _showQrDialog(_DeviceRecord device) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(device.deviceCode),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: SchoolAdminPalette.border,
                    ),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 145,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  device.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${device.building} • ${device.room}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'QR ตัวอย่างสำหรับเปิดข้อมูลอุปกรณ์เมื่อสแกน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ปิด'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showMessage('เตรียม QR สำหรับพิมพ์แล้ว');
              },
              icon: const Icon(Icons.print_rounded),
              label: const Text('พิมพ์ QR'),
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
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: SchoolAdminPalette.border),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: SchoolAdminPalette.primarySoft,
                        child: Icon(
                          Icons.memory_rounded,
                          color: SchoolAdminPalette.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: SchoolAdminPalette.textPrimary,
                              ),
                            ),
                            Text(
                              '${device.deviceCode} • ${device.category}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: SchoolAdminPalette.textSecondary,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DeviceDetailStatus(
                          label: 'เชื่อมต่อ',
                          value: device.status,
                          color: _statusColor(device.status),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DeviceDetailStatus(
                          label: 'สุขภาพ',
                          value: device.health,
                          color: _healthColor(device.health),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DeviceDetailRow(
                    icon: Icons.info_outline_rounded,
                    label: 'รุ่น',
                    value: device.model,
                  ),
                  _DeviceDetailRow(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Serial Number',
                    value: device.serialNumber,
                  ),
                  _DeviceDetailRow(
                    icon: Icons.apartment_rounded,
                    label: 'อาคาร',
                    value: device.building,
                  ),
                  _DeviceDetailRow(
                    icon: Icons.meeting_room_rounded,
                    label: 'จุดติดตั้ง',
                    value: device.room,
                  ),
                  _DeviceDetailRow(
                    icon: Icons.handyman_rounded,
                    label: 'ชุดฝึก',
                    value: device.trainingKit,
                  ),
                  _DeviceDetailRow(
                    icon: Icons.person_rounded,
                    label: 'ผู้รับผิดชอบ',
                    value: device.owner,
                  ),
                  _DeviceDetailRow(
                    icon: Icons.lan_rounded,
                    label: 'IP Address',
                    value: device.ipAddress,
                  ),
                  _DeviceDetailRow(
                    icon: Icons.system_update_rounded,
                    label: 'Firmware',
                    value: device.firmware,
                  ),
                  _DeviceDetailRow(
                    icon: Icons.tune_rounded,
                    label: 'ตรวจความแม่นยำล่าสุด',
                    value: device.calibration,
                  ),
                  _DeviceDetailRow(
                    icon: Icons.calendar_month_rounded,
                    label: 'วันที่ติดตั้ง',
                    value: device.installedDate,
                  ),
                  _DeviceDetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'ติดต่อระบบล่าสุด',
                    value: device.lastSeen,
                  ),
                  _DeviceDetailRow(
                    icon: Icons.notes_rounded,
                    label: 'หมายเหตุ',
                    value: device.note,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _showQrDialog(device);
                        },
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: const Text('ดู QR'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _testDevice(device);
                        },
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        label: const Text('ทดสอบ'),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _openDeviceForm(device: device);
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('แก้ไขข้อมูล'),
                      ),
                    ],
                  ),
                ],
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
        return SchoolAdminPalette.green;
      case 'ออฟไลน์':
        return SchoolAdminPalette.red;
      case 'ตรวจสอบ':
        return SchoolAdminPalette.secondary;
      default:
        return SchoolAdminPalette.textMuted;
    }
  }

  Color _healthColor(String health) {
    switch (health) {
      case 'ปกติ':
        return SchoolAdminPalette.green;
      case 'คำเตือน':
        return SchoolAdminPalette.secondary;
      default:
        return SchoolAdminPalette.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_DeviceRecord> devices = _filteredDevices;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 115),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  _buildSummary(),
                  const SizedBox(height: 14),
                  _buildQuickActions(),
                  const SizedBox(height: 14),
                  _buildHealthOverview(),
                  const SizedBox(height: 14),
                  _buildFilters(),
                  const SizedBox(height: 14),
                  _buildDeviceList(devices),
                  const SizedBox(height: 14),
                  _buildMaintenanceAndAlerts(),
                  const SizedBox(height: 14),
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          final Widget title = const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: SchoolAdminPalette.primarySoft,
                child: Icon(
                  Icons.memory_rounded,
                  color: SchoolAdminPalette.primaryDark,
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'อุปกรณ์',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'เพิ่มและจัดการอุปกรณ์ ดูสถานะออนไลน์ จุดติดตั้ง ชุดฝึก '
                      'QR Code การตรวจความแม่นยำ Firmware และประวัติการทำงาน',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        color: SchoolAdminPalette.textSecondary,
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
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _showMessage('เปิดโหมดสแกน QR อุปกรณ์');
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('สแกน QR'),
              ),
              FilledButton.icon(
                onPressed: () => _openDeviceForm(),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('เพิ่มอุปกรณ์'),
              ),
            ],
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 14),
                actions,
              ],
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
        detail: 'ลงทะเบียนและผูกเข้าระบบแล้ว',
        icon: Icons.memory_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _DeviceSummaryData(
        title: 'ออนไลน์',
        value: '$_onlineCount',
        detail: 'ติดต่อระบบได้ตามปกติ',
        icon: Icons.wifi_rounded,
        color: SchoolAdminPalette.green,
      ),
      _DeviceSummaryData(
        title: 'ออฟไลน์',
        value: '$_offlineCount',
        detail: 'ไม่ตอบสนองหรือขาดการเชื่อมต่อ',
        icon: Icons.wifi_off_rounded,
        color: SchoolAdminPalette.red,
      ),
      _DeviceSummaryData(
        title: 'ควรตรวจสอบ',
        value: '$_attentionCount',
        detail: 'มีคำเตือนหรือสถานะผิดปกติ',
        icon: Icons.notifications_active_rounded,
        color: SchoolAdminPalette.secondary,
      ),
    ];

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        int columns = 4;
        if (constraints.maxWidth < 1050) columns = 2;
        if (constraints.maxWidth < 300) columns = 1;

        const double spacing = 12;
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
        title: 'เพิ่มอุปกรณ์',
        subtitle: 'ลงทะเบียนอุปกรณ์ใหม่และกำหนดจุดติดตั้ง',
        icon: Icons.add_circle_outline_rounded,
        onTap: () => _openDeviceForm(),
      ),
      _DeviceQuickActionData(
        title: 'สแกน QR',
        subtitle: 'เปิดข้อมูลอุปกรณ์จาก QR Code',
        icon: Icons.qr_code_scanner_rounded,
        onTap: () => _showMessage('เปิดโหมดสแกน QR อุปกรณ์'),
      ),
      _DeviceQuickActionData(
        title: 'ทดสอบการเชื่อมต่อ',
        subtitle: 'ตรวจอุปกรณ์ออนไลน์และ Gateway',
        icon: Icons.play_circle_outline_rounded,
        onTap: () => _showMessage('เริ่มทดสอบอุปกรณ์ทั้งหมด'),
      ),
      _DeviceQuickActionData(
        title: 'รายการผิดปกติ',
        subtitle: 'ดูออฟไลน์ คำเตือน และอุปกรณ์ที่ต้องตรวจ',
        icon: Icons.warning_amber_rounded,
        onTap: () {
          setState(() => _selectedStatus = 'ออฟไลน์');
        },
      ),
    ];

    return _DeviceSectionCard(
      title: 'จัดการได้อย่างรวดเร็ว',
      subtitle: 'รวมงานที่ใช้บ่อยในการดูแลอุปกรณ์ไว้ในจุดเดียว',
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          int columns = 4;
          if (constraints.maxWidth < 900) columns = 2;
          if (constraints.maxWidth < 520) columns = 1;

          const double spacing = 10;
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
    return _DeviceSectionCard(
      title: 'สถานะระบบอุปกรณ์',
      subtitle: 'ดูภาพรวมการเชื่อมต่อ จุดติดตั้ง และรายการที่ต้องบำรุงรักษา',
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          final List<_DeviceHealthData> items = [
            _DeviceHealthData(
              title: 'ผูกจุดติดตั้งแล้ว',
              value: '$_assignedCount / ${_devices.length}',
              detail: 'อุปกรณ์มีอาคารและห้องเรียบร้อย',
              progress: _devices.isEmpty ? 0 : _assignedCount / _devices.length,
              icon: Icons.location_on_rounded,
              color: SchoolAdminPalette.primaryDark,
            ),
            const _DeviceHealthData(
              title: 'Firmware ล่าสุด',
              value: '6 / 8',
              detail: 'ยังมี 2 อุปกรณ์ควรตรวจเวอร์ชัน',
              progress: 0.75,
              icon: Icons.system_update_rounded,
              color: Color(0xFF4F6078),
            ),
            const _DeviceHealthData(
              title: 'ตรวจความแม่นยำตามกำหนด',
              value: '5 / 6',
              detail: 'เซนเซอร์ 1 จุดใกล้ถึงกำหนด',
              progress: 0.83,
              icon: Icons.tune_rounded,
              color: SchoolAdminPalette.secondary,
            ),
          ];

          int columns = 3;
          if (constraints.maxWidth < 820) columns = 1;

          const double spacing = 10;
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
    return _DeviceSectionCard(
      title: 'ค้นหาและกรองอุปกรณ์',
      subtitle: 'ค้นหาจากรหัส ชื่อ Serial ห้อง หรือรหัสชุดฝึก',
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          final Widget search = TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ค้นหารหัส ชื่อ Serial ห้อง หรือชุดฝึก',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          );

          final Widget category = _DeviceFilterDropdown(
            label: 'ประเภท',
            value: _selectedCategory,
            items: const [
              'ทุกประเภท',
              'เซนเซอร์',
              'มิเตอร์ไฟฟ้า',
              'มิเตอร์น้ำ',
              'กล้อง',
              'อุปกรณ์ควบคุม',
              'Gateway',
              'อื่น ๆ',
            ],
            onChanged: (String value) {
              setState(() => _selectedCategory = value);
            },
          );

          final Widget building = _DeviceFilterDropdown(
            label: 'อาคาร',
            value: _selectedBuilding,
            items: const [
              'ทุกอาคาร',
              'อาคารเรียน A',
              'อาคารเรียน B',
              'อาคารปฏิบัติการ',
              'อาคารอำนวยการ',
              'อาคารกีฬา',
            ],
            onChanged: (String value) {
              setState(() => _selectedBuilding = value);
            },
          );

          final Widget status = _DeviceFilterDropdown(
            label: 'สถานะ',
            value: _selectedStatus,
            items: const [
              'ทุกสถานะ',
              'ออนไลน์',
              'ออฟไลน์',
              'ตรวจสอบ',
              'ปิดใช้งาน',
            ],
            onChanged: (String value) {
              setState(() => _selectedStatus = value);
            },
          );

          final Widget clear = OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('ล้างตัวกรอง'),
          );

          if (constraints.maxWidth < 900) {
            return Column(
              children: [
                search,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: category),
                    const SizedBox(width: 10),
                    Expanded(child: building),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: status),
                    const SizedBox(width: 10),
                    clear,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 10),
              Expanded(child: category),
              const SizedBox(width: 10),
              Expanded(child: building),
              const SizedBox(width: 10),
              Expanded(child: status),
              const SizedBox(width: 10),
              clear,
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeviceList(List<_DeviceRecord> devices) {
    return _DeviceSectionCard(
      title: 'รายการอุปกรณ์',
      subtitle: 'พบ ${devices.length} รายการ',
      child: devices.isEmpty
          ? const _DeviceEmptyState()
          : LayoutBuilder(
              builder: (
                BuildContext context,
                BoxConstraints constraints,
              ) {
                if (constraints.maxWidth >= 1080) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: SchoolAdminPalette.border,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Table(
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: SchoolAdminPalette.border,
                        ),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(2.2),
                        1: FlexColumnWidth(1.2),
                        2: FlexColumnWidth(1.45),
                        3: FlexColumnWidth(1.3),
                        4: FlexColumnWidth(1.15),
                        5: FlexColumnWidth(1.15),
                        6: FlexColumnWidth(1.0),
                        7: FlexColumnWidth(0.65),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(
                            color: SchoolAdminPalette.primarySoft,
                          ),
                          children: [
                            _DeviceTableHeader(text: 'อุปกรณ์'),
                            _DeviceTableHeader(text: 'ประเภท'),
                            _DeviceTableHeader(text: 'จุดติดตั้ง'),
                            _DeviceTableHeader(text: 'ชุดฝึก'),
                            _DeviceTableHeader(text: 'สถานะ'),
                            _DeviceTableHeader(text: 'สุขภาพ'),
                            _DeviceTableHeader(text: 'ล่าสุด'),
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
                                child: _DeviceCategoryBadge(
                                  value: device.category,
                                ),
                              ),
                              _DeviceTableCell(
                                child: Text(
                                  '${device.building}\n${device.room}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w700,
                                    color: SchoolAdminPalette.textPrimary,
                                  ),
                                ),
                              ),
                              _DeviceTableCell(
                                child: Text(
                                  device.trainingKit,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: SchoolAdminPalette.textPrimary,
                                  ),
                                ),
                              ),
                              _DeviceTableCell(
                                child: _DeviceStatusBadge(
                                  value: device.status,
                                ),
                              ),
                              _DeviceTableCell(
                                child: _DeviceHealthBadge(
                                  value: device.health,
                                ),
                              ),
                              _DeviceTableCell(
                                child: Text(
                                  device.lastSeen,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: SchoolAdminPalette.textSecondary,
                                  ),
                                ),
                              ),
                              _DeviceTableCell(
                                child: PopupMenuButton<String>(
                                  tooltip: 'จัดการ',
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
                                        child: Text('ดูรายละเอียด'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('แก้ไขข้อมูล'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'qr',
                                        child: Text('ดู / พิมพ์ QR'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'test',
                                        child: Text('ทดสอบอุปกรณ์'),
                                      ),
                                      PopupMenuItem(
                                        value: 'toggle',
                                        child: Text(
                                          device.status == 'ปิดใช้งาน'
                                              ? 'เปิดใช้งาน'
                                              : 'ปิดใช้งาน',
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
                    ),
                  );
                }

                return Column(
                  children: devices.map((_DeviceRecord device) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DeviceMobileCard(
                        device: device,
                        onView: () => _showDeviceDetail(device),
                        onEdit: () => _openDeviceForm(device: device),
                        onTest: () => _testDevice(device),
                        onQr: () => _showQrDialog(device),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  Widget _buildMaintenanceAndAlerts() {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        const Widget alerts = _DeviceSectionCard(
          title: 'รายการที่ควรตรวจสอบ',
          subtitle: 'อุปกรณ์ที่ออฟไลน์ มีคำเตือน หรือส่งข้อมูลผิดปกติ',
          child: Column(
            children: [
              _DeviceAlertRow(
                icon: Icons.wifi_off_rounded,
                title: 'SPS30 ไม่ตอบสนอง',
                detail: 'DEV-PM-0004 • B-101 • ออฟไลน์ 28 นาที',
                status: 'เร่งด่วน',
                color: SchoolAdminPalette.red,
              ),
              SizedBox(height: 9),
              _DeviceAlertRow(
                icon: Icons.water_drop_rounded,
                title: 'Water Flow Meter ใช้งานสูงผิดปกติ',
                detail: 'DEV-WTR-0006 • อาคารเรียน B',
                status: 'ตรวจสอบ',
                color: SchoolAdminPalette.secondary,
              ),
              SizedBox(height: 9),
              _DeviceAlertRow(
                icon: Icons.videocam_off_rounded,
                title: 'กล้อง LAB-02 ภาพไม่ต่อเนื่อง',
                detail: 'DEV-CAM-0007 • อาคารปฏิบัติการ',
                status: 'ติดตาม',
                color: SchoolAdminPalette.primaryDark,
              ),
            ],
          ),
        );

        const Widget maintenance = _DeviceSectionCard(
          title: 'แผนบำรุงรักษา',
          subtitle: 'รายการที่ใกล้ถึงกำหนดตรวจหรือเช็กความแม่นยำ',
          child: Column(
            children: [
              _MaintenanceRow(
                title: 'ตรวจ SPS30',
                detail: 'DEV-PM-0004 • กำหนดภายในวันนี้',
                icon: Icons.build_circle_outlined,
                color: SchoolAdminPalette.red,
              ),
              SizedBox(height: 9),
              _MaintenanceRow(
                title: 'ตรวจความแม่นยำ MQ-2',
                detail: 'DEV-SEN-0001 • อีก 6 วัน',
                icon: Icons.tune_rounded,
                color: SchoolAdminPalette.secondary,
              ),
              SizedBox(height: 9),
              _MaintenanceRow(
                title: 'ตรวจ Firmware กล้อง',
                detail: 'DEV-CAM-0007 • อีก 12 วัน',
                icon: Icons.system_update_rounded,
                color: Color(0xFF4F6078),
              ),
            ],
          ),
        );

        if (constraints.maxWidth < 900) {
          return const Column(
            children: [
              alerts,
              SizedBox(height: 14),
              maintenance,
            ],
          );
        }

        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: alerts),
            SizedBox(width: 14),
            Expanded(flex: 4, child: maintenance),
          ],
        );
      },
    );
  }

  Widget _buildLogs() {
    return _DeviceSectionCard(
      title: 'Log การจัดการอุปกรณ์',
      subtitle: 'ประวัติการเพิ่ม แก้ไข ทดสอบ เปิด/ปิด และเหตุผิดปกติล่าสุด',
      child: _logs.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              alignment: Alignment.center,
              child: const Text(
                'ยังไม่มีประวัติการจัดการอุปกรณ์',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            )
          : Column(
              children: _logs.take(6).map((_DeviceLogRecord log) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _DeviceLogRow(log: log),
                );
              }).toList(),
            ),
    );
  }
}

class _DeviceSummaryCard extends StatelessWidget {
  const _DeviceSummaryCard({required this.data});

  final _DeviceSummaryData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool compact = constraints.maxWidth < 240;

        return Container(
          constraints: BoxConstraints(minHeight: compact ? 148 : 130),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DeviceIconBox(icon: data.icon, color: data.color),
                    const SizedBox(height: 10),
                    Text(
                      data.value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _DeviceIconBox(icon: data.icon, color: data.color),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.value,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            data.title,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            data.detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: SchoolAdminPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _DeviceSectionCard extends StatelessWidget {
  const _DeviceSectionCard({
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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              height: 1.4,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          child,
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: Row(
            children: [
              _DeviceIconBox(
                icon: data.icon,
                color: SchoolAdminPalette.primaryDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.5,
                        height: 1.35,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: SchoolAdminPalette.textMuted,
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DeviceIconBox(icon: data.icon, color: data.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
              ),
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: data.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.detail,
            style: const TextStyle(
              fontSize: 8.5,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: data.progress,
              minHeight: 7,
              backgroundColor: SchoolAdminPalette.sandSoft,
              valueColor: AlwaysStoppedAnimation<Color>(data.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceFilterDropdown extends StatelessWidget {
  const _DeviceFilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }
}

class _DeviceDialogDropdown extends StatelessWidget {
  const _DeviceDialogDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }
}

class _DeviceTableHeader extends StatelessWidget {
  const _DeviceTableHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 17,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: SchoolAdminPalette.textPrimary,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 13,
      ),
      child: Center(child: child),
    );
  }
}

class _DeviceTableNameCell extends StatelessWidget {
  const _DeviceTableNameCell({
    required this.device,
    required this.onTap,
  });

  final _DeviceRecord device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 19,
              backgroundColor: SchoolAdminPalette.primarySoft,
              child: Icon(
                Icons.memory_rounded,
                size: 18,
                color: SchoolAdminPalette.primaryDark,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${device.deviceCode} • ${device.serialNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8,
                      color: SchoolAdminPalette.textSecondary,
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: SchoolAdminPalette.primarySoft,
                child: Icon(
                  Icons.memory_rounded,
                  color: SchoolAdminPalette.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    Text(
                      '${device.deviceCode} • ${device.category}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DeviceStatusBadge(value: device.status),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DeviceHealthBadge(value: device.health),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SchoolAdminPalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${device.building} • ${device.room}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ชุดฝึก: ${device.trainingKit} • ล่าสุด: ${device.lastSeen}',
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onQr,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 17),
                  label: const Text('QR'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTest,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 17),
                  label: const Text('ทดสอบ'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 17),
                  label: const Text('แก้ไข'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceCategoryBadge extends StatelessWidget {
  const _DeviceCategoryBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    Color color = SchoolAdminPalette.primaryDark;

    if (value == 'มิเตอร์ไฟฟ้า') {
      color = SchoolAdminPalette.secondary;
    } else if (value == 'มิเตอร์น้ำ') {
      color = const Color(0xFF4F6078);
    } else if (value == 'กล้อง') {
      color = SchoolAdminPalette.red;
    } else if (value == 'อุปกรณ์ควบคุม') {
      color = SchoolAdminPalette.green;
    }

    return _DeviceBadge(label: value, color: color);
  }
}

class _DeviceStatusBadge extends StatelessWidget {
  const _DeviceStatusBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (value) {
      case 'ออนไลน์':
        color = SchoolAdminPalette.green;
        break;
      case 'ออฟไลน์':
        color = SchoolAdminPalette.red;
        break;
      case 'ตรวจสอบ':
        color = SchoolAdminPalette.secondary;
        break;
      default:
        color = SchoolAdminPalette.textMuted;
    }

    return _DeviceBadge(label: value, color: color);
  }
}

class _DeviceHealthBadge extends StatelessWidget {
  const _DeviceHealthBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final Color color = value == 'ปกติ'
        ? SchoolAdminPalette.green
        : value == 'คำเตือน'
            ? SchoolAdminPalette.secondary
            : SchoolAdminPalette.red;

    return _DeviceBadge(label: value, color: color);
  }
}

class _DeviceBadge extends StatelessWidget {
  const _DeviceBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _DeviceAlertRow extends StatelessWidget {
  const _DeviceAlertRow({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          _DeviceIconBox(icon: icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 9,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _DeviceBadge(label: status, color: color),
        ],
      ),
    );
  }
}

class _MaintenanceRow extends StatelessWidget {
  const _MaintenanceRow({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          _DeviceIconBox(icon: icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 9,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _DeviceLogRow extends StatelessWidget {
  const _DeviceLogRow({required this.log});

  final _DeviceLogRecord log;

  Color get color {
    switch (log.type) {
      case 'success':
        return SchoolAdminPalette.green;
      case 'danger':
        return SchoolAdminPalette.red;
      default:
        return SchoolAdminPalette.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool mobile = constraints.maxWidth < 760;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${log.action} • ${log.target}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.detail,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${log.time} • โดย ${log.by}',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _DeviceIconBox(
                      icon: Icons.history_rounded,
                      color: color,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${log.action} • ${log.target}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: SchoolAdminPalette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Text(
                        log.detail,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: SchoolAdminPalette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        log.time,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        log.by,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: SchoolAdminPalette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _DeviceDetailStatus extends StatelessWidget {
  const _DeviceDetailStatus({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceDetailRow extends StatelessWidget {
  const _DeviceDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: SchoolAdminPalette.primaryDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceIconBox extends StatelessWidget {
  const _DeviceIconBox({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withAlpha(80),
          width: 1.1,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}

class _DeviceEmptyState extends StatelessWidget {
  const _DeviceEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 46,
            color: SchoolAdminPalette.textMuted,
          ),
          SizedBox(height: 10),
          Text(
            'ไม่พบอุปกรณ์',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
          Text(
            'ลองเปลี่ยนคำค้นหาหรือล้างตัวกรอง',
            style: TextStyle(
              fontSize: 10,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

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
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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
