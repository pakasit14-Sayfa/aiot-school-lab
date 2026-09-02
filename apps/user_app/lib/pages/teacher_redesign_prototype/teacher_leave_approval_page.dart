import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'teacher_shared_widgets.dart';
import 'teacher_redesign_prototype_page.dart';

class TeacherLeaveApprovalPage extends StatefulWidget {
  const TeacherLeaveApprovalPage({super.key});

  @override
  State<TeacherLeaveApprovalPage> createState() => _TeacherLeaveApprovalPageState();
}

class _TeacherLeaveApprovalPageState extends State<TeacherLeaveApprovalPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get current user's school
      final token = AuthService.sessionToken;
      if (token == null) throw Exception('No session token');
      
      // Directly query the DB (if we have permissions, wait, teachers can read leave_requests in their school per RLS)
      // We will do a simple query to leave_requests joined with users (for student name)
      
      final res = await supabase
          .from('leave_requests')
          .select('''
            id,
            leave_type,
            start_date,
            end_date,
            reason,
            attachment_url,
            status,
            created_at,
            users!leave_requests_student_id_fkey(
              first_name,
              last_name,
              avatar_url
            )
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching leave requests: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reviewRequest(String leaveId, String status) async {
    try {
      final token = AuthService.sessionToken;
      if (token == null) throw Exception('No session token');

      // Call the RPC
      await supabase.rpc('review_leave_request', params: {
        'p_token': token,
        'p_leave_id': leaveId,
        'p_status': status,
        'p_review_note': 'Approve via App',
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'approved' ? 'อนุมัติการลาเรียบร้อย' : 'ปฏิเสธการลาเรียบร้อย')),
      );
      
      _fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final student = req['users'];
    final studentName = student != null 
        ? '${student['first_name']} ${student['last_name']}'
        : 'ไม่ทราบชื่อ';
    
    final isSick = req['leave_type'] == 'sick';
    final typeText = isSick ? 'ลาป่วย' : (req['leave_type'] == 'personal' ? 'ลากิจ' : 'อื่นๆ');
    final typeColor = isSick ? Colors.red : Colors.orange;
    
    final startDate = DateTime.parse(req['start_date']);
    final endDate = DateTime.parse(req['end_date']);
    
    final dateStr = (startDate.day == endDate.day && startDate.month == endDate.month)
        ? '${startDate.day}/${startDate.month}/${startDate.year}'
        : '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}/${endDate.year}';
        
    final attachmentUrl = req['attachment_url'];

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
                  backgroundColor: TeacherPalette.primary.withValues(alpha: 0.1),
                  backgroundImage: (student?['avatar_url'] != null)
                      ? NetworkImage(student!['avatar_url'])
                      : null,
                  child: (student?['avatar_url'] == null)
                      ? const Icon(Icons.person, color: TeacherPalette.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text(
                        'วันที่ยื่น: ${DateTime.parse(req['created_at']).toLocal().toString().split(' ')[0]}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeText,
                    style: TextStyle(color: typeColor, fontWeight: FontWeight.w700, fontSize: 12),
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
                      const Icon(Icons.calendar_today, size: 16, color: TeacherPalette.primary),
                      const SizedBox(width: 8),
                      Text('วันที่ลา: $dateStr', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('เหตุผล: ${req['reason']}'),
                  if (attachmentUrl != null) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        // Open full image
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: Stack(
                              children: [
                                Image.network(attachmentUrl),
                                Positioned(
                                  top: 8, right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.black54),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(attachmentUrl),
                            fit: BoxFit.cover,
                          ),
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
                    onPressed: () => _reviewRequest(req['id'], 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ไม่อนุมัติ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _reviewRequest(req['id'], 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      activeMenuLabel: 'อนุมัติใบลา',
      builder: (context, isDesktop) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('ไม่มีคำขอลาเรียนรอดำเนินการ', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: _requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(_requests[index]);
          },
        );
      },
    );
  }
}
