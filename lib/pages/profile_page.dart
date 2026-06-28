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

              const SizedBox(height: 16),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ',
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

                await updateCurrentUserProfile(
                  newName: newName,
                  newPassword: newPassword,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);

                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('แก้ไขโปรไฟล์เรียบร้อยแล้ว'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('โปรไฟล์')),
        body: const Center(
          child: Text('ยังไม่มีผู้ใช้ Login', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    final name = currentUser?['name'] ?? '';
    final email = currentUser?['email'] ?? '';
    final role = currentUser?['role'] ?? 'user';

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ของฉัน')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: primaryColor.withOpacity(0.12),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 42,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            name,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontSize: 28,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 6),

                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: role == 'admin'
                                  ? Colors.purple.withOpacity(0.12)
                                  : Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              role == 'admin' ? 'ผู้ดูแลระบบ' : 'ผู้ใช้ทั่วไป',
                              style: TextStyle(
                                color: role == 'admin'
                                    ? Colors.purple
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('ชื่อผู้ใช้'),
                      subtitle: Text(name),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('อีเมล'),
                      subtitle: Text(email),
                    ),
                  ),

                  const SizedBox(height: 10),

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

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: showEditProfileDialog,
                      icon: const Icon(Icons.edit),
                      label: const Text('แก้ไขโปรไฟล์'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('กลับหน้า Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
