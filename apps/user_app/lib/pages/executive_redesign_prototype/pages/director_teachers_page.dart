import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorTeachersPage extends StatefulWidget {
  const DirectorTeachersPage({super.key});

  @override
  State<DirectorTeachersPage> createState() =>
      _DirectorTeachersPageState();
}

class _DirectorTeachersPageState extends State<DirectorTeachersPage> {
  String searchText = '';
  String selectedDepartment = 'ทุกฝ่าย';
  String selectedRole = 'ทุกประเภท';
  String selectedStatus = 'ทุกสถานะ';

  final List<String> departments = const [
    'ทุกฝ่าย',
    'ฝ่ายบริหาร',
    'ฝ่ายวิชาการ',
    'ฝ่ายกิจการนักเรียน',
    'ฝ่ายบุคคลและธุรการ',
    'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
    'ฝ่ายเทคโนโลยีและระบบ',
  ];

  final List<String> roles = const [
    'ทุกประเภท',
    'ผู้บริหาร',
    'ครูผู้สอน',
    'หัวหน้าฝ่าย',
    'เจ้าหน้าที่',
    'บุคลากรสนับสนุน',
  ];

  final List<String> statuses = const [
    'ทุกสถานะ',
    'มาปฏิบัติงาน',
    'เข้าสอน',
    'ลา',
    'มาสาย',
    'ประชุม/อบรม',
  ];

  final List<_DepartmentData> departmentData = const [
    _DepartmentData(
      title: 'ฝ่ายบริหาร',
      subtitle: 'กำกับนโยบายและบริหารภาพรวมโรงเรียน',
      staff: 6,
      present: 6,
      onLeave: 0,
      workload: 92,
      icon: Icons.account_balance_rounded,
      color: AppPalette.primaryPink,
      issue: 'ปกติ',
    ),
    _DepartmentData(
      title: 'ฝ่ายวิชาการ',
      subtitle: 'การเรียนการสอน หลักสูตร วัดผล และนิเทศ',
      staff: 54,
      present: 51,
      onLeave: 2,
      workload: 96,
      icon: Icons.school_rounded,
      color: AppPalette.learningBlue,
      issue: 'ติดตาม 2 คน',
    ),
    _DepartmentData(
      title: 'ฝ่ายกิจการนักเรียน',
      subtitle: 'ดูแลพฤติกรรม วินัย ความปลอดภัย และกิจกรรม',
      staff: 8,
      present: 8,
      onLeave: 0,
      workload: 94,
      icon: Icons.groups_2_rounded,
      color: AppPalette.chartPink,
      issue: 'มี 2 เคส',
    ),
    _DepartmentData(
      title: 'ฝ่ายบุคคลและธุรการ',
      subtitle: 'งานบุคคล เอกสาร การลา และงานสำนักงาน',
      staff: 6,
      present: 5,
      onLeave: 1,
      workload: 91,
      icon: Icons.badge_rounded,
      color: AppPalette.behaviorYellow,
      issue: 'ลา 1 คน',
    ),
    _DepartmentData(
      title: 'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
      subtitle: 'ดูแลอาคาร ห้องเรียน น้ำ ไฟ และสภาพแวดล้อม',
      staff: 8,
      present: 7,
      onLeave: 0,
      workload: 89,
      icon: Icons.apartment_rounded,
      color: AppPalette.environmentGreen,
      issue: 'ตรวจอาคาร 2',
    ),
    _DepartmentData(
      title: 'ฝ่ายเทคโนโลยีและระบบ',
      subtitle: 'ดูแลระบบสารสนเทศ AIoT อุปกรณ์ และเครือข่าย',
      staff: 4,
      present: 4,
      onLeave: 0,
      workload: 95,
      icon: Icons.memory_rounded,
      color: AppPalette.chartCream,
      issue: 'ปกติ',
    ),
  ];

  final List<_SubjectGroupData> subjectGroups = const [
    _SubjectGroupData('ภาษาไทย', 6, 95, 94, 1, AppPalette.chartPink),
    _SubjectGroupData('คณิตศาสตร์', 7, 96, 95, 1, AppPalette.learningBlue),
    _SubjectGroupData('วิทยาศาสตร์และเทคโนโลยี', 8, 94, 96, 2, AppPalette.environmentGreen),
    _SubjectGroupData('สังคมศึกษา', 5, 93, 92, 1, AppPalette.chartCream),
    _SubjectGroupData('สุขศึกษาและพลศึกษา', 5, 97, 94, 0, AppPalette.behaviorYellow),
    _SubjectGroupData('ศิลปะ', 4, 95, 93, 0, AppPalette.chartPink2),
    _SubjectGroupData('การงานอาชีพ', 5, 94, 92, 1, AppPalette.chartCream),
    _SubjectGroupData('ภาษาต่างประเทศ', 8, 96, 95, 1, AppPalette.learningBlue),
  ];

  final List<_PersonnelData> personnel = const [
    _PersonnelData(
      name: 'นายสมชาย ใจดี',
      position: 'รองผู้อำนวยการฝ่ายวิชาการ',
      department: 'ฝ่ายวิชาการ',
      role: 'ผู้บริหาร',
      subjectGroup: 'บริหารวิชาการ',
      status: 'มาปฏิบัติงาน',
      email: 'somchai@school.ac.th',
      phone: '08x-xxx-1001',
      attendance: 98,
      teaching: 0,
      taskProgress: 96,
      note: 'กำกับแผนการเรียน การนิเทศ และผลสัมฤทธิ์ทางการเรียน',
      color: AppPalette.primaryPink,
    ),
    _PersonnelData(
      name: 'นางสาวอรทัย พัฒนกิจ',
      position: 'หัวหน้ากลุ่มสาระคณิตศาสตร์',
      department: 'ฝ่ายวิชาการ',
      role: 'หัวหน้าฝ่าย',
      subjectGroup: 'คณิตศาสตร์',
      status: 'เข้าสอน',
      email: 'orathai@school.ac.th',
      phone: '08x-xxx-1002',
      attendance: 97,
      teaching: 96,
      taskProgress: 95,
      note: 'รับผิดชอบแผนการสอนและติดตามนักเรียนที่ผลการเรียนต่ำกว่าเกณฑ์',
      color: AppPalette.learningBlue,
    ),
    _PersonnelData(
      name: 'นายกิตติศักดิ์ แสงทอง',
      position: 'ครูวิทยาศาสตร์',
      department: 'ฝ่ายวิชาการ',
      role: 'ครูผู้สอน',
      subjectGroup: 'วิทยาศาสตร์และเทคโนโลยี',
      status: 'เข้าสอน',
      email: 'kittisak@school.ac.th',
      phone: '08x-xxx-1003',
      attendance: 95,
      teaching: 94,
      taskProgress: 92,
      note: 'สอน ม.4-ม.6 และดูแลห้องปฏิบัติการวิทยาศาสตร์',
      color: AppPalette.environmentGreen,
    ),
    _PersonnelData(
      name: 'นางสาวพรทิพย์ รักษ์ดี',
      position: 'ครูภาษาอังกฤษ',
      department: 'ฝ่ายวิชาการ',
      role: 'ครูผู้สอน',
      subjectGroup: 'ภาษาต่างประเทศ',
      status: 'มาปฏิบัติงาน',
      email: 'porntip@school.ac.th',
      phone: '08x-xxx-1004',
      attendance: 96,
      teaching: 95,
      taskProgress: 94,
      note: 'สอน ม.2 และ ม.5 พร้อมดูแลกิจกรรมภาษาอังกฤษ',
      color: AppPalette.chartPink2,
    ),
    _PersonnelData(
      name: 'นายณัฐวุฒิ มั่นคง',
      position: 'หัวหน้าฝ่ายกิจการนักเรียน',
      department: 'ฝ่ายกิจการนักเรียน',
      role: 'หัวหน้าฝ่าย',
      subjectGroup: 'กิจการนักเรียน',
      status: 'มาปฏิบัติงาน',
      email: 'nattawut@school.ac.th',
      phone: '08x-xxx-1005',
      attendance: 98,
      teaching: 0,
      taskProgress: 94,
      note: 'ดูแลวินัย ความปลอดภัย นักเรียนขาดเรียน และเหตุการณ์ฉุกเฉิน',
      color: AppPalette.chartPink,
    ),
    _PersonnelData(
      name: 'นางสาวสุภาวดี ศรีสุข',
      position: 'เจ้าหน้าที่งานบุคคล',
      department: 'ฝ่ายบุคคลและธุรการ',
      role: 'เจ้าหน้าที่',
      subjectGroup: 'งานบุคคล',
      status: 'มาปฏิบัติงาน',
      email: 'supawadee@school.ac.th',
      phone: '08x-xxx-1006',
      attendance: 97,
      teaching: 0,
      taskProgress: 91,
      note: 'ดูแลข้อมูลบุคลากร การลา ประวัติ และเอกสารราชการ',
      color: AppPalette.behaviorYellow,
    ),
    _PersonnelData(
      name: 'นายประสิทธิ์ ช่างดี',
      position: 'เจ้าหน้าที่อาคารสถานที่',
      department: 'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
      role: 'บุคลากรสนับสนุน',
      subjectGroup: 'อาคารสถานที่',
      status: 'มาปฏิบัติงาน',
      email: 'prasit@school.ac.th',
      phone: '08x-xxx-1007',
      attendance: 95,
      teaching: 0,
      taskProgress: 89,
      note: 'ตรวจสอบระบบน้ำ ไฟ อาคาร และรับผิดชอบเหตุผิดปกติอาคาร 2',
      color: AppPalette.environmentGreen,
    ),
    _PersonnelData(
      name: 'นายธนกฤต ระบบดี',
      position: 'เจ้าหน้าที่ระบบสารสนเทศ',
      department: 'ฝ่ายเทคโนโลยีและระบบ',
      role: 'เจ้าหน้าที่',
      subjectGroup: 'ระบบสารสนเทศ',
      status: 'ประชุม/อบรม',
      email: 'thanakrit@school.ac.th',
      phone: '08x-xxx-1008',
      attendance: 96,
      teaching: 0,
      taskProgress: 95,
      note: 'ดูแล AIoT Dashboard เครือข่าย ฐานข้อมูล และระบบแจ้งเตือน',
      color: AppPalette.chartCream,
    ),
    _PersonnelData(
      name: 'นางสาวจิราพร ตั้งใจ',
      position: 'ครูภาษาไทย',
      department: 'ฝ่ายวิชาการ',
      role: 'ครูผู้สอน',
      subjectGroup: 'ภาษาไทย',
      status: 'ลา',
      email: 'jiraporn@school.ac.th',
      phone: '08x-xxx-1009',
      attendance: 92,
      teaching: 93,
      taskProgress: 90,
      note: 'ลาป่วยวันนี้ มีการจัดครูสอนแทนคาบ 2 และคาบ 4 แล้ว',
      color: AppPalette.chartPink,
    ),
    _PersonnelData(
      name: 'นายวรพล ขยันงาน',
      position: 'ครูสังคมศึกษา',
      department: 'ฝ่ายวิชาการ',
      role: 'ครูผู้สอน',
      subjectGroup: 'สังคมศึกษา',
      status: 'มาสาย',
      email: 'worapon@school.ac.th',
      phone: '08x-xxx-1010',
      attendance: 90,
      teaching: 91,
      taskProgress: 92,
      note: 'มาสาย 18 นาที ระบบบันทึกเวลาเข้าแล้ว และเข้าสอนคาบแรกทันเวลา',
      color: AppPalette.warning,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPersonnel();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'ครูและบุคลากร',
            subtitle:
                'ภาพรวมบุคลากรทั้งโรงเรียน แยกตามฝ่าย กลุ่มสาระ ตำแหน่ง การมาปฏิบัติงาน ภาระงาน และประเด็นที่ผู้อำนวยการควรติดตาม',
          ),
          const SizedBox(height: 14),
          _summaryCards(),
          const SizedBox(height: 16),
          _departmentSection(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1050) {
                return Column(
                  children: [
                    _todayStatusCard(),
                    const SizedBox(height: 16),
                    _directorFollowUpCard(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _todayStatusCard(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _directorFollowUpCard(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _subjectGroupsSection(),
          const SizedBox(height: 16),
          _personnelSection(filtered),
        ],
      ),
    );
  }

  List<_PersonnelData> _filteredPersonnel() {
    final query = searchText.trim().toLowerCase();

    return personnel.where((person) {
      final matchesSearch = query.isEmpty ||
          person.name.toLowerCase().contains(query) ||
          person.position.toLowerCase().contains(query) ||
          person.department.toLowerCase().contains(query) ||
          person.subjectGroup.toLowerCase().contains(query);

      final matchesDepartment = selectedDepartment == 'ทุกฝ่าย' ||
          person.department == selectedDepartment;

      final matchesRole =
          selectedRole == 'ทุกประเภท' || person.role == selectedRole;

      final matchesStatus =
          selectedStatus == 'ทุกสถานะ' || person.status == selectedStatus;

      return matchesSearch &&
          matchesDepartment &&
          matchesRole &&
          matchesStatus;
    }).toList();
  }

  Widget _summaryCards() {
    const items = [
      _SummaryItem(
        title: 'ครูและบุคลากรทั้งหมด',
        value: '86',
        subtitle: 'ครู 61 • บุคลากร 25',
        icon: Icons.groups_rounded,
        color: AppPalette.softPink,
      ),
      _SummaryItem(
        title: 'มาปฏิบัติงานวันนี้',
        value: '82',
        subtitle: 'คิดเป็น 95.3%',
        icon: Icons.how_to_reg_rounded,
        color: AppPalette.softMint,
      ),
      _SummaryItem(
        title: 'ลา / ไม่อยู่',
        value: '3',
        subtitle: 'ลาป่วย 2 • ลากิจ 1',
        icon: Icons.person_off_rounded,
        color: AppPalette.softCream,
      ),
      _SummaryItem(
        title: 'มาสาย',
        value: '2',
        subtitle: 'ติดตามเวลาเข้าสอนแล้ว',
        icon: Icons.schedule_rounded,
        color: AppPalette.softPink2,
      ),
      _SummaryItem(
        title: 'เข้าสอนตามตาราง',
        value: '96%',
        subtitle: 'คาบสอนที่เริ่มตรงเวลา',
        icon: Icons.co_present_rounded,
        color: AppPalette.softBlue,
      ),
      _SummaryItem(
        title: 'ประชุม / อบรม',
        value: '4',
        subtitle: 'จัดครูสอนแทนแล้ว 3 คาบ',
        icon: Icons.event_available_rounded,
        color: AppPalette.softMint,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 6;
        if (constraints.maxWidth < 720) {
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
            mainAxisExtent: 118,
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
                      fontSize: 21,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
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

  Widget _departmentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ภาพรวมแยกตามฝ่าย',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ผู้อำนวยการสามารถดูจำนวนบุคลากร การมาปฏิบัติงาน ภาระงาน และประเด็นที่ต้องติดตามของแต่ละฝ่ายได้ในภาพเดียว',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = 3;
              if (constraints.maxWidth < 700) {
                columns = 1;
              } else if (constraints.maxWidth < 1080) {
                columns = 2;
              }

              return GridView.builder(
                itemCount: departmentData.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 205,
                ),
                itemBuilder: (context, index) {
                  return _departmentCard(departmentData[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _departmentCard(_DepartmentData item) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() => selectedDepartment = item.title);
        _showDepartmentDetail(item);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.tint(item.color, 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppPalette.tint(item.color, 0.18),
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
                    color: item.color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppPalette.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.2,
                height: 1.35,
                color: AppPalette.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _departmentMetric(
                  'ทั้งหมด',
                  '${item.staff}',
                  item.color,
                ),
                _departmentMetric(
                  'มาทำงาน',
                  '${item.present}',
                  AppPalette.success,
                ),
                _departmentMetric(
                  'ลา',
                  '${item.onLeave}',
                  AppPalette.warning,
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                const Text(
                  'ภาระงาน',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: item.workload / 100,
                      minHeight: 6,
                      backgroundColor: AppPalette.softTag,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(item.color),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '${item.workload}%',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'สถานะ',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppPalette.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  item.issue,
                  style: TextStyle(
                    fontSize: 9.2,
                    fontWeight: FontWeight.w700,
                    color: item.issue == 'ปกติ'
                        ? AppPalette.success
                        : AppPalette.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _departmentMetric(
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: AppPalette.tint(color, 0.08),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 8.3,
                color: AppPalette.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถานะการปฏิบัติงานวันนี้',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'สรุปสิ่งที่มีผลต่อการทำงานและการจัดการเรียนการสอนในวันนี้',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          _statusTile(
            icon: Icons.check_circle_rounded,
            title: 'มาปฏิบัติงานตามปกติ',
            value: '82 คน',
            detail: '95.3% ของครูและบุคลากรทั้งหมด',
            color: AppPalette.success,
          ),
          _statusTile(
            icon: Icons.person_off_rounded,
            title: 'ลา',
            value: '3 คน',
            detail: 'ลาป่วย 2 คน • ลากิจ 1 คน',
            color: AppPalette.warning,
          ),
          _statusTile(
            icon: Icons.schedule_rounded,
            title: 'มาสาย',
            value: '2 คน',
            detail: 'ไม่มีผลกระทบต่อคาบสอนในขณะนี้',
            color: AppPalette.chartCream,
          ),
          _statusTile(
            icon: Icons.swap_horiz_rounded,
            title: 'ครูสอนแทน',
            value: '3 คาบ',
            detail: 'จัดครูสอนแทนเรียบร้อยทุกคาบ',
            color: AppPalette.learningBlue,
          ),
          _statusTile(
            icon: Icons.co_present_rounded,
            title: 'คาบสอนเริ่มตรงเวลา',
            value: '96%',
            detail: 'มี 4 คาบที่เริ่มช้ากว่าแผนเล็กน้อย',
            color: AppPalette.primaryPink,
          ),
        ],
      ),
    );
  }

  Widget _statusTile({
    required IconData icon,
    required String title,
    required String value,
    required String detail,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _directorFollowUpCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สิ่งที่ผู้อำนวยการควรติดตาม',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ประเด็นที่อาจกระทบต่อบุคลากร การสอน หรือการบริหารงาน',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          _followUpTile(
            title: 'ครูลา 2 คนในฝ่ายวิชาการ',
            detail:
                'มีคาบสอนรวม 3 คาบที่ต้องจัดครูสอนแทน ขณะนี้จัดสรรครบแล้ว แต่ควรติดตามหากมีการลาต่อเนื่อง',
            status: 'ควรติดตาม',
            color: AppPalette.warning,
            icon: Icons.person_off_rounded,
          ),
          _followUpTile(
            title: 'ภาระงานฝ่ายวิชาการอยู่ที่ 96%',
            detail:
                'ช่วงสอบและงานวัดผลทำให้ภาระงานสูง ควรตรวจสอบการกระจายงานของหัวหน้ากลุ่มสาระและครูผู้รับผิดชอบ',
            status: 'ภาระงานสูง',
            color: AppPalette.chartPink,
            icon: Icons.speed_rounded,
          ),
          _followUpTile(
            title: 'เจ้าหน้าที่อาคารกำลังตรวจสอบอาคาร 2',
            detail:
                'เกี่ยวข้องกับข้อมูลการใช้น้ำสูงผิดปกติ ฝ่ายอาคารสถานที่กำลังตรวจจุดใช้น้ำและระบบท่อ',
            status: 'กำลังดำเนินการ',
            color: AppPalette.warning,
            icon: Icons.apartment_rounded,
          ),
          _followUpTile(
            title: 'มีบุคลากรเข้าอบรมด้านระบบ 1 คน',
            detail:
                'ไม่กระทบการให้บริการระบบหลัก มีเจ้าหน้าที่สำรองรับผิดชอบ AIoT Dashboard และเครือข่าย',
            status: 'ปกติ',
            color: AppPalette.success,
            icon: Icons.computer_rounded,
          ),
        ],
      ),
    );
  }

  Widget _followUpTile({
    required String title,
    required String detail,
    required String status,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPalette.tint(color, 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 10.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.tint(color, 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 8.3,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 9.3,
                    height: 1.4,
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

  Widget _subjectGroupsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ครูผู้สอนแยกตามกลุ่มสาระ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ดูจำนวนครู การมาปฏิบัติงาน ภาพรวมการเข้าสอน และจำนวนครูที่ต้องติดตามของแต่ละกลุ่มสาระ',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = 4;
              if (constraints.maxWidth < 650) {
                columns = 1;
              } else if (constraints.maxWidth < 980) {
                columns = 2;
              }

              return GridView.builder(
                itemCount: subjectGroups.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 145,
                ),
                itemBuilder: (context, index) {
                  final item = subjectGroups[index];

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPalette.tint(item.color, 0.06),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: AppPalette.tint(item.color, 0.16),
                      ),
                    ),
                    child: Column(
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
                        const SizedBox(height: 3),
                        Text(
                          '${item.teachers} คน',
                          style: const TextStyle(
                            fontSize: 9.2,
                            color: AppPalette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _subjectMetric(
                          'มาปฏิบัติงาน',
                          item.attendance,
                          AppPalette.learningBlue,
                        ),
                        _subjectMetric(
                          'เข้าสอน',
                          item.teaching,
                          AppPalette.primaryPink,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Text(
                              'ต้องติดตาม',
                              style: TextStyle(
                                fontSize: 8.8,
                                color: AppPalette.textMuted,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${item.followUp} คน',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: item.followUp > 0
                                    ? AppPalette.warning
                                    : AppPalette.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _subjectMetric(
    String label,
    int value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 66,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 8.4,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 5,
                backgroundColor: AppPalette.softTag,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$value%',
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _personnelSection(List<_PersonnelData> filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายชื่อครูและบุคลากร',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ค้นหาชื่อ ตำแหน่ง ฝ่าย หรือกลุ่มสาระ และกรองตามสถานะการทำงาน',
            style: TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          _filterArea(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'พบ ${filtered.length} คน',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textMuted,
                ),
              ),
              const Spacer(),
              if (selectedDepartment != 'ทุกฝ่าย' ||
                  selectedRole != 'ทุกประเภท' ||
                  selectedStatus != 'ทุกสถานะ' ||
                  searchText.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      searchText = '';
                      selectedDepartment = 'ทุกฝ่าย';
                      selectedRole = 'ทุกประเภท';
                      selectedStatus = 'ทุกสถานะ';
                    });
                  },
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 16,
                  ),
                  label: const Text('ล้างตัวกรอง'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            _emptyPersonnel()
          else
            ...filtered.map(_personnelCard),
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
            hintText: 'ค้นหาชื่อ ตำแหน่ง ฝ่าย หรือกลุ่มสาระ...',
            hintStyle: const TextStyle(fontSize: 10),
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

        final department = _dropdownBox(
          value: selectedDepartment,
          items: departments,
          icon: Icons.account_tree_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedDepartment = value);
          },
        );

        final role = _dropdownBox(
          value: selectedRole,
          items: roles,
          icon: Icons.badge_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedRole = value);
          },
        );

        final status = _dropdownBox(
          value: selectedStatus,
          items: statuses,
          icon: Icons.fact_check_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedStatus = value);
          },
        );

        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(child: department),
                  const SizedBox(width: 8),
                  Expanded(child: role),
                ],
              ),
              const SizedBox(height: 9),
              status,
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
            Expanded(child: department),
            const SizedBox(width: 9),
            Expanded(child: role),
            const SizedBox(width: 9),
            Expanded(child: status),
          ],
        );
      },
    );
  }

  Widget _dropdownBox({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: AppPalette.primaryPink,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppPalette.textDark,
                ),
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
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

  Widget _personnelCard(_PersonnelData person) {
    final statusColor = _statusColor(person.status);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _showPersonnelDetail(person),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;

            final avatar = CircleAvatar(
              radius: 23,
              backgroundColor:
                  AppPalette.tint(person.color, 0.12),
              child: Text(
                _firstLetter(person.name),
                style: TextStyle(
                  color: person.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );

            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  person.position,
                  style: const TextStyle(
                    fontSize: 9.8,
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${person.department} • ${person.subjectGroup}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            );

            final status = Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppPalette.tint(statusColor, 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                person.status,
                style: TextStyle(
                  fontSize: 8.8,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            );

            if (compact) {
              return Row(
                children: [
                  avatar,
                  const SizedBox(width: 11),
                  Expanded(child: info),
                  const SizedBox(width: 8),
                  status,
                ],
              );
            }

            return Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: info,
                ),
                Expanded(
                  child: _listMetric(
                    'มาปฏิบัติงาน',
                    '${person.attendance}%',
                  ),
                ),
                Expanded(
                  child: _listMetric(
                    person.teaching > 0
                        ? 'การเข้าสอน'
                        : 'ความคืบหน้างาน',
                    person.teaching > 0
                        ? '${person.teaching}%'
                        : '${person.taskProgress}%',
                  ),
                ),
                const SizedBox(width: 10),
                status,
                const SizedBox(width: 8),
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

  Widget _listMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8.5,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _emptyPersonnel() {
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
            Icons.search_off_rounded,
            size: 34,
            color: AppPalette.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            'ไม่พบบุคลากรตามตัวกรอง',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ลา':
        return AppPalette.warning;
      case 'มาสาย':
        return AppPalette.danger;
      case 'ประชุม/อบรม':
        return AppPalette.learningBlue;
      case 'เข้าสอน':
        return AppPalette.primaryPink;
      default:
        return AppPalette.success;
    }
  }

  String _firstLetter(String name) {
    final clean = name
        .replaceFirst('นาย', '')
        .replaceFirst('นางสาว', '')
        .replaceFirst('นาง', '')
        .trim();

    return clean.isEmpty ? '?' : clean.substring(0, 1);
  }

  void _showDepartmentDetail(_DepartmentData item) {
    final people = personnel
        .where((person) => person.department == item.title)
        .toList();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            item.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _dialogRow('บุคลากรทั้งหมด', '${item.staff} คน'),
                  _dialogRow('มาปฏิบัติงาน', '${item.present} คน'),
                  _dialogRow('ลา', '${item.onLeave} คน'),
                  _dialogRow('ภาระงานเฉลี่ย', '${item.workload}%'),
                  _dialogRow('สถานะที่ควรทราบ', item.issue),
                  const SizedBox(height: 14),
                  const Text(
                    'บุคลากรตัวอย่างในฝ่าย',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (people.isEmpty)
                    const Text(
                      'ยังไม่มีข้อมูลรายบุคคลตัวอย่างในฝ่ายนี้',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppPalette.textMuted,
                      ),
                    )
                  else
                    ...people.map(
                      (person) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              AppPalette.tint(person.color, 0.12),
                          child: Text(
                            _firstLetter(person.name),
                            style: TextStyle(
                              color: person.color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          person.name,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          person.position,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppPalette.textMuted,
                          ),
                        ),
                        trailing: Text(
                          person.status,
                          style: TextStyle(
                            fontSize: 8.8,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(person.status),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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

  void _showPersonnelDetail(_PersonnelData person) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    AppPalette.tint(person.color, 0.12),
                child: Text(
                  _firstLetter(person.name),
                  style: TextStyle(
                    color: person.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  person.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _dialogRow('ตำแหน่ง', person.position),
                  _dialogRow('ฝ่าย', person.department),
                  _dialogRow('ประเภท', person.role),
                  _dialogRow('กลุ่มงาน / กลุ่มสาระ', person.subjectGroup),
                  _dialogRow('สถานะวันนี้', person.status),
                  _dialogRow(
                    'การมาปฏิบัติงาน',
                    '${person.attendance}%',
                  ),
                  if (person.teaching > 0)
                    _dialogRow(
                      'การเข้าสอน',
                      '${person.teaching}%',
                    ),
                  _dialogRow(
                    'ความคืบหน้างาน',
                    '${person.taskProgress}%',
                  ),
                  _dialogRow('อีเมล', person.email),
                  _dialogRow('โทรศัพท์', person.phone),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPalette.tint(
                        person.color,
                        0.07,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ข้อมูลที่ควรทราบ',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          person.note,
                          style: const TextStyle(
                            fontSize: 9.8,
                            height: 1.45,
                            color: AppPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _dialogRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 9.8,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _DepartmentData {
  final String title;
  final String subtitle;
  final int staff;
  final int present;
  final int onLeave;
  final int workload;
  final IconData icon;
  final Color color;
  final String issue;

  const _DepartmentData({
    required this.title,
    required this.subtitle,
    required this.staff,
    required this.present,
    required this.onLeave,
    required this.workload,
    required this.icon,
    required this.color,
    required this.issue,
  });
}

class _SubjectGroupData {
  final String title;
  final int teachers;
  final int attendance;
  final int teaching;
  final int followUp;
  final Color color;

  const _SubjectGroupData(
    this.title,
    this.teachers,
    this.attendance,
    this.teaching,
    this.followUp,
    this.color,
  );
}

class _PersonnelData {
  final String name;
  final String position;
  final String department;
  final String role;
  final String subjectGroup;
  final String status;
  final String email;
  final String phone;
  final int attendance;
  final int teaching;
  final int taskProgress;
  final String note;
  final Color color;

  const _PersonnelData({
    required this.name,
    required this.position,
    required this.department,
    required this.role,
    required this.subjectGroup,
    required this.status,
    required this.email,
    required this.phone,
    required this.attendance,
    required this.teaching,
    required this.taskProgress,
    required this.note,
    required this.color,
  });
}
