import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'school_import_page.dart';
import 'theme/school_admin_palette.dart';

/// หน้าจัดการนักเรียนของ School Admin
///
/// ประวัติ (2026-09-06): เดิมหน้านี้เรียก `UserAdminService.getAllUsers()`
/// จริงก็จริง แต่แล้ว **แต่งค่าที่ backend ไม่เคยคืนมาขึ้นเองเกือบทั้งแถว** —
/// `list_school_users` คืนแค่ user_id / first_name / last_name / email /
/// active_role / all_roles / active_school_id / status เท่านั้น ส่วน
/// รหัสนักเรียน ระดับชั้น ห้อง เลขที่ ชื่อผู้ปกครอง เบอร์ผู้ปกครอง การมาเรียน
/// และ "เข้าใช้ล่าสุด" ถูกสร้างจากดัชนีของแถว (`idx % 3`, `081-234-567$idx`)
/// นอกจากนี้ยังมีรายชื่อปลอม 3 คน (สมชาย ใจดี ฯลฯ) ที่โผล่มาเมื่อไม่มีนักเรียน
/// และ `catch (_) {}` ที่กลืน error ทั้งก้อน ทำให้ "โหลดล้มเหลว" กับ
/// "ไม่มีข้อมูล" หน้าตาเหมือนกันเป๊ะ
///
/// ตอนนี้ทุกช่องมาจาก RPC จริงเท่านั้น:
///   list_school_users        → ชื่อ อีเมล สถานะบัญชี บทบาททั้งหมด
///   list_homeroom_assignments + list_homeroom_roster
///                            → ระดับชั้น / ห้อง / รหัสนักเรียน (เท่าที่ถูก
///                              จัดห้องแล้วจริง)
///   suspend_user / reactivate_user → ระงับ/เปิดบัญชี
///   update_user_profile      → แก้ชื่อ–นามสกุล
/// ช่องที่ไม่มี RPC รองรับ (ผู้ปกครอง การมาเรียนรายวัน เข้าใช้ล่าสุด เลขที่)
/// ถูกถอดออกทั้งหมด ไม่ได้แทนที่ด้วยค่าเดา
class SchoolStudentsPage extends StatefulWidget {
  const SchoolStudentsPage({
    super.key,
    this.loadUsers,
    this.loadHomerooms,
    this.loadRoster,
    this.suspendUser,
    this.reactivateUser,
    this.updateName,
  });

  /// Injectable seams — production ปล่อยว่างแล้วใช้ service จริง เทสต์ส่งเข้ามา
  /// เพื่อไล่สถานะ loading / data / empty / error / mutation ได้โดยไม่ต้องมี
  /// Supabase จริง (รูปแบบเดียวกับ school_resources_page / cctv page)
  final Future<List<UserModel>> Function()? loadUsers;
  final Future<List<HomeroomAssignment>> Function()? loadHomerooms;
  final Future<List<HomeroomRosterItem>> Function(String gradeLevel, String room)?
      loadRoster;
  final Future<void> Function(String uid)? suspendUser;
  final Future<void> Function(String uid)? reactivateUser;
  final Future<void> Function(String uid, String name)? updateName;

  @override
  State<SchoolStudentsPage> createState() => _SchoolStudentsPageState();
}

class _SchoolStudentsPageState extends State<SchoolStudentsPage> {
  static const String kNoData = 'ยังไม่มีข้อมูล';
  static const String kUnplaced = 'ยังไม่ได้จัดห้องเรียน';
  static const String kAllLevels = 'ทุกระดับชั้น';
  static const String kAllRooms = 'ทุกห้อง';
  static const String kAllStatus = 'ทุกสถานะ';
  static const String kActive = 'ใช้งาน';
  static const String kSuspended = 'ระงับ';

  final TextEditingController _searchController = TextEditingController();

  String _selectedLevel = kAllLevels;
  String _selectedRoom = kAllRooms;
  String _selectedStatus = kAllStatus;
  bool _filterSuspendedOnly = false;

  List<_StudentRecord> _students = const [];
  bool _isLoading = true;
  bool _loadFailed = false;
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<UserModel>> _fetchUsers() =>
      widget.loadUsers?.call() ?? UserAdminService.getAllUsers();

  /// อ่านการจัดห้องเรียนจริงจาก homeroom_assignments + roster ของแต่ละห้อง
  /// นี่คือแหล่งเดียวที่ระบบรู้ระดับชั้น/ห้อง/รหัสนักเรียนของนักเรียนแต่ละคน
  /// (`users.building` / `users.room` ไม่เคยถูกเซ็ตจากฝั่งนี้ — ของเดิมอ่าน
  /// สองช่องนั้นแล้วตกไปที่ค่าคงที่ 'ม.1' / '1' เสมอ)
  Future<Map<String, _Placement>> _fetchPlacements() async {
    final assignments =
        await (widget.loadHomerooms?.call() ??
            HomeroomService.listHomeroomAssignments());
    final Map<String, _Placement> placements = <String, _Placement>{};
    for (final HomeroomAssignment a in assignments) {
      final roster =
          await (widget.loadRoster?.call(a.gradeLevel, a.room) ??
              HomeroomService.listHomeroomRoster(
                gradeLevel: a.gradeLevel,
                room: a.room,
              ));
      for (final HomeroomRosterItem item in roster) {
        placements[item.studentId] = _Placement(
          gradeLevel: a.gradeLevel.trim().isEmpty ? null : a.gradeLevel.trim(),
          room: a.room.trim().isEmpty ? null : a.room.trim(),
          studentCode:
              item.studentCode.trim().isEmpty ? null : item.studentCode.trim(),
        );
      }
    }
    return placements;
  }

  List<_StudentRecord> _toRecords(
    List<UserModel> users,
    Map<String, _Placement> placements,
  ) {
    // ⚠️ ต้องกรองด้วย hasRole (เช็ค all_roles) ไม่ใช่ role == student
    // บัญชีหนึ่งถือได้หลายบทบาท และ active_role คือบทบาทที่ถูก grant ล่าสุด
    // เท่านั้น การเทียบเท่ากับบทบาทเดียวเคยทำให้คนหายจากรายการมาแล้ว
    return users
        .where((UserModel u) => u.hasRole(UserRole.student))
        .map((UserModel u) {
          final _Placement? p = placements[u.uid];
          return _StudentRecord(
            id: u.uid,
            fullName: u.name.trim(),
            email: u.email,
            suspended: u.status == 'suspended',
            gradeLevel: p?.gradeLevel,
            room: p?.room,
            studentCode: p?.studentCode,
          );
        })
        .toList();
  }

  Future<void> _loadStudents() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadFailed = false;
      });
    }
    try {
      final users = await _fetchUsers();
      final placements = await _fetchPlacements();
      if (!mounted) return;
      setState(() {
        _students = _toRecords(users, placements);
        _isLoading = false;
        _loadFailed = false;
      });
    } catch (e) {
      debugPrint('SchoolStudentsPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _students = const [];
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  // ── ตัวเลือกใน filter สร้างจากข้อมูลที่โหลดมาจริง ──────────────────────

  List<String> get _levelItems {
    final Set<String> levels = <String>{
      for (final _StudentRecord s in _students)
        if (s.gradeLevel != null) s.gradeLevel!,
    };
    final List<String> sorted = levels.toList()..sort();
    return <String>[
      kAllLevels,
      ...sorted,
      if (_students.any((_StudentRecord s) => s.gradeLevel == null)) kUnplaced,
    ];
  }

  List<String> get _roomItems {
    final Set<String> rooms = <String>{
      for (final _StudentRecord s in _students)
        if (s.room != null) s.room!,
    };
    final List<String> sorted = rooms.toList()..sort();
    return <String>[kAllRooms, ...sorted];
  }

  List<String> get _statusItems {
    final Set<String> statuses = <String>{
      for (final _StudentRecord s in _students) s.statusLabel,
    };
    final List<String> sorted = statuses.toList()..sort();
    return <String>[kAllStatus, ...sorted];
  }

  String _valid(String selected, List<String> items) =>
      items.contains(selected) ? selected : items.first;

  List<_StudentRecord> get _filteredStudents {
    final String keyword = _searchController.text.trim().toLowerCase();
    final String level = _valid(_selectedLevel, _levelItems);
    final String room = _valid(_selectedRoom, _roomItems);
    final String status = _valid(_selectedStatus, _statusItems);

    return _students.where((_StudentRecord s) {
      final bool matchesSearch =
          keyword.isEmpty ||
          s.fullName.toLowerCase().contains(keyword) ||
          s.email.toLowerCase().contains(keyword) ||
          (s.studentCode ?? '').toLowerCase().contains(keyword);

      final bool matchesLevel = level == kAllLevels
          ? true
          : (level == kUnplaced
                ? s.gradeLevel == null
                : s.gradeLevel == level);

      final bool matchesRoom = room == kAllRooms || s.room == room;

      final bool matchesStatus = _filterSuspendedOnly
          ? s.suspended
          : (status == kAllStatus || s.statusLabel == status);

      return matchesSearch && matchesLevel && matchesRoom && matchesStatus;
    }).toList();
  }

  int get _activeCount =>
      _students.where((_StudentRecord s) => !s.suspended).length;

  int get _suspendedCount =>
      _students.where((_StudentRecord s) => s.suspended).length;

  int get _unplacedCount =>
      _students.where((_StudentRecord s) => s.gradeLevel == null).length;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedLevel = kAllLevels;
      _selectedRoom = kAllRooms;
      _selectedStatus = kAllStatus;
      _filterSuspendedOnly = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Mutations: เขียน → อ่าน canonical กลับ → ตรวจว่าเจอจริง → ค่อยบอกสำเร็จ ──

  _StudentRecord? _find(List<_StudentRecord> list, String id) {
    for (final _StudentRecord s in list) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// อ่านสถานะ canonical กลับมาแล้วคืนรายการที่สร้างใหม่ทั้งชุด
  /// โยน `backend_change_not_confirmed` ถ้า backend ไม่ยืนยันการเปลี่ยนแปลง
  Future<List<_StudentRecord>> _refetchAndConfirm(
    bool Function(_StudentRecord fresh) confirmed,
    String targetId,
  ) async {
    final users = await _fetchUsers();
    final placements = await _fetchPlacements();
    final List<_StudentRecord> fresh = _toRecords(users, placements);
    final _StudentRecord? target = _find(fresh, targetId);
    if (target == null || !confirmed(target)) {
      throw StateError('backend_change_not_confirmed');
    }
    return fresh;
  }

  Future<void> _toggleAccount(_StudentRecord student) async {
    if (_busyIds.contains(student.id)) return;
    final bool wantSuspend = !student.suspended;
    setState(() => _busyIds.add(student.id));
    try {
      if (wantSuspend) {
        await (widget.suspendUser?.call(student.id) ??
            UserAdminService.suspendUser(student.id));
      } else {
        await (widget.reactivateUser?.call(student.id) ??
            UserAdminService.reactivateUser(student.id));
      }
      final List<_StudentRecord> fresh = await _refetchAndConfirm(
        (_StudentRecord s) => s.suspended == wantSuspend,
        student.id,
      );
      if (!mounted) return;
      setState(() {
        _students = fresh;
        _loadFailed = false;
      });
      _showMessage(
        wantSuspend
            ? 'ระงับบัญชี ${student.fullName} แล้ว (ยืนยันกับระบบเรียบร้อย)'
            : 'เปิดใช้งานบัญชี ${student.fullName} แล้ว (ยืนยันกับระบบเรียบร้อย)',
      );
    } catch (e) {
      debugPrint('toggle student account failed: $e');
      _showMessage(
        'ปรับสถานะบัญชีไม่สำเร็จ ระบบยังไม่ยืนยันการเปลี่ยนแปลง กรุณาลองใหม่อีกครั้ง',
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(student.id));
    }
  }

  /// ฟอร์มแก้ไขเหลือเฉพาะช่องที่มี RPC รองรับจริง — `update_user_profile`
  /// แก้ได้แค่ first_name/last_name ช่องอื่นในฟอร์มเดิม (รหัสนักเรียน อีเมล
  /// เลขที่ ระดับชั้น ห้อง ผู้ปกครอง เบอร์โทร การมาเรียน สถานะ) ไม่มี endpoint
  /// ให้เขียนเลย กดบันทึกแล้วค่าหายทันทีที่รีเฟรช
  Future<void> _editStudentName(_StudentRecord student) async {
    final TextEditingController nameController = TextEditingController(
      text: student.fullName,
    );
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('แก้ไขชื่อ–นามสกุลนักเรียน'),
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
                'ระบบรองรับการแก้ไขเฉพาะชื่อ–นามสกุลเท่านั้น '
                'รหัสนักเรียน ระดับชั้น ห้อง และอีเมล ยังไม่มีช่องทางแก้ไขจากหน้านี้',
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
    if (newName == student.fullName) return;

    setState(() => _busyIds.add(student.id));
    try {
      await (widget.updateName?.call(student.id, newName) ??
          AuthService.updateProfile(uid: student.id, name: newName));
      final List<_StudentRecord> fresh = await _refetchAndConfirm(
        (_StudentRecord s) => s.fullName == newName,
        student.id,
      );
      if (!mounted) return;
      setState(() {
        _students = fresh;
        _loadFailed = false;
      });
      _showMessage('บันทึกชื่อนักเรียนแล้ว (ยืนยันกับระบบเรียบร้อย)');
    } catch (e) {
      debugPrint('update student name failed: $e');
      _showMessage(
        'บันทึกชื่อไม่สำเร็จ ระบบยังไม่ยืนยันการเปลี่ยนแปลง กรุณาลองใหม่อีกครั้ง',
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(student.id));
    }
  }

  void _showStudentDetail(_StudentRecord student) {
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
                              Icons.person_rounded,
                              color: SchoolAdminPalette.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.fullName,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: SchoolAdminPalette.textPrimary,
                                  ),
                                ),
                                Text(
                                  student.classLabel ?? kUnplaced,
                                  style: const TextStyle(
                                    fontSize: 12.5,
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
                      const SizedBox(height: 18),
                      _DetailRow(
                        icon: Icons.email_rounded,
                        label: 'อีเมล',
                        value: student.email,
                      ),
                      _DetailRow(
                        icon: Icons.badge_outlined,
                        label: 'รหัสนักเรียน',
                        value: student.studentCode ?? kNoData,
                      ),
                      _DetailRow(
                        icon: Icons.layers_outlined,
                        label: 'ระดับชั้น / ห้อง',
                        value: student.classLabel ?? kNoData,
                      ),
                      _DetailRow(
                        icon: Icons.verified_user_rounded,
                        label: 'สถานะบัญชี',
                        value: student.statusLabel,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ข้อมูลผู้ปกครอง การมาเรียนรายวัน และเวลาเข้าใช้ล่าสุด '
                        'ยังไม่มีช่องทางอ่านจากระบบหลังบ้าน จึงไม่แสดงในหน้านี้',
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
                            _editStudentName(student);
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
    final List<_StudentRecord> students = _filteredStudents;

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
                    _ErrorBanner(onRetry: _loadStudents),
                  ],
                  const SizedBox(height: 14),
                  _buildSummary(),
                  const SizedBox(height: 14),
                  _buildQuickActions(),
                  const SizedBox(height: 14),
                  _buildFilters(),
                  const SizedBox(height: 14),
                  _buildStudentList(students),
                  const SizedBox(height: 14),
                  _buildLevelOverview(),
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
                      Icons.school_rounded,
                      color: SchoolAdminPalette.primaryDark,
                    ),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'จัดการนักเรียน',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ดูรายชื่อนักเรียน ตรวจสอบสถานะบัญชี แก้ไขชื่อ และระงับหรือเปิดใช้งานบัญชี',
                          style: TextStyle(
                            fontSize: 12.5,
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
                    onPressed: _isLoading ? null : _loadStudents,
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
    final String stateNote = _isLoading ? 'กำลังโหลด…' : 'โหลดไม่สำเร็จ';
    final bool unknown = _isLoading || _loadFailed;

    // ⚠️ ช่องตัวเลขใหญ่ต้องสั้นเสมอ — เคยใส่ 'ยังไม่มีข้อมูล' ลงไปแล้วการ์ด
    // overflow 24px ข้อความอธิบายไปอยู่บรรทัดรองแทน
    final List<_SummaryItem> items = [
      _SummaryItem(
        title: 'นักเรียนทั้งหมด',
        value: unknown ? '—' : '${_students.length}',
        detail: unknown ? stateNote : 'รายชื่อในโรงเรียน',
        icon: Icons.groups_rounded,
        color: SchoolAdminPalette.primary,
      ),
      _SummaryItem(
        title: 'บัญชีใช้งานปกติ',
        value: unknown ? '—' : '$_activeCount',
        detail: unknown ? stateNote : 'พร้อมเข้าใช้งาน',
        icon: Icons.verified_rounded,
        color: SchoolAdminPalette.green,
      ),
      _SummaryItem(
        title: 'บัญชีถูกระงับ',
        value: unknown ? '—' : '$_suspendedCount',
        detail: unknown ? stateNote : 'เข้าใช้งานไม่ได้',
        icon: Icons.block_rounded,
        color: SchoolAdminPalette.red,
      ),
      _SummaryItem(
        title: 'ยังไม่ได้จัดห้องเรียน',
        value: unknown ? '—' : '$_unplacedCount',
        detail: unknown ? stateNote : 'ยังไม่อยู่ในห้องเรียนใด',
        icon: Icons.help_outline_rounded,
        color: SchoolAdminPalette.secondary,
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
          children: items.map((_SummaryItem item) {
            return SizedBox(width: width, child: _SummaryCard(item: item));
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return _SectionCard(
      title: 'จัดการได้อย่างรวดเร็ว',
      subtitle: 'ปุ่มที่ยังไม่มีระบบหลังบ้านรองรับจะถูกปิดไว้พร้อมเหตุผล',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final List<_QuickActionData> actions = [
            _QuickActionData(
              title: 'นำเข้ารายชื่อ',
              subtitle: 'เพิ่มนักเรียนหลายคนจากไฟล์',
              icon: Icons.upload_file_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SchoolImportPage(),
                  ),
                );
              },
            ),
            _QuickActionData(
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
            // ไม่มี RPC สร้างบัญชีนักเรียนรายคนที่แอปนี้เรียกได้
            // (`admin_update_user_profile` เป็นของ aiot_dev_dashboard ไม่มี
            // p_token, `create_staff_invitation` เป็นการเชิญบุคลากร ไม่ใช่
            // นักเรียน) ทางเดียวที่ใช้ได้จริงคือ import_school_users_batch
            const _QuickActionData(
              title: 'เพิ่มนักเรียนรายคน',
              subtitle: 'ยังไม่มีระบบหลังบ้านรองรับ ใช้ "นำเข้ารายชื่อ" แทน',
              icon: Icons.person_add_alt_1_rounded,
              onTap: null,
            ),
            const _QuickActionData(
              title: 'ส่งออกรายชื่อ',
              subtitle: 'ยังไม่มีระบบหลังบ้านรองรับการส่งออกไฟล์',
              icon: Icons.download_rounded,
              onTap: null,
            ),
          ];

          int columns = 4;
          if (constraints.maxWidth < 900) columns = 2;
          if (constraints.maxWidth < 520) columns = 1;

          const double spacing = 10;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: actions.map((_QuickActionData item) {
              return SizedBox(width: width, child: _QuickActionCard(data: item));
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    final List<String> levelItems = _levelItems;
    final List<String> roomItems = _roomItems;
    final List<String> statusItems = _statusItems;

    return _SectionCard(
      title: 'ค้นหาและกรองรายชื่อ',
      subtitle: 'ตัวเลือกทั้งหมดสร้างจากข้อมูลที่โหลดมาจริง',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget search = TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อ อีเมล หรือรหัสนักเรียน',
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

          final Widget level = _FilterDropdown(
            label: 'ระดับชั้น',
            value: _valid(_selectedLevel, levelItems),
            items: levelItems,
            onChanged: (String value) =>
                setState(() => _selectedLevel = value),
          );

          final Widget room = _FilterDropdown(
            label: 'ห้อง',
            value: _valid(_selectedRoom, roomItems),
            items: roomItems,
            onChanged: (String value) => setState(() => _selectedRoom = value),
          );

          final Widget status = _FilterDropdown(
            label: 'สถานะบัญชี',
            value: _valid(_selectedStatus, statusItems),
            items: statusItems,
            onChanged: (String value) =>
                setState(() => _selectedStatus = value),
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
                    Expanded(child: level),
                    const SizedBox(width: 10),
                    Expanded(child: room),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [Expanded(child: status), const SizedBox(width: 10), clear],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 10),
              Expanded(child: level),
              const SizedBox(width: 10),
              Expanded(child: room),
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

  Widget _buildStudentList(List<_StudentRecord> students) {
    final Widget body;
    if (_isLoading) {
      body = const _StateBlock(
        icon: Icons.hourglass_top_rounded,
        title: 'กำลังโหลดรายชื่อนักเรียน…',
        detail: 'กำลังอ่านข้อมูลจากระบบ',
        showSpinner: true,
      );
    } else if (_loadFailed) {
      body = _StateBlock(
        icon: Icons.cloud_off_rounded,
        title: 'โหลดรายชื่อนักเรียนไม่สำเร็จ',
        detail: 'ตรวจสอบการเชื่อมต่อแล้วกดลองใหม่อีกครั้ง',
        onRetry: _loadStudents,
      );
    } else if (_students.isEmpty) {
      body = const _StateBlock(
        icon: Icons.inbox_rounded,
        title: kNoData,
        detail: 'ยังไม่มีบัญชีนักเรียนในโรงเรียนนี้',
      );
    } else if (students.isEmpty) {
      body = const _StateBlock(
        icon: Icons.search_off_rounded,
        title: 'ไม่พบรายชื่อนักเรียนตามเงื่อนไข',
        detail: 'ลองเปลี่ยนคำค้นหาหรือล้างตัวกรอง',
      );
    } else {
      body = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth >= 1050) {
            return _DesktopStudentTable(
              students: students,
              busyIds: _busyIds,
              onView: _showStudentDetail,
              onEdit: _editStudentName,
              onToggleAccount: _toggleAccount,
            );
          }
          return Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: students.map((_StudentRecord student) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MobileStudentCard(
                    student: student,
                    busy: _busyIds.contains(student.id),
                    onView: () => _showStudentDetail(student),
                    onEdit: () => _editStudentName(student),
                    onToggle: () => _toggleAccount(student),
                  ),
                );
              }).toList(),
            ),
          );
        },
      );
    }

    return _SectionCard(
      title: 'รายชื่อนักเรียน',
      subtitle: _isLoading
          ? 'กำลังโหลด…'
          : (_loadFailed
                ? 'โหลดไม่สำเร็จ'
                : 'พบ ${students.length} รายการ'
                      '${_filterSuspendedOnly ? ' (กำลังกรองเฉพาะบัญชีที่ถูกระงับ)' : ''}'),
      padding: EdgeInsets.zero,
      action: _filterSuspendedOnly
          ? TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('ยกเลิกการกรอง'),
            )
          : null,
      child: body,
    );
  }

  Widget _buildLevelOverview() {
    return _SectionCard(
      title: 'จำนวนนักเรียนแต่ละระดับชั้น',
      subtitle: 'นับจากการจัดห้องเรียนจริงใน homeroom_assignments',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (_isLoading) {
            return const Text(
              'กำลังโหลด…',
              style: TextStyle(
                fontSize: 13,
                color: SchoolAdminPalette.textSecondary,
              ),
            );
          }
          if (_loadFailed) {
            return const Text(
              'โหลดไม่สำเร็จ',
              style: TextStyle(fontSize: 13, color: SchoolAdminPalette.red),
            );
          }

          final Map<String, int> counts = <String, int>{};
          for (final _StudentRecord s in _students) {
            final String key = s.gradeLevel ?? kUnplaced;
            counts[key] = (counts[key] ?? 0) + 1;
          }
          if (counts.isEmpty) {
            return const Text(
              kNoData,
              style: TextStyle(
                fontSize: 13,
                color: SchoolAdminPalette.textSecondary,
              ),
            );
          }

          final List<String> keys = counts.keys.toList()
            ..sort((String a, String b) {
              if (a == kUnplaced) return 1;
              if (b == kUnplaced) return -1;
              return a.compareTo(b);
            });

          int columns = 3;
          if (constraints.maxWidth < 520) columns = 2;
          if (constraints.maxWidth < 260) columns = 1;
          const double spacing = 8;
          final double cardWidth =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: keys.map((String level) {
              return SizedBox(
                width: cardWidth,
                child: _LevelCountCard(
                  level: level,
                  value: '${counts[level]} คน',
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _Placement {
  const _Placement({this.gradeLevel, this.room, this.studentCode});

  final String? gradeLevel;
  final String? room;
  final String? studentCode;
}

class _StudentRecord {
  const _StudentRecord({
    required this.id,
    required this.fullName,
    required this.email,
    required this.suspended,
    this.gradeLevel,
    this.room,
    this.studentCode,
  });

  final String id;
  final String fullName;
  final String email;
  final bool suspended;

  /// null = backend ไม่ได้คืนค่านี้มา ต้องแสดง `ยังไม่มีข้อมูล` ไม่ใช่ค่าเดา
  final String? gradeLevel;
  final String? room;
  final String? studentCode;

  String get statusLabel => suspended
      ? _SchoolStudentsPageState.kSuspended
      : _SchoolStudentsPageState.kActive;

  String? get classLabel {
    if (gradeLevel == null) return null;
    if (room == null || room == gradeLevel) return gradeLevel;
    return '$gradeLevel/$room';
  }
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
              'โหลดข้อมูลนักเรียนไม่สำเร็จ ตัวเลขและรายชื่อทั้งหมดจึงยังไม่แสดง',
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
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 16),
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
              Icon(icon, size: 46, color: SchoolAdminPalette.textMuted),
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
                fontSize: 12.5,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 220;

        return Container(
          constraints: BoxConstraints(minHeight: compact ? 152 : 145),
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: compact ? 18 : 20,
                backgroundColor: item.color.withAlpha(18),
                child: Icon(
                  item.icon,
                  size: compact ? 18 : 20,
                  color: item.color,
                ),
              ),
              SizedBox(height: compact ? 9 : 12),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 24 : 28,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              SizedBox(height: compact ? 3 : 5),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 12.5 : 13,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              SizedBox(height: compact ? 3 : 4),
              Text(
                item.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 10.5 : 11,
                  height: 1.3,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
    this.padding,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final bool isFullWidth = padding == EdgeInsets.zero;

    return SizedBox(
      width: double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: isFullWidth
                    ? const EdgeInsets.fromLTRB(18, 16, 18, 14)
                    : EdgeInsets.zero,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: SchoolAdminPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(width: 10),
                      action!,
                    ],
                  ],
                ),
              ),
              if (!isFullWidth) const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.data});

  final _QuickActionData data;

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: data.isActive
                  ? const Color(0xFFFFFBEB)
                  : (enabled ? Colors.white : const Color(0xFFF8FAFC)),
              border: Border.all(
                color: data.isActive
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFE2E8F0),
                width: data.isActive ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: data.isActive
                      ? const Color(0xFFFDE68A)
                      : const Color(0xFFF1F5F9),
                  child: Icon(
                    data.icon,
                    color: data.isActive
                        ? const Color(0xFFB45309)
                        : SchoolAdminPalette.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
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
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: data.isActive
                                    ? const Color(0xFF92400E)
                                    : const Color(0xFF0F172A),
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
                      const SizedBox(height: 1),
                      Text(
                        data.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: data.isActive
                              ? const Color(0xFFB45309)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
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

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
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

class _DesktopStudentTable extends StatelessWidget {
  const _DesktopStudentTable({
    required this.students,
    required this.busyIds,
    required this.onView,
    required this.onEdit,
    required this.onToggleAccount,
  });

  final List<_StudentRecord> students;
  final Set<String> busyIds;
  final ValueChanged<_StudentRecord> onView;
  final ValueChanged<_StudentRecord> onEdit;
  final ValueChanged<_StudentRecord> onToggleAccount;

  @override
  Widget build(BuildContext context) {
    return Table(
      border: const TableBorder(
        top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        horizontalInside: BorderSide(color: Color(0xFFF1F5F9), width: 1),
      ),
      columnWidths: const {
        0: FlexColumnWidth(2.8),
        1: FlexColumnWidth(1.3),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.25),
        4: FlexColumnWidth(0.85),
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
            _StudentTableHeader(text: 'นักเรียน', align: TextAlign.left),
            _StudentTableHeader(text: 'รหัสนักเรียน'),
            _StudentTableHeader(text: 'ชั้น/ห้อง'),
            _StudentTableHeader(text: 'สถานะบัญชี'),
            _StudentTableHeader(text: 'จัดการ'),
          ],
        ),
        ...students.map((_StudentRecord student) {
          final bool busy = busyIds.contains(student.id);
          return TableRow(
            children: [
              _StudentTableNameCell(
                student: student,
                onTap: () => onView(student),
              ),
              _StudentTableCell(
                child: Text(
                  student.studentCode ?? _SchoolStudentsPageState.kNoData,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: student.studentCode == null
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF334155),
                  ),
                ),
              ),
              _StudentTableCell(
                child: Text(
                  student.classLabel ?? _SchoolStudentsPageState.kNoData,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: student.classLabel == null
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F172A),
                  ),
                ),
              ),
              _StudentTableCell(
                child: _AccountBadge(value: student.statusLabel),
              ),
              _StudentTableCell(
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : PopupMenuButton<String>(
                        tooltip: 'ตัวเลือกจัดการ',
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        onSelected: (String value) {
                          switch (value) {
                            case 'view':
                              onView(student);
                              break;
                            case 'edit':
                              onEdit(student);
                              break;
                            case 'toggle':
                              onToggleAccount(student);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            const PopupMenuItem<String>(
                              value: 'view',
                              child: Text('ดูรายละเอียด'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('แก้ไขชื่อ–นามสกุล'),
                            ),
                            PopupMenuItem<String>(
                              value: 'toggle',
                              child: Text(
                                student.suspended
                                    ? 'เปิดใช้งานบัญชี'
                                    : 'ระงับบัญชีชั่วคราว',
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
}

class _StudentTableHeader extends StatelessWidget {
  const _StudentTableHeader({
    required this.text,
    this.align = TextAlign.center,
  });

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}

class _StudentTableCell extends StatelessWidget {
  const _StudentTableCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Center(child: child),
    );
  }
}

class _StudentTableNameCell extends StatelessWidget {
  const _StudentTableNameCell({required this.student, required this.onTap});

  final _StudentRecord student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFF1F5F9),
              child: Icon(
                Icons.person_rounded,
                size: 19,
                color: SchoolAdminPalette.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    student.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    student.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
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

class _MobileStudentCard extends StatelessWidget {
  const _MobileStudentCard({
    required this.student,
    required this.busy,
    required this.onView,
    required this.onEdit,
    required this.onToggle,
  });

  final _StudentRecord student;
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(
                  Icons.person_rounded,
                  color: SchoolAdminPalette.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.classLabel ?? _SchoolStudentsPageState.kUnplaced,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onView,
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: _AccountBadge(value: student.statusLabel),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('แก้ไขชื่อ'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onToggle,
                  icon: Icon(
                    student.suspended
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    size: 16,
                  ),
                  label: Text(student.suspended ? 'เปิดบัญชี' : 'ระงับ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountBadge extends StatelessWidget {
  const _AccountBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final bool active = value == _SchoolStudentsPageState.kActive;
    return Container(
      constraints: const BoxConstraints(minWidth: 84),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            active ? Icons.verified_rounded : Icons.block_rounded,
            size: 13,
            color: active ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 4.5),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCountCard extends StatelessWidget {
  const _LevelCountCard({required this.level, required this.value});

  final String level;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            level,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
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
                fontSize: 12.5,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? _SchoolStudentsPageState.kNoData : value,
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

class _SummaryItem {
  const _SummaryItem({
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

class _QuickActionData {
  const _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// null = ยังไม่มี backend รองรับ การ์ดจะถูก disable พร้อมบอกเหตุผลใน subtitle
  final VoidCallback? onTap;
  final bool isActive;
}
