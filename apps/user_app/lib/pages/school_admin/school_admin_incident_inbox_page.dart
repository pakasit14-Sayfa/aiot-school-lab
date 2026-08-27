import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../theme/school_admin_palette.dart';

class SchoolAdminIncidentInboxPage extends StatefulWidget {
  const SchoolAdminIncidentInboxPage({super.key, this.initialIncidents});

  final List<TeacherIncidentReport>? initialIncidents;

  @override
  State<SchoolAdminIncidentInboxPage> createState() =>
      _SchoolAdminIncidentInboxPageState();
}

class _SchoolAdminIncidentInboxPageState
    extends State<SchoolAdminIncidentInboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  String? _loadError;
  List<TeacherIncidentReport> _incidents = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.initialIncidents != null) {
      _incidents = widget.initialIncidents!;
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.initialIncidents != null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final reports = await IncidentService.listTeacherIncidentReports();
      if (!mounted) return;
      setState(() {
        _incidents = reports;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดรายการเหตุการณ์ไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  List<TeacherIncidentReport> _filterByTab(int tabIdx) {
    List<TeacherIncidentReport> base;
    switch (tabIdx) {
      case 1: // New
        base = _incidents.where((i) => i.status == 'new').toList();
        break;
      case 2: // In progress
        base = _incidents
            .where(
              (i) =>
                  i.status == 'acknowledged' ||
                  i.status == 'in_progress' ||
                  i.status == 'escalated',
            )
            .toList();
        break;
      case 3: // Closed
        base = _incidents
            .where((i) => i.status == 'resolved' || i.status == 'cancelled')
            .toList();
        break;
      default: // All
        base = _incidents;
        break;
    }

    if (_searchQuery.trim().isEmpty) return base;
    final q = _searchQuery.trim().toLowerCase();
    return base.where((i) {
      return i.reporterName.toLowerCase().contains(q) ||
          (i.room ?? '').toLowerCase().contains(q) ||
          (i.reason ?? '').toLowerCase().contains(q) ||
          i.id.toLowerCase().contains(q);
    }).toList();
  }

  int _countForTab(int tabIdx) {
    switch (tabIdx) {
      case 1:
        return _incidents.where((i) => i.status == 'new').length;
      case 2:
        return _incidents
            .where(
              (i) =>
                  i.status == 'acknowledged' ||
                  i.status == 'in_progress' ||
                  i.status == 'escalated',
            )
            .length;
      case 3:
        return _incidents
            .where((i) => i.status == 'resolved' || i.status == 'cancelled')
            .length;
      default:
        return _incidents.length;
    }
  }

  Future<void> _acknowledge(TeacherIncidentReport report) async {
    try {
      await IncidentService.acknowledgeIncidentReport(report.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('รับเรื่องเหตุการณ์ ${report.id.substring(0, 8)}... เรียบร้อยแล้ว'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2563EB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('รับเรื่องไม่สำเร็จ: $e')));
    }
  }

  void _showCloseDialog(TeacherIncidentReport report) {
    final noteController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Color(0xFF16A34A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ปิดเหตุการณ์: ${report.id.substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สรุปผลการตรวจสอบและการแก้ไข:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'ระบุผลการตรวจสอบ เช่น ซ่อมบำรุงแล้ว, ส่งต่อเจ้าหน้าที่...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF64748B))),
            ),
            FilledButton.icon(
              onPressed: () async {
                final note = noteController.text.trim();
                if (note.isEmpty) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกสรุปผลการแก้ไข')),
                  );
                  return;
                }
                Navigator.pop(dialogCtx);
                try {
                  await IncidentService.closeIncidentReport(
                    report.id,
                    resolutionType: 'resolved',
                    resolutionNote: note,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('ปิดเหตุการณ์เรียบร้อยแล้ว'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF16A34A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ปิดเหตุการณ์ไม่สำเร็จ: $e')),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('ยืนยันปิดเหตุการณ์'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDetailDialog(TeacherIncidentReport report) async {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return FutureBuilder<IncidentReportDetail>(
          future: IncidentService.getIncidentReport(report.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('กำลังโหลดรายละเอียด...'),
                    ],
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: const Text('เกิดข้อผิดพลาด'),
                content: Text('ไม่สามารถโหลดรายละเอียดได้: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('ปิด'),
                  ),
                ],
              );
            }

            final detail = snapshot.data!;
            final isSos = report.category == IncidentCategory.sos;

            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Container(
                width: 550,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSos ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isSos ? Icons.warning_rounded : Icons.report_problem_rounded,
                                color: isSos ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'รายละเอียดเหตุการณ์ (${isSos ? "SOS ฉุกเฉิน" : "เหตุทั่วไป"})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildDetailRow('รหัสเหตุการณ์:', detail.id),
                    _buildDetailRow('ห้อง / จุดเกิดเหตุ:', detail.room ?? 'ไม่ระบุ'),
                    _buildDetailRow('ผู้แจ้ง:', report.reporterName),
                    _buildDetailRow('เหตุผล / อาการ:', detail.reason ?? 'ไม่ระบุ'),
                    _buildDetailRow('ระดับความรุนแรง:', detail.severity ?? 'ปกติ'),
                    _buildDetailRow('สถานะปัจจุบัน:', detail.status),
                    _buildDetailRow(
                      'เวลาแจ้งเหตุ:',
                      detail.createdAt.toLocal().toString().substring(0, 19),
                    ),
                    if (detail.acknowledgedAt != null)
                      _buildDetailRow(
                        'เวลารับเรื่อง:',
                        detail.acknowledgedAt!.toLocal().toString().substring(0, 19),
                      ),
                    if (detail.resolutionNote != null)
                      _buildDetailRow('บันทึกการปิดเหตุ:', detail.resolutionNote!),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: FilledButton.styleFrom(
                          backgroundColor: SchoolAdminPalette.primaryDark,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('ปิดหน้าต่าง'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _buildErrorView()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1450),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 16),
                            _buildKpiSummaryGrid(),
                            const SizedBox(height: 16),
                            _buildTabsAndFilter(),
                            const SizedBox(height: 16),
                            _buildIncidentList(),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 48),
            const SizedBox(height: 14),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('ลองใหม่'),
              style: FilledButton.styleFrom(
                backgroundColor: SchoolAdminPalette.primaryDark,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleArea = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SchoolAdminPalette.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.inbox_rounded,
                  color: SchoolAdminPalette.primaryDark,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'กล่องข้อความแจ้งเหตุ (Incident & SOS Inbox)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            '${_countForTab(1)} เหตุใหม่',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ศูนย์รับแจ้งเหตุฉุกเฉิน อุบัติเหตุ และรายงานปัญหาความปลอดภัยภายในสถานศึกษา',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionButtons = IconButton(
            onPressed: _load,
            tooltip: 'รีเฟรชข้อมูล',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
          );

          if (constraints.maxWidth < 750) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleArea,
                const SizedBox(height: 14),
                actionButtons,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleArea),
              const SizedBox(width: 16),
              actionButtons,
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiSummaryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKpiCard(
              title: 'เหตุใหม่รอรับเรื่อง',
              value: '${_countForTab(1)} รายการ',
              subtitle: 'New Incident Alert',
              icon: Icons.fiber_new_rounded,
              color: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
              width: isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4,
            ),
            _buildKpiCard(
              title: 'กำลังดำเนินการ',
              value: '${_countForTab(2)} รายการ',
              subtitle: 'In Progress / Action',
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              width: isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4,
            ),
            _buildKpiCard(
              title: 'แก้ไขและปิดแล้ว',
              value: '${_countForTab(3)} รายการ',
              subtitle: 'Resolved Incidents',
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF16A34A),
              bgColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFFBBF7D0),
              width: isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4,
            ),
            _buildKpiCard(
              title: 'รายงานทั้งหมด',
              value: '${_incidents.length} รายการ',
              subtitle: 'All Recorded Events',
              icon: Icons.assignment_rounded,
              color: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
              width: isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsAndFilter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: SchoolAdminPalette.primaryDark,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: SchoolAdminPalette.primaryDark,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
            unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'ทั้งหมด (${_countForTab(0)})'),
              Tab(text: 'เหตุใหม่ (${_countForTab(1)})'),
              Tab(text: 'กำลังดำเนินการ (${_countForTab(2)})'),
              Tab(text: 'ปิดแล้ว (${_countForTab(3)})'),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อผู้แจ้ง, ห้อง หรือรายละเอียดเหตุการณ์...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentList() {
    final list = _filterByTab(_tabController.index);
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF94A3B8)),
            SizedBox(height: 14),
            Text(
              'ไม่มีรายการเหตุการณ์ในหมวดนี้',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildIncidentCard(item);
      },
    );
  }

  Widget _buildIncidentCard(TeacherIncidentReport report) {
    final isSos = report.category == IncidentCategory.sos;
    final isNew = report.status == 'new';
    final isClosed = report.status == 'resolved' || report.status == 'cancelled';

    Color statusColor = const Color(0xFF16A34A);
    Color statusBg = const Color(0xFFF0FDF4);
    String statusLabel = 'ปิดแล้ว';

    if (isNew) {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
      statusLabel = 'เหตุใหม่';
    } else if (!isClosed) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFFBEB);
      statusLabel = 'กำลังดำเนินการ';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
          width: isNew ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isSos ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
            radius: 22,
            child: Icon(
              isSos ? Icons.emergency_rounded : Icons.report_problem_rounded,
              color: isSos ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
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
                        color: isSos ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSos ? const Color(0xFFFECACA) : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Text(
                        isSos ? 'SOS ฉุกเฉิน' : 'แจ้งเหตุทั่วไป',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSos ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Text(
                      report.createdAt.toLocal().toString().substring(0, 16),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ผู้แจ้ง: ${report.reporterName} • ห้อง ${report.room ?? "ไม่ระบุ"}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (report.reason != null && report.reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'อาการ / สาเหตุ: ${report.reason}',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isNew)
                      FilledButton.icon(
                        onPressed: () => _acknowledge(report),
                        icon: const Icon(Icons.check_rounded, size: 14),
                        label: const Text('รับเรื่อง'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    if (!isClosed)
                      OutlinedButton.icon(
                        onPressed: () => _showCloseDialog(report),
                        icon: const Icon(Icons.task_alt_rounded, size: 14),
                        label: const Text('ปิดเหตุการณ์'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF16A34A),
                          side: const BorderSide(color: Color(0xFFBBF7D0)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () => _showDetailDialog(report),
                      icon: const Icon(Icons.info_outline_rounded, size: 14),
                      label: const Text('ดูรายละเอียด'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
