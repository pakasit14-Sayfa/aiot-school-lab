import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class AppDrawer extends StatelessWidget {
  final List<DrawerItem> items;

  const AppDrawer({super.key, required this.items});

  void confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final name = user?.name ?? '';
    final email = user?.email ?? '';
    final role = user?.role ?? UserRole.student;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(name),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            otherAccountsPictures: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role.label,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1ABC9C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: items
                  .map((item) => ListTile(
                        leading: Icon(item.icon, color: item.color),
                        title: Text(item.title),
                        onTap: () {
                          Navigator.pop(context);
                          item.onTap(context);
                        },
                      ))
                  .toList(),
            ),
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('โปรไฟล์ของฉัน'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              confirmLogout(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class DrawerItem {
  final IconData icon;
  final String title;
  final Color color;
  final void Function(BuildContext context) onTap;

  const DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = Colors.blueGrey,
  });
}
