import 'package:flutter/material.dart';
import '../data/user_data.dart';

// หน้านี้ใช้แสดงข้อมูลโปรไฟล์ของผู้ใช้ที่ Login อยู่
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ฟังก์ชันเปิดกล่องแก้ไขโปรไฟล์
  void showEditProfileDialog() {
    final nameController = TextEditingController(
      text: currentUser?['name'] ?? '',
    );

    final passwordController = TextEditingController(
      text: currentUser?['password'] ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('แก้ไขโปรไฟล์'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Email: ${currentUser?['email'] ?? ''}',
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
                  labelText: 'รหัสผ่านใหม่',
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

                await updateCurrentUserProfile(
                  newName: newName,
                  newPassword: newPassword,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);

                // อัปเดตหน้าโปรไฟล์ใหม่
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('แก้ไขโปรไฟล์เรียบร้อยแล้ว')),
                );
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
    // ถ้ายังไม่มีผู้ใช้ Login อยู่
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('โปรไฟล์'), centerTitle: true),
        body: const Center(
          child: Text('ยังไม่มีผู้ใช้ Login', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    final name = currentUser?['name'] ?? '';
    final email = currentUser?['email'] ?? '';
    final role = currentUser?['role'] ?? 'user';

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ของฉัน'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // รูปโปรไฟล์จำลอง
            CircleAvatar(
              radius: 50,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 36),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(email, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 24),

            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('ชื่อผู้ใช้'),
                subtitle: Text(name),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('อีเมล'),
                subtitle: Text(email),
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(
                  role == 'admin'
                      ? Icons.admin_panel_settings
                      : Icons.person_outline,
                ),
                title: const Text('สิทธิ์ผู้ใช้'),
                subtitle: Text(role),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: showEditProfileDialog,
              child: const Text('แก้ไขโปรไฟล์'),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('กลับหน้า Home'),
            ),
          ],
        ),
      ),
    );
  }
}
