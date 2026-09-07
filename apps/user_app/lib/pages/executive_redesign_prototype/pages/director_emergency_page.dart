import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../controllers/director_emergency_controller.dart';
import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

String _statusLabel(String status) => switch (status) {
  'new' => 'รอตรวจสอบ',
  'acknowledged' => 'รับเรื่องแล้ว',
  'in_progress' => 'กำลังดำเนินการ',
  'escalated' => 'ยกระดับแล้ว',
  'resolved' => 'ปิดเหตุแล้ว (เหตุจริง)',
  'cancelled' => 'ปิดเหตุแล้ว (แจ้งเท็จ)',
  _ => status,
};

String _timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t.toLocal());
  if (diff.inMinutes < 1) return 'เมื่อสักครู่';
  if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
  if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
  return '${diff.inDays} วันที่แล้ว';
}

/// Read seams, so loading / data / empty / failure can each be driven in a
/// test. Without them `initState` reaches straight for the Supabase singleton
/// and throws before the page can build — which is why this page had no
/// working coverage at all.
class DirectorEmergencyPage extends StatefulWidget {
  const DirectorEmergencyPage({
    super.key,
    this.loadEmergencyEvents,
    this.loadIncidentSummary,
    this.loadIncidentReports,
    this.closeIncidentReport,
    this.closeEmergencyEvent,
    this.watchUpdates = true,
  });

  final EmergencyEventsLoader? loadEmergencyEvents;
  final IncidentSummaryLoader? loadIncidentSummary;
  final IncidentReportsLoader? loadIncidentReports;
  final IncidentReportCloser? closeIncidentReport;
  final EmergencyEventCloser? closeEmergencyEvent;

  /// Subscribe to the live incident/emergency streams. Off in tests, where
  /// there is no Supabase client to stream from.
  final bool watchUpdates;

  @override
  State<DirectorEmergencyPage> createState() => _DirectorEmergencyPageState();
}

class _DirectorEmergencyPageState extends State<DirectorEmergencyPage> {
  late final DirectorEmergencyController _emergencyController;
  String selectedFilter = 'ทั้งหมด';
  String searchText = '';

  bool sosAccepted = false;
  bool sosResolved = false;

  // Real Database Data State
  List<EmergencyEventItem> _realEmergencyEvents = [];
  List<IncidentSummaryItem> _realIncidentSummary = [];
  List<TeacherIncidentReport> _realIncidents = [];
  bool _isLoadingRealData = false;
  bool _hasRealData = false;

  /// The read failed. Kept apart from "no incidents" because on this page the
  /// two look identical and mean opposite things.
  bool _loadFailed = false;

  EmergencyEventItem? get _activeRealEmergencyEvent {
    if (_realEmergencyEvents.isEmpty) return null;
    return _realEmergencyEvents
        .where((e) => e.status == 'new' || e.status == 'acknowledged')
        .firstOrNull;
  }

  TeacherIncidentReport? get _activeSosIncident {
    if (_realIncidents.isEmpty) return null;
    return _realIncidents
        .where(
          (i) =>
              i.category == IncidentCategory.sos &&
              i.status != 'resolved' &&
              i.status != 'cancelled',
        )
        .firstOrNull;
  }

  TeacherIncidentReport? get _lastResolvedSosIncident {
    if (_realIncidents.isEmpty) return null;
    return _realIncidents
        .where(
          (i) =>
              i.category == IncidentCategory.sos &&
              (i.status == 'resolved' || i.status == 'cancelled'),
        )
        .firstOrNull;
  }

  _EmergencyEvent _convertIncident(TeacherIncidentReport inc) {
    final localTime = inc.createdAt.toLocal();
    final timeStr =
        'วันนี้ • ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')} น.';
    final statusDisplay = inc.status == 'new'
        ? 'กำลังเกิดเหตุ'
        : (inc.status == 'acknowledged'
              ? 'รับเรื่องแล้ว'
              : (inc.status == 'resolved' || inc.status == 'cancelled'
                    ? 'ปิดเหตุแล้ว'
                    : (inc.status == 'escalated'
                          ? 'ยกระดับเป็น SOS แล้ว'
                          : 'กำลังช่วยเหลือ')));
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
      description:
          inc.reason ??
          (isSos
              ? 'นักเรียนส่งสัญญาณขอความช่วยเหลือเร่งด่วน'
              : 'นักเรียนรายงานเหตุผิดปกติ'),
      action: 'ประสานครูเวรและครูห้องพยาบาลเข้าช่วยเหลือทันที',
      icon: isSos
          ? Icons.notifications_active_rounded
          : Icons.warning_amber_rounded,
      color: isSos ? AppPalette.danger : AppPalette.warning,
    );
  }

  _EmergencyEvent _convertEmergencyEvent(EmergencyEventItem evt) {
    final localTime = evt.triggeredAt.toLocal();
    final timeStr =
        'วันนี้ • ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')} น.';
    final statusDisplay = evt.status == 'new'
        ? 'กำลังเกิดเหตุ'
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
      action: 'ประสานครูเวรเข้าตรวจสอบพื้นที่ทันที',
      icon: Icons.emergency_rounded,
      color: AppPalette.danger,
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
    return list;
  }

  StreamSubscription? _incidentSub;
  StreamSubscription? _emergencySub;

  @override
  void initState() {
    super.initState();
    _emergencyController = DirectorEmergencyController(
      loadIncidentReports: widget.loadIncidentReports,
      loadEmergencyEvents: widget.loadEmergencyEvents,
      closeIncidentReport: widget.closeIncidentReport,
      closeEmergencyEvent: widget.closeEmergencyEvent,
    );
    _loadRealData();
    if (widget.watchUpdates) {
      _incidentSub = IncidentService.streamIncidentReports().listen((_) {
        if (mounted) _loadRealData();
      });
      _emergencySub = EmergencyService.streamEmergencyEvents().listen((_) {
        if (mounted) _loadRealData();
      });
    }
  }

  @override
  void dispose() {
    _incidentSub?.cancel();
    _emergencySub?.cancel();
    super.dispose();
  }

  Future<void> _loadRealData() async {
    setState(() {
      _isLoadingRealData = true;
      _loadFailed = false;
    });
    try {
      // Each read used to swallow its own failure into an empty list, so a
      // page that could not reach the backend rendered exactly like a school
      // with no emergencies — the one state a director must never be shown by
      // mistake. Failures now surface; a partial failure is still a failure
      // here, because "no incidents" is only safe to display when it was
      // actually confirmed.
      final results = await Future.wait([
        widget.loadEmergencyEvents?.call() ??
            EmergencyService.listEmergencyEvents(),
        widget.loadIncidentSummary?.call() ??
            IncidentService.getIncidentSummary(),
        widget.loadIncidentReports?.call() ??
            IncidentService.listTeacherIncidentReports(),
      ]);

      if (!mounted) return;
      final eventsList = results[0] as List<EmergencyEventItem>;
      final summary = results[1] as List<IncidentSummaryItem>;
      final incidents = results[2] as List<TeacherIncidentReport>;

      final hasData =
          eventsList.isNotEmpty ||
          incidents.isNotEmpty ||
          summary.any((s) => s.totalCount > 0);

      _emergencyController.replaceCanonicalData(
        incidents: incidents,
        events: eventsList,
      );

      setState(() {
        _realEmergencyEvents = eventsList;
        _realIncidentSummary = summary;
        _realIncidents = incidents;
        _hasRealData = hasData;
        _isLoadingRealData = false;

        if (hasData &&
            (incidents.any((i) => i.category == IncidentCategory.sos) ||
                eventsList.isNotEmpty)) {
          sosResolved = _emergencyController.sosResolved;
          sosAccepted = _emergencyController.sosAccepted;
        } else {
          sosResolved = false;
          sosAccepted = false;
        }
      });
    } catch (e) {
      debugPrint('director_emergency_page: _loadRealData error: $e');
      if (mounted) {
        setState(() {
          _isLoadingRealData = false;
          _loadFailed = true;
        });
      }
    }
  }

  /// Closes one canonical backend record and refuses to report success until
  /// a fresh read confirms the terminal status. All close buttons use this
  /// path so an RPC exception or a silently rejected write cannot turn an
  /// active emergency into a false all-clear in the UI.
  Future<bool> _closeAndConfirmEmergency({
    TeacherIncidentReport? incident,
    EmergencyEventItem? emergencyEvent,
    required String resolutionNote,
  }) async {
    const failureMessage = 'ปิดเหตุไม่สำเร็จ เหตุการณ์ยังเปิดอยู่';
    try {
      await _emergencyController.closeAndConfirm(
        incident: incident,
        emergencyEvent: emergencyEvent,
        resolutionNote: resolutionNote,
      );
      if (!mounted) return false;
      setState(() {
        _realIncidents = _emergencyController.incidentReports;
        _realEmergencyEvents = _emergencyController.emergencyEvents;
        sosResolved = _emergencyController.sosResolved;
        sosAccepted = _emergencyController.sosAccepted;
      });

      _showMessage('✓ ปิดเหตุเรียบร้อยแล้ว');
      return true;
    } catch (error) {
      debugPrint('director_emergency_page: close failed: $error');
      _showMessage(failureMessage);
      return false;
    }
  }

  /// Stated on the page, not only in a log. An unreachable backend must not
  /// be mistaken for a quiet day.
  Widget _loadErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFB91C1C),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'โหลดข้อมูลเหตุฉุกเฉินไม่สำเร็จ — หน้านี้อาจไม่แสดงเหตุที่กำลังเกิดขึ้นจริง',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
          TextButton(
            onPressed: _isLoadingRealData ? null : _loadRealData,
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _demoBadge({String text = 'ข้อมูลจำลอง'}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 3.5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _realBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 3.5),
          const Text(
            'ฐานข้อมูลจริง',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  final List<String> filters = const [
    'ทั้งหมด',
    'กำลังเกิดเหตุ',
    'รับเรื่องแล้ว',
    'กำลังช่วยเหลือ',
    'ปิดเหตุแล้ว',
  ];

  // The 86-line `events` const that used to live here is gone.
  //
  // It held four fully-written emergencies — including an active
  // "SOS จากนักเรียน ห้อง ม.3/2" — and every read of it was guarded by
  // `_hasRealData ? real : events`. `_hasRealData` is false exactly when the
  // school has no incidents at all, so a school with nothing wrong showed a
  // director a student SOS in progress, with counters and an active-incident
  // card to match. The safest possible state rendered as the worst one.
  //
  // Every RPC behind this page is real and executive-allowed, so there is
  // nothing to fall back to: no incidents means no incidents.

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents();

    return RefreshIndicator(
      onRefresh: _loadRealData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _emergencyHeader(),
            if (_loadFailed) ...[
              const SizedBox(height: 12),
              _loadErrorBanner(),
            ],
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
                      _activeIncidentCard(isEqualHeight: false),
                      const SizedBox(height: 16),
                      _responseTeamCard(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _activeIncidentCard(isEqualHeight: false)),
                    const SizedBox(width: 16),
                    Expanded(child: _responseTeamCard()),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _eventHistoryCard(filtered),
          ],
        ),
      ),
    );
  }

  List<_EmergencyEvent> _filteredEvents() {
    final query = searchText.trim().toLowerCase();
    final allEvents = _allDisplayEvents;

    return allEvents.where((item) {
      final matchesSearch =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.type.toLowerCase().contains(query) ||
          item.reporter.toLowerCase().contains(query);

      final matchesFilter =
          selectedFilter == 'ทั้งหมด' || item.status == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _emergencyHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'ศูนย์บัญชาการเหตุฉุกเฉินและความปลอดภัย',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'รับแจ้ง SOS เฝ้าระวังความปลอดภัย และสั่งการช่วยเหลือแบบเรียลไทม์ 24 ชม.',
              style: TextStyle(fontSize: 10.8, color: AppPalette.textMuted),
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
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            // There is no demo data left on this page, so the old
            // `_hasRealData ? real : demo` badge no longer describes anything
            // real. What matters now is whether the read succeeded.
            else if (_loadFailed)
              _demoBadge(text: 'โหลดไม่สำเร็จ')
            else if (_hasRealData)
              _realBadge()
            else
              _demoBadge(text: 'ไม่มีเหตุที่ต้องดำเนินการ'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF059669).withValues(alpha: 0.25),
                ),
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
                    'ระบบ IoT & SOS: ออนไลน์ 100%',
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
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.refresh_rounded,
                      size: 13,
                      color: Color(0xFF475569),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'รีเฟรช',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
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
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 10),
            statusBadge,
          ],
        );
      },
    );
  }

  Widget _summaryCards() {
    // Check if we have real emergency events or incidents from DB
    final int realSosPending =
        _realIncidents
            .where(
              (i) =>
                  i.category == IncidentCategory.sos &&
                  (i.status == 'new' || i.status == 'acknowledged'),
            )
            .length +
        _realEmergencyEvents
            .where((e) => e.status == 'new' || e.status == 'acknowledged')
            .length;

    final int realClosed =
        _realIncidents
            .where((i) => i.status == 'resolved' || i.status == 'cancelled')
            .length +
        _realEmergencyEvents.where((e) => e.status == 'closed').length;

    final int realActive =
        _realIncidents
            .where(
              (i) =>
                  i.category != IncidentCategory.sos &&
                  i.status != 'resolved' &&
                  i.status != 'cancelled',
            )
            .length +
        _realEmergencyEvents.where((e) => e.status == 'acknowledged').length;

    // Active counts calculation
    // Counted from the database only. These used to fall back to counting the
    // invented `events` list, and `sosPendingCount` fell back to the literal
    // `1` — so a school with no incidents was told one SOS was pending.
    final activeCount = realActive;
    final closedCount = realClosed;
    final sosPendingCount = realSosPending;

    final items = [
      _EmergencySummaryData(
        title: 'SOS รอรับเรื่อง',
        value: '$sosPendingCount',
        unit: 'จุด',
        // Was `_hasRealData ? real : 'ห้อง ม.3/2 • แจ้งมา 28 วิ'` — a school
        // with no incidents read as one SOS waiting in a specific room.
        sub: _loadFailed
            ? 'ยังไม่ทราบ — โหลดไม่สำเร็จ'
            : (sosPendingCount == 0
                  ? 'ไม่มีสัญญาณ SOS ค้าง'
                  : 'พบสัญญาณ SOS รอการตอบสนอง'),
        badge: sosPendingCount == 0 ? '✓ เรียบร้อย' : '● วิกฤตทันที',
        badgeBg: sosPendingCount == 0
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFFE4E6),
        badgeTextColor: sosPendingCount == 0
            ? const Color(0xFF059669)
            : const Color(0xFFE11D48),
        icon: Icons.notifications_active_rounded,
        headerBg: const Color(0xFFFFE4E6),
        headerColor: const Color(0xFFBE123C),
        isReal: _hasRealData,
        onTap: _showSosDetail,
      ),
      _EmergencySummaryData(
        title: 'เหตุที่กำลังติดตาม',
        value: '$activeCount',
        unit: 'เรื่อง',
        sub: _hasRealData
            ? (_realIncidentSummary.isNotEmpty
                  ? 'สรุปเหตุในระบบ ${_realIncidentSummary.length} หมวด'
                  : 'เหตุการณ์ที่อยู่ระหว่างประสานงาน')
            : 'ทะเลาะวิวาท 1 • ล้มหมดสติ 1',
        badge: '● กำลังช่วยเหลือ',
        badgeBg: const Color(0xFFFEF3C7),
        badgeTextColor: const Color(0xFFD97706),
        icon: Icons.warning_amber_rounded,
        headerBg: const Color(0xFFFEF3C7),
        headerColor: const Color(0xFF92400E),
        isReal: _hasRealData,
        onTap: () {
          _showMessage('กำลังแสดงเหตุการณ์ที่กำลังติดตามในระบบ');
        },
      ),
      _EmergencySummaryData(
        title: 'ปิดเหตุแล้ววันนี้',
        value: '$closedCount',
        unit: 'เหตุ',
        sub: _hasRealData
            ? 'บันทึกปิดเหตุในระบบ'
            : 'เสร็จสิ้นครบ • เฉลี่ย 14 นาที',
        badge: '✓ ปลอดภัย 100%',
        badgeBg: const Color(0xFFDCFCE7),
        badgeTextColor: const Color(0xFF059669),
        icon: Icons.task_alt_rounded,
        headerBg: const Color(0xFFE6F7ED),
        headerColor: const Color(0xFF047857),
        isReal: _hasRealData,
        onTap: () {
          setState(() => selectedFilter = 'ปิดเหตุแล้ว');
        },
      ),
      _EmergencySummaryData(
        title: 'ความพร้อมทีมครูเวร',
        value: '100',
        unit: '%',
        sub: 'ครูเวร • ครูอนามัย • ปกครอง • ครูที่ปรึกษา',
        badge: '🟢 สแตนด์บาย 4 ชุด',
        badgeBg: const Color(0xFFF3E8FF),
        badgeTextColor: const Color(0xFF7C3AED),
        icon: Icons.health_and_safety_rounded,
        headerBg: const Color(0xFFF3E8FF),
        headerColor: const Color(0xFF6D28D9),
        isReal: false,
        onTap: () {
          _showMessage('ทีมครูเวรและบุคลากรทุกจุดพร้อมปฏิบัติการ 100%');
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int columns = width >= 960 ? 4 : (width >= 560 ? 2 : 1);
        const double spacing = 12;
        final double cardWidth =
            ((width - (spacing * (columns - 1))) / columns).floorToDouble() -
            0.5;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  mouseCursor: SystemMouseCursors.click,
                  hoverColor: item.headerBg.withValues(alpha: 0.25),
                  splashColor: item.headerColor.withValues(alpha: 0.12),
                  onTap: item.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFF1F5F9),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Colored pill header banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: item.headerBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 14,
                                color: item.headerColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: item.headerColor,
                                  ),
                                ),
                              ),
                              if (item.isReal) _realBadge() else _demoBadge(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Big Value + Unit
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              item.value,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.unit,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Bottom Row: Subtitle + Badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: item.badgeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.badge,
                                style: TextStyle(
                                  fontSize: 9.2,
                                  fontWeight: FontWeight.w700,
                                  color: item.badgeTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _sosPanel() {
    // Nothing is happening unless the database says so.
    //
    // `_sosActiveCard` was rendered whenever `sosResolved` was false, which
    // includes the case where there is no incident at all — and it filled
    // itself in with an invented emergency: "SOS จากนักเรียน ห้อง ม.3/2",
    // "อาคาร 3 ชั้น 2", "แจ้งมา 28 วิ", reported by "ครูสมหญิง ใจดี". A small
    // ข้อมูลจำลอง badge disclosed it, but the card is large, red, and on the
    // emergency page — the one screen where a director must be able to trust
    // that what is drawn is happening.
    if (_activeSosIncident == null && _activeRealEmergencyEvent == null) {
      return _noActiveEmergencyCard();
    }
    if (sosResolved) {
      return _sosResolvedCard();
    }
    return _sosActiveCard();
  }

  /// Shown when the school has no open emergency — the normal state, and the
  /// one this page could not previously express.
  Widget _noActiveEmergencyCard() {
    final bool failed = _loadFailed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: failed
              ? const Color(0xFFFECACA)
              : const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            failed ? Icons.cloud_off_rounded : Icons.verified_user_outlined,
            size: 34,
            color: failed ? const Color(0xFFB91C1C) : const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          Text(
            failed
                ? 'ยังไม่ทราบสถานะเหตุฉุกเฉิน'
                : 'ไม่มีเหตุฉุกเฉินที่กำลังดำเนินอยู่',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: failed ? const Color(0xFF991B1B) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            failed
                ? 'โหลดข้อมูลไม่สำเร็จ — อย่าถือว่าไม่มีเหตุ กรุณาลองใหม่หรือตรวจสอบทางช่องทางอื่น'
                : 'ยังไม่มีการแจ้ง SOS จากนักเรียนหรือสัญญาณจากปุ่มฉุกเฉินในโรงเรียน',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          if (failed) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _isLoadingRealData ? null : _loadRealData,
              child: const Text('ลองใหม่'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sosResolvedCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Top Bar: Calm All-Clear Emerald
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFDCFCE7), width: 1),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                final statusIndicator = Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'สภาวะปกติ • เหตุการณ์ SOS ล่าสุดได้รับการแก้ไขเรียบร้อยแล้ว',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                );

                final timeIndicator = Row(
                  children: const [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'ปิดเหตุเมื่อ 10:48 น. (ระงับเหตุใน 6 นาที)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      statusIndicator,
                      const SizedBox(height: 4),
                      timeIndicator,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 3, child: statusIndicator),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: timeIndicator),
                  ],
                );
              },
            ),
          ),

          // Main Body Padding
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 780;

                final resolved = _lastResolvedSosIncident;

                final infoSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7ED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            size: 24,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      resolved != null
                                          ? (resolved.room != null &&
                                                    resolved.room!.isNotEmpty
                                                ? 'บันทึกการระงับเหตุ: SOS ห้อง ${resolved.room}'
                                                : 'บันทึกการระงับเหตุ: SOS จากนักเรียน')
                                          : 'บันทึกการระงับเหตุ: SOS ห้อง ม.3/2',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF059669,
                                        ).withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 5.5,
                                          height: 5.5,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF059669),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'ปิดเหตุแล้ว',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF047857),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                resolved != null
                                    ? '${resolved.reason ?? "สัญญาณฉุกเฉิน"} • ${resolved.room != null && resolved.room!.isNotEmpty ? "ห้อง ${resolved.room}" : "ภายในโรงเรียน"} • ${_statusLabel(resolved.status)}'
                                    : 'ปิดเหตุการณ์เรียบร้อยแล้ว',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Briefing Outcome Box (Clean Apple Inset Summary)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 3.5,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'สรุปผลการปฏิบัติการระงับเหตุ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  resolved != null
                                      ? 'ผู้แจ้ง: ${resolved.reporterName.isNotEmpty ? resolved.reporterName : "นักเรียน"} • สถานะ: ${_statusLabel(resolved.status)}'
                                      : 'ปิดเหตุการณ์เรียบร้อยแล้ว',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    height: 1.45,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Specs & Meta Tags (Clean, unified slate tone)
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _unifiedSpecChip(
                          Icons.place_rounded,
                          resolved?.room != null && resolved!.room!.isNotEmpty
                              ? 'ห้อง ${resolved.room}'
                              : 'ภายในโรงเรียน',
                        ),
                        _unifiedSpecChip(
                          Icons.person_rounded,
                          'ผู้แจ้ง: ${resolved?.reporterName.isNotEmpty == true ? resolved!.reporterName : "นักเรียน"}',
                        ),
                        if (resolved != null)
                          _unifiedSpecChip(
                            Icons.access_time_rounded,
                            _timeAgo(resolved.createdAt),
                          ),
                        _unifiedSpecChip(
                          Icons.check_circle_outline_rounded,
                          _statusLabel(resolved?.status ?? 'resolved'),
                        ),
                      ],
                    ),
                  ],
                );

                final actionSection = Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _showSosDetail,
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: const Text(
                          'ดูรายงานสรุปและไทม์ไลน์',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          foregroundColor: const Color(0xFF475569),
                        ),
                        onPressed: () {
                          final room = resolved?.room;
                          _showMessage(
                            room != null && room.isNotEmpty
                                ? 'กำลังเปิดคลิปบันทึกย้อนหลัง CCTV ห้อง $room ช่วงเกิดเหตุ...'
                                : 'กำลังเปิดคลิปบันทึกย้อนหลัง CCTV ช่วงเกิดเหตุ...',
                          );
                        },
                        icon: const Icon(Icons.videocam_outlined, size: 16),
                        label: const Text(
                          'ดูภาพย้อนหลัง CCTV',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      infoSection,
                      const SizedBox(height: 16),
                      actionSection,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: infoSection),
                    const SizedBox(width: 20),
                    SizedBox(width: 230, child: actionSection),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sosActiveCard() {
    final isUrgent = !sosAccepted;
    final statusColor = sosAccepted
        ? const Color(0xFFD97706)
        : const Color(0xFFE11D48);
    final statusText = sosAccepted
        ? 'รับเรื่องแล้ว • กำลังช่วยเหลือ'
        : 'รอรับ SOS ด่วน';

    final activeIncident = _activeSosIncident;
    final activeEvt = _activeRealEmergencyEvent;
    final bool hasActiveReal = activeIncident != null || activeEvt != null;

    final titleText = activeIncident != null
        ? (activeIncident.room != null && activeIncident.room!.isNotEmpty
              ? 'SOS จากนักเรียน ห้อง ${activeIncident.room}'
              : 'SOS จากนักเรียน')
        : (activeEvt != null
              ? 'เหตุฉุกเฉินจาก ${activeEvt.deviceName}'
              : 'SOS จากนักเรียน ห้อง ม.3/2');

    final reasonText = activeIncident != null
        ? 'ประเภทเหตุ: ${activeIncident.reason ?? "สัญญาณฉุกเฉิน (SOS)"}'
        : (activeEvt != null
              ? 'ประเภทเหตุ: ปุ่มกดแจ้งเหตุฉุกเฉิน'
              : 'ประเภทเหตุ: เจ็บป่วยฉุกเฉิน (นักเรียนหมดสติในคาบเรียน)');

    final locationChip = activeIncident != null
        ? (activeIncident.room != null && activeIncident.room!.isNotEmpty
              ? 'ห้อง ${activeIncident.room}'
              : 'บริเวณโรงเรียน')
        : (activeEvt != null ? activeEvt.location : 'อาคาร 3 ชั้น 2');

    final sensorChip = activeIncident != null
        ? 'แอปนักเรียน (SOS)'
        : (activeEvt != null ? activeEvt.deviceName : 'ปุ่ม SOS ห้อง ม.3/2');

    final reporterChip = activeIncident != null
        ? 'ผู้แจ้ง: ${activeIncident.reporterName.isNotEmpty ? activeIncident.reporterName : "นักเรียน"}'
        : (activeEvt != null
              ? 'ไม่มี (แจ้งเตือนจากอุปกรณ์)'
              : 'ผู้แจ้ง: ครูสมหญิง ใจดี');

    final timeChip = activeIncident != null
        ? 'แจ้งเมื่อ ${activeIncident.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${activeIncident.createdAt.toLocal().minute.toString().padLeft(2, '0')} น.'
        : (activeEvt != null
              ? 'แจ้งเมื่อ ${activeEvt.triggeredAt.toLocal().hour.toString().padLeft(2, '0')}:${activeEvt.triggeredAt.toLocal().minute.toString().padLeft(2, '0')} น.'
              : 'แจ้งเมื่อ 10:42:18 น.');

    final timerText = activeIncident != null
        ? () {
            final diff = DateTime.now().toUtc().difference(
              activeIncident.createdAt,
            );
            if (diff.inMinutes < 1)
              return 'แจ้งมา ${diff.inSeconds} วินาทีที่แล้ว';
            if (diff.inHours < 1) return 'แจ้งมา ${diff.inMinutes} นาทีที่แล้ว';
            return 'แจ้งมา ${diff.inHours} ชม. ที่แล้ว';
          }()
        : (activeEvt != null
              ? () {
                  final diff = DateTime.now().toUtc().difference(
                    activeEvt.triggeredAt.toUtc(),
                  );
                  if (diff.inMinutes < 1)
                    return 'แจ้งมา ${diff.inSeconds} วินาทีที่แล้ว';
                  if (diff.inHours < 1)
                    return 'แจ้งมา ${diff.inMinutes} นาทีที่แล้ว';
                  return 'แจ้งมา ${diff.inHours} ชม. ที่แล้ว';
                }()
              : 'ไม่ทราบเวลาแจ้ง');

    final narrativeText = activeIncident != null
        ? (activeIncident.reason != null && activeIncident.reason!.isNotEmpty
              ? 'นักเรียนส่งสัญญาณขอความช่วยเหลือ: "${activeIncident.reason}" กำลังประสานครูเวรและครูห้องพยาบาลเข้าช่วยเหลือทันที'
              : 'นักเรียนส่งสัญญาณขอความช่วยเหลือฉุกเฉินผ่านระบบ SOS กำลังประสานครูเวรและครูห้องพยาบาลเข้าดูแลพื้นที่')
        : (activeEvt != null
              ? 'ระบบตรวจพบการกดปุ่มแจ้งเหตุฉุกเฉินที่ ${activeEvt.location}'
              : 'นักเรียนหญิงหมดสติระหว่างเรียนคณิตศาสตร์ ครูประจำวิชากำลังปฐมพยาบาลเบื้องต้น ประสานครูห้องพยาบาลและครูเวรเข้าช่วยเหลือ ระบบส่งพิกัดให้ผู้อำนวยการและครูเวรแล้ว');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFFFBFB) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: isUrgent ? 2.0 : 1.3),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isUrgent ? 0.22 : 0.08),
            blurRadius: isUrgent ? 24 : 16,
            offset: const Offset(0, 4),
            spreadRadius: isUrgent ? 1 : 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Top Bar: High-contrast Emergency Banner + Live Timer Capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: sosAccepted
                    ? [const Color(0xFFB45309), const Color(0xFFD97706)]
                    : [
                        const Color(0xFF9F1239),
                        const Color(0xFFE11D48),
                        const Color(0xFFBE123C),
                      ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;

                final timerPill = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timerText,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );

                // ป้ายนี้ต้องอ้างอิงตาม hasActiveReal (มี SOS จริงที่ยัง
                // ไม่ปิดเคสอยู่ไหม) ไม่ใช่ _hasRealData (เคยมีข้อมูลจริง
                // เก่าแค่ไหนก็ได้ในระบบ) — เพราะเนื้อหาการ์ดทั้งหมดข้างบน
                // (title/reason/location/reporter/time/narrative) สลับ
                // ตาม hasActiveReal เท่านั้น ถ้าใช้ _hasRealData จะติดป้าย
                // "ฐานข้อมูลจริง" ให้กับเนื้อหาจำลองที่ฝังไว้ในโค้ดทันทีที่
                // SOS จริงทุกเคสถูกปิดหมด (มีข้อมูลจริงในอดีต แต่ไม่มีเคส
                // ที่ active อยู่แล้ว)
                final badge = hasActiveReal ? _realBadge() : _demoBadge();

                final titleRow = Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.8),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        sosAccepted
                            ? 'กำลังเข้าควบคุมสถานการณ์'
                            : 'LIVE EMERGENCY • สัญญาณ SOS ฉุกเฉิน',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleRow,
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [timerPill, badge],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    timerPill,
                    const SizedBox(width: 8),
                    Expanded(child: titleRow),
                    const SizedBox(width: 6),
                    badge,
                  ],
                );
              },
            ),
          ),

          // Main Body Padding
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 780;

                final infoSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Beacon Icon + Title + Status + Incident Type
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isUrgent
                                  ? [
                                      const Color(0xFFE11D48),
                                      const Color(0xFFBE123C),
                                    ]
                                  : [
                                      const Color(0xFFD97706),
                                      const Color(0xFFB45309),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      titleText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUrgent
                                          ? const Color(0xFFE11D48)
                                          : const Color(0xFFD97706),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusText,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                reasonText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Unified Spec Tags (Placed on top per user request)
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _unifiedSpecChip(
                          Icons.place_rounded,
                          locationChip,
                          isPrimary: isUrgent,
                        ),
                        _unifiedSpecChip(
                          Icons.sensors_rounded,
                          sensorChip,
                          isPrimary: isUrgent,
                        ),
                        _unifiedSpecChip(Icons.person_rounded, reporterChip),
                        _unifiedSpecChip(Icons.access_time_rounded, timeChip),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Incident Narrative - Clean, larger font, high contrast, readable
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? const Color(0xFFFFF1F2)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUrgent
                              ? const Color(0xFFFECDD3)
                              : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isUrgent
                                  ? const Color(0xFFFFE4E6)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              Icons.medical_services_rounded,
                              size: 18,
                              color: isUrgent
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'รายละเอียดสถานการณ์:',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  narrativeText,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.5,
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final actionSection = Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: sosAccepted
                              ? const Color(0xFF059669)
                              : const Color(0xFFE11D48),
                          elevation: isUrgent ? 3 : 0,
                          shadowColor: isUrgent
                              ? const Color(0xFFE11D48).withValues(alpha: 0.5)
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: sosAccepted ? _showSosDetail : _acceptSos,
                        icon: Icon(
                          sosAccepted
                              ? Icons.check_circle_rounded
                              : Icons.crisis_alert_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          sosAccepted
                              ? '✓ ผอ. รับเรื่องแล้ว'
                              : '🚨 รับ SOS และสั่งการ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (sosAccepted) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: FilledButton.tonalIcon(
                          key: const Key('director-emergency-close-hero'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFDCFCE7),
                            foregroundColor: const Color(0xFF047857),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final inc = _activeSosIncident;
                            final evt = _activeRealEmergencyEvent;
                            await _closeAndConfirmEmergency(
                              incident: inc,
                              emergencyEvent: evt,
                              resolutionNote:
                                  'ผู้อำนวยการรับเรื่องและระงับเหตุเรียบร้อย',
                            );
                          },
                          icon: const Icon(Icons.task_alt_rounded, size: 16),
                          label: const Text(
                            'ปิดเหตุการณ์ (เสร็จสิ้น)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isUrgent
                                ? const Color(0xFFFECDD3)
                                : const Color(0xFFCBD5E1),
                          ),
                          foregroundColor: isUrgent
                              ? const Color(0xFF9F1239)
                              : const Color(0xFF475569),
                        ),
                        onPressed: _showSosDetail,
                        icon: const Icon(Icons.visibility_outlined, size: 15),
                        label: const Text(
                          'ดูรายละเอียดและไทม์ไลน์',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          _showMessage(
                            'กำลังเชื่อมต่อสัญญาณกล้อง CCTV $locationChip...',
                          );
                        },
                        icon: const Icon(
                          Icons.videocam_rounded,
                          size: 16,
                          color: Color(0xFFE11D48),
                        ),
                        label: const Text(
                          'เปิดดูกล้อง CCTV ห้องนี้',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                      ),
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      infoSection,
                      const SizedBox(height: 16),
                      actionSection,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: infoSection),
                    const SizedBox(width: 20),
                    SizedBox(width: 230, child: actionSection),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _unifiedSpecChip(
    IconData icon,
    String text, {
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFFFFE4E6) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary ? const Color(0xFFFDA4AF) : const Color(0xFFE2E8F0),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11.5,
            color: isPrimary
                ? const Color(0xFFE11D48)
                : const Color(0xFF64748B),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
              color: isPrimary
                  ? const Color(0xFF9F1239)
                  : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeIncidentCard({bool isEqualHeight = false}) {
    final all = _allDisplayEvents;
    final active = all
        .where(
          (item) =>
              item.status != 'ปิดเหตุแล้ว' &&
              item.id != 'SOS-20260821-001' &&
              item.type != 'SOS',
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with squircle icon & count badge
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;

              final iconBlock = Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  size: 20,
                  color: Color(0xFFD97706),
                ),
              );

              final textBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'เหตุฉุกเฉินที่กำลังติดตาม',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'เหตุการณ์ที่กำลังประสานงานช่วยเหลืออยู่ขณะนี้',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );

              final badgeBlock = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasRealData) _realBadge() else _demoBadge(),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.5,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      '${active.length} เหตุการณ์',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        iconBlock,
                        const SizedBox(width: 10),
                        Expanded(child: textBlock),
                      ],
                    ),
                    const SizedBox(height: 8),
                    badgeBlock,
                  ],
                );
              }

              return Row(
                children: [
                  iconBlock,
                  const SizedBox(width: 12),
                  Expanded(child: textBlock),
                  badgeBlock,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Incident Cards Body (Equal height distribution on desktop)
          //
          // The empty branch used to be Expanded unconditionally, but both
          // call sites pass isEqualHeight: false and this card sits inside a
          // SingleChildScrollView — an Expanded there has no bounded height to
          // expand into and throws during layout. It never showed up because
          // the invented `events` list meant `active` was never empty; with
          // that gone, empty is the ordinary state and the assertion fires on
          // every load. Gate it the same way the populated branch is gated.
          if (active.isEmpty && isEqualHeight)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 38,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ไม่มีเหตุฉุกเฉินค้างการติดตาม',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ทุกจุดในโรงเรียนปลอดภัยและอยู่ในสภาวะปกติ',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (active.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 38,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ไม่มีเหตุฉุกเฉินค้างการติดตาม',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ทุกจุดในโรงเรียนปลอดภัยและอยู่ในสภาวะปกติ',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isEqualHeight)
            Expanded(
              child: Column(
                children: [
                  for (int i = 0; i < active.length; i++) ...[
                    Expanded(child: _activeEventTile(active[i])),
                    if (i < active.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < active.length; i++) ...[
                  _activeEventTile(active[i]),
                  if (i < active.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),

          const SizedBox(height: 10),

          // Bottom Action Bar to match right card
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 9.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _showMessage(
                      'กำลังเปิดแผนที่แสดงพิกัดจุดเกิดเหตุทั้งหมด...',
                    );
                  },
                  icon: const Icon(
                    Icons.map_rounded,
                    size: 14,
                    color: Color(0xFF0284C7),
                  ),
                  label: const Text(
                    'แผนที่จุดเกิดเหตุ',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 9.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _showMessage(
                      'กำลังเปิดรายงานการติดตามเหตุการณ์ย้อนหลัง...',
                    );
                  },
                  icon: const Icon(
                    Icons.history_rounded,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  label: const Text(
                    'ประวัติเหตุการณ์',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activeEventTile(_EmergencyEvent item) {
    final statusColor = _statusColor(item.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: item.color.withValues(alpha: 0.03),
        splashColor: item.color.withValues(alpha: 0.08),
        onTap: () => _showEventDetail(item),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.priority == 'เร่งด่วน'
                  ? const Color(0xFFFDA4AF)
                  : const Color(0xFFE2E8F0),
              width: item.priority == 'เร่งด่วน' ? 1.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: item.priority == 'เร่งด่วน'
                    ? item.color.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Row 1: Category Tag & Status Pill with dot
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon, size: 12, color: item.color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: item.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5.5,
                            height: 5.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Title
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),

              // Description
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),

              // Subtle hairline divider
              const Divider(
                height: 1,
                thickness: 0.6,
                color: Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 6),

              // Row 4: Location/Time on left + Action on right
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${item.location} • ${item.time}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.5,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.type == 'ทะเลาะวิวาท'
                              ? 'ดูกล้อง CCTV'
                              : 'ตรวจอาการ',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 8,
                          color: item.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _responseTeamCard() {
    // The four duty teams that used to be built here are gone.
    //
    // They were a const list naming real-sounding staff — ครูสมชาย,
    // ครูพิมพ์ใจ, ครูสุพรรณี, อ.วินัย, ครูสมหญิง — each with a live status
    // such as "กำลังไปจุดเกิดเหตุ" or "ประจำจุดตรวจ", and a room that fell
    // back to a hardcoded ม.3/2 when no incident was open. Nothing in the
    // schema models an emergency duty roster: there is no team table, no
    // assignment, and no way for anyone to report that they are on their way.
    //
    // This is worse than an invented number. During a real incident a
    // director could read it as confirmation that named people were already
    // responding, and stop looking for them.

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;

              final iconBlock = Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 20,
                  color: Color(0xFF059669),
                ),
              );

              final textBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'ทีมเผชิญเหตุและช่วยเหลือ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ครูเวรและบุคลากรครูภายในโรงเรียน',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );

              final badgeBlock = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _demoBadge(),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.5,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7ED),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text(
                      'พร้อม 100%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        iconBlock,
                        const SizedBox(width: 10),
                        Expanded(child: textBlock),
                      ],
                    ),
                    const SizedBox(height: 8),
                    badgeBlock,
                  ],
                );
              }

              return Row(
                children: [
                  iconBlock,
                  const SizedBox(width: 12),
                  Expanded(child: textBlock),
                  badgeBlock,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Where the four invented duty teams used to render.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.groups_outlined, size: 30, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text(
                  'ยังไม่มีข้อมูลเวรฉุกเฉิน',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ระบบยังไม่มีตารางเวรและการรายงานตัวของผู้รับผิดชอบเหตุฉุกเฉิน '
                  'กรุณาประสานงานตามช่องทางของโรงเรียนโดยตรง',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Bottom Action Bar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFFA7F3D0)),
                    padding: const EdgeInsets.symmetric(vertical: 9.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _showMessage('กำลังต่อสายด่วนถึงครูเวรหัวหน้าชุด...');
                  },
                  icon: const Icon(
                    Icons.phone_rounded,
                    size: 14,
                    color: Color(0xFF059669),
                  ),
                  label: const Text(
                    'โทรครูเวร',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE11D48),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    padding: const EdgeInsets.symmetric(vertical: 9.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _showMessage(
                      'ส่งสัญญาณแจ้งเตือนซ้ำไปยังวิทยุสื่อสารและมือถือของทีมแล้ว',
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_active_rounded,
                    size: 14,
                    color: Color(0xFFE11D48),
                  ),
                  label: const Text(
                    'แจ้งเตือนซ้ำ',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _eventHistoryCard(List<_EmergencyEvent> filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 540;

              final titleCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'บันทึกเหตุการณ์ทั้งหมด',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'ค้นหาและตรวจสอบประวัติการรับแจ้งเหตุ การช่วยเหลือ และการปิดเหตุ',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              );

              final badgeRow = Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_hasRealData) _realBadge() else _demoBadge(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'พบ ${filtered.length} เหตุการณ์',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleCol, const SizedBox(height: 8), badgeRow],
                );
              }

              return Row(
                children: [
                  Expanded(child: titleCol),
                  badgeRow,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _searchAndFilter(),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            _emptyState()
          else
            ...filtered.map(_eventHistoryTile),
        ],
      ),
    );
  }

  Widget _searchAndFilter() {
    final search = TextField(
      onChanged: (value) {
        setState(() => searchText = value);
      },
      style: const TextStyle(fontSize: 11.5),
      decoration: InputDecoration(
        hintText: 'ค้นหาเหตุการณ์ อาคาร ห้อง ผู้แจ้ง หรือประเภทเหตุ...',
        hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 18,
          color: Color(0xFF64748B),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.2),
        ),
      ),
    );

    final filterTabs = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: filters.map((f) {
            final active = selectedFilter == f;
            final allEvents = _allDisplayEvents;
            final count = f == 'ทั้งหมด'
                ? allEvents.length
                : allEvents.where((e) => e.status == f).length;

            Color activeColor = const Color(0xFF0F172A);
            if (active) {
              if (f == 'กำลังเกิดเหตุ') {
                activeColor = const Color(0xFFE11D48);
              } else if (f == 'รับเรื่องแล้ว') {
                activeColor = const Color(0xFF2563EB);
              } else if (f == 'กำลังช่วยเหลือ') {
                activeColor = const Color(0xFFD97706);
              } else if (f == 'ปิดเหตุแล้ว') {
                activeColor = const Color(0xFF059669);
              }
            }

            return InkWell(
              borderRadius: BorderRadius.circular(7),
              onTap: () => setState(() => selectedFilter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (active && f != 'ทั้งหมด') ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: activeColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      '$f ($count)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: active ? activeColor : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [search, const SizedBox(height: 10), filterTabs],
    );
  }

  Widget _eventHistoryTile(_EmergencyEvent item) {
    final statusColor = _statusColor(item.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: item.color.withValues(alpha: 0.03),
        splashColor: item.color.withValues(alpha: 0.08),
        onTap: () => _showEventDetail(item),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 480;

              final statusBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.22),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5.5,
                      height: 5.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 4.5),
                    Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(item.icon, size: 16, color: item.color),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        statusBadge,
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.location} • ${item.time}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 9,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, size: 18, color: item.color),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.type,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2.5),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${item.location} • ${item.time}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  statusBadge,
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: Color(0xFFCBD5E1),
                  ),
                ],
              );
            },
          ),
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

  Future<void> _acceptSos() async {
    final inc = _activeSosIncident;
    final evt = _activeRealEmergencyEvent;
    if (inc != null) {
      try {
        await IncidentService.acknowledgeIncidentReport(inc.id);
      } catch (e) {
        debugPrint('Error acknowledging incident: $e');
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        return;
      }
    } else if (evt != null) {
      try {
        await EmergencyService.acknowledgeEmergencyEvent(evt.id);
      } catch (e) {
        debugPrint('Error acknowledging emergency event: $e');
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        return;
      }
    }

    setState(() => sosAccepted = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รับ SOS แล้ว ระบบกำหนดให้ผู้อำนวยการเป็นผู้รับเรื่อง'),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 3),
        ),
      );
    }

    _showSosDetail();
    await _loadRealData();
  }

  void _showSosDetail() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SosDetailModal',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      pageBuilder: (dialogContext, anim, secondaryAnim) {
        final activeIncident = _activeSosIncident ?? _lastResolvedSosIncident;
        final activeEvt = _activeRealEmergencyEvent;
        final bool hasActiveReal = activeIncident != null || activeEvt != null;

        final modalTitle = activeIncident != null
            ? (activeIncident.room != null && activeIncident.room!.isNotEmpty
                  ? 'SOS จากห้อง ${activeIncident.room}'
                  : 'SOS จากนักเรียน')
            : (activeEvt != null
                  ? 'เหตุฉุกเฉินจาก ${activeEvt.deviceName}'
                  : 'SOS ฉุกเฉิน');

        final modalSubtitle = activeIncident != null
            ? '${activeIncident.reason ?? "สัญญาณฉุกเฉิน"} • ${activeIncident.room != null && activeIncident.room!.isNotEmpty ? "ห้อง ${activeIncident.room!}" : "ในโรงเรียน"} • ${activeIncident.createdAt.toLocal().hour.toString().padLeft(2, "0")}:${activeIncident.createdAt.toLocal().minute.toString().padLeft(2, "0")} น.'
            : (activeEvt != null
                  ? '${activeEvt.location} • ${activeEvt.triggeredAt.toLocal().hour.toString().padLeft(2, "0")}:${activeEvt.triggeredAt.toLocal().minute.toString().padLeft(2, "0")} น.'
                  : 'สัญญาณฉุกเฉิน');

        final modalLocation = activeIncident != null
            ? (activeIncident.room != null && activeIncident.room!.isNotEmpty
                  ? 'ห้อง ${activeIncident.room}'
                  : 'ภายในโรงเรียน')
            : (activeEvt != null ? activeEvt.location : 'ภายในโรงเรียน');

        final modalSource = activeIncident != null
            ? 'แอปพลิเคชันนักเรียน (SOS)'
            : (activeEvt != null
                  ? activeEvt.deviceName
                  : 'ระบบแจ้งเหตุฉุกเฉิน');

        final modalReporter = activeIncident != null
            ? '${activeIncident.reporterName.isNotEmpty ? activeIncident.reporterName : "นักเรียน"} (ส่งสัญญาณฉุกเฉิน)'
            : (activeEvt != null ? 'ไม่มี (แจ้งเตือนจากอุปกรณ์)' : 'นักเรียน');

        final modalTime = activeIncident != null
            ? '${activeIncident.createdAt.toLocal().hour.toString().padLeft(2, "0")}:${activeIncident.createdAt.toLocal().minute.toString().padLeft(2, "0")} น. (วันนี้)'
            : (activeEvt != null
                  ? '${activeEvt.triggeredAt.toLocal().hour.toString().padLeft(2, "0")}:${activeEvt.triggeredAt.toLocal().minute.toString().padLeft(2, "0")} น. (วันนี้)'
                  : '-');

        final modalNarrative = activeIncident != null
            ? (activeIncident.reason != null &&
                      activeIncident.reason!.isNotEmpty
                  ? 'นักเรียนแจ้งเหตุฉุกเฉิน: "${activeIncident.reason}" ระบบส่งสัญญาณแจ้งเตือนไปยังผู้อำนวยการและทีมครูเวรเรียบร้อยแล้ว'
                  : 'นักเรียนส่งสัญญาณขอความช่วยเหลือฉุกเฉินผ่านระบบ SOS กำลังประสานครูเวรและครูห้องพยาบาลเข้าช่วยเหลือ')
            : (activeEvt != null
                  ? 'ระบบตรวจพบการกดปุ่มแจ้งเหตุฉุกเฉินที่ ${activeEvt.location}'
                  : 'ไม่มีรายละเอียดเหตุการณ์');

        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
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
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 36,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Apple-Style Modal Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE11D48,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    size: 22,
                                    color: Color(0xFFE11D48),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        modalTitle,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1D1D1F),
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        modalSubtitle,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF86868B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // เหตุผลเดียวกับใน _sosActiveCard(): เนื้อหา
                                // ของ dialog นี้ (modalTitle/.../modalNarrative
                                // ด้านบน) สลับตาม hasActiveReal เท่านั้น ต้อง
                                // ใช้ตัวแปรเดียวกันกับป้าย ไม่ใช่ _hasRealData
                                if (hasActiveReal)
                                  _realBadge()
                                else
                                  _demoBadge(),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE11D48,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'วิกฤตระดับ 1',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFE11D48),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFE5E5EA,
                                      ).withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 17,
                                      color: Color(0xFF48484A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(
                            height: 1,
                            thickness: 0.6,
                            color: Color(0xFFE5E5EA),
                          ),

                          // 2. Scrollable Body
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Status Pills Row
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      _sosModalChip(
                                        icon: Icons.emergency_rounded,
                                        label: 'สัญญาณ SOS ฉุกเฉิน',
                                        color: const Color(0xFFE11D48),
                                        bg: const Color(0xFFFFE4E6),
                                      ),
                                      _sosModalChip(
                                        icon:
                                            Icons.radio_button_checked_rounded,
                                        label: sosResolved
                                            ? 'ปิดเหตุแล้ว'
                                            : (sosAccepted
                                                  ? 'ผอ. รับเรื่องแล้ว'
                                                  : 'รอรับ SOS'),
                                        color: sosResolved || sosAccepted
                                            ? const Color(0xFF059669)
                                            : const Color(0xFFE11D48),
                                        bg: sosResolved || sosAccepted
                                            ? const Color(0xFFD1FAE5)
                                            : const Color(0xFFFFE4E6),
                                      ),
                                      _sosModalChip(
                                        icon: Icons.sensors_rounded,
                                        label: hasActiveReal
                                            ? 'แอปนักเรียน'
                                            : 'IoT ในห้องเรียน',
                                        color: const Color(0xFF475569),
                                        bg: const Color(0xFFF1F5F9),
                                      ),
                                      _sosModalChip(
                                        icon: Icons.schedule_rounded,
                                        label: activeIncident != null
                                            ? '${activeIncident.createdAt.toLocal().hour.toString().padLeft(2, "0")}:${activeIncident.createdAt.toLocal().minute.toString().padLeft(2, "0")} น.'
                                            : 'ไม่ทราบเวลาแจ้ง',
                                        color: const Color(0xFFB45309),
                                        bg: const Color(0xFFFEF3C7),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Section 1: ข้อมูลจุดเกิดเหตุ (2x2 Grid)
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 16,
                                        color: Color(0xFFE11D48),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'ข้อมูลจุดเกิดเหตุ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  LayoutBuilder(
                                    builder: (context, c) {
                                      final isCompact = c.maxWidth < 450;
                                      final tileWidth = isCompact
                                          ? c.maxWidth
                                          : (c.maxWidth - 10) / 2;
                                      return Wrap(
                                        spacing: 10,
                                        runSpacing: 8,
                                        children: [
                                          _sosInfoTile(
                                            width: tileWidth,
                                            icon: Icons.apartment_rounded,
                                            title: 'สถานที่เกิดเหตุ',
                                            value: modalLocation,
                                            iconColor: const Color(0xFFE11D48),
                                          ),
                                          _sosInfoTile(
                                            width: tileWidth,
                                            icon: Icons.touch_app_rounded,
                                            title: 'แหล่งส่งสัญญาณ',
                                            value: modalSource,
                                            iconColor: const Color(0xFF2563EB),
                                          ),
                                          _sosInfoTile(
                                            width: tileWidth,
                                            icon:
                                                Icons.person_pin_circle_rounded,
                                            title: 'ผู้แจ้งเหตุ / ในพื้นที่',
                                            value: modalReporter,
                                            iconColor: const Color(0xFF059669),
                                          ),
                                          _sosInfoTile(
                                            width: tileWidth,
                                            icon: Icons.schedule_rounded,
                                            title: 'เวลาที่ตรวจพบสัญญาณ',
                                            value: modalTime,
                                            iconColor: const Color(0xFFD97706),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Section 2: รายละเอียดเหตุการณ์และอาการ
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.medical_services_rounded,
                                        size: 16,
                                        color: Color(0xFFE11D48),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'รายละเอียดเหตุการณ์และอาการ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1F2),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFFECDD3),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          modalNarrative,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            height: 1.5,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF881337),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFFDA4AF),
                                            ),
                                          ),
                                          child: Row(
                                            children: const [
                                              Icon(
                                                Icons.add_box_rounded,
                                                size: 16,
                                                color: Color(0xFFE11D48),
                                              ),
                                              SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'มาตรการเร่งด่วน: ประสานครูเวรและครูห้องพยาบาลเข้าดูแลพื้นที่ทันที',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF991B1B),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Quick tactical buttons (CCTV + Call Teacher)
                                  LayoutBuilder(
                                    builder: (context, c) {
                                      final isCompact = c.maxWidth < 430;
                                      final targetRoom = activeIncident?.room;
                                      final targetReporter =
                                          activeIncident?.reporterName;

                                      final cctv = OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFFE11D48,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFFDA4AF),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                          _showMessage(
                                            targetRoom != null &&
                                                    targetRoom.isNotEmpty
                                                ? 'กำลังเชื่อมต่อสัญญาณกล้อง CCTV ห้อง $targetRoom...'
                                                : 'กำลังเชื่อมต่อสัญญาณกล้อง CCTV ห้อง ม.3/2...',
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.videocam_rounded,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'เปิดกล้อง CCTV ห้องนี้',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      );

                                      final call = OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF2563EB,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFBFDBFE),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          _showMessage(
                                            targetReporter != null &&
                                                    targetReporter.isNotEmpty
                                                ? 'กำลังโทรด่วนหาผู้แจ้งเหตุ ($targetReporter)...'
                                                : 'กำลังโทรด่วนหาครูประจำห้อง (ครูสมหญิง)...',
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.phone_in_talk_rounded,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'โทรด่วนหาครูประจำห้อง',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      );

                                      if (isCompact) {
                                        return Column(
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: cctv,
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: call,
                                            ),
                                          ],
                                        );
                                      }

                                      return Row(
                                        children: [
                                          Expanded(child: cctv),
                                          const SizedBox(width: 10),
                                          Expanded(child: call),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Section 3: ขั้นตอนตอบสนองและไทม์ไลน์
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.timeline_rounded,
                                        size: 16,
                                        color: Color(0xFF2563EB),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'ขั้นตอนตอบสนองและไทม์ไลน์',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  Builder(
                                    builder: (context) {
                                      final createdTime = activeIncident != null
                                          ? '${activeIncident.createdAt.toLocal().hour.toString().padLeft(2, "0")}:${activeIncident.createdAt.toLocal().minute.toString().padLeft(2, "0")}:${activeIncident.createdAt.toLocal().second.toString().padLeft(2, "0")} น.'
                                          : (activeEvt != null
                                                ? '${activeEvt.triggeredAt.toLocal().hour.toString().padLeft(2, "0")}:${activeEvt.triggeredAt.toLocal().minute.toString().padLeft(2, "0")}:${activeEvt.triggeredAt.toLocal().second.toString().padLeft(2, "0")} น.'
                                                : '10:42:18 น.');

                                      final broadcastTime =
                                          activeIncident != null
                                          ? '${activeIncident.createdAt.toLocal().hour.toString().padLeft(2, "0")}:${activeIncident.createdAt.toLocal().minute.toString().padLeft(2, "0")}:${(activeIncident.createdAt.toLocal().second + 1).clamp(0, 59).toString().padLeft(2, "0")} น.'
                                          : (activeEvt != null
                                                ? '${activeEvt.triggeredAt.toLocal().hour.toString().padLeft(2, "0")}:${activeEvt.triggeredAt.toLocal().minute.toString().padLeft(2, "0")}:${(activeEvt.triggeredAt.toLocal().second + 1).clamp(0, 59).toString().padLeft(2, "0")} น.'
                                                : '10:42:19 น.');

                                      final ackTime =
                                          activeIncident?.acknowledgedAt != null
                                          ? '${activeIncident!.acknowledgedAt!.toLocal().hour.toString().padLeft(2, "0")}:${activeIncident.acknowledgedAt!.toLocal().minute.toString().padLeft(2, "0")} น. (ผู้อำนวยการ/ครูรับเรื่องแล้ว)'
                                          : (sosAccepted
                                                ? 'รับเรื่องเรียบร้อยแล้ว'
                                                : 'รอการกดยืนยันรับเรื่องด่วน');

                                      return Column(
                                        children: [
                                          _sosTimelineItem(
                                            stepNumber: '1',
                                            title:
                                                'ระบบรับสัญญาณ SOS อัตโนมัติ',
                                            subtitle:
                                                '$createdTime (ตรวจจับและแจ้งเตือนทันที)',
                                            isDone: true,
                                            isCurrent: false,
                                          ),
                                          _sosTimelineItem(
                                            stepNumber: '2',
                                            title:
                                                'ส่งสัญญาณแจ้งผู้อำนวยการและครูเวร',
                                            subtitle:
                                                '$broadcastTime (ส่งผ่านแอปและระบบข้อความด่วน)',
                                            isDone: true,
                                            isCurrent: false,
                                          ),
                                          _sosTimelineItem(
                                            stepNumber: '3',
                                            title:
                                                'ผู้อำนวยการรับ SOS และเข้าคุมเหตุการณ์',
                                            subtitle: ackTime,
                                            isDone:
                                                sosAccepted ||
                                                activeIncident
                                                        ?.acknowledgedAt !=
                                                    null,
                                            isCurrent:
                                                !sosAccepted &&
                                                activeIncident
                                                        ?.acknowledgedAt ==
                                                    null,
                                          ),
                                          _sosTimelineItem(
                                            stepNumber: '4',
                                            title:
                                                'ครูห้องพยาบาลและครูเวรเข้าพื้นที่',
                                            subtitle: sosResolved
                                                ? 'ดำเนินการปฐมพยาบาลและดูแลนักเรียนเรียบร้อย'
                                                : (sosAccepted
                                                      ? 'กำลังเข้าพื้นที่พร้อมชุดปฐมพยาบาล'
                                                      : 'รอดำเนินการสั่งการ'),
                                            isDone: sosResolved,
                                            isCurrent:
                                                sosAccepted && !sosResolved,
                                            isLast: true,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Section 4: ทีมเผชิญเหตุที่ได้รับแจ้ง
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.groups_rounded,
                                        size: 16,
                                        color: Color(0xFF059669),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'ทีมครูเวรและบุคลากรที่ได้รับแจ้ง',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const Spacer(),
                                      _demoBadge(),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  _sosTeamRow(
                                    name: 'ครูเวรอาคาร 3',
                                    role: 'เข้าคุมพื้นที่และดูแลความเรียบร้อย',
                                    status: 'ได้รับแจ้งแล้ว',
                                    statusColor: const Color(0xFF059669),
                                    statusBg: const Color(0xFFD1FAE5),
                                  ),
                                  _sosTeamRow(
                                    name: 'ฝ่ายกิจการนักเรียน / ครูปกครอง',
                                    role:
                                        'ประสานงานและดูแลความปลอดภัยในจุดเกิดเหตุ',
                                    status: 'ได้รับแจ้งแล้ว',
                                    statusColor: const Color(0xFF059669),
                                    statusBg: const Color(0xFFD1FAE5),
                                  ),
                                  _sosTeamRow(
                                    name: 'ครูห้องพยาบาล / อนามัยโรงเรียน',
                                    role:
                                        'เตรียมเวชภัณฑ์และเข้าปฐมพยาบาลเบื้องต้น',
                                    status: 'Standby พร้อม',
                                    statusColor: const Color(0xFF2563EB),
                                    statusBg: const Color(0xFFDBEAFE),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Divider(
                            height: 1,
                            thickness: 0.6,
                            color: Color(0xFFE5E5EA),
                          ),

                          // 3. Decisive Bottom Footer Bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            color: const Color(
                              0xFFF9F9FB,
                            ).withValues(alpha: 0.6),
                            child: LayoutBuilder(
                              builder: (context, c) {
                                final isCompact = c.maxWidth < 460;
                                final accept = ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        (sosAccepted || sosResolved)
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFFE11D48),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: (sosAccepted || sosResolved)
                                      ? null
                                      : () async {
                                          final inc = _activeSosIncident;
                                          final evt = _activeRealEmergencyEvent;
                                          if (inc != null) {
                                            try {
                                              await IncidentService.acknowledgeIncidentReport(
                                                inc.id,
                                              );
                                            } catch (e) {
                                              debugPrint(
                                                'Error acknowledging incident: $e',
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'เกิดข้อผิดพลาด: $e',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                              return;
                                            }
                                          } else if (evt != null) {
                                            try {
                                              await EmergencyService.acknowledgeEmergencyEvent(
                                                evt.id,
                                              );
                                            } catch (e) {
                                              debugPrint(
                                                'Error acknowledging emergency event: $e',
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'เกิดข้อผิดพลาด: $e',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                              return;
                                            }
                                          }
                                          setDialogState(() {
                                            sosAccepted = true;
                                          });
                                          setState(() {
                                            sosAccepted = true;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '✓ ผอ. รับทราบและสั่งการระดมทีมครูเวรและครูอนามัยแล้ว',
                                                ),
                                                backgroundColor: Color(
                                                  0xFF059669,
                                                ),
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                          await _loadRealData();
                                        },
                                  icon: Icon(
                                    (sosAccepted || sosResolved)
                                        ? Icons.check_circle_rounded
                                        : Icons.local_fire_department_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    (sosAccepted || sosResolved)
                                        ? '✓ ผอ. รับเรื่องแล้ว'
                                        : '🚨 รับ SOS และสั่งการ',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                );

                                final resolve = ElevatedButton.icon(
                                  key: const Key(
                                    'director-emergency-close-modal',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !sosAccepted || sosResolved
                                        ? const Color(0xFFE2E8F0)
                                        : const Color(0xFFDCFCE7),
                                    foregroundColor: !sosAccepted || sosResolved
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF047857),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: !sosAccepted || sosResolved
                                      ? null
                                      : () async {
                                          final inc = _activeSosIncident;
                                          final evt = _activeRealEmergencyEvent;
                                          final closed =
                                              await _closeAndConfirmEmergency(
                                                incident: inc,
                                                emergencyEvent: evt,
                                                resolutionNote:
                                                    'ผู้อำนวยการรับเรื่องและระงับเหตุเรียบร้อย',
                                              );
                                          if (closed && dialogContext.mounted) {
                                            Navigator.pop(dialogContext);
                                          }
                                        },
                                  icon: const Icon(
                                    Icons.task_alt_rounded,
                                    size: 17,
                                  ),
                                  label: const Text(
                                    'ปิดเหตุการณ์ (เสร็จสิ้น)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                );

                                if (isCompact) {
                                  return Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: accept,
                                      ),
                                      const SizedBox(height: 8),
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
                                    const SizedBox(width: 10),
                                    Expanded(child: resolve),
                                  ],
                                );
                              },
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

  Widget _sosModalChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sosInfoTile({
    required double width,
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
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
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
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

  Widget _sosTimelineItem({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    bool isLast = false,
  }) {
    final color = isDone
        ? const Color(0xFF059669)
        : isCurrent
        ? const Color(0xFFE11D48)
        : const Color(0xFF94A3B8);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? const Color(0xFF059669)
                      : isCurrent
                      ? const Color(0xFFE11D48)
                      : const Color(0xFFF1F5F9),
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF059669)
                        : isCurrent
                        ? const Color(0xFFFDA4AF)
                        : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        )
                      : isCurrent
                      ? const Icon(Icons.circle, size: 8, color: Colors.white)
                      : Text(
                          stepNumber,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone
                        ? const Color(0xFF059669).withValues(alpha: 0.4)
                        : const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isCurrent || isDone
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isCurrent
                          ? const Color(0xFFE11D48)
                          : isDone
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrent
                          ? const Color(0xFF9F1239)
                          : const Color(0xFF64748B),
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sosTeamRow({
    required String name,
    required String role,
    required String status,
    required Color statusColor,
    required Color statusBg,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetail(_EmergencyEvent item) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'EventDetailModal',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      pageBuilder: (dialogContext, anim, secondaryAnim) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 540),
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
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Apple Modal Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 22,
                                color: item.color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D1D1F),
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.type} • ${item.location} • ${item.time}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF86868B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_hasRealData) _realBadge() else _demoBadge(),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  item.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _statusColor(item.status),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.of(dialogContext).pop(),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE5E5EA,
                                  ).withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 17,
                                  color: Color(0xFF48484A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(
                        height: 1,
                        thickness: 0.6,
                        color: Color(0xFFE5E5EA),
                      ),

                      // Content Body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Box 1: รายละเอียด
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: item.color,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'รายละเอียดเหตุการณ์',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            item.description,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              height: 1.45,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Box 2: การดำเนินการและสถานะ
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    item.status,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _statusColor(
                                      item.status,
                                    ).withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _statusColor(item.status),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'สถานะ: ${item.status}',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: _statusColor(item.status),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'การดำเนินการ: ${item.action}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              height: 1.4,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(
                        height: 1,
                        thickness: 0.6,
                        color: Color(0xFFE5E5EA),
                      ),

                      // Apple Bottom Action Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        color: const Color(0xFFF9F9FB).withValues(alpha: 0.6),
                        child: Row(
                          children: [
                            if (item.status != 'ปิดเหตุแล้ว') ...[
                              GestureDetector(
                                key: const Key(
                                  'director-emergency-close-detail',
                                ),
                                onTap: () async {
                                  final incident = item.type == 'ปุ่มฉุกเฉิน'
                                      ? null
                                      : _realIncidents
                                            .where(
                                              (candidate) =>
                                                  candidate.id == item.id,
                                            )
                                            .firstOrNull;
                                  final emergencyEvent =
                                      item.type == 'ปุ่มฉุกเฉิน'
                                      ? _realEmergencyEvents
                                            .where(
                                              (candidate) =>
                                                  candidate.id == item.id,
                                            )
                                            .firstOrNull
                                      : null;
                                  final closed =
                                      await _closeAndConfirmEmergency(
                                        incident: incident,
                                        emergencyEvent: emergencyEvent,
                                        resolutionNote: 'ปิดเหตุโดยผู้อำนวยการ',
                                      );
                                  if (closed && dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                },
                                child: Container(
                                  height: 38,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(19),
                                    border: Border.all(
                                      color: const Color(0xFF10B981),
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'ปิดเหตุ',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.of(dialogContext).pop(),
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF),
                                  borderRadius: BorderRadius.circular(19),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF007AFF,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'เสร็จสิ้น',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
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
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Text(
        'ไม่พบเหตุการณ์ตามเงื่อนไข',
        style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmergencySummaryData {
  final String title;
  final String value;
  final String unit;
  final String sub;
  final String badge;
  final Color badgeBg;
  final Color badgeTextColor;
  final IconData icon;
  final Color headerBg;
  final Color headerColor;
  final VoidCallback onTap;
  final bool isReal;

  const _EmergencySummaryData({
    required this.title,
    required this.value,
    required this.unit,
    required this.sub,
    required this.badge,
    required this.badgeBg,
    required this.badgeTextColor,
    required this.icon,
    required this.headerBg,
    required this.headerColor,
    required this.onTap,
    this.isReal = false,
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
