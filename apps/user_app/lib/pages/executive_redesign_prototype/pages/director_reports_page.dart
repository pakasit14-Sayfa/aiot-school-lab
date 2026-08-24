import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorReportsPage extends StatefulWidget {
  const DirectorReportsPage({super.key});

  @override
  State<DirectorReportsPage> createState() =>
      _DirectorReportsPageState();
}

class _DirectorReportsPageState extends State<DirectorReportsPage> {
  String searchText = '';
  String selectedDepartment = 'ทุกฝ่าย';
  String selectedReportType = 'ทุกประเภท';
  String selectedFileType = 'ทุกไฟล์';
  String selectedStatus = 'ทุกสถานะ';

  final List<String> departments = const [
    'ทุกฝ่าย',
    'ฝ่ายบริหาร',
    'ฝ่ายวิชาการ',
    'ฝ่ายกิจการนักเรียน',
    'ฝ่ายบุคคลและธุรการ',
    'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
    'ฝ่ายเทคโนโลยีและระบบ',
    'ระบบอัตโนมัติ',
  ];

  final List<String> reportTypes = const [
    'ทุกประเภท',
    'รายวัน',
    'รายสัปดาห์',
    'รายเดือน',
    'ภาคเรียน',
    'เหตุการณ์',
    'เฉพาะกิจ',
  ];

  final List<String> fileTypes = const [
    'ทุกไฟล์',
    'PDF',
    'Excel',
    'Word',
  ];

  final List<String> statuses = const [
    'ทุกสถานะ',
    'ส่งแล้ว',
    'รอตรวจ',
    'อนุมัติแล้ว',
    'ต้องแก้ไข',
    'เกินกำหนด',
  ];

  final List<_ReportFileData> reports = const [
    _ReportFileData(
      title: 'รายงานสรุปการมาเรียนประจำวัน',
      fileName: 'Attendance_Daily_20-08-2569.pdf',
      fileType: 'PDF',
      fileSize: '2.4 MB',
      pages: 18,
      senderName: 'นางสาวอรทัย พัฒนกิจ',
      senderRole: 'หัวหน้าฝ่ายวิชาการ',
      department: 'ฝ่ายวิชาการ',
      reportType: 'รายวัน',
      period: '20 ส.ค. 2569',
      submittedAt: '20 ส.ค. 2569 • 16:42 น.',
      status: 'อนุมัติแล้ว',
      description:
          'สรุปการมาเรียน ขาดเรียน มาสาย และนักเรียนที่ต้องติดตาม แยกระดับชั้น ม.1-ม.6',
      remark:
          'มีนักเรียนขาดเรียนต่อเนื่อง 11 คน ส่งรายชื่อให้ครูประจำชั้นติดตามแล้ว',
      color: AppPalette.learningBlue,
    ),
    _ReportFileData(
      title: 'รายงานเหตุการณ์และความปลอดภัยประจำวัน',
      fileName: 'Safety_Incident_Daily_20-08-2569.pdf',
      fileType: 'PDF',
      fileSize: '1.8 MB',
      pages: 12,
      senderName: 'นายณัฐวุฒิ มั่นคง',
      senderRole: 'หัวหน้าฝ่ายกิจการนักเรียน',
      department: 'ฝ่ายกิจการนักเรียน',
      reportType: 'รายวัน',
      period: '20 ส.ค. 2569',
      submittedAt: '20 ส.ค. 2569 • 17:05 น.',
      status: 'รอตรวจ',
      description:
          'สรุปเหตุการณ์ในโรงเรียน การแจ้งเตือน ความปลอดภัย และเคสที่ฝ่ายกิจการนักเรียนกำลังติดตาม',
      remark:
          'มีเหตุการณ์ที่ต้องติดตาม 2 รายการ ไม่มีเหตุฉุกเฉินระดับรุนแรง',
      color: AppPalette.chartPink,
    ),
    _ReportFileData(
      title: 'รายงานการใช้น้ำและไฟประจำสัปดาห์',
      fileName: 'Utility_Weekly_W3_Aug2569.pdf',
      fileType: 'PDF',
      fileSize: '4.1 MB',
      pages: 24,
      senderName: 'นายประสิทธิ์ ช่างดี',
      senderRole: 'เจ้าหน้าที่อาคารสถานที่',
      department: 'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
      reportType: 'รายสัปดาห์',
      period: '14-20 ส.ค. 2569',
      submittedAt: '20 ส.ค. 2569 • 15:18 น.',
      status: 'รอตรวจ',
      description:
          'เปรียบเทียบการใช้น้ำและไฟรายวัน พร้อมจุดที่ใช้สูงกว่าค่าเฉลี่ยและข้อเสนอแนะการตรวจสอบ',
      remark:
          'อาคาร 2 ใช้น้ำสูงกว่าค่าเฉลี่ยประมาณ 28% อยู่ระหว่างตรวจสอบระบบท่อ',
      color: AppPalette.warning,
    ),
    _ReportFileData(
      title: 'รายงานภาพรวมสิ่งแวดล้อมในห้องเรียน',
      fileName: 'Environment_Classroom_Aug2569.pdf',
      fileType: 'PDF',
      fileSize: '3.6 MB',
      pages: 21,
      senderName: 'AIoT Smart Lab',
      senderRole: 'ระบบสร้างรายงานอัตโนมัติ',
      department: 'ระบบอัตโนมัติ',
      reportType: 'รายเดือน',
      period: '1-20 ส.ค. 2569',
      submittedAt: '20 ส.ค. 2569 • 18:00 น.',
      status: 'ส่งแล้ว',
      description:
          'สรุป PM2.5 อุณหภูมิ ความเข้มแสง CO₂ ก๊าซมีเทน และการตรวจจับควันของห้องเรียนที่เชื่อมต่อ',
      remark:
          'ค่าภาพรวมอยู่ในเกณฑ์ปกติ มี 3 ห้องที่ควรตรวจเรื่องแสงสว่าง',
      color: AppPalette.environmentGreen,
    ),
    _ReportFileData(
      title: 'รายงานผลการเรียนและงานค้างนักเรียน',
      fileName: 'Learning_Assignment_Weekly_20-08-2569.pdf',
      fileType: 'PDF',
      fileSize: '5.2 MB',
      pages: 32,
      senderName: 'นางสาวอรทัย พัฒนกิจ',
      senderRole: 'หัวหน้าฝ่ายวิชาการ',
      department: 'ฝ่ายวิชาการ',
      reportType: 'รายสัปดาห์',
      period: '14-20 ส.ค. 2569',
      submittedAt: '20 ส.ค. 2569 • 16:10 น.',
      status: 'อนุมัติแล้ว',
      description:
          'สรุปคะแนนภาพรวม งานที่ครูมอบหมาย งานค้าง และนักเรียนที่มีผลการเรียนต่ำกว่าเกณฑ์ แยกตามห้อง',
      remark:
          'มีนักเรียน 9 คนที่ควรจัดสอนเสริม และ 5 ห้องที่มีงานค้างสูงกว่าค่าเฉลี่ย',
      color: AppPalette.primaryPink,
    ),
    _ReportFileData(
      title: 'รายงานการปฏิบัติงานครูและบุคลากร',
      fileName: 'Personnel_Attendance_Aug2569.pdf',
      fileType: 'PDF',
      fileSize: '2.9 MB',
      pages: 19,
      senderName: 'นางสาวสุภาวดี ศรีสุข',
      senderRole: 'เจ้าหน้าที่งานบุคคล',
      department: 'ฝ่ายบุคคลและธุรการ',
      reportType: 'รายเดือน',
      period: '1-20 ส.ค. 2569',
      submittedAt: '20 ส.ค. 2569 • 14:25 น.',
      status: 'อนุมัติแล้ว',
      description:
          'สรุปการมาปฏิบัติงาน การลา มาสาย ภาระงาน และสถานะบุคลากรแยกตามฝ่าย',
      remark:
          'อัตรามาปฏิบัติงานเฉลี่ย 95.3% ไม่มีฝ่ายใดมีบุคลากรขาดเกินเกณฑ์',
      color: AppPalette.chartCream,
    ),
    _ReportFileData(
      title: 'รายงานสรุปผลการประชุมฝ่ายบริหาร',
      fileName: 'Management_Meeting_20-08-2569.pdf',
      fileType: 'PDF',
      fileSize: '1.2 MB',
      pages: 9,
      senderName: 'นางสาวกมลชนก ธุรการดี',
      senderRole: 'เจ้าหน้าที่ธุรการ',
      department: 'ฝ่ายบุคคลและธุรการ',
      reportType: 'เหตุการณ์',
      period: 'ประชุมวันที่ 20 ส.ค. 2569',
      submittedAt: '20 ส.ค. 2569 • 11:32 น.',
      status: 'ส่งแล้ว',
      description:
          'บันทึกการประชุม มติที่ประชุม ผู้รับผิดชอบ และกำหนดเวลาติดตามงานแต่ละฝ่าย',
      remark:
          'มีมติให้ฝ่ายอาคารตรวจสอบน้ำอาคาร 2 และฝ่ายวิชาการติดตามนักเรียนขาดเรียนต่อเนื่อง',
      color: AppPalette.chartPink2,
    ),
    _ReportFileData(
      title: 'รายงานงบประมาณและค่าใช้จ่ายประจำเดือน',
      fileName: 'Budget_Aug2569.pdf',
      fileType: 'PDF',
      fileSize: '6.7 MB',
      pages: 41,
      senderName: 'นายสมชาย บริหารดี',
      senderRole: 'รองผู้อำนวยการฝ่ายบริหาร',
      department: 'ฝ่ายบริหาร',
      reportType: 'รายเดือน',
      period: 'ส.ค. 2569',
      submittedAt: '19 ส.ค. 2569 • 16:55 น.',
      status: 'ต้องแก้ไข',
      description:
          'สรุปรายรับ รายจ่าย งบคงเหลือ ค่าใช้จ่ายด้านอาคาร ทรัพยากร และกิจกรรมการเรียนการสอน',
      remark:
          'ผู้อำนวยการขอให้เพิ่มรายละเอียดค่าใช้จ่ายซ่อมบำรุงอาคาร 2 ก่อนอนุมัติ',
      color: AppPalette.danger,
    ),
    _ReportFileData(
      title: 'ข้อมูลรายชื่อนักเรียนที่ต้องติดตาม',
      fileName: 'Student_FollowUp_List_Aug2569.xlsx',
      fileType: 'Excel',
      fileSize: '860 KB',
      pages: 0,
      senderName: 'นายณัฐวุฒิ มั่นคง',
      senderRole: 'หัวหน้าฝ่ายกิจการนักเรียน',
      department: 'ฝ่ายกิจการนักเรียน',
      reportType: 'เฉพาะกิจ',
      period: 'ข้อมูล ณ 20 ส.ค. 2569',
      submittedAt: '20 ส.ค. 2569 • 13:48 น.',
      status: 'ส่งแล้ว',
      description:
          'รายชื่อนักเรียนที่ต้องติดตามด้านการมาเรียน พฤติกรรม และการประสานผู้ปกครอง',
      remark:
          'ใช้ประกอบการติดตามรายบุคคล ไม่ใช่รายงานสรุปสำหรับนำเสนอ',
      color: AppPalette.success,
    ),
    _ReportFileData(
      title: 'แผนดำเนินงานพัฒนาระบบสารสนเทศ',
      fileName: 'IT_System_Plan_Semester1.docx',
      fileType: 'Word',
      fileSize: '1.5 MB',
      pages: 0,
      senderName: 'นายธนกฤต ระบบดี',
      senderRole: 'เจ้าหน้าที่ระบบสารสนเทศ',
      department: 'ฝ่ายเทคโนโลยีและระบบ',
      reportType: 'ภาคเรียน',
      period: 'ภาคเรียนที่ 1/2569',
      submittedAt: '18 ส.ค. 2569 • 10:15 น.',
      status: 'รอตรวจ',
      description:
          'แผนงานดูแลระบบ AIoT ฐานข้อมูล อุปกรณ์ เครือข่าย และแผนสำรองข้อมูลตลอดภาคเรียน',
      remark:
          'เสนอช่วงเวลาบำรุงรักษาระบบหลังเลิกเรียนเพื่อลดผลกระทบต่อผู้ใช้งาน',
      color: AppPalette.learningBlue,
    ),
  ];

  final List<_PendingReportData> pendingReports = const [
    _PendingReportData(
      title: 'รายงานสรุปผลการสอนรายสัปดาห์',
      responsible: 'หัวหน้ากลุ่มสาระทุกกลุ่ม',
      department: 'ฝ่ายวิชาการ',
      dueDate: 'วันนี้ • 18:00 น.',
      submitted: 6,
      total: 8,
      status: 'รอ 2 กลุ่มสาระ',
      color: AppPalette.warning,
    ),
    _PendingReportData(
      title: 'รายงานตรวจอาคารและระบบสาธารณูปโภค',
      responsible: 'ฝ่ายอาคารสถานที่',
      department: 'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
      dueDate: '22 ส.ค. • 16:00 น.',
      submitted: 0,
      total: 1,
      status: 'ยังไม่ส่ง',
      color: AppPalette.learningBlue,
    ),
    _PendingReportData(
      title: 'รายงานสรุปกิจกรรมนักเรียนประจำเดือน',
      responsible: 'ฝ่ายกิจการนักเรียน',
      department: 'ฝ่ายกิจการนักเรียน',
      dueDate: '31 ส.ค. • 17:00 น.',
      submitted: 0,
      total: 1,
      status: 'ยังไม่ถึงกำหนด',
      color: AppPalette.environmentGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReports();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DirectorSectionHeader(
            title: 'รายงานผู้บริหาร',
            subtitle:
                'ติดตามว่าใครส่งรายงาน ไฟล์อะไร ส่งเมื่อไร อยู่ฝ่ายไหน และสถานะการตรวจเป็นอย่างไร โดยเน้นรายงาน PDF เป็นหลัก',
          ),
          const SizedBox(height: 14),
          _summaryCards(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 980) {
                return Column(
                  children: [
                    _recentPdfCard(),
                    const SizedBox(height: 16),
                    _pendingReportsCard(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _recentPdfCard(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _pendingReportsCard(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _allReportsSection(filtered),
        ],
      ),
    );
  }

  List<_ReportFileData> _filteredReports() {
    final query = searchText.trim().toLowerCase();

    return reports.where((report) {
      final matchesSearch = query.isEmpty ||
          report.title.toLowerCase().contains(query) ||
          report.fileName.toLowerCase().contains(query) ||
          report.senderName.toLowerCase().contains(query) ||
          report.senderRole.toLowerCase().contains(query) ||
          report.department.toLowerCase().contains(query);

      final matchesDepartment =
          selectedDepartment == 'ทุกฝ่าย' ||
          report.department == selectedDepartment;

      final matchesType =
          selectedReportType == 'ทุกประเภท' ||
          report.reportType == selectedReportType;

      final matchesFile =
          selectedFileType == 'ทุกไฟล์' ||
          report.fileType == selectedFileType;

      final matchesStatus =
          selectedStatus == 'ทุกสถานะ' ||
          report.status == selectedStatus;

      return matchesSearch &&
          matchesDepartment &&
          matchesType &&
          matchesFile &&
          matchesStatus;
    }).toList();
  }

  Widget _summaryCards() {
    const items = [
      _ReportSummary(
        title: 'รายงานทั้งหมด',
        value: '128',
        subtitle: 'ภาคเรียนปัจจุบัน',
        icon: Icons.folder_copy_rounded,
        color: AppPalette.softPink,
      ),
      _ReportSummary(
        title: 'PDF',
        value: '102',
        subtitle: '79.7% ของไฟล์ทั้งหมด',
        icon: Icons.picture_as_pdf_rounded,
        color: AppPalette.softPink2,
      ),
      _ReportSummary(
        title: 'ส่งวันนี้',
        value: '8',
        subtitle: 'จาก 6 ฝ่าย',
        icon: Icons.upload_file_rounded,
        color: AppPalette.softBlue,
      ),
      _ReportSummary(
        title: 'รอตรวจ',
        value: '12',
        subtitle: 'ต้องตรวจภายในสัปดาห์นี้',
        icon: Icons.rate_review_rounded,
        color: AppPalette.softCream,
      ),
      _ReportSummary(
        title: 'ต้องแก้ไข',
        value: '3',
        subtitle: 'ส่งกลับผู้จัดทำแล้ว',
        icon: Icons.edit_document,
        color: AppPalette.softPink2,
      ),
      _ReportSummary(
        title: 'เกินกำหนด',
        value: '2',
        subtitle: 'ควรติดตามผู้รับผิดชอบ',
        icon: Icons.warning_amber_rounded,
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

  Widget _recentPdfCard() {
    final pdfs = reports
        .where((report) => report.fileType == 'PDF')
        .take(5)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PDF ล่าสุดที่ส่งเข้าระบบ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'แสดงชื่อไฟล์ ผู้ส่ง ฝ่าย และเวลาที่ส่ง เพื่อให้ตรวจสอบแหล่งที่มาของรายงานได้ทันที',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...pdfs.map(_recentPdfTile),
        ],
      ),
    );
  }

  Widget _recentPdfTile(_ReportFileData report) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showReportDetail(report),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppPalette.tint(
            AppPalette.danger,
            0.045,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppPalette.tint(
              AppPalette.danger,
              0.10,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: AppPalette.tint(
                  AppPalette.danger,
                  0.11,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 20,
                color: AppPalette.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    report.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ส่งโดย ${report.senderName} • ${report.department}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8.7,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${report.submittedAt} • ${report.fileSize} • ${report.pages} หน้า',
                    style: const TextStyle(
                      fontSize: 8.2,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            _statusTag(report.status),
          ],
        ),
      ),
    );
  }

  Widget _pendingReportsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายงานที่กำลังรอส่ง',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ดูผู้รับผิดชอบ กำหนดส่ง และจำนวนที่ส่งแล้ว',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...pendingReports.map(_pendingReportTile),
        ],
      ),
    );
  }

  Widget _pendingReportTile(_PendingReportData item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.tint(item.color, 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPalette.tint(item.color, 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${item.responsible} • ${item.department}',
            style: const TextStyle(
              fontSize: 8.7,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'กำหนดส่ง ${item.dueDate}',
                  style: const TextStyle(
                    fontSize: 8.7,
                    color: AppPalette.textMuted,
                  ),
                ),
              ),
              Text(
                item.status,
                style: TextStyle(
                  fontSize: 8.8,
                  fontWeight: FontWeight.w700,
                  color: item.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: item.total == 0
                  ? 0
                  : item.submitted / item.total,
              minHeight: 6,
              backgroundColor: AppPalette.softTag,
              valueColor:
                  AlwaysStoppedAnimation<Color>(item.color),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'ส่งแล้ว ${item.submitted}/${item.total}',
            style: const TextStyle(
              fontSize: 8,
              color: AppPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _allReportsSection(
    List<_ReportFileData> filtered,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ไฟล์รายงานทั้งหมด',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ค้นหาจากชื่อรายงาน ชื่อไฟล์ ผู้ส่ง หรือตำแหน่ง และกรองตามฝ่าย ประเภทรายงาน ประเภทไฟล์ หรือสถานะ',
            style: TextStyle(
              fontSize: 10,
              color: AppPalette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          _filtersArea(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'พบ ${filtered.length} ไฟล์',
                style: const TextStyle(
                  fontSize: 10,
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
                    size: 16,
                  ),
                  label: const Text('ล้างตัวกรอง'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            _emptyReports()
          else
            ...filtered.map(_reportFileTile),
        ],
      ),
    );
  }

  Widget _filtersArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;

        final search = TextField(
          onChanged: (value) {
            setState(() => searchText = value);
          },
          decoration: InputDecoration(
            hintText:
                'ค้นหาชื่อรายงาน ไฟล์ ผู้ส่ง หรือฝ่าย...',
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

        final department = _dropdown(
          value: selectedDepartment,
          items: departments,
          icon: Icons.account_tree_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedDepartment = value);
          },
        );

        final type = _dropdown(
          value: selectedReportType,
          items: reportTypes,
          icon: Icons.description_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedReportType = value);
          },
        );

        final file = _dropdown(
          value: selectedFileType,
          items: fileTypes,
          icon: Icons.attach_file_rounded,
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedFileType = value);
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

        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: department),
                  const SizedBox(width: 8),
                  Expanded(child: type),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: file),
                  const SizedBox(width: 8),
                  Expanded(child: status),
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
                Expanded(child: department),
                const SizedBox(width: 9),
                Expanded(child: type),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: file),
                const SizedBox(width: 9),
                Expanded(child: status),
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
                  fontSize: 9.5,
                  color: AppPalette.textDark,
                ),
                items: items
                    .map(
                      (item) =>
                          DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
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

  Widget _reportFileTile(_ReportFileData report) {
    final fileColor = _fileColor(report.fileType);
    final statusColor = _statusColor(report.status);

    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => _showReportDetail(report),
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
            final compact =
                constraints.maxWidth < 760;

            if (compact) {
              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _fileIcon(report),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _reportMainInfo(report),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _smallTag(
                        report.fileType,
                        fileColor,
                      ),
                      _smallTag(
                        report.reportType,
                        report.color,
                      ),
                      _smallTag(
                        report.status,
                        statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ส่งโดย ${report.senderName} • ${report.submittedAt}',
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                _fileIcon(report),
                const SizedBox(width: 11),
                Expanded(
                  flex: 3,
                  child: _reportMainInfo(report),
                ),
                Expanded(
                  flex: 2,
                  child: _listInfo(
                    'ผู้ส่ง',
                    report.senderName,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _listInfo(
                    'ฝ่าย',
                    report.department,
                  ),
                ),
                Expanded(
                  child: _listInfo(
                    'ประเภท',
                    report.fileType,
                  ),
                ),
                Expanded(
                  child: _listInfo(
                    'ขนาด',
                    report.fileSize,
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
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.status,
                    style: TextStyle(
                      fontSize: 8.4,
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

  Widget _fileIcon(_ReportFileData report) {
    final color = _fileColor(report.fileType);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _fileIconData(report.fileType),
        size: 21,
        color: color,
      ),
    );
  }

  Widget _reportMainInfo(_ReportFileData report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          report.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          report.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8.7,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${report.reportType} • ${report.period}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8.2,
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
            fontSize: 8.1,
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
            fontSize: 8.8,
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
          fontSize: 8.2,
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

  bool _hasActiveFilters() {
    return searchText.isNotEmpty ||
        selectedDepartment != 'ทุกฝ่าย' ||
        selectedReportType != 'ทุกประเภท' ||
        selectedFileType != 'ทุกไฟล์' ||
        selectedStatus != 'ทุกสถานะ';
  }

  void _clearFilters() {
    setState(() {
      searchText = '';
      selectedDepartment = 'ทุกฝ่าย';
      selectedReportType = 'ทุกประเภท';
      selectedFileType = 'ทุกไฟล์';
      selectedStatus = 'ทุกสถานะ';
    });
  }

  Widget _emptyReports() {
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
            Icons.find_in_page_rounded,
            size: 34,
            color: AppPalette.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            'ไม่พบไฟล์รายงานตามเงื่อนไข',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _fileColor(String fileType) {
    switch (fileType) {
      case 'PDF':
        return AppPalette.danger;
      case 'Excel':
        return AppPalette.success;
      case 'Word':
        return AppPalette.learningBlue;
      default:
        return AppPalette.textMuted;
    }
  }

  IconData _fileIconData(String fileType) {
    switch (fileType) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'Excel':
        return Icons.table_chart_rounded;
      case 'Word':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'อนุมัติแล้ว':
        return AppPalette.success;
      case 'รอตรวจ':
        return AppPalette.warning;
      case 'ต้องแก้ไข':
        return AppPalette.danger;
      case 'เกินกำหนด':
        return AppPalette.danger;
      default:
        return AppPalette.learningBlue;
    }
  }

  void _showReportDetail(_ReportFileData report) {
    final fileColor = _fileColor(report.fileType);
    final statusColor = _statusColor(report.status);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppPalette.tint(
                            fileColor,
                            0.10,
                          ),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _fileIconData(report.fileType),
                          color: fileColor,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              report.fileName,
                              style: const TextStyle(
                                fontSize: 9.5,
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
                        report.fileType,
                        fileColor,
                      ),
                      _smallTag(
                        report.reportType,
                        report.color,
                      ),
                      _smallTag(
                        report.status,
                        statusColor,
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
                          _detailSectionTitle(
                            'ข้อมูลไฟล์',
                          ),
                          _detailRow(
                            'ชื่อไฟล์',
                            report.fileName,
                          ),
                          _detailRow(
                            'ประเภทไฟล์',
                            report.fileType,
                          ),
                          _detailRow(
                            'ขนาดไฟล์',
                            report.fileSize,
                          ),
                          if (report.pages > 0)
                            _detailRow(
                              'จำนวนหน้า',
                              '${report.pages} หน้า',
                            ),
                          _detailRow(
                            'ช่วงข้อมูล',
                            report.period,
                          ),
                          const SizedBox(height: 13),
                          _detailSectionTitle(
                            'ข้อมูลผู้ส่ง',
                          ),
                          _detailRow(
                            'ผู้ส่ง',
                            report.senderName,
                          ),
                          _detailRow(
                            'ตำแหน่ง',
                            report.senderRole,
                          ),
                          _detailRow(
                            'ฝ่าย',
                            report.department,
                          ),
                          _detailRow(
                            'ส่งเมื่อ',
                            report.submittedAt,
                          ),
                          const SizedBox(height: 13),
                          _detailSectionTitle(
                            'รายละเอียดรายงาน',
                          ),
                          Text(
                            report.description,
                            style: const TextStyle(
                              fontSize: 9.7,
                              height: 1.5,
                              color:
                                  AppPalette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 13),
                          _detailSectionTitle(
                            'หมายเหตุ / ประเด็นสำคัญ',
                          ),
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppPalette.tint(
                                report.color,
                                0.06,
                              ),
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Text(
                              report.remark,
                              style: const TextStyle(
                                fontSize: 9.7,
                                height: 1.5,
                                color:
                                    AppPalette.textMuted,
                              ),
                            ),
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

                      final viewButton =
                          OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showMessage(
                            'เปิดดู ${report.fileName}',
                          );
                        },
                        icon: const Icon(
                          Icons.visibility_rounded,
                          size: 16,
                        ),
                        label: const Text('เปิดดูไฟล์'),
                      );

                      final downloadButton =
                          FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              AppPalette.primaryPink,
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showMessage(
                            'เริ่มดาวน์โหลด ${report.fileName}',
                          );
                        },
                        icon: const Icon(
                          Icons.download_rounded,
                          size: 16,
                        ),
                        label:
                            const Text('ดาวน์โหลด'),
                      );

                      if (compact) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: viewButton,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: downloadButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: viewButton),
                          const SizedBox(width: 9),
                          Expanded(
                            child: downloadButton,
                          ),
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

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 9.2,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 9.8,
                fontWeight: FontWeight.w600,
              ),
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

class _ReportSummary {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ReportSummary({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _ReportFileData {
  final String title;
  final String fileName;
  final String fileType;
  final String fileSize;
  final int pages;
  final String senderName;
  final String senderRole;
  final String department;
  final String reportType;
  final String period;
  final String submittedAt;
  final String status;
  final String description;
  final String remark;
  final Color color;

  const _ReportFileData({
    required this.title,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.pages,
    required this.senderName,
    required this.senderRole,
    required this.department,
    required this.reportType,
    required this.period,
    required this.submittedAt,
    required this.status,
    required this.description,
    required this.remark,
    required this.color,
  });
}

class _PendingReportData {
  final String title;
  final String responsible;
  final String department;
  final String dueDate;
  final int submitted;
  final int total;
  final String status;
  final Color color;

  const _PendingReportData({
    required this.title,
    required this.responsible,
    required this.department,
    required this.dueDate,
    required this.submitted,
    required this.total,
    required this.status,
    required this.color,
  });
}
