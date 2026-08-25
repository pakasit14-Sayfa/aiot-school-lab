import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

class SchoolAlertsPage extends StatefulWidget {
  const SchoolAlertsPage({super.key});

  @override
  State<SchoolAlertsPage> createState() => _SchoolAlertsPageState();
}

class _SchoolAlertsPageState extends State<SchoolAlertsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'ทุกประเภท';
  String _selectedSeverity = 'ทุกระดับ';
  String _selectedStatus = 'ทุกสถานะ';
  String _selectedBuilding = 'ทุกอาคาร';

  List<_AlertRecord> _alerts = [];
  List<_AlertLogRecord> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await IncidentService.listSchoolAlerts();
      final logs = await SchoolAdminPlatformService().fetchAuditLogs(limit: 6);
      if (mounted) {
        setState(() {
          _alerts = alerts.map((a) {
            final String statusLabel = a.isNew ? 'ใหม่' : (a.isAcknowledged ? 'รับทราบแล้ว' : 'แก้ไขแล้ว');
            return _AlertRecord(
              id: a.id,
              title: '${a.deviceName} (${a.metric})',
              detail: 'ค่าเซนเซอร์: ${a.value} (สถานะ: ${a.status})',
              category: 'อุปกรณ์',
              severity: a.value > 100 ? 'เร่งด่วน' : 'แจ้งเตือน',
              status: statusLabel,
              building: 'อาคารเรียน',
              room: '-',
              source: a.deviceCode,
              createdAt: '${a.triggeredAt.hour.toString().padLeft(2, '0')}:${a.triggeredAt.minute.toString().padLeft(2, '0')} น.',
              recipient: 'แอดมินโรงเรียน',
              action: a.isNew ? 'กดรับทราบเพื่อตรวจสอบ' : 'ตรวจสอบเรียบร้อย',
              iconType: 'device',
            );
          }).toList();

          _logs = logs.map((l) => _AlertLogRecord(
            time: '${l.createdAt.hour.toString().padLeft(2, '0')}:${l.createdAt.minute.toString().padLeft(2, '0')} น.',
            action: l.action,
            target: l.target,
            detail: l.detail.isNotEmpty ? l.detail : l.target,
            by: l.actorName,
            type: 'update',
          )).toList();
        });
      }
    } catch (_) {}
  }

  final List<_AlertRule> _rules = const [
    _AlertRule(
      title: 'นักเรียนไม่มาเรียน',
      condition: 'ไม่พบการเข้าเรียนตามเวลาที่กำหนด',
      recipient: 'ครูประจำชั้น',
      escalation: 'แอดมินเห็นเมื่อยังไม่ดำเนินการ',
      enabled: true,
      iconType: 'student',
    ),
    _AlertRule(
      title: 'อุปกรณ์ออฟไลน์',
      condition: 'ไม่ส่งข้อมูลเกิน 15 นาที',
      recipient: 'ครูประจำอาคาร + แอดมิน',
      escalation: 'เร่งด่วนเมื่อเกิน 30 นาที',
      enabled: true,
      iconType: 'device',
    ),
    _AlertRule(
      title: 'ไฟ / น้ำสูงผิดปกติ',
      condition: 'สูงกว่าค่าเฉลี่ยตามเกณฑ์',
      recipient: 'ครูประจำอาคาร',
      escalation: 'แจ้งแอดมินเมื่อเกินระดับที่กำหนด',
      enabled: true,
      iconType: 'resource',
    ),
    _AlertRule(
      title: 'คุณภาพอากาศผิดปกติ',
      condition: 'PM2.5 / AQI สูงกว่าเกณฑ์',
      recipient: 'ครูประจำอาคาร',
      escalation: 'แจ้งแอดมินเมื่อเข้าสู่ระดับเสี่ยง',
      enabled: true,
      iconType: 'air',
    ),
    _AlertRule(
      title: 'เข้าสู่ระบบผิดเกิน 3 ครั้ง',
      condition: 'บัญชีเดียวใส่รหัสผิดมากกว่า 3 ครั้ง',
      recipient: 'แอดมินโรงเรียน',
      escalation: 'บันทึก Log และตรวจสอบบัญชี',
      enabled: true,
      iconType: 'security',
    ),
  ];



  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_AlertRecord> get _filteredAlerts {
    final String keyword = _searchController.text.trim().toLowerCase();

    return _alerts.where((_AlertRecord alert) {
      final bool matchesSearch = keyword.isEmpty ||
          alert.title.toLowerCase().contains(keyword) ||
          alert.detail.toLowerCase().contains(keyword) ||
          alert.source.toLowerCase().contains(keyword) ||
          alert.room.toLowerCase().contains(keyword);

      final bool matchesCategory = _selectedCategory == 'ทุกประเภท' ||
          alert.category == _selectedCategory;

      final bool matchesSeverity = _selectedSeverity == 'ทุกระดับ' ||
          alert.severity == _selectedSeverity;

      final bool matchesStatus =
          _selectedStatus == 'ทุกสถานะ' || alert.status == _selectedStatus;

      final bool matchesBuilding = _selectedBuilding == 'ทุกอาคาร' ||
          alert.building == _selectedBuilding;

      return matchesSearch &&
          matchesCategory &&
          matchesSeverity &&
          matchesStatus &&
          matchesBuilding;
    }).toList();
  }

  int get _newCount => _alerts.where((alert) => alert.status == 'ใหม่').length;

  int get _urgentCount =>
      _alerts.where((alert) => alert.severity == 'เร่งด่วน').length;

  int get _checkingCount =>
      _alerts.where((alert) => alert.status == 'กำลังตรวจสอบ').length;

  int get _resolvedCount => _alerts.where((alert) {
        return alert.status == 'แก้ไขแล้ว' ||
            alert.status == 'ส่งต่อแล้ว' ||
            alert.status == 'รับทราบแล้ว';
      }).length;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    String title = 'ยืนยันการดำเนินการ';
    String message = 'ต้องการเปลี่ยนสถานะการแจ้งเตือนนี้หรือไม่';

    switch (status) {
      case 'รับทราบแล้ว':
        title = 'ยืนยันการรับทราบ';
        message =
            'ยืนยันว่าคุณได้รับทราบการแจ้งเตือน\n“${alert.title}” แล้วหรือไม่';
        break;
      case 'กำลังตรวจสอบ':
        title = 'ยืนยันการตรวจสอบ';
        message =
            'ยืนยันว่าจะเปลี่ยนรายการ\n“${alert.title}”\nเป็นสถานะกำลังตรวจสอบหรือไม่';
        break;
      case 'แก้ไขแล้ว':
        title = 'ยืนยันว่าแก้ไขแล้ว';
        message =
            'ยืนยันว่าปัญหา\n“${alert.title}”\nได้รับการแก้ไขเรียบร้อยแล้วหรือไม่';
        break;
    }

    final TextEditingController reviewerController = TextEditingController();

    final _AlertConfirmResult? result = await showDialog<_AlertConfirmResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            final String reviewerName = reviewerController.text.trim();
            final bool canConfirm = reviewerName.isNotEmpty;

            return AlertDialog(
              insetPadding: const EdgeInsets.all(16),
              title: Text(title),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: const TextStyle(
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: SchoolAdminPalette.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: SchoolAdminPalette.border,
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 20,
                              color: SchoolAdminPalette.primaryDark,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'ต้องลงชื่อผู้ตรวจสอบก่อนจึงจะกดยืนยันได้ '
                                'ชื่อที่กรอกจะถูกบันทึกไว้ใน Log เพื่อใช้ตรวจสอบย้อนหลัง',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: SchoolAdminPalette.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: reviewerController,
                        autofocus: true,
                        onChanged: (_) {
                          setDialogState(() {});
                        },
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อผู้ตรวจสอบ',
                          hintText: 'กรอกชื่อ-นามสกุลผู้ตรวจสอบ',
                          prefixIcon: Icon(
                            Icons.draw_rounded,
                          ),
                          helperText: 'จำเป็นต้องกรอกก่อนยืนยัน',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton.icon(
                  onPressed: canConfirm
                      ? () {
                          Navigator.of(dialogContext).pop(
                            _AlertConfirmResult(
                              confirmed: true,
                              reviewerName: reviewerName,
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('ยืนยัน'),
                ),
              ],
            );
          },
        );
      },
    );

    reviewerController.dispose();

    if (result?.confirmed == true &&
        result!.reviewerName.trim().isNotEmpty &&
        mounted) {
      _updateAlertStatus(
        alert,
        status,
        reviewerName: result.reviewerName.trim(),
      );
    }
  }

  void _updateAlertStatus(
    _AlertRecord alert,
    String status, {
    required String reviewerName,
  }) {
    final int index = _alerts.indexWhere((item) => item.id == alert.id);
    if (index < 0) return;

    setState(() {
      _alerts[index] = alert.copyWith(status: status);
      _logs.insert(
        0,
        _AlertLogRecord(
          time: 'เมื่อสักครู่',
          action: 'เปลี่ยนสถานะ',
          target: alert.id.toUpperCase(),
          detail: '${alert.status} → $status',
          by: reviewerName,
          type: status == 'แก้ไขแล้ว' ? 'success' : 'update',
        ),
      );
    });

    _showMessage('เปลี่ยนสถานะเป็น “$status” แล้ว');
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: SchoolAdminPalette.border),
            ),
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
                          _confirmAndUpdateAlertStatus(alert, 'รับทราบแล้ว');
                        },
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('รับทราบ'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _confirmAndUpdateAlertStatus(alert, 'กำลังตรวจสอบ');
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
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
              OutlinedButton.icon(
                onPressed: () {
                  _showMessage('ส่งออกรายงานการแจ้งเตือนแล้ว');
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('ส่งออกรายงาน'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final int newCount =
                      _alerts.where((item) => item.status == 'ใหม่').length;

                  if (newCount == 0) {
                    _showMessage(
                      'ไม่มีการแจ้งเตือนใหม่ที่ต้องรับทราบ',
                    );
                    return;
                  }

                  final TextEditingController reviewerController =
                      TextEditingController();

                  final _AlertConfirmResult? result =
                      await showDialog<_AlertConfirmResult>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext dialogContext) {
                      return StatefulBuilder(
                        builder: (
                          BuildContext context,
                          StateSetter setDialogState,
                        ) {
                          final String reviewerName =
                              reviewerController.text.trim();

                          return AlertDialog(
                            insetPadding: const EdgeInsets.all(16),
                            title: const Text('ยืนยันรับทราบทั้งหมด'),
                            content: SizedBox(
                              width: 520,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'มีการแจ้งเตือนใหม่ $newCount รายการ\n'
                                      'ต้องการเปลี่ยนทั้งหมดเป็น '
                                      '“รับทราบแล้ว” หรือไม่',
                                      style: const TextStyle(
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: SchoolAdminPalette.primarySoft,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: SchoolAdminPalette.border,
                                        ),
                                      ),
                                      child: const Text(
                                        'กรุณาลงชื่อผู้ตรวจสอบ '
                                        'ชื่อจะถูกบันทึกไว้ใน Log',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: SchoolAdminPalette.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: reviewerController,
                                      autofocus: true,
                                      onChanged: (_) {
                                        setDialogState(() {});
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'ชื่อผู้ตรวจสอบ',
                                        hintText: 'กรอกชื่อ-นามสกุลผู้ตรวจสอบ',
                                        prefixIcon: Icon(
                                          Icons.draw_rounded,
                                        ),
                                        helperText: 'จำเป็นต้องกรอกก่อนยืนยัน',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('ยกเลิก'),
                              ),
                              FilledButton.icon(
                                onPressed: reviewerName.isNotEmpty
                                    ? () {
                                        Navigator.of(
                                          dialogContext,
                                        ).pop(
                                          _AlertConfirmResult(
                                            confirmed: true,
                                            reviewerName: reviewerName,
                                          ),
                                        );
                                      }
                                    : null,
                                icon: const Icon(
                                  Icons.done_all_rounded,
                                ),
                                label: const Text('ยืนยัน'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );

                  reviewerController.dispose();

                  if (result?.confirmed != true ||
                      result!.reviewerName.trim().isEmpty ||
                      !mounted) {
                    return;
                  }

                  final String reviewerName = result.reviewerName.trim();

                  setState(() {
                    for (int i = 0; i < _alerts.length; i++) {
                      if (_alerts[i].status == 'ใหม่') {
                        _alerts[i] = _alerts[i].copyWith(
                          status: 'รับทราบแล้ว',
                        );
                      }
                    }

                    _logs.insert(
                      0,
                      _AlertLogRecord(
                        time: 'เมื่อสักครู่',
                        action: 'รับทราบทั้งหมด',
                        target: 'การแจ้งเตือนใหม่',
                        detail: 'เปลี่ยนการแจ้งเตือนใหม่ทั้งหมดเป็นรับทราบแล้ว',
                        by: reviewerName,
                        type: 'success',
                      ),
                    );
                  });

                  _showMessage(
                    'รับทราบการแจ้งเตือนใหม่ทั้งหมดแล้ว',
                  );
                },
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('รับทราบทั้งหมด'),
              ),
            ],
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 14),
                actions,
              ],
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
        value: '$_urgentCount',
        detail: 'ควรดำเนินการก่อน',
        icon: Icons.priority_high_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _AlertSummaryData(
        title: 'กำลังตรวจสอบ',
        value: '$_checkingCount',
        detail: 'มีผู้รับผิดชอบแล้ว',
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
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
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
    const List<_PriorityData> items = [
      _PriorityData(
        title: 'อุปกรณ์และระบบ',
        value: '3 รายการ',
        detail: 'ออฟไลน์ / ภาพขาด / ชุดฝึกยังไม่ผูกห้อง',
        icon: Icons.memory_rounded,
        color: SchoolAdminPalette.red,
      ),
      _PriorityData(
        title: 'ไฟฟ้าและน้ำ',
        value: '2 รายการ',
        detail: 'ค่าการใช้งานสูงกว่าปกติ',
        icon: Icons.energy_savings_leaf_rounded,
        color: SchoolAdminPalette.secondary,
      ),
      _PriorityData(
        title: 'ความปลอดภัย',
        value: '1 รายการ',
        detail: 'ใส่รหัสผ่านผิดเกิน 3 ครั้ง',
        icon: Icons.security_rounded,
        color: Color(0xFF4F6078),
      ),
      _PriorityData(
        title: 'ส่งต่ออัตโนมัติ',
        value: '1 รายการ',
        detail: 'นักเรียนไม่มาเรียน → ครูประจำชั้น',
        icon: Icons.forward_to_inbox_rounded,
        color: SchoolAdminPalette.green,
      ),
    ];

    return _AlertSectionCard(
      title: 'ภาพรวมเรื่องที่ต้องดูวันนี้',
      subtitle: 'แยกตามประเภทเพื่อให้แอดมินเห็นสิ่งสำคัญได้เร็วขึ้น',
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          int columns = 4;
          if (constraints.maxWidth < 1000) columns = 2;
          if (constraints.maxWidth < 560) columns = 1;

          const double spacing = 10;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: items.map((_PriorityData item) {
              return SizedBox(
                width: width,
                child: _PriorityCard(data: item),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return _AlertSectionCard(
      title: 'ค้นหาและกรองการแจ้งเตือน',
      subtitle: 'ค้นหาจากชื่อเหตุการณ์ อุปกรณ์ ห้อง หรือแหล่งข้อมูล',
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
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

          final Widget category = _AlertFilterDropdown(
            label: 'ประเภท',
            value: _selectedCategory,
            items: const [
              'ทุกประเภท',
              'อุปกรณ์',
              'ไฟฟ้า',
              'น้ำ',
              'คุณภาพอากาศ',
              'ความปลอดภัย',
              'นักเรียน',
              'ระบบ',
            ],
            onChanged: (String value) {
              setState(() => _selectedCategory = value);
            },
          );

          final Widget severity = _AlertFilterDropdown(
            label: 'ระดับ',
            value: _selectedSeverity,
            items: const [
              'ทุกระดับ',
              'เร่งด่วน',
              'เฝ้าระวัง',
              'แจ้งเตือน',
            ],
            onChanged: (String value) {
              setState(() => _selectedSeverity = value);
            },
          );

          final Widget status = _AlertFilterDropdown(
            label: 'สถานะ',
            value: _selectedStatus,
            items: const [
              'ทุกสถานะ',
              'ใหม่',
              'กำลังตรวจสอบ',
              'รับทราบแล้ว',
              'ส่งต่อแล้ว',
              'แก้ไขแล้ว',
            ],
            onChanged: (String value) {
              setState(() => _selectedStatus = value);
            },
          );

          final Widget building = _AlertFilterDropdown(
            label: 'อาคาร',
            value: _selectedBuilding,
            items: const [
              'ทุกอาคาร',
              'อาคารเรียน A',
              'อาคารเรียน B',
              'อาคารปฏิบัติการ',
              'อาคารอำนวยการ',
              'ระบบกลาง',
            ],
            onChanged: (String value) {
              setState(() => _selectedBuilding = value);
            },
          );

          final Widget clear = OutlinedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('ล้างตัวกรอง'),
          );

          if (constraints.maxWidth < 950) {
            return Column(
              children: [
                search,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: category),
                    const SizedBox(width: 10),
                    Expanded(child: severity),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: status),
                    const SizedBox(width: 10),
                    Expanded(child: building),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: clear,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 10),
              Expanded(child: category),
              const SizedBox(width: 10),
              Expanded(child: severity),
              const SizedBox(width: 10),
              Expanded(child: status),
              const SizedBox(width: 10),
              Expanded(child: building),
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
      child: alerts.isEmpty
          ? const _AlertEmptyState()
          : LayoutBuilder(
              builder: (
                BuildContext context,
                BoxConstraints constraints,
              ) {
                if (constraints.maxWidth >= 1000) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: SchoolAdminPalette.border,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Table(
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: SchoolAdminPalette.border,
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
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(
                            color: SchoolAdminPalette.primarySoft,
                          ),
                          children: [
                            _AlertTableHeader(text: 'การแจ้งเตือน'),
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
                                    fontSize: 11.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w700,
                                    color: SchoolAdminPalette.textPrimary,
                                  ),
                                ),
                              ),
                              _AlertTableCell(
                                child: Text(
                                  alert.createdAt,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: SchoolAdminPalette.textSecondary,
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
                                  onChecking: () =>
                                      _confirmAndUpdateAlertStatus(
                                    alert,
                                    'กำลังตรวจสอบ',
                                  ),
                                  onResolved: () =>
                                      _confirmAndUpdateAlertStatus(
                                    alert,
                                    'แก้ไขแล้ว',
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  );
                }

                return Column(
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
                        onResolved: () => _confirmAndUpdateAlertStatus(
                          alert,
                          'แก้ไขแล้ว',
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  Widget _buildAutomationRules() {
    return _AlertSectionCard(
      title: 'กฎการแจ้งเตือนอัตโนมัติ',
      subtitle:
          'กำหนดว่าระบบจะส่งเรื่องใดให้ใคร เพื่อให้ผู้รับผิดชอบได้รับข้อมูลตรงหน้าที่',
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          int columns = 2;
          if (constraints.maxWidth < 820) columns = 1;

          const double spacing = 10;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: _rules.map((_AlertRule rule) {
              return SizedBox(
                width: width,
                child: _AlertRuleCard(
                  rule: rule,
                  icon: _iconForType(rule.iconType),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDeliveryOverview() {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        const Widget recipients = _AlertSectionCard(
          title: 'ผู้รับการแจ้งเตือน',
          subtitle: 'สรุปเส้นทางการส่งแจ้งเตือนตามหน้าที่',
          child: Column(
            children: [
              _RecipientRow(
                icon: Icons.co_present_rounded,
                title: 'ครูประจำชั้น',
                detail: 'นักเรียนไม่มาเรียน / เรื่องของห้องที่รับผิดชอบ',
                color: SchoolAdminPalette.primaryDark,
              ),
              SizedBox(height: 9),
              _RecipientRow(
                icon: Icons.apartment_rounded,
                title: 'ครูประจำอาคาร',
                detail: 'อุปกรณ์ ไฟฟ้า น้ำ และคุณภาพอากาศของอาคาร',
                color: SchoolAdminPalette.green,
              ),
              SizedBox(height: 9),
              _RecipientRow(
                icon: Icons.admin_panel_settings_rounded,
                title: 'แอดมินโรงเรียน',
                detail: 'ความปลอดภัย ระบบ และเรื่องที่ต้องติดตามต่อ',
                color: SchoolAdminPalette.secondary,
              ),
            ],
          ),
        );

        const Widget channels = _AlertSectionCard(
          title: 'ช่องทางการแจ้งเตือน',
          subtitle: 'สถานะช่องทางที่ระบบเตรียมไว้',
          child: Column(
            children: [
              _ChannelRow(
                icon: Icons.notifications_rounded,
                title: 'แจ้งเตือนในระบบ',
                detail: 'เปิดใช้งาน',
                enabled: true,
              ),
              SizedBox(height: 9),
              _ChannelRow(
                icon: Icons.email_outlined,
                title: 'อีเมล',
                detail: 'เปิดใช้งานสำหรับเรื่องสำคัญ',
                enabled: true,
              ),
              SizedBox(height: 9),
              _ChannelRow(
                icon: Icons.phone_android_rounded,
                title: 'Push Notification',
                detail: 'เตรียมเชื่อมต่อภายหลัง',
                enabled: false,
              ),
            ],
          ),
        );

        if (constraints.maxWidth < 900) {
          return const Column(
            children: [
              recipients,
              SizedBox(height: 14),
              channels,
            ],
          );
        }

        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: recipients),
            SizedBox(width: 14),
            Expanded(flex: 4, child: channels),
          ],
        );
      },
    );
  }

  Widget _buildLogs() {
    return _AlertSectionCard(
      title: 'Log การแจ้งเตือนล่าสุด',
      subtitle: 'บันทึกการสร้าง เปิดดู เปลี่ยนสถานะ และส่งต่อการแจ้งเตือน',
      child: _logs.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              alignment: Alignment.center,
              child: const Text(
                'ยังไม่มีประวัติการแจ้งเตือน',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            )
          : Column(
              children: _logs.take(6).map((_AlertLogRecord log) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _AlertLogRow(log: log),
                );
              }).toList(),
            ),
    );
  }
}

class _AlertSummaryCard extends StatelessWidget {
  const _AlertSummaryCard({required this.data});

  final _AlertSummaryData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
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
                    _AlertIconBox(
                      icon: data.icon,
                      color: data.color,
                    ),
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
                    _AlertIconBox(
                      icon: data.icon,
                      color: data.color,
                    ),
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
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
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
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({required this.data});

  final _PriorityData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AlertIconBox(
            icon: data.icon,
            color: data.color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  data.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: data.color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.detail,
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
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
  const _AlertTableHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 17,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          color: SchoolAdminPalette.textPrimary,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 13,
      ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        child: Row(
          children: [
            _AlertIconBox(
              icon: icon,
              color: color,
              size: 38,
            ),
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
                _AlertIconBox(
                  icon: icon,
                  color: severityColor,
                ),
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
              _AlertBadge(
                label: alert.severity,
                color: severityColor,
              ),
              _AlertBadge(
                label: alert.status,
                color: statusColor,
              ),
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
          icon: Icon(
            Icons.visibility_outlined,
            size: compact ? 14 : 16,
          ),
          label: const Text('ดู'),
        ),
        OutlinedButton.icon(
          onPressed:
              acknowledged || checking || resolved ? null : onAcknowledge,
          style: smallOutlinedStyle,
          icon: Icon(
            acknowledged ? Icons.check_circle_rounded : Icons.done_rounded,
            size: compact ? 14 : 16,
          ),
          label: Text(
            acknowledged ? 'รับทราบแล้ว' : 'รับทราบ',
          ),
        ),
        OutlinedButton.icon(
          onPressed: checking || resolved ? null : onChecking,
          style: smallOutlinedStyle,
          icon: Icon(
            Icons.manage_search_rounded,
            size: compact ? 14 : 16,
          ),
          label: Text(
            checking ? 'กำลังตรวจสอบ' : 'ตรวจสอบ',
          ),
        ),
        FilledButton.icon(
          onPressed: resolved ? null : onResolved,
          style: smallFilledStyle,
          icon: Icon(
            Icons.check_circle_outline_rounded,
            size: compact ? 14 : 16,
          ),
          label: Text(
            resolved ? 'แก้ไขแล้ว' : 'แก้ไขแล้ว',
          ),
        ),
      ],
    );
  }
}

class _AlertRuleCard extends StatelessWidget {
  const _AlertRuleCard({
    required this.rule,
    required this.icon,
  });

  final _AlertRule rule;
  final IconData icon;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AlertIconBox(
                icon: icon,
                color: SchoolAdminPalette.primaryDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rule.title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
              ),
              Icon(
                rule.enabled
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded,
                size: 36,
                color: rule.enabled
                    ? SchoolAdminPalette.green
                    : SchoolAdminPalette.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RuleInfoRow(
            label: 'เงื่อนไข',
            value: rule.condition,
          ),
          _RuleInfoRow(
            label: 'ส่งถึง',
            value: rule.recipient,
          ),
          _RuleInfoRow(
            label: 'ติดตามต่อ',
            value: rule.escalation,
          ),
        ],
      ),
    );
  }
}

class _RuleInfoRow extends StatelessWidget {
  const _RuleInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: SchoolAdminPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientRow extends StatelessWidget {
  const _RecipientRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          _AlertIconBox(icon: icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
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
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color color =
        enabled ? SchoolAdminPalette.green : SchoolAdminPalette.textMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          _AlertIconBox(icon: icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.schedule_rounded,
            color: color,
          ),
        ],
      ),
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
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
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
                    _AlertIconBox(
                      icon: Icons.history_rounded,
                      color: color,
                    ),
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
          Icon(
            icon,
            size: 19,
            color: SchoolAdminPalette.primaryDark,
          ),
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
        border: Border.all(
          color: color.withAlpha(80),
          width: 1.1,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.48,
      ),
    );
  }
}

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 82),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
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

class _AlertEmptyState extends StatelessWidget {
  const _AlertEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 46,
            color: SchoolAdminPalette.textMuted,
          ),
          SizedBox(height: 10),
          Text(
            'ไม่พบการแจ้งเตือน',
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
    );
  }
}

class _AlertConfirmResult {
  const _AlertConfirmResult({
    required this.confirmed,
    required this.reviewerName,
  });

  final bool confirmed;
  final String reviewerName;
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

class _PriorityData {
  const _PriorityData({
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

class _AlertRule {
  const _AlertRule({
    required this.title,
    required this.condition,
    required this.recipient,
    required this.escalation,
    required this.enabled,
    required this.iconType,
  });

  final String title;
  final String condition;
  final String recipient;
  final String escalation;
  final bool enabled;
  final String iconType;
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

  _AlertRecord copyWith({
    String? status,
  }) {
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
