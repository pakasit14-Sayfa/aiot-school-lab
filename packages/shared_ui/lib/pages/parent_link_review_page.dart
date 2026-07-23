import 'package:flutter/material.dart';
import 'package:shared_core/models/user_model.dart';
import 'package:shared_core/models/parent_binding_model.dart';
import 'package:shared_core/services/auth_service.dart';
import 'package:shared_core/services/parent_binding_service.dart';

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
      final pending = await ParentBindingService.listParentLinks(status: 'pending');
      final secondReview = currentUserModel?.role == UserRole.schoolAdmin
          ? await ParentBindingService.listParentLinks(status: 'pending_second_review')
          : <ParentLink>[];
      if (mounted) setState(() => links = [...pending, ...secondReview]);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void requestSecondReview(ParentLink link) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ขอผู้ตรวจคนที่สอง'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'เหตุผลข้อยกเว้น (จำเป็น)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ส่งตรวจ'),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || reason.isEmpty) return;

    try {
      await ParentBindingService.requestParentLinkSecondReview(link.id, reason: reason);
      await loadLinks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  void secondApprove(ParentLink link) async {
    try {
      await ParentBindingService.secondApproveParentLink(link.id);
      await loadLinks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อนุมัติโดยผู้ตรวจคนที่สองแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  void approve(ParentLink link) async {
    try {
      await ParentBindingService.approveParentLink(link.id);
      await loadLinks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อนุมัติแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
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
            decoration: const InputDecoration(labelText: 'เหตุผล (จำเป็น)'),
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

    final reason = reasonController.text.trim();
    if (confirmed != true || reason.isEmpty) return;

    try {
      await ParentBindingService.rejectParentLink(link.id, reason: reason);
      await loadLinks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ปฏิเสธคำขอแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
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
              child: Text(
                'ไม่มีคำขอที่รอตรวจสอบ',
                style: TextStyle(color: Colors.grey),
              ),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          link.parentEmail,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text('นักเรียน: ${link.studentName}'),
                        if (link.isPendingSecondReview)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'รอ School Admin คนที่สองตรวจภายใน SLA',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (link.isPendingSecondReview) {
                                    secondApprove(link);
                                  } else if (currentUserModel?.role ==
                                          UserRole.schoolAdmin &&
                                      currentUserModel?.uid == link.parentId) {
                                    requestSecondReview(link);
                                  } else {
                                    approve(link);
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: Text(
                                  link.isPendingSecondReview
                                      ? 'Second approve'
                                      : currentUserModel?.uid == link.parentId
                                      ? 'ขอผู้ตรวจคนที่สอง'
                                      : 'อนุมัติ',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => reject(link),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
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
