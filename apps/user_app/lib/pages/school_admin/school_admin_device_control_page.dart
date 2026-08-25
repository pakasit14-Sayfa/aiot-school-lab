import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class SchoolAdminDeviceControlPage extends StatefulWidget {
  const SchoolAdminDeviceControlPage({super.key});

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

  final Map<String, bool> _optimisticState = {};
  final Set<String> _sending = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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

  List<DeviceOption> get _filteredRelays => _selectedLocation == _scopeAll
      ? _relays
      : _relays.where((d) => d.location == _selectedLocation).toList();

  Map<String, List<DeviceOption>> get _relaysByLocation {
    final grouped = <String, List<DeviceOption>>{};
    for (final d in _filteredRelays) {
      final loc = d.location ?? 'ไม่ระบุตำแหน่ง';
      grouped.putIfAbsent(loc, () => []).add(d);
    }
    return grouped;
  }

  bool _isWaterDevice(DeviceOption d) => d.name.contains('น้ำ');

  int get _onCount =>
      _filteredRelays.where((d) => _optimisticState[d.id] == true).length;

  Future<void> _toggle(DeviceOption device, bool value) async {
    setState(() => _sending.add(device.id));
    try {
      await RealtimeService.queueDeviceCommand(
        deviceId: device.id,
        command: {'action': value ? 'on' : 'off'},
      );
      if (!mounted) return;
      setState(() => _optimisticState[device.id] = value);
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ควบคุมอุปกรณ์ (ไฟและน้ำ)'),
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
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 18),
          _buildSummaryStats(),
          const SizedBox(height: 14),
          _buildUnknownStateNotice(),
          const SizedBox(height: 14),
          _buildScopeFilterBar(),
          const SizedBox(height: 16),
          if (_filteredRelays.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'ไม่พบอุปกรณ์ควบคุม (relay) ในขอบเขตที่เลือก',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            for (final entry in _relaysByLocation.entries) ...[
              _buildLocationSectionHeader(entry.key, entry.value.length),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 700 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      mainAxisExtent: 120,
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (context, idx) {
                      final device = entry.value[idx];
                      return _ControlCard(
                        device: device,
                        isWater: _isWaterDevice(device),
                        value: _optimisticState[device.id],
                        isSending: _sending.contains(device.id),
                        onChanged: (v) => _toggle(device, v),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
        ],
      ),
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
              Icons.lightbulb_rounded,
              color: Color(0xFFFBBF24),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ควบคุมไฟและน้ำทั้งโรงเรียน',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'สั่งงานอุปกรณ์รีเลย์ไฟแสงสว่างและปั๊มน้ำทุกอาคาร',
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

  Widget _buildSummaryStats() {
    final total = _filteredRelays.length;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.toggle_on_rounded,
            label: 'สั่งเปิดไว้ (เครื่องนี้)',
            value: '$_onCount / $total จุด',
            color: const Color(0xFF059669),
            bg: const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.settings_remote_rounded,
            label: 'อุปกรณ์ควบคุมทั้งหมด',
            value: '$total ตัว',
            color: const Color(0xFF2563EB),
            bg: const Color(0xFFEFF6FF),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildUnknownStateNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1D4ED8)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'สถานะเปิด/ปิดที่แสดงมาจากคำสั่งล่าสุดที่กดในเครื่องนี้เท่านั้น '
              'ยังไม่มีการยืนยันสถานะจริงจากอุปกรณ์กลับมา',
              style: TextStyle(
                color: Color(0xFF1D4ED8),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ตำแหน่ง:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLocation,
              isDense: true,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              onChanged: (val) {
                if (val != null) setState(() => _selectedLocation = val);
              },
              items: _locationOptions.map((o) {
                return DropdownMenuItem(value: o, child: Text(o));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSectionHeader(String location, int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count จุด',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
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
  final bool? value;
  final bool isSending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isOn = value == true;
    final accentColor = isWater
        ? const Color(0xFF0284C7)
        : const Color(0xFFE8A519);
    final isOffline = device.status != 'online';

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: isOn ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOffline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: const Text(
                            'ออฟไลน์',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOn
                          ? accentColor.withValues(alpha: 0.08)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isWater
                              ? Icons.water_drop_rounded
                              : Icons.lightbulb_rounded,
                          size: 16,
                          color: isOn ? accentColor : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            value == null
                                ? 'ไม่ทราบสถานะ'
                                : (isOn ? 'เปิดอยู่' : 'ปิดอยู่'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isSending)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: isOn,
                              onChanged: isOffline ? null : onChanged,
                              activeColor: accentColor,
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
    );
  }
}
