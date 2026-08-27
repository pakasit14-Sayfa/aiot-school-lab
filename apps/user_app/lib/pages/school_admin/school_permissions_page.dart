import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

class SchoolPermissionsPage extends StatefulWidget {
  const SchoolPermissionsPage({super.key});

  @override
  State<SchoolPermissionsPage> createState() => _SchoolPermissionsPageState();
}

class _SchoolPermissionsPageState extends State<SchoolPermissionsPage> {
  final TextEditingController _searchController = TextEditingController();

  int _selectedTab = 0;
  String _selectedRole = 'ทุกบทบาท';
  String _selectedStatus = 'ทุกสถานะ';

  List<_PermissionUser> _users = [];
  List<_PermissionLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final users = await UserAdminService.getAllUsers();
      final logs = await SchoolAdminPlatformService().fetchAuditLogs(limit: 20);
      if (mounted) {
        setState(() {
          _users = users.map((u) {
            return _PermissionUser(
              id: u.uid,
              name: u.name,
              email: u.email,
              role: u.role.label,
              scope: u.building.isNotEmpty
                  ? u.building
                  : (u.room.isNotEmpty ? u.room : 'ทุกอาคาร'),
              status: u.status == 'active' ? 'ใช้งาน' : 'ระงับ',
              lastUpdated: 'วันนี้',
              updatedBy: 'ผู้ดูแลโรงเรียน',
            );
          }).toList();

          _logs = logs
              .map(
                (l) => _PermissionLog(
                  time:
                      '${l.createdAt.hour.toString().padLeft(2, '0')}:${l.createdAt.minute.toString().padLeft(2, '0')} น.',
                  action: l.action,
                  target: l.target,
                  detail: l.detail.isNotEmpty ? l.detail : l.target,
                  by: l.actorName,
                  colorType: 'update',
                ),
              )
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_PermissionUser> get _filteredUsers {
    final String keyword = _searchController.text.trim().toLowerCase();

    return _users.where((_PermissionUser user) {
      final bool matchesSearch =
          keyword.isEmpty ||
          user.name.toLowerCase().contains(keyword) ||
          user.email.toLowerCase().contains(keyword) ||
          user.scope.toLowerCase().contains(keyword);

      final bool matchesRole =
          _selectedRole == 'ทุกบทบาท' || user.role == _selectedRole;

      final bool matchesStatus =
          _selectedStatus == 'ทุกสถานะ' || user.status == _selectedStatus;

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  int get _activeCount =>
      _users.where((user) => user.status == 'ใช้งาน').length;

  int get _pendingCount =>
      _users.where((user) => user.status == 'รอตรวจสอบ').length;

  int get _suspendedCount =>
      _users.where((user) => user.status == 'ระงับ').length;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedRole = 'ทุกบทบาท';
      _selectedStatus = 'ทุกสถานะ';
    });
  }

  Future<void> _openPermissionDialog({_PermissionUser? user}) async {
    final bool editing = user != null;

    final TextEditingController emailController = TextEditingController(
      text: user?.email ?? '',
    );
    final TextEditingController nameController = TextEditingController(
      text: user?.name ?? '',
    );

    String role = user?.role ?? 'ครูผู้สอน';
    String scope = user?.scope ?? 'เฉพาะชั้นเรียนที่สอน';
    String status = user?.status ?? 'ใช้งาน';

    final _PermissionUser? result = await showDialog<_PermissionUser>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SchoolAdminPalette.primaryDark.withAlpha(
                                  20,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                editing
                                    ? Icons.manage_accounts_rounded
                                    : Icons.person_add_alt_1_rounded,
                                color: SchoolAdminPalette.primaryDark,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    editing
                                        ? 'แก้ไขสิทธิ์ผู้ใช้งาน'
                                        : 'เพิ่มสิทธิ์ผู้ใช้งาน',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: SchoolAdminPalette.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    editing
                                        ? 'ปรับปรุงบทบาท ขอบเขต หรือสถานะการเข้าถึงระบบ'
                                        : 'กำหนดบทบาทและขอบเขตการเข้าถึงข้อมูลของบุคลากร',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: SchoolAdminPalette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
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
                        const SizedBox(height: 22),

                        // Form Inputs
                        _buildDialogInputLabel('อีเมลผู้ใช้งาน'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: 'example@school.ac.th',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: SchoolAdminPalette.primaryDark,
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildDialogInputLabel('ชื่อผู้ใช้งาน'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'ชื่อ - นามสกุล',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: SchoolAdminPalette.primaryDark,
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Role Selector Chips
                        _buildDialogInputLabel('เลือกบทบาทในระบบ'),
                        const SizedBox(height: 8),
                        _buildRoleSelectorChips(
                          selectedRole: role,
                          onSelected: (String value) {
                            setDialogState(() {
                              role = value;
                              scope = _defaultScopeForRole(value);
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Scope & Status Selectors
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDialogInputLabel('ขอบเขตการเข้าถึง'),
                                  const SizedBox(height: 6),
                                  _PermissionDialogDropdown(
                                    icon: Icons.account_tree_outlined,
                                    value: scope,
                                    items: const [
                                      'เฉพาะชั้นเรียนที่สอน',
                                      'ม.1/1',
                                      'ม.1/2',
                                      'ม.2/1',
                                      'ม.2/2',
                                      'ม.3/1',
                                      'อาคารเรียน A',
                                      'อาคารเรียน B',
                                      'อาคารปฏิบัติการ',
                                      'ทุกอาคาร',
                                    ],
                                    onChanged: (String value) {
                                      setDialogState(() => scope = value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDialogInputLabel('สถานะบัญชี'),
                                  const SizedBox(height: 6),
                                  _PermissionDialogDropdown(
                                    icon: Icons.verified_user_outlined,
                                    value: status,
                                    items: const ['ใช้งาน', 'รอตรวจสอบ', 'ระงับ'],
                                    onChanged: (String value) {
                                      setDialogState(() => status = value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Real-time Preview Box
                        _PermissionPreviewBox(
                          role: role,
                          scope: scope,
                          status: status,
                        ),
                        const SizedBox(height: 24),

                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              child: const Text(
                                'ยกเลิก',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: SchoolAdminPalette.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: () {
                                final String email = emailController.text.trim();
                                final String name = nameController.text.trim();

                                if (email.isEmpty || name.isEmpty) {
                                  _showMessage('กรุณากรอกชื่อและอีเมลให้ครบ');
                                  return;
                                }

                                Navigator.of(dialogContext).pop(
                                  _PermissionUser(
                                    id:
                                        user?.id ??
                                        'permission-${DateTime.now().millisecondsSinceEpoch}',
                                    name: name,
                                    email: email,
                                    role: role,
                                    scope: scope,
                                    status: status,
                                    lastUpdated: 'เมื่อสักครู่',
                                    updatedBy: 'ผู้ดูแลโรงเรียน',
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: SchoolAdminPalette.primaryDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: Text(
                                editing ? 'บันทึกการแก้ไข' : 'เพิ่มสิทธิ์',
                                style: const TextStyle(fontWeight: FontWeight.w800),
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
      },
    );

    emailController.dispose();
    nameController.dispose();

    if (result == null || !mounted) return;

    try {
      if (editing) {
        final newRole = _parseRole(result.role);
        await UserAdminService.updateRole(uid: result.id, role: newRole);
      }

      await _loadPermissions();

      if (mounted) {
        _showMessage(
          editing
              ? 'บันทึกการแก้ไขสิทธิ์เรียบร้อยแล้ว'
              : 'เพิ่มสิทธิ์ผู้ใช้งานเรียบร้อยแล้ว',
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage('เกิดข้อผิดพลาดในการบันทึกสิทธิ์: $e');
      }
    }
  }

  UserRole _parseRole(String roleLabel) {
    switch (roleLabel) {
      case 'ฝ่ายบริหาร':
        return UserRole.executive;
      case 'ผู้ดูแลระบบ':
      case 'แอดมินโรงเรียน':
        return UserRole.schoolAdmin;
      case 'นักเรียน':
        return UserRole.student;
      case 'ผู้ปกครอง':
        return UserRole.parent;
      case 'ครูผู้สอน':
      case 'ครูประจำชั้น':
      case 'ครูประจำอาคาร':
      default:
        return UserRole.teacher;
    }
  }

  String _defaultScopeForRole(String role) {
    switch (role) {
      case 'ครูประจำชั้น':
        return 'ม.1/1';
      case 'ครูประจำอาคาร':
        return 'อาคารเรียน A';
      case 'ฝ่ายบริหาร':
        return 'ทุกอาคาร';
      default:
        return 'เฉพาะชั้นเรียนที่สอน';
    }
  }

  Widget _buildDialogInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: SchoolAdminPalette.textPrimary,
      ),
    );
  }

  Widget _buildRoleSelectorChips({
    required String selectedRole,
    required ValueChanged<String> onSelected,
  }) {
    final List<(String, IconData, Color)> roles = [
      ('ครูผู้สอน', Icons.menu_book_rounded, const Color(0xFF4F6078)),
      ('ครูประจำชั้น', Icons.school_rounded, SchoolAdminPalette.primaryDark),
      ('ครูประจำอาคาร', Icons.apartment_rounded, SchoolAdminPalette.green),
      ('ฝ่ายบริหาร', Icons.business_center_rounded, SchoolAdminPalette.secondary),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = (constraints.maxWidth - 24) / 4;
        final bool wrap = width < 120;

        return wrap
            ? Wrap(
                spacing: 8,
                runSpacing: 8,
                children: roles.map((role) {
                  final (title, icon, color) = role;
                  final bool isSelected = selectedRole == title;
                  return _roleChipItem(
                    title: title,
                    icon: icon,
                    color: color,
                    isSelected: isSelected,
                    onTap: () => onSelected(title),
                  );
                }).toList(),
              )
            : Row(
                children: roles.map((role) {
                  final (title, icon, color) = role;
                  final bool isSelected = selectedRole == title;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _roleChipItem(
                        title: title,
                        icon: icon,
                        color: color,
                        isSelected: isSelected,
                        onTap: () => onSelected(title),
                      ),
                    ),
                  );
                }).toList(),
              );
      },
    );
  }

  Widget _roleChipItem({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? color.withAlpha(20) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? color : SchoolAdminPalette.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? color : SchoolAdminPalette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(_PermissionUser user) async {
    final int index = _users.indexWhere((item) => item.id == user.id);
    if (index < 0) return;

    final String nextStatus = user.status == 'ระงับ' ? 'ใช้งาน' : 'ระงับ';

    try {
      if (nextStatus == 'ระงับ') {
        await UserAdminService.deleteUser(user.id);
      } else {
        await UserAdminService.reactivateUser(user.id);
      }

      if (!mounted) return;

      setState(() {
        _users[index] = user.copyWith(
          status: nextStatus,
          lastUpdated: 'เมื่อสักครู่',
          updatedBy: 'ผู้ดูแลโรงเรียน',
        );

        _logs.insert(
          0,
          _PermissionLog(
            time: 'เมื่อสักครู่',
            action: nextStatus == 'ระงับ' ? 'ระงับสิทธิ์' : 'เปิดใช้งาน',
            target: user.name,
            detail: nextStatus == 'ระงับ'
                ? 'ระงับบัญชีผู้ใช้งาน'
                : 'เปิดใช้งานบัญชีอีกครั้ง',
            by: 'ผู้ดูแลโรงเรียน',
            colorType: nextStatus == 'ระงับ' ? 'danger' : 'success',
          ),
        );
      });

      _showMessage(
        nextStatus == 'ระงับ'
            ? 'ระงับสิทธิ์ ${user.name} สำเร็จ'
            : 'เปิดใช้งานสิทธิ์ ${user.name} สำเร็จ',
      );
    } catch (e) {
      if (mounted) {
        _showMessage('เกิดข้อผิดพลาดในการปรับสถานะ: $e');
      }
    }
  }

  void _showUserDetail(_PermissionUser user) {
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
                              Icons.admin_panel_settings_rounded,
                              color: SchoolAdminPalette.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: SchoolAdminPalette.textPrimary,
                                  ),
                                ),
                                Text(
                                  user.email,
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
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PermissionDetailRow(
                        icon: Icons.badge_rounded,
                        label: 'บทบาท',
                        value: user.role,
                      ),
                      _PermissionDetailRow(
                        icon: Icons.account_tree_rounded,
                        label: 'ขอบเขต',
                        value: user.scope,
                      ),
                      _PermissionDetailRow(
                        icon: Icons.verified_user_rounded,
                        label: 'สถานะ',
                        value: user.status,
                      ),
                      _PermissionDetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'แก้ไขล่าสุด',
                        value: user.lastUpdated,
                      ),
                      _PermissionDetailRow(
                        icon: Icons.person_outline_rounded,
                        label: 'แก้ไขโดย',
                        value: user.updatedBy,
                      ),
                      const SizedBox(height: 14),
                      _RolePermissionList(role: user.role),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _toggleUserStatus(user);
                              },
                              icon: Icon(
                                user.status == 'ระงับ'
                                    ? Icons.lock_open_rounded
                                    : Icons.block_rounded,
                              ),
                              label: Text(
                                user.status == 'ระงับ'
                                    ? 'เปิดใช้งาน'
                                    : 'ระงับสิทธิ์',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _openPermissionDialog(user: user);
                              },
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('แก้ไขสิทธิ์'),
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

  @override
  Widget build(BuildContext context) {
    final List<_PermissionUser> users = _filteredUsers;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPermissions,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    _buildTabBar(),
                    const SizedBox(height: 14),
                    if (_selectedTab == 0) ...[
                      _buildFilters(),
                      const SizedBox(height: 14),
                      _buildUserList(users),
                      const SizedBox(height: 14),
                      _buildLogs(),
                    ] else if (_selectedTab == 1) ...[
                      _buildRoleOverview(),
                      const SizedBox(height: 14),
                      _buildPermissionMatrix(),
                      const SizedBox(height: 14),
                      _buildSafetyGuide(),
                    ] else if (_selectedTab == 2) ...[
                      _buildLogs(),
                      const SizedBox(height: 14),
                      _buildSafetyGuide(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final List<(String, IconData, int?)> tabs = [
      ('ผู้ใช้งานและสิทธิ์', Icons.badge_rounded, _users.length),
      ('ตารางสิทธิ์ตามบทบาท', Icons.table_chart_rounded, null),
      ('ประวัติการปรับสิทธิ์', Icons.history_rounded, _logs.length),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isNarrow = constraints.maxWidth < 650;
          if (isNarrow) {
            return Column(
              children: List.generate(tabs.length, (int index) {
                final (title, icon, count) = tabs[index];
                final bool isSelected = _selectedTab == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: _tabButton(
                    title: title,
                    icon: icon,
                    count: count,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedTab = index),
                  ),
                );
              }),
            );
          }

          return Row(
            children: List.generate(tabs.length, (int index) {
              final (title, icon, count) = tabs[index];
              final bool isSelected = _selectedTab == index;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _tabButton(
                    title: title,
                    icon: icon,
                    count: count,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedTab = index),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required IconData icon,
    required int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? SchoolAdminPalette.primaryDark : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : SchoolAdminPalette.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : SchoolAdminPalette.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withAlpha(50)
                        : SchoolAdminPalette.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : SchoolAdminPalette.primaryDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0E0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget title = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SchoolAdminPalette.primaryDark.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: SchoolAdminPalette.primaryDark,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'จัดการสิทธิ์และบทบาท (Roles & Permissions)',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'กำหนดบทบาท ขอบเขตชั้นเรียน/อาคาร และจัดการสถานะการเข้าถึงระบบของบุคลากร',
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
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _showMessage('ส่งออกรายการสิทธิ์ตัวอย่างแล้ว');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('ส่งออกรายการ', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              FilledButton.icon(
                onPressed: () => _openPermissionDialog(),
                style: FilledButton.styleFrom(
                  backgroundColor: SchoolAdminPalette.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('เพิ่มสิทธิ์', style: TextStyle(fontWeight: FontWeight.w800)),
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
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary() {
    final List<_PermissionSummaryData> items = [
      _PermissionSummaryData(
        title: 'ผู้มีสิทธิ์ทั้งหมด',
        value: '${_users.length}',
        detail: 'บัญชีที่ได้รับสิทธิ์ในระบบ',
        icon: Icons.people_alt_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _PermissionSummaryData(
        title: 'ใช้งานปกติ',
        value: '$_activeCount',
        detail: 'บัญชีพร้อมใช้งาน',
        icon: Icons.verified_rounded,
        color: SchoolAdminPalette.green,
      ),
      _PermissionSummaryData(
        title: 'รอตรวจสอบ',
        value: '$_pendingCount',
        detail: 'ควรยืนยันบทบาทหรือขอบเขต',
        icon: Icons.hourglass_top_rounded,
        color: SchoolAdminPalette.secondary,
      ),
      _PermissionSummaryData(
        title: 'ระงับสิทธิ์',
        value: '$_suspendedCount',
        detail: 'ไม่สามารถเข้าใช้งานชั่วคราว',
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
          children: items.map((_PermissionSummaryData item) {
            return SizedBox(
              width: width,
              child: _PermissionSummaryCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRoleOverview() {
    const List<_RoleData> roles = [
      _RoleData(
        title: 'ครูผู้สอน',
        subtitle: 'ดูข้อมูลชั้นเรียนและอุปกรณ์ที่เกี่ยวข้องกับวิชาที่สอน',
        icon: Icons.school_outlined,
        color: Color(0xFF4F6078),
        userCount: '2 คน',
      ),
      _RoleData(
        title: 'ครูประจำชั้น',
        subtitle: 'ดูนักเรียนในห้อง รับแจ้งเตือน และติดตามงานประจำชั้น',
        icon: Icons.co_present_rounded,
        color: SchoolAdminPalette.primaryDark,
        userCount: '2 คน',
      ),
      _RoleData(
        title: 'ครูประจำอาคาร',
        subtitle: 'ดูอุปกรณ์ ทรัพยากร และการแจ้งเตือนเฉพาะอาคาร',
        icon: Icons.apartment_rounded,
        color: SchoolAdminPalette.green,
        userCount: '1 คน',
      ),
      _RoleData(
        title: 'ฝ่ายบริหาร',
        subtitle: 'ดูภาพรวม รายงาน และข้อมูลทุกส่วนที่ได้รับอนุญาต',
        icon: Icons.business_center_rounded,
        color: SchoolAdminPalette.secondary,
        userCount: '1 คน',
      ),
    ];

    return _PermissionSectionCard(
      title: 'บทบาทในระบบ',
      subtitle:
          'ใช้บทบาทเป็นชุดสิทธิ์มาตรฐาน เพื่อกำหนดสิทธิ์ได้ง่ายและลดความผิดพลาด',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          int columns = 4;
          if (constraints.maxWidth < 1000) columns = 2;
          if (constraints.maxWidth < 560) columns = 1;

          const double spacing = 10;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: roles.map((_RoleData role) {
              return SizedBox(
                width: width,
                child: _RoleCard(data: role),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildPermissionMatrix() {
    const List<_MatrixRowData> rows = [
      _MatrixRowData(
        module: 'ข้อมูลนักเรียน',
        teacher: 'เฉพาะที่สอน',
        homeroom: 'เฉพาะห้องตนเอง',
        building: '-',
        management: 'ดูได้',
      ),
      _MatrixRowData(
        module: 'ครูและบุคลากร',
        teacher: '-',
        homeroom: '-',
        building: '-',
        management: 'ดูได้',
      ),
      _MatrixRowData(
        module: 'อาคารและห้อง',
        teacher: 'ดูได้',
        homeroom: 'ดูได้',
        building: 'เฉพาะอาคาร',
        management: 'ดูได้',
      ),
      _MatrixRowData(
        module: 'อุปกรณ์ / ชุดฝึก',
        teacher: 'เฉพาะที่ใช้',
        homeroom: 'เฉพาะห้อง',
        building: 'เฉพาะอาคาร',
        management: 'ดูได้',
      ),
      _MatrixRowData(
        module: 'ไฟ / น้ำ / อากาศ',
        teacher: '-',
        homeroom: 'ดูห้องตนเอง',
        building: 'เฉพาะอาคาร',
        management: 'ดูได้',
      ),
      _MatrixRowData(
        module: 'การแจ้งเตือน',
        teacher: 'เฉพาะของตน',
        homeroom: 'เฉพาะห้อง',
        building: 'เฉพาะอาคาร',
        management: 'ดูได้',
      ),
      _MatrixRowData(
        module: 'รายงาน',
        teacher: 'เฉพาะของตน',
        homeroom: 'เฉพาะห้อง',
        building: 'เฉพาะอาคาร',
        management: 'ดูได้',
      ),
    ];

    return _PermissionSectionCard(
      title: 'ตารางสิทธิ์ตามบทบาท',
      subtitle: 'ช่วยให้เห็นภาพว่าแต่ละบทบาทเข้าถึงส่วนใดได้บ้าง',
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth >= 850) {
            return Table(
              border: const TableBorder(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                horizontalInside: BorderSide(
                  color: Color(0xFFF1F5F9),
                  width: 1,
                ),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1.45),
                1: FlexColumnWidth(1.1),
                2: FlexColumnWidth(1.15),
                3: FlexColumnWidth(1.15),
                4: FlexColumnWidth(1.05),
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
                    _PermissionTableHeaderCell(text: 'ข้อมูล / ฟังก์ชัน'),
                    _PermissionTableHeaderCell(text: 'ครูผู้สอน'),
                    _PermissionTableHeaderCell(text: 'ครูประจำชั้น'),
                    _PermissionTableHeaderCell(text: 'ครูประจำอาคาร'),
                    _PermissionTableHeaderCell(text: 'ฝ่ายบริหาร'),
                  ],
                ),
                ...rows.map((_MatrixRowData row) {
                  return TableRow(
                    children: [
                      _PermissionTableModuleCell(text: row.module),
                      _PermissionTableValueCell(value: row.teacher),
                      _PermissionTableValueCell(value: row.homeroom),
                      _PermissionTableValueCell(value: row.building),
                      _PermissionTableValueCell(value: row.management),
                    ],
                  );
                }),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: rows.map((_MatrixRowData row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MatrixMobileCard(data: row),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return _PermissionSectionCard(
      title: 'ค้นหาและกรองผู้ใช้งาน',
      subtitle: 'ค้นหาจากชื่อ อีเมล หรือขอบเขตการเข้าถึง',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget search = TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อ อีเมล ห้อง หรืออาคาร',
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

          final Widget role = _PermissionFilterDropdown(
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

          final Widget status = _PermissionFilterDropdown(
            label: 'สถานะ',
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

          if (constraints.maxWidth < 820) {
            return Column(
              children: [
                search,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: role),
                    const SizedBox(width: 10),
                    Expanded(child: status),
                  ],
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: clear),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 10),
              Expanded(child: role),
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

  Widget _buildUserList(List<_PermissionUser> users) {
    return _PermissionSectionCard(
      title: 'ผู้ใช้งานและสิทธิ์',
      subtitle: 'พบ ${users.length} รายการ',
      padding: EdgeInsets.zero,
      child: users.isEmpty
          ? const _PermissionEmptyState()
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth >= 980) {
                  return Table(
                    border: const TableBorder(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      horizontalInside: BorderSide(
                        color: Color(0xFFF1F5F9),
                        width: 1,
                      ),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2.4),
                      1: FlexColumnWidth(1.25),
                      2: FlexColumnWidth(1.65),
                      3: FlexColumnWidth(1.15),
                      4: FlexColumnWidth(1.45),
                      5: FlexColumnWidth(0.7),
                    },
                    defaultVerticalAlignment:
                        TableCellVerticalAlignment.middle,
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                          ),
                        ),
                        children: [
                          _PermissionUserTableHeader(
                            text: 'ผู้ใช้งาน',
                            align: TextAlign.left,
                          ),
                          _PermissionUserTableHeader(text: 'บทบาท'),
                          _PermissionUserTableHeader(text: 'ขอบเขต'),
                          _PermissionUserTableHeader(text: 'สถานะ'),
                          _PermissionUserTableHeader(text: 'แก้ไขล่าสุด'),
                          _PermissionUserTableHeader(text: 'จัดการ'),
                        ],
                      ),
                      ...users.map((_PermissionUser user) {
                        return TableRow(
                          children: [
                            _PermissionUserTableUserCell(
                              user: user,
                              onTap: () => _showUserDetail(user),
                            ),
                            _PermissionUserTableCell(
                              child: _RoleBadge(value: user.role),
                            ),
                            _PermissionUserTableCell(
                              child: Text(
                                user.scope,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            _PermissionUserTableCell(
                              child: _PermissionStatusBadge(
                                value: user.status,
                              ),
                            ),
                            _PermissionUserTableCell(
                              child: Text(
                                user.lastUpdated,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            _PermissionUserTableCell(
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
                                      _showUserDetail(user);
                                      break;
                                    case 'edit':
                                      _openPermissionDialog(user: user);
                                      break;
                                    case 'password':
                                      _showMessage(
                                        'ส่งคำขอตั้งรหัสผ่านใหม่ให้ ${user.name} แล้ว',
                                      );
                                      break;
                                    case 'toggle':
                                      _toggleUserStatus(user);
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
                                          Text('แก้ไขสิทธิ์'),
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
                                            user.status == 'ระงับ'
                                                ? Icons.check_circle_outline_rounded
                                                : Icons.block_rounded,
                                            size: 18,
                                            color: user.status == 'ระงับ'
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFD97706),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            user.status == 'ระงับ'
                                                ? 'เปิดใช้งาน'
                                                : 'ระงับสิทธิ์',
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
                    children: users.map((_PermissionUser user) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PermissionUserMobileCard(
                          user: user,
                          onView: () => _showUserDetail(user),
                          onEdit: () => _openPermissionDialog(user: user),
                          onToggle: () => _toggleUserStatus(user),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLogs() {
    return _PermissionSectionCard(
      title: 'Log การเปลี่ยนสิทธิ์ล่าสุด',
      subtitle: 'บันทึกว่าใครเปลี่ยนสิทธิ์ของใคร เมื่อไร และเปลี่ยนอะไร',
      child: _logs.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              alignment: Alignment.center,
              child: const Text(
                'ยังไม่มีประวัติการจัดการสิทธิ์',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            )
          : Column(
              children: _logs.take(6).map((_PermissionLog log) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _PermissionLogRow(log: log),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSafetyGuide() {
    return const _PermissionSectionCard(
      title: 'หลักการกำหนดสิทธิ์ที่แนะนำ',
      subtitle: 'ช่วยลดความเสี่ยงในการเข้าถึงข้อมูลเกินความจำเป็น',
      child: Column(
        children: [
          _PermissionGuideRow(
            number: '1',
            title: 'ให้สิทธิ์เท่าที่จำเป็น',
            detail:
                'ครูผู้สอนควรเห็นเฉพาะข้อมูลที่เกี่ยวข้องกับชั้นเรียนหรือวิชาที่รับผิดชอบ',
          ),
          SizedBox(height: 8),
          _PermissionGuideRow(
            number: '2',
            title: 'กำหนดขอบเขตให้ชัด',
            detail:
                'ครูประจำชั้นให้เข้าถึงเฉพาะห้องของตน และครูประจำอาคารให้เข้าถึงเฉพาะอาคารที่รับผิดชอบ',
          ),
          SizedBox(height: 8),
          _PermissionGuideRow(
            number: '3',
            title: 'ตรวจสอบเมื่อเปลี่ยนหน้าที่',
            detail:
                'เมื่อย้ายห้อง ย้ายอาคาร หรือเปลี่ยนตำแหน่ง ควรอัปเดตสิทธิ์ทันที',
          ),
          SizedBox(height: 8),
          _PermissionGuideRow(
            number: '4',
            title: 'ตรวจ Log เป็นระยะ',
            detail:
                'ระบบควรเก็บประวัติการเพิ่ม แก้ไข เปิด และระงับสิทธิ์เพื่อใช้ตรวจสอบย้อนหลัง',
          ),
        ],
      ),
    );
  }
}

class _PermissionSummaryCard extends StatelessWidget {
  const _PermissionSummaryCard({required this.data});

  final _PermissionSummaryData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 240;

        return Container(
          constraints: BoxConstraints(minHeight: compact ? 148 : 130),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: data.color.withAlpha(35),
              width: 1.2,
            ),
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
                color: data.color.withAlpha(12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: data.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(data.icon, color: data.color, size: 22),
                    ),
                    const Spacer(),
                    Text(
                      data.value,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: data.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(data.icon, color: data.color, size: 24),
                    ),
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
                          const SizedBox(height: 3),
                          Text(
                            data.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _PermissionSectionCard extends StatelessWidget {
  const _PermissionSectionCard({
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
      padding: padding ?? const EdgeInsets.all(20),
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
            color: Color(0x0E0F172A),
            blurRadius: 20,
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: SchoolAdminPalette.primaryDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
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
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: SchoolAdminPalette.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isFullWidth) const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.data});

  final _RoleData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: data.color.withAlpha(35), width: 1.2),
        boxShadow: [
          const BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          const BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: data.color.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: data.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: data.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  data.userCount,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: data.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionUserTableHeader extends StatelessWidget {
  const _PermissionUserTableHeader({
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
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
          color: SchoolAdminPalette.textPrimary,
        ),
      ),
    );
  }
}

class _PermissionUserTableCell extends StatelessWidget {
  const _PermissionUserTableCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Center(child: child),
    );
  }
}

class _PermissionUserTableUserCell extends StatelessWidget {
  const _PermissionUserTableUserCell({required this.user, required this.onTap});

  final _PermissionUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String initial =
        user.name.trim().isNotEmpty ? user.name.trim()[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: SchoolAdminPalette.primaryDark.withAlpha(22),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
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

class _PermissionUserMobileCard extends StatelessWidget {
  const _PermissionUserMobileCard({
    required this.user,
    required this.onView,
    required this.onEdit,
    required this.onToggle,
  });

  final _PermissionUser user;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final String initial =
        user.name.trim().isNotEmpty ? user.name.trim()[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: SchoolAdminPalette.primaryDark.withAlpha(22),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
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
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _RoleBadge(value: user.role)),
              const SizedBox(width: 8),
              Expanded(child: _PermissionStatusBadge(value: user.status)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_tree_rounded,
                  size: 17,
                  color: SchoolAdminPalette.primaryDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ขอบเขต: ${user.scope}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: SchoolAdminPalette.textPrimary,
                    ),
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
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('แก้ไข', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    user.status == 'ระงับ'
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    size: 16,
                  ),
                  label: Text(
                    user.status == 'ระงับ' ? 'เปิดใช้งาน' : 'ระงับ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
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

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.value});

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
    return _PermissionBadge(
      label: value,
      color: color,
      icon: Icons.security_rounded,
    );
  }
}

class _PermissionStatusBadge extends StatelessWidget {
  const _PermissionStatusBadge({required this.value});

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
    return _PermissionBadge(
      label: value,
      color: color,
      icon: Icons.verified_user_rounded,
    );
  }
}

class _PermissionBadge extends StatelessWidget {
  const _PermissionBadge({
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
      constraints: const BoxConstraints(minWidth: 92),
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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionTableHeaderCell extends StatelessWidget {
  const _PermissionTableHeaderCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: SchoolAdminPalette.textPrimary,
        ),
      ),
    );
  }
}

class _PermissionTableModuleCell extends StatelessWidget {
  const _PermissionTableModuleCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: SchoolAdminPalette.textPrimary,
        ),
      ),
    );
  }
}

class _PermissionTableValueCell extends StatelessWidget {
  const _PermissionTableValueCell({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      child: Center(child: _MatrixBadge(value: value, expanded: true)),
    );
  }
}

class _MatrixBadge extends StatelessWidget {
  const _MatrixBadge({required this.value, this.expanded = false});

  final String value;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final bool disabled = value == '-';
    final Color color = disabled
        ? SchoolAdminPalette.textMuted
        : value == 'ดูได้'
        ? SchoolAdminPalette.green
        : SchoolAdminPalette.primaryDark;

    final Widget badge = Container(
      width: expanded ? double.infinity : null,
      constraints: expanded
          ? const BoxConstraints(minHeight: 34)
          : const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(disabled ? 8 : 16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(disabled ? 20 : 38)),
      ),
      child: Text(
        disabled ? 'ไม่มีสิทธิ์' : value,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );

    return badge;
  }
}

class _MatrixMobileCard extends StatelessWidget {
  const _MatrixMobileCard({required this.data});

  final _MatrixRowData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.module,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 9),
          _MatrixMobileRow(label: 'ครูผู้สอน', value: data.teacher),
          _MatrixMobileRow(label: 'ครูประจำชั้น', value: data.homeroom),
          _MatrixMobileRow(label: 'ครูประจำอาคาร', value: data.building),
          _MatrixMobileRow(label: 'ฝ่ายบริหาร', value: data.management),
        ],
      ),
    );
  }
}

class _MatrixMobileRow extends StatelessWidget {
  const _MatrixMobileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ),
          _MatrixBadge(value: value),
        ],
      ),
    );
  }
}

class _PermissionFilterDropdown extends StatelessWidget {
  const _PermissionFilterDropdown({
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

class _PermissionDialogDropdown extends StatelessWidget {
  const _PermissionDialogDropdown({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: SchoolAdminPalette.textSecondary,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 18, color: SchoolAdminPalette.primaryDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                  ),
                ],
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

class _PermissionPreviewBox extends StatelessWidget {
  const _PermissionPreviewBox({
    required this.role,
    required this.scope,
    this.status = 'ใช้งาน',
  });

  final String role;
  final String scope;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: SchoolAdminPalette.primaryDark,
              ),
              SizedBox(width: 8),
              Text(
                'สรุปสิทธิ์ที่จะได้รับ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RoleBadge(value: role),
              _PermissionBadge(
                label: scope,
                color: SchoolAdminPalette.primaryDark,
                icon: Icons.account_tree_rounded,
              ),
              _PermissionStatusBadge(value: status),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'ระบบจะจำกัดการเข้าถึงข้อมูลตามบทบาทและขอบเขตที่กำหนดโดยอัตโนมัติ',
            style: TextStyle(
              fontSize: 11.5,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePermissionList extends StatelessWidget {
  const _RolePermissionList({required this.role});

  final String role;

  List<String> get permissions {
    switch (role) {
      case 'ครูประจำชั้น':
        return const [
          'ดูนักเรียนเฉพาะห้องที่รับผิดชอบ',
          'รับแจ้งเตือนนักเรียนในห้อง',
          'ดูรายงานเฉพาะห้องของตน',
          'ดูอุปกรณ์ที่ผูกกับห้อง',
        ];
      case 'ครูประจำอาคาร':
        return const [
          'ดูอาคารและห้องในพื้นที่รับผิดชอบ',
          'ดูอุปกรณ์และชุดฝึกในอาคาร',
          'ดูไฟ น้ำ และคุณภาพอากาศของอาคาร',
          'รับแจ้งเตือนเหตุผิดปกติของอาคาร',
        ];
      case 'ฝ่ายบริหาร':
        return const [
          'ดูภาพรวมโรงเรียน',
          'ดูรายงานทุกส่วนที่ได้รับอนุญาต',
          'ดูข้อมูลอาคารและทรัพยากร',
          'ดูการแจ้งเตือนและ Log',
        ];
      default:
        return const [
          'ดูชั้นเรียนที่รับผิดชอบ',
          'ดูอุปกรณ์ที่ใช้ในการสอน',
          'ดูรายงานที่เกี่ยวกับตนเอง',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สิทธิ์หลัก',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 9),
          ...permissions.map((String item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 17,
                    color: SchoolAdminPalette.green,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PermissionDetailRow extends StatelessWidget {
  const _PermissionDetailRow({
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
                fontSize: 12,
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
                fontSize: 12,
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

class _PermissionLogRow extends StatelessWidget {
  const _PermissionLogRow({required this.log});

  final _PermissionLog log;

  Color get color {
    switch (log.colorType) {
      case 'success':
        return SchoolAdminPalette.green;
      case 'danger':
        return SchoolAdminPalette.red;
      default:
        return SchoolAdminPalette.primaryDark;
    }
  }

  IconData get icon {
    switch (log.colorType) {
      case 'success':
        return Icons.check_circle_outline_rounded;
      case 'danger':
        return Icons.block_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool mobile = constraints.maxWidth < 760;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 14 : 18,
            vertical: mobile ? 14 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x040F172A),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: mobile ? _buildMobile() : _buildDesktop(),
        );
      },
    );
  }

  Widget _buildDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _PermissionIconBox(icon: icon, color: color),
        const SizedBox(width: 14),

        // ชื่อการดำเนินการ + ผู้ที่ถูกเปลี่ยนสิทธิ์
        Expanded(
          flex: 24,
          child: _LogColumn(
            label: 'การดำเนินการ',
            value: '${log.action} • ${log.target}',
            valueColor: SchoolAdminPalette.textPrimary,
            bold: true,
          ),
        ),
        const SizedBox(width: 18),

        // รายละเอียดกินพื้นที่มากที่สุด
        Expanded(
          flex: 34,
          child: _LogColumn(
            label: 'รายละเอียด',
            value: log.detail,
            valueColor: SchoolAdminPalette.textPrimary,
          ),
        ),
        const SizedBox(width: 18),

        // เวลา
        Expanded(
          flex: 18,
          child: _LogColumn(
            label: 'วันและเวลา',
            value: log.time,
            valueColor: color,
          ),
        ),
        const SizedBox(width: 18),

        // ผู้ดำเนินการ
        Expanded(
          flex: 18,
          child: _LogColumn(
            label: 'ดำเนินการโดย',
            value: log.by,
            valueColor: SchoolAdminPalette.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMobile() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PermissionIconBox(icon: icon, color: color),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${log.action} • ${log.target}',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                log.detail,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 10,
                runSpacing: 5,
                children: [
                  Text(
                    log.time,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    'โดย ${log.by}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: SchoolAdminPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogColumn extends StatelessWidget {
  const _LogColumn({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: SchoolAdminPalette.textMuted,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: bold ? 12.5 : 11.5,
            height: 1.45,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _PermissionGuideRow extends StatelessWidget {
  const _PermissionGuideRow({
    required this.number,
    required this.title,
    required this.detail,
  });

  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: SchoolAdminPalette.primarySoft,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: SchoolAdminPalette.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
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

class _PermissionIconBox extends StatelessWidget {
  const _PermissionIconBox({required this.icon, required this.color});

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
        border: Border.all(color: color.withAlpha(80), width: 1.1),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _PermissionEmptyState extends StatelessWidget {
  const _PermissionEmptyState();

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
                'ไม่พบผู้ใช้งาน',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              Text(
                'ลองเปลี่ยนคำค้นหาหรือล้างตัวกรอง',
                style: TextStyle(
                  fontSize: 12,
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

class _PermissionSummaryData {
  const _PermissionSummaryData({
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

class _RoleData {
  const _RoleData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.userCount,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String userCount;
}

class _MatrixRowData {
  const _MatrixRowData({
    required this.module,
    required this.teacher,
    required this.homeroom,
    required this.building,
    required this.management,
  });

  final String module;
  final String teacher;
  final String homeroom;
  final String building;
  final String management;
}

class _PermissionUser {
  const _PermissionUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.scope,
    required this.status,
    required this.lastUpdated,
    required this.updatedBy,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String scope;
  final String status;
  final String lastUpdated;
  final String updatedBy;

  _PermissionUser copyWith({
    String? status,
    String? lastUpdated,
    String? updatedBy,
  }) {
    return _PermissionUser(
      id: id,
      name: name,
      email: email,
      role: role,
      scope: scope,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

class _PermissionLog {
  const _PermissionLog({
    required this.time,
    required this.action,
    required this.target,
    required this.detail,
    required this.by,
    required this.colorType,
  });

  final String time;
  final String action;
  final String target;
  final String detail;
  final String by;
  final String colorType;
}
