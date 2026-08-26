import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    switch (tabIdx) {
      case 1: // New
        return _incidents.where((i) => i.status == 'new').toList();
      case 2: // In progress / acknowledged / escalated
        return _incidents
            .where(
              (i) =>
                  i.status == 'acknowledged' ||
                  i.status == 'in_progress' ||
                  i.status == 'escalated',
            )
            .toList();
      case 3: // Closed
        return _incidents
            .where((i) => i.status == 'resolved' || i.status == 'cancelled')
            .toList();
      default: // All
        return _incidents;
    }
  }

  int _countForTab(int tabIdx) => _filterByTab(tabIdx).length;

  Future<void> _acknowledge(TeacherIncidentReport report) async {
    try {
      await IncidentService.acknowledgeIncidentReport(report.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'รับเรื่องเหตุการณ์ ${report.id.substring(0, 8)}... เรียบร้อยแล้ว',
          ),
          backgroundColor: const Color(0xFF2563EB),
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
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('ปิดเหตุ: ${report.id.substring(0, 8)}...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'สรุปผลการตรวจสอบและการแก้ไข:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'เช่น แก้ไขปัญหาเรียบร้อย ทดสอบใช้งานได้ปกติ...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
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
                    const SnackBar(
                      content: Text('ปิดเหตุการณ์เรียบร้อยแล้ว'),
                      backgroundColor: Color(0xFF059669),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              child: const Text('ยืนยันปิดเหตุ'),
            ),
          ],
        );
      },
    );
  }

  void _showDetailDialog(TeacherIncidentReport report) async {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return FutureBuilder<IncidentReportDetail>(
          future: IncidentService.getIncidentReport(report.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Dialog(
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
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'รายละเอียดเหตุการณ์ (${report.category == IncidentCategory.sos ? "SOS ฉุกเฉิน" : "เหตุทั่วไป"})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildDetailRow('รหัสเหตุการณ์:', detail.id),
                    _buildDetailRow(
                      'ห้อง / จุดเกิดเหตุ:',
                      detail.room ?? 'ไม่ระบุ',
                    ),
                    _buildDetailRow('ผู้แจ้ง:', report.reporterName),
                    _buildDetailRow(
                      'เหตุผล / อาการ:',
                      detail.reason ?? 'ไม่ระบุ',
                    ),
                    _buildDetailRow(
                      'ระดับความรุนแรง:',
                      detail.severity ?? 'ปกติ',
                    ),
                    _buildDetailRow('สถานะปัจจุบัน:', detail.status),
                    _buildDetailRow(
                      'เวลาแจ้งเหตุ:',
                      detail.createdAt.toLocal().toString().substring(0, 19),
                    ),
                    if (detail.acknowledgedAt != null)
                      _buildDetailRow(
                        'เวลารับเรื่อง:',
                        detail.acknowledgedAt!.toLocal().toString().substring(
                          0,
                          19,
                        ),
                      ),
                    if (detail.resolutionNote != null)
                      _buildDetailRow(
                        'บันทึกการปิดเหตุ:',
                        detail.resolutionNote!,
                      ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('กล่องข้อความแจ้งเหตุ (Incident Inbox)'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.fiber_new_rounded,
                      label: 'เหตุใหม่',
                      value: '${_countForTab(1)} รายการ',
                      color: const Color(0xFFDC2626),
                      bg: const Color(0xFFFEF2F2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'กำลังดำเนินการ',
                      value: '${_countForTab(2)} รายการ',
                      color: const Color(0xFFD97706),
                      bg: const Color(0xFFFFFBEB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.task_alt_rounded,
                      label: 'ปิดแล้ว',
                      value: '${_countForTab(3)} รายการ',
                      color: const Color(0xFF059669),
                      bg: const Color(0xFFECFDF5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0F172A),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF2563EB),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'ทั้งหมด (${_countForTab(0)})'),
              Tab(text: 'เหตุใหม่ (${_countForTab(1)}) 🔴'),
              Tab(text: 'กำลังดำเนินการ (${_countForTab(2)}) 🟡'),
              Tab(text: 'ปิดแล้ว (${_countForTab(3)}) 🟢'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(4, (tabIdx) {
              final filtered = _filterByTab(tabIdx);
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inbox_rounded,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ไม่มีรายการเหตุการณ์ในหมวดนี้',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: filtered.length,
                itemBuilder: (context, idx) {
                  final item = filtered[idx];
                  return _buildIncidentCard(item);
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFF87171),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ศูนย์รับแจ้งเหตุการณ์และข้อขัดข้อง',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ติดตามและจัดการข้อขัดข้องอุปกรณ์และเหตุฉุกเฉินทั่วทั้งโรงเรียน',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

  Widget _buildIncidentCard(TeacherIncidentReport item) {
    final isSos = item.category == IncidentCategory.sos;
    final isNew = item.status == 'new';
    final isClosed = item.status == 'resolved' || item.status == 'cancelled';

    Color badgeBg;
    Color badgeBorder;
    Color badgeText;

    if (isSos || item.severity == 'critical') {
      badgeBg = const Color(0xFFFEF2F2);
      badgeBorder = const Color(0xFFFCA5A5);
      badgeText = const Color(0xFFDC2626);
    } else if (item.status == 'acknowledged' || item.status == 'in_progress') {
      badgeBg = const Color(0xFFFFFBEB);
      badgeBorder = const Color(0xFFFCD34D);
      badgeText = const Color(0xFFD97706);
    } else if (isClosed) {
      badgeBg = const Color(0xFFECFDF5);
      badgeBorder = const Color(0xFFA7F3D0);
      badgeText = const Color(0xFF059669);
    } else {
      badgeBg = const Color(0xFFEFF6FF);
      badgeBorder = const Color(0xFFBFDBFE);
      badgeText = const Color(0xFF2563EB);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeBorder),
                  ),
                  child: Text(
                    isSos ? '🚨 SOS' : '⚠️ รายงานเหตุ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: badgeText,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.id.length > 8 ? item.id.substring(0, 8) : item.id,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Text(
                  item.createdAt.toLocal().toString().substring(0, 16),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.reason ?? 'ไม่มีระบุหัวข้อเหตุการณ์',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ห้อง/จุดเกิดเหตุ: ${item.room ?? "ไม่ระบุ"} · ผู้แจ้ง: ${item.reporterName}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showDetailDialog(item),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('ดูรายละเอียด'),
                ),
                if (isNew) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _acknowledge(item),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('รับเรื่อง'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
                if (!isNew && !isClosed) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCloseDialog(item),
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('ปิดเหตุ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
