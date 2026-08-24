import 'package:flutter/material.dart';

import '../data/director_mock_data.dart';
import '../models/director_models.dart';
import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';
import '../widgets/teacher_picker_dialog.dart';

class DirectorMeetingsPage extends StatefulWidget {
  const DirectorMeetingsPage({super.key});

  @override
  State<DirectorMeetingsPage> createState() =>
      _DirectorMeetingsPageState();
}

class _DirectorMeetingsPageState
    extends State<DirectorMeetingsPage> {
  String selectedFilter = 'ทั้งหมด';
  String searchText = '';

  final List<String> filters = const [
    'ทั้งหมด',
    'วันนี้',
    'กำลังจะมาถึง',
    'รอตอบรับ',
    'เสร็จสิ้น',
  ];

  final List<_MeetingItem> meetings = [
    const _MeetingItem(
      id: 'M001',
      title: 'ประชุมฝ่ายบริหารประจำสัปดาห์',
      dateLabel: 'วันนี้',
      dateDetail: '20 ส.ค. 2569',
      time: '09:00 - 10:30',
      location: 'ห้องประชุม 1',
      type: 'ประชุม',
      status: 'ยืนยันแล้ว',
      priority: 'ปกติ',
      organizer: 'ผู้อำนวยการโรงเรียน',
      participants: 8,
      accepted: 8,
      agenda:
          'ติดตามการมาเรียน เหตุฉุกเฉิน การใช้ทรัพยากร และงานที่แต่ละฝ่ายต้องดำเนินการในสัปดาห์นี้',
      note:
          'เตรียม Dashboard ภาพรวมนักเรียน ครูและบุคลากร และข้อมูลน้ำ/ไฟเพื่อใช้ประกอบการประชุม',
      reminder: 'ก่อนประชุม 30 นาที',
      icon: Icons.groups_rounded,
      color: AppPalette.primaryPink,
    ),
    const _MeetingItem(
      id: 'M002',
      title: 'ขอพบหัวหน้าฝ่ายวิชาการ',
      dateLabel: 'วันนี้',
      dateDetail: '20 ส.ค. 2569',
      time: '11:00 - 11:30',
      location: 'ห้องผู้อำนวยการ',
      type: 'ขอพบ',
      status: 'ยืนยันแล้ว',
      priority: 'สำคัญ',
      organizer: 'ผู้อำนวยการโรงเรียน',
      participants: 1,
      accepted: 1,
      agenda:
          'หารือเรื่องนักเรียนที่มีผลการเรียนต่ำกว่าเกณฑ์และแผนสอนเสริมก่อนสอบกลางภาค',
      note:
          'ขอรายชื่อนักเรียนที่ต้องติดตามและแผนสอนเสริมของแต่ละกลุ่มสาระ',
      reminder: 'ก่อนนัด 15 นาที',
      icon: Icons.person_search_rounded,
      color: AppPalette.learningBlue,
    ),
    const _MeetingItem(
      id: 'M003',
      title: 'ประชุมหัวหน้ากลุ่มสาระ',
      dateLabel: 'วันนี้',
      dateDetail: '20 ส.ค. 2569',
      time: '13:00 - 14:30',
      location: 'ห้องวิชาการ',
      type: 'ประชุม',
      status: 'รอตอบรับ',
      priority: 'ปกติ',
      organizer: 'ฝ่ายวิชาการ',
      participants: 8,
      accepted: 6,
      agenda:
          'สรุปผลการสอน ปัญหานักเรียน และเตรียมแผนประเมินผลกลางภาค',
      note:
          'ยังมีหัวหน้ากลุ่มสาระ 2 คนที่ยังไม่ตอบรับคำเชิญ',
      reminder: 'ก่อนประชุม 1 ชั่วโมง',
      icon: Icons.co_present_rounded,
      color: AppPalette.chartPink,
    ),
    const _MeetingItem(
      id: 'M004',
      title: 'ประชุมติดตามอาคาร 2',
      dateLabel: 'พรุ่งนี้',
      dateDetail: '21 ส.ค. 2569',
      time: '10:00 - 10:45',
      location: 'ห้องประชุมเล็ก',
      type: 'ประชุม',
      status: 'ยืนยันแล้ว',
      priority: 'สำคัญ',
      organizer: 'ฝ่ายอาคารสถานที่',
      participants: 5,
      accepted: 5,
      agenda:
          'ติดตามสาเหตุการใช้น้ำสูงผิดปกติ อาคาร 2 และแผนตรวจสอบระบบท่อ/จุดใช้น้ำ',
      note:
          'แนบข้อมูลแนวโน้มการใช้น้ำรายวันและจุดที่มีการใช้สูงกว่าค่าเฉลี่ย',
      reminder: 'ก่อนประชุม 30 นาที',
      icon: Icons.water_drop_rounded,
      color: AppPalette.warning,
    ),
    const _MeetingItem(
      id: 'M005',
      title: 'ประชุมคณะกรรมการสถานศึกษา',
      dateLabel: 'สัปดาห์หน้า',
      dateDetail: '25 ส.ค. 2569',
      time: '09:00 - 11:00',
      location: 'ห้องประชุมใหญ่',
      type: 'ประชุม',
      status: 'รอตอบรับ',
      priority: 'สำคัญ',
      organizer: 'ผู้อำนวยการโรงเรียน',
      participants: 14,
      accepted: 10,
      agenda:
          'รายงานผลการดำเนินงาน งบประมาณ ผลการเรียน ความปลอดภัย และแผนพัฒนาโรงเรียน',
      note:
          'ต้องเตรียมรายงานสรุปประจำเดือนและเอกสารประกอบวาระการประชุม',
      reminder: 'ก่อนประชุม 1 วัน',
      icon: Icons.account_balance_rounded,
      color: AppPalette.environmentGreen,
    ),
    const _MeetingItem(
      id: 'M006',
      title: 'สรุปประชุมกิจการนักเรียน',
      dateLabel: 'เสร็จสิ้น',
      dateDetail: '18 ส.ค. 2569',
      time: '15:00 - 16:00',
      location: 'ห้องกิจการนักเรียน',
      type: 'ประชุม',
      status: 'เสร็จสิ้น',
      priority: 'ปกติ',
      organizer: 'ฝ่ายกิจการนักเรียน',
      participants: 6,
      accepted: 6,
      agenda:
          'ติดตามการขาดเรียน พฤติกรรม และระบบดูแลช่วยเหลือนักเรียน',
      note:
          'มอบหมายให้ครูประจำชั้นติดตามนักเรียนขาดเรียนต่อเนื่อง 11 คน',
      reminder: '-',
      icon: Icons.fact_check_rounded,
      color: AppPalette.chartCream,
    ),
  ];

  final List<_MeetingRequest> requests = [
    const _MeetingRequest(
      name: 'นางสาวอรทัย พัฒนกิจ',
      position: 'หัวหน้ากลุ่มสาระคณิตศาสตร์',
      department: 'ฝ่ายวิชาการ',
      topic: 'ขอหารือเรื่องแผนสอนเสริมนักเรียน ม.5',
      detail:
          'ต้องการขอพบเพื่อเสนอแผนสอนเสริมและขออนุมัติปรับตารางกิจกรรมก่อนสอบกลางภาค',
      requestedTime: 'วันนี้ 14:30 น.',
      waiting: 'รอมา 18 นาที',
      priority: 'ปกติ',
      color: AppPalette.learningBlue,
    ),
    const _MeetingRequest(
      name: 'นายประสิทธิ์ ช่างดี',
      position: 'เจ้าหน้าที่อาคารสถานที่',
      department: 'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
      topic: 'รายงานผลตรวจระบบน้ำอาคาร 2',
      detail:
          'พบจุดที่ควรตรวจเพิ่มเติม 2 จุด ต้องการรายงานข้อมูลให้ผู้อำนวยการทราบก่อนดำเนินการซ่อม',
      requestedTime: 'วันนี้ 15:30 น.',
      waiting: 'รอมา 9 นาที',
      priority: 'สำคัญ',
      color: AppPalette.warning,
    ),
    const _MeetingRequest(
      name: 'นายธนกฤต ระบบดี',
      position: 'เจ้าหน้าที่ระบบสารสนเทศ',
      department: 'ฝ่ายเทคโนโลยีและระบบ',
      topic: 'ขออนุมัติช่วงเวลาปรับปรุงระบบ',
      detail:
          'ต้องการปรับปรุง Dashboard หลังเลิกเรียนประมาณ 30 นาที และขอแจ้งช่วงเวลาที่ระบบอาจไม่พร้อมใช้งาน',
      requestedTime: 'พรุ่งนี้ 09:30 น.',
      waiting: 'ส่งเมื่อ 16:20 น.',
      priority: 'ปกติ',
      color: AppPalette.environmentGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredMeetings = _filteredMeetings();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'ประชุม / ขอพบ',
            subtitle:
                'จัดการประชุม นัดหมาย ขอพบครูและบุคลากร ดูผู้ตอบรับ คำขอเข้าพบ การแจ้งเตือน และประวัติการประชุมในหน้าเดียว',
          ),
          const SizedBox(height: 14),
          _summaryCards(),
          const SizedBox(height: 16),
          _quickActions(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 980) {
                return Column(
                  children: [
                    _todayScheduleCard(),
                    const SizedBox(height: 16),
                    _meetingRequestsCard(),
                  ],
                );
              }

              return SizedBox(
                height: 660,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _todayScheduleCard(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _meetingRequestsCard(),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _allMeetingsSection(filteredMeetings),
        ],
      ),
    );
  }

  List<_MeetingItem> _filteredMeetings() {
    final query = searchText.trim().toLowerCase();

    return meetings.where((meeting) {
      final matchesSearch = query.isEmpty ||
          meeting.title.toLowerCase().contains(query) ||
          meeting.location.toLowerCase().contains(query) ||
          meeting.organizer.toLowerCase().contains(query) ||
          meeting.type.toLowerCase().contains(query);

      bool matchesFilter = true;
      switch (selectedFilter) {
        case 'วันนี้':
          matchesFilter = meeting.dateLabel == 'วันนี้';
          break;
        case 'กำลังจะมาถึง':
          matchesFilter =
              meeting.dateLabel != 'เสร็จสิ้น' &&
              meeting.status != 'เสร็จสิ้น';
          break;
        case 'รอตอบรับ':
          matchesFilter = meeting.status == 'รอตอบรับ';
          break;
        case 'เสร็จสิ้น':
          matchesFilter = meeting.status == 'เสร็จสิ้น';
          break;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _summaryCards() {
    const items = [
      _MeetingSummary(
        title: 'นัดหมายวันนี้',
        value: '3',
        subtitle: 'ประชุม 2 • ขอพบ 1',
        icon: Icons.event_rounded,
        color: AppPalette.softPink,
      ),
      _MeetingSummary(
        title: 'รอตอบรับ',
        value: '6',
        subtitle: 'จาก 2 การประชุม',
        icon: Icons.mark_email_unread_rounded,
        color: AppPalette.softCream,
      ),
      _MeetingSummary(
        title: 'คำขอเข้าพบ',
        value: '3',
        subtitle: 'สำคัญ 1 รายการ',
        icon: Icons.person_search_rounded,
        color: AppPalette.softBlue,
      ),
      _MeetingSummary(
        title: 'ประชุมสัปดาห์นี้',
        value: '7',
        subtitle: 'เสร็จแล้ว 3',
        icon: Icons.groups_rounded,
        color: AppPalette.softMint,
      ),
      _MeetingSummary(
        title: 'เวลาประชุมรวม',
        value: '6.5 ชม.',
        subtitle: 'สัปดาห์ปัจจุบัน',
        icon: Icons.schedule_rounded,
        color: AppPalette.softPink2,
      ),
      _MeetingSummary(
        title: 'อัตราตอบรับ',
        value: '91%',
        subtitle: 'เฉลี่ย 30 วัน',
        icon: Icons.how_to_reg_rounded,
        color: AppPalette.softMint,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 6;
        if (constraints.maxWidth < 700) {
          columns = 2;
        } else if (constraints.maxWidth < 1120) {
          columns = 3;
        }

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: columns == 2 ? 124 : 116,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: AppPalette.tint(Colors.white, 0.82),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 17,
                      color: AppPalette.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.3,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.3,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สร้างนัดหมายใหม่',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'เลือกประชุมทั้งโรงเรียน หลายคน รายฝ่าย หรือขอพบรายบุคคล',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;

              final actions = [
                _actionCard(
                  title: 'ประชุมครูทั้งหมด',
                  subtitle: 'เลือก All และส่งคำเชิญทั้งคณะครู',
                  icon: Icons.groups_2_rounded,
                  color: AppPalette.primaryPink,
                  background: AppPalette.softPink,
                  onTap: () => _createAllTeachersMeeting(),
                ),
                _actionCard(
                  title: 'เลือกผู้เข้าร่วม',
                  subtitle: 'ค้นหาชื่อ / กลุ่มสาระ / เลือกหลายคน',
                  icon: Icons.group_add_rounded,
                  color: AppPalette.learningBlue,
                  background: AppPalette.softBlue,
                  onTap: () => _pickTeachersForMeeting(),
                ),
                _actionCard(
                  title: 'ขอพบรายบุคคล',
                  subtitle: 'ค้นหาและเลือกครูหรือบุคลากร 1 คน',
                  icon: Icons.person_search_rounded,
                  color: AppPalette.environmentGreen,
                  background: AppPalette.softMint,
                  onTap: () => _pickOnePerson(),
                ),
              ];

              if (narrow) {
                return Column(
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      actions[i],
                      if (i != actions.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: actions[0]),
                  const SizedBox(width: 10),
                  Expanded(child: actions[1]),
                  const SizedBox(width: 10),
                  Expanded(child: actions[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppPalette.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayScheduleCard() {
    final today = meetings
        .where((meeting) => meeting.dateLabel == 'วันนี้')
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ตารางประชุมและนัดหมายวันนี้',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ดูเวลา สถานที่ ผู้เข้าร่วม และสถานะของแต่ละนัด',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...today.map(_scheduleTile),
        ],
      ),
    );
  }

  Widget _scheduleTile(_MeetingItem item) {
    final statusColor = _meetingStatusColor(item.status);

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => _showMeetingDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppPalette.tint(item.color, 0.06),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: AppPalette.tint(item.color, 0.14),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Column(
                children: [
                  Text(
                    item.time.split(' - ').first,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.type,
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 62,
              color: AppPalette.border,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 11.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.time} • ${item.location}',
                    style: const TextStyle(
                      fontSize: 9.2,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'ตอบรับ ${item.accepted}/${item.participants} คน',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppPalette.tint(statusColor, 0.11),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.status,
                style: TextStyle(
                  fontSize: 8.4,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meetingRequestsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'คำขอเข้าพบผู้อำนวยการ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'คำขอจากครูและบุคลากรที่รอพิจารณา',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.primaryPinkSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${requests.length} รายการ',
                  style: const TextStyle(
                    fontSize: 8.8,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.primaryPinkDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...requests.map(_requestTile),
        ],
      ),
    );
  }

  Widget _requestTile(_MeetingRequest request) {
    final important = request.priority == 'สำคัญ';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.tint(request.color, 0.06),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppPalette.tint(request.color, 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor:
                    AppPalette.tint(request.color, 0.12),
                child: Text(
                  _firstLetter(request.name),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: request.color,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style: const TextStyle(
                        fontSize: 10.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      request.position,
                      style: const TextStyle(
                        fontSize: 8.8,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (important)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.tint(
                      AppPalette.warning,
                      0.12,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'สำคัญ',
                    style: TextStyle(
                      fontSize: 8.2,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.warning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            request.topic,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            request.detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              height: 1.4,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppPalette.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${request.requestedTime} • ${request.waiting}',
                  style: const TextStyle(
                    fontSize: 8.6,
                    color: AppPalette.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _declineRequest(request),
                  child: const Text(
                    'ปฏิเสธ',
                    style: TextStyle(fontSize: 9.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        AppPalette.primaryPink,
                  ),
                  onPressed: () =>
                      _acceptRequest(request),
                  child: const Text(
                    'รับนัด',
                    style: TextStyle(fontSize: 9.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _allMeetingsSection(
    List<_MeetingItem> filtered,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายการประชุมและนัดหมายทั้งหมด',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ค้นหา กรองสถานะ และกดดูรายละเอียด วาระ ผู้เข้าร่วม และการแจ้งเตือนได้',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          _searchAndFilter(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'พบ ${filtered.length} รายการ',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                selectedFilter,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppPalette.primaryPinkDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (filtered.isEmpty)
            _emptyMeetingList()
          else
            ...filtered.map(_meetingListTile),
        ],
      ),
    );
  }

  Widget _searchAndFilter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        final search = TextField(
          onChanged: (value) {
            setState(() => searchText = value);
          },
          decoration: InputDecoration(
            hintText:
                'ค้นหาหัวข้อ สถานที่ ผู้จัด หรือประเภทนัดหมาย...',
            hintStyle: const TextStyle(fontSize: 9.5),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppPalette.primaryPink,
            ),
            filled: true,
            fillColor: AppPalette.pageBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppPalette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppPalette.border),
            ),
          ),
        );

        final filter = Container(
          height: 48,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: AppPalette.pageBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPalette.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedFilter,
              isExpanded: true,
              items: filters
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedFilter = value);
              },
            ),
          ),
        );

        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: 8),
              filter,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: search,
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 180,
              child: filter,
            ),
          ],
        );
      },
    );
  }

  Widget _meetingListTile(_MeetingItem item) {
    final statusColor = _meetingStatusColor(item.status);

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => _showMeetingDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppPalette.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _meetingIcon(item),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _meetingMainInfo(item),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _smallTag(
                        item.dateDetail,
                        AppPalette.learningBlue,
                      ),
                      _smallTag(
                        item.time,
                        item.color,
                      ),
                      _smallTag(
                        item.status,
                        statusColor,
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                _meetingIcon(item),
                const SizedBox(width: 11),
                Expanded(
                  flex: 3,
                  child: _meetingMainInfo(item),
                ),
                Expanded(
                  child: _listInfo(
                    'วันที่',
                    item.dateDetail,
                  ),
                ),
                Expanded(
                  child: _listInfo(
                    'เวลา',
                    item.time,
                  ),
                ),
                Expanded(
                  child: _listInfo(
                    'ผู้เข้าร่วม',
                    '${item.accepted}/${item.participants}',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        AppPalette.tint(statusColor, 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppPalette.textMuted,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _meetingIcon(_MeetingItem item) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppPalette.tint(item.color, 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        item.icon,
        color: item.color,
        size: 20,
      ),
    );
  }

  Widget _meetingMainInfo(_MeetingItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${item.type} • ${item.location} • ${item.organizer}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8.8,
            color: AppPalette.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _listInfo(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 8.2,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _smallTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.3,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _emptyMeetingList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 34,
            color: AppPalette.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            'ไม่พบรายการตามเงื่อนไข',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _meetingStatusColor(String status) {
    switch (status) {
      case 'รอตอบรับ':
        return AppPalette.warning;
      case 'เสร็จสิ้น':
        return AppPalette.success;
      case 'ยกเลิก':
        return AppPalette.danger;
      default:
        return AppPalette.learningBlue;
    }
  }

  String _firstLetter(String name) {
    final clean = name
        .replaceFirst('นาย', '')
        .replaceFirst('นางสาว', '')
        .replaceFirst('นาง', '')
        .replaceFirst('ครู', '')
        .trim();

    return clean.isEmpty ? '?' : clean.substring(0, 1);
  }

  Future<void> _createAllTeachersMeeting() async {
    final allTeachers = DirectorMockData.teachers;

    await _showCreateScheduleDialog(
      isMeeting: true,
      selected: allTeachers,
      allSelected: true,
    );
  }

  Future<void> _pickTeachersForMeeting() async {
    final result = await showTeacherPickerDialog(
      context: context,
      title: 'เลือกผู้เข้าร่วมประชุม',
      allowMultiple: true,
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    await _showCreateScheduleDialog(
      isMeeting: true,
      selected: result,
      allSelected: false,
    );
  }

  Future<void> _pickOnePerson() async {
    final result = await showTeacherPickerDialog(
      context: context,
      title: 'เลือกครูหรือบุคลากรที่ต้องการขอพบ',
      allowMultiple: false,
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    await _showCreateScheduleDialog(
      isMeeting: false,
      selected: result,
      allSelected: false,
    );
  }

  Future<void> _showCreateScheduleDialog({
    required bool isMeeting,
    required List<TeacherData> selected,
    required bool allSelected,
  }) async {
    final titleController = TextEditingController(
      text: isMeeting ? 'ประชุม' : 'ขอพบ',
    );
    final agendaController = TextEditingController();
    final locationController = TextEditingController(
      text: isMeeting
          ? 'ห้องประชุม 1'
          : 'ห้องผู้อำนวยการ',
    );
    final noteController = TextEditingController();

    DateTime selectedDate = DateTime(2026, 8, 20);
    TimeOfDay selectedTime = const TimeOfDay(
      hour: 14,
      minute: 0,
    );
    String duration = isMeeting ? '60 นาที' : '30 นาที';
    String reminder = 'ก่อน 30 นาที';
    String meetingMode = 'On-site';
    String priority = 'ปกติ';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720,
                  maxHeight: 760,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppPalette.primaryPinkSoft,
                              borderRadius:
                                  BorderRadius.circular(13),
                            ),
                            child: Icon(
                              isMeeting
                                  ? Icons.groups_rounded
                                  : Icons.person_search_rounded,
                              color: AppPalette.primaryPink,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isMeeting
                                  ? 'สร้างการประชุม'
                                  : 'สร้างนัดขอพบ',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext),
                            icon:
                                const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _formField(
                                controller: titleController,
                                label: 'หัวข้อ',
                                icon: Icons.title_rounded,
                              ),
                              const SizedBox(height: 10),
                              _formField(
                                controller: agendaController,
                                label: 'วาระ / เรื่องที่ต้องการหารือ',
                                icon: Icons.notes_rounded,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 10),
                              _formField(
                                controller:
                                    locationController,
                                label: 'สถานที่ / ห้องประชุม / Link Online',
                                icon: Icons.place_rounded,
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder:
                                    (context, constraints) {
                                  final compact =
                                      constraints.maxWidth <
                                          560;

                                  final dateButton =
                                      _dialogSelectBox(
                                    icon: Icons
                                        .calendar_today_rounded,
                                    label: 'วันที่',
                                    value:
                                        '${selectedDate.day}/'
                                        '${selectedDate.month}/'
                                        '${selectedDate.year + 543}',
                                    onTap: () async {
                                      final date =
                                          await showDatePicker(
                                        context: context,
                                        initialDate:
                                            selectedDate,
                                        firstDate:
                                            DateTime(2026),
                                        lastDate:
                                            DateTime(2027),
                                      );

                                      if (date == null) return;
                                      setDialogState(
                                        () =>
                                            selectedDate = date,
                                      );
                                    },
                                  );

                                  final timeButton =
                                      _dialogSelectBox(
                                    icon:
                                        Icons.schedule_rounded,
                                    label: 'เวลา',
                                    value: selectedTime
                                        .format(context),
                                    onTap: () async {
                                      final time =
                                          await showTimePicker(
                                        context: context,
                                        initialTime:
                                            selectedTime,
                                      );

                                      if (time == null) return;
                                      setDialogState(
                                        () =>
                                            selectedTime = time,
                                      );
                                    },
                                  );

                                  if (compact) {
                                    return Column(
                                      children: [
                                        dateButton,
                                        const SizedBox(
                                            height: 9),
                                        timeButton,
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(
                                          child: dateButton),
                                      const SizedBox(width: 9),
                                      Expanded(
                                          child: timeButton),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _dialogDropdown(
                                label: 'ระยะเวลา',
                                value: duration,
                                items: const [
                                  '15 นาที',
                                  '30 นาที',
                                  '45 นาที',
                                  '60 นาที',
                                  '90 นาที',
                                  '120 นาที',
                                ],
                                icon: Icons.timer_rounded,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setDialogState(
                                    () => duration = value,
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _dialogDropdown(
                                label: 'รูปแบบการประชุม',
                                value: meetingMode,
                                items: const [
                                  'On-site',
                                  'Online',
                                  'Hybrid',
                                ],
                                icon:
                                    Icons.video_call_rounded,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setDialogState(
                                    () => meetingMode = value,
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _dialogDropdown(
                                label: 'แจ้งเตือน',
                                value: reminder,
                                items: const [
                                  'ก่อน 15 นาที',
                                  'ก่อน 30 นาที',
                                  'ก่อน 1 ชั่วโมง',
                                  'ก่อน 1 วัน',
                                ],
                                icon: Icons
                                    .notifications_active_rounded,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setDialogState(
                                    () => reminder = value,
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _dialogDropdown(
                                label: 'ความสำคัญ',
                                value: priority,
                                items: const [
                                  'ปกติ',
                                  'สำคัญ',
                                  'เร่งด่วน',
                                ],
                                icon:
                                    Icons.flag_rounded,
                                onChanged: (value) {
                                  if (value == null) return;
                                  setDialogState(
                                    () => priority = value,
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _formField(
                                controller: noteController,
                                label: 'หมายเหตุ / สิ่งที่ต้องเตรียม',
                                icon:
                                    Icons.sticky_note_2_rounded,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppPalette.pageBg,
                                  borderRadius:
                                      BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      allSelected
                                          ? 'ผู้เข้าร่วม: ครูทั้งหมด'
                                          : 'ผู้เข้าร่วม ${selected.length} คน',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: selected
                                          .take(10)
                                          .map(
                                            (person) => Chip(
                                              visualDensity:
                                                  VisualDensity
                                                      .compact,
                                              label: Text(
                                                person.name,
                                                style:
                                                    const TextStyle(
                                                  fontSize: 8.8,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    if (selected.length > 10)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(
                                          top: 6,
                                        ),
                                        child: Text(
                                          '+ อีก ${selected.length - 10} คน',
                                          style: const TextStyle(
                                            fontSize: 8.8,
                                            color: AppPalette
                                                .textMuted,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext),
                              child: const Text('ยกเลิก'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    AppPalette.primaryPink,
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _showSuccessMessage(
                                  isMeeting
                                      ? 'สร้างการประชุมและส่งคำเชิญให้ ${selected.length} คนแล้ว'
                                      : 'สร้างนัดหมายกับ ${selected.first.name} แล้ว',
                                );
                              },
                              icon: const Icon(
                                Icons.send_rounded,
                                size: 17,
                              ),
                              label: const Text('ส่งคำเชิญ'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    agendaController.dispose();
    locationController.dispose();
    noteController.dispose();
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: AppPalette.primaryPink,
        ),
        filled: true,
        fillColor: AppPalette.pageBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppPalette.border),
        ),
      ),
    );
  }

  Widget _dialogDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppPalette.primaryPink,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          '$label: $item',
                          style:
                              const TextStyle(fontSize: 9.8),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogSelectBox({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: AppPalette.pageBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppPalette.primaryPink,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 8.2,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMeetingDetail(_MeetingItem item) {
    final statusColor = _meetingStatusColor(item.status);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppPalette.tint(item.color, 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _detailStatusTag(
                        item.type,
                        item.color,
                      ),
                      const SizedBox(width: 6),
                      _detailStatusTag(
                        item.status,
                        statusColor,
                      ),
                      const SizedBox(width: 6),
                      _detailStatusTag(
                        item.priority,
                        item.priority == 'สำคัญ'
                            ? AppPalette.warning
                            : AppPalette.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailRow(
                    'วันที่',
                    item.dateDetail,
                    Icons.calendar_today_rounded,
                  ),
                  _detailRow(
                    'เวลา',
                    item.time,
                    Icons.schedule_rounded,
                  ),
                  _detailRow(
                    'สถานที่',
                    item.location,
                    Icons.place_rounded,
                  ),
                  _detailRow(
                    'ผู้จัด',
                    item.organizer,
                    Icons.person_rounded,
                  ),
                  _detailRow(
                    'ผู้เข้าร่วม',
                    '${item.accepted}/${item.participants} คนตอบรับ',
                    Icons.groups_rounded,
                  ),
                  _detailRow(
                    'การแจ้งเตือน',
                    item.reminder,
                    Icons.notifications_active_rounded,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'วาระ / เรื่องที่หารือ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.agenda,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'หมายเหตุ / สิ่งที่ต้องเตรียม',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.note,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (item.status != 'เสร็จสิ้น')
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showSuccessMessage(
                    'ส่งการแจ้งเตือนซ้ำสำหรับ "${item.title}" แล้ว',
                  );
                },
                icon: const Icon(
                  Icons.notifications_active_rounded,
                  size: 16,
                ),
                label: const Text('แจ้งเตือนซ้ำ'),
              ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailStatusTag(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _detailRow(
    String title,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: AppPalette.primaryPink,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _acceptRequest(_MeetingRequest request) {
    _showSuccessMessage(
      'รับนัด "${request.topic}" กับ ${request.name} แล้ว',
    );
  }

  void _declineRequest(_MeetingRequest request) {
    _showSuccessMessage(
      'ปฏิเสธคำขอ "${request.topic}" แล้ว',
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MeetingSummary {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MeetingSummary({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _MeetingItem {
  final String id;
  final String title;
  final String dateLabel;
  final String dateDetail;
  final String time;
  final String location;
  final String type;
  final String status;
  final String priority;
  final String organizer;
  final int participants;
  final int accepted;
  final String agenda;
  final String note;
  final String reminder;
  final IconData icon;
  final Color color;

  const _MeetingItem({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.dateDetail,
    required this.time,
    required this.location,
    required this.type,
    required this.status,
    required this.priority,
    required this.organizer,
    required this.participants,
    required this.accepted,
    required this.agenda,
    required this.note,
    required this.reminder,
    required this.icon,
    required this.color,
  });
}

class _MeetingRequest {
  final String name;
  final String position;
  final String department;
  final String topic;
  final String detail;
  final String requestedTime;
  final String waiting;
  final String priority;
  final Color color;

  const _MeetingRequest({
    required this.name,
    required this.position,
    required this.department,
    required this.topic,
    required this.detail,
    required this.requestedTime,
    required this.waiting,
    required this.priority,
    required this.color,
  });
}
