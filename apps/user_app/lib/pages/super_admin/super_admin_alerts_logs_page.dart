import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../utils/web_download.dart';
import 'theme/app_palette.dart';
import 'widgets/dev_ui.dart';

class SuperAdminAlertsLogsPage extends StatefulWidget {
  const SuperAdminAlertsLogsPage({
    super.key,
    this.embedded = false,
    this.loadSchools,
    this.loadAlerts,
    this.loadAuditLogs,
    this.acknowledgeAlert,
    this.resolveAlert,
  });

  /// True when embedded in [SuperAdminNavigationShell]'s desktop sidebar
  /// layout — suppresses this page's own AppBar since the sidebar
  /// already shows which page is selected.
  final bool embedded;

  final Future<List<SchoolPlatformRecord>> Function()? loadSchools;
  final Future<List<SchoolSensorAlertRecord>> Function()? loadAlerts;
  final Future<List<SchoolAdminAuditLog>> Function()? loadAuditLogs;
  final Future<void> Function(String alertId)? acknowledgeAlert;
  final Future<void> Function(String alertId, {String? note})? resolveAlert;

  @override
  State<SuperAdminAlertsLogsPage> createState() =>
      _SuperAdminAlertsLogsPageState();
}

typedef AlertsLogsPage = SuperAdminAlertsLogsPage;

class _SuperAdminAlertsLogsPageState extends State<SuperAdminAlertsLogsPage> {
  final TextEditingController _searchController = TextEditingController();
  final SchoolAdminPlatformService _platformService =
      SchoolAdminPlatformService();

  bool _isLoading = true;
  String? _loadError;

  final List<_AlertViewModel> _alerts = <_AlertViewModel>[];
  final List<SchoolPlatformRecord> _schools = <SchoolPlatformRecord>[];
  final List<SchoolAdminAuditLog> _activityLogs = <SchoolAdminAuditLog>[];

  String _severityFilter = 'ทุกระดับ';
  String _statusFilter = 'ทุกสถานะ';
  String _schoolFilter = 'ทุกโรงเรียน';
  String _sortMode = 'เร่งด่วนก่อน';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final List<SchoolPlatformRecord> schoolRecords =
          await (widget.loadSchools ?? _platformService.fetchSchools)();

      final List<SchoolSensorAlertRecord> alertRecords =
          await (widget.loadAlerts ?? IncidentService.listSchoolAlerts)();

      List<SchoolAdminAuditLog> logRecords = [];
      try {
        logRecords = await (widget.loadAuditLogs ??
            () => _platformService.fetchAuditLogs(limit: 15))();
      } catch (_) {
        logRecords = [];
      }

      if (!mounted) return;

      final Map<String, String> schoolNameById = {
        for (final s in schoolRecords) s.id: s.name,
      };

      final List<_AlertViewModel> loadedAlerts = [];
      for (int i = 0; i < alertRecords.length; i++) {
        final a = alertRecords[i];
        final sName = schoolNameById[a.schoolId] ??
            (a.schoolId.isEmpty ? 'ทุกโรงเรียน' : 'โรงเรียนในระบบ');

        final sev = _calculateSeverity(a.metric, a.value);
        final status = _parseStatus(a.status);

        final mins = DateTime.now().difference(a.triggeredAt).inMinutes;

        final String idSuffix = a.id.replaceAll('-', '').toUpperCase();
        loadedAlerts.add(_AlertViewModel(
          id: 'ALT-${idSuffix.substring(idSuffix.length - 6)}',
          rawRecord: a,
          title: '${a.metric} เกินเกณฑ์ (${a.value.toStringAsFixed(1)})',
          message:
              'อุปกรณ์ ${a.deviceName} (${a.deviceCode}) ส่งค่า ${a.metric} = ${a.value}',
          school: sName,
          schoolId: a.schoolId,
          device: a.deviceName,
          deviceCode: a.deviceCode,
          metric: a.metric,
          value: a.value,
          severity: sev,
          status: status,
          triggeredAt: a.triggeredAt,
          timeLabel: mins < 60
              ? '$mins นาทีที่แล้ว'
              : '${a.triggeredAt.hour.toString().padLeft(2, '0')}:${a.triggeredAt.minute.toString().padLeft(2, '0')} น.',
          acknowledgedBy: a.acknowledgedByName ?? '',
          acknowledgedAt: a.acknowledgedAt,
        ));
      }

      setState(() {
        _alerts
          ..clear()
          ..addAll(loadedAlerts);

        _schools
          ..clear()
          ..addAll(schoolRecords);

        _activityLogs
          ..clear()
          ..addAll(logRecords);

        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  _AlertSeverity _calculateSeverity(String metric, double value) {
    final m = metric.toLowerCase();
    if (m.contains('smoke') || m.contains('gas') || m.contains('fire')) {
      return _AlertSeverity.critical;
    }
    if (m.contains('pm2.5') || m.contains('pm25')) {
      if (value > 75) return _AlertSeverity.critical;
      if (value > 50) return _AlertSeverity.high;
      return _AlertSeverity.medium;
    }
    if (m.contains('temp') || m.contains('อุณหภูมิ')) {
      if (value > 45) return _AlertSeverity.high;
      if (value > 38) return _AlertSeverity.medium;
      return _AlertSeverity.low;
    }
    return _AlertSeverity.medium;
  }

  _AlertStatus _parseStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'acknowledged':
        return _AlertStatus.acknowledged;
      case 'in_progress':
      case 'inprogress':
        return _AlertStatus.inProgress;
      case 'resolved':
      case 'closed':
        return _AlertStatus.resolved;
      default:
        return _AlertStatus.open;
    }
  }

  int get _criticalCount => _alerts
      .where((a) =>
          a.status != _AlertStatus.resolved &&
          a.severity == _AlertSeverity.critical)
      .length;

  int get _highCount => _alerts
      .where((a) =>
          a.status != _AlertStatus.resolved &&
          a.severity == _AlertSeverity.high)
      .length;

  int get _openCount =>
      _alerts.where((a) => a.status == _AlertStatus.open).length;

  int get _resolvedCount =>
      _alerts.where((a) => a.status == _AlertStatus.resolved).length;

  List<String> get _schoolOptions => <String>[
        'ทุกโรงเรียน',
        ...(_schools.map((s) => s.name).toSet().toList()..sort()),
      ];

  List<_AlertViewModel> get _filteredAlerts {
    final String query = _searchController.text.trim().toLowerCase();

    final List<_AlertViewModel> result = _alerts.where((item) {
      final bool matchesText = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.message.toLowerCase().contains(query) ||
          item.school.toLowerCase().contains(query) ||
          item.device.toLowerCase().contains(query) ||
          item.deviceCode.toLowerCase().contains(query) ||
          item.metric.toLowerCase().contains(query);

      bool matchesSeverity = true;
      if (_severityFilter != 'ทุกระดับ') {
        if (_severityFilter == 'วิกฤต (Critical)') {
          matchesSeverity = item.severity == _AlertSeverity.critical;
        } else if (_severityFilter == 'สูง (High)') {
          matchesSeverity = item.severity == _AlertSeverity.high;
        } else if (_severityFilter == 'ปานกลาง (Medium)') {
          matchesSeverity = item.severity == _AlertSeverity.medium;
        } else if (_severityFilter == 'ต่ำ (Low)') {
          matchesSeverity = item.severity == _AlertSeverity.low;
        }
      }

      bool matchesStatus = true;
      if (_statusFilter != 'ทุกสถานะ') {
        if (_statusFilter == 'รอดำเนินการ (Open)') {
          matchesStatus = item.status == _AlertStatus.open;
        } else if (_statusFilter == 'รับทราบแล้ว (Ack)') {
          matchesStatus = item.status == _AlertStatus.acknowledged;
        } else if (_statusFilter == 'แก้ไขแล้ว (Resolved)') {
          matchesStatus = item.status == _AlertStatus.resolved;
        }
      }

      final bool matchesSchool = _schoolFilter == 'ทุกโรงเรียน' ||
          item.school == _schoolFilter ||
          item.school == 'ทุกโรงเรียน';

      return matchesText && matchesSeverity && matchesStatus && matchesSchool;
    }).toList();

    if (_sortMode == 'เร่งด่วนก่อน') {
      result.sort((a, b) {
        final sevComp = b.severity.index.compareTo(a.severity.index);
        if (sevComp != 0) return sevComp;
        return b.triggeredAt.compareTo(a.triggeredAt);
      });
    } else if (_sortMode == 'ล่าสุดก่อน') {
      result.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    } else if (_sortMode == 'ชื่อโรงเรียน') {
      result.sort((a, b) => a.school.compareTo(b.school));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text(
                'การแจ้งเตือนและประวัติระบบ (Alerts & Logs)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  tooltip: 'รีเฟรชข้อมูล',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => _loadAllData(),
                ),
              ],
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _alerts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _alerts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 52, color: AppPalette.carnivalRed),
              const SizedBox(height: 14),
              const Text(
                'ไม่สามารถโหลดข้อมูลการแจ้งเตือนได้',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppPalette.textSecondary),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _loadAllData(),
                style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.deepBlue),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('ลองใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    final List<_AlertViewModel> filteredAlerts = _filteredAlerts;

    return RefreshIndicator(
      onRefresh: () => _loadAllData(showLoading: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: <Widget>[
          _buildHeroCard(),
          const SizedBox(height: 18),
          _buildSummaryCards(),
          const SizedBox(height: 18),
          _buildPriorityPanel(),
          const SizedBox(height: 18),
          _buildSearchAndFilterPanel(),
          const SizedBox(height: 18),
          _buildAlertsListPanel(filteredAlerts),
          const SizedBox(height: 18),
          _buildAuditLogsPanel(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. Hero Card
  // ===========================================================================

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppPalette.deepBlue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: _shadow,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool mobile = constraints.maxWidth < 860;

          final Widget information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _badge(
                    'ศูนย์รวมเหตุฉุกเฉินและเซนเซอร์',
                    AppPalette.circusYellow,
                  ),
                  _badge(
                    'Real-Time Telemetry',
                    Colors.white.withAlpha(50),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'มอนิเตอร์และรับมือเหตุแจ้งเตือนทั่วทั้งระบบ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'ติดตามค่าเซนเซอร์ที่ผิดปกติ รับทราบเหตุ มอบหมายทีม และตรวจสอบ Audit Log ย้อนหลัง',
                style: TextStyle(
                  color: Colors.white.withAlpha(210),
                  fontSize: mobile ? 12 : 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _exportAlerts,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.circusYellow,
                      foregroundColor: AppPalette.textPrimary,
                    ),
                    icon: const Icon(Icons.file_download_rounded),
                    label: const Text(
                      'ส่งออกรายงานเหตุการณ์',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _loadAllData(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('ดึงข้อมูลล่าสุด'),
                  ),
                ],
              ),
            ],
          );

          final Widget metrics = Container(
            width: mobile ? double.infinity : 320,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppPalette.softBeige),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (
                BuildContext context,
                BoxConstraints metricConstraints,
              ) {
                const double gap = 10;
                final double width = (metricConstraints.maxWidth - gap) / 2;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: <Widget>[
                    SizedBox(
                      width: width,
                      child: _heroMetric(
                        Icons.notifications_active_rounded,
                        '${_alerts.length}',
                        'แจ้งเตือนทั้งหมด',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _heroMetric(
                        Icons.warning_amber_rounded,
                        '$_criticalCount',
                        'วิกฤต (Critical)',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _heroMetric(
                        Icons.pending_actions_rounded,
                        '$_openCount',
                        'รอดำเนินการ',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _heroMetric(
                        Icons.check_circle_outline_rounded,
                        '$_resolvedCount',
                        'แก้ไขแล้ว',
                      ),
                    ),
                  ],
                );
              },
            ),
          );

          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                information,
                const SizedBox(height: 18),
                metrics,
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: information),
              const SizedBox(width: 24),
              metrics,
            ],
          );
        },
      ),
    );
  }

  Widget _heroMetric(IconData icon, String value, String label) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.deepBlue.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppPalette.circusYellow.withAlpha(55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppPalette.deepBlue, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.deepBlue,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. Summary Cards
  // ===========================================================================

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 1100 ? 4 : 2;
        const double gap = 12;
        final double width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        final List<Widget> cards = <Widget>[
          _summaryCard(
            Icons.crisis_alert_rounded,
            'เหตุวิกฤต (Critical)',
            '$_criticalCount',
            'ต้องได้รับการตรวจสอบทันที',
            AppPalette.carnivalRed,
          ),
          _summaryCard(
            Icons.warning_rounded,
            'เหตุความเสี่ยงสูง (High)',
            '$_highCount',
            'ค่าเซนเซอร์เกินเกณฑ์มาตรฐาน',
            AppPalette.circusYellow,
          ),
          _summaryCard(
            Icons.hourglass_top_rounded,
            'รอดำเนินการ (Open)',
            '$_openCount',
            'ยังไม่ได้รับการรับทราบหรือแก้ไข',
            AppPalette.deepBlue,
          ),
          _summaryCard(
            Icons.task_alt_rounded,
            'แก้ไขเสร็จสิ้น',
            '$_resolvedCount',
            'เหตุการณ์ที่ปิดงานเรียบร้อย',
            AppPalette.gardenGreen,
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((Widget card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _summaryCard(
    IconData icon,
    String title,
    String value,
    String detail,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withAlpha(30),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. Priority Panel
  // ===========================================================================

  Widget _buildPriorityPanel() {
    final List<_AlertViewModel> urgentAlerts = _alerts
        .where((a) =>
            a.status != _AlertStatus.resolved &&
            (a.severity == _AlertSeverity.critical ||
                a.severity == _AlertSeverity.high))
        .toList();

    return _panel(
      title: 'เหตุการณ์ที่ต้องจัดการเร่งด่วน',
      trailing: _badge(
        '${urgentAlerts.length} เหตุการณ์',
        urgentAlerts.isEmpty ? AppPalette.gardenGreen : AppPalette.carnivalRed,
      ),
      child: urgentAlerts.isEmpty
          ? _empty(
              Icons.verified_user_rounded,
              'ไม่มีเหตุการณ์วิกฤตค้างอยู่',
              'ระบบและค่าเซนเซอร์ทุกโรงเรียนอยู่ในสภาวะปกติ',
            )
          : Column(
              children: <Widget>[
                for (int index = 0;
                    index < urgentAlerts.length && index < 4;
                    index++) ...<Widget>[
                  _urgentAlertRow(urgentAlerts[index]),
                  if (index < urgentAlerts.length.clamp(0, 4) - 1)
                    const Divider(height: 20),
                ],
              ],
            ),
    );
  }

  Widget _urgentAlertRow(_AlertViewModel item) {
    final Color sevColor = _severityColor(item.severity);

    return InkWell(
      onTap: () => _showAlertDetails(item),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: sevColor.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.warning_amber_rounded, color: sevColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppPalette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.school} • ${item.device} (${item.deviceCode})',
                    style: const TextStyle(
                      color: AppPalette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'เกิดขึ้นเมื่อ ${item.timeLabel}',
                    style: TextStyle(
                      color: sevColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (item.status == _AlertStatus.open)
              FilledButton(
                onPressed: () => _acknowledgeAlert(item),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.deepBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(60, 32),
                ),
                child: const Text(
                  'รับทราบ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              )
            else
              _badge(item.statusLabel, _statusColor(item.status)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. Search and Filters
  // ===========================================================================

  Widget _buildSearchAndFilterPanel() {
    return _panel(
      title: 'ค้นหาและกรองการแจ้งเตือน',
      trailing: TextButton.icon(
        onPressed: _clearFilters,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('ล้างตัวกรอง'),
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อเหตุ อุปกรณ์ โรงเรียน ค่าเซนเซอร์',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'ล้างคำค้นหา',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 600
                      ? 2
                      : 1;
              const double gap = 10;
              final double width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: <Widget>[
                  SizedBox(
                    width: width,
                    child: _dropdown(
                      label: 'ความรุนแรง',
                      icon: Icons.shield_rounded,
                      value: _severityFilter,
                      items: const <String>[
                        'ทุกระดับ',
                        'วิกฤต (Critical)',
                        'สูง (High)',
                        'ปานกลาง (Medium)',
                        'ต่ำ (Low)',
                      ],
                      onChanged: (String value) {
                        setState(() {
                          _severityFilter = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _dropdown(
                      label: 'สถานะ',
                      icon: Icons.filter_alt_rounded,
                      value: _statusFilter,
                      items: const <String>[
                        'ทุกสถานะ',
                        'รอดำเนินการ (Open)',
                        'รับทราบแล้ว (Ack)',
                        'แก้ไขแล้ว (Resolved)',
                      ],
                      onChanged: (String value) {
                        setState(() {
                          _statusFilter = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _dropdown(
                      label: 'โรงเรียน',
                      icon: Icons.apartment_rounded,
                      value: _schoolFilter,
                      items: _schoolOptions,
                      onChanged: (String value) {
                        setState(() {
                          _schoolFilter = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _dropdown(
                      label: 'เรียงตาม',
                      icon: Icons.sort_rounded,
                      value: _sortMode,
                      items: const <String>[
                        'เร่งด่วนก่อน',
                        'ล่าสุดก่อน',
                        'ชื่อโรงเรียน',
                      ],
                      onChanged: (String value) {
                        setState(() {
                          _sortMode = value;
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      value: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items
          .map(
            (String item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _severityFilter = 'ทุกระดับ';
      _statusFilter = 'ทุกสถานะ';
      _schoolFilter = 'ทุกโรงเรียน';
      _sortMode = 'เร่งด่วนก่อน';
    });
  }

  // ===========================================================================
  // 5. Alerts List Panel
  // ===========================================================================

  Widget _buildAlertsListPanel(List<_AlertViewModel> filteredAlerts) {
    return _panel(
      title: 'รายการแจ้งเตือนจากอุปกรณ์',
      trailing: Text(
        'พบ ${filteredAlerts.length} รายการ',
        style: const TextStyle(
          color: AppPalette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: filteredAlerts.isEmpty
          ? _empty(
              Icons.notifications_off_rounded,
              'ไม่พบรายการแจ้งเตือน',
              'ลองเปลี่ยนตัวกรองหรือคำค้นหาอีกครั้ง',
            )
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = constraints.maxWidth >= 1050 ? 2 : 1;
                const double gap = 14;
                final double width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: filteredAlerts
                      .map(
                        (_AlertViewModel alert) => SizedBox(
                          width: width,
                          child: _alertCard(alert),
                        ),
                      )
                      .toList(),
                );
              },
            ),
    );
  }

  Widget _alertCard(_AlertViewModel alert) {
    final Color sevColor = _severityColor(alert.severity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: alert.status == _AlertStatus.open
              ? sevColor.withAlpha(140)
              : AppPalette.softBeige.withAlpha(180),
        ),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: sevColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _metricIcon(alert.metric),
                  color: sevColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      alert.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alert.school} • ${alert.timeLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'ตัวเลือก',
                onSelected: (String action) {
                  if (action == 'details') {
                    _showAlertDetails(alert);
                  } else if (action == 'ack') {
                    _acknowledgeAlert(alert);
                  } else if (action == 'resolve') {
                    _openResolveDialog(alert);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'details',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.visibility_rounded),
                      title: Text('ดูรายละเอียด'),
                    ),
                  ),
                  if (alert.status == _AlertStatus.open)
                    const PopupMenuItem<String>(
                      value: 'ack',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.check_rounded),
                        title: Text('รับทราบเหตุการณ์'),
                      ),
                    ),
                  if (alert.status != _AlertStatus.resolved)
                    const PopupMenuItem<String>(
                      value: 'resolve',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.task_alt_rounded),
                        title: Text('ทำเครื่องหมายว่าแก้ไขแล้ว'),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _badge(alert.severityLabel, sevColor),
              _badge(alert.statusLabel, _statusColor(alert.status)),
              _badge(alert.device, AppPalette.deepBlue),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.softBeige.withAlpha(75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: <Widget>[
                _infoRow(Icons.devices_rounded, 'อุปกรณ์',
                    '${alert.device} (${alert.deviceCode})'),
                const SizedBox(height: 8),
                _infoRow(Icons.speed_rounded, 'ค่าที่วัดได้',
                    '${alert.metric} = ${alert.value.toStringAsFixed(1)}'),
                if (alert.acknowledgedBy.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  _infoRow(Icons.person_rounded, 'รับทราบโดย',
                      alert.acknowledgedBy),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAlertDetails(alert),
                  icon: const Icon(Icons.visibility_rounded, size: 17),
                  label: const Text('รายละเอียด'),
                ),
              ),
              const SizedBox(width: 8),
              if (alert.status == _AlertStatus.open)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _acknowledgeAlert(alert),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.deepBlue,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('รับทราบเหตุ'),
                  ),
                )
              else if (alert.status != _AlertStatus.resolved)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openResolveDialog(alert),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.gardenGreen,
                    ),
                    icon: const Icon(Icons.task_alt_rounded, size: 17),
                    label: const Text('ปิดงาน'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16, color: AppPalette.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. Audit Logs Panel
  // ===========================================================================

  Widget _buildAuditLogsPanel() {
    return _panel(
      title: 'ประวัติกิจกรรมและการสั่งการระบบ (Audit Logs)',
      trailing: TextButton.icon(
        onPressed: _exportActivityLogs,
        icon: const Icon(Icons.download_rounded),
        label: const Text('ส่งออก Log'),
      ),
      child: _activityLogs.isEmpty
          ? _empty(
              Icons.history_toggle_off_rounded,
              'ยังไม่มีประวัติกิจกรรม',
              'บันทึกกิจกรรมการสั่งการและแก้ไขระบบจะปรากฏที่นี่',
            )
          : Column(
              children: <Widget>[
                for (int index = 0; index < _activityLogs.length; index++) ...<Widget>[
                  _auditLogRow(_activityLogs[index]),
                  if (index < _activityLogs.length - 1) const Divider(height: 20),
                ],
              ],
            ),
    );
  }

  Widget _auditLogRow(SchoolAdminAuditLog log) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppPalette.deepBlue.withAlpha(25),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.history_rounded, color: AppPalette.deepBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                log.action,
                style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                log.detail.isNotEmpty ? log.detail : log.target,
                style: const TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'โดย ${log.actorName} • ${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')} น.',
                style: const TextStyle(
                  color: AppPalette.gardenGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Dialogs & Actions
  // ===========================================================================

  Future<void> _acknowledgeAlert(_AlertViewModel alert) async {
    try {
      await (widget.acknowledgeAlert ??
          IncidentService.acknowledgeSensorAlert)(alert.rawRecord.id);
      _message('รับทราบเหตุการณ์ ${alert.title} แล้ว');
      _loadAllData(showLoading: false);
    } catch (e) {
      _message('ไม่สามารถรับทราบเหตุการณ์ได้: $e');
    }
  }

  Future<void> _openResolveDialog(_AlertViewModel alert) async {
    final TextEditingController noteController = TextEditingController();

    final bool? resolved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ปิดงานและบันทึกผลการแก้ไข'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('คุณต้องการทำเครื่องหมายว่าเหตุ ${alert.title} ได้รับการแก้ไขแล้วใช่หรือไม่'),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'หมายเหตุการแก้ไข (ถ้ามี)',
                  hintText: 'เช่น ตรวจสอบสายเซนเซอร์แล้ว ค่ากลับสู่เกณฑ์ปกติ',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.gardenGreen,
              ),
              child: const Text('ยืนยันปิดงาน'),
            ),
          ],
        );
      },
    );

    final String note = noteController.text.trim();
    noteController.dispose();

    if (resolved != true || !mounted) return;

    try {
      final resolve = widget.resolveAlert ?? IncidentService.resolveSensorAlert;
      await resolve(
        alert.rawRecord.id,
        note: note.isNotEmpty ? note : null,
      );
      _message('ปิดงานเหตุการณ์ ${alert.title} เรียบร้อยแล้ว');
      _loadAllData(showLoading: false);
    } catch (e) {
      _message('ไม่สามารถปิดงานได้: $e');
    }
  }

  void _showAlertDetails(_AlertViewModel alert) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.80,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            final Color sevColor = _severityColor(alert.severity);

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppPalette.softBeige,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: sevColor.withAlpha(30),
                        child: Icon(
                          _metricIcon(alert.metric),
                          color: sevColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              alert.title,
                              style: const TextStyle(
                                color: AppPalette.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${alert.id} • ${alert.school}',
                              style: const TextStyle(
                                color: AppPalette.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _badge(alert.severityLabel, sevColor),
                      _badge(alert.statusLabel, _statusColor(alert.status)),
                      _badge(alert.device, AppPalette.deepBlue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailSection('รายละเอียดอุปกรณ์และค่าเซนเซอร์', <MapEntry<String, String>>[
                    MapEntry<String, String>('ชื่ออุปกรณ์', alert.device),
                    MapEntry<String, String>('รหัสอุปกรณ์', alert.deviceCode),
                    MapEntry<String, String>('โรงเรียน', alert.school),
                    MapEntry<String, String>('ประเภทเซนเซอร์', alert.metric),
                    MapEntry<String, String>('ค่าที่วัดได้', alert.value.toStringAsFixed(2)),
                    MapEntry<String, String>('เวลาที่เกิดเหตุ', '${alert.triggeredAt}'),
                    if (alert.acknowledgedBy.isNotEmpty)
                      MapEntry<String, String>('ผู้รับทราบเหตุ', alert.acknowledgedBy),
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      if (alert.status == _AlertStatus.open)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _acknowledgeAlert(alert);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppPalette.deepBlue,
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('รับทราบเหตุการณ์'),
                          ),
                        )
                      else if (alert.status != _AlertStatus.resolved)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _openResolveDialog(alert);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppPalette.gardenGreen,
                            ),
                            icon: const Icon(Icons.task_alt_rounded),
                            label: const Text('บันทึกปิดงาน'),
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
    );
  }

  Widget _detailSection(String title, List<MapEntry<String, String>> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.softBeige.withAlpha(65),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final MapEntry<String, String> row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      row.key,
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _csvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _exportAlerts() {
    final List<_AlertViewModel> alerts = _filteredAlerts;
    if (alerts.isEmpty) {
      _message('ไม่มีเหตุแจ้งเตือนให้ส่งออกตามตัวกรองปัจจุบัน');
      return;
    }

    final List<String> header = <String>[
      'id',
      'school',
      'device',
      'device_code',
      'metric',
      'value',
      'severity',
      'status',
      'triggered_at',
      'acknowledged_by',
    ];
    final List<List<String>> rows = <List<String>>[
      header,
      for (final _AlertViewModel a in alerts)
        <String>[
          a.id,
          a.school,
          a.device,
          a.deviceCode,
          a.metric,
          '${a.value}',
          a.severity.name,
          a.status.name,
          a.triggeredAt.toIso8601String(),
          a.acknowledgedBy,
        ],
    ];
    final String csv = rows.map((row) => row.map(_csvField).join(',')).join('\r\n');

    downloadBytes(
      filename: 'alerts_${DateTime.now().toIso8601String().split('T').first}.csv',
      bytes: utf8.encode('﻿$csv'),
      mimeType: 'text/csv',
    );

    _message('ส่งออกรายงานเหตุแจ้งเตือน ${alerts.length} รายการแล้ว');
  }

  void _exportActivityLogs() {
    if (_activityLogs.isEmpty) {
      _message('ไม่มีประวัติกิจกรรมให้ส่งออก');
      return;
    }

    final List<String> header = <String>[
      'action',
      'actor',
      'target',
      'detail',
      'created_at',
    ];
    final List<List<String>> rows = <List<String>>[
      header,
      for (final SchoolAdminAuditLog log in _activityLogs)
        <String>[
          log.action,
          log.actorName,
          log.target,
          log.detail,
          log.createdAt.toIso8601String(),
        ],
    ];
    final String csv = rows.map((row) => row.map(_csvField).join(',')).join('\r\n');

    downloadBytes(
      filename: 'activity_logs_${DateTime.now().toIso8601String().split('T').first}.csv',
      bytes: utf8.encode('﻿$csv'),
      mimeType: 'text/csv',
    );

    _message('ส่งออกประวัติกิจกรรม ${_activityLogs.length} รายการแล้ว');
  }

  Color _severityColor(_AlertSeverity sev) {
    switch (sev) {
      case _AlertSeverity.critical:
        return AppPalette.carnivalRed;
      case _AlertSeverity.high:
        return AppPalette.circusYellow;
      case _AlertSeverity.medium:
        return AppPalette.deepBlue;
      case _AlertSeverity.low:
        return AppPalette.textSecondary;
    }
  }

  Color _statusColor(_AlertStatus status) {
    switch (status) {
      case _AlertStatus.open:
        return AppPalette.carnivalRed;
      case _AlertStatus.acknowledged:
      case _AlertStatus.inProgress:
        return AppPalette.circusYellow;
      case _AlertStatus.resolved:
        return AppPalette.gardenGreen;
    }
  }

  IconData _metricIcon(String metric) {
    final m = metric.toLowerCase();
    if (m.contains('temp') || m.contains('อุณหภูมิ')) {
      return Icons.thermostat_rounded;
    }
    if (m.contains('pm2.5') || m.contains('air') || m.contains('อากาศ')) {
      return Icons.air_rounded;
    }
    if (m.contains('smoke') || m.contains('gas') || m.contains('ควัน')) {
      return Icons.local_fire_department_rounded;
    }
    if (m.contains('volt') || m.contains('power') || m.contains('ไฟ')) {
      return Icons.bolt_rounded;
    }
    return Icons.sensors_rounded;
  }

  Widget _panel({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return AppPanel(title: title, trailing: trailing, child: child);
  }

  Widget _badge(String label, Color color) {
    return StatusBadge(label: label, color: color);
  }

  Widget _empty(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: AppPalette.softBeige.withAlpha(50),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 25,
            backgroundColor: AppPalette.deepBlue.withAlpha(25),
            child: Icon(icon, color: AppPalette.deepBlue, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  List<BoxShadow> get _shadow => <BoxShadow>[
        BoxShadow(
          color: Colors.black.withAlpha(12),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
}

enum _AlertSeverity { critical, high, medium, low }

enum _AlertStatus { open, acknowledged, inProgress, resolved }

class _AlertViewModel {
  final String id;
  final SchoolSensorAlertRecord rawRecord;
  final String title;
  final String message;
  final String school;
  final String schoolId;
  final String device;
  final String deviceCode;
  final String metric;
  final double value;
  final _AlertSeverity severity;
  final _AlertStatus status;
  final DateTime triggeredAt;
  final String timeLabel;
  final String acknowledgedBy;
  final DateTime? acknowledgedAt;

  _AlertViewModel({
    required this.id,
    required this.rawRecord,
    required this.title,
    required this.message,
    required this.school,
    required this.schoolId,
    required this.device,
    required this.deviceCode,
    required this.metric,
    required this.value,
    required this.severity,
    required this.status,
    required this.triggeredAt,
    required this.timeLabel,
    required this.acknowledgedBy,
    this.acknowledgedAt,
  });

  String get severityLabel {
    switch (severity) {
      case _AlertSeverity.critical:
        return 'วิกฤต (Critical)';
      case _AlertSeverity.high:
        return 'สูง (High)';
      case _AlertSeverity.medium:
        return 'ปานกลาง (Medium)';
      case _AlertSeverity.low:
        return 'ต่ำ (Low)';
    }
  }

  String get statusLabel {
    switch (status) {
      case _AlertStatus.open:
        return 'รอดำเนินการ';
      case _AlertStatus.acknowledged:
        return 'รับทราบแล้ว';
      case _AlertStatus.inProgress:
        return 'กำลังตรวจสอบ';
      case _AlertStatus.resolved:
        return 'แก้ไขแล้ว';
    }
  }
}
