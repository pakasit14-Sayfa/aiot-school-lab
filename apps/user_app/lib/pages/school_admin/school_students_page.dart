import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

class SchoolStudentsPage extends StatefulWidget {
  const SchoolStudentsPage({super.key});

  @override
  State<SchoolStudentsPage> createState() => _SchoolStudentsPageState();
}

class _SchoolStudentsPageState extends State<SchoolStudentsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedLevel = 'ทุกระดับชั้น';
  String _selectedRoom = 'ทุกห้อง';
  String _selectedStatus = 'ทุกสถานะ';

  List<_StudentRecord> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final users = await UserAdminService.getAllUsers();
      final studentUsers = users
          .where((u) => u.hasRole(UserRole.student))
          .toList();
      if (mounted) {
        setState(() {
          _students = studentUsers.asMap().entries.map((entry) {
            final idx = entry.key;
            final u = entry.value;
            return _StudentRecord(
              id: u.uid,
              studentCode: 'ST-${u.email.split('@').first.toUpperCase()}',
              fullName: u.name,
              level: u.building.isNotEmpty ? u.building : 'ม.1',
              room: u.room.isNotEmpty ? u.room : '1',
              number: idx + 1,
              email: u.email,
              guardianName: '-',
              guardianPhone: '-',
              attendance: 'มาเรียน',
              accountStatus: u.status == 'active' ? 'ใช้งาน' : 'ระงับ',
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

  List<_StudentRecord> get _filteredStudents {
    final String keyword = _searchController.text.trim().toLowerCase();

    return _students.where((_StudentRecord student) {
      final bool matchesSearch =
          keyword.isEmpty ||
          student.fullName.toLowerCase().contains(keyword) ||
          student.studentCode.toLowerCase().contains(keyword) ||
          student.email.toLowerCase().contains(keyword) ||
          student.guardianName.toLowerCase().contains(keyword) ||
          student.guardianPhone.toLowerCase().contains(keyword);

      final bool matchesLevel =
          _selectedLevel == 'ทุกระดับชั้น' || student.level == _selectedLevel;

      final bool matchesRoom =
          _selectedRoom == 'ทุกห้อง' || student.room == _selectedRoom;

      final bool matchesStatus =
          _selectedStatus == 'ทุกสถานะ' ||
          student.accountStatus == _selectedStatus;

      return matchesSearch && matchesLevel && matchesRoom && matchesStatus;
    }).toList();
  }

  int get _activeCount =>
      _students.where((s) => s.accountStatus == 'ใช้งาน').length;

  int get _pendingCount =>
      _students.where((s) => s.accountStatus == 'รอตรวจสอบ').length;

  int get _attentionCount => _students.where((s) {
    return s.attendance == 'ขาดเรียน' ||
        s.attendance == 'มาสาย' ||
        s.accountStatus == 'รอตรวจสอบ' ||
        s.accountStatus == 'ระงับ';
  }).length;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedLevel = 'ทุกระดับชั้น';
      _selectedRoom = 'ทุกห้อง';
      _selectedStatus = 'ทุกสถานะ';
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openStudentForm({_StudentRecord? student}) async {
    final bool editing = student != null;

    final TextEditingController codeController = TextEditingController(
      text: student?.studentCode ?? '',
    );
    final TextEditingController nameController = TextEditingController(
      text: student?.fullName ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: student?.email ?? '',
    );
    final TextEditingController guardianController = TextEditingController(
      text: student?.guardianName ?? '',
    );
    final TextEditingController phoneController = TextEditingController(
      text: student?.guardianPhone ?? '',
    );
    final TextEditingController numberController = TextEditingController(
      text: student?.number.toString() ?? '',
    );

    String level = student?.level ?? 'ม.1';
    String room = student?.room ?? '1';
    String attendance = student?.attendance ?? 'มาเรียน';
    String accountStatus = student?.accountStatus ?? 'ใช้งาน';

    final _StudentRecord? result = await showDialog<_StudentRecord>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.all(16),
              contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
              title: Text(
                editing ? 'แก้ไขข้อมูลนักเรียน' : 'เพิ่มนักเรียนใหม่',
              ),
              content: SizedBox(
                width: 760,
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
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
                                    labelText: 'รหัสนักเรียน',
                                    hintText: 'เช่น ST-2569-0013',
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
                                  controller: numberController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'เลขที่',
                                    prefixIcon: Icon(
                                      Icons.format_list_numbered_rounded,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: TextField(
                                  controller: guardianController,
                                  decoration: const InputDecoration(
                                    labelText: 'ชื่อผู้ปกครอง',
                                    prefixIcon: Icon(
                                      Icons.supervisor_account_rounded,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: TextField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'เบอร์ผู้ปกครอง',
                                    prefixIcon: Icon(Icons.phone_rounded),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _DialogDropdown(
                                  label: 'ระดับชั้น',
                                  icon: Icons.layers_rounded,
                                  value: level,
                                  items: const [
                                    'ม.1',
                                    'ม.2',
                                    'ม.3',
                                    'ม.4',
                                    'ม.5',
                                    'ม.6',
                                  ],
                                  onChanged: (String value) {
                                    setDialogState(() => level = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _DialogDropdown(
                                  label: 'ห้อง',
                                  icon: Icons.meeting_room_rounded,
                                  value: room,
                                  items: const ['1', '2', '3', '4', '5', '6'],
                                  onChanged: (String value) {
                                    setDialogState(() => room = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _DialogDropdown(
                                  label: 'การมาเรียนวันนี้',
                                  icon: Icons.fact_check_rounded,
                                  value: attendance,
                                  items: const [
                                    'มาเรียน',
                                    'ลา',
                                    'ลาป่วย',
                                    'มาสาย',
                                    'ขาดเรียน',
                                  ],
                                  onChanged: (String value) {
                                    setDialogState(() => attendance = value);
                                  },
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: _DialogDropdown(
                                  label: 'สถานะบัญชี',
                                  icon: Icons.verified_user_rounded,
                                  value: accountStatus,
                                  items: const ['ใช้งาน', 'รอตรวจสอบ', 'ระงับ'],
                                  onChanged: (String value) {
                                    setDialogState(() => accountStatus = value);
                                  },
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
                    final int number =
                        int.tryParse(numberController.text.trim()) ?? 0;

                    if (code.isEmpty ||
                        name.isEmpty ||
                        email.isEmpty ||
                        number <= 0) {
                      _showMessage('กรุณากรอกรหัส ชื่อ อีเมล และเลขที่ให้ครบ');
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      _StudentRecord(
                        id:
                            student?.id ??
                            'student-${DateTime.now().millisecondsSinceEpoch}',
                        studentCode: code,
                        fullName: name,
                        level: level,
                        room: room,
                        number: number,
                        email: email,
                        guardianName: guardianController.text.trim(),
                        guardianPhone: phoneController.text.trim(),
                        attendance: attendance,
                        accountStatus: accountStatus,
                        lastLogin: student?.lastLogin ?? 'ยังไม่เคยเข้าใช้',
                        note: student?.note ?? 'ปกติ',
                      ),
                    );
                  },
                  icon: Icon(
                    editing ? Icons.save_rounded : Icons.person_add_rounded,
                  ),
                  label: Text(editing ? 'บันทึกการแก้ไข' : 'เพิ่มนักเรียน'),
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
    guardianController.dispose();
    phoneController.dispose();
    numberController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      if (editing) {
        final int index = _students.indexWhere((s) => s.id == result.id);
        if (index >= 0) _students[index] = result;
      } else {
        _students.insert(0, result);
      }
    });

    _showMessage(
      editing
          ? 'บันทึกข้อมูลนักเรียนเรียบร้อยแล้ว'
          : 'เพิ่มนักเรียนเรียบร้อยแล้ว',
    );
  }

  Future<void> _deleteStudent(_StudentRecord student) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ลบนักเรียน'),
          content: Text('ต้องการลบ ${student.fullName} ออกจากรายการหรือไม่'),
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
      _students.removeWhere((s) => s.id == student.id);
    });

    _showMessage('ลบนักเรียนออกจากรายการแล้ว');
  }

  void _toggleAccount(_StudentRecord student) {
    final int index = _students.indexWhere((s) => s.id == student.id);
    if (index < 0) return;

    final String nextStatus = student.accountStatus == 'ระงับ'
        ? 'ใช้งาน'
        : 'ระงับ';

    setState(() {
      _students[index] = student.copyWith(accountStatus: nextStatus);
    });

    _showMessage(
      nextStatus == 'ระงับ'
          ? 'ระงับบัญชี ${student.fullName} แล้ว'
          : 'เปิดใช้งานบัญชี ${student.fullName} แล้ว',
    );
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
                                  '${student.studentCode} • ${student.level}/${student.room} • เลขที่ ${student.number}',
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
                        icon: Icons.supervisor_account_rounded,
                        label: 'ผู้ปกครอง',
                        value: student.guardianName,
                      ),
                      _DetailRow(
                        icon: Icons.phone_rounded,
                        label: 'เบอร์ติดต่อ',
                        value: student.guardianPhone,
                      ),
                      _DetailRow(
                        icon: Icons.fact_check_rounded,
                        label: 'การมาเรียนวันนี้',
                        value: student.attendance,
                      ),
                      _DetailRow(
                        icon: Icons.verified_user_rounded,
                        label: 'สถานะบัญชี',
                        value: student.accountStatus,
                      ),
                      _DetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'เข้าใช้ล่าสุด',
                        value: student.lastLogin,
                      ),
                      _DetailRow(
                        icon: Icons.notes_rounded,
                        label: 'หมายเหตุ',
                        value: student.note,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _openStudentForm(student: student);
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('แก้ไขข้อมูล'),
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
                  const SizedBox(height: 14),
                  _buildSummary(),
                  const SizedBox(height: 14),
                  _buildQuickActions(),
                  const SizedBox(height: 14),
                  _buildFilters(),
                  const SizedBox(height: 14),
                  _buildStudentList(students),
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
                          'ดูรายชื่อ เพิ่มข้อมูล แก้ไขห้องเรียน ติดต่อผู้ปกครอง และตรวจสอบบัญชีนักเรียน',
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
                    onPressed: () {
                      _showMessage(
                        'ไปที่เมนู “นำเข้าข้อมูล” เพื่อเพิ่มรายชื่อจากไฟล์',
                      );
                    },
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('นำเข้ารายชื่อ'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openStudentForm(),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('เพิ่มนักเรียน'),
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
    final List<_SummaryItem> items = [
      _SummaryItem(
        title: 'นักเรียนทั้งหมด',
        value: '${_students.length}',
        detail: 'รายชื่อในโรงเรียน',
        icon: Icons.groups_rounded,
        color: SchoolAdminPalette.primary,
      ),
      _SummaryItem(
        title: 'บัญชีใช้งานปกติ',
        value: '$_activeCount',
        detail: 'พร้อมเข้าใช้งาน',
        icon: Icons.verified_rounded,
        color: SchoolAdminPalette.green,
      ),
      _SummaryItem(
        title: 'รอตรวจสอบ',
        value: '$_pendingCount',
        detail: 'ควรตรวจข้อมูลให้ครบ',
        icon: Icons.hourglass_top_rounded,
        color: SchoolAdminPalette.secondary,
      ),
      _SummaryItem(
        title: 'ควรติดตาม',
        value: '$_attentionCount',
        detail: 'ขาด มาสาย หรือบัญชีมีปัญหา',
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
          children: items.map((_SummaryItem item) {
            return SizedBox(
              width: width,
              child: _SummaryCard(item: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return _SectionCard(
      title: 'จัดการได้อย่างรวดเร็ว',
      subtitle: 'รวมงานที่ใช้บ่อยไว้ในจุดเดียว',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final List<_QuickActionData> actions = [
            _QuickActionData(
              title: 'เพิ่มนักเรียน',
              subtitle: 'เพิ่มรายชื่อใหม่',
              icon: Icons.person_add_alt_1_rounded,
              onTap: () => _openStudentForm(),
            ),
            _QuickActionData(
              title: 'นำเข้ารายชื่อ',
              subtitle: 'เพิ่มหลายคนพร้อมกัน',
              icon: Icons.upload_file_rounded,
              onTap: () {
                _showMessage(
                  'ไปที่เมนู “นำเข้าข้อมูล” เพื่อเพิ่มรายชื่อจากไฟล์',
                );
              },
            ),
            _QuickActionData(
              title: 'ส่งออกรายชื่อ',
              subtitle: 'เตรียมข้อมูลเป็นไฟล์',
              icon: Icons.download_rounded,
              onTap: () {
                _showMessage('เตรียมส่งออกรายชื่อนักเรียนแล้ว');
              },
            ),
            _QuickActionData(
              title: 'ดูบัญชีที่มีปัญหา',
              subtitle: 'รอตรวจสอบหรือถูกระงับ',
              icon: Icons.manage_accounts_rounded,
              onTap: () {
                setState(() {
                  _selectedStatus = 'รอตรวจสอบ';
                });
              },
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
              return SizedBox(
                width: width,
                child: _QuickActionCard(data: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return _SectionCard(
      title: 'ค้นหาและกรองรายชื่อ',
      subtitle: 'เลือกเฉพาะข้อมูลที่ต้องการดู',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget search = TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อ รหัส อีเมล ผู้ปกครอง หรือเบอร์โทร',
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
            value: _selectedLevel,
            items: const [
              'ทุกระดับชั้น',
              'ม.1',
              'ม.2',
              'ม.3',
              'ม.4',
              'ม.5',
              'ม.6',
            ],
            onChanged: (String value) {
              setState(() => _selectedLevel = value);
            },
          );

          final Widget room = _FilterDropdown(
            label: 'ห้อง',
            value: _selectedRoom,
            items: const ['ทุกห้อง', '1', '2', '3', '4', '5', '6'],
            onChanged: (String value) {
              setState(() => _selectedRoom = value);
            },
          );

          final Widget status = _FilterDropdown(
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
                    Expanded(child: level),
                    const SizedBox(width: 10),
                    Expanded(child: room),
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
    return _SectionCard(
      title: 'รายชื่อนักเรียน',
      subtitle: 'พบ ${students.length} รายการ',
      child: students.isEmpty
          ? const _EmptyState()
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth >= 1050) {
                  return _DesktopStudentTable(
                    students: students,
                    onView: _showStudentDetail,
                    onEdit: (student) => _openStudentForm(student: student),
                    onToggleAccount: _toggleAccount,
                    onDelete: _deleteStudent,
                    onResetPassword: (student) {
                      _showMessage(
                        'ส่งคำขอตั้งรหัสผ่านใหม่ให้ ${student.fullName} แล้ว',
                      );
                    },
                  );
                }

                return Column(
                  children: students.map((_StudentRecord student) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MobileStudentCard(
                        student: student,
                        onView: () => _showStudentDetail(student),
                        onEdit: () => _openStudentForm(student: student),
                        onToggle: () => _toggleAccount(student),
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
        final Widget levels = _SectionCard(
          title: 'จำนวนนักเรียนแต่ละระดับชั้น',
          subtitle: 'ช่วยดูภาพรวมการกระจายของนักเรียน',
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints levelConstraints) {
              int columns = 3;

              if (levelConstraints.maxWidth < 520) {
                columns = 2;
              }

              if (levelConstraints.maxWidth < 260) {
                columns = 1;
              }

              const double spacing = 8;
              final double cardWidth =
                  (levelConstraints.maxWidth - ((columns - 1) * spacing)) /
                  columns;

              const List<String> levelOrder = [
                'ม.1',
                'ม.2',
                'ม.3',
                'ม.4',
                'ม.5',
                'ม.6',
              ];
              final Map<String, int> counts = {};
              for (final _StudentRecord s in _students) {
                counts[s.level] = (counts[s.level] ?? 0) + 1;
              }
              final List<String> orderedLevels = [
                ...levelOrder.where(counts.containsKey),
                ...counts.keys.where((l) => !levelOrder.contains(l)),
              ];
              final List<_LevelCountData> levels = orderedLevels
                  .map(
                    (l) => _LevelCountData(level: l, value: '${counts[l]} คน'),
                  )
                  .toList();

              if (levels.isEmpty) {
                return const Text(
                  'ยังไม่มีนักเรียนในระบบ',
                  style: TextStyle(
                    fontSize: 13,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                );
              }

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: levels.map((_LevelCountData item) {
                  return SizedBox(
                    width: cardWidth,
                    child: _LevelCountCard(
                      level: item.level,
                      value: item.value,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );

        final List<_StudentRecord> attention = _students
            .where((s) {
              return s.attendance == 'ขาดเรียน' ||
                  s.accountStatus == 'ระงับ' ||
                  s.accountStatus == 'รอตรวจสอบ';
            })
            .take(4)
            .toList();

        final Widget attentionCard = _SectionCard(
          title: 'รายการที่ควรตรวจสอบ',
          subtitle: 'รวมรายการสำคัญที่ควรจัดการก่อน',
          child: Column(
            children: attention.map((_StudentRecord student) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AttentionRow(
                  student: student,
                  onTap: () => _showStudentDetail(student),
                ),
              );
            }).toList(),
          ),
        );

        if (constraints.maxWidth < 900) {
          return Column(
            children: [levels, const SizedBox(height: 14), attentionCard],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: levels),
            const SizedBox(width: 14),
            Expanded(flex: 3, child: attentionCard),
          ],
        );
      },
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
              const SizedBox(height: 14),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: SchoolAdminPalette.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 19,
                backgroundColor: SchoolAdminPalette.primarySoft,
                child: Icon(
                  Icons.touch_app_rounded,
                  color: SchoolAdminPalette.primaryDark,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    Text(
                      data.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: SchoolAdminPalette.textMuted,
              ),
            ],
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

class _DialogDropdown extends StatelessWidget {
  const _DialogDropdown({
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

class _DesktopStudentTable extends StatelessWidget {
  const _DesktopStudentTable({
    required this.students,
    required this.onView,
    required this.onEdit,
    required this.onToggleAccount,
    required this.onDelete,
    required this.onResetPassword,
  });

  final List<_StudentRecord> students;
  final ValueChanged<_StudentRecord> onView;
  final ValueChanged<_StudentRecord> onEdit;
  final ValueChanged<_StudentRecord> onToggleAccount;
  final ValueChanged<_StudentRecord> onDelete;
  final ValueChanged<_StudentRecord> onResetPassword;

  @override
  Widget build(BuildContext context) {
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
          horizontalInside: BorderSide(color: SchoolAdminPalette.border),
        ),
        columnWidths: const {
          0: FlexColumnWidth(2.5),
          1: FlexColumnWidth(1.25),
          2: FlexColumnWidth(1.05),
          3: FlexColumnWidth(0.7),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.2),
          6: FlexColumnWidth(1.25),
          7: FlexColumnWidth(0.65),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          const TableRow(
            decoration: BoxDecoration(color: SchoolAdminPalette.primarySoft),
            children: [
              _StudentTableHeader(text: 'นักเรียน', align: TextAlign.left),
              _StudentTableHeader(text: 'รหัส'),
              _StudentTableHeader(text: 'ชั้น/ห้อง'),
              _StudentTableHeader(text: 'เลขที่'),
              _StudentTableHeader(text: 'การมาเรียน'),
              _StudentTableHeader(text: 'บัญชี'),
              _StudentTableHeader(text: 'เข้าใช้ล่าสุด'),
              _StudentTableHeader(text: 'จัดการ'),
            ],
          ),
          ...students.map((_StudentRecord student) {
            return TableRow(
              children: [
                _StudentTableNameCell(
                  student: student,
                  onTap: () => onView(student),
                ),
                _StudentTableCell(
                  child: Text(
                    student.studentCode,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                ),
                _StudentTableCell(
                  child: Text(
                    '${student.level}/${student.room}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                ),
                _StudentTableCell(
                  child: Text(
                    '${student.number}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                ),
                _StudentTableCell(
                  child: _AttendanceBadge(value: student.attendance),
                ),
                _StudentTableCell(
                  child: _AccountBadge(value: student.accountStatus),
                ),
                _StudentTableCell(
                  child: Text(
                    student.lastLogin,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                ),
                _StudentTableCell(
                  child: PopupMenuButton<String>(
                    tooltip: 'จัดการ',
                    onSelected: (String value) {
                      switch (value) {
                        case 'view':
                          onView(student);
                          break;
                        case 'edit':
                          onEdit(student);
                          break;
                        case 'password':
                          onResetPassword(student);
                          break;
                        case 'toggle':
                          onToggleAccount(student);
                          break;
                        case 'delete':
                          onDelete(student);
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
                          value: 'password',
                          child: Text('ตั้งรหัสผ่านใหม่'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            student.accountStatus == 'ระงับ'
                                ? 'เปิดใช้งานบัญชี'
                                : 'ระงับบัญชี',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('ลบรายการ'),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: SchoolAdminPalette.textPrimary,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 14),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: SchoolAdminPalette.primarySoft,
              child: Icon(
                Icons.person_rounded,
                size: 19,
                color: SchoolAdminPalette.primaryDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                student.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
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
    required this.onView,
    required this.onEdit,
    required this.onToggle,
  });

  final _StudentRecord student;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

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
                  Icons.person_rounded,
                  color: SchoolAdminPalette.primaryDark,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${student.studentCode} • ${student.level}/${student.room} • เลขที่ ${student.number}',
                      style: const TextStyle(
                        fontSize: 13,
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
              Expanded(child: _AttendanceBadge(value: student.attendance)),
              const SizedBox(width: 8),
              Expanded(child: _AccountBadge(value: student.accountStatus)),
            ],
          ),
          const SizedBox(height: 10),
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
                    student.accountStatus == 'ระงับ'
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    size: 17,
                  ),
                  label: Text(
                    student.accountStatus == 'ระงับ' ? 'เปิดบัญชี' : 'ระงับ',
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

class _AttendanceBadge extends StatelessWidget {
  const _AttendanceBadge({required this.value});

  final String value;

  Color get color {
    switch (value) {
      case 'มาเรียน':
        return SchoolAdminPalette.green;
      case 'มาสาย':
        return SchoolAdminPalette.yellow;
      case 'ลา':
      case 'ลาป่วย':
        return SchoolAdminPalette.secondary;
      default:
        return SchoolAdminPalette.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Badge(label: value, color: color, icon: Icons.fact_check_rounded);
  }
}

class _AccountBadge extends StatelessWidget {
  const _AccountBadge({required this.value});

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
    return _Badge(
      label: value,
      color: color,
      icon: Icons.verified_user_rounded,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
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

class _LevelCountData {
  const _LevelCountData({required this.level, required this.value});

  final String level;
  final String value;
}

class _LevelCountCard extends StatelessWidget {
  const _LevelCountCard({required this.level, required this.value});

  final String level;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            level,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.primaryDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.student, required this.onTap});

  final _StudentRecord student;
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
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    Text(
                      '${student.level}/${student.room} • ${student.attendance} • ${student.accountStatus}',
                      style: const TextStyle(
                        fontSize: 13,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
                'ไม่พบรายชื่อนักเรียน',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              Text(
                'ลองเปลี่ยนคำค้นหาหรือล้างตัวกรอง',
                style: TextStyle(
                  fontSize: 12.5,
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _StudentRecord {
  const _StudentRecord({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.level,
    required this.room,
    required this.number,
    required this.email,
    required this.guardianName,
    required this.guardianPhone,
    required this.attendance,
    required this.accountStatus,
    required this.lastLogin,
    required this.note,
  });

  final String id;
  final String studentCode;
  final String fullName;
  final String level;
  final String room;
  final int number;
  final String email;
  final String guardianName;
  final String guardianPhone;
  final String attendance;
  final String accountStatus;
  final String lastLogin;
  final String note;

  _StudentRecord copyWith({String? accountStatus}) {
    return _StudentRecord(
      id: id,
      studentCode: studentCode,
      fullName: fullName,
      level: level,
      room: room,
      number: number,
      email: email,
      guardianName: guardianName,
      guardianPhone: guardianPhone,
      attendance: attendance,
      accountStatus: accountStatus ?? this.accountStatus,
      lastLogin: lastLogin,
      note: note,
    );
  }
}
