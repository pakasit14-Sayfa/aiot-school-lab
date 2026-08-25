import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/app_palette.dart';

class SuperAdminDeviceControlPage extends StatefulWidget {
  const SuperAdminDeviceControlPage({super.key, this.onOpenSchools, this.onOpenDevices});

  final VoidCallback? onOpenSchools;
  final VoidCallback? onOpenDevices;

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

  final List<_SchoolItem> _schools = <_SchoolItem>[];
  final List<_DeviceItem> _devices = <_DeviceItem>[];
  final List<_ActionLog> _logs = <_ActionLog>[];
  final List<_ControlPermission> _permissions = <_ControlPermission>[];

  final List<_ApprovalItem> _approvals = <_ApprovalItem>[];

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
    } catch (_) {}
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
      final DeviceControlDataModel data = await _service.fetchDeviceControlData();

      if (!mounted) {
        return;
      }

      setState(() {
        _schools
          ..clear()
          ..addAll(data.schools.map(_SchoolItem.fromRecord));

        _devices
          ..clear()
          ..addAll(data.devices.map(_DeviceItem.fromRecord));

        _logs
          ..clear()
          ..addAll(data.logs.map(_ActionLog.fromRecord));

        _permissions
          ..clear()
          ..addAll(data.permissions.map(_ControlPermission.fromRecord));

        _approvals
          ..clear()
          ..addAll(data.approvals.map(_ApprovalItem.fromRecord));

        _currentRole = data.currentRole;

        if (_selectedSchoolId != 'ALL') {
          _SchoolItem? selected;

          for (final _SchoolItem item in _schools) {
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

  List<_DeviceItem> get _schoolDevices {
    if (_selectedSchoolId == 'ALL') {
      return _devices;
    }

    return _devices
        .where((_DeviceItem item) => item.schoolId == _selectedSchoolId)
        .toList(growable: false);
  }

  int get _onlineCount =>
      _schoolDevices.where((_DeviceItem item) => item.online).length;

  int get _offlineCount =>
      _schoolDevices.where((_DeviceItem item) => !item.online).length;

  int get _onCount =>
      _schoolDevices
          .where((_DeviceItem item) => item.online && item.isOn)
          .length;

  int get _autoCount =>
      _schoolDevices.where((_DeviceItem item) => item.autoMode).length;

  bool get _canApproveRequests =>
      <String>{'super_admin', 'school_admin'}.contains(_currentRole);

  List<_ApprovalItem> get _visibleApprovals {
    final Iterable<_ApprovalItem> filtered =
        _selectedSchoolId == 'ALL'
            ? _approvals
            : _approvals.where(
              (_ApprovalItem item) => item.schoolId == _selectedSchoolId,
            );

    return filtered.take(12).toList(growable: false);
  }

  List<String> _unique(Iterable<String> values) {
    final List<String> result = values.toSet().toList()..sort();
    return result;
  }

  List<String> get _schoolOptions => <String>[
    'ทุกโรงเรียน',
    ..._schools.map((_SchoolItem item) => item.name),
  ];

  _SchoolItem? get _selectedSchoolItem {
    if (_selectedSchoolId == 'ALL') {
      return null;
    }

    for (final _SchoolItem item in _schools) {
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

  void _selectSchool(_SchoolItem school) {
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

    for (final _SchoolItem item in _schools) {
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
            (_DeviceItem item) =>
                _selectedSchoolId == 'ALL' ||
                item.schoolId == _selectedSchoolId,
          )
          .map((_DeviceItem item) => item.building),
    ),
  ];

  List<String> get _roomOptions => <String>[
    'ทุกห้อง',
    ..._unique(
      _devices
          .where(
            (_DeviceItem item) =>
                (_selectedSchoolId == 'ALL' ||
                    item.schoolId == _selectedSchoolId) &&
                (_building == 'ทุกอาคาร' || item.building == _building),
          )
          .map((_DeviceItem item) => item.room),
    ),
  ];

  List<_DeviceItem> get _filteredDevices {
    final String query = _searchController.text.trim().toLowerCase();

    return _devices.where((_DeviceItem item) {
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

  @override
  Widget build(BuildContext context) {
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
                boxShadow: _shadow,
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

    final List<_DeviceItem> filtered = _filteredDevices;

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
    final _SchoolItem? selected = _selectedSchoolItem;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppPalette.softBeige),
        boxShadow: _shadow,
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
                        _schoolMiniStat(
                          '${selected.totalDevices}',
                          'อุปกรณ์',
                          Icons.memory_rounded,
                        ),
                        _schoolMiniStat(
                          '${selected.onlineDevices}',
                          'ออนไลน์',
                          Icons.wifi_tethering_rounded,
                        ),
                        _schoolMiniStat(
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

  Widget _schoolMiniStat(String value, String label, IconData icon) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.softBeige),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: AppPalette.deepBlue, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
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
                      child: _metric(
                        Icons.wifi_tethering_rounded,
                        '$_onlineCount',
                        'ออนไลน์',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _metric(
                        Icons.power_rounded,
                        '$_onCount',
                        'กำลังเปิด',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _metric(
                        Icons.auto_mode_rounded,
                        '$_autoCount',
                        'อัตโนมัติ',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _metric(
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

  Widget _metric(IconData icon, String value, String label) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.deepBlue.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppPalette.circusYellow.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppPalette.deepBlue, size: 19),
          ),
          const SizedBox(height: 11),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.deepBlue,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
          _summaryCard(
            Icons.devices_rounded,
            'อุปกรณ์ทั้งหมด',
            '${_devices.length}',
            'ลงทะเบียนในระบบควบคุม',
            AppPalette.deepBlue,
          ),
          _summaryCard(
            Icons.toggle_on_rounded,
            'กำลังเปิด',
            '$_onCount',
            'เปิดอยู่และเชื่อมต่อปกติ',
            AppPalette.gardenGreen,
          ),
          _summaryCard(
            Icons.auto_mode_rounded,
            'โหมดอัตโนมัติ',
            '$_autoCount',
            'ทำงานตามเงื่อนไขระบบ',
            AppPalette.circusYellow,
          ),
          _summaryCard(
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

  Widget _summaryCard(
    IconData icon,
    String title,
    String value,
    String detail,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 165),
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
            radius: 21,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedScopeControls() {
    final List<_ProtectedScope> scopes = <_ProtectedScope>[
      _ProtectedScope(
        code: 'main',
        title: 'อุปกรณ์หลัก',
        subtitle: 'บอร์ดควบคุมและ Gateway ส่วนกลาง',
        icon: Icons.hub_rounded,
        color: AppPalette.deepBlue,
      ),
      _ProtectedScope(
        code: 'electricity',
        title: 'ระบบไฟฟ้า',
        subtitle: 'แหล่งจ่ายไฟและรีเลย์ไฟฟ้า',
        icon: Icons.electric_bolt_rounded,
        color: AppPalette.circusYellow,
      ),
      _ProtectedScope(
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
                  .map((_ProtectedScope scope) {
                    final List<_DeviceItem> targets = _devicesForScope(
                      scope.code,
                    );

                    final int onCount =
                        targets.where((_DeviceItem item) => item.isOn).length;

                    final int onlineCount =
                        targets.where((_DeviceItem item) => item.online).length;

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
    final List<_ApprovalItem> approvals = _visibleApprovals;

    return _panel(
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
              '${approvals.where((_ApprovalItem item) => item.status == 'pending').length} รออนุมัติ',
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
              ? _empty(
                Icons.approval_outlined,
                'ยังไม่มีคำขออนุมัติ',
                'เมื่อผู้ใช้ขอเปิดหรือปิดระบบ คำขอจะปรากฏที่นี่',
              )
              : Column(
                children: approvals
                    .map(_buildApprovalTile)
                    .toList(growable: false),
              ),
    );
  }

  Widget _buildApprovalTile(_ApprovalItem item) {
    final Color statusColor = switch (item.status) {
      'approved' => AppPalette.gardenGreen,
      'rejected' => AppPalette.carnivalRed,
      'expired' => AppPalette.textSecondary,
      _ => AppPalette.circusYellow,
    };

    final String statusLabel = switch (item.status) {
      'approved' => 'อนุมัติแล้ว',
      'rejected' => 'ไม่อนุมัติ',
      'expired' => 'หมดเวลา',
      _ => 'รออนุมัติ',
    };

    final bool canDecide = _canApproveRequests && item.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget information = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  item.turnOn
                      ? Icons.power_settings_new_rounded
                      : Icons.power_off_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${item.turnOn ? 'ขอเปิด' : 'ขอปิด'} '
                      '${item.scopeLabel}',
                      style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.schoolName} • '
                      '${item.targetCount} อุปกรณ์',
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'ผู้ขอ: ${item.requesterName} • '
                      '${item.requestedLabel}',
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    if (item.reason.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        'เหตุผล: ${item.reason}',
                        style: const TextStyle(
                          color: AppPalette.textPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (item.approverName != null) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        'ผู้พิจารณา: ${item.approverName}',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final Widget actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (canDecide) ...<Widget>[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _rejectApproval(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.carnivalRed,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('ไม่อนุมัติ'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _approveWithPassword(item),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.gardenGreen,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.password_rounded, size: 17),
                  label: const Text('ยืนยันด้วยรหัสผ่าน'),
                ),
              ],
            ],
          );

          if (constraints.maxWidth < 820) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                information,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: actions,
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: information),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }

  List<_DeviceItem> _devicesForScope(String scope) {
    if (_selectedSchoolId == 'ALL') {
      return <_DeviceItem>[];
    }

    return _devices
        .where((_DeviceItem item) {
          if (item.schoolId != _selectedSchoolId) {
            return false;
          }

          return _scopeForDevice(item) == scope;
        })
        .toList(growable: false);
  }

  String _scopeForDevice(_DeviceItem item) {
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
    required List<_DeviceItem> devices,
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
        await _service.createControlApprovalRequest(
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

  Future<void> _approveWithPassword(_ApprovalItem item) async {
    final TextEditingController passwordController = TextEditingController();

    bool obscure = true;
    String? dialogError;

    final bool? approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              icon: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppPalette.deepBlue,
                size: 42,
              ),
              title: const Text('แอดมินยืนยันการอนุมัติ'),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${item.turnOn ? 'เปิด' : 'ปิด'} '
                      '${item.scopeLabel}\n'
                      '${item.schoolName} • '
                      '${item.targetCount} อุปกรณ์',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: obscure,
                      autofocus: true,
                      onSubmitted: (_) {},
                      decoration: InputDecoration(
                        labelText: 'รหัสผ่านบัญชีแอดมิน',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscure = !obscure;
                            });
                          },
                          icon: Icon(
                            obscure
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                        errorText: dialogError,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'รหัสผ่านจะถูกส่งไปตรวจสอบกับ Supabase Auth '
                      'และจะไม่ถูกเก็บไว้ในตารางคำขอ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 10,
                        height: 1.4,
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
                  onPressed: () async {
                    final String password = passwordController.text.trim();

                    if (password.isEmpty) {
                      setDialogState(() {
                        dialogError = 'กรุณากรอกรหัสผ่านยืนยัน';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(true);
                  },
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('อนุมัติคำสั่ง'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();

    if (approved != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.decideControlApprovalRequest(
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

  Future<void> _rejectApproval(_ApprovalItem item) async {
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
      await _service.decideControlApprovalRequest(
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
    final List<_DeviceItem> offline =
        _devices.where((_DeviceItem item) => !item.online).toList();

    return _panel(
      title: 'รายการที่ควรจัดการก่อน',
      trailing: _badge(
        '${offline.length} รายการ',
        offline.isEmpty ? AppPalette.gardenGreen : AppPalette.carnivalRed,
      ),
      child:
          offline.isEmpty
              ? _empty(
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
                  child: _dropdown(
                    'โรงเรียน',
                    Icons.apartment_rounded,
                    _schoolOptions.contains(_school) ? _school : 'ทุกโรงเรียน',
                    _schoolOptions,
                    _selectSchoolByName,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _dropdown(
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
                  child: _dropdown(
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
                  child: _dropdown(
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

  Widget _dropdown(
    String label,
    IconData icon,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items:
          items
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
      onChanged: (String? value) {
        if (value != null) {
          onChanged(value);
        }
      },
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

  Widget _buildDevicePanel(List<_DeviceItem> filtered) {
    return _panel(
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
            _empty(
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
                        (_DeviceItem item) =>
                            SizedBox(width: width, child: _deviceCard(item)),
                      )
                      .toList(growable: false),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _deviceCard(_DeviceItem item) {
    final Color stateColor =
        !item.online
            ? AppPalette.carnivalRed
            : item.isOn
            ? AppPalette.gardenGreen
            : AppPalette.deepBlue;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color:
              item.online
                  ? AppPalette.softBeige.withValues(alpha: 0.7)
                  : AppPalette.carnivalRed.withValues(alpha: 0.5),
        ),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(item.icon, color: stateColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.id} • ${item.type}',
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'ดูรายละเอียด',
                onPressed: () => _showDetails(item),
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _badge(
                item.online ? 'ออนไลน์' : 'ออฟไลน์',
                item.online ? AppPalette.gardenGreen : AppPalette.carnivalRed,
              ),
              _badge(
                item.isOn ? 'กำลังเปิด' : 'ปิดอยู่',
                item.isOn ? AppPalette.gardenGreen : AppPalette.deepBlue,
              ),
              _badge(
                item.autoMode ? 'อัตโนมัติ' : 'ควบคุมเอง',
                item.autoMode ? AppPalette.circusYellow : AppPalette.deepBlue,
              ),
              if (item.commandPending)
                _badge('รออุปกรณ์รับคำสั่ง', AppPalette.circusYellow),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppPalette.softBeige.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${item.school} • ${item.building} • ${item.room}',
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.reading,
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.updated,
                  style: TextStyle(
                    color:
                        item.online
                            ? AppPalette.textSecondary
                            : AppPalette.carnivalRed,
                    fontSize: 10,
                  ),
                ),
                if (!item.online) ...<Widget>[
                  const SizedBox(height: 6),
                  const Text(
                    'ยังส่งคำขอเปิด–ปิดได้ โดยคำสั่งจะรอ '
                    'จนกว่า MiniPC หรือ Gateway จะเชื่อมต่อ',
                    style: TextStyle(
                      color: AppPalette.textSecondary,
                      fontSize: 9.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: item.autoMode ? 'อัตโนมัติ' : 'ควบคุมเอง',
                  decoration: const InputDecoration(
                    labelText: 'โหมดทำงาน',
                    prefixIcon: Icon(Icons.tune_rounded),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'อัตโนมัติ',
                      child: Text('อัตโนมัติ'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'ควบคุมเอง',
                      child: Text('ควบคุมเอง'),
                    ),
                  ],
                  onChanged:
                      item.commandPending
                          ? null
                          : (String? value) {
                            if (value == null) {
                              return;
                            }

                            _changeMode(item, value == 'อัตโนมัติ');
                          },
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: <Widget>[
                  Text(
                    item.isOn ? 'เปิด' : 'ปิด',
                    style: TextStyle(
                      color: stateColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Switch.adaptive(
                    value: item.isOn,
                    onChanged:
                        item.commandPending
                            ? null
                            : (bool value) => _confirmToggle(item, value),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanels() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget permission = _panel(
          title: 'สิทธิ์ควบคุมอุปกรณ์',
          trailing: IconButton(
            tooltip: 'เพิ่มสิทธิ์',
            onPressed: _addPermission,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
          child:
              _permissions.isEmpty
                  ? _empty(
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
                        _permissionRow(
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

        final Widget logs = _panel(
          title: 'ประวัติคำสั่งล่าสุด',
          trailing: TextButton(
            onPressed: () => _message('เปิดประวัติคำสั่งทั้งหมด'),
            child: const Text('ดูทั้งหมด'),
          ),
          child:
              _logs.isEmpty
                  ? _empty(
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
                        _logRow(_logs[index]),
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

  Widget _permissionRow(String email, String detail, Color color) {
    return Row(
      children: <Widget>[
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.person_rounded, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                email,
                style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _message('เปิดแก้ไขสิทธิ์ของ $email'),
          icon: const Icon(Icons.edit_rounded),
        ),
      ],
    );
  }

  Widget _logRow(_ActionLog log) {
    final Color color =
        log.success ? AppPalette.gardenGreen : AppPalette.carnivalRed;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            log.success ? Icons.check_rounded : Icons.close_rounded,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                log.title,
                style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                log.detail,
                style: const TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${log.actor} • ${log.time}',
                style: TextStyle(
                  color: color,
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

  Future<void> _confirmToggle(_DeviceItem item, bool value) async {
    final String scope = _scopeForDevice(item);

    await _requestProtectedControl(
      scope: scope,
      scopeLabel: _scopeLabel(scope),
      turnOn: value,
      devices: <_DeviceItem>[item],
      customTitle: '${value ? 'เปิด' : 'ปิด'} ${item.name}',
    );
  }

  Future<void> _changeMode(_DeviceItem item, bool autoMode) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _service.queueDeviceCommand(
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
    final List<_DeviceItem> targets = _devices
        .where((_DeviceItem item) => item.online && item.isOn)
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
        await _service.queueDeviceCommand(
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
                'บัญชีต้องถูกสร้างใน Supabase Authentication '
                'และมีข้อมูลในตาราง profiles แล้ว',
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
              child: const Text('กำหนดเป็น Operator'),
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
            ? 'เพิ่มสิทธิ์ควบคุมให้ $email แล้ว'
            : 'ไม่พบบัญชี $email ในตาราง profiles',
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

  void _showDetails(_DeviceItem item) {
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
                _detailRow('โรงเรียน', item.school),
                _detailRow('อาคาร', item.building),
                _detailRow('ห้อง', item.room),
                _detailRow('สถานะ', item.online ? 'ออนไลน์' : 'ออฟไลน์'),
                _detailRow('ค่าปัจจุบัน', item.reading),
                _detailRow('อัปเดตล่าสุด', item.updated),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
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

  Widget _panel({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: _shadow,
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _empty(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: AppPalette.softBeige.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 27,
            backgroundColor: AppPalette.deepBlue.withValues(alpha: 0.1),
            child: Icon(icon, color: AppPalette.deepBlue),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
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

  List<BoxShadow> get _shadow => <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.045),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ];
}

class _SchoolItem {
  const _SchoolItem({
    required this.databaseId,
    required this.schoolCode,
    required this.name,
    required this.province,
    required this.packageName,
    required this.status,
    required this.totalDevices,
    required this.onlineDevices,
    required this.openAlerts,
  });

  final String databaseId;
  final String schoolCode;
  final String name;
  final String province;
  final String packageName;
  final String status;
  final int totalDevices;
  final int onlineDevices;
  final int openAlerts;

  factory _SchoolItem.fromRecord(DeviceControlSchoolRecord record) {
    return _SchoolItem(
      databaseId: record.databaseId,
      schoolCode: record.schoolCode,
      name: record.name,
      province: record.province,
      packageName: record.packageName,
      status: record.status,
      totalDevices: record.totalDevices,
      onlineDevices: record.onlineDevices,
      openAlerts: record.openAlerts,
    );
  }
}

class _ProtectedScope {
  const _ProtectedScope({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String code;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _ApprovalItem {
  const _ApprovalItem({
    required this.databaseId,
    required this.schoolId,
    required this.schoolName,
    required this.scope,
    required this.action,
    required this.reason,
    required this.targetCount,
    required this.status,
    required this.requestedBy,
    required this.requesterName,
    required this.requestedAt,
    required this.expiresAt,
    required this.approverName,
    required this.decisionNote,
  });

  final String databaseId;
  final String schoolId;
  final String schoolName;
  final String scope;
  final String action;
  final String reason;
  final int targetCount;
  final String status;
  final String requestedBy;
  final String requesterName;
  final DateTime? requestedAt;
  final DateTime? expiresAt;
  final String? approverName;
  final String decisionNote;

  factory _ApprovalItem.fromRecord(DeviceControlApprovalRecord record) {
    return _ApprovalItem(
      databaseId: record.id,
      schoolId: record.schoolId,
      schoolName: record.schoolName,
      scope: record.command.contains('building')
          ? 'building'
          : (record.command.contains('school') ? 'school' : 'main'),
      action: record.command,
      reason: record.notes ?? '',
      targetCount: 1,
      status: record.status,
      requestedBy: record.requestedBy,
      requesterName: record.requesterName,
      requestedAt: record.createdAt,
      expiresAt: record.createdAt?.add(const Duration(hours: 24)),
      approverName: record.reviewerName,
      decisionNote: record.notes ?? '',
    );
  }

  bool get turnOn => action == 'power_on';

  String get scopeLabel {
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

  String get requestedLabel {
    final DateTime? value = requestedAt;

    if (value == null) {
      return '-';
    }

    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');

    return '${value.day}/${value.month}/${value.year + 543} '
        '$hour:$minute น.';
  }
}

class _DeviceItem {
  final String databaseId;
  final String schoolId;
  final String id;
  final String name;
  final String school;
  final String building;
  final String room;
  final String type;
  final String categoryCode;
  final IconData icon;
  final bool online;
  final String reading;
  final String updated;
  final String commandStatus;
  final Map<String, dynamic> metadata;

  bool isOn;
  bool autoMode;

  _DeviceItem({
    required this.databaseId,
    required this.schoolId,
    required this.id,
    required this.name,
    required this.school,
    required this.building,
    required this.room,
    required this.type,
    required this.categoryCode,
    required this.icon,
    required this.online,
    required this.isOn,
    required this.autoMode,
    required this.reading,
    required this.updated,
    required this.commandStatus,
    required this.metadata,
  });

  factory _DeviceItem.fromRecord(DeviceControlItemRecord record) {
    IconData icon;

    switch (record.categoryCode) {
      case 'SEN':
        icon = Icons.sensors_rounded;
        break;
      case 'CAM':
        icon = Icons.videocam_rounded;
        break;
      case 'RLY':
        icon = Icons.electrical_services_rounded;
        break;
      case 'WTR':
        icon = Icons.water_drop_rounded;
        break;
      case 'PWR':
        icon = Icons.power_rounded;
        break;
      case 'GTW':
        icon = Icons.router_rounded;
        break;
      case 'CTL':
      default:
        icon = Icons.developer_board_rounded;
        break;
    }

    final DateTime? updatedDt = record.updatedAt;
    final String updatedStr = updatedDt != null
        ? '${updatedDt.day}/${updatedDt.month} ${updatedDt.hour.toString().padLeft(2, '0')}:${updatedDt.minute.toString().padLeft(2, '0')}'
        : '-';

    return _DeviceItem(
      databaseId: record.databaseId,
      schoolId: record.schoolId,
      id: record.deviceCode,
      name: record.name,
      school: record.schoolName,
      building: record.building,
      room: record.room,
      type: record.categoryCode,
      categoryCode: record.categoryCode,
      icon: icon,
      online: record.online,
      isOn: record.isPoweredOn,
      autoMode: record.controlMode == 'auto',
      reading: '-',
      updated: updatedStr,
      commandStatus: 'idle',
      metadata: Map<String, dynamic>.from(record.metadata),
    );
  }

  bool get commandPending {
    return <String>{
      'pending',
      'processing',
      'queued',
    }.contains(commandStatus.toLowerCase());
  }
}

class _ActionLog {
  final String title;
  final String detail;
  final String time;
  final String actor;
  final bool success;

  const _ActionLog({
    required this.title,
    required this.detail,
    required this.time,
    required this.actor,
    required this.success,
  });

  factory _ActionLog.fromRecord(DeviceControlLogRecord record) {
    final DateTime? dt = record.createdAt;
    final String timeStr = dt != null
        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '-';

    return _ActionLog(
      title: record.eventType,
      detail: record.message,
      time: timeStr,
      actor: 'ระบบ',
      success: true,
    );
  }
}

class _ControlPermission {
  final String email;
  final String detail;
  final Color color;

  const _ControlPermission({
    required this.email,
    required this.detail,
    required this.color,
  });

  factory _ControlPermission.fromRecord(DeviceControlPermissionRecord record) {
    Color color;

    switch (record.role) {
      case 'super_admin':
        color = AppPalette.deepBlue;
        break;
      case 'support':
        color = AppPalette.gardenGreen;
        break;
      case 'school_admin':
        color = AppPalette.circusYellow;
        break;
      case 'operator':
      default:
        color = const Color(0xFF1676B5);
        break;
    }

    return _ControlPermission(
      email: record.email,
      detail: '${record.fullName} (${record.schoolName ?? "ทุกโรงเรียน"})',
      color: color,
    );
  }
}
