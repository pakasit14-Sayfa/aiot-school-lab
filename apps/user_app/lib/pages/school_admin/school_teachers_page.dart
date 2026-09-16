import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'school_import_page.dart';
import 'theme/school_admin_palette.dart';
import 'widgets/invite_user_sheet.dart';

/// หน้าครูและบุคลากรของ School Admin
///
/// ประวัติ (2026-09-06): เดิมหน้านี้อ่าน `list_school_users` +
/// `list_homeroom_assignments` จริง แต่ **แต่งข้อมูลรอบ ๆ ขึ้นเกือบทั้งหน้า**
/// - `teacherCode: 'TC-2569-${idx+1}'` สร้างจากลำดับแถว ไม่ใช่รหัสจริง
/// - `department` มาจาก `u.building` ซึ่งเป็นฟิลด์ของ facility_manager
///   (บทบาทที่ถูกยุบไปแล้ว) ถ้าว่างจะตกไปที่ค่าคงที่ `'วิทยาศาสตร์'` —
///   ผลคือครูทุกคนถูกจัดเข้ากลุ่มสาระวิทยาศาสตร์/ฝ่ายวิชาการอัตโนมัติ และ
///   การ์ด "บุคลากรแยกตามฝ่าย" 6 ใบกับชิป "กลุ่มสาระ" 10 ใบก็นับจากค่านั้น
/// - `phone`, `mainRole`, `buildingDuty`, `permission`, `lastLogin`, `note`
///   เป็นค่าคงที่ทั้งหมด (`'-'`, `'ครูผู้สอน'`, `'ปกติ'`) ไม่มี RPC ไหนคืนมา
/// - การ์ด "การมอบหมายหน้าที่" เขียนตายว่า "กำหนดแล้ว 32 จาก 34 ห้อง"
///   (progress 0.94), "กำหนดผู้รับผิดชอบครบ 6 อาคาร" (progress 1.0) และ
///   "4 บทบาท" ทั้งที่ระบบไม่เคยมีตัวเลขพวกนี้
/// - filter "บทบาท" กับ "อาคาร" เป็นรายการเขียนมือที่กรองอะไรไม่ได้เลย
///   (ทุกคน permission = 'ครูผู้สอน' และ building = 'อาคารเรียน A')
/// - `catch (_) {}` สองจุดกลืน error ทั้งตอนโหลดและตอนบันทึกครูประจำชั้น
/// - `_showAssignmentDialog` มีปุ่ม "บันทึก" ที่ตอบว่า "บันทึกตัวอย่างเรียบร้อย"
///   โดยไม่เขียนอะไรเลย
///
/// ตอนนี้เหลือเฉพาะสิ่งที่ backend มีจริง:
///   list_school_users        → ชื่อ อีเมล สถานะบัญชี บทบาททั้งหมด
///   list_homeroom_assignments → การมอบหมายครูประจำชั้นจริง + จำนวนนักเรียน
///   set_homeroom_teacher / remove_homeroom_teacher → มอบหมาย/ยกเลิกจริง
///   suspend_user / reactivate_user → ระงับ/เปิดบัญชี
///   update_user_profile      → แก้ชื่อ–นามสกุล
class SchoolTeachersPage extends StatefulWidget {
  const SchoolTeachersPage({
    super.key,
    this.loadUsers,
    this.loadHomerooms,
    this.setHomeroomTeacher,
    this.removeHomeroomTeacher,
    this.suspendUser,
    this.reactivateUser,
    this.updateName,
    this.createInvitation,
    this.loadBuildings,
    this.setBuildingManager,
  });

  /// Injectable seams — production ปล่อยว่างแล้วใช้ service จริง
  final Future<List<UserModel>> Function()? loadUsers;
  final Future<List<HomeroomAssignment>> Function()? loadHomerooms;
  final Future<String?> Function(String gradeLevel, String room, String teacherId)?
      setHomeroomTeacher;
  final Future<bool> Function(String assignmentId)? removeHomeroomTeacher;
  final Future<void> Function(String uid)? suspendUser;
  final Future<void> Function(String uid)? reactivateUser;
  final Future<void> Function(String uid, String name)? updateName;

  /// เชิญบุคลากรรายคน (create_staff_invitation) · ผู้รับผิดชอบอาคาร
  /// (list_school_buildings + set_school_building_manager — 20260914010000)
  final InvitationCreator? createInvitation;
  final Future<List<SchoolBuildingRecord>> Function()? loadBuildings;
  final Future<void> Function({
    required String buildingId,
    required String? managerName,
  })?
  setBuildingManager;

  @override
  State<SchoolTeachersPage> createState() => _SchoolTeachersPageState();
}

class _SchoolTeachersPageState extends State<SchoolTeachersPage> {
  static const String kNoData = 'ยังไม่มีข้อมูล';
  static const String kAllRoles = 'ทุกบทบาท';
  static const String kAllHomerooms = 'ทุกห้องประจำชั้น';
  static const String kNoHomeroom = 'ยังไม่ได้เป็นครูประจำชั้น';
  static const String kAllStatus = 'ทุกสถานะ';
  static const String kActive = 'ใช้งาน';
  static const String kSuspended = 'ระงับ';

  final TextEditingController _searchController = TextEditingController();

  String _selectedRole = kAllRoles;
  String _selectedHomeroom = kAllHomerooms;
  String _selectedStatus = kAllStatus;
  bool _filterSuspendedOnly = false;

  List<_TeacherRecord> _teachers = const [];
  List<HomeroomAssignment> _assignments = const [];
  bool _isLoading = true;
  bool _loadFailed = false;
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<UserModel>> _fetchUsers() =>
      widget.loadUsers?.call() ?? UserAdminService.getAllUsers();

  Future<List<HomeroomAssignment>> _fetchHomerooms() =>
      widget.loadHomerooms?.call() ?? HomeroomService.listHomeroomAssignments();

  List<_TeacherRecord> _toRecords(
    List<UserModel> users,
    List<HomeroomAssignment> assignments,
  ) {
    // ⚠️ ต้องกรองด้วย hasRole (ดู all_roles) ไม่ใช่ role == teacher
    // บัญชีเดียวถือได้หลายบทบาท และ active_role คือบทบาทที่ถูก grant ล่าสุด
    // เท่านั้น — การเทียบเท่ากับบทบาทเดียวเคยทำให้ครูหายจากรายการมาแล้ว
    return users.where((UserModel u) => u.hasRole(UserRole.teacher)).map((
      UserModel u,
    ) {
      final List<HomeroomAssignment> mine = assignments
          .where((HomeroomAssignment a) => a.teacherId == u.uid)
          .toList();
      return _TeacherRecord(
        id: u.uid,
        fullName: u.name.trim(),
        email: u.email,
        suspended: u.status == 'suspended',
        roles: u.allRoles.isEmpty ? <UserRole>[u.role] : u.allRoles,
        homerooms: mine
            .map((HomeroomAssignment a) => _homeroomLabel(a))
            .toList(),
      );
    }).toList();
  }

  static String _homeroomLabel(HomeroomAssignment a) {
    final String grade = a.gradeLevel.trim();
    final String room = a.room.trim();
    if (grade.isEmpty && room.isEmpty) return kNoData;
    if (room.isEmpty || room == grade) return grade;
    if (grade.isEmpty) return room;
    return '$grade/$room';
  }

  Future<void> _loadTeachers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadFailed = false;
      });
    }
    try {
      final users = await _fetchUsers();
      final assignments = await _fetchHomerooms();
      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _teachers = _toRecords(users, assignments);
        _isLoading = false;
        _loadFailed = false;
      });
    } catch (e) {
      debugPrint('SchoolTeachersPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _teachers = const [];
        _assignments = const [];
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  // ── ตัวเลือก filter สร้างจากข้อมูลจริง ─────────────────────────────────

  List<String> get _roleItems {
    final Set<String> labels = <String>{
      for (final _TeacherRecord t in _teachers)
        for (final UserRole r in t.roles) r.label,
    };
    final List<String> sorted = labels.toList()..sort();
    return <String>[kAllRoles, ...sorted];
  }

  List<String> get _homeroomItems {
    final Set<String> labels = <String>{
      for (final HomeroomAssignment a in _assignments) _homeroomLabel(a),
    };
    final List<String> sorted = labels.toList()..sort();
    return <String>[
      kAllHomerooms,
      ...sorted,
      if (_teachers.any((_TeacherRecord t) => t.homerooms.isEmpty)) kNoHomeroom,
    ];
  }

  List<String> get _statusItems {
    final Set<String> statuses = <String>{
      for (final _TeacherRecord t in _teachers) t.statusLabel,
    };
    final List<String> sorted = statuses.toList()..sort();
    return <String>[kAllStatus, ...sorted];
  }

  String _valid(String selected, List<String> items) =>
      items.contains(selected) ? selected : items.first;

  List<_TeacherRecord> get _filteredTeachers {
    final String keyword = _searchController.text.trim().toLowerCase();
    final String role = _valid(_selectedRole, _roleItems);
    final String homeroom = _valid(_selectedHomeroom, _homeroomItems);
    final String status = _valid(_selectedStatus, _statusItems);

    return _teachers.where((_TeacherRecord t) {
      final bool matchesSearch =
          keyword.isEmpty ||
          t.fullName.toLowerCase().contains(keyword) ||
          t.email.toLowerCase().contains(keyword);

      final bool matchesRole =
          role == kAllRoles ||
          t.roles.any((UserRole r) => r.label == role);

      final bool matchesHomeroom = homeroom == kAllHomerooms
          ? true
          : (homeroom == kNoHomeroom
                ? t.homerooms.isEmpty
                : t.homerooms.contains(homeroom));

      final bool matchesStatus = _filterSuspendedOnly
          ? t.suspended
          : (status == kAllStatus || t.statusLabel == status);

      return matchesSearch && matchesRole && matchesHomeroom && matchesStatus;
    }).toList();
  }

  int get _activeCount =>
      _teachers.where((_TeacherRecord t) => !t.suspended).length;

  int get _suspendedCount =>
      _teachers.where((_TeacherRecord t) => t.suspended).length;

  int get _homeroomTeacherCount =>
      _teachers.where((_TeacherRecord t) => t.homerooms.isNotEmpty).length;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedRole = kAllRoles;
      _selectedHomeroom = kAllHomerooms;
      _selectedStatus = kAllStatus;
      _filterSuspendedOnly = false;
    });
  }

  /// ผู้รับผิดชอบอาคาร = buildings.manager_name (ที่หน้าอาคารแสดง) — เลือกจาก
  /// รายชื่อครูที่โหลดไว้ในหน้านี้ แล้วเขียนผ่าน set_school_building_manager
  Future<void> _openBuildingManagerPicker() async {
    List<SchoolBuildingRecord> buildings;
    try {
      buildings = await (widget.loadBuildings ??
          () => SchoolAdminPlatformService().fetchBuildings())();
    } catch (e) {
      debugPrint('SchoolTeachersPage: list_school_buildings ล้ม — $e');
      if (!mounted) return;
      _showMessage('โหลดรายการอาคารไม่สำเร็จ กรุณาลองใหม่');
      return;
    }
    if (!mounted) return;
    if (buildings.isEmpty) {
      _showMessage('ยังไม่มีอาคารในระบบ — สร้างจากหน้า "อาคารและห้อง" ก่อน');
      return;
    }
    final names = <String>{for (final t in _teachers) t.fullName}.toList()..sort();
    var buildingId = buildings.first.id;
    String? manager = buildings.first.managerName.isEmpty ? null : buildings.first.managerName;
    if (manager != null && !names.contains(manager)) names.add(manager);
    var submitting = false;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Future<void> submit() async {
            setSheet(() {
              submitting = true;
              error = null;
            });
            try {
              await (widget.setBuildingManager ??
                  ({required String buildingId, required String? managerName}) =>
                      SchoolAdminPlatformService().setBuildingManager(
                        buildingId: buildingId,
                        managerName: managerName,
                      ))(buildingId: buildingId, managerName: manager);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              if (!mounted) return;
              _showMessage(manager == null
                  ? 'ล้างผู้รับผิดชอบอาคารแล้ว'
                  : 'กำหนด $manager เป็นผู้รับผิดชอบอาคารแล้ว');
            } catch (e) {
              debugPrint('SchoolTeachersPage: set_school_building_manager ล้ม — $e');
              if (!sheetContext.mounted) return;
              setSheet(() {
                submitting = false;
                error = 'บันทึกผู้รับผิดชอบไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('กำหนดครูประจำอาคาร',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: buildingId,
                    decoration: const InputDecoration(labelText: 'อาคาร'),
                    items: [
                      for (final b in buildings)
                        DropdownMenuItem(value: b.id, child: Text(b.name)),
                    ],
                    onChanged: submitting
                        ? null
                        : (v) => setSheet(() {
                              buildingId = v ?? buildingId;
                              final current = buildings.firstWhere((b) => b.id == buildingId).managerName;
                              manager = current.isEmpty ? null : current;
                              if (manager != null && !names.contains(manager)) names.add(manager!);
                            }),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    value: manager,
                    decoration: const InputDecoration(labelText: 'ผู้รับผิดชอบ'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('— ไม่กำหนด —')),
                      for (final n in names) DropdownMenuItem<String?>(value: n, child: Text(n)),
                    ],
                    onChanged: submitting ? null : (v) => setSheet(() => manager = v),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TextButton(
                        onPressed: submitting ? null : () => Navigator.of(sheetContext).pop(),
                        child: const Text('ยกเลิก'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: submitting ? null : submit,
                        child: Text(submitting ? 'กำลังบันทึก…' : 'บันทึก'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Mutations: เขียน → อ่าน canonical → ตรวจว่าเจอจริง → ค่อยบอกสำเร็จ ──

  _TeacherRecord? _find(List<_TeacherRecord> list, String id) {
    for (final _TeacherRecord t in list) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _toggleAccount(_TeacherRecord teacher) async {
    if (_busyIds.contains(teacher.id)) return;
    final bool wantSuspend = !teacher.suspended;
    setState(() => _busyIds.add(teacher.id));
    try {
      if (wantSuspend) {
        await (widget.suspendUser?.call(teacher.id) ??
            UserAdminService.suspendUser(teacher.id));
      } else {
        await (widget.reactivateUser?.call(teacher.id) ??
            UserAdminService.reactivateUser(teacher.id));
      }
      final users = await _fetchUsers();
      final assignments = await _fetchHomerooms();
      final List<_TeacherRecord> fresh = _toRecords(users, assignments);
      final _TeacherRecord? target = _find(fresh, teacher.id);
      if (target == null || target.suspended != wantSuspend) {
        throw StateError('backend_status_not_confirmed');
      }
      if (!mounted) return;
      setState(() {
        _teachers = fresh;
        _assignments = assignments;
        _loadFailed = false;
      });
      _showMessage(
        wantSuspend
            ? 'ระงับบัญชี ${teacher.fullName} แล้ว (ยืนยันกับระบบเรียบร้อย)'
            : 'เปิดใช้งานบัญชี ${teacher.fullName} แล้ว (ยืนยันกับระบบเรียบร้อย)',
      );
    } catch (e) {
      debugPrint('toggle teacher account failed: $e');
      _showMessage(
        'ปรับสถานะบัญชีไม่สำเร็จ ระบบยังไม่ยืนยันการเปลี่ยนแปลง กรุณาลองใหม่อีกครั้ง',
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(teacher.id));
    }
  }

  /// ฟอร์มเดิมมี 12 ช่อง แต่มีเพียงชื่อ–นามสกุล (update_user_profile) กับ
  /// ครูประจำชั้น (homeroom_assignments) ที่เขียนลงฐานข้อมูลได้จริง
  /// ครูประจำชั้นย้ายไปอยู่ในส่วน "ครูประจำชั้น" ด้านบน ที่นี่จึงเหลือแค่ชื่อ
  Future<void> _editTeacherName(_TeacherRecord teacher) async {
    final TextEditingController nameController = TextEditingController(
      text: teacher.fullName,
    );
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('แก้ไขชื่อ–นามสกุลบุคลากร'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ–นามสกุล',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ระบบรองรับการแก้ไขเฉพาะชื่อ–นามสกุล '
                'ส่วนกลุ่มสาระ เบอร์โทร ตำแหน่ง และอาคารที่รับผิดชอบ '
                'ยังไม่มีที่เก็บในฐานข้อมูล จึงยังแก้ไขไม่ได้',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(nameController.text.trim()),
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
    nameController.dispose();

    if (newName == null || !mounted) return;
    if (newName.isEmpty) {
      _showMessage('กรุณากรอกชื่อ–นามสกุล');
      return;
    }
    if (newName == teacher.fullName) return;

    setState(() => _busyIds.add(teacher.id));
    try {
      await (widget.updateName?.call(teacher.id, newName) ??
          AuthService.updateProfile(uid: teacher.id, name: newName));
      final users = await _fetchUsers();
      final assignments = await _fetchHomerooms();
      final List<_TeacherRecord> fresh = _toRecords(users, assignments);
      final _TeacherRecord? target = _find(fresh, teacher.id);
      if (target == null || target.fullName != newName) {
        throw StateError('backend_change_not_confirmed');
      }
      if (!mounted) return;
      setState(() {
        _teachers = fresh;
        _assignments = assignments;
        _loadFailed = false;
      });
      _showMessage('บันทึกชื่อบุคลากรแล้ว (ยืนยันกับระบบเรียบร้อย)');
    } catch (e) {
      debugPrint('update teacher name failed: $e');
      _showMessage(
        'บันทึกชื่อไม่สำเร็จ ระบบยังไม่ยืนยันการเปลี่ยนแปลง กรุณาลองใหม่อีกครั้ง',
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(teacher.id));
    }
  }

  Future<void> _assignHomeroom() async {
    if (_teachers.isEmpty) {
      _showMessage('ยังไม่มีรายชื่อครูให้มอบหมาย');
      return;
    }
    final TextEditingController gradeController = TextEditingController();
    final TextEditingController roomController = TextEditingController();
    String teacherId = _teachers.first.id;

    final _HomeroomDraft? draft = await showDialog<_HomeroomDraft>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('มอบหมายครูประจำชั้น'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: gradeController,
                      decoration: const InputDecoration(
                        labelText: 'ระดับชั้น',
                        hintText: 'เช่น ม.1',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: roomController,
                      decoration: const InputDecoration(
                        labelText: 'ห้อง',
                        hintText: 'เช่น 1',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // รายชื่อในดรอปดาวน์มาจากครูที่โหลดมาจริงเท่านั้น
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'ครู'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: teacherId,
                          isExpanded: true,
                          isDense: true,
                          items: _teachers.map((_TeacherRecord t) {
                            return DropdownMenuItem<String>(
                              value: t.id,
                              child: Text(
                                t.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? v) {
                            if (v != null) {
                              setDialogState(() => teacherId = v);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    _HomeroomDraft(
                      gradeLevel: gradeController.text.trim(),
                      room: roomController.text.trim(),
                      teacherId: teacherId,
                    ),
                  ),
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );

    gradeController.dispose();
    roomController.dispose();

    if (draft == null || !mounted) return;
    if (draft.gradeLevel.isEmpty || draft.room.isEmpty) {
      _showMessage('กรุณากรอกระดับชั้นและห้องให้ครบ');
      return;
    }

    const String busyKey = '__homeroom__';
    setState(() => _busyIds.add(busyKey));
    try {
      await (widget.setHomeroomTeacher?.call(
            draft.gradeLevel,
            draft.room,
            draft.teacherId,
          ) ??
          HomeroomService.setHomeroomTeacher(
            gradeLevel: draft.gradeLevel,
            room: draft.room,
            teacherId: draft.teacherId,
          ));
      final assignments = await _fetchHomerooms();
      final bool confirmed = assignments.any(
        (HomeroomAssignment a) =>
            a.teacherId == draft.teacherId &&
            a.gradeLevel.trim() == draft.gradeLevel &&
            a.room.trim() == draft.room,
      );
      if (!confirmed) throw StateError('backend_change_not_confirmed');
      final users = await _fetchUsers();
      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _teachers = _toRecords(users, assignments);
        _loadFailed = false;
      });
      _showMessage(
        'มอบหมายครูประจำชั้น ${draft.gradeLevel}/${draft.room} แล้ว (ยืนยันกับระบบเรียบร้อย)',
      );
    } catch (e) {
      debugPrint('set homeroom teacher failed: $e');
      _showMessage(
        'มอบหมายครูประจำชั้นไม่สำเร็จ ระบบยังไม่ยืนยันการเปลี่ยนแปลง กรุณาลองใหม่อีกครั้ง',
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(busyKey));
    }
  }

  Future<void> _removeHomeroom(HomeroomAssignment assignment) async {
    if (_busyIds.contains(assignment.assignmentId)) return;
    setState(() => _busyIds.add(assignment.assignmentId));
    try {
      await (widget.removeHomeroomTeacher?.call(assignment.assignmentId) ??
          HomeroomService.removeHomeroomTeacher(assignment.assignmentId));
      final assignments = await _fetchHomerooms();
      final bool stillThere = assignments.any(
        (HomeroomAssignment a) => a.assignmentId == assignment.assignmentId,
      );
      if (stillThere) throw StateError('backend_change_not_confirmed');
      final users = await _fetchUsers();
      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _teachers = _toRecords(users, assignments);
        _loadFailed = false;
      });
      _showMessage('ยกเลิกการมอบหมายแล้ว (ยืนยันกับระบบเรียบร้อย)');
    } catch (e) {
      debugPrint('remove homeroom teacher failed: $e');
      _showMessage(
        'ยกเลิกการมอบหมายไม่สำเร็จ ระบบยังไม่ยืนยันการเปลี่ยนแปลง กรุณาลองใหม่อีกครั้ง',
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(assignment.assignmentId));
    }
  }

  void _showTeacherDetail(_TeacherRecord teacher) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                              Icons.badge_rounded,
                              color: SchoolAdminPalette.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              teacher.fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: SchoolAdminPalette.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _TeacherDetailRow(
                        icon: Icons.email_rounded,
                        label: 'อีเมล',
                        value: teacher.email,
                      ),
                      _TeacherDetailRow(
                        icon: Icons.security_rounded,
                        label: 'บทบาทในระบบ',
                        value: teacher.rolesLabel,
                      ),
                      _TeacherDetailRow(
                        icon: Icons.co_present_rounded,
                        label: 'ครูประจำชั้น',
                        value: teacher.homerooms.isEmpty
                            ? kNoHomeroom
                            : teacher.homerooms.join(', '),
                      ),
                      _TeacherDetailRow(
                        icon: Icons.verified_user_rounded,
                        label: 'สถานะบัญชี',
                        value: teacher.statusLabel,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'กลุ่มสาระ เบอร์โทร ตำแหน่งหลัก อาคารที่รับผิดชอบ และเวลาเข้าใช้ล่าสุด '
                        'ยังไม่มีที่เก็บในฐานข้อมูล จึงไม่แสดงในหน้านี้',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.45,
                          color: SchoolAdminPalette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _editTeacherName(teacher);
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('แก้ไขชื่อ–นามสกุล'),
                        ),
                      ),
                    ],
                  ),
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
    final List<_TeacherRecord> teachers = _filteredTeachers;

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
                  if (_loadFailed) ...[
                    const SizedBox(height: 14),
                    _ErrorBanner(onRetry: _loadTeachers),
                  ],
                  const SizedBox(height: 14),
                  _buildSummary(),
                  const SizedBox(height: 14),
                  _buildQuickActions(),
                  const SizedBox(height: 14),
                  _buildHomeroomSection(),
                  const SizedBox(height: 14),
                  _buildFilters(),
                  const SizedBox(height: 14),
                  _buildTeacherList(teachers),
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
              const Widget title = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: SchoolAdminPalette.primarySoft,
                    child: Icon(
                      Icons.groups_rounded,
                      color: SchoolAdminPalette.primaryDark,
                    ),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ครูและบุคลากร',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ดูรายชื่อบุคลากร มอบหมายครูประจำชั้น แก้ไขชื่อ และระงับหรือเปิดใช้งานบัญชี',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
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
                    onPressed: _isLoading ? null : _loadTeachers,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('รีเฟรช'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const SchoolImportPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('นำเข้ารายชื่อ'),
                  ),
                ],
              );

              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 16), actions],
                );
              }

              return Row(
                children: [
                  const Expanded(child: title),
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
    final bool unknown = _isLoading || _loadFailed;
    final String stateNote = _isLoading ? 'กำลังโหลด…' : 'โหลดไม่สำเร็จ';

    // ⚠️ ช่องตัวเลขใหญ่ต้องสั้น — ข้อความสถานะไปอยู่บรรทัดรอง
    final List<_TeacherSummaryData> items = [
      _TeacherSummaryData(
        title: 'ครูและบุคลากรทั้งหมด',
        value: unknown ? '—' : '${_teachers.length}',
        detail: unknown ? stateNote : 'บัญชีที่มีบทบาทครู',
        icon: Icons.groups_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _TeacherSummaryData(
        title: 'บัญชีใช้งานปกติ',
        value: unknown ? '—' : '$_activeCount',
        detail: unknown ? stateNote : 'พร้อมเข้าใช้งาน',
        icon: Icons.verified_rounded,
        color: SchoolAdminPalette.green,
      ),
      _TeacherSummaryData(
        title: 'ครูประจำชั้น',
        value: unknown ? '—' : '$_homeroomTeacherCount',
        detail: unknown ? stateNote : 'ได้รับมอบหมายห้องแล้ว',
        icon: Icons.co_present_rounded,
        color: SchoolAdminPalette.secondary,
      ),
      _TeacherSummaryData(
        title: 'บัญชีถูกระงับ',
        value: unknown ? '—' : '$_suspendedCount',
        detail: unknown ? stateNote : 'เข้าใช้งานไม่ได้',
        icon: Icons.block_rounded,
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
          children: items.map((_TeacherSummaryData item) {
            return SizedBox(width: width, child: _TeacherSummaryCard(data: item));
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final List<_TeacherQuickActionData> actions = [
      _TeacherQuickActionData(
        title: 'มอบหมายครูประจำชั้น',
        subtitle: 'จับคู่ครูกับชั้นและห้องเรียนจริง',
        icon: Icons.co_present_rounded,
        onTap: (_isLoading || _loadFailed) ? null : _assignHomeroom,
      ),
      _TeacherQuickActionData(
        title: 'ดูบัญชีที่ถูกระงับ',
        subtitle: _filterSuspendedOnly
            ? 'กำลังกรอง (กดเพื่อยกเลิก)'
            : 'กรองเฉพาะบัญชีที่ถูกระงับ',
        icon: Icons.warning_amber_rounded,
        isActive: _filterSuspendedOnly,
        onTap: () {
          setState(() {
            _filterSuspendedOnly = !_filterSuspendedOnly;
            if (_filterSuspendedOnly) _selectedStatus = kAllStatus;
          });
        },
      ),
      _TeacherQuickActionData(
        title: 'เพิ่มบุคลากรรายคน',
        subtitle: 'ออกรหัสเชิญให้ไปสร้างบัญชีเอง',
        icon: Icons.person_add_alt_1_rounded,
        onTap: () => showInviteUserSheet(
          context,
          create: widget.createInvitation ??
              ({required String email, required UserRole role}) =>
                  InvitationService.createInvitation(email: email, role: role),
          onInvited: _loadTeachers,
        ),
      ),
      _TeacherQuickActionData(
        title: 'กำหนดครูประจำอาคาร',
        subtitle: 'เลือกอาคารและผู้รับผิดชอบจากรายชื่อครู',
        icon: Icons.apartment_rounded,
        onTap: _openBuildingManagerPicker,
      ),
    ];

    return _TeacherSectionCard(
      title: 'จัดการได้อย่างรวดเร็ว',
      subtitle: 'ทางลัดไปยังคำสั่งที่ใช้บ่อย',
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
            children: actions.map((_TeacherQuickActionData item) {
              return SizedBox(
                width: width,
                child: _TeacherQuickActionCard(data: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildHomeroomSection() {
    final Widget body;
    if (_isLoading) {
      body = const _StateBlock(
        icon: Icons.hourglass_top_rounded,
        title: 'กำลังโหลดการมอบหมาย…',
        detail: 'กำลังอ่านข้อมูลจากระบบ',
        showSpinner: true,
      );
    } else if (_loadFailed) {
      body = _StateBlock(
        icon: Icons.cloud_off_rounded,
        title: 'โหลดการมอบหมายไม่สำเร็จ',
        detail: 'ตรวจสอบการเชื่อมต่อแล้วกดลองใหม่อีกครั้ง',
        onRetry: _loadTeachers,
      );
    } else if (_assignments.isEmpty) {
      body = const _StateBlock(
        icon: Icons.inbox_rounded,
        title: kNoData,
        detail: 'ยังไม่มีการมอบหมายครูประจำชั้นในปีการศึกษาปัจจุบัน',
      );
    } else {
      body = Column(
        children: _assignments.map((HomeroomAssignment a) {
          final bool busy = _busyIds.contains(a.assignmentId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SchoolAdminPalette.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.co_present_rounded,
                    color: SchoolAdminPalette.primaryDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _homeroomLabel(a),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${a.teacherName ?? kNoData} • นักเรียน ${a.studentCount} คน',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: SchoolAdminPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (busy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton(
                      onPressed: () => _removeHomeroom(a),
                      child: const Text('ยกเลิกการมอบหมาย'),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return _TeacherSectionCard(
      title: 'ครูประจำชั้น',
      subtitle: 'ข้อมูลจริงจากตาราง homeroom_assignments ของปีการศึกษาปัจจุบัน',
      child: body,
    );
  }

  Widget _buildFilters() {
    final List<String> roleItems = _roleItems;
    final List<String> homeroomItems = _homeroomItems;
    final List<String> statusItems = _statusItems;

    return _TeacherSectionCard(
      title: 'ค้นหาและกรองรายชื่อ',
      subtitle: 'ตัวเลือกทั้งหมดสร้างจากข้อมูลที่โหลดมาจริง',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget search = TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อหรืออีเมล',
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

          final Widget role = _TeacherFilterDropdown(
            label: 'บทบาท',
            value: _valid(_selectedRole, roleItems),
            items: roleItems,
            onChanged: (String v) => setState(() => _selectedRole = v),
          );

          final Widget homeroom = _TeacherFilterDropdown(
            label: 'ห้องประจำชั้น',
            value: _valid(_selectedHomeroom, homeroomItems),
            items: homeroomItems,
            onChanged: (String v) => setState(() => _selectedHomeroom = v),
          );

          final Widget status = _TeacherFilterDropdown(
            label: 'สถานะบัญชี',
            value: _valid(_selectedStatus, statusItems),
            items: statusItems,
            onChanged: (String v) => setState(() => _selectedStatus = v),
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
                    Expanded(child: role),
                    const SizedBox(width: 10),
                    Expanded(child: homeroom),
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
              Expanded(child: role),
              const SizedBox(width: 10),
              Expanded(child: homeroom),
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

  Widget _buildTeacherList(List<_TeacherRecord> teachers) {
    final Widget body;
    if (_isLoading) {
      body = const _StateBlock(
        icon: Icons.hourglass_top_rounded,
        title: 'กำลังโหลดรายชื่อบุคลากร…',
        detail: 'กำลังอ่านข้อมูลจากระบบ',
        showSpinner: true,
      );
    } else if (_loadFailed) {
      body = _StateBlock(
        icon: Icons.cloud_off_rounded,
        title: 'โหลดรายชื่อบุคลากรไม่สำเร็จ',
        detail: 'ตรวจสอบการเชื่อมต่อแล้วกดลองใหม่อีกครั้ง',
        onRetry: _loadTeachers,
      );
    } else if (_teachers.isEmpty) {
      body = const _StateBlock(
        icon: Icons.inbox_rounded,
        title: kNoData,
        detail: 'ยังไม่มีบัญชีที่มีบทบาทครูในโรงเรียนนี้',
      );
    } else if (teachers.isEmpty) {
      body = const _StateBlock(
        icon: Icons.search_off_rounded,
        title: 'ไม่พบรายชื่อตามเงื่อนไข',
        detail: 'ลองเปลี่ยนคำค้นหาหรือล้างตัวกรอง',
      );
    } else {
      body = Column(
        children: teachers.map((_TeacherRecord teacher) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TeacherCard(
              teacher: teacher,
              busy: _busyIds.contains(teacher.id),
              onView: () => _showTeacherDetail(teacher),
              onEdit: () => _editTeacherName(teacher),
              onToggle: () => _toggleAccount(teacher),
            ),
          );
        }).toList(),
      );
    }

    return _TeacherSectionCard(
      title: 'รายชื่อครูและบุคลากร',
      subtitle: _isLoading
          ? 'กำลังโหลด…'
          : (_loadFailed
                ? 'โหลดไม่สำเร็จ'
                : 'พบ ${teachers.length} รายการ'
                      '${_filterSuspendedOnly ? ' (กำลังกรองเฉพาะบัญชีที่ถูกระงับ)' : ''}'),
      child: body,
    );
  }
}

class _HomeroomDraft {
  const _HomeroomDraft({
    required this.gradeLevel,
    required this.room,
    required this.teacherId,
  });

  final String gradeLevel;
  final String room;
  final String teacherId;
}

class _TeacherRecord {
  const _TeacherRecord({
    required this.id,
    required this.fullName,
    required this.email,
    required this.suspended,
    required this.roles,
    required this.homerooms,
  });

  final String id;
  final String fullName;
  final String email;
  final bool suspended;

  /// บทบาททั้งหมดจาก `all_roles` ไม่ใช่ active_role ตัวเดียว
  final List<UserRole> roles;
  final List<String> homerooms;

  String get statusLabel => suspended
      ? _SchoolTeachersPageState.kSuspended
      : _SchoolTeachersPageState.kActive;

  String get rolesLabel => roles.isEmpty
      ? _SchoolTeachersPageState.kNoData
      : roles.map((UserRole r) => r.label).join(', ');
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'โหลดข้อมูลบุคลากรไม่สำเร็จ ตัวเลขและรายชื่อทั้งหมดจึงยังไม่แสดง',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }
}

class _StateBlock extends StatelessWidget {
  const _StateBlock({
    required this.icon,
    required this.title,
    required this.detail,
    this.onRetry,
    this.showSpinner = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onRetry;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            if (showSpinner)
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Icon(icon, size: 44, color: SchoolAdminPalette.textMuted),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('ลองใหม่'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeacherSummaryCard extends StatelessWidget {
  const _TeacherSummaryCard({required this.data});

  final _TeacherSummaryData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 240;

        return Container(
          constraints: BoxConstraints(minHeight: compact ? 172 : 156),
          padding: EdgeInsets.all(compact ? 15 : 17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TeacherIconBox(
                      icon: data.icon,
                      color: data.color,
                      compact: true,
                    ),
                    const SizedBox(height: 12),
                    _value(26),
                    const SizedBox(height: 5),
                    _title(13),
                    const SizedBox(height: 3),
                    _detail(),
                  ],
                )
              : Row(
                  children: [
                    _TeacherIconBox(icon: data.icon, color: data.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _value(28),
                          const SizedBox(height: 5),
                          _title(13.5),
                          const SizedBox(height: 3),
                          _detail(),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _value(double size) => Text(
    data.value,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: SchoolAdminPalette.textPrimary,
    ),
  );

  Widget _title(double size) => Text(
    data.title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: SchoolAdminPalette.textPrimary,
    ),
  );

  Widget _detail() => Text(
    data.detail,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontSize: 10.5,
      height: 1.4,
      color: SchoolAdminPalette.textSecondary,
    ),
  );
}

class _TeacherQuickActionCard extends StatelessWidget {
  const _TeacherQuickActionCard({required this.data});

  final _TeacherQuickActionData data;

  @override
  Widget build(BuildContext context) {
    final bool enabled = data.onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: data.isActive ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 104),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: data.isActive
                  ? const Color(0xFFFFFBEB)
                  : (enabled ? Colors.white : const Color(0xFFF8FAFC)),
              border: Border.all(
                color: data.isActive
                    ? const Color(0xFFF59E0B)
                    : SchoolAdminPalette.border,
                width: data.isActive ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _TeacherIconBox(
                  icon: data.icon,
                  color: SchoolAdminPalette.primaryDark,
                  compact: true,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              data.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: SchoolAdminPalette.textPrimary,
                              ),
                            ),
                          ),
                          if (!enabled) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ปิดใช้งาน',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.4,
                          color: SchoolAdminPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeacherSectionCard extends StatelessWidget {
  const _TeacherSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
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
              const SizedBox(height: 3),
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
        ),
      ),
    );
  }
}

class _TeacherFilterDropdown extends StatelessWidget {
  const _TeacherFilterDropdown({
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

class _TeacherCard extends StatelessWidget {
  const _TeacherCard({
    required this.teacher,
    required this.busy,
    required this.onView,
    required this.onEdit,
    required this.onToggle,
  });

  final _TeacherRecord teacher;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                  Icons.badge_rounded,
                  color: SchoolAdminPalette.primaryDark,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      teacher.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TeacherBadge(
                label: teacher.rolesLabel,
                color: SchoolAdminPalette.primaryDark,
                icon: Icons.security_rounded,
              ),
              _TeacherBadge(
                label: teacher.homerooms.isEmpty
                    ? _SchoolTeachersPageState.kNoHomeroom
                    : 'ประจำชั้น ${teacher.homerooms.join(', ')}',
                color: SchoolAdminPalette.secondary,
                icon: Icons.co_present_rounded,
              ),
              _TeacherBadge(
                label: teacher.statusLabel,
                color: teacher.suspended
                    ? SchoolAdminPalette.red
                    : SchoolAdminPalette.green,
                icon: Icons.verified_user_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('แก้ไขชื่อ'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onToggle,
                  icon: Icon(
                    teacher.suspended
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    size: 17,
                  ),
                  label: Text(teacher.suspended ? 'เปิดบัญชี' : 'ระงับ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeacherBadge extends StatelessWidget {
  const _TeacherBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherIconBox extends StatelessWidget {
  const _TeacherIconBox({
    required this.icon,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 46 : 52;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: color.withAlpha(82), width: 1.1),
      ),
      child: Icon(icon, color: color, size: compact ? 22 : 24),
    );
  }
}

class _TeacherDetailRow extends StatelessWidget {
  const _TeacherDetailRow({
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
          Icon(icon, color: SchoolAdminPalette.primaryDark, size: 19),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
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
              value.isEmpty ? _SchoolTeachersPageState.kNoData : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
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

class _TeacherSummaryData {
  const _TeacherSummaryData({
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

class _TeacherQuickActionData {
  const _TeacherQuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// null = ยังไม่มี backend รองรับ การ์ดจะถูก disable พร้อมบอกเหตุผล
  final VoidCallback? onTap;
  final bool isActive;
}
