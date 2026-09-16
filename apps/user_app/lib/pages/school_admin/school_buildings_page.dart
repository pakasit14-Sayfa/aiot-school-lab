import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

class SchoolBuildingsPage extends StatefulWidget {
  const SchoolBuildingsPage({
    super.key,
    this.loadBuildings,
    this.loadRooms,
    this.loadLogs,
    this.createBuilding,
    this.createRoom,
    this.updateBuilding,
    this.deleteBuilding,
    this.setBuildingManager,
    this.updateRoom,
    this.deleteRoom,
    this.loadAlerts,
    this.loadDevices,
    this.loadStaffDirectory,
  });

  /// Injectable seams for tests — production leaves these null and uses the
  /// real service (same pattern as school_resources_page).
  final Future<List<SchoolBuildingRecord>> Function()? loadBuildings;
  final Future<List<SchoolRoomRecord>> Function()? loadRooms;
  final Future<List<SchoolAdminAuditLog>> Function()? loadLogs;

  /// สร้างอาคาร/ห้องผ่าน `import_school_buildings_batch` /
  /// `import_school_rooms_batch` (RPC เดียวกับหน้านำเข้าข้อมูล ส่งทีละ 1 แถว)
  /// — ยังไม่มี RPC แก้ไข/ลบ จึงมีแค่ "สร้าง" ที่ต่อจริง
  final Future<BulkImportResult> Function(Map<String, dynamic> building)?
  createBuilding;
  final Future<BulkImportResult> Function(Map<String, dynamic> room)?
  createRoom;

  /// แก้ไข/ลบ/ผู้รับผิดชอบ — update_school_building / delete_school_building /
  /// set_school_building_manager / update_school_room / delete_school_room
  /// (20260914010000) · "รายการที่ควรตรวจสอบ" = แจ้งเตือนสถานะ new ของโรงเรียน
  /// (list_school_alerts) จับคู่ที่ตั้งจาก list_school_devices
  final Future<void> Function({
    required String buildingId,
    required String name,
    required String code,
    int? floors,
    String? note,
  })?
  updateBuilding;
  final Future<void> Function(String buildingId)? deleteBuilding;
  final Future<void> Function({
    required String buildingId,
    required String? managerName,
  })?
  setBuildingManager;
  final Future<void> Function({
    required String roomId,
    required String name,
    required String code,
    String? floor,
    String? roomType,
    int? capacity,
  })?
  updateRoom;
  final Future<void> Function(String roomId)? deleteRoom;
  final Future<List<SchoolSensorAlertRecord>> Function()? loadAlerts;
  final Future<List<DeviceOption>> Function()? loadDevices;
  final Future<List<StaffDirectoryEntry>> Function()? loadStaffDirectory;

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

  /// แจ้งเตือนที่ยังไม่รับทราบ + ที่ตั้งอุปกรณ์ (สำหรับการ์ด "รายการที่ควรตรวจสอบ")
  List<_AlertSpot> _alertSpots = const [];
  bool _alertsLoading = true;
  bool _alertsFailed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAlertSpots();
  }

  Future<void> _loadAlertSpots() async {
    if (mounted) {
      setState(() {
        _alertsLoading = true;
        _alertsFailed = false;
      });
    }
    try {
      final results = await Future.wait<Object>([
        (widget.loadAlerts ??
            () => IncidentService.listSchoolAlerts(status: 'new'))(),
        (widget.loadDevices ?? LessonService.listSchoolDevices)(),
      ]);
      final alerts = results[0] as List<SchoolSensorAlertRecord>;
      final devices = results[1] as List<DeviceOption>;
      final locationOf = {for (final d in devices) d.id: d.location ?? ''};
      if (!mounted) return;
      setState(() {
        _alertSpots = alerts
            .map(
              (a) => _AlertSpot(
                deviceName: a.deviceName,
                location: locationOf[a.deviceId] ?? '',
                metric: a.metric,
                value: a.value,
                triggeredAt: a.triggeredAt,
              ),
            )
            .toList();
        _alertsLoading = false;
      });
    } catch (e) {
      debugPrint('SchoolBuildingsPage: โหลดแจ้งเตือนไม่สำเร็จ — $e');
      if (!mounted) return;
      setState(() {
        _alertsLoading = false;
        _alertsFailed = true;
      });
    }
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final buildings =
          await (widget.loadBuildings ??
              () => SchoolAdminPlatformService().fetchBuildings())();
      final rooms =
          await (widget.loadRooms ??
              () => SchoolAdminPlatformService().fetchRooms())();
      final logs =
          await (widget.loadLogs ??
              () => SchoolAdminPlatformService().fetchAuditLogs(limit: 6))();
      if (!mounted) return;
      setState(() {
        _buildings = buildings
            .map(
              (b) => _BuildingRecord(
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
              ),
            )
            .toList();

        _rooms = rooms
            .map(
              (r) => _RoomRecord(
                id: r.id,
                code: r.code,
                name: r.name,
                building: r.buildingName,
                // เดิม RPC/model fabricate 'ชั้น 1' และ 'ปกติ' เมื่อไม่มีค่า
                // ตอนนี้เป็น null จริงจากต้นทาง จึงต้องบอกตรงๆ ว่ายังไม่มีข้อมูล
                // แทนการเดาแทนโรงเรียน
                floor: r.floor ?? 'ยังไม่มีข้อมูล',
                type: r.roomType,
                capacity: r.capacity,
                teacher: r.teacherName,
                devices: r.devicesCount,
                trainingKits: r.trainingKitsCount,
                status: r.status == 'active' ? 'พร้อมใช้งาน' : 'ตรวจสอบ',
                resourceStatus: r.resourceStatus ?? 'ยังไม่มีข้อมูล',
              ),
            )
            .toList();

        _logs = logs
            .map(
              (l) => _BuildingLogRecord(
                time:
                    '${l.createdAt.hour.toString().padLeft(2, '0')}:${l.createdAt.minute.toString().padLeft(2, '0')} น.',
                action: l.action,
                target: l.target,
                detail: l.detail.isNotEmpty ? l.detail : l.target,
                by: l.actorName,
                // เดิม hardcode 'success' ทุกแถวเขียวหมด ทั้งที่ audit_logs
                // ไม่มีคอลัมน์ผลลัพธ์เก็บไว้เลย — อนุมานจากชื่อ action
                // เท่าที่บอกได้จริงเหมือนที่แก้ไว้แล้วใน
                // school_admin_profile_page.dart
                type: _logTypeFor(l.action),
              ),
            )
            .toList();

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
      final bool matchesSearch =
          keyword.isEmpty ||
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

  /// `audit_logs` ไม่ได้เก็บสถานะสำเร็จ/ล้มเหลวไว้ ชื่อ action จึงเป็นสิ่งเดียว
  /// ที่ใช้อนุมานได้ อะไรที่บอกไม่ได้ให้เป็นกลาง ดีกว่าเดาว่าสำเร็จ
  String _logTypeFor(String action) {
    final a = action.toLowerCase();
    if (a.contains('fail') || a.contains('denied') || a.contains('revoke')) {
      return 'danger';
    }
    if (a.contains('delete') ||
        a.contains('suspend') ||
        a.contains('archive')) {
      return 'warning';
    }
    return 'neutral';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedBuilding = 'ทุกอาคาร';
      _selectedType = 'ทุกประเภท';
      _selectedStatus = 'ทุกสถานะ';
    });
  }

  /// แปลผลจาก import batch (ส่ง 1 แถว) เป็นประโยคที่แอดมินแก้เองได้ —
  /// RPC ไม่ raise เมื่อข้ามแถว แต่คืน `skipped` พร้อมเหตุผลเป็นรหัส
  static String? _skipReasonMessage(BulkImportResult result, String what) {
    if (result.insertedCount >= 1) return null;
    final reason = result.skipped.isEmpty ? '' : result.skipped.first.reason;
    switch (reason) {
      case 'duplicate_code':
        return 'รหัส$whatนี้มีอยู่แล้ว กรุณาใช้รหัสอื่น';
      case 'missing_required_field':
        return 'กรอกชื่อและรหัส$whatให้ครบก่อนบันทึก';
      case 'building_not_found':
        return 'ไม่พบอาคารที่เลือก กรุณาโหลดหน้าใหม่แล้วลองอีกครั้ง';
      default:
        return 'สร้าง$whatไม่สำเร็จ${reason.isEmpty ? '' : ' ($reason)'}';
    }
  }

  static String _mutationFailureMessage(Object e, String what) {
    final raw = e.toString();
    if (raw.contains('duplicate_code')) {
      return 'รหัส$whatนี้มีอยู่แล้ว กรุณาใช้รหัสอื่น';
    }
    if (raw.contains('building_has_rooms')) {
      return 'ลบอาคารไม่ได้ — ยังมีห้องอยู่ในอาคารนี้ ย้ายหรือลบห้องก่อน';
    }
    if (raw.contains('room_has_devices')) {
      return 'ลบห้องไม่ได้ — ยังมีอุปกรณ์ที่ระบุห้องนี้อยู่ ย้ายอุปกรณ์ก่อน';
    }
    if (raw.contains('missing_required_field')) {
      return 'กรอกชื่อและรหัส$whatให้ครบ';
    }
    return 'บันทึก$whatไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
  }

  Future<void> _deleteBuilding(_BuildingRecord building) async {
    final ok = await _confirmDelete(
      'ลบอาคาร "${building.name}"?',
      'อาคารที่ยังมีห้องอยู่จะลบไม่ได้ ระบบจะแจ้งให้ย้าย/ลบห้องก่อน',
    );
    if (!ok || !mounted) return;
    try {
      await (widget.deleteBuilding ??
          (id) => SchoolAdminPlatformService().deleteBuilding(id))(building.id);
      if (!mounted) return;
      _showMessage('ลบอาคาร "${building.name}" แล้ว');
      await _loadData();
    } catch (e) {
      debugPrint('SchoolBuildingsPage: ลบอาคารไม่สำเร็จ — $e');
      if (!mounted) return;
      _showMessage(_mutationFailureMessage(e, 'อาคาร'));
    }
  }

  Future<bool> _confirmDelete(String title, String detail) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(detail),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _openBuildingForm({_BuildingRecord? building}) async {
    if (building != null) {
      await _openEditBuildingForm(building);
      return;
    }
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final floorsCtrl = TextEditingController(text: '1');
    var submitting = false;
    String? formError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Future<void> submit() async {
            final name = nameCtrl.text.trim();
            final code = codeCtrl.text.trim();
            final floors = int.tryParse(floorsCtrl.text.trim());
            if (name.isEmpty || code.isEmpty) {
              setSheet(() => formError = 'กรอกชื่อและรหัสอาคารให้ครบ');
              return;
            }
            if (floors == null || floors < 1) {
              setSheet(() => formError = 'จำนวนชั้นต้องเป็นตัวเลขตั้งแต่ 1');
              return;
            }
            setSheet(() {
              submitting = true;
              formError = null;
            });
            try {
              final create =
                  widget.createBuilding ??
                  (b) => SchoolAdminPlatformService().importBuildingsBatch([b]);
              final result = await create({
                'name': name,
                'code': code,
                'floors': floors,
              });
              // แอดมินอาจกดพื้นหลังปิดแผ่นไปแล้วระหว่างรอ — ห้าม setState บน
              // StatefulBuilder ที่ถูกถอดไปแล้ว
              if (!sheetContext.mounted) return;
              final problem = _skipReasonMessage(result, 'อาคาร');
              if (problem != null) {
                setSheet(() {
                  submitting = false;
                  formError = problem;
                });
                return;
              }
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              if (!mounted) return;
              _showMessage('สร้างอาคาร "$name" แล้ว');
              await _loadData();
            } catch (e) {
              debugPrint('SchoolBuildingsPage: สร้างอาคารไม่สำเร็จ — $e');
              if (!sheetContext.mounted) return;
              setSheet(() {
                submitting = false;
                formError = 'สร้างอาคารไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
              });
            }
          }

          return _DisposeOnClose(
            controllers: [nameCtrl, codeCtrl, floorsCtrl],
            child: _MutationSheet(
              title: 'สร้างอาคารใหม่',
              subtitle: 'บันทึกลงระบบจริงผ่านการนำเข้าข้อมูลอาคาร',
              submitting: submitting,
              error: formError,
              onSubmit: submit,
              fields: [
                _SheetField(
                  controller: nameCtrl,
                  label: 'ชื่ออาคาร',
                  autofocus: true,
                ),
                _SheetField(controller: codeCtrl, label: 'รหัสอาคาร (ไม่ซ้ำ)'),
                _SheetField(
                  controller: floorsCtrl,
                  label: 'จำนวนชั้น',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditBuildingForm(_BuildingRecord building) async {
    final nameCtrl = TextEditingController(text: building.name);
    final codeCtrl = TextEditingController(text: building.code);
    final floorsCtrl = TextEditingController(text: '${building.floors}');
    final noteCtrl = TextEditingController(text: building.note);
    var submitting = false;
    String? formError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Future<void> submit() async {
            final name = nameCtrl.text.trim();
            final code = codeCtrl.text.trim();
            final floors = int.tryParse(floorsCtrl.text.trim());
            if (name.isEmpty || code.isEmpty) {
              setSheet(() => formError = 'กรอกชื่อและรหัสอาคารให้ครบ');
              return;
            }
            if (floors == null || floors < 1) {
              setSheet(() => formError = 'จำนวนชั้นต้องเป็นตัวเลขตั้งแต่ 1');
              return;
            }
            setSheet(() {
              submitting = true;
              formError = null;
            });
            try {
              final update =
                  widget.updateBuilding ??
                  ({
                    required String buildingId,
                    required String name,
                    required String code,
                    int? floors,
                    String? note,
                  }) => SchoolAdminPlatformService().updateBuilding(
                    buildingId: buildingId,
                    name: name,
                    code: code,
                    floors: floors,
                    note: note,
                  );
              await update(
                buildingId: building.id,
                name: name,
                code: code,
                floors: floors,
                note: noteCtrl.text.trim(),
              );
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              if (!mounted) return;
              _showMessage('บันทึกอาคาร "$name" แล้ว');
              await _loadData();
            } catch (e) {
              debugPrint('SchoolBuildingsPage: แก้อาคารไม่สำเร็จ — $e');
              if (!sheetContext.mounted) return;
              setSheet(() {
                submitting = false;
                formError = _mutationFailureMessage(e, 'อาคาร');
              });
            }
          }

          return _DisposeOnClose(
            controllers: [nameCtrl, codeCtrl, floorsCtrl, noteCtrl],
            child: _MutationSheet(
              title: 'แก้ไขอาคาร',
              subtitle: 'บันทึกลงระบบจริงผ่าน update_school_building',
              submitting: submitting,
              error: formError,
              onSubmit: submit,
              onDelete: submitting
                  ? null
                  : () {
                      Navigator.of(sheetContext).pop();
                      _deleteBuilding(building);
                    },
              fields: [
                _SheetField(
                  controller: nameCtrl,
                  label: 'ชื่ออาคาร',
                  autofocus: true,
                ),
                _SheetField(controller: codeCtrl, label: 'รหัสอาคาร (ไม่ซ้ำ)'),
                _SheetField(
                  controller: floorsCtrl,
                  label: 'จำนวนชั้น',
                  keyboardType: TextInputType.number,
                ),
                _SheetField(controller: noteCtrl, label: 'หมายเหตุ (ถ้ามี)'),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditRoomForm(_RoomRecord room) async {
    final nameCtrl = TextEditingController(text: room.name);
    final codeCtrl = TextEditingController(text: room.code);
    final floorCtrl = TextEditingController(
      text: room.floor == 'ยังไม่มีข้อมูล' ? '' : room.floor,
    );
    final typeCtrl = TextEditingController(text: room.type);
    final capacityCtrl = TextEditingController(text: '${room.capacity}');
    var submitting = false;
    String? formError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Future<void> submit() async {
            final name = nameCtrl.text.trim();
            final code = codeCtrl.text.trim();
            final capacity = int.tryParse(capacityCtrl.text.trim());
            if (name.isEmpty || code.isEmpty) {
              setSheet(() => formError = 'กรอกชื่อและรหัสห้องให้ครบ');
              return;
            }
            if (capacity == null || capacity < 1) {
              setSheet(() => formError = 'ความจุต้องเป็นตัวเลขตั้งแต่ 1');
              return;
            }
            setSheet(() {
              submitting = true;
              formError = null;
            });
            try {
              final update =
                  widget.updateRoom ??
                  ({
                    required String roomId,
                    required String name,
                    required String code,
                    String? floor,
                    String? roomType,
                    int? capacity,
                  }) => SchoolAdminPlatformService().updateRoom(
                    roomId: roomId,
                    name: name,
                    code: code,
                    floor: floor,
                    roomType: roomType,
                    capacity: capacity,
                  );
              await update(
                roomId: room.id,
                name: name,
                code: code,
                floor: floorCtrl.text.trim(),
                roomType: typeCtrl.text.trim(),
                capacity: capacity,
              );
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              if (!mounted) return;
              _showMessage('บันทึกห้อง "$name" แล้ว');
              await _loadData();
            } catch (e) {
              debugPrint('SchoolBuildingsPage: แก้ห้องไม่สำเร็จ — $e');
              if (!sheetContext.mounted) return;
              setSheet(() {
                submitting = false;
                formError = _mutationFailureMessage(e, 'ห้อง');
              });
            }
          }

          return _DisposeOnClose(
            controllers: [
              nameCtrl,
              codeCtrl,
              floorCtrl,
              typeCtrl,
              capacityCtrl,
            ],
            child: _MutationSheet(
              title: 'แก้ไขห้อง',
              subtitle: 'บันทึกลงระบบจริงผ่าน update_school_room',
              submitting: submitting,
              error: formError,
              onSubmit: submit,
              onDelete: submitting
                  ? null
                  : () {
                      Navigator.of(sheetContext).pop();
                      _deleteRoom(room);
                    },
              fields: [
                _SheetField(
                  controller: nameCtrl,
                  label: 'ชื่อห้อง',
                  autofocus: true,
                ),
                _SheetField(controller: codeCtrl, label: 'รหัสห้อง (ไม่ซ้ำ)'),
                _SheetField(controller: floorCtrl, label: 'ชั้น (ถ้ามี)'),
                _SheetField(controller: typeCtrl, label: 'ประเภทห้อง'),
                _SheetField(
                  controller: capacityCtrl,
                  label: 'ความจุ (คน)',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ผู้รับผิดชอบอาคาร — เลือกจากรายชื่อบุคลากรจริง (list_staff_directory)
  /// หรือล้างค่า แล้วเขียน buildings.manager_name ผ่าน set_school_building_manager
  Future<void> _openManagerPicker({_BuildingRecord? building}) async {
    if (_buildings.isEmpty) {
      _showMessage('ต้องมีอาคารก่อน จึงจะกำหนดผู้รับผิดชอบได้');
      return;
    }
    List<StaffDirectoryEntry> staff;
    try {
      staff =
          await (widget.loadStaffDirectory ??
              StaffOrgService.listStaffDirectory)();
    } catch (e) {
      debugPrint('SchoolBuildingsPage: โหลดรายชื่อบุคลากรไม่สำเร็จ — $e');
      if (!mounted) return;
      _showMessage('โหลดรายชื่อบุคลากรไม่สำเร็จ กรุณาลองใหม่');
      return;
    }
    if (!mounted) return;

    var buildingId = (building ?? _buildings.first).id;
    String? managerName = (building ?? _buildings.first).manager.isEmpty
        ? null
        : (building ?? _buildings.first).manager;
    var submitting = false;
    String? formError;
    final names = <String>{
      for (final s in staff) s.fullName,
      ?managerName,
    }.toList()..sort();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Future<void> submit() async {
            setSheet(() {
              submitting = true;
              formError = null;
            });
            try {
              await (widget.setBuildingManager ??
                  ({
                    required String buildingId,
                    required String? managerName,
                  }) => SchoolAdminPlatformService().setBuildingManager(
                    buildingId: buildingId,
                    managerName: managerName,
                  ))(buildingId: buildingId, managerName: managerName);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              if (!mounted) return;
              _showMessage(
                managerName == null
                    ? 'ล้างผู้รับผิดชอบอาคารแล้ว'
                    : 'กำหนดผู้รับผิดชอบเป็น $managerName แล้ว',
              );
              await _loadData();
            } catch (e) {
              debugPrint(
                'SchoolBuildingsPage: set_school_building_manager ล้ม — $e',
              );
              if (!sheetContext.mounted) return;
              setSheet(() {
                submitting = false;
                formError = 'บันทึกผู้รับผิดชอบไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
              });
            }
          }

          return _MutationSheet(
            title: 'กำหนดผู้รับผิดชอบอาคาร',
            subtitle: 'เลือกจากรายชื่อบุคลากรของโรงเรียน — บันทึกลงระบบจริง',
            submitting: submitting,
            error: formError,
            onSubmit: submit,
            fields: [
              DropdownButtonFormField<String>(
                value: buildingId,
                decoration: const InputDecoration(labelText: 'อาคาร'),
                items: [
                  for (final b in _buildings)
                    DropdownMenuItem(value: b.id, child: Text(b.name)),
                ],
                onChanged: submitting
                    ? null
                    : (v) => setSheet(() {
                        buildingId = v ?? buildingId;
                        final current = _buildings
                            .firstWhere((b) => b.id == buildingId)
                            .manager;
                        managerName = current.isEmpty ? null : current;
                        if (managerName != null &&
                            !names.contains(managerName)) {
                          names.add(managerName!);
                        }
                      }),
              ),
              DropdownButtonFormField<String?>(
                value: managerName,
                decoration: const InputDecoration(labelText: 'ผู้รับผิดชอบ'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— ไม่กำหนด —'),
                  ),
                  for (final n in names)
                    DropdownMenuItem<String?>(value: n, child: Text(n)),
                ],
                onChanged: submitting
                    ? null
                    : (v) => setSheet(() => managerName = v),
              ),
              if (staff.isEmpty)
                const Text(
                  'ยังไม่มีบุคลากรในโรงเรียน — เพิ่มจากหน้า "ครูและบุคลากร" ก่อน',
                  style: TextStyle(
                    fontSize: 12,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openRoomForm({
    _RoomRecord? room,
    String? initialBuilding,
  }) async {
    if (room != null) {
      await _openEditRoomForm(room);
      return;
    }
    if (_buildings.isEmpty) {
      _showMessage('ต้องสร้างอาคารก่อน จึงจะเพิ่มห้องได้');
      return;
    }
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final floorCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '30');
    var buildingCode = _buildings
        .firstWhere(
          (b) => b.name == initialBuilding,
          orElse: () => _buildings.first,
        )
        .code;
    var submitting = false;
    String? formError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Future<void> submit() async {
            final name = nameCtrl.text.trim();
            final code = codeCtrl.text.trim();
            final capacity = int.tryParse(capacityCtrl.text.trim());
            if (name.isEmpty || code.isEmpty) {
              setSheet(() => formError = 'กรอกชื่อและรหัสห้องให้ครบ');
              return;
            }
            if (capacity == null || capacity < 1) {
              setSheet(() => formError = 'ความจุต้องเป็นตัวเลขตั้งแต่ 1');
              return;
            }
            setSheet(() {
              submitting = true;
              formError = null;
            });
            try {
              final create =
                  widget.createRoom ??
                  (r) => SchoolAdminPlatformService().importRoomsBatch([r]);
              final result = await create({
                'name': name,
                'code': code,
                'building_code': buildingCode,
                'floor': floorCtrl.text.trim(),
                'capacity': capacity,
              });
              if (!sheetContext.mounted) return;
              final problem = _skipReasonMessage(result, 'ห้อง');
              if (problem != null) {
                setSheet(() {
                  submitting = false;
                  formError = problem;
                });
                return;
              }
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              if (!mounted) return;
              _showMessage('สร้างห้อง "$name" แล้ว');
              await _loadData();
            } catch (e) {
              debugPrint('SchoolBuildingsPage: สร้างห้องไม่สำเร็จ — $e');
              if (!sheetContext.mounted) return;
              setSheet(() {
                submitting = false;
                formError = 'สร้างห้องไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
              });
            }
          }

          return _DisposeOnClose(
            controllers: [nameCtrl, codeCtrl, floorCtrl, capacityCtrl],
            child: _MutationSheet(
              title: 'สร้างห้องใหม่',
              subtitle: 'บันทึกลงระบบจริงผ่านการนำเข้าข้อมูลห้อง',
              submitting: submitting,
              error: formError,
              onSubmit: submit,
              fields: [
                DropdownButtonFormField<String>(
                  value: buildingCode,
                  decoration: const InputDecoration(labelText: 'อาคาร'),
                  items: [
                    for (final b in _buildings)
                      DropdownMenuItem(value: b.code, child: Text(b.name)),
                  ],
                  onChanged: submitting
                      ? null
                      : (v) => setSheet(() => buildingCode = v ?? buildingCode),
                ),
                _SheetField(
                  controller: nameCtrl,
                  label: 'ชื่อห้อง',
                  autofocus: true,
                ),
                _SheetField(controller: codeCtrl, label: 'รหัสห้อง (ไม่ซ้ำ)'),
                _SheetField(controller: floorCtrl, label: 'ชั้น (ถ้ามี)'),
                _SheetField(
                  controller: capacityCtrl,
                  label: 'ความจุ (คน)',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteRoom(_RoomRecord room) async {
    final ok = await _confirmDelete(
      'ลบห้อง "${room.name}"?',
      'ห้องที่ยังมีอุปกรณ์ระบุห้องนี้อยู่จะลบไม่ได้ ระบบจะแจ้งให้ย้ายอุปกรณ์ก่อน',
    );
    if (!ok || !mounted) return;
    try {
      await (widget.deleteRoom ??
          (id) => SchoolAdminPlatformService().deleteRoom(id))(room.id);
      if (!mounted) return;
      _showMessage('ลบห้อง "${room.name}" แล้ว');
      await _loadData();
    } catch (e) {
      debugPrint('SchoolBuildingsPage: ลบห้องไม่สำเร็จ — $e');
      if (!mounted) return;
      _showMessage(_mutationFailureMessage(e, 'ห้อง'));
    }
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
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: SchoolAdminPalette.primarySoft,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.meeting_room_rounded,
                            color: SchoolAdminPalette.primaryDark,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${room.code} • ${room.name}',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: SchoolAdminPalette.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${room.building} • ${room.floor}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: SchoolAdminPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _openRoomForm(room: room);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: SchoolAdminPalette.primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text(
                              'แก้ไขห้อง',
                              style: TextStyle(fontWeight: FontWeight.w800),
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
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
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
                  children: [title, const SizedBox(height: 14), actions],
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
        ),
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
      builder: (BuildContext context, BoxConstraints constraints) {
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
        subtitle: 'เลือกผู้รับผิดชอบจากรายชื่อบุคลากร',
        icon: Icons.engineering_rounded,
        onTap: () => _openManagerPicker(),
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
        builder: (BuildContext context, BoxConstraints constraints) {
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
            const Icon(
              Icons.error_outline_rounded,
              color: SchoolAdminPalette.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'โหลดข้อมูลอาคารไม่สำเร็จ',
                style: TextStyle(
                  fontSize: 12,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            ),
            TextButton(onPressed: _loadData, child: const Text('ลองใหม่')),
          ],
        ),
      );
    } else if (_buildings.isEmpty) {
      content = SizedBox(
        width: double.infinity,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  size: 40,
                  color: SchoolAdminPalette.textSecondary,
                ),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: SchoolAdminPalette.textSecondary,
                  ),
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
          ),
        ),
      );
    } else {
      content = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
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
        builder: (BuildContext context, BoxConstraints constraints) {
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
            items: ['ทุกอาคาร', ..._buildings.map((item) => item.name)],
            onChanged: (String value) {
              setState(() => _selectedBuilding = value);
            },
          );

          // เดิม items เป็นลิสต์ hardcode 5/4 ตัวเลือกที่ไม่ตรงกับข้อมูลจริง
          // เลย — ห้องมีแค่ 'ห้องเรียน'/'ห้องปฏิบัติการ' จริง (ดู seed) และ
          // สถานะห้องมีแค่ 'พร้อมใช้งาน'/'ตรวจสอบ' (ไม่มี CRUD ให้สร้างค่าอื่น
          // ได้เลย) ตัวเลือกที่เหลือกรองไม่ได้จริงสักครั้ง — เปลี่ยนเป็นสร้าง
          // จากข้อมูลที่โหลดจริงเหมือนตัวกรองอาคารด้านบน
          final Widget type = _BuildingFilterDropdown(
            label: 'ประเภทห้อง',
            value: _selectedType,
            items: ['ทุกประเภท', ..._rooms.map((r) => r.type).toSet()],
            onChanged: (String value) {
              setState(() => _selectedType = value);
            },
          );

          final Widget status = _BuildingFilterDropdown(
            label: 'สถานะ',
            value: _selectedStatus,
            items: ['ทุกสถานะ', ..._rooms.map((r) => r.status).toSet()],
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
      padding: EdgeInsets.zero,
      child: rooms.isEmpty
          ? const _BuildingEmptyState()
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth >= 1050) {
                  return Table(
                    border: const TableBorder(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      horizontalInside: BorderSide(
                        color: Color(0xFFF1F5F9),
                        width: 1,
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
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                        ),
                        children: [
                          _RoomTableHeader(text: 'ห้อง', align: TextAlign.left),
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
                                  fontSize: 12,
                                  height: 1.4,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
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
                                  fontSize: 12,
                                  height: 1.35,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            _RoomTableCell(
                              child: Text(
                                '${room.devices} อุปกรณ์\n${room.trainingKits} ชุดฝึก',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            _RoomTableCell(
                              child: _RoomStatusBadge(value: room.status),
                            ),
                            _RoomTableCell(
                              child: _ResourceBadge(value: room.resourceStatus),
                            ),
                            _RoomTableCell(
                              child: PopupMenuButton<String>(
                                tooltip: 'จัดการ',
                                color: Colors.white,
                                surfaceTintColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                elevation: 6,
                                shadowColor: const Color(0x1A000000),
                                onSelected: (String value) {
                                  switch (value) {
                                    case 'view':
                                      _showRoomDetail(room);
                                      break;
                                    case 'edit':
                                      _openRoomForm(room: room);
                                      break;
                                    case 'delete':
                                      _deleteRoom(room);
                                      break;
                                  }
                                },
                                // เดิมมีตัวเลือก 'ดูอุปกรณ์ในห้อง' ที่กดแล้วโชว์
                                // snackbar เฉยๆ ไม่เปิดอะไรจริง — ยังไม่มีทาง
                                // กรองหน้าอุปกรณ์ตามห้อง เอาออกแทนตัวเลือกที่
                                // กดแล้วไม่มีอะไรเกิดขึ้น
                                itemBuilder: (BuildContext context) {
                                  return [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.visibility_outlined,
                                            size: 18,
                                            color: Color(0xFF475569),
                                          ),
                                          SizedBox(width: 10),
                                          Text('ดูรายละเอียด'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: Color(0xFF475569),
                                          ),
                                          SizedBox(width: 10),
                                          Text('แก้ไขห้อง'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: Color(0xFFEF4444),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'ลบห้อง',
                                            style: TextStyle(
                                              color: Color(0xFFEF4444),
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
                  padding: const EdgeInsets.all(14),
                  child: Column(
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
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMonitoring() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // รอบก่อนเป็น 3 แถว hardcode แล้วถูกเปลี่ยนเป็น "ยังไม่มีระบบ" — ตอนนี้
        // คือแจ้งเตือนสถานะ new ของโรงเรียน (list_school_alerts) จับคู่ที่ตั้ง
        // จาก list_school_devices ว่างคือว่าง ล้มคือล้ม
        final Widget alerts = _BuildingSectionCard(
          title: 'รายการที่ควรตรวจสอบ',
          subtitle: 'อุปกรณ์ที่มีแจ้งเตือนเกินเกณฑ์และยังไม่ได้รับทราบ',
          child: _alertsLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _alertsFailed
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'โหลดรายการแจ้งเตือนไม่สำเร็จ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadAlertSpots,
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : _alertSpots.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'ไม่มีแจ้งเตือนที่ยังไม่ได้รับทราบ',
                      style: TextStyle(
                        fontSize: 12,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final spot in _alertSpots.take(8))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFD97706),
                        ),
                        title: Text(
                          spot.deviceName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${spot.location.isEmpty ? 'ไม่ระบุที่ตั้ง' : spot.location} · '
                          '${spot.metric} ${spot.value}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                    if (_alertSpots.length > 8)
                      Text(
                        'และอีก ${_alertSpots.length - 8} รายการ — ดูทั้งหมดที่หน้า "การแจ้งเตือน"',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: SchoolAdminPalette.textSecondary,
                        ),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'ยังไม่มีข้อมูลอาคาร',
                    style: TextStyle(
                      fontSize: 12,
                      color: SchoolAdminPalette.textSecondary,
                    ),
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
            children: [alerts, const SizedBox(height: 14), assignments],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: alerts),
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
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 240;

        return Container(
          constraints: BoxConstraints(minHeight: compact ? 150 : 134),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.1),
            boxShadow: [
              const BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
              const BoxShadow(
                color: Color(0x0C0F172A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: data.color.withAlpha(20),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BuildingIconBox(icon: data.icon, color: data.color),
                    const SizedBox(height: 12),
                    Text(
                      data.value,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 12.5,
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
                        fontSize: 11,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _BuildingIconBox(icon: data.icon, color: data.color),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.value,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: SchoolAdminPalette.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.title,
                            style: const TextStyle(
                              fontSize: 13,
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
                              fontSize: 11.5,
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
    this.padding,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final bool isFullWidth = padding == EdgeInsets.zero;

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: isFullWidth
                ? const EdgeInsets.fromLTRB(20, 18, 20, 14)
                : EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: SchoolAdminPalette.primaryDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isFullWidth) const SizedBox(height: 18),
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
    final Widget card = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x050F172A),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _BuildingIconBox(
                icon: data.icon,
                color: SchoolAdminPalette.primaryDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
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

    if (data.onTap == null) {
      return Opacity(
        opacity: 0.55,
        child: Tooltip(message: 'ยังไม่เปิดใช้งาน', child: card),
      );
    }
    return card;
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
    final List<String> values = widget.rooms
        .map((_RoomRecord room) => room.floor)
        .toSet()
        .toList();

    values.sort();
    return values;
  }

  // เดิม dropdown สถานะด้านล่างมีตัวเลือก 'ปิดใช้งาน' hardcode ตายตัว ทั้งที่
  // room.status ไม่เคยเป็นค่านั้นได้เลย (map แค่ 'พร้อมใช้งาน'/'ตรวจสอบ')
  List<String> get _statuses {
    final List<String> values = widget.rooms
        .map((_RoomRecord room) => room.status)
        .toSet()
        .toList();

    values.sort();
    return values;
  }

  List<_RoomRecord> get _filteredRooms {
    final String keyword = _searchController.text.trim().toLowerCase();

    final List<_RoomRecord> result = widget.rooms.where((_RoomRecord room) {
      final bool matchesSearch =
          keyword.isEmpty ||
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
    final Color buildingStatusColor = _buildingStatusColor(
      widget.building.status,
    );

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAF7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: SchoolAdminPalette.border),
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
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 720;

          final Widget title = Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: SchoolAdminPalette.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SchoolAdminPalette.border),
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
                icon: const Icon(Icons.add_home_work_rounded, size: 18),
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
              children: [title, const SizedBox(height: 12), actions],
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
              : 'มีรายละเอียดห้องที่บันทึกไว้ในระบบ $recordedRooms ห้อง '
                    'จากจำนวนห้องที่กำหนดไว้ $configuredRooms ห้อง',
          style: const TextStyle(
            fontSize: 12,
            height: 1.45,
            color: SchoolAdminPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
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
                return SizedBox(width: width, child: item);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final List<String> floorItems = ['ทุกชั้น', ..._floors];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
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
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'ทุกสถานะ',
                          child: Text('ทุกสถานะ'),
                        ),
                        ..._statuses.map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          ),
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
            builder: (BuildContext context, BoxConstraints constraints) {
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
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
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
        ),
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
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: color.withAlpha(18),
            child: Icon(icon, size: 21, color: color),
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

  // ไม่มีสัญญาณ 'resource_status' จริงจาก backend เลย (ดู
  // list_school_rooms) 'ยังไม่มีข้อมูล' ต้องเป็นสีกลาง ไม่ใช่แดง — แดงคือ
  // "มีปัญหา" ซึ่งเป็นการเดาเกินสิ่งที่ระบบรู้จริงเหมือนกับที่เคย hardcode
  // 'ปกติ' เขียวมาก่อน
  Color get _resourceColor {
    if (room.resourceStatus == 'ปกติ') return SchoolAdminPalette.green;
    if (room.resourceStatus == 'ยังไม่มีข้อมูล') {
      return SchoolAdminPalette.textMuted;
    }
    return SchoolAdminPalette.red;
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
            border: Border.all(color: SchoolAdminPalette.border),
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
                  _RoomBrowserBadge(label: room.status, color: _statusColor),
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
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('ดูรายละเอียด'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 18),
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
        Icon(icon, size: 17, color: SchoolAdminPalette.primaryDark),
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
  const _RoomBrowserBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(50)),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${building.code} • ${building.floors} ชั้น',
                      style: const TextStyle(
                        fontSize: 11.5,
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenRooms,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  icon: const Icon(Icons.meeting_room_rounded, size: 16),
                  label: const Text(
                    'ดูห้อง',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: onEdit,
                tooltip: 'แก้ไขอาคาร',
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                icon: const Icon(Icons.edit_rounded, size: 18),
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
        Icon(icon, size: 17, color: SchoolAdminPalette.primaryDark),
        const SizedBox(width: 8),
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
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
              fontSize: 12,
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
  const _RoomTableHeader({required this.text, this.align = TextAlign.center});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF475569),
          letterSpacing: 0.2,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      child: Center(child: child),
    );
  }
}

class _RoomTableNameCell extends StatelessWidget {
  const _RoomTableNameCell({required this.room, required this.onTap});

  final _RoomRecord room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SchoolAdminPalette.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.meeting_room_rounded,
                size: 18,
                color: SchoolAdminPalette.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.code,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  Text(
                    room.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SchoolAdminPalette.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.meeting_room_rounded,
                  color: SchoolAdminPalette.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
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
                        fontSize: 11.5,
                        height: 1.35,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onView,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _RoomStatusBadge(value: room.status)),
              const SizedBox(width: 8),
              Expanded(child: _ResourceBadge(value: room.resourceStatus)),
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

    return _BuildingBadge(label: value, color: color);
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

    return _BuildingBadge(label: value, color: color);
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

    return _BuildingBadge(label: value, color: color);
  }
}

class _ResourceBadge extends StatelessWidget {
  const _ResourceBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final Color color = value == 'ปกติ'
        ? SchoolAdminPalette.green
        : SchoolAdminPalette.red;

    return _BuildingBadge(label: value, color: color);
  }
}

class _BuildingBadge extends StatelessWidget {
  const _BuildingBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80, minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
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
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool mobile = constraints.maxWidth < 760;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x040F172A),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${log.action} • ${log.target}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.detail,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${log.time} • โดย ${log.by}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _BuildingIconBox(icon: Icons.history_rounded, color: color),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${log.action} • ${log.target}',
                        style: const TextStyle(
                          fontSize: 12.5,
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
                          fontSize: 11.5,
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
                          fontSize: 11,
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
                          fontSize: 11,
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
          Icon(icon, size: 19, color: SchoolAdminPalette.primaryDark),
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
  const _BuildingIconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(45), width: 1.1),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _BuildingEmptyState extends StatelessWidget {
  const _BuildingEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 45),
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
        ),
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
  final VoidCallback? onTap;
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

  _BuildingRecord copyWith({int? rooms}) {
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

/// แผ่นฟอร์มสร้างอาคาร/ห้อง — ใช้ร่วมกัน 2 ฟอร์ม
class _MutationSheet extends StatelessWidget {
  const _MutationSheet({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.submitting,
    required this.error,
    required this.onSubmit,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final List<Widget> fields;
  final bool submitting;
  final String? error;
  final Future<void> Function() onSubmit;

  /// ฟอร์มแก้ไขมีปุ่มลบ — null = ฟอร์มสร้าง
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (final f in fields) ...[f, const SizedBox(height: 10)],
              if (error != null) ...[
                Text(
                  error!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  TextButton(
                    onPressed: submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('ยกเลิก'),
                  ),
                  if (onDelete != null)
                    TextButton(
                      onPressed: onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                      ),
                      child: const Text('ลบ'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: submitting ? null : onSubmit,
                    child: Text(submitting ? 'กำลังบันทึก…' : 'บันทึก'),
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

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
  }
}

/// ถือ controller ของฟอร์มในแผ่นไว้จน route ของแผ่นถูกถอดจริง — dispose ทันที
/// หลัง `showModalBottomSheet` คืนค่าจะชนแอนิเมชันปิดที่ยังวาด TextField อยู่
class _DisposeOnClose extends StatefulWidget {
  const _DisposeOnClose({required this.controllers, required this.child});

  final List<TextEditingController> controllers;
  final Widget child;

  @override
  State<_DisposeOnClose> createState() => _DisposeOnCloseState();
}

class _DisposeOnCloseState extends State<_DisposeOnClose> {
  @override
  void dispose() {
    for (final c in widget.controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// อุปกรณ์ที่มีแจ้งเตือนยังไม่รับทราบ + ที่ตั้ง (สำหรับ "รายการที่ควรตรวจสอบ")
class _AlertSpot {
  const _AlertSpot({
    required this.deviceName,
    required this.location,
    required this.metric,
    required this.value,
    required this.triggeredAt,
  });

  final String deviceName;
  final String location;
  final String metric;
  final double value;
  final DateTime triggeredAt;
}
