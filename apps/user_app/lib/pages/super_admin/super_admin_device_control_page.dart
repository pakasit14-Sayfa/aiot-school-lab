import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'models/device_control_models.dart';
import 'theme/app_palette.dart';
import 'widgets/device_control_sections.dart';
import 'widgets/device_control_widgets.dart';

class SuperAdminDeviceControlPage extends StatefulWidget {
  const SuperAdminDeviceControlPage({
    super.key,
    this.onOpenSchools,
    this.onOpenDevices,
    this.loadControlData,
    this.queueDeviceCommand,
    this.createControlApprovalRequest,
    this.decideControlApprovalRequest,
  });

  final VoidCallback? onOpenSchools;
  final VoidCallback? onOpenDevices;

  /// Injectable seams for tests — production leaves these null and uses the
  /// real service (same pattern as school_admin's connection tests).
  final Future<DeviceControlDataModel> Function()? loadControlData;
  final Future<String> Function({
    required String deviceId,
    required Map<String, dynamic> command,
  })?
  queueDeviceCommand;
  final Future<Map<String, dynamic>> Function({
    required String deviceId,
    required String command,
    String? reason,
  })?
  createControlApprovalRequest;
  final Future<Map<String, dynamic>> Function({
    required String requestId,
    required bool approved,
    String? reason,
  })?
  decideControlApprovalRequest;

  @override
  State<SuperAdminDeviceControlPage> createState() => _SuperAdminDeviceControlPageState();
}

typedef DeviceControlPage = SuperAdminDeviceControlPage;

class _SuperAdminDeviceControlPageState extends State<SuperAdminDeviceControlPage> {
  final TextEditingController _searchController = TextEditingController();

  final SchoolAdminPlatformService _service = SchoolAdminPlatformService();

  Timer? _refreshTimer;
  Timer? _realtimeDebounce;
  RealtimeChannel? _realtimeChannel;

  String _selectedSchoolId = 'ALL';
  String _school = 'ทุกโรงเรียน';
  String _building = 'ทุกอาคาร';
  String _room = 'ทุกห้อง';
  String _status = 'ทุกสถานะ';

  final List<SchoolItem> _schools = <SchoolItem>[];
  final List<DeviceItem> _devices = <DeviceItem>[];
  final List<ActionLog> _logs = <ActionLog>[];
  final List<ControlPermission> _permissions = <ControlPermission>[];

  final List<ApprovalItem> _approvals = <ApprovalItem>[];

  String _currentRole = 'viewer';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    _loadControlData();
    _subscribeToSystemChanges();

    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (Timer _) {
      if (!_isSaving) {
        _loadControlData(showLoading: false);
      }
    });
  }

  void _subscribeToSystemChanges() {
    try {
      final SupabaseClient client = Supabase.instance.client;

      _realtimeChannel =
          client
              .channel(
                'developer-device-control-${DateTime.now().microsecondsSinceEpoch}',
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'schools',
                callback: _handleRealtimeChange,
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'devices',
                callback: _handleRealtimeChange,
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'alerts',
                callback: _handleRealtimeChange,
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'device_commands',
                callback: _handleRealtimeChange,
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'control_approval_requests',
                callback: _handleRealtimeChange,
              )
              .subscribe();
    } catch (error) {
      debugPrint('super_admin_device_control_page: realtime subscribe failed: $error');
    }
  }

  void _handleRealtimeChange(PostgresChangePayload payload) {
    _realtimeDebounce?.cancel();

    _realtimeDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || _isSaving) {
        return;
      }

      _loadControlData(showLoading: false);
    });
  }

  Future<void> _loadControlData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final DeviceControlDataModel data =
          await (widget.loadControlData ?? _service.fetchDeviceControlData)();

      if (!mounted) {
        return;
      }

      setState(() {
        _schools
          ..clear()
          ..addAll(data.schools.map(SchoolItem.fromRecord));

        _devices
          ..clear()
          ..addAll(data.devices.map(DeviceItem.fromRecord));

        _logs
          ..clear()
          ..addAll(data.logs.map(ActionLog.fromRecord));

        _permissions
          ..clear()
          ..addAll(data.permissions.map(ControlPermission.fromRecord));

        _approvals
          ..clear()
          ..addAll(data.approvals.map(ApprovalItem.fromRecord));

        _currentRole = data.currentRole;

        if (_selectedSchoolId != 'ALL') {
          SchoolItem? selected;

          for (final SchoolItem item in _schools) {
            if (item.databaseId == _selectedSchoolId) {
              selected = item;
              break;
            }
          }

          if (selected == null) {
            _selectedSchoolId = 'ALL';
            _school = 'ทุกโรงเรียน';
          } else {
            _school = selected.name;
          }
        }

        if (!_buildingOptions.contains(_building)) {
          _building = 'ทุกอาคาร';
        }

        if (!_roomOptions.contains(_room)) {
          _room = 'ทุกห้อง';
        }

        _isLoading = false;
        _loadError = null;
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = '${error.message}\nรหัส: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _realtimeDebounce?.cancel();

    final RealtimeChannel? channel = _realtimeChannel;

    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }

    _searchController.dispose();
    super.dispose();
  }

  List<DeviceItem> get _schoolDevices {
    if (_selectedSchoolId == 'ALL') {
      return _devices;
    }

    return _devices
        .where((DeviceItem item) => item.schoolId == _selectedSchoolId)
        .toList(growable: false);
  }

  int get _onlineCount =>
      _schoolDevices.where((DeviceItem item) => item.online).length;

  int get _offlineCount =>
      _schoolDevices.where((DeviceItem item) => !item.online).length;

  int get _onCount =>
      _schoolDevices
          .where((DeviceItem item) => item.online && item.isOn)
          .length;

  int get _autoCount =>
      _schoolDevices.where((DeviceItem item) => item.autoMode).length;

  bool get _canApproveRequests =>
      <String>{'super_admin', 'school_admin'}.contains(_currentRole);

  List<ApprovalItem> get _visibleApprovals {
    final Iterable<ApprovalItem> filtered =
        _selectedSchoolId == 'ALL'
            ? _approvals
            : _approvals.where(
              (ApprovalItem item) => item.schoolId == _selectedSchoolId,
            );

    return filtered.take(12).toList(growable: false);
  }

  List<String> _unique(Iterable<String> values) {
    final List<String> result = values.toSet().toList()..sort();
    return result;
  }

  List<String> get _schoolOptions => <String>[
    'ทุกโรงเรียน',
    ..._schools.map((SchoolItem item) => item.name),
  ];

  SchoolItem? get _selectedSchoolItem {
    if (_selectedSchoolId == 'ALL') {
      return null;
    }

    for (final SchoolItem item in _schools) {
      if (item.databaseId == _selectedSchoolId) {
        return item;
      }
    }

    return null;
  }

  void _selectAllSchools() {
    setState(() {
      _selectedSchoolId = 'ALL';
      _school = 'ทุกโรงเรียน';
      _building = 'ทุกอาคาร';
      _room = 'ทุกห้อง';
      _status = 'ทุกสถานะ';
    });
  }

  void _selectSchool(SchoolItem school) {
    setState(() {
      _selectedSchoolId = school.databaseId;
      _school = school.name;
      _building = 'ทุกอาคาร';
      _room = 'ทุกห้อง';
      _status = 'ทุกสถานะ';
    });
  }

  void _selectSchoolByName(String schoolName) {
    if (schoolName == 'ทุกโรงเรียน') {
      _selectAllSchools();
      return;
    }

    for (final SchoolItem item in _schools) {
      if (item.name == schoolName) {
        _selectSchool(item);
        return;
      }
    }
  }

  List<String> get _buildingOptions => <String>[
    'ทุกอาคาร',
    ..._unique(
      _devices
          .where(
            (DeviceItem item) =>
                _selectedSchoolId == 'ALL' ||
                item.schoolId == _selectedSchoolId,
          )
          .map((DeviceItem item) => item.building),
    ),
  ];

  List<String> get _roomOptions => <String>[
    'ทุกห้อง',
    ..._unique(
      _devices
          .where(
            (DeviceItem item) =>
                (_selectedSchoolId == 'ALL' ||
                    item.schoolId == _selectedSchoolId) &&
                (_building == 'ทุกอาคาร' || item.building == _building),
          )
          .map((DeviceItem item) => item.room),
    ),
  ];

  List<DeviceItem> get _filteredDevices {
    final String query = _searchController.text.trim().toLowerCase();

    return _devices.where((DeviceItem item) {
      final bool matchesText =
          query.isEmpty ||
          item.id.toLowerCase().contains(query) ||
          item.name.toLowerCase().contains(query) ||
          item.school.toLowerCase().contains(query) ||
          item.building.toLowerCase().contains(query) ||
          item.room.toLowerCase().contains(query);

      final bool matchesSchool =
          _selectedSchoolId == 'ALL' || item.schoolId == _selectedSchoolId;
      final bool matchesBuilding =
          _building == 'ทุกอาคาร' || item.building == _building;
      final bool matchesRoom = _room == 'ทุกห้อง' || item.room == _room;

      bool matchesStatus = true;
      if (_status == 'ออนไลน์') {
        matchesStatus = item.online;
      } else if (_status == 'ออฟไลน์') {
        matchesStatus = !item.online;
      } else if (_status == 'เปิดอยู่') {
        matchesStatus = item.online && item.isOn;
      } else if (_status == 'ปิดอยู่') {
        matchesStatus = item.online && !item.isOn;
      }

      return matchesText &&
          matchesSchool &&
          matchesBuilding &&
          matchesRoom &&
          matchesStatus;
    }).toList();
  }

  // Same reasoning as SuperAdminSchoolsPage: this page has no `embedded`
  // toggle, is placed inside the desktop sidebar shell (Material ancestor
  // provided there) but also pushed as a standalone mobile route from
  // SuperAdminHubPage, which provides none — the DropdownButtonFormField
  // widgets in this page's filter/permission UI throw
  // `debugCheckHasMaterial` without a Scaffold ancestor. A bare Scaffold
  // fixes it without changing the page's look.
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading && _devices.isEmpty) {
      return const ColoredBox(
        color: AppPalette.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(color: AppPalette.deepBlue),
              SizedBox(height: 14),
              Text(
                'กำลังโหลดศูนย์ควบคุมจาก Supabase...',
                style: TextStyle(color: AppPalette.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null && _devices.isEmpty) {
      return ColoredBox(
        color: AppPalette.background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: deviceControlCardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: AppPalette.carnivalRed,
                    size: 54,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'โหลดข้อมูลควบคุมไม่สำเร็จ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppPalette.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppPalette.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => _loadControlData(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('ลองใหม่'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final List<DeviceItem> filtered = _filteredDevices;

    return ColoredBox(
      color: AppPalette.background,
      child: Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: () => _loadControlData(showLoading: false),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                _buildHero(),
                const SizedBox(height: 18),
                _buildSchoolSelector(),
                const SizedBox(height: 18),
                _buildSummary(),
                const SizedBox(height: 18),
                _buildApprovalRequestsPanel(),
                const SizedBox(height: 18),
                _buildPriority(),
                const SizedBox(height: 18),
                _buildDevicePanel(filtered),
                const SizedBox(height: 18),
                _buildBottomPanels(),
              ],
            ),
          ),
          if (_isSaving)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.10),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppPalette.deepBlue,
                            ),
                          ),
                          SizedBox(width: 14),
                          Text(
                            'กำลังส่งคำสั่ง...',
                            style: TextStyle(
                              color: AppPalette.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSchoolSelector() {
    final SchoolItem? selected = _selectedSchoolItem;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppPalette.softBeige),
        boxShadow: deviceControlCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 760;

              final Widget title = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ค้นหาโรงเรียน ตำแหน่ง และอุปกรณ์',
                    style: TextStyle(
                      color: AppPalette.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'เลือกโรงเรียน อาคาร ห้อง และสถานะ '
                    'จากข้อมูลที่เพิ่มไว้ในระบบ',
                    style: TextStyle(
                      color: AppPalette.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              );

              final Widget actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: widget.onOpenSchools,
                    icon: const Icon(Icons.apartment_rounded, size: 18),
                    label: const Text('จัดการโรงเรียน'),
                  ),
                  FilledButton.icon(
                    onPressed: widget.onOpenDevices,
                    icon: const Icon(Icons.add_box_rounded, size: 18),
                    label: const Text('เพิ่ม/ดูอุปกรณ์'),
                  ),
                  IconButton(
                    tooltip: 'โหลดข้อมูลล่าสุด',
                    onPressed: () => _loadControlData(showLoading: false),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    title,
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: title),
                  const SizedBox(width: 16),
                  actions,
                ],
              );
            },
          ),
          const SizedBox(height: 15),
          if (_schools.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppPalette.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppPalette.softBeige),
              ),
              child: Column(
                children: <Widget>[
                  const Icon(
                    Icons.apartment_outlined,
                    color: AppPalette.deepBlue,
                    size: 34,
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'ยังไม่มีโรงเรียนในระบบ',
                    style: TextStyle(
                      color: AppPalette.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'เพิ่มโรงเรียนจากหน้าจัดการโรงเรียน '
                    'แล้วกลับมากดโหลดข้อมูลล่าสุด',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppPalette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenSchools,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('ไปหน้าเพิ่มโรงเรียน'),
                  ),
                ],
              ),
            )
          else ...<Widget>[
            _buildDeviceFiltersContent(),
            if (selected != null) ...<Widget>[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppPalette.deepBlue.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppPalette.deepBlue.withValues(alpha: 0.14),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool compact = constraints.maxWidth < 650;

                    final Widget info = Row(
                      children: <Widget>[
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppPalette.deepBlue.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: AppPalette.deepBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                selected.name,
                                style: const TextStyle(
                                  color: AppPalette.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${selected.schoolCode} • '
                                '${selected.province} • '
                                '${selected.packageName}',
                                style: const TextStyle(
                                  color: AppPalette.textSecondary,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final Widget counts = Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        deviceControlSchoolMiniStat(
                          '${selected.totalDevices}',
                          'อุปกรณ์',
                          Icons.memory_rounded,
                        ),
                        deviceControlSchoolMiniStat(
                          '${selected.onlineDevices}',
                          'ออนไลน์',
                          Icons.wifi_tethering_rounded,
                        ),
                        deviceControlSchoolMiniStat(
                          '${selected.openAlerts}',
                          'แจ้งเตือน',
                          Icons.notifications_active_rounded,
                        ),
                      ],
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          info,
                          const SizedBox(height: 12),
                          counts,
                        ],
                      );
                    }

                    return Row(
                      children: <Widget>[
                        Expanded(child: info),
                        const SizedBox(width: 14),
                        counts,
                      ],
                    );
                  },
                ),
              ),
              if (selected.totalDevices == 0) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppPalette.circusYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppPalette.deepBlue,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'โรงเรียนนี้ยังไม่มีอุปกรณ์ '
                          'จึงแสดงค่าควบคุมเป็น 0',
                          style: TextStyle(
                            color: AppPalette.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onOpenDevices,
                        child: const Text('เพิ่มอุปกรณ์'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppPalette.deepBlue, Color(0xFF1676B5)],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppPalette.deepBlue.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool mobile = constraints.maxWidth < 760;

          final Widget text = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.circusYellow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'ศูนย์ควบคุมอุปกรณ์',
                  style: TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedSchoolId == 'ALL'
                    ? 'ควบคุมอุปกรณ์\nจากส่วนกลาง'
                    : 'ควบคุมอุปกรณ์\n$_school',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: mobile ? 25 : 34,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedSchoolId == 'ALL'
                    ? 'เลือกโรงเรียนด้านบนเพื่อดูอุปกรณ์ อาคาร ห้อง '
                        'และคำขออนุมัติของโรงเรียนนั้น'
                    : 'ข้อมูลเชื่อมกับหน้าโรงเรียนและหน้าอุปกรณ์โดยตรง '
                        'เมื่อเพิ่มหรือแก้ไขข้อมูลแล้วกดรีเฟรชเพื่อดูค่าล่าสุด',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontSize: mobile ? 12 : 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _status = 'ออฟไลน์';
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.circusYellow,
                      foregroundColor: AppPalette.textPrimary,
                    ),
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: Text('ตรวจสอบออฟไลน์ $_offlineCount เครื่อง'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _emergencyStop,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    icon: const Icon(Icons.power_settings_new_rounded),
                    label: const Text('หยุดฉุกเฉิน'),
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
                  color: Colors.black.withValues(alpha: 0.08),
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
                      child: deviceControlMetric(
                        Icons.wifi_tethering_rounded,
                        '$_onlineCount',
                        'ออนไลน์',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: deviceControlMetric(
                        Icons.power_rounded,
                        '$_onCount',
                        'กำลังเปิด',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: deviceControlMetric(
                        Icons.auto_mode_rounded,
                        '$_autoCount',
                        'อัตโนมัติ',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: deviceControlMetric(
                        Icons.portable_wifi_off_rounded,
                        '$_offlineCount',
                        'ออฟไลน์',
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
              children: <Widget>[text, const SizedBox(height: 18), metrics],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: text),
              const SizedBox(width: 24),
              metrics,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 1100 ? 4 : 2;
        const double gap = 12;
        final double width =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        final List<Widget> cards = <Widget>[
          deviceControlSummaryCard(
            Icons.devices_rounded,
            'อุปกรณ์ทั้งหมด',
            '${_devices.length}',
            'ลงทะเบียนในระบบควบคุม',
            AppPalette.deepBlue,
          ),
          deviceControlSummaryCard(
            Icons.toggle_on_rounded,
            'กำลังเปิด',
            '$_onCount',
            'เปิดอยู่และเชื่อมต่อปกติ',
            AppPalette.gardenGreen,
          ),
          deviceControlSummaryCard(
            Icons.auto_mode_rounded,
            'โหมดอัตโนมัติ',
            '$_autoCount',
            'ทำงานตามเงื่อนไขระบบ',
            AppPalette.circusYellow,
          ),
          deviceControlSummaryCard(
            Icons.error_outline_rounded,
            'ต้องตรวจสอบ',
            '$_offlineCount',
            'อุปกรณ์ขาดการเชื่อมต่อ',
            AppPalette.carnivalRed,
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
              cards
                  .map((Widget card) => SizedBox(width: width, child: card))
                  .toList(),
        );
      },
    );
  }

  Widget _buildUnifiedScopeControls() {
    final List<ProtectedScope> scopes = <ProtectedScope>[
      ProtectedScope(
        code: 'main',
        title: 'อุปกรณ์หลัก',
        subtitle: 'บอร์ดควบคุมและ Gateway ส่วนกลาง',
        icon: Icons.hub_rounded,
        color: AppPalette.deepBlue,
      ),
      ProtectedScope(
        code: 'electricity',
        title: 'ระบบไฟฟ้า',
        subtitle: 'แหล่งจ่ายไฟและรีเลย์ไฟฟ้า',
        icon: Icons.electric_bolt_rounded,
        color: AppPalette.circusYellow,
      ),
      ProtectedScope(
        code: 'water',
        title: 'ระบบน้ำ',
        subtitle: 'ปั๊มน้ำ วาล์ว และอุปกรณ์น้ำ',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF1676B5),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 650;

            final Widget title = Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppPalette.deepBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppPalette.deepBlue,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'ควบคุมแบบรวม',
                        style: TextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'เปิด–ปิดเป็นกลุ่ม หรือควบคุมรายเครื่องได้ในกล่องเดียว',
                        style: TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final Widget approvalBadge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppPalette.circusYellow.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.lock_rounded,
                    size: 15,
                    color: AppPalette.deepBlue,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'ต้องให้แอดมินอนุมัติ',
                    style: TextStyle(
                      color: AppPalette.deepBlue,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  title,
                  const SizedBox(height: 10),
                  approvalBadge,
                ],
              );
            }

            return Row(
              children: <Widget>[
                Expanded(child: title),
                const SizedBox(width: 12),
                approvalBadge,
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppPalette.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppPalette.softBeige),
          ),
          child: Text(
            _selectedSchoolId == 'ALL'
                ? 'กรุณาเลือกโรงเรียนก่อนส่งคำขอเปิด–ปิด '
                    'จากนั้นสามารถเลือกสั่งทั้งกลุ่มหรือรายเครื่องได้'
                : 'คำขอเปิด–ปิดจะส่งให้แอดมินตรวจสอบ '
                    'และยืนยันด้วยรหัสผ่านก่อนสร้างคำสั่งไปยังอุปกรณ์',
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columns =
                constraints.maxWidth >= 1050
                    ? 3
                    : constraints.maxWidth >= 680
                    ? 2
                    : 1;

            const double gap = 12;
            final double width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: scopes
                  .map((ProtectedScope scope) {
                    final List<DeviceItem> targets = _devicesForScope(
                      scope.code,
                    );

                    final int onCount =
                        targets.where((DeviceItem item) => item.isOn).length;

                    final int onlineCount =
                        targets.where((DeviceItem item) => item.online).length;

                    final bool canRequest =
                        _selectedSchoolId != 'ALL' && targets.isNotEmpty;

                    return SizedBox(
                      width: width,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: scope.color.withValues(alpha: 0.035),
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(
                            color: scope.color.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: scope.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    scope.icon,
                                    color: scope.color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        scope.title,
                                        style: const TextStyle(
                                          color: AppPalette.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        scope.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppPalette.textSecondary,
                                          fontSize: 9.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${targets.length} อุปกรณ์ • '
                              '$onlineCount ออนไลน์ • '
                              '$onCount เปิดอยู่',
                              style: const TextStyle(
                                color: AppPalette.textPrimary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed:
                                        canRequest
                                            ? () => _requestProtectedControl(
                                              scope: scope.code,
                                              scopeLabel: scope.title,
                                              turnOn: true,
                                              devices: targets,
                                            )
                                            : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppPalette.gardenGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.power_settings_new_rounded,
                                      size: 17,
                                    ),
                                    label: const Text('ขอเปิด'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        canRequest
                                            ? () => _requestProtectedControl(
                                              scope: scope.code,
                                              scopeLabel: scope.title,
                                              turnOn: false,
                                              devices: targets,
                                            )
                                            : null,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppPalette.carnivalRed,
                                      side: const BorderSide(
                                        color: AppPalette.carnivalRed,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.power_off_rounded,
                                      size: 17,
                                    ),
                                    label: const Text('ขอปิด'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }

  Widget _buildApprovalRequestsPanel() {
    final List<ApprovalItem> approvals = _visibleApprovals;

    return deviceControlPanel(
      title: 'คำขออนุมัติการเปิด–ปิด',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppPalette.deepBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${approvals.where((ApprovalItem item) => item.status == 'pending').length} รออนุมัติ',
              style: const TextStyle(
                color: AppPalette.deepBlue,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'รีเฟรชคำขอ',
            onPressed: () => _loadControlData(showLoading: false),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      child:
          approvals.isEmpty
              ? deviceControlEmpty(
                Icons.approval_outlined,
                'ยังไม่มีคำขออนุมัติ',
                'เมื่อผู้ใช้ขอเปิดหรือปิดระบบ คำขอจะปรากฏที่นี่',
              )
              : Column(
                children: approvals
                    .map(
                      (ApprovalItem item) => DeviceControlApprovalTile(
                        item: item,
                        canDecide:
                            _canApproveRequests && item.status == 'pending',
                        onReject: _rejectApproval,
                        onApprove: _approveWithPassword,
                      ),
                    )
                    .toList(growable: false),
              ),
    );
  }

  List<DeviceItem> _devicesForScope(String scope) {
    if (_selectedSchoolId == 'ALL') {
      return <DeviceItem>[];
    }

    return _devices
        .where((DeviceItem item) {
          if (item.schoolId != _selectedSchoolId) {
            return false;
          }

          return _scopeForDevice(item) == scope;
        })
        .toList(growable: false);
  }

  String _scopeForDevice(DeviceItem item) {
    final String explicit =
        item.metadata['control_group']?.toString().trim().toLowerCase() ?? '';

    if (<String>{'main', 'electricity', 'water'}.contains(explicit)) {
      return explicit;
    }

    if (item.categoryCode == 'WTR') {
      return 'water';
    }

    if (<String>{'PWR', 'RLY'}.contains(item.categoryCode)) {
      return 'electricity';
    }

    return 'main';
  }

  String _scopeLabel(String scope) {
    switch (scope) {
      case 'water':
        return 'ระบบน้ำ';
      case 'electricity':
        return 'ระบบไฟฟ้า';
      case 'main':
      default:
        return 'อุปกรณ์หลัก';
    }
  }

  Future<void> _requestProtectedControl({
    required String scope,
    required String scopeLabel,
    required bool turnOn,
    required List<DeviceItem> devices,
    String? customTitle,
  }) async {
    if (_selectedSchoolId == 'ALL') {
      _message('กรุณาเลือกโรงเรียนก่อนส่งคำขอ');
      return;
    }

    if (devices.isEmpty) {
      _message('ไม่พบอุปกรณ์ในกลุ่ม $scopeLabel');
      return;
    }

    final TextEditingController reasonController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            turnOn ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
            color: turnOn ? AppPalette.gardenGreen : AppPalette.carnivalRed,
            size: 38,
          ),
          title: Text(
            customTitle ?? 'ส่งคำขอ${turnOn ? 'เปิด' : 'ปิด'} $scopeLabel',
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'โรงเรียน: $_school\n'
                  'จำนวนอุปกรณ์: ${devices.length} เครื่อง\n\n'
                  'ระบบจะยังไม่ส่งคำสั่งไปยังอุปกรณ์ '
                  'จนกว่าแอดมินจะตรวจสอบและยืนยันด้วยรหัสผ่านของตนเอง',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'เหตุผลหรือรายละเอียดเพิ่มเติม',
                    hintText: 'เช่น เปิดระบบน้ำเพื่อทดสอบประจำวัน',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.send_rounded),
              label: const Text('ส่งให้แอดมินอนุมัติ'),
            ),
          ],
        );
      },
    );

    final String reason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      for (final item in devices) {
        await (widget.createControlApprovalRequest ??
            _service.createControlApprovalRequest)(
          deviceId: item.databaseId,
          command: turnOn ? 'power_on' : 'power_off',
          reason: reason.isNotEmpty ? reason : 'Scope: $scope',
        );
      }

      await _loadControlData(showLoading: false);

      if (!mounted) {
        return;
      }

      _message(
        'ส่งคำขอ${turnOn ? 'เปิด' : 'ปิด'} '
        '$scopeLabel ให้แอดมินแล้ว',
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      _message('ส่งคำขอไม่สำเร็จ: ${error.message}');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _message('ส่งคำขอไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// RedTeam fix (2026-08-31): this dialog used to have a password field
  /// with a caption claiming the password would be "sent to Supabase
  /// Auth for verification" — the app doesn't use Supabase Auth at all
  /// (custom p_token session system per CLAUDE.md), and the field was
  /// only ever checked for non-emptiness, so any single character
  /// approved a real device-control action. Removed the false claim
  /// entirely rather than build a new re-auth RPC for this pass — this
  /// is now an honest plain confirmation, not fake security theater.
  Future<void> _approveWithPassword(ApprovalItem item) async {
    final bool? approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.admin_panel_settings_rounded,
            color: AppPalette.deepBlue,
            size: 42,
          ),
          title: const Text('ยืนยันการอนุมัติ'),
          content: SizedBox(
            width: 440,
            child: Text(
              '${item.turnOn ? 'เปิด' : 'ปิด'} '
              '${item.scopeLabel}\n'
              '${item.schoolName} • '
              '${item.targetCount} อุปกรณ์\n\n'
              'คุณแน่ใจหรือไม่ที่จะอนุมัติคำสั่งนี้?',
              textAlign: TextAlign.center,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.verified_rounded),
              label: const Text('อนุมัติคำสั่ง'),
            ),
          ],
        );
      },
    );

    if (approved != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await (widget.decideControlApprovalRequest ?? _service.decideControlApprovalRequest)(
        requestId: item.databaseId,
        approved: true,
      );

      await _loadControlData(showLoading: false);

      if (!mounted) {
        return;
      }

      _message(
        'อนุมัติคำขอแล้ว ระบบสร้างคำสั่ง pending '
        'ให้ MiniPC ดำเนินการต่อ',
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      _message('อนุมัติไม่สำเร็จ: ${error.message}');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _message('อนุมัติไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _rejectApproval(ApprovalItem item) async {
    final TextEditingController reasonController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ไม่อนุมัติคำขอ'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'เหตุผลที่ไม่อนุมัติ',
              prefixIcon: Icon(Icons.comment_outlined),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.carnivalRed,
              ),
              child: const Text('ยืนยันไม่อนุมัติ'),
            ),
          ],
        );
      },
    );

    final String reason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await (widget.decideControlApprovalRequest ?? _service.decideControlApprovalRequest)(
        requestId: item.databaseId,
        approved: false,
        reason: reason,
      );

      await _loadControlData(showLoading: false);

      if (!mounted) {
        return;
      }

      _message('บันทึกการไม่อนุมัติแล้ว');
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      _message('บันทึกไม่สำเร็จ: ${error.message}');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _message('บันทึกไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildPriority() {
    final List<DeviceItem> offline =
        _devices.where((DeviceItem item) => !item.online).toList();

    return deviceControlPanel(
      title: 'รายการที่ควรจัดการก่อน',
      trailing: deviceControlBadge(
        '${offline.length} รายการ',
        offline.isEmpty ? AppPalette.gardenGreen : AppPalette.carnivalRed,
      ),
      child:
          offline.isEmpty
              ? deviceControlEmpty(
                Icons.task_alt_rounded,
                'ไม่มีอุปกรณ์ที่ต้องตรวจสอบ',
                'อุปกรณ์ทั้งหมดเชื่อมต่อและทำงานได้ตามปกติ',
              )
              : Column(
                children: <Widget>[
                  for (
                    int index = 0;
                    index < offline.length;
                    index++
                  ) ...<Widget>[
                    InkWell(
                      onTap: () => _showDetails(offline[index]),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppPalette.carnivalRed.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.portable_wifi_off_rounded,
                                color: AppPalette.carnivalRed,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    offline[index].name,
                                    style: const TextStyle(
                                      color: AppPalette.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${offline[index].school} • '
                                    '${offline[index].building} • '
                                    '${offline[index].room}',
                                    style: const TextStyle(
                                      color: AppPalette.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    offline[index].updated,
                                    style: const TextStyle(
                                      color: AppPalette.carnivalRed,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppPalette.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index < offline.length - 1) const Divider(height: 24),
                  ],
                ],
              ),
    );
  }

  Widget _buildDeviceFiltersContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'ค้นหาชื่อ รหัส โรงเรียน อาคาร หรือห้อง',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'ล้างคำค้นหาและตัวกรองทั้งหมด',
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded),
            ),
          ),
        ),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columns =
                constraints.maxWidth >= 900
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
                  child: deviceControlDropdown(
                    'โรงเรียน',
                    Icons.apartment_rounded,
                    _schoolOptions.contains(_school) ? _school : 'ทุกโรงเรียน',
                    _schoolOptions,
                    _selectSchoolByName,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: deviceControlDropdown(
                    'อาคาร',
                    Icons.location_city_rounded,
                    _buildingOptions.contains(_building)
                        ? _building
                        : 'ทุกอาคาร',
                    _buildingOptions,
                    (String value) {
                      setState(() {
                        _building = value;
                        _room = 'ทุกห้อง';
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: width,
                  child: deviceControlDropdown(
                    'ห้อง',
                    Icons.meeting_room_rounded,
                    _roomOptions.contains(_room) ? _room : 'ทุกห้อง',
                    _roomOptions,
                    (String value) {
                      setState(() {
                        _room = value;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: width,
                  child: deviceControlDropdown(
                    'สถานะ',
                    Icons.filter_alt_rounded,
                    _status,
                    const <String>[
                      'ทุกสถานะ',
                      'ออนไลน์',
                      'ออฟไลน์',
                      'เปิดอยู่',
                      'ปิดอยู่',
                    ],
                    (String value) {
                      setState(() {
                        _status = value;
                      });
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _selectedSchoolId = 'ALL';
      _school = 'ทุกโรงเรียน';
      _building = 'ทุกอาคาร';
      _room = 'ทุกห้อง';
      _status = 'ทุกสถานะ';
    });
  }

  Widget _buildDevicePanel(List<DeviceItem> filtered) {
    return deviceControlPanel(
      title: 'ควบคุมอุปกรณ์',
      trailing: Text(
        'พบ ${filtered.length} อุปกรณ์',
        style: const TextStyle(
          color: AppPalette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildUnifiedScopeControls(),
          const SizedBox(height: 22),
          const Divider(height: 1, color: AppPalette.softBeige),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 600;

              final Widget title = const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ควบคุมรายเครื่อง',
                    style: TextStyle(
                      color: AppPalette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'เปลี่ยนโหมด เปิด–ปิด และดูรายละเอียดของแต่ละอุปกรณ์',
                    style: TextStyle(
                      color: AppPalette.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              );

              final Widget count = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.deepBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${filtered.length} รายการ',
                  style: const TextStyle(
                    color: AppPalette.deepBlue,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[title, const SizedBox(height: 9), count],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  count,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            deviceControlEmpty(
              Icons.search_off_rounded,
              'ไม่พบอุปกรณ์',
              _selectedSchoolId == 'ALL'
                  ? 'เลือกโรงเรียนหรือเปลี่ยนตัวกรองเพื่อดูอุปกรณ์'
                  : 'โรงเรียนที่เลือกยังไม่มีอุปกรณ์ '
                      'หรือไม่ตรงกับตัวกรอง',
            )
          else
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = constraints.maxWidth >= 1050 ? 2 : 1;

                const double gap = 14;
                final double width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: filtered
                      .map(
                        (DeviceItem item) => SizedBox(
                          width: width,
                          child: DeviceControlDeviceCard(
                            item: item,
                            onShowDetails: _showDetails,
                            onChangeMode: _changeMode,
                            onToggle: _confirmToggle,
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
        ],
      ),
    );
  }


  Widget _buildBottomPanels() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget permission = deviceControlPanel(
          title: 'สิทธิ์ควบคุมอุปกรณ์',
          trailing: IconButton(
            tooltip: 'เพิ่มสิทธิ์',
            onPressed: _addPermission,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
          child:
              _permissions.isEmpty
                  ? deviceControlEmpty(
                    Icons.manage_accounts_outlined,
                    'ยังไม่มีผู้ใช้ที่ควบคุมอุปกรณ์',
                    'เพิ่มสิทธิ์ให้บัญชีที่ลงทะเบียนใน Supabase',
                  )
                  : Column(
                    children: <Widget>[
                      for (
                        int index = 0;
                        index < _permissions.length;
                        index++
                      ) ...<Widget>[
                        deviceControlPermissionRow(
                          _permissions[index].email,
                          _permissions[index].detail,
                          _permissions[index].color,
                        ),
                        if (index < _permissions.length - 1)
                          const Divider(height: 24),
                      ],
                    ],
                  ),
        );

        final Widget logs = deviceControlPanel(
          title: 'ประวัติคำสั่งล่าสุด',
          child:
              _logs.isEmpty
                  ? deviceControlEmpty(
                    Icons.history_rounded,
                    'ยังไม่มีประวัติคำสั่ง',
                    'คำสั่งเปิด–ปิดและเปลี่ยนโหมดจะแสดงที่นี่',
                  )
                  : Column(
                    children: <Widget>[
                      for (
                        int index = 0;
                        index < _logs.length;
                        index++
                      ) ...<Widget>[
                        deviceControlLogRow(_logs[index]),
                        if (index < _logs.length - 1) const Divider(height: 24),
                      ],
                    ],
                  ),
        );

        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: permission),
              const SizedBox(width: 14),
              Expanded(child: logs),
            ],
          );
        }

        return Column(
          children: <Widget>[permission, const SizedBox(height: 14), logs],
        );
      },
    );
  }

  Future<void> _confirmToggle(DeviceItem item, bool value) async {
    final String scope = _scopeForDevice(item);

    await _requestProtectedControl(
      scope: scope,
      scopeLabel: _scopeLabel(scope),
      turnOn: value,
      devices: <DeviceItem>[item],
      customTitle: '${value ? 'เปิด' : 'ปิด'} ${item.name}',
    );
  }

  Future<void> _changeMode(DeviceItem item, bool autoMode) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await (widget.queueDeviceCommand ?? _service.queueDeviceCommand)(
        deviceId: item.databaseId,
        command: <String, dynamic>{
          'action': 'set_mode',
          'mode': autoMode ? 'auto' : 'manual',
        },
      );

      await _loadControlData(showLoading: false);

      if (!mounted) {
        return;
      }

      _message(
        'ส่งคำสั่งเปลี่ยน ${item.name} เป็นโหมด '
        '${autoMode ? 'อัตโนมัติ' : 'ควบคุมเอง'} แล้ว',
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      _message('เปลี่ยนโหมดไม่สำเร็จ: ${error.message}');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _message('เปลี่ยนโหมดไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _emergencyStop() async {
    final List<DeviceItem> targets = _devices
        .where((DeviceItem item) => item.online && item.isOn)
        .toList(growable: false);

    if (targets.isEmpty) {
      _message('ไม่มีอุปกรณ์ออนไลน์ที่กำลังเปิดอยู่');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppPalette.carnivalRed,
            size: 42,
          ),
          title: const Text('หยุดอุปกรณ์ฉุกเฉิน'),
          content: Text(
            'ระบบจะส่งคำสั่งปิดอุปกรณ์ที่กำลังเปิดและออนไลน์ '
            '${targets.length} เครื่อง\n'
            'ควรใช้เมื่อเกิดเหตุฉุกเฉินเท่านั้น',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.carnivalRed,
              ),
              child: const Text('ยืนยันหยุดทั้งหมด'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      for (final item in targets) {
        await (widget.queueDeviceCommand ?? _service.queueDeviceCommand)(
          deviceId: item.databaseId,
          command: const <String, dynamic>{
            'action': 'emergency_stop',
          },
        );
      }

      await _loadControlData(showLoading: false);

      if (!mounted) {
        return;
      }

      _message('ส่งคำสั่งหยุดฉุกเฉิน ${targets.length} เครื่องแล้ว');
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      _message('หยุดฉุกเฉินไม่สำเร็จ: ${error.message}');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _message('หยุดฉุกเฉินไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _addPermission() async {
    final TextEditingController emailController = TextEditingController();

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('เพิ่มสิทธิ์ควบคุม'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'บัญชีต้องมีอยู่แล้วในระบบ การกดยืนยันจะให้สิทธิ์ '
                '"ผู้ดูแลโรงเรียน (School Admin)" แก่บัญชีนี้ — '
                'สิทธิ์เต็มระดับโรงเรียน ไม่ใช่สิทธิ์จำกัดเฉพาะอุปกรณ์',
                style: TextStyle(color: AppPalette.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'อีเมลที่ลงทะเบียน',
                  prefixIcon: Icon(Icons.email_rounded),
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
              onPressed: () {
                final String email = emailController.text.trim();

                if (!email.contains('@') || !email.contains('.')) {
                  _message('กรุณากรอกอีเมลให้ถูกต้อง');
                  return;
                }

                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('ตั้งเป็นผู้ดูแลโรงเรียน (School Admin)'),
            ),
          ],
        );
      },
    );

    final String email = emailController.text.trim();

    emailController.dispose();

    if (saved != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final users = await UserAdminService.getAllUsers();
      final target = users.cast<UserModel?>().firstWhere(
            (u) => u?.email.toLowerCase() == email.toLowerCase(),
            orElse: () => null,
          );
      if (target != null) {
        await UserAdminService.addSecondaryRole(uid: target.uid, role: UserRole.schoolAdmin);
      }
      final bool updated = target != null;

      await _loadControlData(showLoading: false);

      if (!mounted) {
        return;
      }

      _message(
        updated
            ? 'ตั้ง $email เป็นผู้ดูแลโรงเรียน (School Admin) แล้ว'
            : 'ไม่พบบัญชี $email ในระบบ',
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      _message('เพิ่มสิทธิ์ไม่สำเร็จ: ${error.message}');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _message('เพิ่มสิทธิ์ไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showDetails(DeviceItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppPalette.softBeige,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: AppPalette.deepBlue.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(item.icon, color: AppPalette.deepBlue),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: AppPalette.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.id} • ${item.type}',
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
                const SizedBox(height: 18),
                deviceControlDetailRow('โรงเรียน', item.school),
                deviceControlDetailRow('อาคาร', item.building),
                deviceControlDetailRow('ห้อง', item.room),
                deviceControlDetailRow('สถานะ', item.online ? 'ออนไลน์' : 'ออฟไลน์'),
                deviceControlDetailRow('ค่าปัจจุบัน', item.reading),
                deviceControlDetailRow('อัปเดตล่าสุด', item.updated),
              ],
            ),
          ),
        );
      },
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

}
