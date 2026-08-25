import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../theme/school_admin_palette.dart';

class SchoolBuildingsPage extends StatefulWidget {
  const SchoolBuildingsPage({super.key});

  @override
  State<SchoolBuildingsPage> createState() => _SchoolBuildingsPageState();
}

class _SchoolBuildingsPageState extends State<SchoolBuildingsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedBuilding = 'ทุกอาคาร';
  String _selectedType = 'ทุกประเภท';
  String _selectedStatus = 'ทุกสถานะ';

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final buildings = await SchoolAdminPlatformService().fetchBuildings();
      final rooms = await SchoolAdminPlatformService().fetchRooms();
      final logs = await SchoolAdminPlatformService().fetchAuditLogs(limit: 6);
      if (!mounted) return;
      setState(() {
        _buildings = buildings.map((b) => _BuildingRecord(
          id: b.id,
          code: b.code,
          name: b.name,
          floors: b.floors,
          rooms: b.roomsCount,
          manager: b.managerName,
          devices: b.devicesCount,
          trainingKits: b.trainingKitsCount,
          status: b.status == 'active' ? 'ใช้งาน' : 'ตรวจสอบ',
          note: b.note,
        )).toList();

        _rooms = rooms.map((r) => _RoomRecord(
          id: r.id,
          code: r.code,
          name: r.name,
          building: r.buildingName,
          floor: r.floor,
          type: r.roomType,
          capacity: r.capacity,
          teacher: r.teacherName,
          devices: r.devicesCount,
          trainingKits: r.trainingKitsCount,
          status: r.status == 'active' ? 'พร้อมใช้งาน' : 'ตรวจสอบ',
          resourceStatus: r.resourceStatus,
        )).toList();

        _logs = logs.map((l) => _BuildingLogRecord(
          time: '${l.createdAt.hour.toString().padLeft(2, '0')}:${l.createdAt.minute.toString().padLeft(2, '0')} น.',
          action: l.action,
          target: l.target,
          detail: l.detail.isNotEmpty ? l.detail : l.target,
          by: l.actorName,
          type: 'success',
        )).toList();

        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<_BuildingRecord> _buildings = [];
  List<_RoomRecord> _rooms = [];
  List<_BuildingLogRecord> _logs = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_RoomRecord> get _filteredRooms {
    final String keyword = _searchController.text.trim().toLowerCase();

    return _rooms.where((_RoomRecord room) {
      final bool matchesSearch = keyword.isEmpty ||
          room.code.toLowerCase().contains(keyword) ||
          room.name.toLowerCase().contains(keyword) ||
          room.building.toLowerCase().contains(keyword) ||
          room.teacher.toLowerCase().contains(keyword);

      final bool matchesBuilding =
          _selectedBuilding == 'ทุกอาคาร' || room.building == _selectedBuilding;

      final bool matchesType =
          _selectedType == 'ทุกประเภท' || room.type == _selectedType;

      final bool matchesStatus =
          _selectedStatus == 'ทุกสถานะ' || room.status == _selectedStatus;

      return matchesSearch && matchesBuilding && matchesType && matchesStatus;
    }).toList();
  }

  int get _activeBuildingCount =>
      _buildings.where((item) => item.status == 'ใช้งาน').length;

  int get _readyRoomCount =>
      _rooms.where((item) => item.status == 'พร้อมใช้งาน').length;

  int get _attentionRoomCount =>
      _rooms.where((item) => item.status == 'ตรวจสอบ').length;

  int get _totalDevices =>
      _buildings.fold<int>(0, (sum, item) => sum + item.devices);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedBuilding = 'ทุกอาคาร';
      _selectedType = 'ทุกประเภท';
      _selectedStatus = 'ทุกสถานะ';
    });
  }

  Future<void> _openBuildingForm({_BuildingRecord? building}) async {
    final bool editing = building != null;

    final TextEditingController codeController = TextEditingController(
      text: building?.code ?? '',
    );
    final TextEditingController nameController = TextEditingController(
      text: building?.name ?? '',
    );
    final TextEditingController floorsController = TextEditingController(
      text: building?.floors.toString() ?? '1',
    );
    final TextEditingController managerController = TextEditingController(
      text: building?.manager ?? '',
    );
    final TextEditingController noteController = TextEditingController(
      text: building?.note ?? '',
    );

    String status = building?.status ?? 'ใช้งาน';

    final _BuildingRecord? result = await showDialog<_BuildingRecord>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(16),
          title: Text(
            editing ? 'แก้ไขข้อมูลอาคาร' : 'สร้างอาคารใหม่',
          ),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (
                  BuildContext context,
                  StateSetter setDialogState,
                ) {
                  return Column(
                    children: [
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'รหัสอาคาร',
                          hintText: 'เช่น BLD-C',
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่ออาคาร',
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: floorsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'จำนวนชั้น',
                          prefixIcon: Icon(Icons.layers_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: managerController,
                        decoration: const InputDecoration(
                          labelText: 'ครูประจำอาคาร / ผู้รับผิดชอบ',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BuildingDialogDropdown(
                        label: 'สถานะอาคาร',
                        icon: Icons.verified_rounded,
                        value: status,
                        items: const [
                          'ใช้งาน',
                          'ตรวจสอบ',
                          'ปิดใช้งาน',
                        ],
                        onChanged: (String value) {
                          setDialogState(() => status = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'หมายเหตุ',
                          prefixIcon: Icon(Icons.notes_rounded),
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
                final int floors =
                    int.tryParse(floorsController.text.trim()) ?? 0;

                if (code.isEmpty || name.isEmpty || floors <= 0) {
                  _showMessage('กรุณากรอกรหัส ชื่ออาคาร และจำนวนชั้น');
                  return;
                }

                Navigator.of(dialogContext).pop(
                  _BuildingRecord(
                    id: building?.id ??
                        'building-${DateTime.now().millisecondsSinceEpoch}',
                    code: code,
                    name: name,
                    floors: floors,
                    rooms: building?.rooms ?? 0,
                    manager: managerController.text.trim().isEmpty
                        ? 'ยังไม่กำหนด'
                        : managerController.text.trim(),
                    devices: building?.devices ?? 0,
                    trainingKits: building?.trainingKits ?? 0,
                    status: status,
                    note: noteController.text.trim().isEmpty
                        ? 'ไม่มีหมายเหตุ'
                        : noteController.text.trim(),
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: Text(editing ? 'บันทึกการแก้ไข' : 'สร้างอาคาร'),
            ),
          ],
        );
      },
    );

    codeController.dispose();
    nameController.dispose();
    floorsController.dispose();
    managerController.dispose();
    noteController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      if (editing) {
        final int index = _buildings.indexWhere((item) => item.id == result.id);
        if (index >= 0) {
          _buildings[index] = result;
        }

        _logs.insert(
          0,
          _BuildingLogRecord(
            time: 'เมื่อสักครู่',
            action: 'แก้ไขอาคาร',
            target: result.name,
            detail: 'อัปเดตข้อมูลอาคารและผู้รับผิดชอบ',
            by: 'ผู้ดูแลโรงเรียน',
            type: 'update',
          ),
        );
      } else {
        _buildings.insert(0, result);

        _logs.insert(
          0,
          _BuildingLogRecord(
            time: 'เมื่อสักครู่',
            action: 'สร้างอาคาร',
            target: result.name,
            detail: 'เพิ่มอาคารใหม่เข้าสู่ระบบ',
            by: 'ผู้ดูแลโรงเรียน',
            type: 'success',
          ),
        );
      }
    });

    _showMessage(
      editing ? 'บันทึกข้อมูลอาคารแล้ว' : 'สร้างอาคารใหม่แล้ว',
    );
  }

  Future<void> _openRoomForm(
      {_RoomRecord? room, String? initialBuilding}) async {
    final bool editing = room != null;

    final TextEditingController codeController = TextEditingController(
      text: room?.code ?? '',
    );
    final TextEditingController nameController = TextEditingController(
      text: room?.name ?? '',
    );
    final TextEditingController capacityController = TextEditingController(
      text: room?.capacity.toString() ?? '40',
    );
    final TextEditingController teacherController = TextEditingController(
      text: room?.teacher ?? '',
    );

    String building = room?.building ??
        initialBuilding ??
        (_buildings.isNotEmpty ? _buildings.first.name : 'อาคารเรียน A');
    String floor = room?.floor ?? 'ชั้น 1';
    String type = room?.type ?? 'ห้องเรียน';
    String status = room?.status ?? 'พร้อมใช้งาน';

    final _RoomRecord? result = await showDialog<_RoomRecord>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(16),
          title: Text(editing ? 'แก้ไขข้อมูลห้อง' : 'สร้างห้องใหม่'),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (
                  BuildContext context,
                  StateSetter setDialogState,
                ) {
                  return LayoutBuilder(
                    builder: (
                      BuildContext context,
                      BoxConstraints constraints,
                    ) {
                      final bool oneColumn = constraints.maxWidth < 620;
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
                                labelText: 'รหัสห้อง',
                                hintText: 'เช่น A-301',
                                prefixIcon: Icon(Icons.tag_rounded),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'ชื่อห้อง',
                                prefixIcon: Icon(Icons.meeting_room_rounded),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _BuildingDialogDropdown(
                              label: 'อาคาร',
                              icon: Icons.apartment_rounded,
                              value: building,
                              items:
                                  _buildings.map((item) => item.name).toList(),
                              onChanged: (String value) {
                                setDialogState(() => building = value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _BuildingDialogDropdown(
                              label: 'ชั้น',
                              icon: Icons.layers_rounded,
                              value: floor,
                              items: const [
                                'ชั้น 1',
                                'ชั้น 2',
                                'ชั้น 3',
                                'ชั้น 4',
                                'ชั้น 5',
                              ],
                              onChanged: (String value) {
                                setDialogState(() => floor = value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _BuildingDialogDropdown(
                              label: 'ประเภทห้อง',
                              icon: Icons.category_rounded,
                              value: type,
                              items: const [
                                'ห้องเรียน',
                                'ห้องปฏิบัติการ',
                                'ห้องประชุม',
                                'ห้องสำนักงาน',
                                'ห้องเก็บอุปกรณ์',
                              ],
                              onChanged: (String value) {
                                setDialogState(() => type = value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: capacityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'ความจุ',
                                prefixIcon: Icon(Icons.groups_rounded),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: TextField(
                              controller: teacherController,
                              decoration: const InputDecoration(
                                labelText: 'ครู / ผู้ดูแลห้อง',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth,
                            child: _BuildingDialogDropdown(
                              label: 'สถานะห้อง',
                              icon: Icons.verified_rounded,
                              value: status,
                              items: const [
                                'พร้อมใช้งาน',
                                'ตรวจสอบ',
                                'ปิดใช้งาน',
                              ],
                              onChanged: (String value) {
                                setDialogState(() => status = value);
                              },
                            ),
                          ),
                        ],
                      );
                    },
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
                final int capacity =
                    int.tryParse(capacityController.text.trim()) ?? 0;

                if (code.isEmpty || name.isEmpty || capacity <= 0) {
                  _showMessage('กรุณากรอกรหัส ชื่อห้อง และความจุ');
                  return;
                }

                Navigator.of(dialogContext).pop(
                  _RoomRecord(
                    id: room?.id ??
                        'room-${DateTime.now().millisecondsSinceEpoch}',
                    code: code,
                    name: name,
                    building: building,
                    floor: floor,
                    type: type,
                    capacity: capacity,
                    teacher: teacherController.text.trim().isEmpty
                        ? 'ยังไม่กำหนด'
                        : teacherController.text.trim(),
                    devices: room?.devices ?? 0,
                    trainingKits: room?.trainingKits ?? 0,
                    status: status,
                    resourceStatus: room?.resourceStatus ?? 'ปกติ',
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: Text(editing ? 'บันทึกการแก้ไข' : 'สร้างห้อง'),
            ),
          ],
        );
      },
    );

    codeController.dispose();
    nameController.dispose();
    capacityController.dispose();
    teacherController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      if (editing) {
        final int index = _rooms.indexWhere((item) => item.id == result.id);
        if (index >= 0) {
          _rooms[index] = result;
        }

        _logs.insert(
          0,
          _BuildingLogRecord(
            time: 'เมื่อสักครู่',
            action: 'แก้ไขห้อง',
            target: result.code,
            detail: '${result.building} • ${result.name}',
            by: 'ผู้ดูแลโรงเรียน',
            type: 'update',
          ),
        );
      } else {
        _rooms.insert(0, result);

        final int buildingIndex =
            _buildings.indexWhere((item) => item.name == result.building);
        if (buildingIndex >= 0) {
          final _BuildingRecord oldBuilding = _buildings[buildingIndex];
          _buildings[buildingIndex] = oldBuilding.copyWith(
            rooms: oldBuilding.rooms + 1,
          );
        }

        _logs.insert(
          0,
          _BuildingLogRecord(
            time: 'เมื่อสักครู่',
            action: 'สร้างห้อง',
            target: result.code,
            detail: '${result.building} • ${result.name}',
            by: 'ผู้ดูแลโรงเรียน',
            type: 'success',
          ),
        );
      }
    });

    _showMessage(editing ? 'บันทึกข้อมูลห้องแล้ว' : 'สร้างห้องใหม่แล้ว');
  }

  Future<void> _deleteRoom(_RoomRecord room) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ลบห้อง'),
          content: Text(
            'ต้องการลบ ${room.code} ${room.name} ออกจากระบบหรือไม่',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: SchoolAdminPalette.red,
              ),
              child: const Text('ยืนยันลบ'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _rooms.removeWhere((item) => item.id == room.id);

      final int buildingIndex =
          _buildings.indexWhere((item) => item.name == room.building);
      if (buildingIndex >= 0) {
        final _BuildingRecord oldBuilding = _buildings[buildingIndex];
        _buildings[buildingIndex] = oldBuilding.copyWith(
          rooms: oldBuilding.rooms > 0 ? oldBuilding.rooms - 1 : 0,
        );
      }

      _logs.insert(
        0,
        _BuildingLogRecord(
          time: 'เมื่อสักครู่',
          action: 'ลบห้อง',
          target: room.code,
          detail: '${room.building} • ${room.name}',
          by: 'ผู้ดูแลโรงเรียน',
          type: 'danger',
        ),
      );
    });

    _showMessage('ลบห้องออกจากระบบแล้ว');
  }

  Future<void> _openBuildingRooms(_BuildingRecord building) async {
    final List<_RoomRecord> rooms = _rooms
        .where((_RoomRecord room) => room.building == building.name)
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.94,
          child: _BuildingRoomsBrowserSheet(
            building: building,
            rooms: rooms,
            onAddRoom: () {
              Navigator.of(sheetContext).pop();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }

                _openRoomForm(initialBuilding: building.name);
              });
            },
            onViewRoom: (_RoomRecord room) {
              Navigator.of(sheetContext).pop();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }

                _showRoomDetail(room);
              });
            },
            onEditRoom: (_RoomRecord room) {
              Navigator.of(sheetContext).pop();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }

                _openRoomForm(room: room);
              });
            },
          ),
        );
      },
    );
  }

  void _showRoomDetail(_RoomRecord room) {
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
                          Icons.meeting_room_rounded,
                          color: SchoolAdminPalette.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${room.code} • ${room.name}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: SchoolAdminPalette.textPrimary,
                              ),
                            ),
                            Text(
                              '${room.building} • ${room.floor}',
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
                  _BuildingDetailRow(
                    icon: Icons.category_rounded,
                    label: 'ประเภทห้อง',
                    value: room.type,
                  ),
                  _BuildingDetailRow(
                    icon: Icons.groups_rounded,
                    label: 'ความจุ',
                    value: '${room.capacity} คน',
                  ),
                  _BuildingDetailRow(
                    icon: Icons.person_rounded,
                    label: 'ครู / ผู้ดูแล',
                    value: room.teacher,
                  ),
                  _BuildingDetailRow(
                    icon: Icons.memory_rounded,
                    label: 'อุปกรณ์',
                    value: '${room.devices} รายการ',
                  ),
                  _BuildingDetailRow(
                    icon: Icons.handyman_rounded,
                    label: 'ชุดฝึก',
                    value: '${room.trainingKits} ชุด',
                  ),
                  _BuildingDetailRow(
                    icon: Icons.verified_rounded,
                    label: 'สถานะห้อง',
                    value: room.status,
                  ),
                  _BuildingDetailRow(
                    icon: Icons.energy_savings_leaf_rounded,
                    label: 'ทรัพยากร / ระบบ',
                    value: room.resourceStatus,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _showMessage(
                              'เปิดหน้าอุปกรณ์ของ ${room.code} แล้ว',
                            );
                          },
                          icon: const Icon(Icons.memory_rounded),
                          label: const Text('ดูอุปกรณ์'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _openRoomForm(room: room);
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('แก้ไขห้อง'),
                        ),
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

  @override
  Widget build(BuildContext context) {
    final List<_RoomRecord> rooms = _filteredRooms;

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
                  _buildBuildingOverview(),
                  const SizedBox(height: 14),
                  _buildFilters(),
                  const SizedBox(height: 14),
                  _buildRooms(rooms),
                  const SizedBox(height: 14),
                  _buildMonitoring(),
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
                  Icons.apartment_rounded,
                  color: SchoolAdminPalette.primaryDark,
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'อาคารและห้อง',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'สร้างและดูแลอาคาร ห้องเรียน ห้องปฏิบัติการ '
                      'กำหนดผู้รับผิดชอบ ตรวจอุปกรณ์ ชุดฝึก และสถานะพื้นที่',
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
                onPressed: () => _openRoomForm(),
                icon: const Icon(Icons.add_home_work_rounded),
                label: const Text('สร้างห้อง'),
              ),
              FilledButton.icon(
                onPressed: () => _openBuildingForm(),
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('สร้างอาคาร'),
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
    final List<_BuildingSummaryData> items = [
      _BuildingSummaryData(
        title: 'อาคารทั้งหมด',
        value: '${_buildings.length}',
        detail: 'ใช้งานปกติ $_activeBuildingCount อาคาร',
        icon: Icons.apartment_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _BuildingSummaryData(
        title: 'ห้องทั้งหมด',
        value: '${_rooms.length}',
        detail: 'พร้อมใช้งาน $_readyRoomCount ห้อง',
        icon: Icons.meeting_room_rounded,
        color: const Color(0xFF4F6078),
      ),
      _BuildingSummaryData(
        title: 'อุปกรณ์ในพื้นที่',
        value: '$_totalDevices',
        detail: 'อุปกรณ์ที่ผูกกับอาคาร',
        icon: Icons.memory_rounded,
        color: SchoolAdminPalette.green,
      ),
      _BuildingSummaryData(
        title: 'ควรตรวจสอบ',
        value: '$_attentionRoomCount',
        detail: 'ห้องหรือระบบที่มีความผิดปกติ',
        icon: Icons.notifications_active_rounded,
        color: SchoolAdminPalette.red,
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
          children: items.map((_BuildingSummaryData item) {
            return SizedBox(
              width: width,
              child: _BuildingSummaryCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final List<_BuildingQuickActionData> actions = [
      _BuildingQuickActionData(
        title: 'สร้างอาคารใหม่',
        subtitle: 'เพิ่มอาคารและกำหนดผู้รับผิดชอบ',
        icon: Icons.add_business_rounded,
        onTap: () => _openBuildingForm(),
      ),
      _BuildingQuickActionData(
        title: 'สร้างห้องใหม่',
        subtitle: 'เพิ่มห้องและผูกเข้ากับอาคาร',
        icon: Icons.add_home_work_rounded,
        onTap: () => _openRoomForm(),
      ),
      _BuildingQuickActionData(
        title: 'กำหนดครูประจำอาคาร',
        subtitle: 'ระบุผู้รับผิดชอบและรับแจ้งเตือน',
        icon: Icons.engineering_rounded,
        onTap: () {
          _showMessage('เปิดการกำหนดครูประจำอาคาร');
        },
      ),
      _BuildingQuickActionData(
        title: 'ตรวจพื้นที่ผิดปกติ',
        subtitle: 'ดูห้องที่มีอุปกรณ์หรือทรัพยากรผิดปกติ',
        icon: Icons.warning_amber_rounded,
        onTap: () {
          setState(() => _selectedStatus = 'ตรวจสอบ');
        },
      ),
    ];

    return _BuildingSectionCard(
      title: 'จัดการได้อย่างรวดเร็ว',
      subtitle: 'รวมงานที่ใช้บ่อยไว้ในจุดเดียว',
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
            children: actions.map((_BuildingQuickActionData item) {
              return SizedBox(
                width: width,
                child: _BuildingQuickActionCard(data: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildBuildingOverview() {
    Widget content;
    if (_loading && _buildings.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    } else if (_error != null && _buildings.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: SchoolAdminPalette.red, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'โหลดข้อมูลอาคารไม่สำเร็จ',
                style: TextStyle(fontSize: 12, color: SchoolAdminPalette.textSecondary),
              ),
            ),
            TextButton(
              onPressed: _loadData,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    } else if (_buildings.isEmpty) {
      content = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SchoolAdminPalette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.apartment_rounded, size: 40, color: SchoolAdminPalette.textSecondary),
            const SizedBox(height: 8),
            const Text(
              'ยังไม่มีข้อมูลอาคารในระบบ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'กดปุ่มด้านล่างเพื่อเพิ่มอาคารเรียนหรืออาคารปฏิบัติการแรก',
              style: TextStyle(fontSize: 12, color: SchoolAdminPalette.textSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openBuildingForm(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('เพิ่มอาคารแรก'),
              style: FilledButton.styleFrom(
                backgroundColor: SchoolAdminPalette.primaryDark,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else {
      content = LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          int columns = 3;
          if (constraints.maxWidth < 1050) columns = 2;
          if (constraints.maxWidth < 650) columns = 1;

          const double spacing = 10;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: _buildings.map((_BuildingRecord item) {
              return SizedBox(
                width: width,
                child: _BuildingOverviewCard(
                  building: item,
                  onEdit: () => _openBuildingForm(building: item),
                  onOpenRooms: () {
                    _openBuildingRooms(item);
                  },
                ),
              );
            }).toList(),
          );
        },
      );
    }

    return _BuildingSectionCard(
      title: 'ภาพรวมอาคาร',
      subtitle: 'ดูจำนวนห้อง ผู้รับผิดชอบ อุปกรณ์ ชุดฝึก และสถานะของแต่ละอาคาร',
      child: content,
    );
  }

  Widget _buildFilters() {
    return _BuildingSectionCard(
      title: 'ค้นหาและกรองห้อง',
      subtitle: 'ค้นหาจากรหัสห้อง ชื่อห้อง อาคาร หรือผู้รับผิดชอบ',
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          final Widget search = TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ค้นหารหัสห้อง ชื่อห้อง อาคาร หรือครูผู้ดูแล',
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

          final Widget building = _BuildingFilterDropdown(
            label: 'อาคาร',
            value: _selectedBuilding,
            items: [
              'ทุกอาคาร',
              ..._buildings.map((item) => item.name),
            ],
            onChanged: (String value) {
              setState(() => _selectedBuilding = value);
            },
          );

          final Widget type = _BuildingFilterDropdown(
            label: 'ประเภทห้อง',
            value: _selectedType,
            items: const [
              'ทุกประเภท',
              'ห้องเรียน',
              'ห้องปฏิบัติการ',
              'ห้องประชุม',
              'ห้องสำนักงาน',
              'ห้องเก็บอุปกรณ์',
            ],
            onChanged: (String value) {
              setState(() => _selectedType = value);
            },
          );

          final Widget status = _BuildingFilterDropdown(
            label: 'สถานะ',
            value: _selectedStatus,
            items: const [
              'ทุกสถานะ',
              'พร้อมใช้งาน',
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
                    Expanded(child: building),
                    const SizedBox(width: 10),
                    Expanded(child: type),
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
              Expanded(child: building),
              const SizedBox(width: 10),
              Expanded(child: type),
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

  Widget _buildRooms(List<_RoomRecord> rooms) {
    return _BuildingSectionCard(
      title: 'รายการห้อง',
      subtitle: 'พบ ${rooms.length} รายการ',
      child: rooms.isEmpty
          ? const _BuildingEmptyState()
          : LayoutBuilder(
              builder: (
                BuildContext context,
                BoxConstraints constraints,
              ) {
                if (constraints.maxWidth >= 1050) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: SchoolAdminPalette.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Table(
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: SchoolAdminPalette.border,
                        ),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(1.7),
                        1: FlexColumnWidth(1.55),
                        2: FlexColumnWidth(1.1),
                        3: FlexColumnWidth(1.15),
                        4: FlexColumnWidth(1.35),
                        5: FlexColumnWidth(1.0),
                        6: FlexColumnWidth(1.15),
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
                            _RoomTableHeader(text: 'ห้อง'),
                            _RoomTableHeader(text: 'อาคาร / ชั้น'),
                            _RoomTableHeader(text: 'ประเภท'),
                            _RoomTableHeader(text: 'ผู้ดูแล'),
                            _RoomTableHeader(text: 'อุปกรณ์ / ชุดฝึก'),
                            _RoomTableHeader(text: 'สถานะ'),
                            _RoomTableHeader(text: 'ระบบ / ทรัพยากร'),
                            _RoomTableHeader(text: 'จัดการ'),
                          ],
                        ),
                        ...rooms.map((_RoomRecord room) {
                          return TableRow(
                            children: [
                              _RoomTableNameCell(
                                room: room,
                                onTap: () => _showRoomDetail(room),
                              ),
                              _RoomTableCell(
                                child: Text(
                                  '${room.building}\n${room.floor}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    height: 1.4,
                                    fontWeight: FontWeight.w700,
                                    color: SchoolAdminPalette.textPrimary,
                                  ),
                                ),
                              ),
                              _RoomTableCell(
                                child: _RoomTypeBadge(value: room.type),
                              ),
                              _RoomTableCell(
                                child: Text(
                                  room.teacher,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    height: 1.35,
                                    color: SchoolAdminPalette.textPrimary,
                                  ),
                                ),
                              ),
                              _RoomTableCell(
                                child: Text(
                                  '${room.devices} อุปกรณ์\n${room.trainingKits} ชุดฝึก',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w700,
                                    color: SchoolAdminPalette.textPrimary,
                                  ),
                                ),
                              ),
                              _RoomTableCell(
                                child: _RoomStatusBadge(value: room.status),
                              ),
                              _RoomTableCell(
                                child: _ResourceBadge(
                                  value: room.resourceStatus,
                                ),
                              ),
                              _RoomTableCell(
                                child: PopupMenuButton<String>(
                                  tooltip: 'จัดการ',
                                  onSelected: (String value) {
                                    switch (value) {
                                      case 'view':
                                        _showRoomDetail(room);
                                        break;
                                      case 'edit':
                                        _openRoomForm(room: room);
                                        break;
                                      case 'devices':
                                        _showMessage(
                                          'เปิดรายการอุปกรณ์ของ ${room.code}',
                                        );
                                        break;
                                      case 'delete':
                                        _deleteRoom(room);
                                        break;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return const [
                                      PopupMenuItem(
                                        value: 'view',
                                        child: Text('ดูรายละเอียด'),
                                      ),
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('แก้ไขห้อง'),
                                      ),
                                      PopupMenuItem(
                                        value: 'devices',
                                        child: Text('ดูอุปกรณ์ในห้อง'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('ลบห้อง'),
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
                  children: rooms.map((_RoomRecord room) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RoomMobileCard(
                        room: room,
                        onView: () => _showRoomDetail(room),
                        onEdit: () => _openRoomForm(room: room),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  Widget _buildMonitoring() {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        const Widget alerts = _BuildingSectionCard(
          title: 'รายการที่ควรตรวจสอบ',
          subtitle: 'รวมพื้นที่ที่อุปกรณ์หรือการใช้ทรัพยากรมีความผิดปกติ',
          child: Column(
            children: [
              _BuildingAlertRow(
                icon: Icons.memory_rounded,
                title: 'อุปกรณ์ออฟไลน์',
                detail: 'LAB-02 • อาคารปฏิบัติการ • 2 อุปกรณ์',
                status: 'เร่งด่วน',
                color: SchoolAdminPalette.red,
              ),
              SizedBox(height: 9),
              _BuildingAlertRow(
                icon: Icons.water_drop_rounded,
                title: 'การใช้น้ำสูงกว่าปกติ',
                detail: 'B-101 • อาคารเรียน B',
                status: 'ตรวจสอบ',
                color: SchoolAdminPalette.secondary,
              ),
              SizedBox(height: 9),
              _BuildingAlertRow(
                icon: Icons.sensors_rounded,
                title: 'เซนเซอร์อาคารกีฬารอตรวจสอบ',
                detail: 'อาคารกีฬา • 1 จุด',
                status: 'ติดตาม',
                color: SchoolAdminPalette.primaryDark,
              ),
            ],
          ),
        );

        final Widget assignments = _BuildingSectionCard(
          title: 'ผู้รับผิดชอบอาคาร',
          subtitle: 'ตรวจสอบว่าทุกอาคารมีครูหรือผู้รับผิดชอบแล้ว',
          child: _buildings.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    'ยังไม่มีข้อมูลอาคาร',
                    style: TextStyle(fontSize: 12, color: SchoolAdminPalette.textSecondary),
                  ),
                )
              : Column(
                  children: _buildings.take(5).map((_BuildingRecord item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _BuildingManagerRow(building: item),
                    );
                  }).toList(),
                ),
        );

        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              alerts,
              const SizedBox(height: 14),
              assignments,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(flex: 5, child: alerts),
            const SizedBox(width: 14),
            Expanded(flex: 4, child: assignments),
          ],
        );
      },
    );
  }

  Widget _buildLogs() {
    return _BuildingSectionCard(
      title: 'Log การจัดการอาคารและห้อง',
      subtitle: 'ดูประวัติการสร้าง แก้ไข และเปลี่ยนข้อมูลพื้นที่ล่าสุด',
      child: _logs.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              alignment: Alignment.center,
              child: const Text(
                'ยังไม่มีประวัติการจัดการอาคารและห้อง',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            )
          : Column(
              children: _logs.take(6).map((_BuildingLogRecord log) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _BuildingLogRow(log: log),
                );
              }).toList(),
            ),
    );
  }
}

class _BuildingSummaryCard extends StatelessWidget {
  const _BuildingSummaryCard({required this.data});

  final _BuildingSummaryData data;

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
                    _BuildingIconBox(
                      icon: data.icon,
                      color: data.color,
                    ),
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
                    _BuildingIconBox(
                      icon: data.icon,
                      color: data.color,
                    ),
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

class _BuildingSectionCard extends StatelessWidget {
  const _BuildingSectionCard({
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
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
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

class _BuildingQuickActionCard extends StatelessWidget {
  const _BuildingQuickActionCard({required this.data});

  final _BuildingQuickActionData data;

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
              _BuildingIconBox(
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
                        fontSize: 13.5,
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

class _BuildingRoomsBrowserSheet extends StatefulWidget {
  const _BuildingRoomsBrowserSheet({
    required this.building,
    required this.rooms,
    required this.onAddRoom,
    required this.onViewRoom,
    required this.onEditRoom,
  });

  final _BuildingRecord building;
  final List<_RoomRecord> rooms;
  final VoidCallback onAddRoom;
  final ValueChanged<_RoomRecord> onViewRoom;
  final ValueChanged<_RoomRecord> onEditRoom;

  @override
  State<_BuildingRoomsBrowserSheet> createState() =>
      _BuildingRoomsBrowserSheetState();
}

class _BuildingRoomsBrowserSheetState
    extends State<_BuildingRoomsBrowserSheet> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFloor = 'ทุกชั้น';
  String _selectedStatus = 'ทุกสถานะ';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _floors {
    final List<String> values =
        widget.rooms.map((_RoomRecord room) => room.floor).toSet().toList();

    values.sort();
    return values;
  }

  List<_RoomRecord> get _filteredRooms {
    final String keyword = _searchController.text.trim().toLowerCase();

    final List<_RoomRecord> result = widget.rooms.where((_RoomRecord room) {
      final bool matchesSearch = keyword.isEmpty ||
          room.code.toLowerCase().contains(keyword) ||
          room.name.toLowerCase().contains(keyword) ||
          room.type.toLowerCase().contains(keyword) ||
          room.teacher.toLowerCase().contains(keyword);

      final bool matchesFloor =
          _selectedFloor == 'ทุกชั้น' || room.floor == _selectedFloor;

      final bool matchesStatus =
          _selectedStatus == 'ทุกสถานะ' || room.status == _selectedStatus;

      return matchesSearch && matchesFloor && matchesStatus;
    }).toList();

    result.sort((_RoomRecord a, _RoomRecord b) {
      final int floorCompare = a.floor.compareTo(b.floor);
      if (floorCompare != 0) {
        return floorCompare;
      }

      return a.code.compareTo(b.code);
    });

    return result;
  }

  int get _readyCount => widget.rooms
      .where((_RoomRecord room) => room.status == 'พร้อมใช้งาน')
      .length;

  int get _attentionCount =>
      widget.rooms.where((_RoomRecord room) => room.status == 'ตรวจสอบ').length;

  int get _totalCapacity => widget.rooms.fold<int>(
        0,
        (int total, _RoomRecord room) => total + room.capacity,
      );

  int get _totalDevices => widget.rooms.fold<int>(
        0,
        (int total, _RoomRecord room) => total + room.devices,
      );

  Color _buildingStatusColor(String value) {
    if (value == 'ใช้งาน') {
      return SchoolAdminPalette.green;
    }

    if (value == 'ตรวจสอบ') {
      return SchoolAdminPalette.secondary;
    }

    return SchoolAdminPalette.red;
  }

  @override
  Widget build(BuildContext context) {
    final List<_RoomRecord> rooms = _filteredRooms;
    final Color buildingStatusColor =
        _buildingStatusColor(widget.building.status);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAF7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: SchoolAdminPalette.border,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(
              context: context,
              buildingStatusColor: buildingStatusColor,
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummary(),
                    const SizedBox(height: 16),
                    _buildFilters(),
                    const SizedBox(height: 16),
                    _buildRoomList(rooms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required Color buildingStatusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          final bool compact = constraints.maxWidth < 720;

          final Widget title = Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: SchoolAdminPalette.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SchoolAdminPalette.border,
                  ),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: SchoolAdminPalette.primaryDark,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.building.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.building.code} • '
                      '${widget.building.floors} ชั้น • '
                      'ผู้รับผิดชอบ ${widget.building.manager}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _RoomBrowserBadge(
                label: widget.building.status,
                color: buildingStatusColor,
              ),
              FilledButton.icon(
                onPressed: widget.onAddRoom,
                icon: const Icon(
                  Icons.add_home_work_rounded,
                  size: 18,
                ),
                label: const Text('เพิ่มห้อง'),
              ),
              IconButton.outlined(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'ปิด',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary() {
    final int configuredRooms = widget.building.rooms;
    final int recordedRooms = widget.rooms.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'สรุปข้อมูลห้อง',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: SchoolAdminPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          recordedRooms == configuredRooms
              ? 'รายละเอียดห้องที่บันทึกไว้ในระบบครบ $recordedRooms ห้อง'
              : 'มีรายละเอียดห้องในข้อมูลตัวอย่าง $recordedRooms ห้อง '
                  'จากจำนวนห้องที่กำหนดไว้ $configuredRooms ห้อง',
          style: const TextStyle(
            fontSize: 12,
            height: 1.45,
            color: SchoolAdminPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            int columns = 5;

            if (constraints.maxWidth < 920) {
              columns = 3;
            }

            if (constraints.maxWidth < 620) {
              columns = 2;
            }

            if (constraints.maxWidth < 330) {
              columns = 1;
            }

            const double spacing = 10;
            final double width =
                (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            final List<Widget> items = [
              _RoomBrowserSummaryCard(
                title: 'ห้องในระบบ',
                value: '$recordedRooms',
                detail: 'กำหนดไว้ $configuredRooms ห้อง',
                icon: Icons.meeting_room_rounded,
                color: SchoolAdminPalette.primaryDark,
              ),
              _RoomBrowserSummaryCard(
                title: 'พร้อมใช้งาน',
                value: '$_readyCount',
                detail: 'ห้องที่ใช้งานได้ปกติ',
                icon: Icons.check_circle_rounded,
                color: SchoolAdminPalette.green,
              ),
              _RoomBrowserSummaryCard(
                title: 'ต้องตรวจสอบ',
                value: '$_attentionCount',
                detail: 'ห้องที่มีรายการติดตาม',
                icon: Icons.warning_amber_rounded,
                color: SchoolAdminPalette.secondary,
              ),
              _RoomBrowserSummaryCard(
                title: 'ความจุรวม',
                value: '$_totalCapacity',
                detail: 'คน',
                icon: Icons.groups_rounded,
                color: SchoolAdminPalette.blue,
              ),
              _RoomBrowserSummaryCard(
                title: 'อุปกรณ์',
                value: '$_totalDevices',
                detail: 'รายการในห้อง',
                icon: Icons.memory_rounded,
                color: SchoolAdminPalette.primary,
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items.map((Widget item) {
                return SizedBox(
                  width: width,
                  child: item,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final List<String> floorItems = [
      'ทุกชั้น',
      ..._floors,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SchoolAdminPalette.border,
        ),
      ),
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          final bool oneColumn = constraints.maxWidth < 620;
          final double fieldWidth = oneColumn
              ? constraints.maxWidth
              : (constraints.maxWidth - 20) / 3;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: fieldWidth,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'ค้นหาห้อง',
                    hintText: 'รหัสห้อง ชื่อห้อง ประเภท หรือผู้ดูแล',
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
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'ชั้น',
                    prefixIcon: Icon(Icons.layers_rounded),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFloor,
                      isExpanded: true,
                      items: floorItems.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedFloor = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'สถานะห้อง',
                    prefixIcon: Icon(Icons.verified_rounded),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'ทุกสถานะ',
                          child: Text('ทุกสถานะ'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'พร้อมใช้งาน',
                          child: Text('พร้อมใช้งาน'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'ตรวจสอบ',
                          child: Text('ตรวจสอบ'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'ปิดใช้งาน',
                          child: Text('ปิดใช้งาน'),
                        ),
                      ],
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoomList(List<_RoomRecord> rooms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'รายการห้อง',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
            ),
            Text(
              'พบ ${rooms.length} รายการ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (rooms.isEmpty)
          _buildEmptyRooms()
        else
          LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints constraints,
            ) {
              int columns = 2;

              if (constraints.maxWidth < 780) {
                columns = 1;
              }

              const double spacing = 10;
              final double width =
                  (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: rooms.map((_RoomRecord room) {
                  return SizedBox(
                    width: width,
                    child: _BuildingRoomBrowserCard(
                      room: room,
                      onView: () => widget.onViewRoom(room),
                      onEdit: () => widget.onEditRoom(room),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyRooms() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SchoolAdminPalette.border,
        ),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: SchoolAdminPalette.primarySoft,
            child: Icon(
              Icons.meeting_room_outlined,
              size: 28,
              color: SchoolAdminPalette.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ยังไม่พบห้องตามตัวกรอง',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'ลองเปลี่ยนคำค้นหา ชั้น หรือสถานะ '
            'หรือเพิ่มข้อมูลห้องใหม่ให้กับอาคารนี้',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: widget.onAddRoom,
            icon: const Icon(Icons.add_home_work_rounded),
            label: const Text('เพิ่มห้องใหม่'),
          ),
        ],
      ),
    );
  }
}

class _RoomBrowserSummaryCard extends StatelessWidget {
  const _RoomBrowserSummaryCard({
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: SchoolAdminPalette.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: color.withAlpha(18),
            child: Icon(
              icon,
              size: 21,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.35,
                    color: SchoolAdminPalette.textSecondary,
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

class _BuildingRoomBrowserCard extends StatelessWidget {
  const _BuildingRoomBrowserCard({
    required this.room,
    required this.onView,
    required this.onEdit,
  });

  final _RoomRecord room;
  final VoidCallback onView;
  final VoidCallback onEdit;

  Color get _statusColor {
    if (room.status == 'พร้อมใช้งาน') {
      return SchoolAdminPalette.green;
    }

    if (room.status == 'ตรวจสอบ') {
      return SchoolAdminPalette.secondary;
    }

    return SchoolAdminPalette.red;
  }

  Color get _resourceColor {
    return room.resourceStatus == 'ปกติ'
        ? SchoolAdminPalette.green
        : SchoolAdminPalette.red;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: SchoolAdminPalette.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: SchoolAdminPalette.primarySoft,
                    child: Icon(
                      Icons.meeting_room_rounded,
                      size: 21,
                      color: SchoolAdminPalette.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${room.code} • ${room.name}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${room.floor} • ${room.type}',
                          style: const TextStyle(
                            fontSize: 11,
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _RoomBrowserBadge(
                    label: room.status,
                    color: _statusColor,
                  ),
                  _RoomBrowserBadge(
                    label: 'ระบบ: ${room.resourceStatus}',
                    color: _resourceColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _RoomBrowserInfoRow(
                icon: Icons.person_rounded,
                label: 'ครู / ผู้ดูแล',
                value: room.teacher,
              ),
              const SizedBox(height: 7),
              _RoomBrowserInfoRow(
                icon: Icons.groups_rounded,
                label: 'ความจุ',
                value: '${room.capacity} คน',
              ),
              const SizedBox(height: 7),
              _RoomBrowserInfoRow(
                icon: Icons.memory_rounded,
                label: 'อุปกรณ์',
                value: '${room.devices} รายการ',
              ),
              const SizedBox(height: 7),
              _RoomBrowserInfoRow(
                icon: Icons.handyman_rounded,
                label: 'ชุดฝึก',
                value: '${room.trainingKits} ชุด',
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onView,
                      icon: const Icon(
                        Icons.visibility_rounded,
                        size: 18,
                      ),
                      label: const Text('ดูรายละเอียด'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_rounded,
                      size: 18,
                    ),
                    label: const Text('แก้ไข'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomBrowserInfoRow extends StatelessWidget {
  const _RoomBrowserInfoRow({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: SchoolAdminPalette.primaryDark,
        ),
        const SizedBox(width: 7),
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomBrowserBadge extends StatelessWidget {
  const _RoomBrowserBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withAlpha(50),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _BuildingOverviewCard extends StatelessWidget {
  const _BuildingOverviewCard({
    required this.building,
    required this.onEdit,
    required this.onOpenRooms,
  });

  final _BuildingRecord building;
  final VoidCallback onEdit;
  final VoidCallback onOpenRooms;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BuildingIconBox(
                icon: Icons.apartment_rounded,
                color: SchoolAdminPalette.primaryDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    Text(
                      '${building.code} • ${building.floors} ชั้น',
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _BuildingStatusBadge(value: building.status),
            ],
          ),
          const SizedBox(height: 13),
          _BuildingMetricRow(
            icon: Icons.meeting_room_rounded,
            label: 'ห้อง',
            value: '${building.rooms} ห้อง',
          ),
          const SizedBox(height: 8),
          _BuildingMetricRow(
            icon: Icons.memory_rounded,
            label: 'อุปกรณ์',
            value: '${building.devices} รายการ',
          ),
          const SizedBox(height: 8),
          _BuildingMetricRow(
            icon: Icons.handyman_rounded,
            label: 'ชุดฝึก',
            value: '${building.trainingKits} ชุด',
          ),
          const SizedBox(height: 8),
          _BuildingMetricRow(
            icon: Icons.person_rounded,
            label: 'ผู้รับผิดชอบ',
            value: building.manager,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenRooms,
                  child: const Text('ดูห้อง'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: onEdit,
                tooltip: 'แก้ไขอาคาร',
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuildingMetricRow extends StatelessWidget {
  const _BuildingMetricRow({
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
        Icon(
          icon,
          size: 16,
          color: SchoolAdminPalette.primaryDark,
        ),
        const SizedBox(width: 7),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomTableHeader extends StatelessWidget {
  const _RoomTableHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 17,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          color: SchoolAdminPalette.textPrimary,
        ),
      ),
    );
  }
}

class _RoomTableCell extends StatelessWidget {
  const _RoomTableCell({required this.child});

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

class _RoomTableNameCell extends StatelessWidget {
  const _RoomTableNameCell({
    required this.room,
    required this.onTap,
  });

  final _RoomRecord room;
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
                Icons.meeting_room_rounded,
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
                    room.code,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  Text(
                    room.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
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

class _RoomMobileCard extends StatelessWidget {
  const _RoomMobileCard({
    required this.room,
    required this.onView,
    required this.onEdit,
  });

  final _RoomRecord room;
  final VoidCallback onView;
  final VoidCallback onEdit;

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
                  Icons.meeting_room_rounded,
                  color: SchoolAdminPalette.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${room.code} • ${room.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    Text(
                      '${room.building} • ${room.floor}',
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
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
              Expanded(child: _RoomStatusBadge(value: room.status)),
              const SizedBox(width: 8),
              Expanded(
                child: _ResourceBadge(value: room.resourceStatus),
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
            child: Wrap(
              spacing: 12,
              runSpacing: 7,
              children: [
                Text(
                  'ประเภท: ${room.type}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                Text(
                  'ความจุ: ${room.capacity} คน',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                Text(
                  'อุปกรณ์: ${room.devices}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                Text(
                  'ชุดฝึก: ${room.trainingKits}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 17),
              label: const Text('แก้ไขข้อมูลห้อง'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomTypeBadge extends StatelessWidget {
  const _RoomTypeBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    Color color = SchoolAdminPalette.primaryDark;

    if (value == 'ห้องปฏิบัติการ') {
      color = SchoolAdminPalette.green;
    } else if (value == 'ห้องประชุม') {
      color = SchoolAdminPalette.secondary;
    }

    return _BuildingBadge(
      label: value,
      color: color,
    );
  }
}

class _RoomStatusBadge extends StatelessWidget {
  const _RoomStatusBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final Color color = value == 'พร้อมใช้งาน'
        ? SchoolAdminPalette.green
        : value == 'ตรวจสอบ'
            ? SchoolAdminPalette.secondary
            : SchoolAdminPalette.red;

    return _BuildingBadge(
      label: value,
      color: color,
    );
  }
}

class _BuildingStatusBadge extends StatelessWidget {
  const _BuildingStatusBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final Color color = value == 'ใช้งาน'
        ? SchoolAdminPalette.green
        : value == 'ตรวจสอบ'
            ? SchoolAdminPalette.secondary
            : SchoolAdminPalette.red;

    return _BuildingBadge(
      label: value,
      color: color,
    );
  }
}

class _ResourceBadge extends StatelessWidget {
  const _ResourceBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final Color color =
        value == 'ปกติ' ? SchoolAdminPalette.green : SchoolAdminPalette.red;

    return _BuildingBadge(
      label: value,
      color: color,
    );
  }
}

class _BuildingBadge extends StatelessWidget {
  const _BuildingBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 96,
        minHeight: 34,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
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
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _BuildingFilterDropdown extends StatelessWidget {
  const _BuildingFilterDropdown({
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

class _BuildingDialogDropdown extends StatelessWidget {
  const _BuildingDialogDropdown({
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

class _BuildingAlertRow extends StatelessWidget {
  const _BuildingAlertRow({
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
          _BuildingIconBox(icon: icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _BuildingBadge(
            label: status,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _BuildingManagerRow extends StatelessWidget {
  const _BuildingManagerRow({required this.building});

  final _BuildingRecord building;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: SchoolAdminPalette.primarySoft,
            child: Icon(
              Icons.person_rounded,
              size: 17,
              color: SchoolAdminPalette.primaryDark,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  building.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                Text(
                  building.manager,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _BuildingStatusBadge(value: building.status),
        ],
      ),
    );
  }
}

class _BuildingLogRow extends StatelessWidget {
  const _BuildingLogRow({required this.log});

  final _BuildingLogRecord log;

  Color get color {
    switch (log.type) {
      case 'success':
        return SchoolAdminPalette.green;
      case 'warning':
        return SchoolAdminPalette.secondary;
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
                        fontSize: 11,
                        height: 1.45,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${log.time} • โดย ${log.by}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _BuildingIconBox(
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

class _BuildingDetailRow extends StatelessWidget {
  const _BuildingDetailRow({
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

class _BuildingIconBox extends StatelessWidget {
  const _BuildingIconBox({
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

class _BuildingEmptyState extends StatelessWidget {
  const _BuildingEmptyState();

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
            'ไม่พบห้อง',
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

class _BuildingSummaryData {
  const _BuildingSummaryData({
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

class _BuildingQuickActionData {
  const _BuildingQuickActionData({
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

class _BuildingRecord {
  const _BuildingRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.floors,
    required this.rooms,
    required this.manager,
    required this.devices,
    required this.trainingKits,
    required this.status,
    required this.note,
  });

  final String id;
  final String code;
  final String name;
  final int floors;
  final int rooms;
  final String manager;
  final int devices;
  final int trainingKits;
  final String status;
  final String note;

  _BuildingRecord copyWith({
    int? rooms,
  }) {
    return _BuildingRecord(
      id: id,
      code: code,
      name: name,
      floors: floors,
      rooms: rooms ?? this.rooms,
      manager: manager,
      devices: devices,
      trainingKits: trainingKits,
      status: status,
      note: note,
    );
  }
}

class _RoomRecord {
  const _RoomRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.building,
    required this.floor,
    required this.type,
    required this.capacity,
    required this.teacher,
    required this.devices,
    required this.trainingKits,
    required this.status,
    required this.resourceStatus,
  });

  final String id;
  final String code;
  final String name;
  final String building;
  final String floor;
  final String type;
  final int capacity;
  final String teacher;
  final int devices;
  final int trainingKits;
  final String status;
  final String resourceStatus;
}

class _BuildingLogRecord {
  const _BuildingLogRecord({
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
