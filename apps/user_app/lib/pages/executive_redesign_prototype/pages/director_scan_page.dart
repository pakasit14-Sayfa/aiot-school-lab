import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// หน้าสแกน QR / Barcode สำหรับสแกนครู-บุคลากร และชุดฝึก/อุปกรณ์
/// (โหมดสาธิต — กล้องจริงต้องเชื่อมต่ออุปกรณ์/สิทธิ์กล้องบนเครื่อง)
class DirectorScanPage extends StatefulWidget {
  const DirectorScanPage({super.key});

  @override
  State<DirectorScanPage> createState() => _DirectorScanPageState();
}

class _DirectorScanPageState extends State<DirectorScanPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanCtrl;

  int mode = 0; // 0 = ครู/บุคลากร, 1 = ชุดฝึก/อุปกรณ์
  bool flashOn = false;
  int _teacherIdx = 0;
  int _kitIdx = 0;

  final List<_ScanTeacher> teachers = const [
    _ScanTeacher(
      name: 'ครูสมชาย รักเรียน',
      code: 'T-1042',
      group: 'กลุ่มสาระวิทยาศาสตร์',
      position: 'ครูชำนาญการ',
      status: 'เข้างานแล้ว 07:52 น.',
      color: AppPalette.learningBlue,
    ),
    _ScanTeacher(
      name: 'ครูสมหญิง ใจดี',
      code: 'T-1088',
      group: 'กลุ่มสาระคณิตศาสตร์',
      position: 'ครูชำนาญการพิเศษ',
      status: 'เข้างานแล้ว 07:41 น.',
      color: AppPalette.primaryPink,
    ),
    _ScanTeacher(
      name: 'ครูวิชัย มั่นคง',
      code: 'T-1150',
      group: 'กลุ่มสาระการงานอาชีพ',
      position: 'ครู คศ.1',
      status: 'เข้างานแล้ว 08:05 น.',
      color: AppPalette.environmentGreen,
    ),
  ];

  final List<_ScanKit> kits = const [
    _ScanKit(
      name: 'ชุดฝึก Arduino IoT Starter',
      code: 'KIT-IOT-014',
      category: 'อิเล็กทรอนิกส์ / IoT',
      status: 'พร้อมใช้งาน',
      detail: 'ครบชุด • ยืมล่าสุด ม.5/2',
      color: AppPalette.chartCream,
    ),
    _ScanKit(
      name: 'ชุดฝึกหุ่นยนต์ RB-07',
      code: 'KIT-ROBOT-007',
      category: 'หุ่นยนต์ / เมคคาทรอนิกส์',
      status: 'กำลังถูกยืม',
      detail: 'ยืมโดย ม.6/1 • กำหนดคืน 25 ส.ค.',
      color: AppPalette.primaryPink,
    ),
    _ScanKit(
      name: 'ชุดฝึกเซนเซอร์สิ่งแวดล้อม',
      code: 'KIT-ENV-021',
      category: 'วิทยาศาสตร์สิ่งแวดล้อม',
      status: 'พร้อมใช้งาน',
      detail: 'ครบชุด • เก็บที่ห้องปฏิบัติการ 2',
      color: AppPalette.environmentGreen,
    ),
  ];

  final List<_RecentScan> recent = const [
    _RecentScan('ครูสมหญิง ใจดี', 'T-1088 • ครู', '09:14 น.', 'เข้างาน',
        Icons.badge_rounded, AppPalette.primaryPink),
    _RecentScan('ชุดฝึกหุ่นยนต์ RB-07', 'KIT-ROBOT-007 • ชุดฝึก', '08:50 น.',
        'คืนแล้ว', Icons.memory_rounded, AppPalette.learningBlue),
    _RecentScan('ครูวิชัย มั่นคง', 'T-1150 • ครู', '08:32 น.', 'เข้างาน',
        Icons.badge_rounded, AppPalette.environmentGreen),
  ];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'สแกน QR Code',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'วาง QR Code หรือ Barcode ให้อยู่ภายในกรอบ',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppPalette.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _modeToggle(),
                    const SizedBox(height: 16),
                    _viewfinder(),
                    const SizedBox(height: 12),
                    _statusStrip(),
                    const SizedBox(height: 14),
                    _simulateButton(),
                    const SizedBox(height: 14),
                    _quickActions(),
                    const SizedBox(height: 16),
                    _tipCard(),
                    const SizedBox(height: 18),
                    const Text(
                      'สแกนล่าสุด',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    ...recent.map(_recentTile),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.border),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สแกนข้อมูล',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  'AIoT Smart Lab',
                  style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppPalette.primaryPinkSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 20,
              color: AppPalette.primaryPinkDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          _modeTab('ครู / บุคลากร', Icons.badge_rounded, 0),
          _modeTab('ชุดฝึก / อุปกรณ์', Icons.memory_rounded, 1),
        ],
      ),
    );
  }

  Widget _modeTab(String label, IconData icon, int value) {
    final selected = mode == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => setState(() => mode = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppPalette.primaryPink : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppPalette.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppPalette.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewfinder() {
    return AspectRatio(
      aspectRatio: 1.06,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF23232B), Color(0xFF141418)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const inset = 26.0;
            final frameTop = inset;
            final frameBottom = constraints.maxHeight - inset - 40;

            return Stack(
              children: [
                // เส้นสแกนเคลื่อนไหว
                AnimatedBuilder(
                  animation: _scanCtrl,
                  builder: (context, _) {
                    final y = frameTop +
                        (frameBottom - frameTop) * _scanCtrl.value;
                    return Positioned(
                      left: inset,
                      right: inset,
                      top: y,
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppPalette.tint(AppPalette.primaryPink, 0.0),
                              AppPalette.primaryPink,
                              AppPalette.tint(AppPalette.primaryPink, 0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.tint(AppPalette.primaryPink, 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // มุมกรอบสีเหลือง
                _corner(top: inset, left: inset, alignTop: true, alignLeft: true),
                _corner(top: inset, right: inset, alignTop: true, alignLeft: false),
                _corner(
                    bottom: inset + 40, left: inset, alignTop: false, alignLeft: true),
                _corner(
                    bottom: inset + 40,
                    right: inset,
                    alignTop: false,
                    alignLeft: false),
                // ไอคอน + ข้อความกลางกรอบ
                Positioned(
                  left: 0,
                  right: 0,
                  top: frameTop + (frameBottom - frameTop) / 2 - 44,
                  child: Column(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: AppPalette.tint(Colors.white, 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          mode == 0
                              ? Icons.qr_code_scanner_rounded
                              : Icons.qr_code_2_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        mode == 0
                            ? 'เล็งกรอบไปที่บัตรครู / QR ประจำตัว'
                            : 'เล็งกรอบไปที่ป้ายชุดฝึก / บาร์โค้ด',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // แถบสถานะด้านล่างในกรอบ
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppPalette.tint(Colors.black, 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFC53D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ระบบกำลังค้นหารหัสอัตโนมัติ',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ป้ายโหมดสาธิต
                Positioned(
                  left: inset,
                  top: inset,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppPalette.tint(Colors.black, 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'โหมดสาธิต',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFC53D),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool alignTop,
    required bool alignLeft,
  }) {
    const yellow = Color(0xFFFFC53D);
    const side = BorderSide(color: yellow, width: 3.5);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: alignTop ? side : BorderSide.none,
            bottom: alignTop ? BorderSide.none : side,
            left: alignLeft ? side : BorderSide.none,
            right: alignLeft ? BorderSide.none : side,
          ),
        ),
      ),
    );
  }

  Widget _statusStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppPalette.primaryPinkSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 15, color: AppPalette.primaryPinkDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mode == 0
                  ? 'สแกนบัตรครู/บุคลากร เพื่อบันทึกเวลาเข้างานและยืนยันตัวตน'
                  : 'สแกนชุดฝึก/อุปกรณ์ เพื่อตรวจสอบสถานะ การยืม-คืน และที่จัดเก็บ',
              style: const TextStyle(
                fontSize: 9.5,
                height: 1.4,
                color: AppPalette.primaryPinkDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simulateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primaryPink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _simulateScan,
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
        label: Text(
          mode == 0 ? 'จำลองการสแกนครู' : 'จำลองการสแกนชุดฝึก',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            flashOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
            flashOn ? 'ปิดไฟ' : 'เปิดไฟ',
            () => setState(() => flashOn = !flashOn),
            active: flashOn,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            Icons.dialpad_rounded,
            'กรอกรหัส',
            _enterCodeManually,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickAction(
            Icons.cameraswitch_rounded,
            'สลับกล้อง',
            () => _showMessage('ตัวอย่าง: สลับกล้องหน้า/หลัง'),
          ),
        ),
      ],
    );
  }

  Widget _quickAction(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppPalette.primaryPink : AppPalette.border,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: active
                    ? AppPalette.primaryPink
                    : AppPalette.primaryPinkSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 19,
                color: active ? Colors.white : AppPalette.primaryPinkDark,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.softCream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppPalette.tint(Colors.white, 0.7),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.tips_and_updates_rounded,
                size: 18, color: AppPalette.warning),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เคล็ดลับการสแกน',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  'ถือโทรศัพท์ให้นิ่ง เว้นระยะห่าง 15 - 25 ซม. และเปิดไฟเมื่ออยู่ในที่แสงน้อย เพื่อให้จับรหัสได้เร็วขึ้น',
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.5,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentTile(_RecentScan item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppPalette.tint(item.color, 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8.6,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.time,
                style: const TextStyle(
                  fontSize: 8.5,
                  color: AppPalette.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppPalette.tint(AppPalette.success, 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------

  void _simulateScan() {
    if (mode == 0) {
      final teacher = teachers[_teacherIdx % teachers.length];
      _teacherIdx++;
      _showTeacherResult(teacher);
    } else {
      final kit = kits[_kitIdx % kits.length];
      _kitIdx++;
      _showKitResult(kit);
    }
  }

  void _enterCodeManually() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('กรอกรหัสด้วยตนเอง',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: mode == 0 ? 'เช่น T-1042' : 'เช่น KIT-IOT-014',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.primaryPink,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _simulateScan();
              },
              child: const Text('ค้นหา'),
            ),
          ],
        );
      },
    );
  }

  void _showTeacherResult(_ScanTeacher t) {
    _showResultSheet(
      accent: t.color,
      icon: Icons.badge_rounded,
      typeLabel: 'บัตรครู / บุคลากร',
      title: t.name,
      code: t.code,
      status: t.status,
      statusColor: AppPalette.success,
      rows: [
        ['กลุ่มสาระ', t.group],
        ['ตำแหน่ง', t.position],
        ['รหัสประจำตัว', t.code],
      ],
      primaryLabel: 'บันทึกเวลาเข้างาน',
    );
  }

  void _showKitResult(_ScanKit k) {
    final available = k.status == 'พร้อมใช้งาน';
    _showResultSheet(
      accent: k.color,
      icon: Icons.memory_rounded,
      typeLabel: 'ชุดฝึก / อุปกรณ์',
      title: k.name,
      code: k.code,
      status: k.status,
      statusColor: available ? AppPalette.success : AppPalette.warning,
      rows: [
        ['หมวดหมู่', k.category],
        ['รหัสอุปกรณ์', k.code],
        ['รายละเอียด', k.detail],
      ],
      primaryLabel: available ? 'บันทึกการยืม' : 'ดูประวัติการยืม',
    );
  }

  void _showResultSheet({
    required Color accent,
    required IconData icon,
    required String typeLabel,
    required String title,
    required String code,
    required String status,
    required Color statusColor,
    required List<List<String>> rows,
    required String primaryLabel,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppPalette.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    'สแกนสำเร็จ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    typeLabel,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppPalette.tint(accent, 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: accent, size: 27),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppPalette.tint(statusColor, 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppPalette.pageBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPalette.border),
                ),
                child: Column(
                  children: [
                    for (final row in rows) _sheetRow(row[0], row[1]),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('ปิด'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.primaryPink,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showMessage('$primaryLabel • $title เรียบร้อย');
                      },
                      child: Text(
                        primaryLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// -----------------------------------------------------------------------------
// MODELS
// -----------------------------------------------------------------------------

class _ScanTeacher {
  final String name;
  final String code;
  final String group;
  final String position;
  final String status;
  final Color color;

  const _ScanTeacher({
    required this.name,
    required this.code,
    required this.group,
    required this.position,
    required this.status,
    required this.color,
  });
}

class _ScanKit {
  final String name;
  final String code;
  final String category;
  final String status;
  final String detail;
  final Color color;

  const _ScanKit({
    required this.name,
    required this.code,
    required this.category,
    required this.status,
    required this.detail,
    required this.color,
  });
}

class _RecentScan {
  final String title;
  final String subtitle;
  final String time;
  final String status;
  final IconData icon;
  final Color color;

  const _RecentScan(
    this.title,
    this.subtitle,
    this.time,
    this.status,
    this.icon,
    this.color,
  );
}
