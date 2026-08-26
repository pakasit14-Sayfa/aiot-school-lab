import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../theme/school_admin_palette.dart';

class SchoolReportsPage extends StatefulWidget {
  const SchoolReportsPage({super.key});

  @override
  State<SchoolReportsPage> createState() => _SchoolReportsPageState();
}

class _SchoolReportsPageState extends State<SchoolReportsPage> {
  String _reportType = 'ภาพรวมโรงเรียน';
  String _period = 'เดือนนี้';
  String _building = 'ทุกอาคาร';
  String _room = 'ทุกห้อง';

  SchoolAdminDashboardSummary? _summaryData;
  List<_ReportLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    try {
      final summary = await SchoolAdminPlatformService()
          .fetchDashboardSummary();
      final logs = await SchoolAdminPlatformService().fetchAuditLogs(limit: 5);
      if (!mounted) return;
      setState(() {
        _summaryData = summary;
        _logs = logs
            .map(
              (l) => _ReportLog(
                '${l.createdAt.hour.toString().padLeft(2, '0')}:${l.createdAt.minute.toString().padLeft(2, '0')} น.',
                l.action,
                l.detail.isNotEmpty ? l.detail : l.target,
                l.actorName,
              ),
            )
            .toList();
      });
    } catch (_) {}
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _createReport(String format) {
    _message(
      'ระบบสร้างรายงานรูปแบบ $format ยังอยู่ระหว่างการพัฒนาและยังไม่เชื่อมต่อระบบหลังบ้าน',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 115),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 14),
                  _summary(),
                  const SizedBox(height: 14),
                  _reportTypes(),
                  const SizedBox(height: 14),
                  _filters(),
                  const SizedBox(height: 14),
                  _preview(),
                  const SizedBox(height: 14),
                  _insights(),
                  const SizedBox(height: 14),
                  _recentReports(),
                  const SizedBox(height: 14),
                  _logsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return _box(
      child: LayoutBuilder(
        builder: (context, c) {
          final title = const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: SchoolAdminPalette.primarySoft,
                child: Icon(
                  Icons.assessment_rounded,
                  color: SchoolAdminPalette.primaryDark,
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'รายงาน',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'สรุปข้อมูลนักเรียน อาคาร อุปกรณ์ ไฟฟ้า น้ำ คุณภาพอากาศ การแจ้งเตือน และความปลอดภัย พร้อมสร้างรายงานตามช่วงเวลา',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _createReport('Excel'),
                icon: const Icon(Icons.table_view_rounded),
                label: const Text('ส่งออก Excel'),
              ),
              FilledButton.icon(
                onPressed: () => _createReport('PDF'),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('สร้าง PDF'),
              ),
            ],
          );
          if (c.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 14), actions],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _summary() {
    final s = _summaryData;
    final data = [
      _Summary(
        'นักเรียน',
        s != null ? s.studentsCount.toString() : '--',
        'รายชื่อในระบบโรงเรียน',
        Icons.groups_rounded,
        SchoolAdminPalette.primaryDark,
      ),
      _Summary(
        'อุปกรณ์',
        s != null ? '${s.devicesCount}' : '--',
        s != null ? 'ออนไลน์ ${s.devicesOnline}' : 'ลงทะเบียนในระบบ',
        Icons.memory_rounded,
        const Color(0xFF4F6078),
      ),
      _Summary(
        'อาคาร / ห้อง',
        s != null ? '${s.buildingsCount} / ${s.roomsCount}' : '--',
        'พื้นที่ที่เปิดใช้งาน',
        Icons.apartment_rounded,
        SchoolAdminPalette.secondary,
      ),
      _Summary(
        'การแจ้งเตือน',
        s != null ? '${s.openAlertsCount}' : '--',
        'รายการที่รอตรวจสอบ',
        Icons.notifications_active_rounded,
        SchoolAdminPalette.red,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        int columns = 4;
        if (c.maxWidth < 1050) {
          columns = 2;
        }
        if (c.maxWidth < 300) {
          columns = 1;
        }
        const gap = 12.0;
        final w = (c.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: data
              .map((e) => SizedBox(width: w, child: _SummaryCard(e)))
              .toList(),
        );
      },
    );
  }

  Widget _reportTypes() {
    const data = [
      _Type(
        'ภาพรวมโรงเรียน',
        'นักเรียน อาคาร อุปกรณ์ ทรัพยากร และแจ้งเตือน',
        Icons.dashboard_rounded,
        SchoolAdminPalette.primaryDark,
      ),
      _Type(
        'นักเรียน',
        'จำนวน การเข้าเรียน สถานะบัญชี และรายการที่ควรติดตาม',
        Icons.school_rounded,
        Color(0xFF4F6078),
      ),
      _Type(
        'อุปกรณ์',
        'ออนไลน์ ออฟไลน์ การตรวจความแม่นยำ และเหตุผิดปกติ',
        Icons.memory_rounded,
        SchoolAdminPalette.green,
      ),
      _Type(
        'ไฟฟ้าและน้ำ',
        'ปริมาณการใช้ เปรียบเทียบ และจุดที่ใช้สูงผิดปกติ',
        Icons.energy_savings_leaf_rounded,
        SchoolAdminPalette.secondary,
      ),
      _Type(
        'คุณภาพอากาศ',
        'PM2.5 คุณภาพอากาศ และช่วงเวลาที่ควรติดตาม',
        Icons.air_rounded,
        Color(0xFF71836F),
      ),
      _Type(
        'การแจ้งเตือน',
        'เหตุการณ์ ระดับ ผู้รับผิดชอบ และผลการดำเนินการ',
        Icons.notifications_rounded,
        SchoolAdminPalette.red,
      ),
      _Type(
        'ความปลอดภัย',
        'การเข้าสู่ระบบผิดปกติและประวัติการเข้าถึง',
        Icons.security_rounded,
        Color(0xFF6C5B52),
      ),
      _Type(
        'อาคารและห้อง',
        'จำนวนห้อง ผู้ดูแล อุปกรณ์ และสถานะพื้นที่',
        Icons.apartment_rounded,
        SchoolAdminPalette.primaryDark,
      ),
    ];
    return _section(
      'เลือกรายงานที่ต้องการ',
      'กดเลือกหัวข้อเพื่อดูตัวอย่างและสร้างรายงาน',
      LayoutBuilder(
        builder: (context, c) {
          int columns = 4;
          if (c.maxWidth < 1050) {
            columns = 2;
          }
          if (c.maxWidth < 560) {
            columns = 1;
          }
          const gap = 10.0;
          final w = (c.maxWidth - (columns - 1) * gap) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: data
                .map(
                  (e) => SizedBox(
                    width: w,
                    child: _TypeCard(
                      e,
                      selected: _reportType == e.title,
                      onTap: () => setState(() => _reportType = e.title),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _filters() {
    final period = _Drop('ช่วงเวลา', Icons.date_range_rounded, _period, const [
      'วันนี้',
      '7 วันล่าสุด',
      'เดือนนี้',
      'เดือนที่แล้ว',
      'ปีนี้',
    ], (v) => setState(() => _period = v));
    final building = _Drop('อาคาร', Icons.apartment_rounded, _building, const [
      'ทุกอาคาร',
      'อาคารเรียน A',
      'อาคารเรียน B',
      'อาคารปฏิบัติการ',
      'อาคารอำนวยการ',
      'อาคารกีฬา',
    ], (v) => setState(() => _building = v));
    final room = _Drop('ห้อง', Icons.meeting_room_rounded, _room, const [
      'ทุกห้อง',
      'A-101',
      'A-102',
      'A-201',
      'B-101',
      'LAB-01',
      'LAB-02',
    ], (v) => setState(() => _room = v));
    return _section(
      'กำหนดข้อมูลในรายงาน',
      'เลือกช่วงเวลา อาคาร และห้องก่อนสร้างรายงาน',
      LayoutBuilder(
        builder: (context, c) {
          final reset = OutlinedButton.icon(
            onPressed: () => setState(() {
              _period = 'เดือนนี้';
              _building = 'ทุกอาคาร';
              _room = 'ทุกห้อง';
            }),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('ค่าเริ่มต้น'),
          );
          if (c.maxWidth < 780) {
            return Column(
              children: [
                period,
                const SizedBox(height: 10),
                building,
                const SizedBox(height: 10),
                room,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: reset),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: period),
              const SizedBox(width: 10),
              Expanded(child: building),
              const SizedBox(width: 10),
              Expanded(child: room),
              const SizedBox(width: 10),
              reset,
            ],
          );
        },
      ),
    );
  }

  Widget _preview() {
    return _section(
      'ตัวอย่างรายงาน: $_reportType',
      'ช่วง $_period • $_building • $_room',
      LayoutBuilder(
        builder: (context, c) {
          const chart = _Chart();
          const metrics = Column(
            children: [
              _Metric('การใช้ไฟฟ้า', '386 kWh', '+4.2%', false),
              SizedBox(height: 9),
              _Metric('การใช้น้ำ', '18.4 m³', '-2.1%', true),
              SizedBox(height: 9),
              _Metric('อุปกรณ์ออนไลน์', '146 / 152', '96.1%', true),
              SizedBox(height: 9),
              _Metric('แจ้งเตือนเร่งด่วน', '2 รายการ', 'ต้องติดตาม', false),
            ],
          );
          if (c.maxWidth < 850) {
            return const Column(
              children: [chart, SizedBox(height: 12), metrics],
            );
          }
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: chart),
              SizedBox(width: 14),
              Expanded(flex: 4, child: metrics),
            ],
          );
        },
      ),
    );
  }

  Widget _insights() {
    const data = [
      _Insight(
        'ไฟฟ้าเพิ่มขึ้น',
        'อาคารปฏิบัติการใช้ไฟสูงกว่าค่าเฉลี่ยของช่วงเดียวกันประมาณ 14%',
        Icons.bolt_rounded,
        SchoolAdminPalette.secondary,
      ),
      _Insight(
        'อุปกรณ์ควรตรวจสอบ',
        'พบอุปกรณ์ 6 รายการที่ออฟไลน์ มีคำเตือน หรือส่งข้อมูลไม่ต่อเนื่อง',
        Icons.memory_rounded,
        SchoolAdminPalette.red,
      ),
      _Insight(
        'คุณภาพอากาศส่วนใหญ่ปกติ',
        'พื้นที่ส่วนใหญ่ยังอยู่ในเกณฑ์ปกติ แต่ A-201 มีค่า PM2.5 สูงขึ้น',
        Icons.air_rounded,
        SchoolAdminPalette.green,
      ),
      _Insight(
        'การเข้าเรียนอยู่ในเกณฑ์ดี',
        'การเข้าเรียนเฉลี่ยวันนี้ 96.4% รายการขาดเรียนส่งให้ครูประจำชั้นแล้ว',
        Icons.school_rounded,
        Color(0xFF4F6078),
      ),
    ];
    return _section(
      'ประเด็นสำคัญจากข้อมูล',
      'สรุปสิ่งที่ควรเห็นก่อนเปิดรายงานฉบับเต็ม',
      LayoutBuilder(
        builder: (context, c) {
          int columns = c.maxWidth < 760 ? 1 : 2;
          const gap = 10.0;
          final w = (c.maxWidth - (columns - 1) * gap) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: data
                .map((e) => SizedBox(width: w, child: _InsightCard(e)))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _recentReports() {
    return _section(
      'รายงานที่สร้างล่าสุด',
      'กดดูรายละเอียดหรือดาวน์โหลดรายงานที่เคยสร้างไว้',
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SchoolAdminPalette.border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 36,
              color: SchoolAdminPalette.textSecondary,
            ),
            SizedBox(height: 8),
            Text(
              'ระบบสร้างรายงานและส่งออกไฟล์ยังไม่พร้อมใช้งานในเวอร์ชันนี้',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'การส่งออกข้อมูลเป็นไฟล์ PDF และ Excel อยู่ระหว่างการพัฒนาระบบหลังบ้าน',
              style: TextStyle(
                fontSize: 11,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logsSection() {
    return _section(
      'Log การใช้งานรายงาน',
      'บันทึกว่าใครสร้าง ดู หรือส่งออกรายงานเมื่อไร',
      _logs.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              alignment: Alignment.center,
              child: const Text(
                'ยังไม่มีประวัติการใช้งานรายงาน',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            )
          : Column(
              children: _logs
                  .take(6)
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _LogRow(e),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _box({required Widget child}) => SizedBox(
    width: double.infinity,
    child: Card(
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    ),
  );

  Widget _section(String title, String subtitle, Widget child) => SizedBox(
    width: double.infinity,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.data);
  final _Summary data;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 135),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: SchoolAdminPalette.border),
    ),
    child: Row(
      children: [
        _IconBox(data.icon, data.color),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TypeCard extends StatelessWidget {
  const _TypeCard(this.data, {required this.selected, required this.onTap});
  final _Type data;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? SchoolAdminPalette.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? SchoolAdminPalette.primary
                : SchoolAdminPalette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBox(data.icon, data.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.45,
                      color: SchoolAdminPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              size: 19,
              color: selected
                  ? SchoolAdminPalette.primaryDark
                  : SchoolAdminPalette.textMuted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _Drop extends StatelessWidget {
  const _Drop(this.label, this.icon, this.value, this.items, this.onChanged);
  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            onChanged(v);
          }
        },
      ),
    ),
  );
}

class _Chart extends StatelessWidget {
  const _Chart();
  @override
  Widget build(BuildContext context) => Container(
    height: 270,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: SchoolAdminPalette.border),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'แนวโน้มข้อมูลในช่วงที่เลือก',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: SchoolAdminPalette.textPrimary,
          ),
        ),
        SizedBox(height: 14),
        Expanded(
          child: CustomPaint(painter: _LinePainter(), child: SizedBox.expand()),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ต้นช่วง', style: _axis),
            Text('กลางช่วง', style: _axis),
            Text('ล่าสุด', style: _axis),
          ],
        ),
      ],
    ),
  );
}

const _axis = TextStyle(fontSize: 10.5, color: SchoolAdminPalette.textMuted);

class _LinePainter extends CustomPainter {
  const _LinePainter();
  static const values = [
    0.42,
    0.56,
    0.48,
    0.68,
    0.63,
    0.78,
    0.72,
    0.84,
    0.76,
    0.88,
    0.81,
    0.91,
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = SchoolAdminPalette.border.withAlpha(90)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final line = Paint()
      ..color = SchoolAdminPalette.primaryDark
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - values[i] * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, line);
    final point = Paint()..color = SchoolAdminPalette.primaryDark;
    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - values[i] * size.height;
      canvas.drawCircle(Offset(x, y), 3.2, point);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Metric extends StatelessWidget {
  const _Metric(this.title, this.value, this.change, this.good);
  final String title, value, change;
  final bool good;
  @override
  Widget build(BuildContext context) {
    final color = good ? SchoolAdminPalette.green : SchoolAdminPalette.red;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              change,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard(this.data);
  final _Insight data;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: SchoolAdminPalette.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBox(data.icon, data.color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.detail,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LogRow extends StatelessWidget {
  const _LogRow(this.log);
  final _ReportLog log;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final mobile = c.maxWidth < 760;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: SchoolAdminPalette.border),
        ),
        child: mobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.action,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.detail,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: SchoolAdminPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${log.time} • โดย ${log.by}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: SchoolAdminPalette.green,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  _IconBox(Icons.history_rounded, SchoolAdminPalette.green),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      log.action,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Text(
                      log.detail,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      log.time,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: SchoolAdminPalette.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      log.by,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon, this.color);
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color.withAlpha(24),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withAlpha(80), width: 1.1),
    ),
    child: Icon(icon, color: color, size: 20),
  );
}

class _Summary {
  const _Summary(this.title, this.value, this.detail, this.icon, this.color);
  final String title, value, detail;
  final IconData icon;
  final Color color;
}

class _Type {
  const _Type(this.title, this.subtitle, this.icon, this.color);
  final String title, subtitle;
  final IconData icon;
  final Color color;
}

class _Insight {
  const _Insight(this.title, this.detail, this.icon, this.color);
  final String title, detail;
  final IconData icon;
  final Color color;
}

class _ReportLog {
  const _ReportLog(this.time, this.action, this.detail, this.by);
  final String time, action, detail, by;
}
