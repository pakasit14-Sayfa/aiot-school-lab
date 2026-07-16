import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class IssueBindingCodePage extends StatefulWidget {
  const IssueBindingCodePage({super.key});

  @override
  State<IssueBindingCodePage> createState() => _IssueBindingCodePageState();
}

class _IssueBindingCodePageState extends State<IssueBindingCodePage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController studentCodeController = TextEditingController();
  bool isSending = false;
  List<BindingCode> codes = [];
  bool isLoadingList = true;

  @override
  void initState() {
    super.initState();
    loadCodes();
  }

  Future<void> loadCodes() async {
    setState(() => isLoadingList = true);
    try {
      final result = await AuthService.listBindingCodes();
      if (mounted) setState(() => codes = result);
    } finally {
      if (mounted) setState(() => isLoadingList = false);
    }
  }

  void showCodeDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ออกรหัสสำเร็จ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('สำหรับนักเรียน: ${result['studentName']}'),
              const SizedBox(height: 12),
              const Text('ส่งรหัสนี้ให้ผู้ปกครอง (มีอายุ 14 วัน):'),
              const SizedBox(height: 8),
              SelectableText(
                result['code'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  fontSize: 18,
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

  void issueCode() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isSending = true);

    try {
      final result = await AuthService.createBindingCode(
        studentCode: studentCodeController.text.trim(),
      );

      studentCodeController.clear();
      await loadCodes();

      if (!mounted) return;
      showCodeDialog(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  void revokeCode(BindingCode code) async {
    try {
      await AuthService.revokeBindingCode(code.id);
      await loadCodes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    studentCodeController.dispose();
    super.dispose();
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
      appBar: AppBar(title: const Text('ออกรหัสผูกบัญชีผู้ปกครอง')),
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
                    'ออกรหัสสำหรับนักเรียน',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: studentCodeController,
                    decoration: const InputDecoration(
                      labelText: 'รหัสนักเรียน (Student Code)',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'กรุณากรอกรหัสนักเรียน'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSending ? null : issueCode,
                      icon: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code),
                      label: Text(isSending ? 'กำลังออกรหัส...' : 'ออกรหัส'),
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
                  'รหัสที่ออกแล้ว',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: loadCodes,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoadingList)
              const Center(child: CircularProgressIndicator())
            else if (codes.isEmpty)
              const Text('ยังไม่มีรหัสที่ออก', style: TextStyle(color: Colors.grey))
            else
              ...codes.map((code) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(code.studentName),
                    subtitle: Text(
                      '${code.codeHint} • ${code.status}'
                      '${code.isIssued ? " • หมดอายุ ${code.expiresAt.toLocal()}" : ""}',
                    ),
                    trailing: code.isIssued
                        ? IconButton(
                            tooltip: 'ยกเลิกรหัส',
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => revokeCode(code),
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
