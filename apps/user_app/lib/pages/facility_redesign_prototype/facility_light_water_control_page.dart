// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase/switch จริง
// ตามสเปก STK-11: "ไม่มีสิทธิ์ควบคุม → ดูได้อย่างเดียว" (Read-only Summary)
//
// 2026-08-14: เดิมเมนู "เปิด-ปิดอาคาร" (index 1) เป็น checklist wizard
// (facility_building_wizard_page.dart) ที่ไม่มียูสเคสทางการรองรับเลย
// (ไม่มีใน STK-6..11) แถมขัดกับหลักการ "Read-only" ของ role นี้ที่ระบุไว้
// ตรงๆ ในเอกสาร — ผู้ใช้ให้นิยามใหม่ว่า "เปิด-ปิดอาคาร" หมายถึงการ
// เปิด-ปิดไฟ (และน้ำ) ตามอาคาร/ชั้น/ห้องที่รับผิดชอบแทน ซึ่งตรงกับ STK-11
// เป๊ะอยู่แล้ว จึงเอาไฟล์นี้มาแทนที่ index 1 ทั้งหมด (ลบ
// facility_building_wizard_page.dart ทิ้ง) พร้อมเพิ่มตัวเลือกลำดับชั้น
// อาคาร → ชั้น → ห้อง (เดิมเป็นลิสต์เรียบไม่มีลำดับชั้น)
//
// 2026-08-15: ออกแบบใหม่ทั้งหมดตามคำขอผู้ใช้ (เน้นสวยงามแบบพรีเมียม) —
// เพิ่ม hero header, การ์ดสรุปสถิติ (ไฟ/น้ำเปิดอยู่กี่จุด), จัดกลุ่มการ์ด
// ตามชั้นแทนลิสต์เรียบยาวๆ, และปรับการ์ดควบคุมแต่ละจุดให้มีสไตล์ premium
// (ไอคอนวงกลม, แถบสีข้าง, layout ชัดเจนขึ้น) — โครงสร้าง state/logic เดิม
// (STK-11 scope lock ที่เพิ่งแก้ก่อนหน้านี้) ไม่เปลี่ยน แก้แค่ชั้น UI
//
// เป็น Widget content ต่อกับ FacilityAppShell เดิม (ไม่มี Scaffold/AppBar
// เป็นของตัวเอง) ใช้เป็น nav item index 1 ได้โดยตรง — ถ้าจะ Navigator.push
// จากที่อื่นต้องห่อด้วย Scaffold+AppBar ที่จุดเรียกเอง (ดูตัวอย่างที่
// facility_building_overview_page.dart._buildQuickLinksRow)
import 'package:flutter/material.dart';
import 'facility_shared_widgets.dart';

class FacilityLightWaterControlPage extends StatefulWidget {
  const FacilityLightWaterControlPage({super.key});

  @override
  State<FacilityLightWaterControlPage> createState() =>
      _FacilityLightWaterControlPageState();
}

class _FacilityLightWaterControlPageState
    extends State<FacilityLightWaterControlPage> {
  bool _hasControlPermission =
      false; // STK-11: เริ่มต้นแบบไม่มีสิทธิ์ (Read-only)

  static const _scopeAll = 'ทั้งหมด';

  // 2026-08-15: เดิมมี 3 อาคารให้เลือก (รวม 'ทั้งหมด') — ขัดกับ STK-11 ที่
  // กำหนดว่าผู้ดูแลอาคารสั่งงานได้เฉพาะอุปกรณ์ที่ตัวเองมีสิทธิ์ควบคุม/อาคาร
  // ที่รับผิดชอบเท่านั้น (เหมือนกับ STK-6/7/9/10 ที่ scope = อาคารเดียวกัน)
  // ตัดอาคาร 1/2 ออก เหลือแต่อาคารที่รับผิดชอบจริง — ไม่มีทางสั่งไฟ/น้ำ
  // อาคารอื่นได้จากหน้านี้อีกแล้ว
  static const _assignedBuilding = 'อาคาร 3 (วิทยาศาสตร์)';

  // อาคาร → ชั้น → รายชื่อห้อง/พื้นที่ (mock โครงสร้างลำดับชั้น — เหลือแค่
  // อาคารที่รับผิดชอบ)
  final Map<String, Map<String, List<String>>> _buildingStructure = {
    _assignedBuilding: {
      'ชั้น 1': ['ห้องปฏิบัติการ', 'โถงทางเดิน'],
      'ชั้น 2': ['ห้อง 201', 'ห้อง 202'],
      'ชั้น 3': ['ห้อง 301', 'ห้อง 302'],
    },
  };

  String _selectedFloor = _scopeAll;
  String _selectedRoom = _scopeAll;

  late final Map<String, bool> _lightState = _generateInitialState(
    seedOffset: 0,
  );
  late final Map<String, bool> _waterState = _generateInitialState(
    seedOffset: 1,
  );

  /// สร้าง key ตำแหน่งแบบ "อาคาร · ชั้น · ห้อง" ครบทุกห้องในทุกอาคารไว้ล่วง
  /// หน้า แล้วค่อยกรองการแสดงผลตาม dropdown ที่เลือกทีหลัง
  Map<String, bool> _generateInitialState({required int seedOffset}) {
    final state = <String, bool>{};
    var i = 0;
    for (final building in _buildingStructure.entries) {
      for (final floor in building.value.entries) {
        for (final room in floor.value) {
          final key = '${building.key} · ${floor.key} · $room';
          state[key] = (i + seedOffset) % 3 != 0;
          i++;
        }
      }
    }
    return state;
  }

  List<String> get _floorOptions => [
    _scopeAll,
    ...(_buildingStructure[_assignedBuilding]?.keys ?? const <String>[]),
  ];

  List<String> get _roomOptions {
    if (_selectedFloor == _scopeAll) return [_scopeAll];
    return [
      _scopeAll,
      ...(_buildingStructure[_assignedBuilding]?[_selectedFloor] ??
          const <String>[]),
    ];
  }

  /// รายการตำแหน่งที่ตรงกับ ชั้น/ห้อง ที่เลือกอยู่ตอนนี้ (อาคารคงที่แล้ว)
  List<String> get _filteredLocations {
    return _lightState.keys.where((key) {
      final parts = key.split(' · ');
      final building = parts[0];
      final floor = parts[1];
      final room = parts[2];
      if (building != _assignedBuilding) return false;
      if (_selectedFloor != _scopeAll && floor != _selectedFloor) {
        return false;
      }
      if (_selectedRoom != _scopeAll && room != _selectedRoom) return false;
      return true;
    }).toList();
  }

  /// จัดกลุ่มตำแหน่งที่กรองแล้วตามชั้น เรียงตามลำดับชั้นจริง (ไม่ใช่ตาม
  /// ลำดับสุ่มของ Map key) — ใช้ render เป็น section แยกแต่ละชั้น
  Map<String, List<String>> get _locationsByFloor {
    final grouped = <String, List<String>>{};
    final filtered = _filteredLocations;
    for (final floor
        in _buildingStructure[_assignedBuilding]?.keys ?? const <String>[]) {
      final locations = filtered
          .where((key) => key.split(' · ')[1] == floor)
          .toList();
      if (locations.isNotEmpty) grouped[floor] = locations;
    }
    return grouped;
  }

  int get _lightsOnCount =>
      _filteredLocations.where((l) => _lightState[l] == true).length;
  int get _waterOnCount =>
      _filteredLocations.where((l) => _waterState[l] == true).length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 18),
          _buildSummaryStats(),
          const SizedBox(height: 18),
          _buildPermissionDemoPanel(),
          const SizedBox(height: 14),
          _buildScopeFilterBar(),
          const SizedBox(height: 16),
          if (!_hasControlPermission) _buildReadOnlyBanner(),
          if (_filteredLocations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'ไม่พบตำแหน่งที่ตรงกับตัวเลือกนี้',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: FacilityTheme.softMauve,
                  ),
                ),
              ),
            )
          else
            for (final entry in _locationsByFloor.entries) ...[
              _buildFloorSectionHeader(entry.key, entry.value.length),
              const SizedBox(height: 10),
              FacilityResponsiveGrid(
                spacing: 14,
                minItemWidth: 280,
                children: [
                  for (final location in entry.value)
                    _ControlCard(
                      location: location,
                      lightOn: _lightState[location]!,
                      waterOn: _waterState[location]!,
                      hasPermission: _hasControlPermission,
                      onLightChanged: (v) =>
                          setState(() => _lightState[location] = v),
                      onWaterChanged: (v) =>
                          setState(() => _waterState[location] = v),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
        ],
      ),
    );
  }

  /// 🌈 Hero Header — ไล่เฉดสีน้ำเงินเข้มของธีม พร้อมไอคอนหลอดไฟเน้นสีทอง
  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FacilityTheme.primaryNavy, Color(0xFF2D6A85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: FacilityTheme.primaryNavy.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
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
              color: Color(0xFFE8A519),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ควบคุมไฟและน้ำ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'STK-11 · $_assignedBuilding',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 การ์ดสรุปสถิติ — ไฟ/น้ำเปิดอยู่กี่จุด จากทั้งหมดที่กรองอยู่ตอนนี้
  Widget _buildSummaryStats() {
    final total = _filteredLocations.length;
    return FacilityResponsiveGrid(
      spacing: 12,
      minItemWidth: 160,
      children: [
        _buildStatCard(
          icon: Icons.lightbulb_rounded,
          label: 'ไฟเปิดอยู่',
          value: '$_lightsOnCount / $total จุด',
          color: const Color(0xFFE8A519),
          bg: const Color(0xFFFFFBEB),
        ),
        _buildStatCard(
          icon: Icons.water_drop_rounded,
          label: 'น้ำเปิดอยู่',
          value: '$_waterOnCount / $total จุด',
          color: const Color(0xFF0284C7),
          bg: const Color(0xFFF0F9FF),
        ),
        _buildStatCard(
          icon: _hasControlPermission
              ? Icons.lock_open_rounded
              : Icons.lock_outline_rounded,
          label: 'สิทธิ์ปัจจุบัน',
          value: _hasControlPermission ? 'ควบคุมได้' : 'ดูอย่างเดียว',
          color: _hasControlPermission
              ? FacilityTheme.safeGreen
              : FacilityTheme.softMauve,
          bg: _hasControlPermission
              ? const Color(0xFFECFDF5)
              : FacilityTheme.bgSlate,
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
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
                    fontWeight: FontWeight.w700,
                    color: FacilityTheme.softMauve,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
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

  /// 🧪 แถบทดสอบสิทธิ์ (Demo เท่านั้น) — ตั้งใจให้ดูเป็น "แผงทดสอบ" แยกจาก
  /// UI จริง (เส้นประ + สีเรียบ) ไม่ใช่ฟีเจอร์ที่ผู้ใช้จริงจะเห็น เพราะสิทธิ์
  /// จริงมาจากบัญชีผู้ใช้ ไม่ใช่การกดสลับเอง
  Widget _buildPermissionDemoPanel() {
    return DottedBorderContainer(
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            size: 16,
            color: FacilityTheme.softMauve,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'แผงทดสอบสิทธิ์ (Demo เท่านั้น — ไม่ใช่ของจริง):',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: FacilityTheme.softMauve,
              ),
            ),
          ),
          _buildDemoChip(
            label: 'ดูอย่างเดียว',
            selected: !_hasControlPermission,
            color: FacilityTheme.warningOrange,
            onTap: () => setState(() => _hasControlPermission = false),
          ),
          const SizedBox(width: 6),
          _buildDemoChip(
            label: 'มีสิทธิ์ควบคุม',
            selected: _hasControlPermission,
            color: FacilityTheme.safeGreen,
            onTap: () => setState(() => _hasControlPermission = true),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? color : FacilityTheme.softMauve,
          ),
        ),
      ),
    );
  }

  /// 🏢 อาคารคงที่ตามที่รับผิดชอบ (ไม่มีทางเลือกอาคารอื่น) + ตัวเลือก
  /// ลำดับชั้น: ชั้น → ห้อง ภายในอาคารเดียวกันนี้เท่านั้น
  Widget _buildScopeFilterBar() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.apartment_rounded,
                size: 15,
                color: FacilityTheme.primaryPurple,
              ),
              SizedBox(width: 7),
              Text(
                _assignedBuilding,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: FacilityTheme.inkIndigo,
                ),
              ),
            ],
          ),
        ),
        _buildScopeDropdown(
          label: 'ชั้น:',
          value: _selectedFloor,
          options: _floorOptions,
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _selectedFloor = val;
              _selectedRoom = _scopeAll;
            });
          },
        ),
        _buildScopeDropdown(
          label: 'ห้อง:',
          value: _selectedRoom,
          options: _roomOptions,
          onChanged: _selectedFloor == _scopeAll
              ? null
              : (val) {
                  if (val == null) return;
                  setState(() => _selectedRoom = val);
                },
        ),
      ],
    );
  }

  Widget _buildReadOnlyBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: FacilityTheme.warningOrange,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'คุณไม่มีสิทธิ์ควบคุมอุปกรณ์นี้ ดูสถานะได้อย่างเดียว (Read-only Summary)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorSectionHeader(String floor, int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: FacilityTheme.primaryPurple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          floor,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: FacilityTheme.inkIndigo,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count จุด',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: FacilityTheme.softMauve,
          ),
        ),
      ],
    );
  }

  Widget _buildScopeDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: FacilityTheme.softMauve,
            ),
          ),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                color: onChanged == null
                    ? const Color(0xFFCBD5E1)
                    : FacilityTheme.primaryPurple,
              ),
              style: TextStyle(
                color: onChanged == null
                    ? const Color(0xFFCBD5E1)
                    : FacilityTheme.inkIndigo,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
              onChanged: onChanged,
              items: options.map((o) {
                return DropdownMenuItem(value: o, child: Text(o));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// กรอบเส้นประบางๆ ใช้แยก "แผงทดสอบ" ออกจาก UI จริงด้วยสายตา
class DottedBorderContainer extends StatelessWidget {
  const DottedBorderContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: FacilityTheme.bgSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
          width: 1.2,
          style: BorderStyle.solid,
        ),
      ),
      child: child,
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.location,
    required this.lightOn,
    required this.waterOn,
    required this.hasPermission,
    required this.onLightChanged,
    required this.onWaterChanged,
  });

  final String location;
  final bool lightOn;
  final bool waterOn;
  final bool hasPermission;
  final ValueChanged<bool> onLightChanged;
  final ValueChanged<bool> onWaterChanged;

  @override
  Widget build(BuildContext context) {
    // ห้องชื่อเดียว (ตัดส่วน "อาคาร · ชั้น" ออก เหลือแค่ห้อง/พื้นที่ —
    // อาคาร/ชั้นแสดงเป็น section header อยู่แล้วด้านบน ไม่ต้องซ้ำ)
    final roomLabel = location.split(' · ').last;
    final anyOn = lightOn || waterOn;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                color: anyOn
                    ? FacilityTheme.safeGreen
                    : const Color(0xFFCBD5E1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          roomLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: FacilityTheme.inkIndigo,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!hasPermission)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: FacilityTheme.bgSlate,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 12,
                                color: FacilityTheme.softMauve,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'ดูอย่างเดียว',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: FacilityTheme.softMauve,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ToggleRow(
                    icon: Icons.lightbulb_rounded,
                    label: 'ไฟ',
                    accentColor: const Color(0xFFE8A519),
                    value: lightOn,
                    hasPermission: hasPermission,
                    onChanged: onLightChanged,
                  ),
                  const SizedBox(height: 10),
                  _ToggleRow(
                    icon: Icons.water_drop_rounded,
                    label: 'น้ำ',
                    accentColor: const Color(0xFF0284C7),
                    value: waterOn,
                    hasPermission: hasPermission,
                    onChanged: onWaterChanged,
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.value,
    required this.hasPermission,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final bool value;
  final bool hasPermission;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? accentColor.withValues(alpha: 0.08)
            : FacilityTheme.bgSlate,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: value ? accentColor.withValues(alpha: 0.18) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: value ? accentColor : FacilityTheme.softMauve,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: FacilityTheme.inkIndigo,
              ),
            ),
          ),
          Text(
            value ? 'เปิดอยู่' : 'ปิดอยู่',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: value ? accentColor : FacilityTheme.softMauve,
            ),
          ),
          const SizedBox(width: 6),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: hasPermission
                  ? onChanged
                  : null, // Disabled when no permission
              activeColor: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
