import 'dart:convert';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../utils/web_download.dart';
import 'controllers/school_admin_alerts_controller.dart';
import 'controllers/school_admin_async_state.dart';
import 'theme/school_admin_palette.dart';

typedef SchoolAdminAuditLogsLoader =
    Future<List<SchoolAdminAuditLog>> Function();
typedef SchoolAlertsDownloadBytes =
    void Function({
      required String filename,
      required List<int> bytes,
      required String mimeType,
    });

class SchoolAlertsPage extends StatefulWidget {
  const SchoolAlertsPage({
    super.key,
    this.controller,
    this.loadAuditLogs,
    this.downloadBytesOverride,
  });

  final SchoolAdminAlertsController? controller;
  final SchoolAdminAuditLogsLoader? loadAuditLogs;
  // Seam for tests: lets a test prove the export button actually calls a
  // download instead of the old always-disabled button with a tooltip.
  final SchoolAlertsDownloadBytes? downloadBytesOverride;

  @override
  State<SchoolAlertsPage> createState() => _SchoolAlertsPageState();
}

class _SchoolAlertsPageState extends State<SchoolAlertsPage> {
  final TextEditingController _searchController = TextEditingController();

  late final SchoolAdminAlertsController _controller;
  late final SchoolAdminAuditLogsLoader _loadAuditLogs;
  late final bool _ownsController;

  String _selectedCategory = 'ทุกประเภท';
  String _selectedSeverity = 'ทุกระดับ';
  String _selectedStatus = 'ทุกสถานะ';
  String _selectedBuilding = 'ทุกอาคาร';

  List<_AlertRecord> _alerts = [];
  List<_AlertLogRecord> _logs = [];
  bool _isLoading = true;
  String? _loadError;
  String? _logsLoadError;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        SchoolAdminAlertsController(
          loadAlerts: () => IncidentService.listSchoolAlerts(),
          acknowledgeAlert: IncidentService.acknowledgeSensorAlert,
          resolveAlert: IncidentService.resolveSensorAlert,
        );
    _loadAuditLogs =
        widget.loadAuditLogs ??
        () => SchoolAdminPlatformService().fetchAuditLogs(limit: 6);
    _controller.addListener(_syncAlertsFromController);
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    await _controller.load();
    await _refreshAuditLogs();
  }

  Future<void> _refreshAuditLogs() async {
    try {
      final logs = await _loadAuditLogs();
      if (!mounted) return;
      setState(() {
        _logsLoadError = null;
        _logs = logs
            .map(
              (log) => _AlertLogRecord(
                time:
                    '${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')} น.',
                action: log.action,
                target: log.target,
                detail: log.detail.isNotEmpty ? log.detail : log.target,
                by: log.actorName,
                type: 'update',
              ),
            )
            .toList(growable: false);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _logs = [];
        _logsLoadError = 'โหลดประวัติการแจ้งเตือนไม่สำเร็จ';
      });
    }
  }

  void _syncAlertsFromController() {
    if (!mounted) return;
    final state = _controller.state;
    List<SchoolSensorAlertRecord>? records;
    var isLoading = false;
    String? loadError;

    if (state is SchoolAdminData<List<SchoolSensorAlertRecord>>) {
      records = state.value;
    } else if (state is SchoolAdminEmpty<List<SchoolSensorAlertRecord>>) {
      records = const <SchoolSensorAlertRecord>[];
    } else if (state is SchoolAdminLoading<List<SchoolSensorAlertRecord>>) {
      records = state.previousData;
      isLoading = state.previousData == null;
    } else if (state is SchoolAdminError<List<SchoolSensorAlertRecord>>) {
      records = state.previousData;
      loadError = state.message;
    }

    setState(() {
      _isLoading = isLoading;
      _loadError = loadError;
      if (records != null) {
        _alerts = records.map(_mapAlertRecord).toList(growable: false);
      }
    });
  }

  _AlertRecord _mapAlertRecord(SchoolSensorAlertRecord alert) {
    final statusLabel = switch (alert.status) {
      'new' => 'ใหม่',
      'acknowledged' => 'รับทราบแล้ว',
      'resolved' => 'แก้ไขแล้ว',
      _ => alert.status,
    };
    return _AlertRecord(
      id: alert.id,
      title: '${alert.deviceName} (${alert.metric})',
      detail: 'ค่าเซนเซอร์: ${alert.value} (สถานะ: ${alert.status})',
      category: 'อุปกรณ์',
      severity: '--',
      status: statusLabel,
      building: '--',
      room: '--',
      source: alert.deviceCode,
      createdAt:
          '${alert.triggeredAt.hour.toString().padLeft(2, '0')}:${alert.triggeredAt.minute.toString().padLeft(2, '0')} น.',
      recipient: alert.acknowledgedByName ?? '--',
      action: '--',
      iconType: 'device',
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_syncAlertsFromController);
    if (_ownsController) _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_AlertRecord> get _filteredAlerts {
    final String keyword = _searchController.text.trim().toLowerCase();

    return _alerts.where((_AlertRecord alert) {
      final bool matchesSearch =
          keyword.isEmpty ||
          alert.title.toLowerCase().contains(keyword) ||
          alert.detail.toLowerCase().contains(keyword) ||
          alert.source.toLowerCase().contains(keyword) ||
          alert.room.toLowerCase().contains(keyword);

      final bool matchesCategory =
          _selectedCategory == 'ทุกประเภท' ||
          alert.category == _selectedCategory;

      final bool matchesSeverity =
          _selectedSeverity == 'ทุกระดับ' ||
          alert.severity == _selectedSeverity;

      final bool matchesStatus =
          _selectedStatus == 'ทุกสถานะ' || alert.status == _selectedStatus;

      final bool matchesBuilding =
          _selectedBuilding == 'ทุกอาคาร' ||
          alert.building == _selectedBuilding;

      return matchesSearch &&
          matchesCategory &&
          matchesSeverity &&
          matchesStatus &&
          matchesBuilding;
    }).toList();
  }

  String _csvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static const List<String> _alertsCsvHeader = [
    'id',
    'title',
    'detail',
    'category',
    'severity',
    'status',
    'building',
    'room',
    'source',
    'created_at',
    'recipient',
  ];

  /// Shared by both CSV and Excel export so the two formats can never drift
  /// apart. Returns null when the current filter matches nothing.
  List<List<String>>? _buildAlertRows() {
    final alerts = _filteredAlerts;
    if (alerts.isEmpty) return null;
    return <List<String>>[
      _alertsCsvHeader,
      for (final alert in alerts)
        [
          alert.id,
          alert.title,
          alert.detail,
          alert.category,
          alert.severity,
          alert.status,
          alert.building,
          alert.room,
          alert.source,
          alert.createdAt,
          alert.recipient,
        ],
    ];
  }

  void _exportAlerts() {
    final rows = _buildAlertRows();
    if (rows == null) {
      _showMessage('ไม่มีเหตุแจ้งเตือนให้ส่งออกตามตัวกรองปัจจุบัน');
      return;
    }
    final csv = rows.map((row) => row.map(_csvField).join(',')).join('\r\n');

    final doDownload = widget.downloadBytesOverride ?? downloadBytes;
    doDownload(
      filename:
          'alerts_${DateTime.now().toIso8601String().split('T').first}.csv',
      bytes: utf8.encode('﻿$csv'),
      mimeType: 'text/csv',
    );

    _showMessage('ส่งออกรายงานเหตุแจ้งเตือน ${rows.length - 1} รายการแล้ว (CSV)');
  }

  void _exportAlertsExcel() {
    final rows = _buildAlertRows();
    if (rows == null) {
      _showMessage('ไม่มีเหตุแจ้งเตือนให้ส่งออกตามตัวกรองปัจจุบัน');
      return;
    }

    final workbook = xls.Excel.createExcel();
    final sheet = workbook[workbook.getDefaultSheet() ?? 'Sheet1'];
    for (final row in rows) {
      sheet.appendRow(row.map(xls.TextCellValue.new).toList());
    }
    final bytes = workbook.encode();
    if (bytes == null) {
      _showMessage('สร้างไฟล์ Excel ไม่สำเร็จ');
      return;
    }

    final doDownload = widget.downloadBytesOverride ?? downloadBytes;
    doDownload(
      filename:
          'alerts_${DateTime.now().toIso8601String().split('T').first}.xlsx',
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    _showMessage(
      'ส่งออกรายงานเหตุแจ้งเตือน ${rows.length - 1} รายการแล้ว (Excel)',
    );
  }

  int get _newCount => _alerts.where((alert) => alert.status == 'ใหม่').length;

  int get _resolvedCount => _alerts.where((alert) {
    return alert.status == 'แก้ไขแล้ว' ||
        alert.status == 'ส่งต่อแล้ว' ||
        alert.status == 'รับทราบแล้ว';
  }).length;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'ทุกประเภท';
      _selectedSeverity = 'ทุกระดับ';
      _selectedStatus = 'ทุกสถานะ';
      _selectedBuilding = 'ทุกอาคาร';
    });
  }

  Future<void> _confirmAndUpdateAlertStatus(
    _AlertRecord alert,
    String status,
  ) async {
    // Unreachable from the UI now that the button is disabled, but kept as
    // a guard: nothing in `sensor_alerts` can hold this state.
    if (status == 'กำลังตรวจสอบ') return;
    final isAcknowledge = status == 'รับทราบแล้ว';
    final isResolve = status == 'แก้ไขแล้ว';
    if (!isAcknowledge && !isResolve) {
      _showMessage('ไม่รองรับสถานะนี้');
      return;
    }
    if (_controller.busyAlertIds.contains(alert.id)) {
      _showMessage('กำลังบันทึกการแจ้งเตือนนี้');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        title: Text(isAcknowledge ? 'ยืนยันการรับทราบ' : 'ยืนยันว่าแก้ไขแล้ว'),
        content: Text(
          isAcknowledge
              ? 'ยืนยันว่าคุณได้รับทราบการแจ้งเตือน\n“${alert.title}” แล้วหรือไม่'
              : 'ยืนยันว่าปัญหา\n“${alert.title}”\nได้รับการแก้ไขเรียบร้อยแล้วหรือไม่',
          style: const TextStyle(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final succeeded = isAcknowledge
        ? await _controller.acknowledge(alert.id)
        : await _controller.resolve(alert.id);
    if (!mounted) return;

    if (succeeded) {
      await _refreshAuditLogs();
      if (mounted) _showMessage('เปลี่ยนสถานะเป็น “$status” แล้ว');
      return;
    }

    final state = _controller.state;
    final message = state is SchoolAdminError<List<SchoolSensorAlertRecord>>
        ? state.message
        : 'บันทึกสถานะการแจ้งเตือนไม่สำเร็จ';
    _showMessage(message);
  }

  void _showAlertDetail(_AlertRecord alert) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AlertIconBox(
                            icon: _iconForType(alert.iconType),
                            color: _severityColor(alert.severity),
                            size: 52,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alert.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: SchoolAdminPalette.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alert.detail,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: SchoolAdminPalette.textSecondary,
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
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _AlertBadge(
                            label: alert.severity,
                            color: _severityColor(alert.severity),
                          ),
                          _AlertBadge(
                            label: alert.status,
                            color: _statusColor(alert.status),
                          ),
                          _AlertBadge(
                            label: alert.category,
                            color: SchoolAdminPalette.primaryDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _AlertDetailRow(
                        icon: Icons.apartment_rounded,
                        label: 'อาคาร',
                        value: alert.building,
                      ),
                      _AlertDetailRow(
                        icon: Icons.meeting_room_rounded,
                        label: 'ห้อง / พื้นที่',
                        value: alert.room,
                      ),
                      _AlertDetailRow(
                        icon: Icons.sensors_rounded,
                        label: 'แหล่งข้อมูล',
                        value: alert.source,
                      ),
                      _AlertDetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'เวลาแจ้งเตือน',
                        value: alert.createdAt,
                      ),
                      _AlertDetailRow(
                        icon: Icons.forward_to_inbox_rounded,
                        label: 'ผู้รับแจ้ง',
                        value: alert.recipient,
                      ),
                      _AlertDetailRow(
                        icon: Icons.task_alt_rounded,
                        label: 'สิ่งที่ควรทำ',
                        value: alert.action,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'จัดการการแจ้งเตือน',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: SchoolAdminPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _confirmAndUpdateAlertStatus(
                                alert,
                                'รับทราบแล้ว',
                              );
                            },
                            icon: const Icon(Icons.visibility_rounded),
                            label: const Text('รับทราบ'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _confirmAndUpdateAlertStatus(
                                alert,
                                'กำลังตรวจสอบ',
                              );
                            },
                            icon: const Icon(Icons.manage_search_rounded),
                            label: const Text('กำลังตรวจสอบ'),
                          ),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _confirmAndUpdateAlertStatus(alert, 'แก้ไขแล้ว');
                            },
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text('แก้ไขแล้ว'),
                          ),
                        ],
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

  Color _severityColor(String severity) {
    switch (severity) {
      case 'เร่งด่วน':
        return SchoolAdminPalette.red;
      case 'เฝ้าระวัง':
        return SchoolAdminPalette.secondary;
      default:
        return SchoolAdminPalette.primaryDark;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ใหม่':
        return SchoolAdminPalette.red;
      case 'กำลังตรวจสอบ':
        return SchoolAdminPalette.secondary;
      case 'แก้ไขแล้ว':
      case 'ส่งต่อแล้ว':
      case 'รับทราบแล้ว':
        return SchoolAdminPalette.green;
      default:
        return SchoolAdminPalette.textMuted;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'device':
        return Icons.memory_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'electric':
        return Icons.bolt_rounded;
      case 'air':
        return Icons.air_rounded;
      case 'security':
        return Icons.security_rounded;
      case 'student':
        return Icons.person_off_rounded;
      case 'resource':
        return Icons.energy_savings_leaf_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_AlertRecord> alerts = _filteredAlerts;

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
                  _buildHeader(),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: LinearProgressIndicator(),
                    ),
                  if (_loadError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: SchoolAdminPalette.red,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_loadError!)),
                              TextButton(
                                onPressed: _loadAlerts,
                                child: const Text('ลองใหม่'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  _buildSummary(),
                  const SizedBox(height: 14),
                  _buildPriorityOverview(),
                  const SizedBox(height: 14),
                  _buildFilters(),
                  const SizedBox(height: 14),
                  _buildAlerts(alerts),
                  const SizedBox(height: 14),
                  _buildAutomationRules(),
                  const SizedBox(height: 14),
                  _buildDeliveryOverview(),
                  const SizedBox(height: 14),
                  _buildLogs(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget title = const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: SchoolAdminPalette.primarySoft,
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: SchoolAdminPalette.primaryDark,
                    ),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'การแจ้งเตือน',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'รวมเหตุผิดปกติจากอุปกรณ์ ไฟฟ้า น้ำ คุณภาพอากาศ '
                          'ความปลอดภัย และการแจ้งเตือนที่ระบบส่งต่อให้ผู้รับผิดชอบ',
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

              final Widget actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // The "acknowledge all" control below was tappable and
                  // answered with a "ยังไม่เชื่อมต่อ" snackbar. Honest, but the
                  // DoD asks for controls without a backend to be disabled —
                  // an admin should be able to see what is unavailable
                  // without having to press it.
                  PopupMenuButton<String>(
                    tooltip: 'ส่งออกรายงาน',
                    onSelected: (value) => value == 'csv'
                        ? _exportAlerts()
                        : _exportAlertsExcel(),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'csv', child: Text('ส่งออกเป็น CSV')),
                      PopupMenuItem(
                        value: 'excel',
                        child: Text('ส่งออกเป็น Excel'),
                      ),
                    ],
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('ส่งออกรายงาน'),
                    ),
                  ),
                  Tooltip(
                    message:
                        'ยังไม่เปิดใช้งาน — รับทราบได้ทีละรายการจากปุ่มในตาราง',
                    child: FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.done_all_rounded),
                      label: const Text('รับทราบทั้งหมด (ยังไม่เปิดใช้งาน)'),
                    ),
                  ),
                ],
              );

              if (constraints.maxWidth < 760) {
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
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final List<_AlertSummaryData> items = [
      _AlertSummaryData(
        title: 'แจ้งเตือนใหม่',
        value: '$_newCount',
        detail: 'ยังไม่ได้รับทราบ',
        icon: Icons.notifications_none_rounded,
        color: SchoolAdminPalette.red,
      ),
      _AlertSummaryData(
        title: 'เร่งด่วน',
        value: '--',
        detail: 'ยังไม่มีข้อมูลระดับความเร่งด่วน',
        icon: Icons.priority_high_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _AlertSummaryData(
        title: 'กำลังตรวจสอบ',
        value: '--',
        detail: 'ยังไม่มีสถานะนี้จากระบบหลังบ้าน',
        icon: Icons.manage_search_rounded,
        color: SchoolAdminPalette.secondary,
      ),
      _AlertSummaryData(
        title: 'ดำเนินการแล้ว',
        value: '$_resolvedCount',
        detail: 'รับทราบ ส่งต่อ หรือแก้ไขแล้ว',
        icon: Icons.check_circle_outline_rounded,
        color: SchoolAdminPalette.green,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1050) columns = 2;
        if (constraints.maxWidth < 300) columns = 1;

        const double spacing = 12;
        final double width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((_AlertSummaryData item) {
            return SizedBox(
              width: width,
              child: _AlertSummaryCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPriorityOverview() {
    return const _AlertSectionCard(
      title: 'ภาพรวมเรื่องที่ต้องดูวันนี้',
      subtitle: 'ยังไม่มีการเชื่อมต่อข้อมูลสรุปตามประเภทจากระบบหลังบ้าน',
      child: _AlertUnavailableContent(),
    );
  }

  /// A dropdown offering only the values that actually occur in the loaded
  /// alerts, or nothing at all when the field carries no real value.
  ///
  /// Returns null when there is nothing to choose between — a field the
  /// backend never populates renders as '--' on every row, and a filter over
  /// it is a control that cannot do anything.
  Widget? _buildDerivedFilter({
    required String label,
    required String allLabel,
    required String selected,
    required Iterable<String> values,
    required ValueChanged<String> onChanged,
  }) {
    final options =
        values.where((v) => v.trim().isNotEmpty && v != '--').toSet().toList()
          ..sort();
    if (options.isEmpty) return null;

    return _AlertFilterDropdown(
      label: label,
      // A stale selection (the user filtered, then the data changed under
      // them) must not leave the dropdown showing a value it no longer has.
      value: options.contains(selected) ? selected : allLabel,
      items: <String>[allLabel, ...options],
      onChanged: onChanged,
    );
  }

  Widget _buildFilters() {
    return _AlertSectionCard(
      title: 'ค้นหาและกรองการแจ้งเตือน',
      subtitle: 'ค้นหาจากชื่อเหตุการณ์ อุปกรณ์ ห้อง หรือแหล่งข้อมูล',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget search = TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ค้นหาการแจ้งเตือน อุปกรณ์ ห้อง หรือแหล่งข้อมูล',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          );

          // Every dropdown below is built from the alerts actually loaded.
          //
          // They used to be const lists, and none of them could filter
          // anything. `list_school_alerts` returns device sensor alerts, so
          // the page maps every row to category 'อุปกรณ์' with no severity,
          // building or room — yet the menus offered ไฟฟ้า / น้ำ /
          // คุณภาพอากาศ / ความปลอดภัย / นักเรียน, three severity levels, and
          // five invented building names ("อาคารเรียน A", "อาคารปฏิบัติการ").
          // Choosing any of them emptied the table and looked like "no alerts
          // in that building" rather than "this filter cannot work".
          // Statuses 'กำลังตรวจสอบ' and 'ส่งต่อแล้ว' likewise do not exist in
          // `sensor_alerts`. A filter offering only the values present can
          // never lie about what it is filtering.
          final Widget? category = _buildDerivedFilter(
            label: 'ประเภท',
            allLabel: 'ทุกประเภท',
            selected: _selectedCategory,
            values: _alerts.map((a) => a.category),
            onChanged: (value) => setState(() => _selectedCategory = value),
          );

          final Widget? severity = _buildDerivedFilter(
            label: 'ระดับ',
            allLabel: 'ทุกระดับ',
            selected: _selectedSeverity,
            values: _alerts.map((a) => a.severity),
            onChanged: (value) => setState(() => _selectedSeverity = value),
          );

          final Widget? status = _buildDerivedFilter(
            label: 'สถานะ',
            allLabel: 'ทุกสถานะ',
            selected: _selectedStatus,
            values: _alerts.map((a) => a.status),
            onChanged: (value) => setState(() => _selectedStatus = value),
          );

          final Widget? building = _buildDerivedFilter(
            label: 'อาคาร',
            allLabel: 'ทุกอาคาร',
            selected: _selectedBuilding,
            values: _alerts.map((a) => a.building),
            onChanged: (value) => setState(() => _selectedBuilding = value),
          );

          final Widget clear = OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('ล้างตัวกรอง'),
          );

          // Only the dropdowns that have something to offer.
          final dropdowns = <Widget>[?category, ?severity, ?status, ?building];

          if (constraints.maxWidth < 950) {
            return Column(
              children: [
                search,
                if (dropdowns.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: dropdowns
                        .map((d) => SizedBox(width: 200, child: d))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: clear),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: search),
              for (final d in dropdowns) ...[
                const SizedBox(width: 10),
                Expanded(child: d),
              ],
              const SizedBox(width: 10),
              clear,
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlerts(List<_AlertRecord> alerts) {
    return _AlertSectionCard(
      title: 'รายการแจ้งเตือน',
      subtitle: 'พบ ${alerts.length} รายการ',
      padding: EdgeInsets.zero,
      child: alerts.isEmpty
          ? const _AlertEmptyState()
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth >= 1000) {
                  return Table(
                    border: const TableBorder(
                      top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      horizontalInside: BorderSide(
                        color: Color(0xFFF1F5F9),
                        width: 1,
                      ),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2.6),
                      1: FlexColumnWidth(1.05),
                      2: FlexColumnWidth(1.05),
                      3: FlexColumnWidth(1.2),
                      4: FlexColumnWidth(1.45),
                      5: FlexColumnWidth(1.05),
                      6: FlexColumnWidth(2.55),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                        ),
                        children: [
                          _AlertTableHeader(
                            text: 'การแจ้งเตือน',
                            align: TextAlign.left,
                          ),
                          _AlertTableHeader(text: 'ประเภท'),
                          _AlertTableHeader(text: 'ระดับ'),
                          _AlertTableHeader(text: 'สถานะ'),
                          _AlertTableHeader(text: 'พื้นที่'),
                          _AlertTableHeader(text: 'เวลา'),
                          _AlertTableHeader(text: 'จัดการ'),
                        ],
                      ),
                      ...alerts.map((_AlertRecord alert) {
                        return TableRow(
                          children: [
                            _AlertTableNameCell(
                              alert: alert,
                              icon: _iconForType(alert.iconType),
                              color: _severityColor(alert.severity),
                              onTap: () => _showAlertDetail(alert),
                            ),
                            _AlertTableCell(
                              child: _AlertBadge(
                                label: alert.category,
                                color: SchoolAdminPalette.primaryDark,
                              ),
                            ),
                            _AlertTableCell(
                              child: _AlertBadge(
                                label: alert.severity,
                                color: _severityColor(alert.severity),
                              ),
                            ),
                            _AlertTableCell(
                              child: _AlertBadge(
                                label: alert.status,
                                color: _statusColor(alert.status),
                              ),
                            ),
                            _AlertTableCell(
                              child: Text(
                                '${alert.building}\n${alert.room}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            _AlertTableCell(
                              child: Text(
                                alert.createdAt,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            _AlertTableCell(
                              child: _AlertActionButtons(
                                alert: alert,
                                onView: () => _showAlertDetail(alert),
                                onAcknowledge: () =>
                                    _confirmAndUpdateAlertStatus(
                                      alert,
                                      'รับทราบแล้ว',
                                    ),
                                onChecking: () => _confirmAndUpdateAlertStatus(
                                  alert,
                                  'กำลังตรวจสอบ',
                                ),
                                onResolved: () => _confirmAndUpdateAlertStatus(
                                  alert,
                                  'แก้ไขแล้ว',
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: alerts.map((_AlertRecord alert) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertMobileCard(
                          alert: alert,
                          icon: _iconForType(alert.iconType),
                          severityColor: _severityColor(alert.severity),
                          statusColor: _statusColor(alert.status),
                          onTap: () => _showAlertDetail(alert),
                          onAcknowledge: () => _confirmAndUpdateAlertStatus(
                            alert,
                            'รับทราบแล้ว',
                          ),
                          onChecking: () => _confirmAndUpdateAlertStatus(
                            alert,
                            'กำลังตรวจสอบ',
                          ),
                          onResolved: () =>
                              _confirmAndUpdateAlertStatus(alert, 'แก้ไขแล้ว'),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAutomationRules() {
    return const _AlertSectionCard(
      title: 'กฎการแจ้งเตือนอัตโนมัติ',
      subtitle: 'ยังไม่มีการเชื่อมต่อข้อมูลกฎการแจ้งเตือนจากระบบหลังบ้าน',
      child: _AlertUnavailableContent(),
    );
  }

  Widget _buildDeliveryOverview() {
    return const _AlertSectionCard(
      title: 'ช่องทางและผู้รับการแจ้งเตือน',
      subtitle: 'ยังไม่มีการเชื่อมต่อข้อมูลช่องทางและผู้รับจากระบบหลังบ้าน',
      child: _AlertUnavailableContent(),
    );
  }

  Widget _buildLogs() {
    Widget content;
    if (_logsLoadError != null) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: SchoolAdminPalette.red,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(_logsLoadError!)),
            TextButton(
              onPressed: _refreshAuditLogs,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    } else if (_logs.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Text(
                'ยังไม่มีข้อมูล',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ยังไม่มีประวัติการแจ้งเตือน',
                style: TextStyle(color: SchoolAdminPalette.textSecondary),
              ),
            ],
          ),
        ),
      );
    } else {
      content = Column(
        children: _logs.take(6).map((_AlertLogRecord log) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _AlertLogRow(log: log),
          );
        }).toList(),
      );
    }

    return _AlertSectionCard(
      title: 'Log การแจ้งเตือนล่าสุด',
      subtitle: 'บันทึกการสร้าง เปิดดู เปลี่ยนสถานะ และส่งต่อการแจ้งเตือน',
      child: content,
    );
  }
}

class _AlertSummaryCard extends StatelessWidget {
  const _AlertSummaryCard({required this.data});

  final _AlertSummaryData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 240;

        return Container(
          constraints: BoxConstraints(minHeight: compact ? 148 : 130),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AlertIconBox(icon: data.icon, color: data.color),
                    const SizedBox(height: 10),
                    Text(
                      data.value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 12,
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
                )
              : Row(
                  children: [
                    _AlertIconBox(icon: data.icon, color: data.color),
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
                          const SizedBox(height: 5),
                          Text(
                            data.title,
                            style: const TextStyle(
                              fontSize: 12,
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
      },
    );
  }
}

class _AlertSectionCard extends StatelessWidget {
  const _AlertSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.padding,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final bool isFullWidth = padding == EdgeInsets.zero;

    return SizedBox(
      width: double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: isFullWidth
                    ? const EdgeInsets.fromLTRB(18, 16, 18, 14)
                    : EdgeInsets.zero,
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
                  ],
                ),
              ),
              if (!isFullWidth) const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertFilterDropdown extends StatelessWidget {
  const _AlertFilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }
}

class _AlertTableHeader extends StatelessWidget {
  const _AlertTableHeader({required this.text, this.align = TextAlign.center});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF475569),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _AlertTableCell extends StatelessWidget {
  const _AlertTableCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      child: Center(child: child),
    );
  }
}

class _AlertTableNameCell extends StatelessWidget {
  const _AlertTableNameCell({
    required this.alert,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final _AlertRecord alert;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          children: [
            _AlertIconBox(icon: icon, color: color, size: 38),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.45,
                      color: SchoolAdminPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertMobileCard extends StatelessWidget {
  const _AlertMobileCard({
    required this.alert,
    required this.icon,
    required this.severityColor,
    required this.statusColor,
    required this.onTap,
    required this.onAcknowledge,
    required this.onChecking,
    required this.onResolved,
  });

  final _AlertRecord alert;
  final IconData icon;
  final Color severityColor;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onAcknowledge;
  final VoidCallback onChecking;
  final VoidCallback onResolved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AlertIconBox(icon: icon, color: severityColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: SchoolAdminPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.detail,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.45,
                          color: SchoolAdminPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _AlertBadge(label: alert.severity, color: severityColor),
              _AlertBadge(label: alert.status, color: statusColor),
              _AlertBadge(
                label: alert.category,
                color: SchoolAdminPalette.primaryDark,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SchoolAdminPalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert.building} • ${alert.room}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${alert.createdAt} • ส่งถึง ${alert.recipient}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.45,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _AlertActionButtons(
            alert: alert,
            onView: onTap,
            onAcknowledge: onAcknowledge,
            onChecking: onChecking,
            onResolved: onResolved,
            compact: false,
          ),
        ],
      ),
    );
  }
}

class _AlertActionButtons extends StatelessWidget {
  const _AlertActionButtons({
    required this.alert,
    required this.onView,
    required this.onAcknowledge,
    required this.onChecking,
    required this.onResolved,
    this.compact = true,
  });

  final _AlertRecord alert;
  final VoidCallback onView;
  final VoidCallback onAcknowledge;
  final VoidCallback onChecking;
  final VoidCallback onResolved;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool acknowledged = alert.status == 'รับทราบแล้ว';
    final bool checking = alert.status == 'กำลังตรวจสอบ';
    final bool resolved = alert.status == 'แก้ไขแล้ว';

    final ButtonStyle smallOutlinedStyle = OutlinedButton.styleFrom(
      minimumSize: Size(compact ? 0 : 94, compact ? 38 : 42),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 8 : 10,
      ),
      textStyle: TextStyle(
        fontSize: compact ? 8.2 : 9.5,
        fontWeight: FontWeight.w900,
      ),
    );

    final ButtonStyle smallFilledStyle = FilledButton.styleFrom(
      minimumSize: Size(compact ? 0 : 94, compact ? 38 : 42),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 8 : 10,
      ),
      textStyle: TextStyle(
        fontSize: compact ? 8.2 : 9.5,
        fontWeight: FontWeight.w900,
      ),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      runSpacing: 5,
      children: [
        OutlinedButton.icon(
          onPressed: onView,
          style: smallOutlinedStyle,
          icon: Icon(Icons.visibility_outlined, size: compact ? 14 : 16),
          label: const Text('ดู'),
        ),
        OutlinedButton.icon(
          onPressed: acknowledged || checking || resolved
              ? null
              : onAcknowledge,
          style: smallOutlinedStyle,
          icon: Icon(
            acknowledged ? Icons.check_circle_rounded : Icons.done_rounded,
            size: compact ? 14 : 16,
          ),
          label: Text(acknowledged ? 'รับทราบแล้ว' : 'รับทราบ'),
        ),
        // `sensor_alerts.status` only ever holds 'acknowledged' or
        // 'resolved' — `acknowledge_sensor_alert` and `resolve_sensor_alert`
        // are the only writers and there is no investigating state for this
        // to move an alert into. The button used to be tappable and answer
        // with "ยังไม่เชื่อมต่อระบบหลังบ้าน", which reads as "not wired up
        // yet" when in fact nothing in the schema can back it.
        Tooltip(
          message: 'ยังไม่เปิดใช้งาน — ระบบยังไม่มีสถานะ "กำลังตรวจสอบ"',
          child: OutlinedButton.icon(
            onPressed: null,
            style: smallOutlinedStyle,
            icon: Icon(Icons.manage_search_rounded, size: compact ? 14 : 16),
            label: Text(checking ? 'กำลังตรวจสอบ' : 'ตรวจสอบ'),
          ),
        ),
        FilledButton.icon(
          onPressed: resolved ? null : onResolved,
          style: smallFilledStyle,
          icon: Icon(
            Icons.check_circle_outline_rounded,
            size: compact ? 14 : 16,
          ),
          label: Text(resolved ? 'แก้ไขแล้ว' : 'แก้ไขแล้ว'),
        ),
      ],
    );
  }
}

class _AlertLogRow extends StatelessWidget {
  const _AlertLogRow({required this.log});

  final _AlertLogRecord log;

  Color get color {
    switch (log.type) {
      case 'success':
        return SchoolAdminPalette.green;
      case 'danger':
        return SchoolAdminPalette.red;
      default:
        return SchoolAdminPalette.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool mobile = constraints.maxWidth < 760;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
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
                      '${log.action} • ${log.target}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
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
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _AlertIconBox(icon: Icons.history_rounded, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${log.action} • ${log.target}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: SchoolAdminPalette.textPrimary,
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
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
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
                          color: SchoolAdminPalette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _AlertDetailRow extends StatelessWidget {
  const _AlertDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: SchoolAdminPalette.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertIconBox extends StatelessWidget {
  const _AlertIconBox({
    required this.icon,
    required this.color,
    this.size = 42,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80), width: 1.1),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _AlertUnavailableContent extends StatelessWidget {
  const _AlertUnavailableContent();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, color: SchoolAdminPalette.textMuted),
            SizedBox(height: 8),
            Text(
              'ยังไม่มีข้อมูล',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'ส่วนนี้ยังไม่เชื่อมต่อระบบหลังบ้าน',
              style: TextStyle(color: SchoolAdminPalette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertEmptyState extends StatelessWidget {
  const _AlertEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 45),
          child: const Column(
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 46,
                color: SchoolAdminPalette.textMuted,
              ),
              SizedBox(height: 10),
              Text(
                'ยังไม่มีข้อมูล',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              Text(
                'ลองเปลี่ยนคำค้นหาหรือล้างตัวกรอง',
                style: TextStyle(
                  fontSize: 12,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertSummaryData {
  const _AlertSummaryData({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
}

class _AlertRecord {
  const _AlertRecord({
    required this.id,
    required this.title,
    required this.detail,
    required this.category,
    required this.severity,
    required this.status,
    required this.building,
    required this.room,
    required this.source,
    required this.createdAt,
    required this.recipient,
    required this.action,
    required this.iconType,
  });

  final String id;
  final String title;
  final String detail;
  final String category;
  final String severity;
  final String status;
  final String building;
  final String room;
  final String source;
  final String createdAt;
  final String recipient;
  final String action;
  final String iconType;

  _AlertRecord copyWith({String? status}) {
    return _AlertRecord(
      id: id,
      title: title,
      detail: detail,
      category: category,
      severity: severity,
      status: status ?? this.status,
      building: building,
      room: room,
      source: source,
      createdAt: createdAt,
      recipient: recipient,
      action: action,
      iconType: iconType,
    );
  }
}

class _AlertLogRecord {
  const _AlertLogRecord({
    required this.time,
    required this.action,
    required this.target,
    required this.detail,
    required this.by,
    required this.type,
  });

  final String time;
  final String action;
  final String target;
  final String detail;
  final String by;
  final String type;
}
