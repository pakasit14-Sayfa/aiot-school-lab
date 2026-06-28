import 'package:flutter/material.dart';
import '../data/user_data.dart';

// หน้านี้ใช้แสดงรายชื่อผู้ใช้ทั้งหมด
class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  // เก็บข้อความที่พิมพ์ในช่องค้นหา
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
              const SizedBox(height: 12),

              // ช่องแก้ไขชื่อ
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ช่องแก้ไขรหัสผ่าน
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'รหัสผ่าน',
                  border: OutlineInputBorder(),
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
                    const SnackBar(content: Text('กรุณากรอกชื่อและรหัสผ่าน')),
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

                // อัปเดตหน้าจอใหม่
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('แก้ไขข้อมูลเรียบร้อยแล้ว')),
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

                // อัปเดตหน้าจอใหม่
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('เปลี่ยนสิทธิ์เรียบร้อยแล้ว')),
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

                // ปิดกล่องยืนยัน
                Navigator.pop(dialogContext);

                // อัปเดตหน้าจอใหม่
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบผู้ใช้เรียบร้อยแล้ว')),
                );
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ถ้าไม่ใช่ admin ห้ามเข้าหน้านี้
    if (currentUser?['role'] != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ไม่มีสิทธิ์เข้าถึง'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 80),
                const SizedBox(height: 16),
                const Text(
                  'คุณไม่มีสิทธิ์เข้าถึงหน้านี้',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'หน้านี้สำหรับผู้ดูแลระบบเท่านั้น',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: const Text('กลับหน้า Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // กรองข้อมูลผู้ใช้ตามข้อความค้นหา
    final filteredUsers = users.where((user) {
      final name = user['name']?.toLowerCase() ?? '';
      final email = user['email']?.toLowerCase() ?? '';
      final keyword = searchText.toLowerCase();

      return name.contains(keyword) || email.contains(keyword);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายชื่อผู้ใช้ทั้งหมด'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ช่องค้นหา
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'ค้นหาชื่อหรืออีเมล',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // แสดงจำนวนผู้ใช้
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'พบผู้ใช้ ${filteredUsers.length} คน',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // รายชื่อผู้ใช้
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(
                    child: Text(
                      'ไม่พบข้อมูลผู้ใช้',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final name = user['name'] ?? '';
                      final email = user['email'] ?? '';
                      final role = user['role'] ?? 'user';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Email: $email\nPassword: ****\nRole: $role',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ปุ่มเปลี่ยนสิทธิ์
                              IconButton(
                                icon: Icon(
                                  role == 'admin'
                                      ? Icons.admin_panel_settings
                                      : Icons.person,
                                ),
                                onPressed: currentUser?['email'] == email
                                    ? null
                                    : () {
                                        confirmToggleRole(user);
                                      },
                              ),

                              // ปุ่มแก้ไข
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  showEditUserDialog(user);
                                },
                              ),

                              // ปุ่มลบ
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: currentUser?['email'] == email
                                    ? null
                                    : () {
                                        confirmDeleteUser(email);
                                      },
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
    );
  }
}

// ฟังก์ชันเปลี่ยนสิทธิ์ผู้ใช้ admin <-> user
Future<void> toggleUserRoleByEmail(String email) async {
  // ไม่ให้เปลี่ยนสิทธิ์ของตัวเอง
  if (currentUser?['email'] == email) {
    return;
  }

  final index = users.indexWhere((user) => user['email'] == email);

  if (index != -1) {
    final currentRole = users[index]['role'] ?? 'user';

    if (currentRole == 'admin') {
      users[index]['role'] = 'user';
    } else {
      users[index]['role'] = 'admin';
    }

    // บันทึกข้อมูลใหม่ลงเครื่อง
    await saveUsers();
  }
}
