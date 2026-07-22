import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

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
        appBar: AppBar(
          title: const Text(
            'โปรไฟล์',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Text(
            'ยังไม่มีผู้ใช้ Login',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    final isAdmin = user.role == UserRole.schoolAdmin;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceBright,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withValues(alpha: 0.8), primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 40,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Text(
                'โปรไฟล์ของฉัน',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            backgroundColor: primaryColor,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? Colors.purple.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isAdmin
                                ? Colors.purple.withValues(alpha: 0.3)
                                : Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.person_outline,
                              size: 20,
                              color: isAdmin ? Colors.purple : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user.role.label,
                              style: TextStyle(
                                color: isAdmin ? Colors.purple : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('ข้อมูลส่วนตัว', Icons.info_outline),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              Icons.person,
                              'ชื่อผู้ใช้',
                              user.name,
                            ),
                            Divider(
                              height: 1,
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                            _buildInfoTile(Icons.email, 'อีเมล', user.email),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: showEditProfileDialog,
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text(
                            'แก้ไขข้อมูล',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle(
                        'อุปกรณ์และการเข้าสู่ระบบ',
                        Icons.security,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user,
                                  color: Colors.green,
                                ),
                              ),
                              title: const Text(
                                'เซสชันปัจจุบัน',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                'โทเคนถูกเก็บในพื้นที่ปลอดภัยของอุปกรณ์',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                onPressed: () async =>
                                    await AuthService.signOut(),
                                tooltip: 'ออกจากระบบ',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () async =>
                              await AuthService.signOutAllDevices(),
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'ออกจากระบบทั้งหมด',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700], size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.black54),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
