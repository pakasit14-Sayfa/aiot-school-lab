import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_core/shared_core.dart';

import '../../utils/web_download.dart';
import 'theme/app_palette.dart';
import 'widgets/dev_ui.dart';

class SuperAdminDevicesPage extends StatefulWidget {
  const SuperAdminDevicesPage({super.key, this.embedded = false});

  /// True when embedded in [SuperAdminNavigationShell]'s desktop sidebar
  /// layout — suppresses this page's own AppBar since the sidebar
  /// already shows which page is selected.
  final bool embedded;

  @override
  State<SuperAdminDevicesPage> createState() => _SuperAdminDevicesPageState();
}

typedef DevicesPage = SuperAdminDevicesPage;

class _SuperAdminDevicesPageState extends State<SuperAdminDevicesPage> {
  final TextEditingController _searchController = TextEditingController();
  final SchoolAdminPlatformService _service = SchoolAdminPlatformService();

  bool _isLoading = true;
  String? _loadError;

  final List<_DeviceViewModel> _devices = <_DeviceViewModel>[];
  final List<DeviceControlSchoolRecord> _schools = <DeviceControlSchoolRecord>[];

  String _schoolFilter = 'ทุกโรงเรียน';
  String _categoryFilter = 'ทุกหมวดหมู่';
  String _statusFilter = 'ทุกสถานะ';
  String _sortMode = 'ชื่ออุปกรณ์';

  @override
  void initState() {
    super.initState();
    _loadDevicesData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDevicesData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final DeviceControlDataModel data =
          await _service.fetchDeviceControlData();

      if (!mounted) return;

      final List<_DeviceViewModel> loaded = [];
      for (int i = 0; i < data.devices.length; i++) {
        final d = data.devices[i];
        final typeName = _categoryNameByCode(d.categoryCode);

        loaded.add(_DeviceViewModel(
          id: d.deviceCode.isNotEmpty
              ? d.deviceCode
              : 'DEV-${(i + 1).toString().padLeft(4, '0')}',
          dbId: d.databaseId,
          name: d.name,
          deviceCode: d.deviceCode,
          school: d.schoolName.isNotEmpty ? d.schoolName : 'ไม่ระบุ',
          schoolId: d.schoolId,
          building: d.building.isNotEmpty ? d.building : 'ไม่ระบุ',
          room: d.room.isNotEmpty ? d.room : 'ไม่ระบุ',
          category: typeName,
          categoryCode: d.categoryCode,
          isOnline: d.online,
          status: d.status,
          metadata: d.metadata,
          updatedAt: d.updatedAt,
        ));
      }

      setState(() {
        _devices
          ..clear()
          ..addAll(loaded);

        _schools
          ..clear()
          ..addAll(data.schools);

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

  String _categoryNameByCode(String code) {
    switch (code.toUpperCase()) {
      case 'SEN':
      case 'SENSOR':
        return 'เซนเซอร์ (Sensor)';
      case 'RLY':
      case 'RELAY':
        return 'รีเลย์ / สวิตช์ (Relay)';
      case 'CAM':
      case 'CAMERA':
        return 'กล้อง (Camera)';
      case 'GTW':
      case 'GATEWAY':
        return 'Gateway / Router';
      case 'CTL':
      case 'CONTROLLER':
        return 'บอร์ดควบคุม (Controller)';
      default:
        return 'อุปกรณ์ IoT ทั่วไป';
    }
  }

  int get _onlineCount => _devices.where((d) => d.isOnline).length;
  int get _offlineCount => _devices.where((d) => !d.isOnline).length;

  List<String> get _schoolOptions => <String>[
        'ทุกโรงเรียน',
        ...(_schools.map((s) => s.name).toSet().toList()..sort()),
      ];

  List<_DeviceViewModel> get _filteredDevices {
    final String query = _searchController.text.trim().toLowerCase();

    final List<_DeviceViewModel> result = _devices.where((item) {
      final bool matchesText = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.deviceCode.toLowerCase().contains(query) ||
          item.school.toLowerCase().contains(query) ||
          item.building.toLowerCase().contains(query) ||
          item.room.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);

      final bool matchesSchool = _schoolFilter == 'ทุกโรงเรียน' ||
          item.school == _schoolFilter ||
          item.school == 'ทุกโรงเรียน';

      bool matchesCategory = true;
      if (_categoryFilter != 'ทุกหมวดหมู่') {
        matchesCategory = item.category.contains(_categoryFilter.split(' ').first);
      }

      bool matchesStatus = true;
      if (_statusFilter == 'ออนไลน์') {
        matchesStatus = item.isOnline;
      } else if (_statusFilter == 'ออฟไลน์') {
        matchesStatus = !item.isOnline;
      }

      return matchesText && matchesSchool && matchesCategory && matchesStatus;
    }).toList();

    if (_sortMode == 'ชื่ออุปกรณ์') {
      result.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortMode == 'รหัสอุปกรณ์') {
      result.sort((a, b) => a.deviceCode.compareTo(b.deviceCode));
    } else if (_sortMode == 'สถานะออนไลน์ก่อน') {
      result.sort((a, b) => a.isOnline == b.isOnline ? 0 : (a.isOnline ? -1 : 1));
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
                'ทะเบียนและรหัสอุปกรณ์ (Devices & QR)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  tooltip: 'รีเฟรชข้อมูล',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => _loadDevicesData(),
                ),
              ],
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _devices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _devices.isEmpty) {
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
                'ไม่สามารถโหลดทะเบียนอุปกรณ์ได้',
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
                onPressed: () => _loadDevicesData(),
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

    final List<_DeviceViewModel> filteredDevices = _filteredDevices;

    return RefreshIndicator(
      onRefresh: () => _loadDevicesData(showLoading: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: <Widget>[
          _buildHeroCard(),
          const SizedBox(height: 18),
          _buildSummaryCards(),
          const SizedBox(height: 18),
          _buildSearchAndFilterPanel(),
          const SizedBox(height: 18),
          _buildDevicesListPanel(filteredDevices),
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
                    'ศูนย์ทะเบียนและ QR Code อุปกรณ์',
                    AppPalette.circusYellow,
                  ),
                  _badge(
                    'Device Registry',
                    Colors.white.withAlpha(50),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'ระบบจัดการทะเบียน รหัสกำกับ และ QR Code อุปกรณ์',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'ตรวจสอบตำแหน่ง ติดตามสถานะออนไลน์ พิมพ์ QR Code สติกเกอร์ และระบุพิกัดอุปกรณ์ในแต่ละห้องเรียน',
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
                    onPressed: _showRegisterDeviceDialog,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.circusYellow,
                      foregroundColor: AppPalette.textPrimary,
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text(
                      'ลงทะเบียนอุปกรณ์ใหม่',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exportDeviceRegistry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('ส่งออกทะเบียนอุปกรณ์'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _loadDevicesData(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('ซิงค์ข้อมูลล่าสุด'),
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
                        Icons.devices_rounded,
                        '${_devices.length}',
                        'อุปกรณ์ทั้งหมด',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _heroMetric(
                        Icons.wifi_rounded,
                        '$_onlineCount',
                        'ออนไลน์',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _heroMetric(
                        Icons.wifi_off_rounded,
                        '$_offlineCount',
                        'ออฟไลน์',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _heroMetric(
                        Icons.apartment_rounded,
                        '${_schools.length}',
                        'โรงเรียน',
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
            Icons.wifi_rounded,
            'อุปกรณ์ออนไลน์',
            '$_onlineCount',
            'เชื่อมต่อและส่งข้อมูลปกติ',
            AppPalette.gardenGreen,
          ),
          _summaryCard(
            Icons.wifi_off_rounded,
            'อุปกรณ์ออฟไลน์',
            '$_offlineCount',
            'ไม่ได้ส่งข้อมูลหรือปิดเครื่อง',
            AppPalette.carnivalRed,
          ),
          _summaryCard(
            Icons.qr_code_2_rounded,
            'QR Code พร้อมใช้งาน',
            '${_devices.length}',
            'สแกนเพื่อระบุตำแหน่งและสั่งการ',
            AppPalette.deepBlue,
          ),
          _summaryCard(
            Icons.category_rounded,
            'หมวดหมู่อุปกรณ์',
            '${_devices.map((d) => d.category).toSet().length}',
            'เซนเซอร์, รีเลย์, กล้อง, เกตเวย์',
            AppPalette.circusYellow,
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
  // 3. Search & Filters
  // ===========================================================================

  Widget _buildSearchAndFilterPanel() {
    return _panel(
      title: 'ค้นหาและกรองอุปกรณ์',
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
              hintText: 'ค้นหาชื่ออุปกรณ์ รหัส QR โรงเรียน อาคาร ห้อง หรือหมวดหมู่',
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
                      label: 'หมวดหมู่อุปกรณ์',
                      icon: Icons.category_rounded,
                      value: _categoryFilter,
                      items: const <String>[
                        'ทุกหมวดหมู่',
                        'เซนเซอร์',
                        'รีเลย์',
                        'กล้อง',
                        'Gateway',
                        'บอร์ดควบคุม',
                      ],
                      onChanged: (String value) {
                        setState(() {
                          _categoryFilter = value;
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
                        'ออนไลน์',
                        'ออฟไลน์',
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
                      label: 'เรียงตาม',
                      icon: Icons.sort_rounded,
                      value: _sortMode,
                      items: const <String>[
                        'ชื่ออุปกรณ์',
                        'รหัสอุปกรณ์',
                        'สถานะออนไลน์ก่อน',
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
      _schoolFilter = 'ทุกโรงเรียน';
      _categoryFilter = 'ทุกหมวดหมู่';
      _statusFilter = 'ทุกสถานะ';
      _sortMode = 'ชื่ออุปกรณ์';
    });
  }

  // ===========================================================================
  // 4. Devices List Panel
  // ===========================================================================

  Widget _buildDevicesListPanel(List<_DeviceViewModel> filteredDevices) {
    return _panel(
      title: 'รายการอุปกรณ์และ QR Code',
      trailing: Text(
        'พบ ${filteredDevices.length} เครื่อง',
        style: const TextStyle(
          color: AppPalette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: filteredDevices.isEmpty
          ? _empty(
              Icons.devices_other_rounded,
              'ไม่พบอุปกรณ์ที่ตรงกับเงื่อนไข',
              'ลองปรับตัวกรองโรงเรียนหรือคำค้นหาใหม่',
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
                  children: filteredDevices
                      .map(
                        (_DeviceViewModel device) => SizedBox(
                          width: width,
                          child: _deviceCard(device),
                        ),
                      )
                      .toList(),
                );
              },
            ),
    );
  }

  Widget _deviceCard(_DeviceViewModel device) {
    final Color statusColor =
        device.isOnline ? AppPalette.gardenGreen : AppPalette.carnivalRed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: device.isOnline
              ? AppPalette.gardenGreen.withAlpha(120)
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
                  color: AppPalette.deepBlue.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _categoryIcon(device.categoryCode),
                  color: AppPalette.deepBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      device.name,
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
                      '${device.school} • ${device.building} ${device.room}',
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
              IconButton(
                tooltip: 'แสดง QR Code',
                onPressed: () => _showQrModal(device),
                icon: const Icon(Icons.qr_code_2_rounded,
                    color: AppPalette.deepBlue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _badge(
                device.isOnline ? 'ออนไลน์' : 'ออฟไลน์',
                statusColor,
              ),
              _badge(device.category, AppPalette.deepBlue),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: device.deviceCode));
                  _message('คัดลอกรหัส ${device.deviceCode} แล้ว');
                },
                borderRadius: BorderRadius.circular(999),
                child: _badge('รหัส: ${device.deviceCode}', AppPalette.circusYellow),
              ),
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
                _infoRow(Icons.apartment_rounded, 'โรงเรียน', device.school),
                const SizedBox(height: 8),
                _infoRow(Icons.meeting_room_rounded, 'ตำแหน่ง',
                    '${device.building} · ${device.room}'),
                const SizedBox(height: 8),
                _infoRow(Icons.fingerprint_rounded, 'รหัสกำกับ',
                    device.deviceCode),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showQrModal(device),
                  icon: const Icon(Icons.qr_code_rounded, size: 17),
                  label: const Text('QR Code'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showDeviceDetails(device),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.deepBlue,
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 17),
                  label: const Text('รายละเอียด'),
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
  // Modals & Actions
  // ===========================================================================

  void _showQrModal(_DeviceViewModel device) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            device.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppPalette.softBeige),
                ),
                child: QrImageView(
                  data: device.deviceCode,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 14),
              SelectableText(
                device.deviceCode,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppPalette.deepBlue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${device.school} • ${device.building} ${device.room}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppPalette.textSecondary,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ปิด'),
            ),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: device.deviceCode));
                Navigator.of(dialogContext).pop();
                _message('คัดลอกรหัส ${device.deviceCode} เรียบร้อยแล้ว');
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('คัดลอกรหัส'),
            ),
          ],
        );
      },
    );
  }

  void _showDeviceDetails(_DeviceViewModel device) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
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
                        backgroundColor: AppPalette.deepBlue.withAlpha(30),
                        child: Icon(
                          _categoryIcon(device.categoryCode),
                          color: AppPalette.deepBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              device.name,
                              style: const TextStyle(
                                color: AppPalette.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${device.deviceCode} • ${device.school}',
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
                      _badge(
                        device.isOnline ? 'ออนไลน์' : 'ออฟไลน์',
                        device.isOnline
                            ? AppPalette.gardenGreen
                            : AppPalette.carnivalRed,
                      ),
                      _badge(device.category, AppPalette.deepBlue),
                      _badge('รหัส: ${device.deviceCode}', AppPalette.circusYellow),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailSection('ข้อมูลอุปกรณ์และสถานที่ติดตั้ง', <MapEntry<String, String>>[
                    MapEntry<String, String>('ชื่ออุปกรณ์', device.name),
                    MapEntry<String, String>('รหัสกำกับอุปกรณ์', device.deviceCode),
                    MapEntry<String, String>('โรงเรียน', device.school),
                    MapEntry<String, String>('อาคาร / ห้อง', '${device.building} · ${device.room}'),
                    MapEntry<String, String>('หมวดหมู่', device.category),
                    MapEntry<String, String>('สถานะการเชื่อมต่อ', device.isOnline ? 'เชื่อมต่ออยู่' : 'ไม่ได้เชื่อมต่อ'),
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _showQrModal(device);
                          },
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: const Text('แสดง QR Code'),
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

  static const Map<String, String> _deviceTypeLabels = {
    'mini_pc': 'Mini PC',
    'aiot_gateway': 'AIoT Gateway',
    'pm25_sensor': 'เซนเซอร์ PM2.5',
    'air_quality_sensor': 'เซนเซอร์คุณภาพอากาศ',
    'light_sensor': 'เซนเซอร์แสง',
    'energy_meter': 'มิเตอร์พลังงาน',
    'camera': 'กล้อง',
    'relay': 'รีเลย์',
    'emergency_button': 'ปุ่มฉุกเฉิน',
    'warning_light': 'ไฟแจ้งเตือน',
  };

  Future<void> _showRegisterDeviceDialog() async {
    if (_schools.isEmpty) {
      _message('ยังไม่มีโรงเรียนในระบบให้ลงทะเบียนอุปกรณ์');
      return;
    }

    final nameController = TextEditingController();
    final buildingController = TextEditingController();
    final roomController = TextEditingController();
    String? schoolId = _schools.first.databaseId;
    String type = _deviceTypeLabels.keys.first;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('ลงทะเบียนอุปกรณ์ใหม่'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: schoolId,
                    decoration: const InputDecoration(labelText: 'โรงเรียน'),
                    items: _schools
                        .map((s) => DropdownMenuItem(
                              value: s.databaseId,
                              child: Text(s.name),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => schoolId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'ชื่ออุปกรณ์'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'ประเภทอุปกรณ์'),
                    items: _deviceTypeLabels.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: buildingController,
                    decoration: const InputDecoration(labelText: 'อาคาร (ไม่บังคับ)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roomController,
                    decoration: const InputDecoration(labelText: 'ห้อง (ไม่บังคับ)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty || schoolId == null) {
                        _message('กรุณากรอกชื่ออุปกรณ์และเลือกโรงเรียน');
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        final result = await _service.registerDevice(
                          schoolId: schoolId!,
                          name: name,
                          type: type,
                          building: buildingController.text.trim().isEmpty
                              ? null
                              : buildingController.text.trim(),
                          room: roomController.text.trim().isEmpty
                              ? null
                              : roomController.text.trim(),
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        await _loadDevicesData(showLoading: false);
                        if (!mounted) return;
                        await _showDeviceTokenDialog(
                          result['device_token'] as String,
                        );
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        _message('ลงทะเบียนไม่สำเร็จ: $e');
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ลงทะเบียน'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeviceTokenDialog(String deviceToken) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลงทะเบียนสำเร็จ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'คัดลอก device token นี้ไปตั้งค่าในอุปกรณ์จริง — จะแสดงครั้งนี้ครั้งเดียวเท่านั้น',
            ),
            const SizedBox(height: 12),
            SelectableText(
              deviceToken,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: deviceToken));
              _message('คัดลอก token แล้ว');
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('คัดลอก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('เสร็จสิ้น'),
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

  void _exportDeviceRegistry() {
    final devices = _filteredDevices;
    if (devices.isEmpty) {
      _message('ไม่มีอุปกรณ์ให้ส่งออกตามตัวกรองปัจจุบัน');
      return;
    }

    final header = [
      'device_code',
      'name',
      'category',
      'school',
      'building',
      'room',
      'status',
      'updated_at',
    ];
    final rows = <List<String>>[
      header,
      for (final d in devices)
        [
          d.deviceCode,
          d.name,
          d.category,
          d.school,
          d.building,
          d.room,
          d.status,
          d.updatedAt?.toIso8601String() ?? '',
        ],
    ];
    final csv = rows
        .map((row) => row.map(_csvField).join(','))
        .join('\r\n');

    downloadBytes(
      filename:
          'device_registry_${DateTime.now().toIso8601String().split('T').first}.csv',
      bytes: utf8.encode('﻿$csv'),
      mimeType: 'text/csv',
    );
    _message('ส่งออกข้อมูลทะเบียนอุปกรณ์จำนวน ${devices.length} รายการแล้ว');
  }

  IconData _categoryIcon(String code) {
    switch (code.toUpperCase()) {
      case 'SEN':
      case 'SENSOR':
        return Icons.sensors_rounded;
      case 'RLY':
      case 'RELAY':
        return Icons.toggle_on_rounded;
      case 'CAM':
      case 'CAMERA':
        return Icons.videocam_rounded;
      case 'GTW':
      case 'GATEWAY':
        return Icons.router_rounded;
      case 'CTL':
      case 'CONTROLLER':
        return Icons.developer_board_rounded;
      default:
        return Icons.memory_rounded;
    }
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

class _DeviceViewModel {
  final String id;
  final String dbId;
  final String name;
  final String deviceCode;
  final String school;
  final String schoolId;
  final String building;
  final String room;
  final String category;
  final String categoryCode;
  final bool isOnline;
  final String status;
  final Map<String, dynamic> metadata;
  final DateTime? updatedAt;

  _DeviceViewModel({
    required this.id,
    required this.dbId,
    required this.name,
    required this.deviceCode,
    required this.school,
    required this.schoolId,
    required this.building,
    required this.room,
    required this.category,
    required this.categoryCode,
    required this.isOnline,
    required this.status,
    required this.metadata,
    this.updatedAt,
  });
}
