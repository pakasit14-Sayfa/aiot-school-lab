import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void showEditProfileDialog() {
    final nameController = TextEditingController(
      text: currentUserModel?.name ?? '',
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
                'Email: ${currentUserModel?.email ?? ''}',
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
              const SizedBox(height: 8),
              const Text(
                'หากต้องการเปลี่ยนรหัสผ่าน ใช้ฟังก์ชัน "ลืมรหัสผ่าน" ในหน้า Login',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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

                await AuthService.updateProfile(
                  uid: currentUserModel!.uid,
                  name: newName,
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
    final user = currentUserModel;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('โปรไฟล์')),
        body: const Center(
          child: Text('ยังไม่มีผู้ใช้ Login', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    final isAdmin = user.role == UserRole.schoolAdmin;

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
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 42,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            user.name,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontSize: 28,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 6),

                          Text(
                            user.email,
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
                              color: isAdmin
                                  ? Colors.purple.withOpacity(0.12)
                                  : Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user.role.label,
                              style: TextStyle(
                                color: isAdmin ? Colors.purple : Colors.green,
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
                      subtitle: Text(user.name),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('อีเมล'),
                      subtitle: Text(user.email),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: ListTile(
                      leading: Icon(
                        isAdmin
                            ? Icons.admin_panel_settings
                            : Icons.person_outline,
                      ),
                      title: const Text('สิทธิ์ผู้ใช้'),
                      subtitle: Text(user.role.label),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: showEditProfileDialog,
                      icon: const Icon(Icons.edit),
                      label: const Text('แก้ไขชื่อ'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
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
