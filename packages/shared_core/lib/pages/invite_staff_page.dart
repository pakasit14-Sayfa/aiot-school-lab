import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/invitation_model.dart';
import '../services/auth_service.dart';

class InviteStaffPage extends StatefulWidget {
  const InviteStaffPage({super.key});

  @override
  State<InviteStaffPage> createState() => _InviteStaffPageState();
}

class _InviteStaffPageState extends State<InviteStaffPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  UserRole selectedRole = UserRole.teacher;
  bool isSending = false;
  List<StaffInvitation> invitations = [];
  bool isLoadingList = true;

  @override
  void initState() {
    super.initState();
    loadInvitations();
  }

  Future<void> loadInvitations() async {
    setState(() => isLoadingList = true);
    try {
      final result = await AuthService.listInvitations();
      if (mounted) setState(() => invitations = result);
    } finally {
      if (mounted) setState(() => isLoadingList = false);
    }
  }

  void showTokenDialog(String token) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('เชิญสำเร็จ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ส่งรหัสเชิญนี้ให้ผู้ถูกเชิญ (มีอายุ 7 วัน):'),
              const SizedBox(height: 12),
              SelectableText(
                token,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  void sendInvite() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isSending = true);

    try {
      final token = await AuthService.createInvitation(
        email: emailController.text.trim(),
        role: selectedRole,
      );

      emailController.clear();
      await loadInvitations();

      if (!mounted) return;
      showTokenDialog(token);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  void revokeInvite(StaffInvitation invitation) async {
    try {
      await AuthService.revokeInvitation(invitation.id);
      await loadInvitations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserModel?.role != UserRole.schoolAdmin &&
        currentUserModel?.role != UserRole.superAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('ไม่มีสิทธิ์เข้าถึง')),
        body: const Center(child: Text('หน้านี้สำหรับแอดมินเท่านั้น')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('เชิญผู้ใช้ใหม่')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'เชิญด้วยอีเมล',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'กรุณากรอกอีเมล';
                      if (!v.contains('@')) return 'รูปแบบอีเมลไม่ถูกต้อง';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'บทบาท',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    items: UserRole.values
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.label),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedRole = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSending ? null : sendInvite,
                      icon: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(isSending ? 'กำลังส่ง...' : 'สร้างคำเชิญ'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'คำเชิญที่ส่งไปแล้ว',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: loadInvitations,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoadingList)
              const Center(child: CircularProgressIndicator())
            else if (invitations.isEmpty)
              const Text('ยังไม่มีคำเชิญ', style: TextStyle(color: Colors.grey))
            else
              ...invitations.map((invitation) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(invitation.email),
                    subtitle: Text(
                      '${invitation.role.label} • ${invitation.status}'
                      '${invitation.isPending ? " • หมดอายุ ${invitation.expiresAt.toLocal()}" : ""}',
                    ),
                    trailing: invitation.isPending
                        ? IconButton(
                            tooltip: 'ยกเลิกคำเชิญ',
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => revokeInvite(invitation),
                          )
                        : null,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
