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
  String searchText = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
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

  void showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('แก้ไขชื่อผู้ใช้'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Email: ${user.email}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อผู้ใช้',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณากรอกชื่อ'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                await AuthService.updateProfile(uid: user.uid, name: newName);

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await loadUsers();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('แก้ไขข้อมูลเรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('บันทึก'),
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
              title: const Text('เปลี่ยนสิทธิ์ผู้ใช้'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Email: ${user.email}'),
                    const SizedBox(height: 16),
                    ...allowedRoles.map((role) {
                      return RadioListTile<UserRole>(
                        title: Text(role.label),
                        value: role,
                        groupValue: selectedRole,
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedRole = v);
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await UserAdminService.updateRole(
                      uid: user.uid,
                      role: selectedRole,
                    );

                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                    await loadUsers();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('เปลี่ยนสิทธิ์เรียบร้อยแล้ว'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('ยืนยัน'),
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
          title: const Text('ยืนยันการระงับผู้ใช้'),
          content: Text('ต้องการระงับการใช้งานผู้ใช้นี้หรือไม่? (บัญชีจะไม่ถูกลบถาวร)\n${user.email}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                await UserAdminService.deleteUser(user.uid);

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await loadUsers();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ระงับผู้ใช้เรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ระงับ'),
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
          title: const Text('ยืนยันการเปิดใช้งานผู้ใช้'),
          content: Text('ต้องการเปิดใช้งานบัญชีผู้ใช้นี้อีกครั้งหรือไม่?\n${user.email}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                await UserAdminService.reactivateUser(user.uid);

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await loadUsers();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('เปิดใช้งานผู้ใช้เรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('เปิดใช้งาน'),
            ),
          ],
        );
      },
    );
  }

  Widget buildRoleBadge(UserRole role) {
    final isAdmin = role == UserRole.schoolAdmin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin
            ? Colors.purple.withValues(alpha: 0.12)
            : Colors.blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: isAdmin ? Colors.purple : Colors.blue.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildStatusBadge(UserModel user) {
    if (user.isSuspended) {
      return Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'ถูกระงับ',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (currentUserModel?.role != UserRole.schoolAdmin &&
        currentUserModel?.role != UserRole.superAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('ไม่มีสิทธิ์เข้าถึง')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 90, color: primaryColor),
                const SizedBox(height: 20),
                const Text(
                  'คุณไม่มีสิทธิ์เข้าถึงหน้านี้',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'หน้านี้สำหรับแอดมินโรงเรียนเท่านั้น',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text('กลับหน้า Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredUsers = users.where((u) {
      final keyword = searchText.toLowerCase();
      return u.name.toLowerCase().contains(keyword) ||
          u.email.toLowerCase().contains(keyword);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ใช้'),
        actions: [
          IconButton(
            tooltip: 'เชิญผู้ใช้ใหม่',
            icon: const Icon(Icons.person_add_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InviteStaffPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'ออกรหัสผูกบัญชีผู้ปกครอง',
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IssueBindingCodePage()),
              );
            },
          ),
          IconButton(
            tooltip: 'คำขอผูกบัญชีผู้ปกครอง',
            icon: const Icon(Icons.family_restroom),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ParentLinkReviewPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadUsers,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'รายชื่อผู้ใช้ทั้งหมด',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: (v) => setState(() => searchText = v),
                          decoration: const InputDecoration(
                            labelText: 'ค้นหาชื่อหรืออีเมล',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.group, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'พบผู้ใช้ ${filteredUsers.length} คน',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              'ไม่พบข้อมูลผู้ใช้',
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final isMe =
                                  currentUserModel?.uid == user.uid;

                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.only(bottom: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor:
                                            primaryColor.withValues(alpha: 0.12),
                                        child: Text(
                                          user.name.isNotEmpty
                                              ? user.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 14),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    user.name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                buildRoleBadge(user.role),
                                                buildStatusBadge(user),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user.email,
                                              style: TextStyle(
                                                color: user.isSuspended
                                                    ? Colors.red.shade400
                                                    : Colors.grey,
                                                decoration: user.isSuspended
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            if (isMe)
                                              const Text(
                                                'บัญชีที่กำลังใช้งานอยู่',
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      Column(
                                        children: [
                                          IconButton(
                                            tooltip: 'เปลี่ยนสิทธิ์',
                                            icon: const Icon(
                                                Icons.manage_accounts),
                                            onPressed: isMe
                                                ? null
                                                : () =>
                                                    showChangeRoleDialog(user),
                                          ),
                                          IconButton(
                                            tooltip: 'แก้ไขชื่อ',
                                            icon: const Icon(Icons.edit),
                                            onPressed: () =>
                                                showEditUserDialog(user),
                                          ),
                                           if (user.isSuspended)
                                             IconButton(
                                               tooltip: 'เปิดใช้งานผู้ใช้',
                                               icon: const Icon(
                                                   Icons.check_circle_outline),
                                               color: Colors.green,
                                               onPressed: isMe
                                                   ? null
                                                   : () =>
                                                       confirmReactivateUser(
                                                           user),
                                             )
                                           else
                                             IconButton(
                                               tooltip: 'ระงับผู้ใช้',
                                               icon: const Icon(Icons.delete),
                                               color: Colors.red,
                                               onPressed: isMe
                                                   ? null
                                                   : () =>
                                                       confirmDeleteUser(user),
                                             ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
