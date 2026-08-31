import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

Color _categoryColor(IncidentCategory c) => c == IncidentCategory.sos
    ? const Color(0xFFDC2626)
    : const Color(0xFFD97706);

String _categoryLabel(IncidentCategory c) =>
    c == IncidentCategory.sos ? 'SOS ฉุกเฉิน' : 'แจ้งเหตุผิดปกติ';

String _statusLabel(String status) => switch (status) {
  'new' => 'รอตรวจสอบ',
  'acknowledged' => 'รับเรื่องแล้ว',
  'in_progress' => 'กำลังดำเนินการ',
  'escalated' => 'ยกระดับแล้ว',
  'resolved' => 'ปิดเหตุแล้ว (เหตุจริง)',
  'cancelled' => 'ปิดเหตุแล้ว (แจ้งเท็จ)',
  _ => status,
};

Color _statusColor(String status) => switch (status) {
  'new' => TeacherPalette.muted,
  'acknowledged' => const Color(0xFF2563EB),
  'in_progress' => const Color(0xFFD97706),
  'escalated' => const Color(0xFFDC2626),
  'resolved' => const Color(0xFF059669),
  'cancelled' => TeacherPalette.muted,
  _ => TeacherPalette.muted,
};

Widget _buildSeverityBadge(String? severity) {
  final (label, color) = switch (severity) {
    'high' => ('🔴 เหตุใหญ่', const Color(0xFFDC2626)),
    'medium' => ('🟠 เหตุปานกลาง', const Color(0xFFD97706)),
    _ => ('🟢 เหตุเล็ก', const Color(0xFF059669)),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

String _timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t.toLocal());
  if (diff.inMinutes < 1) return 'เมื่อสักครู่';
  if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
  if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
  return '${diff.inDays} วันที่แล้ว';
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year;
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm น.';
}


// ==========================================
// S4: หน้ารับแจ้งเหตุ (Inbox) — เชื่อมต่อ Backend จริง (Merge กับ Emergency Events)
// ==========================================

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
  final TeacherIncidentReport? originalIncident;

  _EmergencyEvent({
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
    this.originalIncident,
  });
}

class TeacherIncidentInboxPage extends StatefulWidget {
  const TeacherIncidentInboxPage({super.key});

  @override
  State<TeacherIncidentInboxPage> createState() =>
      _TeacherIncidentInboxPageState();
}

class _TeacherIncidentInboxPageState extends State<TeacherIncidentInboxPage> {
  String selectedFilter = 'ทั้งหมด';
  String searchText = '';

  bool _isLoadingRealData = false;
  List<EmergencyEventItem> _realEmergencyEvents = [];
    List<TeacherIncidentReport> _realIncidents = [];
  
  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    setState(() => _isLoadingRealData = true);
    try {
      final results = await Future.wait([
        EmergencyService.listEmergencyEvents().catchError((e) {
          debugPrint('EmergencyService.listEmergencyEvents error: $e');
          return <EmergencyEventItem>[];
        }),
        IncidentService.getIncidentSummary().catchError((e) {
          debugPrint('IncidentService.getIncidentSummary error: $e');
          return <IncidentSummaryItem>[];
        }),
        IncidentService.listTeacherIncidentReports().catchError((e) {
          debugPrint('IncidentService.listTeacherIncidentReports error: $e');
          return <TeacherIncidentReport>[];
        }),
      ]);

      if (!mounted) return;
      final eventsList = results[0] as List<EmergencyEventItem>;
            final incidents = results[2] as List<TeacherIncidentReport>;

      setState(() {
        _realEmergencyEvents = eventsList;
                _realIncidents = incidents;
                _isLoadingRealData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRealData = false);
      debugPrint('Load real data error: $e');
    }
  }

  _EmergencyEvent _convertIncident(TeacherIncidentReport inc) {
    final localTime = inc.createdAt.toLocal();
    final timeStr = 'วันนี้ • ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')} น.';
    final statusDisplay = inc.status == 'new'
        ? 'รอตรวจสอบ'
        : (inc.status == 'acknowledged'
            ? 'รับเรื่องแล้ว'
            : (inc.status == 'resolved' || inc.status == 'cancelled'
                ? 'ปิดเหตุแล้ว'
                : 'กำลังช่วยเหลือ'));
    final isSos = inc.category == IncidentCategory.sos;
    return _EmergencyEvent(
      id: inc.id,
      title: inc.reason != null && inc.reason!.isNotEmpty
          ? inc.reason!
          : (isSos ? 'SOS จากนักเรียน' : 'แจ้งเหตุผิดปกติ'),
      type: isSos ? 'SOS' : 'เหตุผิดปกติ',
      location: inc.room != null && inc.room!.isNotEmpty
          ? 'ห้อง ${inc.room}'
          : 'ภายในโรงเรียน',
      time: timeStr,
      reporter: inc.reporterName.isNotEmpty ? inc.reporterName : 'นักเรียน',
      source: 'แอปนักเรียน (SOS)',
      status: statusDisplay,
      priority: isSos ? 'เร่งด่วน' : 'สูง',
      description: inc.reason ?? (isSos ? 'นักเรียนส่งสัญญาณขอความช่วยเหลือเร่งด่วน' : 'นักเรียนรายงานเหตุผิดปกติ'),
      action: 'ตรวจสอบและให้ความช่วยเหลือ',
      icon: isSos ? Icons.notifications_active_rounded : Icons.warning_amber_rounded,
      color: isSos ? TeacherPalette.red : TeacherPalette.orange,
      originalIncident: inc,
    );
  }

  _EmergencyEvent _convertEmergencyEvent(EmergencyEventItem evt) {
    final localTime = evt.triggeredAt.toLocal();
    final timeStr = 'วันนี้ • ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')} น.';
    final statusDisplay = evt.status == 'new'
        ? 'รอตรวจสอบ'
        : (evt.status == 'acknowledged' ? 'รับเรื่องแล้ว' : 'ปิดเหตุแล้ว');
    return _EmergencyEvent(
      id: evt.id,
      title: 'เหตุฉุกเฉินจาก ${evt.deviceName}',
      type: 'ปุ่มฉุกเฉิน',
      location: evt.location,
      time: timeStr,
      reporter: 'IoT Sensor',
      source: evt.deviceName,
      status: statusDisplay,
      priority: 'เร่งด่วน',
      description: 'ระบบตรวจพบการกดปุ่มแจ้งเหตุฉุกเฉินที่ ${evt.location}',
      action: 'เข้าตรวจสอบพื้นที่ทันที',
      icon: Icons.emergency_rounded,
      color: TeacherPalette.red,
    );
  }

  List<_EmergencyEvent> get _allDisplayEvents {
    final list = <_EmergencyEvent>[];
    for (final inc in _realIncidents) {
      list.add(_convertIncident(inc));
    }
    for (final evt in _realEmergencyEvents) {
      list.add(_convertEmergencyEvent(evt));
    }
    // Sort by most urgent / newest
    list.sort((a, b) {
      if (a.priority != b.priority) {
        return a.priority == 'เร่งด่วน' ? -1 : 1;
      }
      return b.time.compareTo(a.time); // simple string sort for time
    });
    return list;
  }

  List<_EmergencyEvent> _filteredEvents() {
    final query = searchText.trim().toLowerCase();
    final allEvents = _allDisplayEvents;

    return allEvents.where((item) {
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

  Future<void> _openDetail(_EmergencyEvent event) async {
    if (event.originalIncident != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherIncidentDetailPage(incident: event.originalIncident!),
        ),
      );
      if (mounted) _loadRealData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เป็นเหตุจาก Hardware SOS กรุณาใช้อุปกรณ์จัดการ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents();

    return TeacherMockPageShell(
      title: 'รับแจ้งเหตุฉุกเฉิน',
      activeMenuLabel: 'แจ้งเหตุฉุกเฉิน',
      builder: (context, isDesktop) {
        return RefreshIndicator(
          onRefresh: _loadRealData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _emergencyHeader(),
                const SizedBox(height: 14),
                _summaryCards(),
                const SizedBox(height: 16),
                _eventHistoryCard(filtered),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emergencyHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'รับแจ้งเหตุฉุกเฉิน (Inbox)',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: TeacherPalette.ink,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'รับแจ้ง SOS เฝ้าระวังความปลอดภัย และติดตามเหตุการณ์ในวิชา/ห้องที่สอน',
              style: TextStyle(
                fontSize: 10.8,
                color: TeacherPalette.muted,
              ),
            ),
          ],
        );

        final statusBadge = Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_isLoadingRealData)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: TeacherPalette.primary),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'เชื่อมต่อระบบจริง',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _isLoadingRealData ? null : _loadRealData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.refresh_rounded, size: 13, color: TeacherPalette.muted),
                    SizedBox(width: 4),
                    Text(
                      'รีเฟรช',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: TeacherPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleBlock, const SizedBox(height: 8), statusBadge],
          );
        }
        return Row(
          children: [Expanded(child: titleBlock), const SizedBox(width: 10), statusBadge],
        );
      },
    );
  }

  Widget _summaryCards() {
    final int realSosPending = _realIncidents
            .where((i) => i.category == IncidentCategory.sos && (i.status == 'new' || i.status == 'acknowledged'))
            .length +
        _realEmergencyEvents.where((e) => e.status == 'new' || e.status == 'acknowledged').length;

    final int realClosed = _realIncidents
            .where((i) => i.status == 'resolved' || i.status == 'cancelled')
            .length +
        _realEmergencyEvents.where((e) => e.status == 'closed').length;

    final int realActive = _realIncidents
            .where((i) =>
                i.category != IncidentCategory.sos &&
                i.status != 'resolved' &&
                i.status != 'cancelled')
            .length +
        _realEmergencyEvents.where((e) => e.status == 'acknowledged').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final children = [
          _buildStatCard(
            title: 'SOS รอตรวจสอบ',
            value: '$realSosPending',
            icon: Icons.notifications_active_rounded,
            color: TeacherPalette.red,
            bgColor: const Color(0xFFFFE4E6), // light red
          ),
          _buildStatCard(
            title: 'เหตุที่กำลังติดตาม',
            value: '$realActive',
            icon: Icons.warning_amber_rounded,
            color: TeacherPalette.orange,
            bgColor: const Color(0xFFFEF3C7), // light orange
          ),
          _buildStatCard(
            title: 'จัดการเสร็จสิ้น',
            value: '$realClosed',
            icon: Icons.verified_rounded,
            color: TeacherPalette.green,
            bgColor: const Color(0xFFDCFCE7), // light green
          ),
        ];

        if (compact) {
          return Column(
            children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
          );
        }
        return Row(
          children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TeacherPalette.muted,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: TeacherPalette.ink,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventHistoryCard(List<_EmergencyEvent> events) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TeacherPalette.skyVivid,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded, size: 18, color: TeacherPalette.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ประวัติเหตุการณ์ทั้งหมด',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'รายการเหตุฉุกเฉินและอุบัติเหตุที่เกิดขึ้น',
                        style: TextStyle(
                          fontSize: 11,
                          color: TeacherPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TeacherPalette.border),
          _buildFilterBar(),
          const Divider(height: 1, color: TeacherPalette.border),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 48, color: TeacherPalette.green),
                    const SizedBox(height: 12),
                    const Text(
                      'ไม่มีเหตุการณ์ในขณะนี้',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TeacherPalette.muted),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: TeacherPalette.border),
              itemBuilder: (context, index) {
                final evt = events[index];
                return _buildEventListItem(evt);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 36,
            child: TextField(
              onChanged: (val) => setState(() => searchText = val),
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                hintText: 'ค้นหาเหตุการณ์...',
                hintStyle: const TextStyle(color: TeacherPalette.muted, fontSize: 12.5),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: TeacherPalette.muted),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: TeacherPalette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: TeacherPalette.border),
                ),
              ),
            ),
          ),
          _filterChip('ทั้งหมด'),
          _filterChip('รอตรวจสอบ'),
          _filterChip('รับเรื่องแล้ว'),
          _filterChip('ปิดเหตุแล้ว'),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = selectedFilter == label;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? TeacherPalette.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? TeacherPalette.primary : TeacherPalette.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : TeacherPalette.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildEventListItem(_EmergencyEvent evt) {
    return InkWell(
      onTap: () => _openDetail(evt),
      hoverColor: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: evt.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(evt.icon, size: 20, color: evt.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        evt.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.ink,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: evt.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: evt.color.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          evt.priority,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: evt.color,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: evt.status == 'ปิดเหตุแล้ว' ? TeacherPalette.green.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: evt.status == 'ปิดเหตุแล้ว' ? TeacherPalette.green.withValues(alpha: 0.3) : TeacherPalette.border),
                        ),
                        child: Text(
                          evt.status,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: evt.status == 'ปิดเหตุแล้ว' ? TeacherPalette.green : TeacherPalette.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${evt.type} • ${evt.location} • รายงานโดย ${evt.reporter}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    evt.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TeacherPalette.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    evt.time,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: TeacherPalette.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: TeacherPalette.border),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// S4a: หน้ารายละเอียดเหตุ (ครู/Admin)
// ==========================================

class TeacherIncidentDetailPage extends StatefulWidget {
  const TeacherIncidentDetailPage({super.key, required this.incident});

  final TeacherIncidentReport incident;

  @override
  State<TeacherIncidentDetailPage> createState() =>
      _TeacherIncidentDetailPageState();
}

class _TeacherIncidentDetailPageState extends State<TeacherIncidentDetailPage> {
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _acknowledge() async {
    if (widget.incident.status != 'new') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('มีผู้รับเรื่องนี้แล้ว'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await IncidentService.acknowledgeIncidentReport(widget.incident.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รับเรื่องเรียบร้อยแล้ว'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถรับเรื่องได้: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _saveNote() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await IncidentService.addIncidentAction(widget.incident.id, text);
      _noteCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกความคืบหน้าเรียบร้อยแล้ว'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถบันทึกได้: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _escalate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.priority_high_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ยืนยันยกระดับเหตุ',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: const Text(
          'การยกระดับจะสร้างเหตุฉุกเฉินจริงในระบบ (เทียบเท่าปุ่มฉุกเฉินทางกายภาพ) '
          'และแจ้งเตือนวงกว้างขึ้นทันที ยืนยันหรือไม่?',
          style: TextStyle(fontSize: 13, color: TeacherPalette.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              minimumSize: Size.zero,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยกระดับเหตุ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isSubmitting = true);
    try {
      await IncidentService.escalateIncidentReport(widget.incident.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยกระดับเป็นเหตุฉุกเฉินเรียบร้อยแล้ว'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถยกระดับได้: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _close() async {
    final noteCtrl = TextEditingController();
    var isRealIncident = true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'ยืนยันปิดเหตุ',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _closeChoiceTile(
                      label: 'เหตุจริง',
                      selected: isRealIncident,
                      color: const Color(0xFF059669),
                      onTap: () => setModalState(() => isRealIncident = true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _closeChoiceTile(
                      label: 'แจ้งเท็จ/กดพลาด',
                      selected: !isRealIncident,
                      color: TeacherPalette.muted,
                      onTap: () => setModalState(() => isRealIncident = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'สรุปผล *',
                  hintText: 'บันทึกสรุปผลการดำเนินการ',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                backgroundColor: TeacherPalette.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (noteCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('ปิดเหตุ'),
            ),
          ],
        ),
      ),
    );
    if (result != true) return;
    setState(() => _isSubmitting = true);
    try {
      final resType = isRealIncident ? 'resolved' : 'cancelled';
      await IncidentService.closeIncidentReport(
        widget.incident.id,
        resolutionType: resType,
        resolutionNote: noteCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ปิดเหตุเรียบร้อยแล้ว'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถปิดเหตุได้: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _closeChoiceTile({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? color.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : TeacherPalette.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : TeacherPalette.ink,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final accent = _categoryColor(incident.category);
    final isNew = incident.status == 'new';
    final isTerminal =
        incident.status == 'resolved' ||
        incident.status == 'cancelled' ||
        incident.status == 'escalated';

    final roomLabel =
        incident.room != null && incident.room!.isNotEmpty
            ? ' — ห้อง ${incident.room}'
            : '';

    return TeacherMockPageShell(
      title: 'รายละเอียดการแจ้งเหตุ$roomLabel',
      activeMenuLabel: 'แจ้งเหตุฉุกเฉิน',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: TeacherPalette.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                incident.category == IncidentCategory.sos
                                    ? Icons.emergency_rounded
                                    : Icons.warning_amber_rounded,
                                color: accent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              _categoryLabel(incident.category),
                                              style: TextStyle(
                                                color: accent,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                              ),
                                            ),
                                            _buildSeverityBadge(incident.severity),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TeacherStatusChip(
                                        label: _statusLabel(incident.status),
                                        color: _statusColor(incident.status),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'ห้อง ${incident.room ?? "ไม่ระบุ"} · แจ้งโดย ${incident.reporterName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: TeacherPalette.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'แจ้งเมื่อ ${_timeAgo(incident.createdAt)} (${_formatDateTime(incident.createdAt)})',
                                    style: const TextStyle(
                                      color: TeacherPalette.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (incident.reason != null &&
                                      incident.reason!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFFCA5A5),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline_rounded,
                                                size: 15,
                                                color: Color(0xFFDC2626),
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'เหตุผล / สิ่งที่พบเห็น (แจ้งจากนักเรียน):',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF991B1B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            incident.reason!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: TeacherPalette.ink,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_isSubmitting)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        if (!isTerminal && !_isSubmitting) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              if (isNew)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: _acknowledge,
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('รับเรื่อง'),
                                ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  minimumSize: Size.zero,
                                ),
                                onPressed: _escalate,
                                icon: const Icon(
                                  Icons.priority_high_rounded,
                                  size: 18,
                                ),
                                label: const Text('ยกระดับเป็นเหตุฉุกเฉิน'),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF059669),
                                ),
                                onPressed: _close,
                                icon: const Icon(
                                  Icons.task_alt_rounded,
                                  size: 18,
                                ),
                                label: const Text('ปิดเหตุ'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (!isTerminal && !_isSubmitting) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'บันทึกการดำเนินการ',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _noteCtrl,
                            decoration: InputDecoration(
                              hintText: 'พิมพ์ความคืบหน้า...',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TeacherPalette.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            minimumSize: Size.zero,
                          ),
                          onPressed: _saveNote,
                          child: const Text('บันทึก'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ==========================================
// S4b: ประวัติเหตุทั้งหมด
// ==========================================

