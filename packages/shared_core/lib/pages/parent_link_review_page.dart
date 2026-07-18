import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/parent_binding_model.dart';
import '../services/auth_service.dart';

class ParentLinkReviewPage extends StatefulWidget {
  const ParentLinkReviewPage({super.key});

  @override
  State<ParentLinkReviewPage> createState() => _ParentLinkReviewPageState();
}

class _ParentLinkReviewPageState extends State<ParentLinkReviewPage> {
  List<ParentLink> links = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLinks();
  }

  Future<void> loadLinks() async {
    setState(() => isLoading = true);
    try {
      final result = await AuthService.listParentLinks(status: 'pending');
      if (mounted) setState(() => links = result);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void approve(ParentLink link) async {
    try {
      await AuthService.approveParentLink(link.id);
      await loadLinks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อนุมัติแล้ว'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void reject(ParentLink link) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ปฏิเสธคำขอผูกบัญชี'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(labelText: 'เหตุผล (ถ้ามี)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('ปฏิเสธ'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await AuthService.rejectParentLink(link.id, reason: reasonController.text.trim());
      await loadLinks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ปฏิเสธคำขอแล้ว'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserModel?.role != UserRole.schoolAdmin &&
        currentUserModel?.role != UserRole.teacher &&
        currentUserModel?.role != UserRole.superAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('ไม่มีสิทธิ์เข้าถึง')),
        body: const Center(child: Text('หน้านี้สำหรับแอดมิน/ครูเท่านั้น')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('คำขอผูกบัญชีผู้ปกครอง'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadLinks),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : links.isEmpty
              ? const Center(
                  child: Text('ไม่มีคำขอที่รอตรวจสอบ', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: links.length,
                  itemBuilder: (context, index) {
                    final link = links[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${link.parentName} (${link.relationship})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(link.parentEmail, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('นักเรียน: ${link.studentName}'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => approve(link),
                                    icon: const Icon(Icons.check),
                                    label: const Text('อนุมัติ'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => reject(link),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                    icon: const Icon(Icons.close),
                                    label: const Text('ปฏิเสธ'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
