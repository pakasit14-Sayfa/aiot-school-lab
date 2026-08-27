import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

class SchoolTeachersPage extends StatefulWidget {
  const SchoolTeachersPage({super.key});

  @override
  State<SchoolTeachersPage> createState() => _SchoolTeachersPageState();
}

class _SchoolTeachersPageState extends State<SchoolTeachersPage> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _divisions = [
    'ฝ่ายประชาสัมพันธ์',
    'ฝ่ายปกครอง',
    'ฝ่ายวิชาการ',
    'ฝ่ายทะเบียน',
    'ฝ่ายบริหารงานบุคคล',
    'ฝ่ายบริหารทั่วไป',
  ];

  static const List<String> _academicSubjects = [
    'วิทยาศาสตร์',
    'คณิตศาสตร์',
    'ภาษาอังกฤษ',
    'ภาษาไทย',
    'สังคมศึกษา',
    'สุขศึกษาและพลศึกษา',
    'ศิลปะ',
    'การงานอาชีพ',
    'เทคโนโลยี',
    'แนะแนว',
  ];

  String _divisionFromDepartment(String department) {
    if (_academicSubjects.contains(department)) {
      return 'ฝ่ายวิชาการ';
    }

    if (_divisions.contains(department)) {
      return department;
    }

    if (department == 'ภาษาต่างประเทศ') {
      return 'ฝ่ายวิชาการ';
    }

    if (department == 'สุขศึกษา') {
      return 'ฝ่ายวิชาการ';
    }

    return 'ฝ่ายบริหารทั่วไป';
  }

  String _subjectFromDepartment(String department) {
    if (department == 'ภาษาต่างประเทศ') {
      return 'ภาษาอังกฤษ';
    }

    if (department == 'สุขศึกษา') {
      return 'สุขศึกษาและพลศึกษา';
    }

    if (_academicSubjects.contains(department)) {
      return department;
    }

    return 'วิทยาศาสตร์';
  }

  int _countDivision(String division) {
    return _teachers
        .where(
          (_TeacherRecord teacher) =>
              _divisionFromDepartment(teacher.department) == division,
        )
        .length;
  }

  int _countSubject(String subject) {
    return _teachers
        .where(
          (_TeacherRecord teacher) =>
              _divisionFromDepartment(teacher.department) == 'ฝ่ายวิชาการ' &&
              _subjectFromDepartment(teacher.department) == subject,
        )
        .length;
  }

  String _selectedRole = 'ทุกบทบาท';
  String _selectedBuilding = 'ทุกอาคาร';
  String _selectedStatus = 'ทุกสถานะ';

  List<_TeacherRecord> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    try {
      final users = await UserAdminService.getAllUsers();
      final teacherUsers = users
          .where((u) => u.hasRole(UserRole.teacher))
          .toList();
      if (mounted) {
        setState(() {
          _teachers = teacherUsers.asMap().entries.map((entry) {
            final idx = entry.key;
            final u = entry.value;
            return _TeacherRecord(
              id: u.uid,
              teacherCode: 'TC-2569-${(idx + 1).toString().padLeft(3, '0')}',
              fullName: u.name,
              email: u.email,
              phone: '-',
              department: u.building.isNotEmpty ? u.building : 'วิทยาศาสตร์',
              mainRole: 'ครูผู้สอน',
              homeroom: u.room.isNotEmpty ? u.room : '-',
              building: u.building.isNotEmpty ? u.building : 'อาคารเรียน A',
              buildingDuty: '-',
              accountStatus: u.status == 'active' ? 'ใช้งาน' : 'ระงับ',
              permission: 'ครูผู้สอน',
              lastLogin: '-',
              note: 'ปกติ',
            );
          }).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_TeacherRecord> get _filteredTeachers {
    final String keyword = _searchController.text.trim().toLowerCase();

    return _teachers.where((_TeacherRecord teacher) {
      final bool matchesSearch =
          keyword.isEmpty ||
          teacher.fullName.toLowerCase().contains(keyword) ||
          teacher.teacherCode.toLowerCase().contains(keyword) ||
          teacher.email.toLowerCase().contains(keyword) ||
          teacher.phone.toLowerCase().contains(keyword) ||
          teacher.department.toLowerCase().contains(keyword);

      final bool matchesRole =
          _selectedRole == 'ทุกบทบาท' || teacher.permission == _selectedRole;

      final bool matchesBuilding =
          _selectedBuilding == 'ทุกอาคาร' ||
          teacher.building == _selectedBuilding ||
          teacher.buildingDuty == _selectedBuilding;

      final bool matchesStatus =
          _selectedStatus == 'ทุกสถานะ' ||
          teacher.accountStatus == _selectedStatus;

      return matchesSearch && matchesRole && matchesBuilding && matchesStatus;
    }).toList();
  }

  int get _activeCount =>
      _teachers.where((t) => t.accountStatus == 'ใช้งาน').length;

  int get _homeroomCount => _teachers.where((t) => t.homeroom != '-').length;

  int get _buildingTeacherCount =>
      _teachers.where((t) => t.buildingDuty != '-').length;

  int get _attentionCount => _teachers.where((t) {
    return t.accountStatus == 'รอตรวจสอบ' || t.accountStatus == 'ระงับ';
  }).length;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedRole = 'ทุกบทบาท';
      _selectedBuilding = 'ทุกอาคาร';
      _selectedStatus = 'ทุกสถานะ';
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openTeacherForm({
    _TeacherRecord? teacher,
    String? initialDivision,
    String? initialSubject,
  }) async {
    final bool editing = teacher != null;

    final TextEditingController codeController = TextEditingController(
      text: teacher?.teacherCode ?? '',
    );
    final TextEditingController nameController = TextEditingController(
      text: teacher?.fullName ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: teacher?.email ?? '',
    );
    final TextEditingController phoneController = TextEditingController(
      text: teacher?.phone ?? '',
    );
    final TextEditingController noteController = TextEditingController(
      text: teacher?.note ?? '',
    );

    String division = teacher != null
        ? _divisionFromDepartment(teacher.department)
        : (initialDivision ?? 'ฝ่ายวิชาการ');
    String academicSubject = teacher != null
        ? _subjectFromDepartment(teacher.department)
        : (initialSubject ?? 'วิทยาศาสตร์');
    String mainRole = teacher?.mainRole ?? 'ครูผู้สอน';
    String homeroom = teacher?.homeroom ?? '-';
    String building = teacher?.building ?? 'อาคารเรียน A';
    String buildingDuty = teacher?.buildingDuty ?? '-';
    String accountStatus = teacher?.accountStatus ?? 'ใช้งาน';
    String permission = teacher?.permission ?? 'ครูผู้สอน';

    final _TeacherRecord? result = await showDialog<_TeacherRecord>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.all(16),
              contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
              title: Text(editing ? 'แก้ไขข้อมูลครู' : 'เพิ่มครูและบุคลากร'),
              content: SizedBox(
                width: 820,
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
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
                                    labelText: 'รหัสครู / บุคลากร',
                                    hintText: 'เช่น TC-2569-011',
                                    prefixIcon: Icon(Icons.badge_rounded),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'ชื่อ–นามสกุล',
                                    prefixIcon: Icon(Icons.person_rounded),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: TextField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'อีเมล',
                                    prefixIcon: Icon(Icons.email_rounded),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: TextField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'เบอร์โทรศัพท์',
                                    prefixIcon: Icon(Icons.phone_rounded),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _TeacherDialogDropdown(
                                  label: 'ฝ่ายงาน',
                                  icon: Icons.account_tree_rounded,
                                  value: division,
                                  items: _divisions,
                                  onChanged: (String value) {
                                    setDialogState(() {
                                      division = value;
                                    });
                                  },
                                ),
                              ),
                              if (division == 'ฝ่ายวิชาการ')
                                SizedBox(
                                  width: fieldWidth,
                                  child: _TeacherDialogDropdown(
                                    label: 'กลุ่มสาระ / หมวดวิชา',
                                    icon: Icons.menu_book_rounded,
                                    value: academicSubject,
                                    items: _academicSubjects,
                                    onChanged: (String value) {
                                      setDialogState(() {
                                        academicSubject = value;
                                      });
                                    },
                                  ),
                                ),
                              SizedBox(
                                width: fieldWidth,
                                child: _TeacherDialogDropdown(
                                  label: 'ตำแหน่งหลัก',
                                  icon: Icons.work_outline_rounded,
                                  value: mainRole,
                                  items: const [
                                    'ครูผู้สอน',
                                    'หัวหน้ากลุ่มสาระ',
                                    'ครูแนะแนว',
                                    'หัวหน้าฝ่ายปกครอง',
                                    'เจ้าหน้าที่ประชาสัมพันธ์',
                                    'เจ้าหน้าที่ทะเบียน',
                                    'หัวหน้างานบุคคล',
                                    'เจ้าหน้าที่บริหารทั่วไป',
                                    'ฝ่ายบริหาร',
                                    'เจ้าหน้าที่',
                                  ],
                                  onChanged: (String value) {
                                    setDialogState(() => mainRole = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _TeacherDialogDropdown(
                                  label: 'ครูประจำชั้น',
                                  icon: Icons.co_present_rounded,
                                  value: homeroom,
                                  items: const [
                                    '-',
                                    'ม.1/1',
                                    'ม.1/2',
                                    'ม.2/1',
                                    'ม.2/2',
                                    'ม.3/1',
                                    'ม.3/2',
                                    'ม.4/1',
                                    'ม.4/2',
                                    'ม.5/1',
                                    'ม.5/2',
                                    'ม.6/1',
                                    'ม.6/2',
                                  ],
                                  onChanged: (String value) {
                                    setDialogState(() => homeroom = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _TeacherDialogDropdown(
                                  label: 'อาคารที่ทำงานหลัก',
                                  icon: Icons.apartment_rounded,
                                  value: building,
                                  items: const [
                                    'อาคารเรียน A',
                                    'อาคารเรียน B',
                                    'อาคารปฏิบัติการ',
                                    'อาคารอำนวยการ',
                                    'อาคารกีฬา',
                                    'โรงอาหาร',
                                  ],
                                  onChanged: (String value) {
                                    setDialogState(() => building = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _TeacherDialogDropdown(
                                  label: 'ครูประจำอาคาร',
                                  icon: Icons.engineering_rounded,
                                  value: buildingDuty,
                                  items: const [
                                    '-',
                                    'อาคารเรียน A',
                                    'อาคารเรียน B',
                                    'อาคารปฏิบัติการ',
                                    'อาคารอำนวยการ',
                                    'อาคารกีฬา',
                                    'โรงอาหาร',
                                  ],
                                  onChanged: (String value) {
                                    setDialogState(() => buildingDuty = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _TeacherDialogDropdown(
                                  label: 'สิทธิ์ในระบบ',
                                  icon: Icons.security_rounded,
                                  value: permission,
                                  items: const [
                                    'ครูผู้สอน',
                                    'ครูประจำชั้น',
                                    'ครูประจำอาคาร',
                                    'ฝ่ายบริหาร',
                                  ],
                                  onChanged: (String value) {
                                    setDialogState(() => permission = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _TeacherDialogDropdown(
                                  label: 'สถานะบัญชี',
                                  icon: Icons.verified_user_rounded,
                                  value: accountStatus,
                                  items: const ['ใช้งาน', 'รอตรวจสอบ', 'ระงับ'],
                                  onChanged: (String value) {
                                    setDialogState(() => accountStatus = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: oneColumn
                                    ? constraints.maxWidth
                                    : constraints.maxWidth,
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
                    final String email = emailController.text.trim();

                    if (code.isEmpty || name.isEmpty || email.isEmpty) {
                      _showMessage('กรุณากรอกรหัส ชื่อ และอีเมลให้ครบ');
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      _TeacherRecord(
                        id:
                            teacher?.id ??
                            'teacher-${DateTime.now().millisecondsSinceEpoch}',
                        teacherCode: code,
                        fullName: name,
                        email: email,
                        phone: phoneController.text.trim(),
                        department: division == 'ฝ่ายวิชาการ'
                            ? academicSubject
                            : division,
                        mainRole: mainRole,
                        homeroom: homeroom,
                        building: building,
                        buildingDuty: buildingDuty,
                        accountStatus: accountStatus,
                        permission: permission,
                        lastLogin: teacher?.lastLogin ?? 'ยังไม่เคยเข้าใช้',
                        note: noteController.text.trim().isEmpty
                            ? 'ปกติ'
                            : noteController.text.trim(),
                      ),
                    );
                  },
                  icon: Icon(
                    editing ? Icons.save_rounded : Icons.person_add_rounded,
                  ),
                  label: Text(editing ? 'บันทึกการแก้ไข' : 'เพิ่มบุคลากร'),
                ),
              ],
            );
          },
        );
      },
    );

    codeController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    noteController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      if (editing) {
        final int index = _teachers.indexWhere((t) => t.id == result.id);
        if (index >= 0) _teachers[index] = result;
      } else {
        _teachers.insert(0, result);
      }
    });

    _showMessage(
      editing
          ? 'บันทึกข้อมูลครูเรียบร้อยแล้ว'
          : 'เพิ่มครูและบุคลากรเรียบร้อยแล้ว',
    );
  }

  Future<void> _deleteTeacher(_TeacherRecord teacher) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ลบครูและบุคลากร'),
          content: Text('ต้องการลบ ${teacher.fullName} ออกจากระบบหรือไม่'),
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
      _teachers.removeWhere((t) => t.id == teacher.id);
    });

    _showMessage('ลบข้อมูลบุคลากรแล้ว');
  }

  void _toggleAccount(_TeacherRecord teacher) {
    final int index = _teachers.indexWhere((t) => t.id == teacher.id);
    if (index < 0) return;

    final String nextStatus = teacher.accountStatus == 'ระงับ'
        ? 'ใช้งาน'
        : 'ระงับ';

    setState(() {
      _teachers[index] = teacher.copyWith(accountStatus: nextStatus);
    });

    _showMessage(
      nextStatus == 'ระงับ'
          ? 'ระงับบัญชี ${teacher.fullName} แล้ว'
          : 'เปิดใช้งานบัญชี ${teacher.fullName} แล้ว',
    );
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  teacher.fullName,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    color: SchoolAdminPalette.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${teacher.teacherCode} • ${teacher.department}',
                                  style: const TextStyle(
                                    fontSize: 11,
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
                      _TeacherDetailRow(
                        icon: Icons.email_rounded,
                        label: 'อีเมล',
                        value: teacher.email,
                      ),
                      _TeacherDetailRow(
                        icon: Icons.phone_rounded,
                        label: 'เบอร์โทร',
                        value: teacher.phone,
                      ),
                      _TeacherDetailRow(
                        icon: Icons.account_tree_rounded,
                        label: 'ฝ่ายงาน',
                        value: _divisionFromDepartment(teacher.department),
                      ),
                      if (_divisionFromDepartment(teacher.department) ==
                          'ฝ่ายวิชาการ')
                        _TeacherDetailRow(
                          icon: Icons.menu_book_rounded,
                          label: 'กลุ่มสาระ',
                          value: _subjectFromDepartment(teacher.department),
                        ),
                      _TeacherDetailRow(
                        icon: Icons.work_outline_rounded,
                        label: 'ตำแหน่งหลัก',
                        value: teacher.mainRole,
                      ),
                      _TeacherDetailRow(
                        icon: Icons.co_present_rounded,
                        label: 'ครูประจำชั้น',
                        value: teacher.homeroom,
                      ),
                      _TeacherDetailRow(
                        icon: Icons.apartment_rounded,
                        label: 'อาคารหลัก',
                        value: teacher.building,
                      ),
                      _TeacherDetailRow(
                        icon: Icons.engineering_rounded,
                        label: 'ครูประจำอาคาร',
                        value: teacher.buildingDuty,
                      ),
                      _TeacherDetailRow(
                        icon: Icons.security_rounded,
                        label: 'สิทธิ์ในระบบ',
                        value: teacher.permission,
                      ),
                      _TeacherDetailRow(
                        icon: Icons.verified_user_rounded,
                        label: 'สถานะบัญชี',
                        value: teacher.accountStatus,
                      ),
                      _TeacherDetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'เข้าใช้ล่าสุด',
                        value: teacher.lastLogin,
                      ),
                      _TeacherDetailRow(
                        icon: Icons.notes_rounded,
                        label: 'หมายเหตุ',
                        value: teacher.note,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _showMessage(
                                  'ส่งคำขอตั้งรหัสผ่านใหม่ให้ ${teacher.fullName} แล้ว',
                                );
                              },
                              icon: const Icon(Icons.password_rounded),
                              label: const Text('ตั้งรหัสผ่านใหม่'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _openTeacherForm(teacher: teacher);
                              },
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('แก้ไขข้อมูล'),
                            ),
                          ),
                        ],
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

  void _showAssignmentDialog({
    required String title,
    required IconData icon,
    required String description,
  }) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: SchoolAdminPalette.primaryDark),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ปิด'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showMessage('$title: บันทึกตัวอย่างเรียบร้อย');
              },
              child: const Text('บันทึก'),
            ),
          ],
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
                  const SizedBox(height: 14),
                  _buildSummary(),
                  const SizedBox(height: 14),
                  _buildDivisionOverview(),
                  const SizedBox(height: 14),
                  _buildQuickActions(),
                  const SizedBox(height: 14),
                  _buildAssignments(),
                  const SizedBox(height: 14),
                  _buildFilters(),
                  const SizedBox(height: 14),
                  _buildTeacherList(teachers),
                  const SizedBox(height: 14),
                  _buildBottomOverview(),
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
                          'เพิ่มและแก้ไขบุคลากร กำหนดครูประจำชั้น ครูประจำอาคาร สิทธิ์การใช้งาน และตรวจสอบสถานะบัญชี',
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
                    onPressed: () {
                      _showMessage(
                        'ไปที่เมนู “นำเข้าข้อมูล” เพื่อเพิ่มรายชื่อบุคลากรจากไฟล์',
                      );
                    },
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('นำเข้ารายชื่อ'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openTeacherForm(),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('เพิ่มบุคลากร'),
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
    final List<_TeacherSummaryData> items = [
      _TeacherSummaryData(
        title: 'ครูและบุคลากรทั้งหมด',
        value: '${_teachers.length}',
        detail: 'รายชื่อในระบบโรงเรียน',
        icon: Icons.groups_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _TeacherSummaryData(
        title: 'บัญชีใช้งานปกติ',
        value: '$_activeCount',
        detail: 'พร้อมเข้าใช้งาน',
        icon: Icons.verified_rounded,
        color: SchoolAdminPalette.green,
      ),
      _TeacherSummaryData(
        title: 'ครูประจำชั้น',
        value: '$_homeroomCount',
        detail: 'ได้รับมอบหมายห้องแล้ว',
        icon: Icons.co_present_rounded,
        color: SchoolAdminPalette.secondary,
      ),
      _TeacherSummaryData(
        title: 'ควรตรวจสอบ',
        value: '$_attentionCount',
        detail: 'บัญชีรอตรวจสอบหรือถูกระงับ',
        icon: Icons.notifications_active_rounded,
        color: SchoolAdminPalette.red,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1050) columns = 2;
        if (constraints.maxWidth < 520) columns = 2;
        if (constraints.maxWidth < 300) columns = 1;

        const double spacing = 12;
        final double width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((_TeacherSummaryData item) {
            return SizedBox(
              width: width,
              child: _TeacherSummaryCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDivisionOverview() {
    final List<_DivisionViewData> items = [
      _DivisionViewData(
        title: 'ฝ่ายประชาสัมพันธ์',
        count: _countDivision('ฝ่ายประชาสัมพันธ์'),
        subtitle: 'ข่าวสาร เว็บไซต์ สื่อ และการประชาสัมพันธ์',
        icon: Icons.campaign_rounded,
        color: SchoolAdminPalette.secondary,
      ),
      _DivisionViewData(
        title: 'ฝ่ายปกครอง',
        count: _countDivision('ฝ่ายปกครอง'),
        subtitle: 'วินัย ความประพฤติ และการดูแลช่วยเหลือนักเรียน',
        icon: Icons.gavel_rounded,
        color: SchoolAdminPalette.red,
      ),
      _DivisionViewData(
        title: 'ฝ่ายวิชาการ',
        count: _countDivision('ฝ่ายวิชาการ'),
        subtitle: 'กดเข้าไปดูแยกตามกลุ่มสาระและหมวดวิชา',
        icon: Icons.school_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _DivisionViewData(
        title: 'ฝ่ายทะเบียน',
        count: _countDivision('ฝ่ายทะเบียน'),
        subtitle: 'ทะเบียนนักเรียน ผลการเรียน และเอกสารการศึกษา',
        icon: Icons.fact_check_rounded,
        color: SchoolAdminPalette.blue,
      ),
      _DivisionViewData(
        title: 'ฝ่ายบริหารงานบุคคล',
        count: _countDivision('ฝ่ายบริหารงานบุคคล'),
        subtitle: 'ข้อมูลบุคลากร การลา ภาระงาน และงานบุคคล',
        icon: Icons.badge_rounded,
        color: SchoolAdminPalette.green,
      ),
      _DivisionViewData(
        title: 'ฝ่ายบริหารทั่วไป',
        count: _countDivision('ฝ่ายบริหารทั่วไป'),
        subtitle: 'อาคารสถานที่ พัสดุ สารบรรณ และงานสนับสนุน',
        icon: Icons.business_center_rounded,
        color: SchoolAdminPalette.primary,
      ),
    ];

    return _TeacherSectionCard(
      title: 'บุคลากรแยกตามฝ่าย',
      subtitle:
          'เลือกฝ่ายที่ต้องการก่อน แล้วกดเข้าไปดูรายชื่อ รายละเอียด และแก้ไขบุคลากรในฝ่ายนั้น',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          int columns = 3;

          if (constraints.maxWidth < 900) {
            columns = 2;
          }

          if (constraints.maxWidth < 520) {
            columns = 1;
          }

          const double spacing = 10;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: items.map((_DivisionViewData item) {
              return SizedBox(
                width: width,
                child: _DivisionOverviewCard(
                  data: item,
                  onTap: () => _openDivisionBrowser(item.title),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _openDivisionBrowser(
    String division, {
    String? initialSubject,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.94,
          child: _TeacherDivisionBrowserSheet(
            division: division,
            allTeachers: _teachers,
            academicSubjects: _academicSubjects,
            initialSubject: initialSubject,
            divisionForTeacher: (_TeacherRecord teacher) {
              return _divisionFromDepartment(teacher.department);
            },
            subjectForTeacher: (_TeacherRecord teacher) {
              return _subjectFromDepartment(teacher.department);
            },
            onAdd: (String? selectedSubject) {
              Navigator.of(sheetContext).pop();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }

                _openTeacherForm(
                  initialDivision: division,
                  initialSubject: selectedSubject,
                );
              });
            },
            onView: (_TeacherRecord teacher) {
              Navigator.of(sheetContext).pop();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }

                _showTeacherDetail(teacher);
              });
            },
            onEdit: (_TeacherRecord teacher) {
              Navigator.of(sheetContext).pop();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }

                _openTeacherForm(teacher: teacher);
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final List<_TeacherQuickActionData> actions = [
      _TeacherQuickActionData(
        title: 'เพิ่มครู / บุคลากร',
        subtitle: 'สร้างบัญชีและข้อมูลบุคลากรใหม่',
        icon: Icons.person_add_alt_1_rounded,
        onTap: () => _openTeacherForm(),
      ),
      _TeacherQuickActionData(
        title: 'กำหนดครูประจำชั้น',
        subtitle: 'จับคู่ครูกับชั้นและห้องเรียน',
        icon: Icons.co_present_rounded,
        onTap: () {
          _showAssignmentDialog(
            title: 'กำหนดครูประจำชั้น',
            icon: Icons.co_present_rounded,
            description:
                'เลือกครูและห้องเรียนที่ต้องการมอบหมาย ระบบจะใช้ข้อมูลนี้สำหรับการแจ้งเตือนนักเรียนและงานประจำชั้น',
          );
        },
      ),
      _TeacherQuickActionData(
        title: 'กำหนดครูประจำอาคาร',
        subtitle: 'ระบุผู้รับผิดชอบแต่ละอาคาร',
        icon: Icons.apartment_rounded,
        onTap: () {
          _showAssignmentDialog(
            title: 'กำหนดครูประจำอาคาร',
            icon: Icons.apartment_rounded,
            description:
                'เลือกครูและอาคารที่รับผิดชอบ เพื่อรับการแจ้งเตือนอุปกรณ์ ไฟฟ้า น้ำ และเหตุผิดปกติของอาคาร',
          );
        },
      ),
      _TeacherQuickActionData(
        title: 'จัดการสิทธิ์',
        subtitle: 'กำหนดส่วนที่แต่ละบัญชีเข้าถึงได้',
        icon: Icons.admin_panel_settings_rounded,
        onTap: () {
          _showAssignmentDialog(
            title: 'จัดการสิทธิ์ผู้ใช้งาน',
            icon: Icons.admin_panel_settings_rounded,
            description:
                'กำหนดสิทธิ์ตามหน้าที่ เช่น ครูผู้สอน ครูประจำชั้น ครูประจำอาคาร หรือฝ่ายบริหาร',
          );
        },
      ),
    ];

    return _TeacherSectionCard(
      title: 'จัดการได้อย่างรวดเร็ว',
      subtitle: 'รวมงานที่แอดมินโรงเรียนใช้บ่อยไว้ในจุดเดียว',
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

  Widget _buildAssignments() {
    return _TeacherSectionCard(
      title: 'การมอบหมายหน้าที่',
      subtitle: 'ตรวจสอบครูประจำชั้น ครูประจำอาคาร และสิทธิ์ที่เกี่ยวข้อง',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final List<_AssignmentData> items = [
            _AssignmentData(
              title: 'ครูประจำชั้น',
              value: '$_homeroomCount คน',
              detail: 'กำหนดแล้ว 32 จาก 34 ห้อง',
              progress: 0.94,
              icon: Icons.co_present_rounded,
              color: SchoolAdminPalette.primaryDark,
            ),
            _AssignmentData(
              title: 'ครูประจำอาคาร',
              value: '$_buildingTeacherCount คน',
              detail: 'กำหนดผู้รับผิดชอบครบ 6 อาคาร',
              progress: 1,
              icon: Icons.apartment_rounded,
              color: SchoolAdminPalette.green,
            ),
            const _AssignmentData(
              title: 'สิทธิ์ในระบบ',
              value: '4 บทบาท',
              detail: 'ครูผู้สอน / ประจำชั้น / ประจำอาคาร / ฝ่ายบริหาร',
              progress: 0.92,
              icon: Icons.security_rounded,
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
            children: items.map((_AssignmentData item) {
              return SizedBox(
                width: width,
                child: _AssignmentCard(data: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return _TeacherSectionCard(
      title: 'ค้นหาและกรองรายชื่อ',
      subtitle: 'ค้นหาได้จากชื่อ รหัส อีเมล เบอร์โทร หรือกลุ่มสาระ',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget search = TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อ รหัส อีเมล เบอร์โทร หรือกลุ่มสาระ',
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
            value: _selectedRole,
            items: const [
              'ทุกบทบาท',
              'ครูผู้สอน',
              'ครูประจำชั้น',
              'ครูประจำอาคาร',
              'ฝ่ายบริหาร',
            ],
            onChanged: (String value) {
              setState(() => _selectedRole = value);
            },
          );

          final Widget building = _TeacherFilterDropdown(
            label: 'อาคาร',
            value: _selectedBuilding,
            items: const [
              'ทุกอาคาร',
              'อาคารเรียน A',
              'อาคารเรียน B',
              'อาคารปฏิบัติการ',
              'อาคารอำนวยการ',
              'อาคารกีฬา',
              'โรงอาหาร',
            ],
            onChanged: (String value) {
              setState(() => _selectedBuilding = value);
            },
          );

          final Widget status = _TeacherFilterDropdown(
            label: 'สถานะบัญชี',
            value: _selectedStatus,
            items: const ['ทุกสถานะ', 'ใช้งาน', 'รอตรวจสอบ', 'ระงับ'],
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
                    Expanded(child: role),
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
              Expanded(child: role),
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

  Widget _buildTeacherList(List<_TeacherRecord> teachers) {
    return _TeacherSectionCard(
      title: 'รายชื่อครูและบุคลากร',
      subtitle: 'พบ ${teachers.length} รายการ',
      child: teachers.isEmpty
          ? const _TeacherEmptyState()
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth >= 1080) {
                  return _DesktopTeacherTable(
                    teachers: teachers,
                    onView: _showTeacherDetail,
                    onEdit: (teacher) => _openTeacherForm(teacher: teacher),
                    onToggleAccount: _toggleAccount,
                    onDelete: _deleteTeacher,
                    onResetPassword: (teacher) {
                      _showMessage(
                        'ส่งคำขอตั้งรหัสผ่านใหม่ให้ ${teacher.fullName} แล้ว',
                      );
                    },
                  );
                }

                return Column(
                  children: teachers.map((_TeacherRecord teacher) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MobileTeacherCard(
                        teacher: teacher,
                        onView: () => _showTeacherDetail(teacher),
                        onEdit: () => _openTeacherForm(teacher: teacher),
                        onToggle: () => _toggleAccount(teacher),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  Widget _buildBottomOverview() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget departments = _TeacherSectionCard(
          title: 'กลุ่มสาระในฝ่ายวิชาการ',
          subtitle: 'กดกลุ่มสาระเพื่อเปิดรายชื่อครูในหมวดนั้นโดยตรง',
          child: LayoutBuilder(
            builder:
                (BuildContext context, BoxConstraints departmentConstraints) {
                  int columns = 3;

                  if (departmentConstraints.maxWidth < 620) {
                    columns = 2;
                  }

                  if (departmentConstraints.maxWidth < 270) {
                    columns = 1;
                  }

                  const double spacing = 8;
                  final double cardWidth =
                      (departmentConstraints.maxWidth -
                          ((columns - 1) * spacing)) /
                      columns;

                  final List<_DepartmentData> departments = _academicSubjects
                      .map((String subject) {
                        return _DepartmentData(
                          label: subject,
                          value: '${_countSubject(subject)}',
                        );
                      })
                      .toList();

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: departments.map((_DepartmentData item) {
                      return SizedBox(
                        width: cardWidth,
                        child: _DepartmentChip(
                          label: item.label,
                          value: item.value,
                          onTap: () => _openDivisionBrowser(
                            'ฝ่ายวิชาการ',
                            initialSubject: item.label,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
          ),
        );

        final List<_TeacherRecord> attention = _teachers.where((t) {
          return t.accountStatus == 'รอตรวจสอบ' || t.accountStatus == 'ระงับ';
        }).toList();

        final Widget attentionCard = _TeacherSectionCard(
          title: 'รายการที่ควรตรวจสอบ',
          subtitle: 'บัญชีหรือข้อมูลที่แอดมินควรดำเนินการ',
          child: attention.isEmpty
              ? const Text(
                  'ไม่มีรายการที่ต้องตรวจสอบ',
                  style: TextStyle(
                    fontSize: 10,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                )
              : Column(
                  children: attention.map((_TeacherRecord teacher) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TeacherAttentionRow(
                        teacher: teacher,
                        onTap: () => _showTeacherDetail(teacher),
                      ),
                    );
                  }).toList(),
                ),
        );

        if (constraints.maxWidth < 900) {
          return Column(
            children: [departments, const SizedBox(height: 14), attentionCard],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: departments),
            const SizedBox(width: 14),
            Expanded(flex: 3, child: attentionCard),
          ],
        );
      },
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
                    Text(
                      data.value,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
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
                        fontSize: 10.5,
                        height: 1.4,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
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
                          Text(
                            data.value,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            data.title,
                            style: const TextStyle(
                              fontSize: 13.5,
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
        );
      },
    );
  }
}

class _TeacherQuickActionCard extends StatelessWidget {
  const _TeacherQuickActionCard({required this.data});

  final _TeacherQuickActionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: SchoolAdminPalette.border),
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
                        fontSize: 10.5,
                        height: 1.4,
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

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.data});

  final _AssignmentData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 136),
      padding: const EdgeInsets.all(14),
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
              _TeacherIconBox(
                icon: data.icon,
                color: data.color,
                compact: true,
              ),
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

class _TeacherDialogDropdown extends StatelessWidget {
  const _TeacherDialogDropdown({
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
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }
}

class _DesktopTeacherTable extends StatelessWidget {
  const _DesktopTeacherTable({
    required this.teachers,
    required this.onView,
    required this.onEdit,
    required this.onToggleAccount,
    required this.onDelete,
    required this.onResetPassword,
  });

  final List<_TeacherRecord> teachers;
  final ValueChanged<_TeacherRecord> onView;
  final ValueChanged<_TeacherRecord> onEdit;
  final ValueChanged<_TeacherRecord> onToggleAccount;
  final ValueChanged<_TeacherRecord> onDelete;
  final ValueChanged<_TeacherRecord> onResetPassword;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll<Color>(
          Color(0xFFF8FAFC),
        ),
        headingTextStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF475569),
        ),
        dataTextStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF0F172A),
        ),
        dataRowMinHeight: 76,
        dataRowMaxHeight: 88,
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('ครู / บุคลากร')),
          DataColumn(label: Text('กลุ่มสาระ')),
          DataColumn(label: Text('บทบาท')),
          DataColumn(label: Text('ประจำชั้น')),
          DataColumn(label: Text('ประจำอาคาร')),
          DataColumn(label: Text('สถานะ')),
          DataColumn(label: Text('เข้าใช้ล่าสุด')),
          DataColumn(label: Text('จัดการ')),
        ],
        rows: teachers.map((_TeacherRecord teacher) {
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 235,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFF1F5F9),
                        child: Icon(
                          Icons.badge_rounded,
                          size: 18,
                          color: SchoolAdminPalette.primary,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              teacher.teacherCode,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () => onView(teacher),
              ),
              DataCell(Text(teacher.department)),
              DataCell(_TeacherRoleBadge(value: teacher.permission)),
              DataCell(Text(teacher.homeroom)),
              DataCell(Text(teacher.buildingDuty)),
              DataCell(_TeacherAccountBadge(value: teacher.accountStatus)),
              DataCell(
                SizedBox(
                  width: 115,
                  child: Text(
                    teacher.lastLogin,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                PopupMenuButton<String>(
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
                        onView(teacher);
                        break;
                      case 'edit':
                        onEdit(teacher);
                        break;
                      case 'password':
                        onResetPassword(teacher);
                        break;
                      case 'toggle':
                        onToggleAccount(teacher);
                        break;
                      case 'delete':
                        onDelete(teacher);
                        break;
                    }
                  },
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
                            Text('แก้ไขข้อมูล'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'password',
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_reset_rounded,
                              size: 18,
                              color: Color(0xFF475569),
                            ),
                            SizedBox(width: 10),
                            Text('ตั้งรหัสผ่านใหม่'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              teacher.accountStatus == 'ระงับ'
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.block_rounded,
                              size: 18,
                              color: teacher.accountStatus == 'ระงับ'
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              teacher.accountStatus == 'ระงับ'
                                  ? 'เปิดใช้งานบัญชี'
                                  : 'ระงับบัญชีชั่วคราว',
                            ),
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
                              'ลบรายการ',
                              style: TextStyle(color: Color(0xFFEF4444)),
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
        }).toList(),
      ),
    );
  }
}

class _MobileTeacherCard extends StatelessWidget {
  const _MobileTeacherCard({
    required this.teacher,
    required this.onView,
    required this.onEdit,
    required this.onToggle,
  });

  final _TeacherRecord teacher;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 136),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${teacher.teacherCode} • ${teacher.department}',
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
              IconButton(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _TeacherRoleBadge(value: teacher.permission)),
              const SizedBox(width: 8),
              Expanded(
                child: _TeacherAccountBadge(value: teacher.accountStatus),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (teacher.homeroom != '-' || teacher.buildingDuty != '-')
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SchoolAdminPalette.border),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (teacher.homeroom != '-')
                    Text(
                      'ประจำชั้น ${teacher.homeroom}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                  if (teacher.buildingDuty != '-')
                    Text(
                      'ประจำ ${teacher.buildingDuty}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('แก้ไข'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    teacher.accountStatus == 'ระงับ'
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    size: 17,
                  ),
                  label: Text(
                    teacher.accountStatus == 'ระงับ' ? 'เปิดบัญชี' : 'ระงับ',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeacherRoleBadge extends StatelessWidget {
  const _TeacherRoleBadge({required this.value});

  final String value;

  Color get color {
    switch (value) {
      case 'ครูประจำชั้น':
        return SchoolAdminPalette.primaryDark;
      case 'ครูประจำอาคาร':
        return SchoolAdminPalette.green;
      case 'ฝ่ายบริหาร':
        return SchoolAdminPalette.secondary;
      default:
        return const Color(0xFF4F6078);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TeacherBadge(
      label: value,
      color: color,
      icon: Icons.security_rounded,
    );
  }
}

class _TeacherAccountBadge extends StatelessWidget {
  const _TeacherAccountBadge({required this.value});

  final String value;

  Color get color {
    switch (value) {
      case 'ใช้งาน':
        return SchoolAdminPalette.green;
      case 'รอตรวจสอบ':
        return SchoolAdminPalette.secondary;
      default:
        return SchoolAdminPalette.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TeacherBadge(
      label: value,
      color: color,
      icon: Icons.verified_user_rounded,
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
      constraints: const BoxConstraints(minWidth: 108, minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              value.isEmpty ? 'ไม่ได้ระบุ' : value,
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

class _DepartmentData {
  const _DepartmentData({required this.label, required this.value});

  final String label;
  final String value;
}

class _DepartmentChip extends StatelessWidget {
  const _DepartmentChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$value คน',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.primaryDark,
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

class _TeacherAttentionRow extends StatelessWidget {
  const _TeacherAttentionRow({required this.teacher, required this.onTap});

  final _TeacherRecord teacher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: SchoolAdminPalette.red,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.fullName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    Text(
                      '${teacher.permission} • ${teacher.accountStatus}',
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
        ),
      ),
    );
  }
}

class _TeacherEmptyState extends StatelessWidget {
  const _TeacherEmptyState();

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
                'ไม่พบรายชื่อครูและบุคลากร',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              Text(
                'ลองเปลี่ยนคำค้นหาหรือล้างตัวกรอง',
                style: TextStyle(
                  fontSize: 11.5,
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

class _DivisionViewData {
  const _DivisionViewData({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final int count;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _DivisionOverviewCard extends StatelessWidget {
  const _DivisionOverviewCard({required this.data, required this.onTap});

  final _DivisionViewData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: data.color.withAlpha(18),
                child: Icon(data.icon, size: 23, color: data.color),
              ),
              const SizedBox(width: 11),
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
                      '${data.count} คน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: data.color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.4,
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

class _TeacherDivisionBrowserSheet extends StatefulWidget {
  const _TeacherDivisionBrowserSheet({
    required this.division,
    required this.allTeachers,
    required this.academicSubjects,
    required this.initialSubject,
    required this.divisionForTeacher,
    required this.subjectForTeacher,
    required this.onAdd,
    required this.onView,
    required this.onEdit,
  });

  final String division;
  final List<_TeacherRecord> allTeachers;
  final List<String> academicSubjects;
  final String? initialSubject;
  final String Function(_TeacherRecord teacher) divisionForTeacher;
  final String Function(_TeacherRecord teacher) subjectForTeacher;
  final ValueChanged<String?> onAdd;
  final ValueChanged<_TeacherRecord> onView;
  final ValueChanged<_TeacherRecord> onEdit;

  @override
  State<_TeacherDivisionBrowserSheet> createState() =>
      _TeacherDivisionBrowserSheetState();
}

class _TeacherDivisionBrowserSheetState
    extends State<_TeacherDivisionBrowserSheet> {
  final TextEditingController _searchController = TextEditingController();

  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_TeacherRecord> get _divisionTeachers {
    return widget.allTeachers.where((_TeacherRecord teacher) {
      return widget.divisionForTeacher(teacher) == widget.division;
    }).toList();
  }

  List<_TeacherRecord> get _filteredTeachers {
    final String keyword = _searchController.text.trim().toLowerCase();

    final List<_TeacherRecord> items = _divisionTeachers.where((
      _TeacherRecord teacher,
    ) {
      final bool matchesSubject =
          widget.division != 'ฝ่ายวิชาการ' ||
          _selectedSubject == null ||
          widget.subjectForTeacher(teacher) == _selectedSubject;

      final bool matchesSearch =
          keyword.isEmpty ||
          teacher.fullName.toLowerCase().contains(keyword) ||
          teacher.teacherCode.toLowerCase().contains(keyword) ||
          teacher.email.toLowerCase().contains(keyword) ||
          teacher.phone.toLowerCase().contains(keyword) ||
          teacher.mainRole.toLowerCase().contains(keyword);

      return matchesSubject && matchesSearch;
    }).toList();

    items.sort(
      (_TeacherRecord a, _TeacherRecord b) => a.fullName.compareTo(b.fullName),
    );

    return items;
  }

  int _countSubject(String subject) {
    return _divisionTeachers.where((_TeacherRecord teacher) {
      return widget.subjectForTeacher(teacher) == subject;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final List<_TeacherRecord> teachers = _filteredTeachers;

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
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummary(),
                    if (widget.division == 'ฝ่ายวิชาการ') ...[
                      const SizedBox(height: 16),
                      _buildSubjectGroups(),
                    ],
                    const SizedBox(height: 16),
                    _buildSearch(),
                    const SizedBox(height: 16),
                    _buildTeacherList(teachers),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 720;

          final Widget title = Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: SchoolAdminPalette.primarySoft,
                child: Icon(
                  Icons.groups_rounded,
                  color: SchoolAdminPalette.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.division,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.division == 'ฝ่ายวิชาการ'
                          ? 'เลือกกลุ่มสาระ แล้วดูหรือแก้ไขข้อมูลครูในหมวดนั้น'
                          : 'ดูรายชื่อ รายละเอียด และแก้ไขบุคลากรในฝ่ายนี้',
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
            children: [
              FilledButton.icon(
                onPressed: () => widget.onAdd(_selectedSubject),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('เพิ่มบุคลากร'),
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
    final int active = _divisionTeachers
        .where((_TeacherRecord teacher) => teacher.accountStatus == 'ใช้งาน')
        .length;

    final int attention = _divisionTeachers
        .where(
          (_TeacherRecord teacher) =>
              teacher.accountStatus == 'รอตรวจสอบ' ||
              teacher.accountStatus == 'ระงับ',
        )
        .length;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int columns = 3;

        if (constraints.maxWidth < 640) {
          columns = 1;
        }

        const double spacing = 10;
        final double width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        final List<_DivisionMiniSummary> items = [
          _DivisionMiniSummary(
            title: 'บุคลากรทั้งหมด',
            value: '${_divisionTeachers.length}',
            icon: Icons.groups_rounded,
            color: SchoolAdminPalette.primaryDark,
          ),
          _DivisionMiniSummary(
            title: 'บัญชีใช้งาน',
            value: '$active',
            icon: Icons.verified_rounded,
            color: SchoolAdminPalette.green,
          ),
          _DivisionMiniSummary(
            title: 'ควรตรวจสอบ',
            value: '$attention',
            icon: Icons.warning_amber_rounded,
            color: SchoolAdminPalette.red,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((_DivisionMiniSummary item) {
            return SizedBox(
              width: width,
              child: _DivisionMiniSummaryCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSubjectGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'กลุ่มสาระ / หมวดวิชา',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: SchoolAdminPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'กดกลุ่มสาระเพื่อกรองรายชื่อครูในฝ่ายวิชาการ',
          style: TextStyle(
            fontSize: 11.5,
            color: SchoolAdminPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            int columns = 5;

            if (constraints.maxWidth < 950) {
              columns = 3;
            }

            if (constraints.maxWidth < 620) {
              columns = 2;
            }

            if (constraints.maxWidth < 330) {
              columns = 1;
            }

            const double spacing = 8;
            final double width =
                (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: width,
                  child: _SubjectFilterCard(
                    title: 'ทุกกลุ่มสาระ',
                    count: _divisionTeachers.length,
                    selected: _selectedSubject == null,
                    onTap: () {
                      setState(() {
                        _selectedSubject = null;
                      });
                    },
                  ),
                ),
                ...widget.academicSubjects.map((String subject) {
                  return SizedBox(
                    width: width,
                    child: _SubjectFilterCard(
                      title: subject,
                      count: _countSubject(subject),
                      selected: _selectedSubject == subject,
                      onTap: () {
                        setState(() {
                          _selectedSubject = subject;
                        });
                      },
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: 'ค้นหาบุคลากรในฝ่าย',
        hintText: 'ชื่อ รหัส อีเมล เบอร์โทร หรือตำแหน่ง',
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
  }

  Widget _buildTeacherList(List<_TeacherRecord> teachers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'รายชื่อบุคลากร',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
            ),
            Text(
              'พบ ${teachers.length} คน',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (teachers.isEmpty)
          _buildEmpty()
        else
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              int columns = 2;

              if (constraints.maxWidth < 820) {
                columns = 1;
              }

              const double spacing = 10;
              final double width =
                  (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: teachers.map((_TeacherRecord teacher) {
                  return SizedBox(
                    width: width,
                    child: _DivisionTeacherCard(
                      teacher: teacher,
                      division: widget.divisionForTeacher(teacher),
                      subject: widget.division == 'ฝ่ายวิชาการ'
                          ? widget.subjectForTeacher(teacher)
                          : null,
                      onView: () => widget.onView(teacher),
                      onEdit: () => widget.onEdit(teacher),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmpty() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
          child: Column(
            children: [
              const Icon(
                Icons.person_search_rounded,
                size: 44,
                color: SchoolAdminPalette.textMuted,
              ),
              const SizedBox(height: 10),
              const Text(
                'ยังไม่พบบุคลากรตามเงื่อนไข',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'เปลี่ยนคำค้นหา เลือกกลุ่มสาระอื่น หรือเพิ่มบุคลากรใหม่',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.45,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => widget.onAdd(_selectedSubject),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('เพิ่มบุคลากร'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DivisionMiniSummary {
  const _DivisionMiniSummary({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _DivisionMiniSummaryCard extends StatelessWidget {
  const _DivisionMiniSummaryCard({required this.data});

  final _DivisionMiniSummary data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
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
            backgroundColor: data.color.withAlpha(16),
            child: Icon(data.icon, size: 20, color: data.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: data.color,
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

class _SubjectFilterCard extends StatelessWidget {
  const _SubjectFilterCard({
    required this.title,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SchoolAdminPalette.primarySoft : Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? SchoolAdminPalette.primary
                  : SchoolAdminPalette.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: selected
                        ? SchoolAdminPalette.primaryDark
                        : SchoolAdminPalette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? SchoolAdminPalette.primaryDark
                      : SchoolAdminPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DivisionTeacherCard extends StatelessWidget {
  const _DivisionTeacherCard({
    required this.teacher,
    required this.division,
    required this.subject,
    required this.onView,
    required this.onEdit,
  });

  final _TeacherRecord teacher;
  final String division;
  final String? subject;
  final VoidCallback onView;
  final VoidCallback onEdit;

  Color get _statusColor {
    if (teacher.accountStatus == 'ใช้งาน') {
      return SchoolAdminPalette.green;
    }

    if (teacher.accountStatus == 'รอตรวจสอบ') {
      return SchoolAdminPalette.secondary;
    }

    return SchoolAdminPalette.red;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 23,
                    backgroundColor: SchoolAdminPalette.primarySoft,
                    child: Icon(
                      Icons.badge_rounded,
                      color: SchoolAdminPalette.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacher.fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${teacher.teacherCode} • ${teacher.mainRole}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            color: SchoolAdminPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withAlpha(14),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: _statusColor.withAlpha(45)),
                    ),
                    child: Text(
                      teacher.accountStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DivisionTeacherInfoRow(
                icon: Icons.account_tree_rounded,
                label: 'ฝ่าย',
                value: division,
              ),
              if (subject != null) ...[
                const SizedBox(height: 7),
                _DivisionTeacherInfoRow(
                  icon: Icons.menu_book_rounded,
                  label: 'กลุ่มสาระ',
                  value: subject!,
                ),
              ],
              const SizedBox(height: 7),
              _DivisionTeacherInfoRow(
                icon: Icons.email_rounded,
                label: 'อีเมล',
                value: teacher.email,
              ),
              const SizedBox(height: 7),
              _DivisionTeacherInfoRow(
                icon: Icons.phone_rounded,
                label: 'โทร',
                value: teacher.phone,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('ดูข้อมูล'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('แก้ไข'),
                    ),
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

class _DivisionTeacherInfoRow extends StatelessWidget {
  const _DivisionTeacherInfoRow({
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _AssignmentData {
  const _AssignmentData({
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

class _TeacherRecord {
  const _TeacherRecord({
    required this.id,
    required this.teacherCode,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.department,
    required this.mainRole,
    required this.homeroom,
    required this.building,
    required this.buildingDuty,
    required this.accountStatus,
    required this.permission,
    required this.lastLogin,
    required this.note,
  });

  final String id;
  final String teacherCode;
  final String fullName;
  final String email;
  final String phone;
  final String department;
  final String mainRole;
  final String homeroom;
  final String building;
  final String buildingDuty;
  final String accountStatus;
  final String permission;
  final String lastLogin;
  final String note;

  _TeacherRecord copyWith({String? accountStatus}) {
    return _TeacherRecord(
      id: id,
      teacherCode: teacherCode,
      fullName: fullName,
      email: email,
      phone: phone,
      department: department,
      mainRole: mainRole,
      homeroom: homeroom,
      building: building,
      buildingDuty: buildingDuty,
      accountStatus: accountStatus ?? this.accountStatus,
      permission: permission,
      lastLogin: lastLogin,
      note: note,
    );
  }
}
