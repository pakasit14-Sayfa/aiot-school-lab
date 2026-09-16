import 'dart:convert';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';
import '../../utils/web_download.dart';

typedef ReportsDownloadBytes =
    void Function({
      required String filename,
      required List<int> bytes,
      required String mimeType,
    });

class SchoolReportsPage extends StatefulWidget {
  const SchoolReportsPage({
    super.key,
    this.loadSummary,
    this.loadLogs,
    this.downloadBytesOverride,
  });

  /// Injectable read seams, same pattern as the already-connected School
  /// Admin pages. Production passes nothing and the real service is used;
  /// tests supply these so loading / data / empty / error can each be driven
  /// deterministically without a live Supabase client.
  final Future<SchoolAdminDashboardSummary> Function()? loadSummary;
  final Future<List<SchoolAdminAuditLog>> Function()? loadLogs;
  // Seam for tests: lets a test prove the export button actually calls a
  // download instead of the old always-"still in development" SnackBar.
  final ReportsDownloadBytes? downloadBytesOverride;

  @override
  State<SchoolReportsPage> createState() => _SchoolReportsPageState();
}

class _SchoolReportsPageState extends State<SchoolReportsPage> {
  String _reportType = 'ภาพรวมโรงเรียน';

  SchoolAdminDashboardSummary? _summaryData;
  List<_ReportLog> _logs = [];

  // loading / data / empty / error are tracked separately. Previously this
  // page had none of them: `catch (_) {}` swallowed every failure and the
  // cards fell back to '--', so a failed load was indistinguishable from a
  // school that genuinely has no data yet.
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _hasError = false;
      });
    }
    try {
      final summary = await (widget.loadSummary?.call() ??
          SchoolAdminPlatformService().fetchDashboardSummary());
      final logs = await (widget.loadLogs?.call() ??
          SchoolAdminPlatformService().fetchAuditLogs(limit: 5));
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
        _loading = false;
      });
    } catch (e) {
      debugPrint('SchoolReportsPage load failed: $e');
      if (!mounted) return;
      // Keep the last confirmed data on screen rather than blanking it, and
      // surface the failure instead of hiding it. No raw backend text.
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: SchoolAdminPalette.red,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'โหลดข้อมูลรายงานไม่สำเร็จ กรุณาลองใหม่',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: SchoolAdminPalette.red,
              ),
            ),
          ),
          TextButton(
            onPressed: _loading ? null : _loadReportData,
            style: TextButton.styleFrom(minimumSize: Size.zero),
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _csvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Shared by both CSV and Excel export so the two formats can never drift
  /// apart in content. No RPC computes a per-report-type breakdown, so this
  /// exports the same real summary counts shown on screen — null when there
  /// is nothing loaded yet to export.
  List<List<String>>? _buildReportRows() {
    final s = _summaryData;
    if (s == null) return null;
    return <List<String>>[
      ['metric', 'value'],
      ['students_count', '${s.studentsCount}'],
      ['devices_count', '${s.devicesCount}'],
      ['devices_online', '${s.devicesOnline}'],
      ['buildings_count', '${s.buildingsCount}'],
      ['rooms_count', '${s.roomsCount}'],
      ['open_alerts_count', '${s.openAlertsCount}'],
    ];
  }

  void _exportReport() {
    final rows = _buildReportRows();
    if (rows == null) {
      _message('ยังไม่มีข้อมูลสำหรับส่งออก');
      return;
    }
    final csv = rows.map((row) => row.map(_csvField).join(',')).join('\r\n');
    final doDownload = widget.downloadBytesOverride ?? downloadBytes;
    doDownload(
      filename:
          'school_report_${DateTime.now().toIso8601String().split('T').first}.csv',
      bytes: utf8.encode('﻿$csv'),
      mimeType: 'text/csv',
    );
    _message('ส่งออกรายงานแล้ว (CSV)');
  }

  void _exportReportExcel() {
    final rows = _buildReportRows();
    if (rows == null) {
      _message('ยังไม่มีข้อมูลสำหรับส่งออก');
      return;
    }
    final workbook = xls.Excel.createExcel();
    final sheet = workbook[workbook.getDefaultSheet() ?? 'Sheet1'];
    for (final row in rows) {
      sheet.appendRow(row.map(xls.TextCellValue.new).toList());
    }
    final bytes = workbook.encode();
    if (bytes == null) {
      _message('สร้างไฟล์ Excel ไม่สำเร็จ');
      return;
    }
    final doDownload = widget.downloadBytesOverride ?? downloadBytes;
    doDownload(
      filename:
          'school_report_${DateTime.now().toIso8601String().split('T').first}.xlsx',
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    _message('ส่งออกรายงานแล้ว (Excel)');
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
                  if (_hasError) _errorBanner(),
                  _summary(),
                  const SizedBox(height: 14),
                  _reportTypes(),
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
              PopupMenuButton<String>(
                tooltip: 'ส่งออกรายงาน',
                onSelected: (value) =>
                    value == 'csv' ? _exportReport() : _exportReportExcel(),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'csv', child: Text('ส่งออกเป็น CSV')),
                  PopupMenuItem(value: 'excel', child: Text('ส่งออกเป็น Excel')),
                ],
                child: FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('ส่งออกรายงาน'),
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: SchoolAdminPalette.primaryDark,
                    disabledForegroundColor: Colors.white,
                  ),
                ),
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
    // Three distinct meanings, previously all rendered as '--':
    //   loading  -> '…'
    //   no data  -> 'ยังไม่มีข้อมูล'
    //   real      -> the number, including a real 0
    String value(String Function(SchoolAdminDashboardSummary) read) {
      if (s != null) return read(s);
      return _loading ? '…' : 'ยังไม่มีข้อมูล';
    }

    final data = [
      _Summary(
        'นักเรียน',
        value((v) => v.studentsCount.toString()),
        'รายชื่อในระบบโรงเรียน',
        Icons.groups_rounded,
        SchoolAdminPalette.primaryDark,
      ),
      _Summary(
        'อุปกรณ์',
        value((v) => '${v.devicesCount}'),
        s != null ? 'ออนไลน์ ${s.devicesOnline}' : 'ลงทะเบียนในระบบ',
        Icons.memory_rounded,
        const Color(0xFF4F6078),
      ),
      _Summary(
        'อาคาร / ห้อง',
        value((v) => '${v.buildingsCount} / ${v.roomsCount}'),
        'พื้นที่ที่เปิดใช้งาน',
        Icons.apartment_rounded,
        SchoolAdminPalette.secondary,
      ),
      _Summary(
        'การแจ้งเตือน',
        value((v) => '${v.openAlertsCount}'),
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

  Widget _preview() {
    final s = _summaryData;
    // No backend computes a time-series trend or a per-report-type metric
    // breakdown for this page (school_admin_energy_page /
    // school_resources_page own that for their specific domains). This used
    // to be a hand-drawn chart with values like '386 kWh' and '+4.2%' typed
    // in directly — numbers that never came from anywhere. Show the real
    // counts we do have instead of fabricating a trend we can't back up.
    final metrics = s == null
        ? <_Metric>[]
        : [
            _Metric('นักเรียนในระบบ', '${s.studentsCount} คน'),
            _Metric(
              'อุปกรณ์ออนไลน์',
              '${s.devicesOnline} / ${s.devicesCount}',
            ),
            _Metric('อาคาร / ห้อง', '${s.buildingsCount} / ${s.roomsCount}'),
            _Metric('การแจ้งเตือนที่รอตรวจสอบ', '${s.openAlertsCount} รายการ'),
          ];
    return _section(
      'ตัวอย่างรายงาน: $_reportType',
      // เดิมบรรทัดนี้เขียนว่า "ช่วง <ช่วงเวลา> • <อาคาร> • <ห้อง>" ตามค่าที่
      // เลือกจาก dropdown 3 ตัวด้านบน — แต่ไม่มีตัวไหนกรองข้อมูลจริงเลย
      // สักตัว (ค่าถูกใช้พิมพ์บรรทัดนี้อย่างเดียว) ผู้ดูแลจึงเลือก "อาคารเรียน B"
      // แล้วอ่านตัวเลขทั้งโรงเรียนโดยเข้าใจว่าเป็นของอาคารนั้น dropdown ทั้ง 3
      // ถูกลบทิ้ง และบรรทัดนี้บอกขอบเขตจริงของข้อมูลแทน
      'ภาพรวมทั้งโรงเรียน ณ เวลาที่โหลดล่าสุด',
      metrics.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 16,
              ),
              alignment: Alignment.center,
              child: Text(
                _loading ? 'กำลังโหลด…' : 'ยังไม่มีข้อมูลสำหรับตัวอย่างรายงาน',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, c) {
                int columns = c.maxWidth < 700 ? 1 : 2;
                const gap = 10.0;
                final w = (c.maxWidth - (columns - 1) * gap) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: metrics
                      .map((m) => SizedBox(width: w, child: _MetricCard(m)))
                      .toList(),
                );
              },
            ),
    );
  }

  Widget _insights() {
    final s = _summaryData;
    // These used to be 4 hand-written claims ('อาคารปฏิบัติการใช้ไฟสูงกว่า
    // ค่าเฉลี่ย 14%', 'การเข้าเรียนเฉลี่ยวันนี้ 96.4%'...) with no backend
    // behind any of them — invented every time regardless of the school's
    // real state. Built from the same summary the cards above already load;
    // no interpretive claim we can't support with a real number.
    final data = s == null
        ? <_Insight>[]
        : [
            _Insight(
              s.devicesCount - s.devicesOnline > 0
                  ? 'มีอุปกรณ์ออฟไลน์'
                  : 'อุปกรณ์ออนไลน์ครบ',
              s.devicesCount - s.devicesOnline > 0
                  ? 'อุปกรณ์ออฟไลน์ ${s.devicesCount - s.devicesOnline} จากทั้งหมด ${s.devicesCount} เครื่อง'
                  : 'อุปกรณ์ทั้งหมด ${s.devicesCount} เครื่องออนไลน์อยู่',
              Icons.memory_rounded,
              s.devicesCount - s.devicesOnline > 0
                  ? SchoolAdminPalette.red
                  : SchoolAdminPalette.green,
            ),
            _Insight(
              s.openAlertsCount > 0 ? 'มีการแจ้งเตือนรอตรวจสอบ' : 'ไม่มีการแจ้งเตือนค้าง',
              s.openAlertsCount > 0
                  ? 'มีการแจ้งเตือน ${s.openAlertsCount} รายการที่ยังไม่ได้ตรวจสอบ'
                  : 'ไม่มีการแจ้งเตือนที่รอตรวจสอบในขณะนี้',
              Icons.notifications_active_rounded,
              s.openAlertsCount > 0
                  ? SchoolAdminPalette.red
                  : SchoolAdminPalette.green,
            ),
            _Insight(
              'นักเรียนในระบบ',
              'มีนักเรียนลงทะเบียนในระบบทั้งหมด ${s.studentsCount} คน',
              Icons.school_rounded,
              SchoolAdminPalette.primaryDark,
            ),
            _Insight(
              'อาคารและห้อง',
              'มี ${s.buildingsCount} อาคาร รวม ${s.roomsCount} ห้องที่เปิดใช้งาน',
              Icons.apartment_rounded,
              SchoolAdminPalette.secondary,
            ),
          ];
    return _section(
      'ประเด็นสำคัญจากข้อมูล',
      'สรุปสิ่งที่ควรเห็นก่อนเปิดรายงานฉบับเต็ม',
      data.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 16,
              ),
              alignment: Alignment.center,
              child: Text(
                _loading ? 'กำลังโหลด…' : 'ยังไม่มีข้อมูลสำหรับสรุปประเด็นสำคัญ',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            )
          : LayoutBuilder(
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
              'ระบบยังไม่เก็บประวัติไฟล์รายงานที่เคยส่งออกไว้ในเวอร์ชันนี้',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'กดปุ่ม "ส่งออกรายงาน" ด้านบนเพื่อดาวน์โหลดข้อมูลปัจจุบันเป็น CSV หรือ Excel ได้ทันที',
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
              child: Text(
                // The project-wide empty-state wording is exactly
                // 'ยังไม่มีข้อมูล'; the loading case must not reuse it, or a
                // slow load reads as "this school has no history".
                _loading
                    ? 'กำลังโหลด…'
                    : 'ยังไม่มีข้อมูลประวัติการใช้งานรายงาน',
                style: const TextStyle(
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

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.data);
  final _Metric data;
  @override
  Widget build(BuildContext context) => Container(
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
            data.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          data.value,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
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

class _Metric {
  const _Metric(this.title, this.value);
  final String title, value;
}
