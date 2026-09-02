import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorNotificationsPage extends StatefulWidget {
  const DirectorNotificationsPage({super.key});

  @override
  State<DirectorNotificationsPage> createState() =>
      _DirectorNotificationsPageState();
}

class _DirectorNotificationsPageState
    extends State<DirectorNotificationsPage> {
  String searchText = '';
  String selectedCategory = 'ทั้งหมด';
  String selectedPriority = 'ทุกระดับ';
  String selectedStatus = 'ทุกสถานะ';
  String selectedTime = 'ทั้งหมด';

  final List<String> categories = const [
    'ทั้งหมด',
    'เหตุฉุกเฉิน',
    'นักเรียน',
    'ครูและบุคลากร',
    'น้ำ / ไฟ',
    'สิ่งแวดล้อม',
    'ระบบ',
    'รายงาน / ประชุม',
  ];

  final List<String> priorities = const [
    'ทุกระดับ',
    'เร่งด่วน',
    'สูง',
    'ปานกลาง',
    'ข้อมูลทั่วไป',
  ];

  final List<String> statuses = const [
    'ทุกสถานะ',
    'ใหม่',
    'รับทราบแล้ว',
    'กำลังดำเนินการ',
    'แก้ไขแล้ว',
  ];

  final List<String> times = const [
    'ทั้งหมด',
    'วันนี้',
    '24 ชั่วโมงล่าสุด',
    '7 วันล่าสุด',
  ];

  late List<_NotificationData> notifications;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadNotifications();
  }

  void _initNotifications() {
    notifications = [
      const _NotificationData(
        id: 'N001',
        title: 'ตรวจพบเหตุทะเลาะวิวาทบริเวณอาคาร 2',
        summary:
            'กล้อง AI ตรวจพบพฤติกรรมเสี่ยงบริเวณทางเดินชั้น 2 ระบบส่งแจ้งเตือนให้ฝ่ายกิจการนักเรียนแล้ว',
        category: 'เหตุฉุกเฉิน',
        priority: 'เร่งด่วน',
        status: 'ใหม่',
        location: 'อาคาร 2 • ชั้น 2',
        source: 'AI Camera • CAM-B2-02',
        createdAt: 'วันนี้ • 09:02 น.',
        responsible: 'ฝ่ายกิจการนักเรียน',
        action:
            'ตรวจสอบพื้นที่ทันที ติดต่อครูเวร และยืนยันสถานการณ์ในระบบ',
        detail:
            'ระบบวิเคราะห์ภาพตรวจพบการเคลื่อนไหวที่เข้าข่ายทะเลาะวิวาทต่อเนื่องประมาณ 18 วินาที มีนักเรียนอยู่ในบริเวณ 6 คน ระบบบันทึกเหตุการณ์และส่งต่อให้เจ้าหน้าที่ที่เกี่ยวข้องแล้ว',
        icon: Icons.warning_amber_rounded,
        color: AppPalette.danger,
        isUnread: true,
      ),
      const _NotificationData(
        id: 'N002',
        title: 'นักเรียน ม.6/1 ขาดเรียนสูงกว่าค่าเฉลี่ย',
        summary:
            'วันนี้มีนักเรียนขาดเรียน 7 คน คิดเป็นอัตราการมาเรียนประมาณ 86% ต่ำกว่าค่าเฉลี่ยระดับชั้น',
        category: 'นักเรียน',
        priority: 'สูง',
        status: 'รับทราบแล้ว',
        location: 'ม.6/1',
        source: 'ระบบเช็กชื่อ',
        createdAt: 'วันนี้ • 08:45 น.',
        responsible: 'ครูประจำชั้น ม.6/1',
        action:
            'ตรวจสอบรายชื่อนักเรียนขาดเรียนต่อเนื่อง และประสานผู้ปกครองในรายที่เกินเกณฑ์',
        detail:
            'นักเรียนขาดเรียน 7 คน โดย 3 คนมีประวัติขาดเรียนต่อเนื่องในช่วง 7 วันที่ผ่านมา ระบบแนะนำให้ครูประจำชั้นตรวจสอบสาเหตุและบันทึกผลการติดตาม',
        icon: Icons.person_off_rounded,
        color: AppPalette.warning,
        isUnread: true,
      ),
      const _NotificationData(
        id: 'N003',
        title: 'การใช้น้ำอาคาร 2 สูงผิดปกติ',
        summary:
            'ปริมาณการใช้น้ำสูงกว่าค่าเฉลี่ยช่วงเวลาเดียวกันประมาณ 28% พบความผิดปกติบริเวณชั้น 2-3',
        category: 'น้ำ / ไฟ',
        priority: 'สูง',
        status: 'กำลังดำเนินการ',
        location: 'อาคาร 2 • ชั้น 2-3',
        source: 'Smart Water Meter',
        createdAt: 'วันนี้ • 08:20 น.',
        responsible: 'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
        action:
            'ตรวจจุดใช้น้ำ ห้องน้ำ และระบบท่อ พร้อมบันทึกผลการตรวจในระบบ',
        detail:
            'มิเตอร์น้ำรายอาคารตรวจพบอัตราการใช้น้ำสูงขึ้นต่อเนื่องตั้งแต่ 07:40 น. ปัจจุบันฝ่ายอาคารสถานที่ได้รับเรื่องและกำลังตรวจสอบจุดใช้น้ำสำคัญ',
        icon: Icons.water_drop_rounded,
        color: AppPalette.warning,
        isUnread: false,
      ),
      const _NotificationData(
        id: 'N004',
        title: 'ค่า PM2.5 ห้อง ม.3/2 สูงกว่าเกณฑ์เฝ้าระวัง',
        summary:
            'ค่า PM2.5 วัดได้ 42 µg/m³ ต่อเนื่อง 12 นาที ควรตรวจสอบการระบายอากาศในห้อง',
        category: 'สิ่งแวดล้อม',
        priority: 'ปานกลาง',
        status: 'ใหม่',
        location: 'อาคาร 3 • ห้อง ม.3/2',
        source: 'Air Quality Sensor',
        createdAt: 'วันนี้ • 08:11 น.',
        responsible: 'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
        action:
            'ตรวจสอบเครื่องปรับอากาศ เปิดระบบระบายอากาศ และตรวจค่าอีกครั้งภายใน 15 นาที',
        detail:
            'เซนเซอร์คุณภาพอากาศตรวจพบค่าฝุ่นสูงขึ้นหลังเริ่มเรียนคาบแรก ขณะนี้ยังไม่พบควันหรือก๊าซผิดปกติ',
        icon: Icons.air_rounded,
        color: AppPalette.chartCream,
        isUnread: true,
      ),
      const _NotificationData(
        id: 'N005',
        title: 'มีควันในห้องปฏิบัติการวิทยาศาสตร์',
        summary:
            'เซนเซอร์ตรวจพบควันระดับเฝ้าระวัง ระบบแจ้งครูผู้สอนและเจ้าหน้าที่อาคารแล้ว',
        category: 'เหตุฉุกเฉิน',
        priority: 'เร่งด่วน',
        status: 'กำลังดำเนินการ',
        location: 'อาคาร 1 • ห้อง Lab Science',
        source: 'Smoke Sensor • SMK-LAB-01',
        createdAt: 'วันนี้ • 07:58 น.',
        responsible: 'ครูวิทยาศาสตร์ / ฝ่ายอาคารสถานที่',
        action:
            'ตรวจสอบแหล่งกำเนิดควัน อพยพนักเรียนหากจำเป็น และยืนยันสถานะความปลอดภัย',
        detail:
            'ระบบตรวจพบควันเหนือระดับปกติประมาณ 2 นาที ไม่พบอุณหภูมิสูงผิดปกติ เจ้าหน้าที่กำลังตรวจสอบพื้นที่',
        icon: Icons.sensors_rounded,
        color: AppPalette.danger,
        isUnread: true,
      ),
      const _NotificationData(
        id: 'N006',
        title: 'ครูผู้สอน 2 คนยังไม่บันทึกผลการสอนวันนี้',
        summary:
            'ระบบพบว่ามีคาบเรียนที่จบแล้วแต่ยังไม่มีบันทึกการสอนหรือการมอบหมายงานในระบบ',
        category: 'ครูและบุคลากร',
        priority: 'ปานกลาง',
        status: 'ใหม่',
        location: 'ฝ่ายวิชาการ',
        source: 'ระบบบันทึกการสอน',
        createdAt: 'วันนี้ • 07:35 น.',
        responsible: 'หัวหน้าฝ่ายวิชาการ',
        action:
            'แจ้งเตือนครูผู้สอนให้บันทึกผลการสอนก่อนสิ้นวัน และติดตามหากยังไม่ดำเนินการ',
        detail:
            'พบ 2 รายวิชาที่ข้อมูลไม่ครบ ได้แก่ คณิตศาสตร์ ม.4/1 และภาษาอังกฤษ ม.5/2 ระบบจะส่งแจ้งเตือนซ้ำเวลา 16:00 น.',
        icon: Icons.co_present_rounded,
        color: AppPalette.learningBlue,
        isUnread: false,
      ),
      const _NotificationData(
        id: 'N007',
        title: 'อุปกรณ์ Gateway อาคาร 3 ไม่ตอบสนอง',
        summary:
            'Mini PC Gateway ขาดการเชื่อมต่อกับระบบกลางเกิน 5 นาที อุปกรณ์บางจุดอาจส่งข้อมูลล่าช้า',
        category: 'ระบบ',
        priority: 'สูง',
        status: 'กำลังดำเนินการ',
        location: 'อาคาร 3',
        source: 'System Health Monitor',
        createdAt: 'วันนี้ • 07:18 น.',
        responsible: 'ฝ่ายเทคโนโลยีและระบบ',
        action:
            'ตรวจสอบเครือข่าย Gateway และสถานะ MQTT พร้อมทดสอบการส่งข้อมูลหลังแก้ไข',
        detail:
            'ระบบได้รับข้อมูลครั้งล่าสุดเวลา 07:12 น. อุปกรณ์ปลายทางบางตัวอาจยังทำงานแต่ข้อมูลจะไม่ขึ้น Dashboard จนกว่า Gateway จะกลับมาออนไลน์',
        icon: Icons.dns_rounded,
        color: AppPalette.learningBlue,
        isUnread: true,
      ),
      const _NotificationData(
        id: 'N008',
        title: 'รายงานฝ่ายวิชาการยังรอตรวจ 2 ฉบับ',
        summary:
            'มีรายงาน PDF ประจำสัปดาห์ 2 ฉบับที่ส่งแล้วและยังรอการตรวจจากผู้อำนวยการ',
        category: 'รายงาน / ประชุม',
        priority: 'ข้อมูลทั่วไป',
        status: 'ใหม่',
        location: 'ระบบรายงาน',
        source: 'Report Center',
        createdAt: 'เมื่อวาน • 17:42 น.',
        responsible: 'ผู้อำนวยการโรงเรียน',
        action:
            'เปิดดูรายงาน ตรวจสอบรายละเอียด และเลือกอนุมัติหรือส่งกลับแก้ไข',
        detail:
            'รายงานที่รอตรวจคือ รายงานผลการเรียนประจำสัปดาห์ และรายงานการสอนของครูประจำสัปดาห์ ทั้งสองไฟล์เป็น PDF',
        icon: Icons.description_rounded,
        color: AppPalette.chartPink,
        isUnread: true,
      ),
      const _NotificationData(
        id: 'N009',
        title: 'ประชุมคณะกรรมการสถานศึกษาในอีก 3 วัน',
        summary:
            'ระบบเตือนให้เตรียมรายงานผลการเรียน งบประมาณ ความปลอดภัย และข้อมูลทรัพยากรก่อนประชุม',
        category: 'รายงาน / ประชุม',
        priority: 'ข้อมูลทั่วไป',
        status: 'รับทราบแล้ว',
        location: 'ห้องประชุมใหญ่',
        source: 'ปฏิทินวิชาการ',
        createdAt: 'เมื่อวาน • 16:30 น.',
        responsible: 'ฝ่ายบริหาร',
        action:
            'ตรวจสอบวาระ เอกสารแนบ และรายงานที่ต้องใช้ประกอบการประชุม',
        detail:
            'การประชุมกำหนดวันที่ 25 ส.ค. 2569 เวลา 09:00-11:00 น. มีผู้ตอบรับแล้ว 10 จาก 14 คน',
        icon: Icons.event_rounded,
        color: AppPalette.environmentGreen,
        isUnread: false,
      ),
      const _NotificationData(
        id: 'N010',
        title: 'แก้ไขปัญหาไฟฟ้าอาคาร 1 เรียบร้อยแล้ว',
        summary:
            'ฝ่ายอาคารสถานที่ยืนยันว่าจุดใช้ไฟผิดปกติได้รับการตรวจสอบและกลับสู่ค่าปกติ',
        category: 'น้ำ / ไฟ',
        priority: 'ข้อมูลทั่วไป',
        status: 'แก้ไขแล้ว',
        location: 'อาคาร 1 • ชั้น 1',
        source: 'Smart Energy Meter',
        createdAt: 'เมื่อวาน • 15:05 น.',
        responsible: 'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
        action: 'ไม่ต้องดำเนินการเพิ่มเติม',
        detail:
            'ตรวจพบปลั๊กอุปกรณ์ที่เปิดทิ้งไว้หลังเลิกใช้งาน เจ้าหน้าที่ปิดอุปกรณ์และตรวจค่าการใช้ไฟซ้ำแล้ว',
        icon: Icons.bolt_rounded,
        color: AppPalette.environmentGreen,
        isUnread: false,
      ),
    ];
  }

  Future<void> _loadNotifications() async {
    try {
      final realList = await NotificationService.listMyNotifications();
      if (!mounted || realList.isEmpty) return;
      setState(() {
        notifications = realList.map((n) {
          return _NotificationData(
            id: n.id,
            title: n.title,
            summary: n.body ?? '',
            category: 'ระบบ',
            priority: 'ข้อมูลทั่วไป',
            status: n.isUnread ? 'ใหม่' : 'รับทราบแล้ว',
            location: 'ระบบโรงเรียน',
            source: 'Notification Service',
            createdAt:
                '${n.createdAt.hour.toString().padLeft(2, '0')}:${n.createdAt.minute.toString().padLeft(2, '0')} น.',
            responsible: 'ฝ่ายบริหาร',
            action: 'ตรวจสอบรายละเอียด',
            detail: n.body ?? '',
            icon: Icons.notifications_rounded,
            color: AppPalette.learningBlue,
            isUnread: n.isUnread,
          );
        }).toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifications();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'การแจ้งเตือน',
            subtitle:
                'รวมเหตุการณ์สำคัญที่ผู้อำนวยการควรรับทราบ พร้อมระดับความเร่งด่วน แหล่งที่มา ผู้รับผิดชอบ และสถานะการดำเนินงาน',
          ),
          const SizedBox(height: 14),
          _summaryCards(),
          const SizedBox(height: 16),
          _urgentSection(),
          const SizedBox(height: 16),
          _notificationsSection(filtered),
        ],
      ),
    );
  }

  List<_NotificationData> _filteredNotifications() {
    final query = searchText.trim().toLowerCase();

    return notifications.where((item) {
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.summary.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.source.toLowerCase().contains(query) ||
          item.responsible.toLowerCase().contains(query);

      final matchesCategory =
          selectedCategory == 'ทั้งหมด' ||
          item.category == selectedCategory;

      final matchesPriority =
          selectedPriority == 'ทุกระดับ' ||
          item.priority == selectedPriority;

      final matchesStatus =
          selectedStatus == 'ทุกสถานะ' ||
          item.status == selectedStatus;

      final matchesTime = _matchesTime(item);

      return matchesSearch &&
          matchesCategory &&
          matchesPriority &&
          matchesStatus &&
          matchesTime;
    }).toList();
  }

  bool _matchesTime(_NotificationData item) {
    switch (selectedTime) {
      case 'วันนี้':
        return item.createdAt.startsWith('วันนี้');
      case '24 ชั่วโมงล่าสุด':
        return item.createdAt.startsWith('วันนี้') ||
            item.createdAt.startsWith('เมื่อวาน');
      case '7 วันล่าสุด':
        return true;
      default:
        return true;
    }
  }

  Widget _summaryCards() {
    final unread =
        notifications.where((item) => item.isUnread).length;
    final urgent = notifications
        .where((item) => item.priority == 'เร่งด่วน')
        .length;
    final high = notifications
        .where((item) => item.priority == 'สูง')
        .length;
    final inProgress = notifications
        .where(
          (item) => item.status == 'กำลังดำเนินการ',
        )
        .length;
    final resolved = notifications
        .where((item) => item.status == 'แก้ไขแล้ว')
        .length;
    final today = notifications
        .where(
          (item) => item.createdAt.startsWith('วันนี้'),
        )
        .length;

    final items = [
      _SummaryData(
        title: 'ยังไม่ได้อ่าน',
        value: '$unread',
        subtitle: 'ควรเปิดตรวจสอบ',
        icon: Icons.mark_email_unread_rounded,
        color: AppPalette.softPink,
      ),
      _SummaryData(
        title: 'เร่งด่วน',
        value: '$urgent',
        subtitle: 'ต้องตรวจทันที',
        icon: Icons.warning_amber_rounded,
        color: AppPalette.softPink2,
      ),
      _SummaryData(
        title: 'ระดับสูง',
        value: '$high',
        subtitle: 'ควรติดตาม',
        icon: Icons.priority_high_rounded,
        color: AppPalette.softCream,
      ),
      _SummaryData(
        title: 'กำลังดำเนินการ',
        value: '$inProgress',
        subtitle: 'มีผู้รับผิดชอบแล้ว',
        icon: Icons.sync_rounded,
        color: AppPalette.softBlue,
      ),
      _SummaryData(
        title: 'แก้ไขแล้ว',
        value: '$resolved',
        subtitle: 'ปิดเหตุการณ์แล้ว',
        icon: Icons.task_alt_rounded,
        color: AppPalette.softMint,
      ),
      _SummaryData(
        title: 'วันนี้ทั้งหมด',
        value: '$today',
        subtitle: 'ทุกหมวด',
        icon: Icons.today_rounded,
        color: AppPalette.softBlue,
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
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: columns == 2 ? 126 : 116,
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
                      color:
                          AppPalette.tint(Colors.white, 0.82),
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
                      fontSize: 9.2,
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
                      fontSize: 8.2,
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

  Widget _urgentSection() {
    final urgent = notifications
        .where(
          (item) =>
              item.priority == 'เร่งด่วน' &&
              item.status != 'แก้ไขแล้ว',
        )
        .toList();

    return Container(
      width: double.infinity,
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
                      'ควรตรวจสอบทันที',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'เฉพาะเหตุการณ์ระดับเร่งด่วนที่ยังไม่ปิดเหตุ',
                      style: TextStyle(
                        fontSize: 10,
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
                  color:
                      AppPalette.tint(AppPalette.danger, 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${urgent.length} เหตุการณ์',
                  style: const TextStyle(
                    fontSize: 8.8,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 720) {
                return Column(
                  children: [
                    for (int i = 0;
                        i < urgent.length;
                        i++) ...[
                      _urgentCard(urgent[i]),
                      if (i != urgent.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  for (int i = 0;
                      i < urgent.length;
                      i++) ...[
                    Expanded(
                      child: _urgentCard(urgent[i]),
                    ),
                    if (i != urgent.length - 1)
                      const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _urgentCard(_NotificationData item) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openDetail(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              AppPalette.tint(AppPalette.danger, 0.055),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                AppPalette.tint(AppPalette.danger, 0.17),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: AppPalette.danger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _priorityTag(item.priority),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              item.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(
                  Icons.place_rounded,
                  size: 14,
                  color: AppPalette.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.location,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ),
                Text(
                  item.createdAt,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationsSection(
    List<_NotificationData> filtered,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;

              final title = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'รายการแจ้งเตือนทั้งหมด',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ค้นหา กรอง และตรวจสอบสถานะของเหตุการณ์จากทุกส่วนของโรงเรียน',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              );

              final markAllButton =
                  OutlinedButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(
                  Icons.done_all_rounded,
                  size: 16,
                ),
                label: const Text(
                  'อ่านทั้งหมด',
                  style: TextStyle(fontSize: 9.5),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 9),
                    markAllButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  markAllButton,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _filterArea(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'พบ ${filtered.length} รายการ',
                style: const TextStyle(
                  fontSize: 9.8,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textMuted,
                ),
              ),
              const Spacer(),
              if (_hasActiveFilters())
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 15,
                  ),
                  label: const Text('ล้างตัวกรอง'),
                ),
            ],
          ),
          const SizedBox(height: 7),
          if (filtered.isEmpty)
            _emptyState()
          else
            ...filtered.map(_notificationTile),
        ],
      ),
    );
  }

  Widget _filterArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;

        final search = TextField(
          onChanged: (value) {
            setState(() => searchText = value);
          },
          decoration: InputDecoration(
            hintText:
                'ค้นหาเหตุการณ์ ห้อง อาคาร แหล่งที่มา หรือผู้รับผิดชอบ...',
            hintStyle: const TextStyle(fontSize: 9.3),
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

        final category = _dropdown(
          value: selectedCategory,
          items: categories,
          icon: Icons.category_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedCategory = value);
          },
        );

        final priority = _dropdown(
          value: selectedPriority,
          items: priorities,
          icon: Icons.flag_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedPriority = value);
          },
        );

        final status = _dropdown(
          value: selectedStatus,
          items: statuses,
          icon: Icons.fact_check_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedStatus = value);
          },
        );

        final time = _dropdown(
          value: selectedTime,
          items: times,
          icon: Icons.schedule_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedTime = value);
          },
        );

        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: category),
                  const SizedBox(width: 8),
                  Expanded(child: priority),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: status),
                  const SizedBox(width: 8),
                  Expanded(child: time),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: search,
                ),
                const SizedBox(width: 9),
                Expanded(child: category),
                const SizedBox(width: 9),
                Expanded(child: priority),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: status),
                const SizedBox(width: 9),
                Expanded(child: time),
                const Spacer(flex: 4),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
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
            size: 16,
            color: AppPalette.primaryPink,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 9.3,
                  color: AppPalette.textDark,
                ),
                items: items
                    .map(
                      (item) =>
                          DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _notificationTile(_NotificationData item) {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => _openDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.isUnread
              ? AppPalette.tint(item.color, 0.045)
              : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: item.isUnread
                ? AppPalette.tint(item.color, 0.16)
                : AppPalette.border,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _notificationIcon(item),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _notificationMainInfo(item),
                      ),
                      if (item.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin:
                              const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _priorityTag(item.priority),
                      _statusTag(item.status),
                      _smallTag(
                        item.category,
                        item.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.location} • ${item.createdAt}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                _notificationIcon(item),
                const SizedBox(width: 11),
                Expanded(
                  flex: 3,
                  child: _notificationMainInfo(item),
                ),
                Expanded(
                  child: _listInfo(
                    'หมวด',
                    item.category,
                  ),
                ),
                Expanded(
                  child: _listInfo(
                    'สถานที่',
                    item.location,
                  ),
                ),
                Expanded(
                  child: _listInfo(
                    'ผู้รับผิดชอบ',
                    item.responsible,
                  ),
                ),
                _priorityTag(item.priority),
                const SizedBox(width: 7),
                _statusTag(item.status),
                const SizedBox(width: 7),
                if (item.isUnread)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 4),
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

  Widget _notificationIcon(_NotificationData item) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppPalette.tint(item.color, 0.11),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        item.icon,
        size: 20,
        color: item.color,
      ),
    );
  }

  Widget _notificationMainInfo(
    _NotificationData item,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.4,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${item.createdAt} • ${item.source}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
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
            fontSize: 9.5,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _priorityTag(String priority) {
    final color = _priorityColor(priority);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _statusTag(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
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
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'เร่งด่วน':
        return AppPalette.danger;
      case 'สูง':
        return AppPalette.warning;
      case 'ปานกลาง':
        return AppPalette.learningBlue;
      default:
        return AppPalette.textMuted;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ใหม่':
        return AppPalette.primaryPink;
      case 'รับทราบแล้ว':
        return AppPalette.learningBlue;
      case 'กำลังดำเนินการ':
        return AppPalette.warning;
      case 'แก้ไขแล้ว':
        return AppPalette.success;
      default:
        return AppPalette.textMuted;
    }
  }

  bool _hasActiveFilters() {
    return searchText.isNotEmpty ||
        selectedCategory != 'ทั้งหมด' ||
        selectedPriority != 'ทุกระดับ' ||
        selectedStatus != 'ทุกสถานะ' ||
        selectedTime != 'ทั้งหมด';
  }

  void _clearFilters() {
    setState(() {
      searchText = '';
      selectedCategory = 'ทั้งหมด';
      selectedPriority = 'ทุกระดับ';
      selectedStatus = 'ทุกสถานะ';
      selectedTime = 'ทั้งหมด';
    });
  }

  void _markAllRead() {
    setState(() {
      notifications = notifications
          .map(
            (item) => item.copyWith(isUnread: false),
          )
          .toList();
    });

    _showMessage('ทำเครื่องหมายอ่านทั้งหมดแล้ว');
  }

  void _openDetail(_NotificationData item) {
    final index = notifications
        .indexWhere((element) => element.id == item.id);

    if (index >= 0 && notifications[index].isUnread) {
      setState(() {
        notifications[index] =
            notifications[index].copyWith(
          isUnread: false,
        );
      });
    }

    final current = index >= 0
        ? notifications[index]
        : item;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'NotificationDetailModal',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 240),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      pageBuilder: (dialogContext, anim, secondaryAnim) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                _NotificationData dialogItem = current;

                void updateStatus(String status) {
                  final actualIndex = notifications.indexWhere(
                    (element) => element.id == dialogItem.id,
                  );

                  if (actualIndex < 0) return;

                  setState(() {
                    notifications[actualIndex] =
                        notifications[actualIndex].copyWith(status: status);
                  });

                  dialogItem = notifications[actualIndex];
                  setDialogState(() {});
                }

                return Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 640,
                      maxHeight: 780,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 36,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Banner with category accent tint
                          Container(
                            padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
                            decoration: BoxDecoration(
                              color: dialogItem.color.withValues(alpha: 0.08),
                              border: Border(
                                bottom: BorderSide(
                                  color: dialogItem.color.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: dialogItem.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    dialogItem.icon,
                                    color: dialogItem.color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dialogItem.title,
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'เวลา ${dialogItem.createdAt} • รหัส: ${dialogItem.id}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppPalette.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFF64748B),
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Scrollable Body
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 7,
                                    runSpacing: 7,
                                    children: [
                                      _smallTag(
                                        dialogItem.category,
                                        dialogItem.color,
                                      ),
                                      _priorityTag(
                                        dialogItem.priority,
                                      ),
                                      _statusTag(
                                        dialogItem.status,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _detailSectionTitle('รายละเอียดเหตุการณ์'),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      dialogItem.detail,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        height: 1.5,
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _detailSectionTitle('ข้อมูลการแจ้งเตือน'),
                                  const SizedBox(height: 8),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isCompact = constraints.maxWidth < 450;
                                      final tileWidth = isCompact ? constraints.maxWidth : (constraints.maxWidth - 10) / 2;
                                      return Wrap(
                                        spacing: 10,
                                        runSpacing: 8,
                                        children: [
                                          _detailTile(
                                            width: tileWidth,
                                            icon: Icons.place_rounded,
                                            title: 'สถานที่',
                                            value: dialogItem.location,
                                            color: dialogItem.color,
                                          ),
                                          _detailTile(
                                            width: tileWidth,
                                            icon: Icons.sensors_rounded,
                                            title: 'แหล่งที่มา',
                                            value: dialogItem.source,
                                            color: const Color(0xFF2563EB),
                                          ),
                                          _detailTile(
                                            width: tileWidth,
                                            icon: Icons.person_rounded,
                                            title: 'ผู้รับผิดชอบ',
                                            value: dialogItem.responsible,
                                            color: const Color(0xFF059669),
                                          ),
                                          _detailTile(
                                            width: tileWidth,
                                            icon: Icons.category_rounded,
                                            title: 'หมวดหมู่ & ระดับ',
                                            value: '${dialogItem.category} • ${dialogItem.priority}',
                                            color: const Color(0xFF7C3AED),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _detailSectionTitle('สิ่งที่ควรดำเนินการ'),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: dialogItem.color.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: dialogItem.color.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.assignment_turned_in_rounded,
                                          size: 18,
                                          color: dialogItem.color,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            dialogItem.action,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              height: 1.5,
                                              fontWeight: FontWeight.w600,
                                              color: dialogItem.color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _detailSectionTitle('ลำดับการติดตาม'),
                                  const SizedBox(height: 8),
                                  _timelineItem(
                                    'ระบบสร้างการแจ้งเตือน',
                                    dialogItem.createdAt,
                                    true,
                                  ),
                                  _timelineItem(
                                    'ส่งให้ ${dialogItem.responsible}',
                                    'ส่งอัตโนมัติเรียบร้อย',
                                    true,
                                  ),
                                  _timelineItem(
                                    dialogItem.status == 'แก้ไขแล้ว'
                                        ? 'ปิดเหตุการณ์แล้ว'
                                        : dialogItem.status,
                                    dialogItem.status == 'ใหม่'
                                        ? 'รอดำเนินการ'
                                        : 'อัปเดตล่าสุด',
                                    dialogItem.status != 'ใหม่',
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Footer Actions Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              border: Border(
                                top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                              ),
                            ),
                            child: _detailActions(
                              dialogItem,
                              updateStatus,
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
        );
      },
    );
  }

  Widget _detailActions(
    _NotificationData item,
    ValueChanged<String> updateStatus,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;

        final buttons = <Widget>[
          if (item.status == 'ใหม่')
            OutlinedButton.icon(
              onPressed: () =>
                  updateStatus('รับทราบแล้ว'),
              icon: const Icon(
                Icons.visibility_rounded,
                size: 16,
              ),
              label: const Text('รับทราบ'),
            ),
          if (item.status == 'รับทราบแล้ว')
            OutlinedButton.icon(
              onPressed: () =>
                  updateStatus('กำลังดำเนินการ'),
              icon: const Icon(
                Icons.sync_rounded,
                size: 16,
              ),
              label:
                  const Text('เริ่มดำเนินการ'),
            ),
          if (item.status == 'กำลังดำเนินการ')
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor:
                    AppPalette.environmentGreen,
              ),
              onPressed: () =>
                  updateStatus('แก้ไขแล้ว'),
              icon: const Icon(
                Icons.task_alt_rounded,
                size: 16,
              ),
              label:
                  const Text('ยืนยันแก้ไขแล้ว'),
            ),
          OutlinedButton.icon(
            onPressed: () {
              _showMessage(
                'ส่งแจ้งเตือนซ้ำให้ ${item.responsible} แล้ว',
              );
            },
            icon: const Icon(
              Icons.notifications_active_rounded,
              size: 16,
            ),
            label: const Text('แจ้งเตือนซ้ำ'),
          ),
        ];

        if (compact) {
          return Column(
            children: [
              for (int i = 0;
                  i < buttons.length;
                  i++) ...[
                SizedBox(
                  width: double.infinity,
                  child: buttons[i],
                ),
                if (i != buttons.length - 1)
                  const SizedBox(height: 7),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: buttons,
        );
      },
    );
  }

  Widget _detailSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }



  Widget _detailTile({
    required double width,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(
    String title,
    String subtitle,
    bool completed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: completed
                  ? AppPalette.tint(
                      AppPalette.environmentGreen,
                      0.12,
                    )
                  : AppPalette.softTag,
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed
                  ? Icons.check_rounded
                  : Icons.more_horiz_rounded,
              size: 14,
              color: completed
                  ? AppPalette.environmentGreen
                  : AppPalette.textMuted,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
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
            Icons.notifications_off_rounded,
            size: 34,
            color: AppPalette.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            'ไม่พบการแจ้งเตือนตามเงื่อนไข',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SummaryData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _NotificationData {
  final String id;
  final String title;
  final String summary;
  final String category;
  final String priority;
  final String status;
  final String location;
  final String source;
  final String createdAt;
  final String responsible;
  final String action;
  final String detail;
  final IconData icon;
  final Color color;
  final bool isUnread;

  const _NotificationData({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.priority,
    required this.status,
    required this.location,
    required this.source,
    required this.createdAt,
    required this.responsible,
    required this.action,
    required this.detail,
    required this.icon,
    required this.color,
    required this.isUnread,
  });

  _NotificationData copyWith({
    String? status,
    bool? isUnread,
  }) {
    return _NotificationData(
      id: id,
      title: title,
      summary: summary,
      category: category,
      priority: priority,
      status: status ?? this.status,
      location: location,
      source: source,
      createdAt: createdAt,
      responsible: responsible,
      action: action,
      detail: detail,
      icon: icon,
      color: color,
      isUnread: isUnread ?? this.isUnread,
    );
  }
}
