import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorEmergencyPage extends StatefulWidget {
  const DirectorEmergencyPage({super.key});

  @override
  State<DirectorEmergencyPage> createState() =>
      _DirectorEmergencyPageState();
}

class _DirectorEmergencyPageState
    extends State<DirectorEmergencyPage> {
  String selectedFilter = 'ทั้งหมด';
  String searchText = '';

  bool sosAccepted = false;
  bool sosResolved = false;

  final List<String> filters = const [
    'ทั้งหมด',
    'กำลังเกิดเหตุ',
    'รับเรื่องแล้ว',
    'กำลังช่วยเหลือ',
    'ปิดเหตุแล้ว',
  ];

  final List<_EmergencyEvent> events = const [
    _EmergencyEvent(
      id: 'SOS-20260821-001',
      title: 'SOS จากนักเรียน ห้อง ม.3/2',
      type: 'SOS',
      location: 'อาคาร 3 • ชั้น 2 • ห้อง ม.3/2',
      time: 'วันนี้ • 10:42 น.',
      reporter: 'นักเรียน ม.3/2',
      source: 'ปุ่ม SOS ในห้องเรียน',
      status: 'กำลังเกิดเหตุ',
      priority: 'เร่งด่วน',
      description:
          'มีการกดปุ่ม SOS ภายในห้องเรียน ระบบส่งตำแหน่งและแจ้งเตือนไปยังผู้อำนวยการ ครูเวร และฝ่ายกิจการนักเรียน',
      action:
          'รับ SOS เพื่อล็อกผู้รับผิดชอบ ตรวจสอบกล้อง/พื้นที่ และประสานครูเวรเข้าตรวจสอบทันที',
      icon: Icons.notifications_active_rounded,
      color: AppPalette.danger,
    ),
    _EmergencyEvent(
      id: 'EVT-20260821-018',
      title: 'ตรวจพบเหตุทะเลาะวิวาท',
      type: 'ทะเลาะวิวาท',
      location: 'อาคาร 2 • ชั้น 3',
      time: 'วันนี้ • 10:24 น.',
      reporter: 'AI Camera',
      source: 'CAM-B2-03',
      status: 'กำลังช่วยเหลือ',
      priority: 'สูง',
      description:
          'กล้อง AI ตรวจพบการเคลื่อนไหวที่เข้าข่ายทะเลาะวิวาทต่อเนื่อง ระบบแจ้งครูเวรและฝ่ายกิจการนักเรียนแล้ว',
      action:
          'ตรวจสอบสถานการณ์ แยกนักเรียนออกจากพื้นที่ และบันทึกผลการดำเนินการ',
      icon: Icons.sports_martial_arts_rounded,
      color: AppPalette.danger,
    ),
    _EmergencyEvent(
      id: 'EVT-20260821-017',
      title: 'ตรวจพบนักเรียนล้ม',
      type: 'ล้ม / หมดสติ',
      location: 'อาคาร 1 • ชั้น 2',
      time: 'วันนี้ • 09:51 น.',
      reporter: 'AI Camera',
      source: 'CAM-B1-06',
      status: 'รับเรื่องแล้ว',
      priority: 'สูง',
      description:
          'ระบบตรวจพบนักเรียนนอนอยู่บริเวณทางเดินนานกว่าค่าที่กำหนด จึงส่งแจ้งเตือนอัตโนมัติ',
      action:
          'ประสานครูเวรและห้องพยาบาลเพื่อตรวจอาการและยืนยันความปลอดภัย',
      icon: Icons.personal_injury_rounded,
      color: AppPalette.primaryPink,
    ),
    _EmergencyEvent(
      id: 'EVT-20260821-014',
      title: 'ตรวจพบควันในห้องวิทยาศาสตร์',
      type: 'ควัน / ไฟ',
      location: 'อาคาร 1 • ห้องวิทยาศาสตร์',
      time: 'วันนี้ • 09:18 น.',
      reporter: 'Smoke Sensor',
      source: 'SMK-LAB-01',
      status: 'ปิดเหตุแล้ว',
      priority: 'สูง',
      description:
          'เซนเซอร์ตรวจพบควันระดับเฝ้าระวัง เจ้าหน้าที่ตรวจสอบพบว่าเกิดจากกิจกรรมทดลองในห้อง',
      action:
          'ตรวจสอบแล้ว ไม่พบเหตุเพลิงไหม้ เปิดระบบระบายอากาศและปิดเหตุ',
      icon: Icons.smoke_free_rounded,
      color: AppPalette.warning,
    ),
    _EmergencyEvent(
      id: 'EVT-20260820-041',
      title: 'กดปุ่ม SOS บริเวณสนามกีฬา',
      type: 'SOS',
      location: 'สนามกีฬา • จุด SOS-02',
      time: 'เมื่อวาน • 15:26 น.',
      reporter: 'นักเรียน',
      source: 'ปุ่ม SOS สนามกีฬา',
      status: 'ปิดเหตุแล้ว',
      priority: 'เร่งด่วน',
      description:
          'นักเรียนกด SOS หลังเพื่อนเกิดอาการหน้ามืดระหว่างกิจกรรมกีฬา',
      action:
          'ครูพละและห้องพยาบาลเข้าช่วยเหลือ นักเรียนอาการปลอดภัยและปิดเหตุแล้ว',
      icon: Icons.notifications_active_rounded,
      color: AppPalette.danger,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'รับแจ้งเหตุฉุกเฉิน',
            subtitle:
                'รับ SOS และติดตามเหตุสำคัญภายในโรงเรียน ตั้งแต่รับเรื่อง มอบหมายผู้ช่วยเหลือ ตรวจสอบพื้นที่ จนถึงปิดเหตุ',
          ),
          const SizedBox(height: 14),
          _summaryCards(),
          const SizedBox(height: 16),
          _sosPanel(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 980) {
                return Column(
                  children: [
                    _activeIncidentCard(),
                    const SizedBox(height: 16),
                    _responseTeamCard(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _activeIncidentCard(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _responseTeamCard(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _eventHistoryCard(filtered),
        ],
      ),
    );
  }

  List<_EmergencyEvent> _filteredEvents() {
    final query = searchText.trim().toLowerCase();

    return events.where((item) {
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.type.toLowerCase().contains(query) ||
          item.reporter.toLowerCase().contains(query);

      final matchesFilter = selectedFilter == 'ทั้งหมด' ||
          item.status == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _summaryCards() {
    const items = [
      _EmergencySummary(
        title: 'SOS ใหม่',
        value: '1',
        subtitle: 'รอรับเรื่อง',
        icon: Icons.notifications_active_rounded,
        color: AppPalette.softPink2,
      ),
      _EmergencySummary(
        title: 'กำลังเกิดเหตุ',
        value: '2',
        subtitle: 'ต้องติดตามทันที',
        icon: Icons.warning_amber_rounded,
        color: AppPalette.softPink,
      ),
      _EmergencySummary(
        title: 'กำลังช่วยเหลือ',
        value: '1',
        subtitle: 'มีทีมรับผิดชอบแล้ว',
        icon: Icons.health_and_safety_rounded,
        color: AppPalette.softCream,
      ),
      _EmergencySummary(
        title: 'ปิดเหตุวันนี้',
        value: '3',
        subtitle: 'ดำเนินการเรียบร้อย',
        icon: Icons.task_alt_rounded,
        color: AppPalette.softMint,
      ),
      _EmergencySummary(
        title: 'เวลาเฉลี่ยรับเรื่อง',
        value: '42 วิ',
        subtitle: '7 วันล่าสุด',
        icon: Icons.timer_outlined,
        color: AppPalette.softBlue,
      ),
      _EmergencySummary(
        title: 'สถานะระบบ SOS',
        value: 'Online',
        subtitle: 'พร้อมรับแจ้งเหตุ',
        icon: Icons.wifi_tethering_rounded,
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

  Widget _sosPanel() {
    final statusColor = sosResolved
        ? AppPalette.success
        : sosAccepted
            ? AppPalette.warning
            : AppPalette.danger;

    final statusText = sosResolved
        ? 'ปิดเหตุแล้ว'
        : sosAccepted
            ? 'รับ SOS แล้ว'
            : 'SOS ใหม่';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.tint(AppPalette.danger, 0.11),
            AppPalette.tint(AppPalette.primaryPink, 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppPalette.tint(
            AppPalette.danger,
            0.20,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppPalette.danger,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'SOS จากห้อง ม.3/2',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.tint(
                                  statusColor,
                                  0.12,
                                ),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 8.8,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'อาคาร 3 • ชั้น 2 • ห้อง ม.3/2 • วันนี้ 10:42 น.',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'มีการกดปุ่ม SOS ภายในห้องเรียน ระบบส่งตำแหน่งให้ผู้อำนวยการ ครูเวร และฝ่ายกิจการนักเรียนแล้ว',
                style: TextStyle(
                  fontSize: 10.2,
                  height: 1.45,
                  color: AppPalette.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              _sosDetailBox(),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoChip(
                    Icons.medical_services_rounded,
                    'เจ็บป่วยฉุกเฉิน',
                    AppPalette.danger,
                  ),
                  _infoChip(
                    Icons.place_rounded,
                    'อาคาร 3 ชั้น 2',
                    AppPalette.danger,
                  ),
                  _infoChip(
                    Icons.schedule_rounded,
                    'แจ้งมา 28 วินาที',
                    AppPalette.warning,
                  ),
                  _infoChip(
                    Icons.sensors_rounded,
                    'ปุ่ม SOS ห้องเรียน',
                    AppPalette.learningBlue,
                  ),
                ],
              ),
            ],
          );

          final actions = Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: sosAccepted
                        ? AppPalette.environmentGreen
                        : AppPalette.danger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: sosResolved
                      ? null
                      : sosAccepted
                          ? _showSosDetail
                          : _acceptSos,
                  icon: Icon(
                    sosAccepted
                        ? Icons.check_circle_rounded
                        : Icons.call_received_rounded,
                    size: 22,
                  ),
                  label: Text(
                    sosAccepted
                        ? 'รับ SOS แล้ว'
                        : 'รับ SOS',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showSosDetail,
                  icon: const Icon(
                    Icons.visibility_rounded,
                    size: 16,
                  ),
                  label: const Text('ดูรายละเอียด'),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: info,
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 190,
                child: actions,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoChip(
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sosDetailBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.tint(AppPalette.danger, 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppPalette.tint(AppPalette.danger, 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.personal_injury_rounded,
                  size: 18,
                  color: AppPalette.danger,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ประเภทเหตุ • เจ็บป่วยฉุกเฉิน',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.danger,
                      ),
                    ),
                    Text(
                      'นักเรียนหมดสติระหว่างคาบเรียน',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppPalette.tint(AppPalette.danger, 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'รุนแรงสูง',
                  style: TextStyle(
                    fontSize: 8.6,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          const Text(
            'นักเรียนหญิงชั้น ม.3/2 หมดสติระหว่างคาบเรียนคณิตศาสตร์ เพื่อนร่วมชั้นและครูประจำวิชากดปุ่ม SOS '
            'ขณะนี้ครูกำลังปฐมพยาบาลเบื้องต้น ผู้ป่วยยังหายใจแต่ไม่รู้สึกตัว ต้องการเจ้าหน้าที่พยาบาลและรถฉุกเฉินโดยด่วน',
            style: TextStyle(
              fontSize: 10,
              height: 1.5,
              color: AppPalette.textDark,
            ),
          ),
          const SizedBox(height: 11),
          _sosDetailLine(
            Icons.person_rounded,
            'ผู้กดแจ้ง',
            'ครูสมหญิง ใจดี (ครูประจำวิชาคณิตศาสตร์)',
          ),
          _sosDetailLine(
            Icons.emergency_rounded,
            'ผู้ประสบเหตุ',
            'นักเรียนหญิง 1 คน • ชั้น ม.3/2',
          ),
          _sosDetailLine(
            Icons.local_hospital_rounded,
            'สิ่งที่ต้องการ',
            'เจ้าหน้าที่พยาบาล + รถฉุกเฉิน และแจ้งผู้ปกครอง',
          ),
        ],
      ),
    );
  }

  Widget _sosDetailLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppPalette.danger),
          const SizedBox(width: 7),
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeIncidentCard() {
    final active = events
        .where(
          (item) =>
              item.status != 'ปิดเหตุแล้ว' &&
              item.id != 'SOS-20260821-001',
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เหตุที่กำลังติดตาม',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'แสดงเฉพาะเหตุที่ยังไม่ปิด เพื่อให้ผู้อำนวยการเห็นสถานการณ์ปัจจุบันได้ทันที',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...active.map(_activeEventTile),
        ],
      ),
    );
  }

  Widget _activeEventTile(_EmergencyEvent item) {
    final statusColor = _statusColor(item.status);

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => _showEventDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppPalette.tint(item.color, 0.05),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: AppPalette.tint(item.color, 0.14),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.location} • ${item.time}',
                    style: const TextStyle(
                      fontSize: 8.6,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.6,
                      height: 1.4,
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
                color:
                    AppPalette.tint(statusColor, 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.status,
                style: TextStyle(
                  fontSize: 8,
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

  Widget _responseTeamCard() {
    final teams = const [
      _ResponseTeam(
        name: 'ครูเวรอาคาร 3',
        detail: 'คุณครูสมชาย ใจดี',
        status: 'พร้อมรับเหตุ',
        icon: Icons.person_rounded,
        color: AppPalette.environmentGreen,
      ),
      _ResponseTeam(
        name: 'ฝ่ายกิจการนักเรียน',
        detail: 'เจ้าหน้าที่ 2 คน',
        status: 'กำลังไปจุดเกิดเหตุ',
        icon: Icons.groups_rounded,
        color: AppPalette.warning,
      ),
      _ResponseTeam(
        name: 'ห้องพยาบาล',
        detail: 'พยาบาลประจำโรงเรียน',
        status: 'พร้อมช่วยเหลือ',
        icon: Icons.medical_services_rounded,
        color: AppPalette.learningBlue,
      ),
      _ResponseTeam(
        name: 'ฝ่ายอาคารสถานที่',
        detail: 'เจ้าหน้าที่เวร',
        status: 'พร้อมรับเหตุ',
        icon: Icons.home_repair_service_rounded,
        color: AppPalette.chartCream,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ทีมตอบสนองเหตุฉุกเฉิน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ดูหน่วยที่ได้รับแจ้งและสถานะการเข้าช่วยเหลือ',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...teams.map(_responseTeamTile),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showMessage(
                      'ตัวอย่าง: โทรหาครูเวร',
                    );
                  },
                  icon: const Icon(
                    Icons.phone_rounded,
                    size: 16,
                  ),
                  label: const Text(
                    'โทรครูเวร',
                    style: TextStyle(fontSize: 9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showMessage(
                      'ส่งแจ้งเตือนซ้ำให้ทีมฉุกเฉินแล้ว',
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_active_rounded,
                    size: 16,
                  ),
                  label: const Text(
                    'แจ้งซ้ำ',
                    style: TextStyle(fontSize: 9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _responseTeamTile(_ResponseTeam team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppPalette.tint(team.color, 0.055),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              team.icon,
              size: 17,
              color: team.color,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: const TextStyle(
                    fontSize: 10.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  team.detail,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            team.status,
            style: TextStyle(
              fontSize: 8.2,
              fontWeight: FontWeight.w700,
              color: team.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventHistoryCard(
    List<_EmergencyEvent> filtered,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ประวัติการรับแจ้งเหตุ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ค้นหาเหตุการณ์และดูว่าใครแจ้ง จากระบบใด ที่ไหน และปัจจุบันอยู่ในสถานะใด',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          _searchAndFilter(),
          const SizedBox(height: 11),
          Row(
            children: [
              Text(
                'พบ ${filtered.length} เหตุการณ์',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                selectedFilter,
                style: const TextStyle(
                  fontSize: 8.8,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.primaryPinkDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            _emptyState()
          else
            ...filtered.map(_eventHistoryTile),
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
                'ค้นหาเหตุ อาคาร ห้อง ผู้แจ้ง หรือประเภทเหตุ...',
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
          padding:
              const EdgeInsets.symmetric(horizontal: 10),
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
                    (item) =>
                        DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style:
                            const TextStyle(fontSize: 9.5),
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
            const SizedBox(width: 9),
            SizedBox(
              width: 190,
              child: filter,
            ),
          ],
        );
      },
    );
  }

  Widget _eventHistoryTile(_EmergencyEvent item) {
    final statusColor = _statusColor(item.status);

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => _showEventDetail(item),
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
            final compact = constraints.maxWidth < 720;

            if (compact) {
              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _eventIcon(item),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _eventMainInfo(item),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _smallTag(
                        item.type,
                        item.color,
                      ),
                      _smallTag(
                        item.priority,
                        _priorityColor(item.priority),
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
                _eventIcon(item),
                const SizedBox(width: 11),
                Expanded(
                  flex: 3,
                  child: _eventMainInfo(item),
                ),
                Expanded(
                  child: _listInfo(
                    'ประเภท',
                    item.type,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _listInfo(
                    'สถานที่',
                    item.location,
                  ),
                ),
                Expanded(
                  child: _listInfo(
                    'ผู้แจ้ง',
                    item.reporter,
                  ),
                ),
                _smallTag(
                  item.status,
                  statusColor,
                ),
                const SizedBox(width: 6),
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

  Widget _eventIcon(_EmergencyEvent item) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppPalette.tint(item.color, 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        item.icon,
        size: 20,
        color: item.color,
      ),
    );
  }

  Widget _eventMainInfo(_EmergencyEvent item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${item.time} • ${item.source}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8.5,
            color: AppPalette.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _listInfo(
    String title,
    String value,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 8,
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
            fontSize: 8.7,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _smallTag(
    String text,
    Color color,
  ) {
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
          fontSize: 8.1,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'กำลังเกิดเหตุ':
        return AppPalette.danger;
      case 'รับเรื่องแล้ว':
        return AppPalette.learningBlue;
      case 'กำลังช่วยเหลือ':
        return AppPalette.warning;
      case 'ปิดเหตุแล้ว':
        return AppPalette.success;
      default:
        return AppPalette.textMuted;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'เร่งด่วน':
        return AppPalette.danger;
      case 'สูง':
        return AppPalette.warning;
      default:
        return AppPalette.learningBlue;
    }
  }

  void _acceptSos() {
    setState(() => sosAccepted = true);

    _showMessage(
      'รับ SOS แล้ว ระบบกำหนดให้ผู้อำนวยการเป็นผู้รับเรื่อง',
    );

    _showSosDetail();
  }

  void _showSosDetail() {
    showDialog<void>(
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
                  maxWidth: 700,
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
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppPalette.tint(
                                AppPalette.danger,
                                0.10,
                              ),
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: AppPalette.danger,
                            ),
                          ),
                          const SizedBox(width: 11),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SOS จากห้อง ม.3/2',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'SOS-20260821-001 • วันนี้ 10:42 น.',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color:
                                        AppPalette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext),
                            icon: const Icon(
                              Icons.close_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          _smallTag(
                            'SOS',
                            AppPalette.danger,
                          ),
                          _smallTag(
                            sosResolved
                                ? 'ปิดเหตุแล้ว'
                                : sosAccepted
                                    ? 'รับเรื่องแล้ว'
                                    : 'รอรับ SOS',
                            sosResolved
                                ? AppPalette.success
                                : sosAccepted
                                    ? AppPalette.learningBlue
                                    : AppPalette.danger,
                          ),
                          _smallTag(
                            'เร่งด่วน',
                            AppPalette.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _detailTitle(
                                'ข้อมูลจุดเกิดเหตุ',
                              ),
                              _detailRow(
                                'สถานที่',
                                'อาคาร 3 • ชั้น 2 • ห้อง ม.3/2',
                              ),
                              _detailRow(
                                'แหล่งแจ้ง',
                                'ปุ่ม SOS ในห้องเรียน',
                              ),
                              _detailRow(
                                'ผู้แจ้ง',
                                'นักเรียน ม.3/2',
                              ),
                              _detailRow(
                                'เวลาที่แจ้ง',
                                '10:42:18 น.',
                              ),
                              const SizedBox(height: 12),
                              _detailTitle(
                                'รายละเอียด',
                              ),
                              const Text(
                                'เหตุ: นักเรียนหญิงชั้น ม.3/2 หมดสติระหว่างคาบเรียนคณิตศาสตร์ ครูประจำวิชากดปุ่ม SOS และกำลังปฐมพยาบาลเบื้องต้น ผู้ป่วยยังหายใจแต่ไม่รู้สึกตัว ต้องการพยาบาลและรถฉุกเฉินโดยด่วน ระบบส่งตำแหน่งให้ผู้บริหาร ครูเวร และฝ่ายกิจการนักเรียนแล้ว',
                                style: TextStyle(
                                  fontSize: 9.7,
                                  height: 1.5,
                                  color:
                                      AppPalette.textMuted,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _detailTitle(
                                'ขั้นตอนตอบสนอง',
                              ),
                              _timeline(
                                'ระบบรับสัญญาณ SOS',
                                '10:42:18 น.',
                                true,
                              ),
                              _timeline(
                                'แจ้งผู้อำนวยการ',
                                '10:42:19 น.',
                                true,
                              ),
                              _timeline(
                                'ผู้อำนวยการรับ SOS',
                                sosAccepted
                                    ? 'รับเรื่องแล้ว'
                                    : 'รอรับเรื่อง',
                                sosAccepted,
                              ),
                              _timeline(
                                'ทีมเข้าตรวจสอบพื้นที่',
                                sosResolved
                                    ? 'ดำเนินการแล้ว'
                                    : 'กำลังรอการยืนยัน',
                                sosResolved,
                              ),
                              const SizedBox(height: 12),
                              _detailTitle(
                                'ทีมที่ได้รับแจ้ง',
                              ),
                              _teamLine(
                                'ครูเวรอาคาร 3',
                                'ได้รับแจ้ง',
                                AppPalette.environmentGreen,
                              ),
                              _teamLine(
                                'ฝ่ายกิจการนักเรียน',
                                'ได้รับแจ้ง',
                                AppPalette.environmentGreen,
                              ),
                              _teamLine(
                                'ห้องพยาบาล',
                                'Standby',
                                AppPalette.learningBlue,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact =
                              constraints.maxWidth < 520;

                          final accept = FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  AppPalette.danger,
                            ),
                            onPressed: sosAccepted
                                ? null
                                : () {
                                    setState(
                                      () =>
                                          sosAccepted = true,
                                    );
                                    setDialogState(() {});
                                  },
                            icon: const Icon(
                              Icons.call_received_rounded,
                              size: 16,
                            ),
                            label: const Text('รับ SOS'),
                          );

                          final resolve =
                              FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  AppPalette.environmentGreen,
                            ),
                            onPressed: sosResolved
                                ? null
                                : () {
                                    setState(() {
                                      sosAccepted = true;
                                      sosResolved = true;
                                    });
                                    setDialogState(() {});
                                  },
                            icon: const Icon(
                              Icons.task_alt_rounded,
                              size: 16,
                            ),
                            label:
                                const Text('ปิดเหตุ'),
                          );

                          if (compact) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: accept,
                                ),
                                const SizedBox(height: 7),
                                SizedBox(
                                  width: double.infinity,
                                  child: resolve,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: accept),
                              const SizedBox(width: 8),
                              Expanded(child: resolve),
                            ],
                          );
                        },
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
  }

  void _showEventDetail(_EmergencyEvent item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            item.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _smallTag(item.type, item.color),
                      _smallTag(
                        item.priority,
                        _priorityColor(item.priority),
                      ),
                      _smallTag(
                        item.status,
                        _statusColor(item.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailRow(
                    'รหัสเหตุ',
                    item.id,
                  ),
                  _detailRow(
                    'สถานที่',
                    item.location,
                  ),
                  _detailRow(
                    'เวลา',
                    item.time,
                  ),
                  _detailRow(
                    'ผู้แจ้ง',
                    item.reporter,
                  ),
                  _detailRow(
                    'แหล่งข้อมูล',
                    item.source,
                  ),
                  const SizedBox(height: 12),
                  _detailTitle('รายละเอียด'),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 9.7,
                      height: 1.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _detailTitle(
                    'การดำเนินการ',
                  ),
                  Text(
                    item.action,
                    style: const TextStyle(
                      fontSize: 9.7,
                      height: 1.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
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

  Widget _detailTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 9.7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(
    String title,
    String subtitle,
    bool done,
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
              color: done
                  ? AppPalette.tint(
                      AppPalette.environmentGreen,
                      0.12,
                    )
                  : AppPalette.softTag,
              shape: BoxShape.circle,
            ),
            child: Icon(
              done
                  ? Icons.check_rounded
                  : Icons.more_horiz_rounded,
              size: 14,
              color: done
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
                    fontSize: 9.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 8.4,
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

  Widget _teamLine(
    String name,
    String status,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: color,
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
        vertical: 28,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Text(
        'ไม่พบเหตุการณ์ตามเงื่อนไข',
        style: TextStyle(
          fontSize: 10,
          color: AppPalette.textMuted,
        ),
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

class _EmergencySummary {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _EmergencySummary({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _EmergencyEvent {
  final String id;
  final String title;
  final String type;
  final String location;
  final String time;
  final String reporter;
  final String source;
  final String status;
  final String priority;
  final String description;
  final String action;
  final IconData icon;
  final Color color;

  const _EmergencyEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.time,
    required this.reporter,
    required this.source,
    required this.status,
    required this.priority,
    required this.description,
    required this.action,
    required this.icon,
    required this.color,
  });
}

class _ResponseTeam {
  final String name;
  final String detail;
  final String status;
  final IconData icon;
  final Color color;

  const _ResponseTeam({
    required this.name,
    required this.detail,
    required this.status,
    required this.icon,
    required this.color,
  });
}
