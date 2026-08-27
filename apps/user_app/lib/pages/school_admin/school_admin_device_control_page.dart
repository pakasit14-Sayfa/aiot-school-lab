import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../theme/school_admin_palette.dart';

class SchoolAdminDeviceControlPage extends StatefulWidget {
  const SchoolAdminDeviceControlPage({super.key, this.initialRelays});

  final List<DeviceOption>? initialRelays;

  @override
  State<SchoolAdminDeviceControlPage> createState() =>
      _SchoolAdminDeviceControlPageState();
}

class _SchoolAdminDeviceControlPageState
    extends State<SchoolAdminDeviceControlPage> {
  static const _scopeAll = 'ทั้งหมด';

  bool _loading = true;
  String? _loadError;
  List<DeviceOption> _relays = [];
  String _selectedLocation = _scopeAll;
  String _searchQuery = '';
  String _typeFilter = 'ทั้งหมด'; // ทั้งหมด, ไฟฟ้าและแสงสว่าง, ระบบน้ำ

  final Map<String, bool> _optimisticState = {};
  final Set<String> _sending = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialRelays != null) {
      _relays = widget.initialRelays!;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.initialRelays != null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final devices = await RealtimeService.listSchoolDevices();
      if (!mounted) return;
      setState(() {
        _relays = devices.where((d) => d.type == 'relay').toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดรายชื่ออุปกรณ์ไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  List<String> get _locationOptions => [
    _scopeAll,
    ...{
      for (final d in _relays)
        if (d.location != null) d.location!,
    }.toList()..sort(),
  ];

  bool _isWaterDevice(DeviceOption d) => d.name.contains('น้ำ');

  List<DeviceOption> get _filteredRelays {
    return _relays.where((d) {
      final matchesLoc =
          _selectedLocation == _scopeAll || d.location == _selectedLocation;
      final q = _searchQuery.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          (d.location ?? '').toLowerCase().contains(q);

      final isWater = _isWaterDevice(d);
      final matchesType = _typeFilter == 'ทั้งหมด' ||
          (_typeFilter == 'ระบบน้ำ' && isWater) ||
          (_typeFilter == 'ไฟฟ้าและแสงสว่าง' && !isWater);

      return matchesLoc && matchesQuery && matchesType;
    }).toList();
  }

  Map<String, List<DeviceOption>> get _relaysByLocation {
    final grouped = <String, List<DeviceOption>>{};
    for (final d in _filteredRelays) {
      final loc = d.location ?? 'ไม่ระบุตำแหน่ง';
      grouped.putIfAbsent(loc, () => []).add(d);
    }
    return grouped;
  }

  int get _onCount =>
      _filteredRelays.where((d) => _optimisticState[d.id] == true).length;

  int get _waterCount => _filteredRelays.where(_isWaterDevice).length;
  int get _electricCount => _filteredRelays.where((d) => !_isWaterDevice(d)).length;

  Future<void> _toggle(DeviceOption device, bool value) async {
    setState(() => _sending.add(device.id));
    try {
      await RealtimeService.queueDeviceCommand(
        deviceId: device.id,
        command: {'action': value ? 'on' : 'off'},
      );
      if (!mounted) return;
      setState(() => _optimisticState[device.id] = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งคำสั่ง ${value ? "เปิด" : "ปิด"} ${device.name} สำเร็จ'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: value ? const Color(0xFF16A34A) : const Color(0xFF475569),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('สั่งงานไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _sending.remove(device.id));
    }
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
                            _buildUnknownStateNotice(),
                            const SizedBox(height: 16),
                            _buildFilterBar(),
                            const SizedBox(height: 20),
                            _buildRelaysGroupedList(),
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
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFD97706),
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
                          'ควบคุมไฟและน้ำ (Device Control)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            '${_relays.length} สวิตช์รีเลย์',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'สั่งการเปิด-ปิดสวิตช์รีเลย์ ควบคุมระบบไฟฟ้า แสงสว่าง และวาล์วน้ำในโรงเรียนแบบเรียลไทม์',
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
    final total = _filteredRelays.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKpiCard(
              title: 'สั่งเปิดไว้ (เครื่องนี้)',
              value: '$_onCount / $total จุด',
              subtitle: 'Active Relay Outputs',
              icon: Icons.toggle_on_rounded,
              color: const Color(0xFF16A34A),
              bgColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFFBBF7D0),
              width: isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4,
            ),
            _buildKpiCard(
              title: 'อุปกรณ์รีเลย์ทั้งหมด',
              value: '$total ตัว',
              subtitle: 'Connected Relays',
              icon: Icons.settings_remote_rounded,
              color: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
              width: isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4,
            ),
            _buildKpiCard(
              title: 'ระบบไฟฟ้าและแสงสว่าง',
              value: '$_electricCount ตัว',
              subtitle: 'Lights & Power Relays',
              icon: Icons.bolt_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              width: isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4,
            ),
            _buildKpiCard(
              title: 'ระบบน้ำและวาล์ว',
              value: '$_waterCount ตัว',
              subtitle: 'Water Pumps & Valves',
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF0284C7),
              bgColor: const Color(0xFFF0F9FF),
              borderColor: const Color(0xFFBAE6FD),
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

  Widget _buildUnknownStateNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2563EB)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'คำสั่งเปิด/ปิดจะถูกส่งไปยัง Queue คำสั่งควบคุมของอุปกรณ์ IoT โดยตรง และสถานะที่แสดงสะท้อนตามคำสั่งล่าสุดที่สั่งงานจากระบบ',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final searchField = TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อสวิตช์ หรือสถานที่...',
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
          );

          final dropdownType = DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButton<String>(
                value: _typeFilter,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                items: ['ทั้งหมด', 'ไฟฟ้าและแสงสว่าง', 'ระบบน้ำ'].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (v) => setState(() => _typeFilter = v ?? 'ทั้งหมด'),
              ),
            ),
          );

          final dropdownLocation = DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButton<String>(
                value: _selectedLocation,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                items: _locationOptions.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (v) => setState(() => _selectedLocation = v ?? _scopeAll),
              ),
            ),
          );

          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: dropdownType),
                    const SizedBox(width: 10),
                    Expanded(child: dropdownLocation),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              SizedBox(width: 170, child: dropdownType),
              const SizedBox(width: 12),
              SizedBox(width: 200, child: dropdownLocation),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRelaysGroupedList() {
    if (_filteredRelays.isEmpty) {
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
            Icon(Icons.power_off_rounded, size: 40, color: Color(0xFF94A3B8)),
            SizedBox(height: 14),
            Text(
              'ไม่พบอุปกรณ์ควบคุม (relay) ในเงื่อนไขที่เลือก',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
    }

    final groups = _relaysByLocation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          _buildLocationHeader(entry.key, entry.value.length),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 750 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 100,
                ),
                itemCount: entry.value.length,
                itemBuilder: (context, idx) {
                  final device = entry.value[idx];
                  return _ControlCard(
                    device: device,
                    isWater: _isWaterDevice(device),
                    value: _optimisticState[device.id] ?? false,
                    isSending: _sending.contains(device.id),
                    onChanged: (v) => _toggle(device, v),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildLocationHeader(String location, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.place_rounded, color: Color(0xFF2563EB), size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          location,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count สวิตช์',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.device,
    required this.isWater,
    required this.value,
    required this.isSending,
    required this.onChanged,
  });

  final DeviceOption device;
  final bool isWater;
  final bool value;
  final bool isSending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final activeColor = isWater ? const Color(0xFF0284C7) : const Color(0xFFD97706);
    final activeBg = isWater ? const Color(0xFFF0F9FF) : const Color(0xFFFFFBEB);
    final activeBorder = isWater ? const Color(0xFFBAE6FD) : const Color(0xFFFDE68A);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? activeBorder : const Color(0xFFE2E8F0),
          width: value ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: value ? activeColor.withAlpha(20) : const Color(0x03000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value ? activeBg : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value ? activeBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              isWater
                  ? (value ? Icons.water_drop_rounded : Icons.water_drop_outlined)
                  : (value ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded),
              color: value ? activeColor : const Color(0xFF94A3B8),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  device.location ?? 'ไม่ระบุตำแหน่ง',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isSending)
            const SizedBox(
              width: 28,
              height: 28,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Transform.scale(
              scale: 0.9,
              child: Switch(
                value: value,
                activeColor: Colors.white,
                activeTrackColor: activeColor,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFCBD5E1),
                onChanged: onChanged,
              ),
            ),
        ],
      ),
    );
  }
}
