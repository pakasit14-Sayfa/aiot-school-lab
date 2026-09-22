import 'package:flutter/material.dart';
import 'teacher_redesign_prototype_page.dart';

/// หน้าศูนย์รวมระบบดีไซน์และส่วนประกอบการออกแบบ (Design System & UI Component Showcase)
/// เป็นหน้า Standalone รวมโทนสี, ปุ่มมาตรฐานทุกรูปแบบ, การ์ดแจ้งเตือนทุกประเภท,
/// และการ์ดแสดงผล เพื่อให้คุณครูและทีมงานเลือกใช้งานได้อย่างเป็นเอกภาพเดียวกัน
class TeacherDesignSystemPage extends StatefulWidget {
  const TeacherDesignSystemPage({super.key});

  @override
  State<TeacherDesignSystemPage> createState() =>
      _TeacherDesignSystemPageState();
}

class _TeacherDesignSystemPageState extends State<TeacherDesignSystemPage> {
  int _selectedPointPill = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherPalette.page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: TeacherPalette.ink,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ระบบดีไซน์และส่วนประกอบการออกแบบ',
              style: TextStyle(
                color: TeacherPalette.ink,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            Text(
              'Design System & UI Component Showcase',
              style: TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎨 SECTION 1: PALETTE & COLOR TOKENS
            _buildSectionHeader(
              title: '1. โทนสีและสไตล์ดีไซน์ (Color Tokens & Theme)',
              subtitle: 'ฐานสีหลัก Ocean Navy 85% ผสานสีสถานะแจ้งเตือน 15%',
              icon: Icons.palette_rounded,
            ),
            const SizedBox(height: 12),
            _buildColorSwatchesCard(),
            const SizedBox(height: 28),

            // 🔘 SECTION 2: BUTTONS & BADGES
            _buildSectionHeader(
              title: '2. ปุ่มกดมาตรฐานและป้ายสถานะ (System Buttons & Badges)',
              subtitle: 'ปุ่มดำเนินการหลัก ปุ่มรอง ปุ่มลบ และป้ายบอกสถานะสากล',
              icon: Icons.smart_button_rounded,
            ),
            const SizedBox(height: 12),
            _buildButtonsAndBadgesCard(),
            const SizedBox(height: 28),

            // 🔔 SECTION 3: ALERT & NOTIFICATION BANNERS
            _buildSectionHeader(
              title: '3. การ์ดและแบนเนอร์แจ้งเตือนระบบ (Alert & Banners)',
              subtitle:
                  'การ์ดเตือนงานค้างตรวจ การ์ดแจ้งเตือนสำเร็จ การ์ดเตือนภัย',
              icon: Icons.notifications_active_rounded,
            ),
            const SizedBox(height: 12),
            _buildAlertBannersCard(),
            const SizedBox(height: 28),

            // 🎴 SECTION 4: CONTENT & QUESTION ITEM CARDS
            _buildSectionHeader(
              title: '4. การ์ดแสดงผลบทเรียนและข้อสอบ (Item & Question Cards)',
              subtitle: 'การ์ดใบงานความสูงเท่ากันเป๊ะ และการ์ดออกข้อสอบ',
              icon: Icons.space_dashboard_rounded,
            ),
            const SizedBox(height: 12),
            _buildContentCardsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TeacherPalette.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: TeacherPalette.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: TeacherPalette.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSwatchesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TeacherPalette.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'โทนสีหลักธีมระบบ (85% Theme Base)',
            style: TextStyle(
              color: TeacherPalette.ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ColorTile(
                  name: 'Violet Dark',
                  hex: '#542E85',
                  color: TeacherPalette.violet,
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ColorTile(
                  name: 'Mauve Primary',
                  hex: '#7448A6',
                  color: TeacherPalette.mauve,
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ColorTile(
                  name: 'Lavender Soft',
                  hex: '#C5A9DC',
                  color: TeacherPalette.lavender,
                  textColor: TeacherPalette.ink,
                  border: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'โทนสีฟังก์ชันแจ้งเตือน (15% Functional Accents)',
            style: TextStyle(
              color: TeacherPalette.ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ColorTile(
                  name: 'Success Mint',
                  hex: '#10B981',
                  color: TeacherPalette.green,
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ColorTile(
                  name: 'Warning Amber',
                  hex: '#F97316',
                  color: TeacherPalette.orange,
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ColorTile(
                  name: 'Alert Red',
                  hex: '#EF4444',
                  color: TeacherPalette.red,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsAndBadgesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TeacherPalette.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รูปแบบปุ่มกด (System Buttons)',
            style: TextStyle(
              color: TeacherPalette.ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Primary Button
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                label: const Text('ปุ่มหลัก (Primary Button)'),
                style: FilledButton.styleFrom(
                  backgroundColor: TeacherPalette.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              // Secondary Outlined Button
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('ปุ่มรอง (Outlined Button)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TeacherPalette.primary,
                  side: const BorderSide(color: TeacherPalette.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              // Danger Button
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('ปุ่มลบ (Danger Button)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TeacherPalette.red,
                  side: const BorderSide(color: TeacherPalette.red),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'ป้ายบอกสถานะและคะแนนสากล (Status Badges & LMS Point Pills)',
            style: TextStyle(
              color: TeacherPalette.ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // LMS Point Pill
              PopupMenuButton<int>(
                onSelected: (val) => setState(() => _selectedPointPill = val),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 1,
                    child: Text('1 คะแนน (มาตรฐาน)'),
                  ),
                  const PopupMenuItem(
                    value: 2,
                    child: Text('2 คะแนน (ปานกลาง)'),
                  ),
                  const PopupMenuItem(
                    value: 5,
                    child: Text('5 คะแนน (โจทย์ยาก)'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: TeacherPalette.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: TeacherPalette.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        size: 14,
                        color: TeacherPalette.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_selectedPointPill คะแนน',
                        style: const TextStyle(
                          color: TeacherPalette.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: TeacherPalette.green,
                      ),
                    ],
                  ),
                ),
              ),
              // Success Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TeacherPalette.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'เผยแพร่แล้ว',
                  style: TextStyle(
                    color: TeacherPalette.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              // Urgent Pending Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TeacherPalette.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'รอตรวจ 12 ชิ้น',
                  style: TextStyle(
                    color: TeacherPalette.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              // Draft Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TeacherPalette.skyDeep.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'ฉบับร่างครู',
                  style: TextStyle(
                    color: TeacherPalette.skyDeep,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBannersCard() {
    return Column(
      children: [
        // Urgent Action Banner (Orange)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TeacherPalette.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: TeacherPalette.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TeacherPalette.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'มี 12 งานส่งเข้ามาใหม่ รอคุณครูตรวจคะแนน',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'วิชา โครงงานเซนเซอร์ (PBL-110) · ปิดรับส่งแล้ว',
                      style: TextStyle(
                        color: TeacherPalette.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: TeacherPalette.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
                child: const Text('ตรวจงาน ->'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Success Alert Banner (Green)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TeacherPalette.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: TeacherPalette.green.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TeacherPalette.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เผยแพร่ข้อสอบก่อนเรียนเรียบร้อยแล้ว',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'นักเรียน 32 คนในห้อง ม.5/1 สามารถเริ่มทำข้อสอบได้ทันที',
                      style: TextStyle(
                        color: TeacherPalette.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Info System Banner (Blue)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TeacherPalette.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: TeacherPalette.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TeacherPalette.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ระบบสลับข้อสอบและตัวเลือกอัตโนมัติทำงานเปิดอยู่',
                      style: TextStyle(
                        color: TeacherPalette.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ป้องกันการลอกข้อสอบระหว่างทำ โดยสุ่มลำดับข้อและตัวเลือกให้นักเรียนแต่ละคนสดๆ',
                      style: TextStyle(
                        color: TeacherPalette.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Equal-Height Item Card Sample
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: TeacherPalette.border, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: TeacherPalette.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '📚 บทเรียน',
                      style: TextStyle(
                        color: TeacherPalette.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: TeacherPalette.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'เผยแพร่แล้ว',
                      style: TextStyle(
                        color: TeacherPalette.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'บทเรียนที่ 1: การต่อวงจรเซนเซอร์ GP2Y1014AU0F กับ Arduino',
                style: TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ส่งแล้ว 28/32 คน (87.5%) · มีไฟล์คลิปวิดีโอสาธิตประกอบ',
                style: TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: const LinearProgressIndicator(
                        value: 0.875,
                        minHeight: 6,
                        backgroundColor: TeacherPalette.page,
                        valueColor: AlwaysStoppedAnimation(
                          TeacherPalette.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text('ตรวจงาน'),
                    style: FilledButton.styleFrom(
                      backgroundColor: TeacherPalette.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.name,
    required this.hex,
    required this.color,
    required this.textColor,
    this.border = false,
  });

  final String name;
  final String hex;
  final Color color;
  final Color textColor;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: border ? Border.all(color: TeacherPalette.border) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hex,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
