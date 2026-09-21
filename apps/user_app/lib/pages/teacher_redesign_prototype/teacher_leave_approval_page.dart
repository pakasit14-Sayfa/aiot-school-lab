import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'teacher_shared_widgets.dart';
import 'teacher_redesign_prototype_page.dart';

class TeacherLeaveApprovalPage extends StatefulWidget {
  const TeacherLeaveApprovalPage({
    super.key,
    this.listPendingLeaveRequests,
    this.reviewLeaveRequest,
    this.getAttachmentDownloadUrl,
  });

  /// Read/write seams threaded to the corresponding LeaveService static
  /// calls in production.
  final Future<List<LeaveRequestForReview>> Function()?
  listPendingLeaveRequests;
  final Future<void> Function({
    required String leaveId,
    required String status,
    String? reviewNote,
  })?
  reviewLeaveRequest;
  final Future<String> Function(String leaveId)? getAttachmentDownloadUrl;

  @override
  State<TeacherLeaveApprovalPage> createState() =>
      _TeacherLeaveApprovalPageState();
}

class _TeacherLeaveApprovalPageState extends State<TeacherLeaveApprovalPage> {
  bool _isLoading = true;
  String? _loadError;
  List<LeaveRequestForReview> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final loadRequests =
          widget.listPendingLeaveRequests ??
          LeaveService.listPendingLeaveRequests;
      final items = await loadRequests();
      if (!mounted) return;
      setState(() {
        _requests = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดคำขอลาไม่สำเร็จ';
        _isLoading = false;
      });
    }
  }

  Future<void> _reviewRequest(String leaveId, String status) async {
    try {
      final review =
          widget.reviewLeaveRequest ?? LeaveService.reviewLeaveRequest;
      await review(
        leaveId: leaveId,
        status: status,
        reviewNote: status == 'approved'
            ? 'อนุมัติผ่านแอป'
            : 'ไม่อนุมัติผ่านแอป',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'อนุมัติการลาเรียบร้อย'
                : 'ปฏิเสธการลาเรียบร้อย',
          ),
        ),
      );

      _fetchRequests();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่')),
      );
    }
  }

  Future<void> _viewAttachment(String leaveId) async {
    try {
      final getUrl =
          widget.getAttachmentDownloadUrl ??
          LeaveService.getAttachmentDownloadUrl;
      final url = await getUrl(leaveId);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Stack(
            children: [
              Image.network(url),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เปิดไฟล์แนบไม่สำเร็จ')));
    }
  }

  Widget _buildRequestCard(LeaveRequestForReview req) {
    final studentName = req.studentName;

    final isSick = req.leaveType == 'sick';
    final typeText = isSick
        ? 'ลาป่วย'
        : (req.leaveType == 'personal' ? 'ลากิจ' : 'อื่นๆ');
    final typeColor = isSick ? Colors.red : Colors.orange;

    final startDate = req.startDate;
    final endDate = req.endDate;

    final dateStr =
        (startDate.day == endDate.day && startDate.month == endDate.month)
        ? '${startDate.day}/${startDate.month}/${startDate.year}'
        : '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}/${endDate.year}';

    final hasAttachment = req.attachmentPath != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: TeacherPalette.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: TeacherPalette.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'วันที่ยื่น: ${req.createdAt.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeText,
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: TeacherPalette.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'วันที่ลา: $dateStr',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('เหตุผล: ${req.reason ?? '-'}'),
                  if (hasAttachment) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _viewAttachment(req.leaveId),
                      child: Container(
                        height: 44,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.attach_file_rounded,
                              size: 18,
                              color: TeacherPalette.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'ดูไฟล์แนบ',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reviewRequest(req.leaveId, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('ไม่อนุมัติ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _reviewRequest(req.leaveId, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('อนุมัติ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'กล่องอนุมัติใบลา',
      onRefresh: _fetchRequests,
      activeMenuLabel: 'อนุมัติใบลา',
      builder: (context, isDesktop) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_loadError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _fetchRequests,
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            ),
          );
        }
        if (_requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'ไม่มีคำขอลาเรียนรอดำเนินการ',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }
        // Not ListView.builder: TeacherMockPageShell already wraps its
        // builder() result in a SingleChildScrollView, so a nested
        // ListView here gets unbounded height and crashes with "Vertical
        // viewport was given unbounded height" the moment there's at
        // least one real pending request.
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [for (final r in _requests) _buildRequestCard(r)],
          ),
        );
      },
    );
  }
}
