import 'package:flutter/material.dart';
import 'package:shared_core/models/user_model.dart';
import 'package:shared_core/services/auth_service.dart';
import 'package:shared_core/services/user_admin_service.dart';
import 'invite_staff_page.dart';
import 'issue_binding_code_page.dart';
import 'parent_link_review_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<UserModel> users = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'ทุกบทบาท';
  String _selectedStatus = 'ทุกสถานะ';
  bool _filterSuspendedOnly = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final result = await UserAdminService.getAllUsers();
      if (mounted) {
        setState(() {
          users = result;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          users = [];
          isLoading = false;
        });
      }
    }
  }

  List<UserModel> get filteredUsers {
    final keyword = _searchController.text.trim().toLowerCase();
    return users.where((u) {
      final matchesSearch = keyword.isEmpty ||
          u.name.toLowerCase().contains(keyword) ||
          u.email.toLowerCase().contains(keyword) ||
          u.uid.toLowerCase().contains(keyword);

      final matchesRole = _selectedRole == 'ทุกบทบาท' || u.role.label == _selectedRole;

      final bool matchesStatus;
      if (_filterSuspendedOnly) {
        matchesStatus = u.isSuspended;
      } else {
        if (_selectedStatus == 'ใช้งาน') {
          matchesStatus = !u.isSuspended;
        } else if (_selectedStatus == 'ถูกระงับ') {
          matchesStatus = u.isSuspended;
        } else {
          matchesStatus = true;
        }
      }

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  int get _activeCount => users.where((u) => !u.isSuspended).length;
  int get _suspendedCount => users.where((u) => u.isSuspended).length;
  int get _adminStaffCount => users.where((u) => u.role == UserRole.schoolAdmin || u.role == UserRole.superAdmin).length;
  int get _teacherCount => users.where((u) => u.role == UserRole.teacher).length;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedRole = 'ทุกบทบาท';
      _selectedStatus = 'ทุกสถานะ';
      _filterSuspendedOnly = false;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);

    showDialog(
      context: context,
      builder: (dialogContext) {
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
                  color: const Color(0xFF9E401A).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_rounded, color: Color(0xFF9E401A), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'แก้ไขข้อมูลผู้ใช้',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'อัปเดตชื่อแสดงผลในระบบ',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.email,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อ-นามสกุล',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF64748B)),
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
                      borderSide: const BorderSide(color: Color(0xFF9E401A), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ยกเลิก'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  _showMessage('กรุณากรอกชื่อผู้ใช้', isError: true);
                  return;
                }

                await AuthService.updateProfile(uid: user.uid, name: newName);
                if (!mounted) return;
                Navigator.pop(dialogContext);
                await loadUsers();
                _showMessage('แก้ไขข้อมูลผู้ใช้เรียบร้อยแล้ว');
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('บันทึก'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9E401A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  void showChangeRoleDialog(UserModel user) {
    UserRole selectedRole = user.role;
    final allowedRoles = UserRole.values.where((r) =>
        currentUserModel?.role == UserRole.superAdmin ||
        r != UserRole.superAdmin).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                      color: const Color(0xFF0284C7).withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF0284C7), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'เปลี่ยนสิทธิ์และบทบาท',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      ...allowedRoles.map((role) {
                        final isSelected = selectedRole == role;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: RadioListTile<UserRole>(
                            title: Row(
                              children: [
                                Text(
                                  role.label,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                    color: isSelected ? const Color(0xFF15803D) : const Color(0xFF0F172A),
                                  ),
                                ),
                                const Spacer(),
                                _buildRoleChip(role),
                              ],
                            ),
                            value: role,
                            groupValue: selectedRole,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedRole = v);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await UserAdminService.updateRole(
                      uid: user.uid,
                      role: selectedRole,
                    );
                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                    await loadUsers();
                    _showMessage('ปรับสิทธิ์ผู้ใช้เป็น ${selectedRole.label} เรียบร้อยแล้ว');
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('ยืนยันการเปลี่ยนสิทธิ์'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.block_rounded, color: Color(0xFFDC2626), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยืนยันการระงับผู้ใช้',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'บัญชีจะไม่ถูกลบถาวร แต่จะไม่สามารถเข้าสู่ระบบได้',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Text(
            'ต้องการระงับการใช้งานของ ${user.name} (${user.email}) หรือไม่?',
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ยกเลิก'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await UserAdminService.deleteUser(user.uid);
                if (!mounted) return;
                Navigator.pop(dialogContext);
                await loadUsers();
                _showMessage('ระงับผู้ใช้เรียบร้อยแล้ว');
              },
              icon: const Icon(Icons.block_rounded, size: 18),
              label: const Text('ระงับบัญชี'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  void confirmReactivateUser(UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เปิดใช้งานผู้ใช้',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'คืนสิทธิ์การเข้าสู่ระบบตามปกติ',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Text(
            'ต้องการเปิดใช้งานบัญชีของ ${user.name} (${user.email}) อีกครั้งหรือไม่?',
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ยกเลิก'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await UserAdminService.reactivateUser(user.uid);
                if (!mounted) return;
                Navigator.pop(dialogContext);
                await loadUsers();
                _showMessage('เปิดใช้งานผู้ใช้เรียบร้อยแล้ว');
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('เปิดใช้งาน'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildRoleChip(UserRole role) {
    Color bg;
    Color fg;

    switch (role) {
      case UserRole.superAdmin:
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7E22CE);
        break;
      case UserRole.schoolAdmin:
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFC2410C);
        break;
      case UserRole.teacher:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        break;
      case UserRole.student:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case UserRole.parent:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case UserRole.executive:
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF334155);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget buildRoleBadge(UserRole role) => _buildRoleChip(role);

  Widget buildStatusBadge(UserModel user) {
    if (user.isSuspended) {
      return Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 12, color: Color(0xFFDC2626)),
            SizedBox(width: 4),
            Text(
              'ถูกระงับ',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
          SizedBox(width: 4),
          Text(
            'ใช้งาน',
            style: TextStyle(
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredUsers;

    if (currentUserModel?.role != null &&
        currentUserModel?.role != UserRole.schoolAdmin &&
        currentUserModel?.role != UserRole.superAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('ไม่มีสิทธิ์เข้าถึง'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 80, color: Color(0xFFDC2626)),
                const SizedBox(height: 18),
                const Text(
                  'คุณไม่มีสิทธิ์เข้าถึงหน้านี้',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'หน้านี้สำหรับแอดมินโรงเรียนและผู้ดูแลระบบเท่านั้น',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('กลับหน้าหลัก'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9E401A),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF9E401A)))
            : SingleChildScrollView(
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
                        _buildFilters(),
                        const SizedBox(height: 18),
                        _buildUserList(filtered),
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
                  Icons.people_alt_rounded,
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
                      'จัดการผู้ใช้ (User Management)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'บริหารจัดการบัญชีผู้ใช้งานระบบ สิทธิ์บทบาท และคำขอผูกบัญชีในสถานศึกษา',
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ParentLinkReviewPage()),
                  );
                },
                icon: const Icon(Icons.family_restroom_rounded, size: 18),
                label: const Text('คำขอผู้ปกครอง'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: const Color(0xFF334155),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IssueBindingCodePage()),
                  );
                },
                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                label: const Text('ออกรหัสผูกบัญชี'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: const Color(0xFF334155),
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InviteStaffPage()),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('เชิญผู้ใช้ใหม่'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9E401A),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              IconButton(
                onPressed: loadUsers,
                tooltip: 'รีเฟรช',
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 920) {
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
    final List<_SummaryItemData> items = [
      _SummaryItemData(
        title: 'ผู้ใช้งานทั้งหมด',
        value: '${users.length}',
        detail: 'รวมทุกบทบาทในสถานศึกษา',
        icon: Icons.group_rounded,
        color: const Color(0xFF0284C7),
      ),
      _SummaryItemData(
        title: 'เปิดใช้งานปกติ',
        value: '$_activeCount',
        detail: users.isEmpty ? 'ไม่มีผู้ใช้' : '${((_activeCount / (users.isEmpty ? 1 : users.length)) * 100).toStringAsFixed(0)}% ของระบบ',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
      ),
      _SummaryItemData(
        title: 'ถูกระงับการใช้งาน',
        value: '$_suspendedCount',
        detail: 'ปิดการเข้าถึงชั่วคราว',
        icon: Icons.block_rounded,
        color: const Color(0xFFDC2626),
      ),
      _SummaryItemData(
        title: 'ผู้ดูแลและบุคลากร',
        value: '${_adminStaffCount + _teacherCount}',
        detail: 'แอดมิน & ครูผู้สอน',
        icon: Icons.admin_panel_settings_rounded,
        color: const Color(0xFF9E401A),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1050) columns = 2;
        if (constraints.maxWidth < 520) columns = 1;

        const double spacing = 14;
        final double width = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: _SummaryCard(data: item),
            );
          }).toList(),
        );
      },
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
                    hintText: 'ค้นหาด้วยชื่อ, อีเมล หรือ UID ผู้ใช้...',
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
                      borderSide: const BorderSide(color: Color(0xFF9E401A), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                selected: _filterSuspendedOnly,
                onSelected: (val) {
                  setState(() => _filterSuspendedOnly = val);
                },
                avatar: Icon(
                  Icons.block_rounded,
                  size: 18,
                  color: _filterSuspendedOnly ? Colors.white : const Color(0xFFDC2626),
                ),
                label: const Text('⚠️ ดูเฉพาะบัญชีที่ถูกระงับ'),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _filterSuspendedOnly ? Colors.white : const Color(0xFF0F172A),
                ),
                backgroundColor: const Color(0xFFFEE2E2),
                selectedColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _filterSuspendedOnly ? const Color(0xFFDC2626) : const Color(0xFFFECACA),
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
                'บทบาท:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
              ),
              ...[
                'ทุกบทบาท',
                'ผู้ดูแลโรงเรียน',
                'ครูผู้สอน',
                'นักเรียน',
                'ผู้ปกครอง',
                'ผู้บริหาร',
              ].map((roleName) {
                final isSelected = _selectedRole == roleName;
                return ChoiceChip(
                  label: Text(roleName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRole = roleName);
                  },
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                  selectedColor: const Color(0xFF9E401A),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF9E401A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                );
              }),
              const SizedBox(width: 8),
              if (_selectedRole != 'ทุกบทบาท' ||
                  _selectedStatus != 'ทุกสถานะ' ||
                  _filterSuspendedOnly ||
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

  Widget _buildUserList(List<UserModel> filtered) {
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
                        'รายชื่อผู้ใช้ทั้งหมด',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ตารางแสดงข้อมูลผู้ใช้ สิทธิ์บทบาท และสถานะการใช้งานในระบบ',
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
                    'พบผู้ใช้ ${filtered.length} คน',
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
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text(
                    'ไม่พบข้อมูลผู้ใช้',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ลองเปลี่ยนคำค้นหาหรือล้างตัวกรองหมวดหมู่',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth >= 950) {
                  return Table(
                    border: const TableBorder(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      horizontalInside: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2.8),
                      1: FlexColumnWidth(1.4),
                      2: FlexColumnWidth(1.4),
                      3: FlexColumnWidth(1.2),
                      4: FlexColumnWidth(0.8),
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
                          _TableHeader(text: 'ผู้ใช้งาน / อีเมล', align: TextAlign.left),
                          _TableHeader(text: 'บทบาทในระบบ'),
                          _TableHeader(text: 'อาคาร / ห้อง'),
                          _TableHeader(text: 'สถานะ'),
                          _TableHeader(text: 'จัดการ'),
                        ],
                      ),
                      ...filtered.map((user) {
                        final isMe = currentUserModel?.uid == user.uid;
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF9E401A).withAlpha(22),
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        color: Color(0xFF9E401A),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
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
                                            Text(
                                              user.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: user.isSuspended ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            if (isMe) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEFF6FF),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'คุณ',
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user.email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: const Color(0xFF64748B),
                                            decoration: user.isSuspended ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Center(child: _buildRoleChip(user.role)),
                            Center(
                              child: Text(
                                (user.building.isNotEmpty || user.room.isNotEmpty)
                                    ? '${user.building} ${user.room}'.trim()
                                    : '-',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                              ),
                            ),
                            Center(child: buildStatusBadge(user)),
                            Center(
                              child: PopupMenuButton<String>(
                                tooltip: 'จัดการผู้ใช้',
                                color: Colors.white,
                                surfaceTintColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                elevation: 6,
                                shadowColor: const Color(0x1A000000),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'role':
                                      showChangeRoleDialog(user);
                                      break;
                                    case 'edit':
                                      showEditUserDialog(user);
                                      break;
                                    case 'toggle':
                                      if (user.isSuspended) {
                                        confirmReactivateUser(user);
                                      } else {
                                        confirmDeleteUser(user);
                                      }
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  return [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
                                          SizedBox(width: 10),
                                          Text('แก้ไขชื่อผู้ใช้'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'role',
                                      enabled: !isMe,
                                      child: const Row(
                                        children: [
                                          Icon(Icons.manage_accounts_outlined, size: 18, color: Color(0xFF475569)),
                                          SizedBox(width: 10),
                                          Text('เปลี่ยนสิทธิ์และบทบาท'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      enabled: !isMe,
                                      child: Row(
                                        children: [
                                          Icon(
                                            user.isSuspended ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                                            size: 18,
                                            color: user.isSuspended ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            user.isSuspended ? 'เปิดใช้งานบัญชี' : 'ระงับการใช้งาน',
                                            style: TextStyle(
                                              color: user.isSuspended ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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

                // Mobile Card Layout
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: filtered.map((user) {
                      final isMe = currentUserModel?.uid == user.uid;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF9E401A).withAlpha(22),
                                  child: Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Color(0xFF9E401A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
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
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        user.email,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                buildStatusBadge(user),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildRoleChip(user.role),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'แก้ไขชื่อ',
                                  onPressed: () => showEditUserDialog(user),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                                  tooltip: 'เปลี่ยนสิทธิ์',
                                  onPressed: isMe ? null : () => showChangeRoleDialog(user),
                                ),
                                if (user.isSuspended)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF16A34A)),
                                    tooltip: 'เปิดใช้งาน',
                                    onPressed: isMe ? null : () => confirmReactivateUser(user),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.block_rounded, size: 18, color: Color(0xFFDC2626)),
                                    tooltip: 'ระงับผู้ใช้',
                                    onPressed: isMe ? null : () => confirmDeleteUser(user),
                                  ),
                              ],
                            ),
                          ],
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
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.text, this.align = TextAlign.center});

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

class _SummaryItemData {
  const _SummaryItemData({
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryItemData data;

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
