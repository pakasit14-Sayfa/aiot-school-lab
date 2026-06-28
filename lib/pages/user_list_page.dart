import 'package:flutter/material.dart';
import '../data/user_data.dart';

// หน้านี้ใช้แสดงรายชื่อผู้ใช้ทั้งหมด
class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String searchText = '';

  // ฟังก์ชันเปิดกล่องแก้ไขผู้ใช้
  void showEditUserDialog(Map<String, String> user) {
    final nameController = TextEditingController(text: user['name']);
    final passwordController = TextEditingController(text: user['password']);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('แก้ไขข้อมูลผู้ใช้'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Email: ${user['email']}',
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

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'รหัสผ่านใหม่',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final newPassword = passwordController.text.trim();

                if (newName.isEmpty || newPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณากรอกชื่อและรหัสผ่าน'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                await updateUserByEmail(
                  email: user['email'] ?? '',
                  newName: newName,
                  newPassword: newPassword,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);

                setState(() {});

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

  // ฟังก์ชันยืนยันก่อนเปลี่ยนสิทธิ์ผู้ใช้
  void confirmToggleRole(Map<String, String> user) {
    final email = user['email'] ?? '';
    final role = user['role'] ?? 'user';
    final newRole = role == 'admin' ? 'user' : 'admin';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('เปลี่ยนสิทธิ์ผู้ใช้'),
          content: Text(
            'ต้องการเปลี่ยนสิทธิ์ของ\n$email\nจาก $role เป็น $newRole หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                await toggleUserRoleByEmail(email);

                if (!mounted) return;

                Navigator.pop(dialogContext);

                setState(() {});

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
  }

  // ฟังก์ชันยืนยันก่อนลบผู้ใช้
  void confirmDeleteUser(String email) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text('ต้องการลบผู้ใช้นี้หรือไม่?\n$email'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                await deleteUserByEmail(email);

                if (!mounted) return;

                Navigator.pop(dialogContext);

                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ลบผู้ใช้เรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  // สร้างป้ายแสดง role
  Widget buildRoleBadge(String role) {
    final isAdmin = role == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAdmin
            ? Colors.purple.withOpacity(0.12)
            : Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'User',
        style: TextStyle(
          color: isAdmin ? Colors.purple : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // ถ้าไม่ใช่ admin ห้ามเข้าหน้านี้
    if (currentUser?['role'] != 'admin') {
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
                  'หน้านี้สำหรับผู้ดูแลระบบเท่านั้น',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('กลับหน้า Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredUsers = users.where((user) {
      final name = user['name']?.toLowerCase() ?? '';
      final email = user['email']?.toLowerCase() ?? '';
      final keyword = searchText.toLowerCase();

      return name.contains(keyword) || email.contains(keyword);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('จัดการผู้ใช้')),
      body: SafeArea(
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

                  const SizedBox(height: 6),

                  const Text(
                    'ค้นหา แก้ไข ลบ และเปลี่ยนสิทธิ์ผู้ใช้',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'ค้นหาชื่อหรืออีเมล',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Icon(Icons.group, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'พบผู้ใช้ ${filteredUsers.length} คน',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final name = user['name'] ?? '';
                        final email = user['email'] ?? '';
                        final role = user['role'] ?? 'user';
                        final isCurrentUser = currentUser?['email'] == email;

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
                                  backgroundColor: primaryColor.withOpacity(
                                    0.12,
                                  ),
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
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
                                              name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          buildRoleBadge(role),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      Text(
                                        email,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      const Text(
                                        'Password: ****',
                                        style: TextStyle(color: Colors.grey),
                                      ),

                                      if (isCurrentUser) ...[
                                        const SizedBox(height: 6),
                                        const Text(
                                          'บัญชีที่กำลังใช้งานอยู่',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Column(
                                  children: [
                                    IconButton(
                                      tooltip: 'เปลี่ยนสิทธิ์',
                                      icon: Icon(
                                        role == 'admin'
                                            ? Icons.admin_panel_settings
                                            : Icons.person,
                                      ),
                                      onPressed: isCurrentUser
                                          ? null
                                          : () {
                                              confirmToggleRole(user);
                                            },
                                    ),

                                    IconButton(
                                      tooltip: 'แก้ไข',
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        showEditUserDialog(user);
                                      },
                                    ),

                                    IconButton(
                                      tooltip: 'ลบ',
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: isCurrentUser
                                          ? null
                                          : () {
                                              confirmDeleteUser(email);
                                            },
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
