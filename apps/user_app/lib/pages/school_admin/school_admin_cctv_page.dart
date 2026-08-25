import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class SchoolAdminCctvPage extends StatefulWidget {
  const SchoolAdminCctvPage({super.key});

  @override
  State<SchoolAdminCctvPage> createState() => _SchoolAdminCctvPageState();
}

class _SchoolAdminCctvPageState extends State<SchoolAdminCctvPage> {
  List<CameraAccessGrantItem> _grants = [];
  bool _isLoading = true;
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ExecutiveService.listCameraAccessGrants(),
        UserAdminService.getAllUsers(),
      ]);

      if (mounted) {
        setState(() {
          _grants = results[0] as List<CameraAccessGrantItem>;
          _users = results[1] as List<UserModel>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGrantDialog() {
    String? selectedUserId = _users.isNotEmpty ? _users.first.uid : null;
    final reasonController = TextEditingController(text: 'เฝ้าระวังความปลอดภัยและกิจกรรมการเรียนการสอน');
    int validDays = 7;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('อนุญาตสิทธิ์เข้าถึงกล้อง CCTV'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('เลือกผู้ใช้งาน:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedUserId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _users.map((u) {
                        return DropdownMenuItem(
                          value: u.uid,
                          child: Text('${u.name} (${u.role.label})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) => setDialogState(() => selectedUserId = v),
                    ),
                    const SizedBox(height: 16),
                    const Text('เหตุผลความจำเป็น (ตามหลัก PDPA):'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'ระบุเหตุผลการเข้าถึง',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('ระยะเวลาที่อนุญาต:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: validDays,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 วัน (ชั่วคราว)')),
                        DropdownMenuItem(value: 7, child: Text('7 วัน (1 สัปดาห์)')),
                        DropdownMenuItem(value: 30, child: Text('30 วัน (1 เดือน)')),
                        DropdownMenuItem(value: 90, child: Text('90 วัน (1 ภาคการศึกษา)')),
                      ],
                      onChanged: (v) => setDialogState(() => validDays = v ?? 7),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: selectedUserId == null
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(dialogContext);
                          final validUntil = DateTime.now().add(Duration(days: validDays));
                          await ExecutiveService.grantCameraAccess(
                            userId: selectedUserId!,
                            reason: reasonController.text.trim(),
                            validUntil: validUntil,
                          );

                          nav.pop();
                          if (!mounted) return;
                          _loadData();

                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('อนุญาตสิทธิ์เข้าถึงกล้อง CCTV เรียบร้อยแล้ว'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                  child: const Text('ยืนยันอนุญาต'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmRevokeGrant(CameraAccessGrantItem grant) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยกเลิกสิทธิ์เข้าถึงกล้อง'),
          content: Text('ต้องการเพิกถอนสิทธิ์การเข้าถึงกล้องของ ${grant.userName} หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(dialogContext);
                await ExecutiveService.revokeCameraAccess(grant.grantId);

                nav.pop();
                if (!mounted) return;
                _loadData();

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('เพิกถอนสิทธิ์เรียบร้อยแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('เพิกถอนสิทธิ์'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('กล้อง CCTV & สิทธิ์การเข้าถึง'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGrantDialog,
        icon: const Icon(Icons.add_moderator),
        label: const Text('อนุญาตสิทธิ์ใหม่'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Notice banner regarding PDPA and AI status
                  _buildNoticeBanner(theme),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'รายการผู้ได้รับสิทธิ์เข้าถึงกล้อง (${_grants.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Grant List
                  if (_grants.isEmpty)
                    _buildEmptyState()
                  else
                    ..._grants.map((grant) => _buildGrantCard(grant)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildNoticeBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.indigo.shade700),
              const SizedBox(width: 8),
              Text(
                'การคุ้มครองข้อมูลส่วนบุคคล (PDPA & CCTV Policy)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'การเข้าถึงภาพจากกล้องวงจรปิดต้องได้รับอนุญาตตามหลักเกณฑ์ความจำเป็นและมีบันทึก Audit Log ทุกครั้ง ทั้งนี้ฟังก์ชัน AI Video Analytics อยู่ระหว่างการพัฒนาระบบประมวลผล',
            style: TextStyle(fontSize: 13, color: Colors.indigo.shade900, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.videocam_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'ยังไม่มีการให้สิทธิ์เข้าถึงกล้อง CCTV',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'กดปุ่ม "อนุญาตสิทธิ์ใหม่" เพื่อเพิ่มผู้มีสิทธิ์เข้าถึง',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGrantCard(CameraAccessGrantItem grant) {
    final isExpired = grant.validUntil.isBefore(DateTime.now());
    final bool isActive = grant.isActive;

    String statusLabel;
    Color statusBgColor;
    Color statusBorderColor;
    Color statusTextColor;

    if (isActive) {
      statusLabel = 'ใช้งานอยู่';
      statusBgColor = Colors.green.shade50;
      statusBorderColor = Colors.green.shade300;
      statusTextColor = Colors.green.shade800;
    } else if (isExpired) {
      statusLabel = 'หมดอายุ';
      statusBgColor = Colors.grey.shade200;
      statusBorderColor = Colors.grey.shade400;
      statusTextColor = Colors.grey.shade700;
    } else {
      statusLabel = 'เพิกถอนสิทธิ์แล้ว';
      statusBgColor = Colors.red.shade50;
      statusBorderColor = Colors.red.shade300;
      statusTextColor = Colors.red.shade800;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: isActive
                  ? Colors.indigo.shade100
                  : (isExpired ? Colors.grey.shade200 : Colors.red.shade100),
              radius: 24,
              child: Icon(
                isActive ? Icons.videocam : Icons.videocam_off,
                color: isActive
                    ? Colors.indigo.shade700
                    : (isExpired ? Colors.grey : Colors.red.shade700),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          grant.userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: isActive ? null : TextDecoration.lineThrough,
                            color: isActive ? null : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusBorderColor),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${grant.userEmail} • ${grant.userRole}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'เหตุผล: ${grant.reason}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'หมดอายุ: ${grant.validUntil.day}/${grant.validUntil.month}/${grant.validUntil.year}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isActive)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'เพิกถอนสิทธิ์',
                onPressed: () => _confirmRevokeGrant(grant),
              ),
          ],
        ),
      ),
    );
  }
}
