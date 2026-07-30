import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
import '../teacher/course_list_page.dart';

/// Professional Microsoft Teams Teacher Workspace (Emoji-Free & Clean Enterprise Design)
class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _activeRailIndex = 2; // 2 = Teams
  int _activeClassIndex = 0; // 0 = SC30201 AIoT ชีววิทยา
  int _activeTabContentIndex = 0; // 0 = Posts, 1 = Files, 2 = Assignments, 3 = Grades, 4 = Telemetry

  final List<Map<String, dynamic>> _teacherClasses = [
    {
      'code': 'SC30201',
      'name': 'AIoT ชีววิทยาและสิ่งแวดล้อม',
      'grade': 'ม.4/1',
      'students': 35,
      'room': 'Lab 3',
      'color': const Color(0xFF059669), // Signature Emerald Green
      'icon': Icons.science_outlined,
    },
    {
      'code': 'CS40102',
      'name': 'การเขียนโปรแกรมหุ่นยนต์ AI',
      'grade': 'ม.5/2',
      'students': 28,
      'room': 'Com 1',
      'color': const Color(0xFF0284C7), // Tech Cyan
      'icon': Icons.precision_manufacturing_outlined,
    },
    {
      'code': 'PH20101',
      'name': 'ฟิสิกส์ประยุกต์และ IoT',
      'grade': 'ม.4/3',
      'students': 32,
      'room': 'Lab 1',
      'color': const Color(0xFFD97706), // Amber
      'icon': Icons.bolt_outlined,
    },
    {
      'code': 'EV30301',
      'name': 'วิทยาศาสตร์สิ่งแวดล้อม',
      'grade': 'ม.6/1',
      'students': 30,
      'room': 'แปลงเกษตร',
      'color': const Color(0xFF10B981), // Emerald Mint
      'icon': Icons.eco_outlined,
    },
  ];

  final List<Map<String, dynamic>> _postsFeed = [
    {
      'author': 'ครูสมชาย สายวิทย์ (คุณ)',
      'role': 'ครูผู้สอนประจำวิชา',
      'time': 'วันนี้ 09:30 น.',
      'title': '[ประกาศ] การส่งรายงานผลการทดลองวัดค่า PM2.5 และ CO2',
      'body': 'ให้นักเรียนทุกคนในคลาส ม.4/1 เตรียมรายงานผลการทดลองวัดค่าฝุ่นละออง PM2.5 และก๊าซ CO2 ในห้องเรียน Lab 3 มาส่งภายในวันศุกร์นี้ สามารถดาวน์โหลดเอกสารคู่มือได้จากแท็บไฟล์เอกสารครับ',
      'likes': 18,
      'replies': 4,
    },
    {
      'author': 'นายธีรภัทร สมบูรณ์',
      'role': 'นักเรียน • ม.4/1',
      'time': 'เมื่อวานนี้ 16:45 น.',
      'title': 'สอบถามเรื่องการเขียนโค้ดอ่านค่าเซนเซอร์',
      'body': 'สอบถามรหัสโค้ดส่วนการเชื่อมต่อกับเซนเซอร์ DHT22 ต้องตั้งค่าพิน GPIO ตรงกับบอร์ด ESP32 หมายเลข 4 หรือไม่ครับ',
      'likes': 6,
      'replies': 2,
    },
  ];

  void _showCreateAnnouncementModal() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.campaign_rounded, color: Color(0xFF059669), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('สร้างประกาศประจำชั้นเรียน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A))),
                        SizedBox(height: 2),
                        Text('ประกาศข่าวสารไปยังนักเรียนทุกคนในคลาส', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'หัวข้อประกาศ',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bodyController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'รายละเอียดประกาศ',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    setState(() {
                      _postsFeed.insert(0, {
                        'author': 'ครูสมชาย สายวิทย์ (คุณ)',
                        'role': 'ครูผู้สอนประจำวิชา',
                        'time': 'เมื่อสักครู่นี้',
                        'title': titleController.text.trim(),
                        'body': bodyController.text.trim().isEmpty ? 'รายละเอียดเพิ่มเติมอยู่ในแท็บไฟล์เอกสารครับ' : bodyController.text.trim(),
                        'likes': 0,
                        'replies': 0,
                      });
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('โพสต์ประกาศใหม่ไปยังกระดานข่าวเรียบร้อยแล้ว'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('โพสต์ประกาศ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateAssignmentModal() {
    final titleController = TextEditingController();
    final scoreController = TextEditingController(text: '20');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_task_rounded, color: Color(0xFF059669), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('สร้างการบ้านใหม่', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A))),
                        SizedBox(height: 2),
                        Text('วิชา SC30201: AIoT ชีววิทยาและสิ่งแวดล้อม (ม.4/1)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'หัวข้อการบ้าน / ชื่องาน',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'คะแนนเต็ม',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('มอบหมายการบ้านใหม่สำเร็จ แจ้งเตือนไปยังนักเรียน 35 คนเรียบร้อยแล้ว'),
                        backgroundColor: Color(0xFF059669),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('มอบหมายการบ้าน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGradeStudentModal(Map<String, String> student) {
    final score1Controller = TextEditingController(text: student['score1']?.split('/')[0] ?? '18');
    final score2Controller = TextEditingController(text: student['score2']?.split('/')[0] ?? '14');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.grade_rounded, color: Color(0xFF059669), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ตรวจงานและกรอกคะแนนนักเรียน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text('${student['name']} (เลขประจำตัว ${student['id']})', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: score1Controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'คะแนนใบงานที่ 1 (เต็ม 20)',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: score2Controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'คะแนนใบงานที่ 2 (เต็ม 15)',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final s1 = int.tryParse(score1Controller.text) ?? 18;
                    final s2 = int.tryParse(score2Controller.text) ?? 14;
                    final total = s1 + s2;
                    final gradeLetter = total >= 32 ? 'A' : (total >= 28 ? 'B+' : 'B');

                    setState(() {
                      student['score1'] = '$s1/20';
                      student['score2'] = '$s2/15';
                      student['total'] = '$total/35 ($gradeLetter)';
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('บันทึกคะแนนของ ${student['name']} รวม $total/35 เรียบร้อยแล้ว'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('บันทึกคะแนนเกรด', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final teacherName = user?.name ?? 'ครูสมชาย สายวิทย์';
    final currentClass = _teacherClasses[_activeClassIndex];
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth <= 1024; // Increased breakpoint to 1024px for all laptop/half-screen windows

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF047857),
          foregroundColor: Colors.white,
          title: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _activeClassIndex,
              dropdownColor: const Color(0xFF047857),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              onChanged: (newIndex) {
                if (newIndex != null) {
                  setState(() {
                    _activeClassIndex = newIndex;
                  });
                }
              },
              items: List.generate(_teacherClasses.length, (idx) {
                final cls = _teacherClasses[idx];
                return DropdownMenuItem<int>(
                  value: idx,
                  child: Text('${cls['code']} - ${cls['name']}'),
                );
              }),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_box_rounded, color: Colors.white),
              tooltip: 'สร้างรายวิชาใหม่',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherCourseListPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              tooltip: 'สั่งการบ้านใหม่',
              onPressed: _showCreateAssignmentModal,
            ),
          ],
        ),
        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF047857), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.school_rounded, color: Color(0xFF047857), size: 28),
                ),
                accountName: Text(teacherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                accountEmail: Text(user?.email ?? 'teacher@aiot-school-lab.local', style: const TextStyle(fontSize: 12)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text('เลือกทีมชั้นเรียนของคุณ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _teacherClasses.length,
                  itemBuilder: (context, index) {
                    final item = _teacherClasses[index];
                    final isSelected = _activeClassIndex == index;
                    final color = item['color'] as Color;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: color.withOpacity(0.1),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                        child: Icon(item['icon'] as IconData, color: Colors.white, size: 18),
                      ),
                      title: Text(item['name'] as String, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13.5)),
                      subtitle: Text('${item['code']} • ${item['grade']} • ${item['students']} คน', style: const TextStyle(fontSize: 11)),
                      onTap: () {
                        setState(() {
                          _activeClassIndex = index;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IssueBindingCodePage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF059669)),
                    ),
                    icon: const Icon(Icons.qr_code_rounded, size: 18, color: Color(0xFF059669)),
                    label: const Text('รหัสผูกผู้ปกครอง', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildTeamsWorkspaceHeader(currentClass),
            _buildTeamsWorkspaceTabs(),
            Expanded(
              child: _buildTeamsActiveTabContent(currentClass),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. Left Rail Sidebar
          _buildTeamsActivityRail(teacherName),

          // 2. Class List Left Panel
          _buildTeamsClassChannelsPanel(),

          // 3. Main Workspace Canvas
          Expanded(
            child: Column(
              children: [
                _buildTeamsWorkspaceHeader(currentClass),
                _buildTeamsWorkspaceTabs(),
                Expanded(
                  child: _buildTeamsActiveTabContent(currentClass),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsActivityRail(String teacherName) {
    final railItems = [
      {'icon': Icons.notifications_none_rounded, 'label': 'กิจกรรม', 'badge': 3},
      {'icon': Icons.chat_bubble_outline_rounded, 'label': 'แชท', 'badge': 5},
      {'icon': Icons.groups_outlined, 'label': 'ทีมวิชา', 'badge': 0},
      {'icon': Icons.assignment_outlined, 'label': 'การบ้าน', 'badge': 2},
      {'icon': Icons.calendar_today_rounded, 'label': 'ตารางสอน', 'badge': 0},
      {'icon': Icons.bar_chart_rounded, 'label': 'วิเคราะห์', 'badge': 0},
    ];

    return Container(
      width: 72,
      color: const Color(0xFF0F172A), // Dark Slate
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),

          // ทางเข้าสู่หน้าจัดการรายวิชาจริง (สร้างวิชา/บทเรียน/งาน/ให้คะแนน)
          // — ส่วนบนของหน้านี้เป็นตัวอย่างการออกแบบ (mock), ยังไม่ได้ต่อ backend จริง
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeacherCourseListPage()),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Icon(Icons.fact_check_rounded, color: Colors.white, size: 20),
                  SizedBox(height: 2),
                  Text(
                    'วิชาจริง',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF334155), height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: railItems.length,
              itemBuilder: (context, index) {
                final isSelected = _activeRailIndex == index;
                final item = railItems[index];

                return InkWell(
                  onTap: () {
                    setState(() {
                      _activeRailIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: isSelected
                          ? const Border(left: BorderSide(color: Color(0xFF2563EB), width: 3.5))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconButton(
              tooltip: 'ออกจากระบบ ($teacherName)',
              icon: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF1E293B),
                child: Icon(Icons.logout_rounded, color: Colors.white, size: 16),
              ),
              onPressed: () => AuthService.signOut(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsClassChannelsPanel() {
    return Container(
      width: 270,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Text(
              'ทีมชั้นเรียนของฉัน',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _teacherClasses.length,
              itemBuilder: (context, index) {
                final item = _teacherClasses[index];
                final isSelected = _activeClassIndex == index;
                final color = item['color'] as Color;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        _activeClassIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.08) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item['icon'] as IconData, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['code'] as String,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['name'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item['grade']} • ${item['students']} คน',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IssueBindingCodePage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E40AF)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.qr_code_rounded, size: 18, color: Color(0xFF1E40AF)),
                label: const Text('รหัสผูกผู้ปกครอง', style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsWorkspaceHeader(Map<String, dynamic> currentClass) {
    final Color themeColor = currentClass['color'] as Color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(currentClass['icon'] as IconData, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: themeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                currentClass['code'] as String,
                                style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            Text(
                              'ชั้นเรียน ${currentClass['grade']} • ห้อง ${currentClass['room']}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          currentClass['name'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showCreateAssignmentModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('สั่งการบ้านใหม่', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeamsWorkspaceTabs() {
    final tabs = [
      {'icon': Icons.forum_rounded, 'title': 'กระดานสนทนา'},
      {'icon': Icons.folder_open_rounded, 'title': 'ไฟล์เอกสาร'},
      {'icon': Icons.assignment_outlined, 'title': 'การบ้าน'},
      {'icon': Icons.grade_outlined, 'title': 'เกรดและคะแนน'},
      {'icon': Icons.sensors_rounded, 'title': 'ข้อมูลเซนเซอร์'},
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _activeTabContentIndex == index;
            final tab = tabs[index];

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _activeTabContentIndex = index;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: isSelected ? const Color(0xFF059669) : Colors.transparent,
                  foregroundColor: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(
                  tab['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
                label: Text(
                  tab['title'] as String,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTeamsActiveTabContent(Map<String, dynamic> currentClass) {
    switch (_activeTabContentIndex) {
      case 0:
        return _buildTeamsPostsContent();
      case 1:
        return _buildTeamsFilesContent();
      case 2:
        return _buildTeamsAssignmentsContent();
      case 3:
        return _buildTeamsGradesContent();
      case 4:
        return _buildTeamsTelemetryContent(currentClass['room'] as String);
      default:
        return _buildTeamsPostsContent();
    }
  }

  Widget _buildTeamsPostsContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Announcement Creation Banner for Teachers
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF059669).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ประกาศข่าวสารในชั้นเรียน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                    SizedBox(height: 2),
                    Text('ส่งข้อความแจ้งเตือนสำคัญ เอกสารการเรียน หรือกำหนดการสอบไปยังนักเรียนทุกคน', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateAnnouncementModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('ประกาศใหม่', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),

        ..._postsFeed.map((post) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF059669),
                      child: Icon(Icons.person_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post['author'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A))),
                        Text('${post['role']} • ${post['time']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(post['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                Text(post['body'] as String, style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF334155))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text('${post['likes']} ถูกใจ', style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Text('${post['replies']} ความคิดเห็น', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.reply_rounded, size: 16, color: Color(0xFF059669)),
                      label: const Text('ตอบกลับ', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTeamsFilesContent() {
    final files = [
      {'name': 'คู่มือปฏิบัติการวัดค่า PM2.5 และ CO2.pdf', 'size': '2.8 MB', 'date': 'วันนี้ 09:30 น.'},
      {'name': 'สไลด์การสอน - ระบบนิเวศและเซนเซอร์ AIoT.pptx', 'size': '6.4 MB', 'date': 'เมื่อวานนี้'},
      {'name': 'ผังวงจรการต่อบอร์ด ESP32_Lab3.pdf', 'size': '1.5 MB', 'date': '24 ก.ค. 2026'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final f = files[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF059669), size: 22),
            ),
            title: Text(f['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
            subtitle: Text('ขนาด: ${f['size']} • อัปโหลดเมื่อ: ${f['date']}'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('กำลังดาวน์โหลดไฟล์: ${f['name']}...'),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              },
              child: const Text('ดาวน์โหลด', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamsAssignmentsContent() {
    final assignments = [
      {'title': 'รายงานการทดลองวัดค่า PM2.5 ในห้องเรียน', 'due': 'วันศุกร์นี้ 16:30 น.', 'submitted': '28/35 คน', 'status': 'รอตรวจ'},
      {'title': 'แบบจำลองคำนวณการใช้พลังงานโซลาร์เซลล์', 'due': 'จันทร์หน้า 23:59 น.', 'submitted': '15/35 คน', 'status': 'เปิดรับส่ง'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final a = assignments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment_rounded, color: Color(0xFF059669), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('กำหนดส่ง: ${a['due']} • ส่งงานแล้ว: ${a['submitted']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _showGradeStudentModal({
                    'name': 'นายธีรภัทร สมบูรณ์',
                    'id': '6401',
                    'score1': '18/20',
                    'score2': '14/15',
                  });
                },
                child: const Text('ตรวจคะแนน', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  final List<Map<String, String>> _teacherStudentGrades = [
    {'name': 'นายธีรภัทร สมบูรณ์', 'id': '6401', 'score1': '18/20', 'score2': '14/15', 'total': '32/35 (A)'},
    {'name': 'นางสาวกานต์ดา สุขใจ', 'id': '6402', 'score1': '19/20', 'score2': '15/15', 'total': '34/35 (A)'},
    {'name': 'นายชยพล วิทยา', 'id': '6403', 'score1': '16/20', 'score2': '13/15', 'total': '29/35 (B+)'},
  ];

  Widget _buildTeamsGradesContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('สมุดคะแนนและเกรดประจำคลาส', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
              ElevatedButton.icon(
                onPressed: () {
                  _showGradeStudentModal(_teacherStudentGrades[0]);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('กรอกคะแนนนักเรียน', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DataTable(
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text('เลขประจำตัว', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ชื่อ-นามสกุล นักเรียน', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ใบงานที่ 1 (20)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ใบงานที่ 2 (15)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('คะแนนสะสมรวม', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _teacherStudentGrades.map((s) {
                return DataRow(
                  onSelectChanged: (_) {
                    _showGradeStudentModal(s);
                  },
                  cells: [
                    DataCell(Text(s['id']!)),
                    DataCell(Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(s['score1']!)),
                    DataCell(Text(s['score2']!)),
                    DataCell(Text(s['total']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669)))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsTelemetryContent(String room) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ข้อมูลเซนเซอร์ห้องเรียน $room', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(12)),
                  child: const Text('เชื่อมต่อข้อมูลเรียบร้อย', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTelemetryStatTile('ฝุ่น PM2.5', '14 µg/m³', 'คุณภาพอากาศดี', const Color(0xFF059669))),
                const SizedBox(width: 12),
                Expanded(child: _buildTelemetryStatTile('ก๊าซ CO2', '420 ppm', 'การถ่ายเทอากาศปกติ', const Color(0xFF0284C7))),
                const SizedBox(width: 12),
                Expanded(child: _buildTelemetryStatTile('อุณหภูมิ', '25.8°C', 'อยู่ในเกณฑ์ปกติ', const Color(0xFFD97706))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryStatTile(String label, String value, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: color)),
          const SizedBox(height: 2),
          Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
