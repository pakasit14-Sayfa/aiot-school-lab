import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'teacher_redesign_prototype_page.dart';
import 'teacher_assignment_editor_page.dart';
import 'teacher_shared_widgets.dart';

/// Master Design System & Storybook Workbench (รวมหน้าสรุปดีไซน์ + Mews Storybook)
/// รวมทุกอย่างไว้ในที่เดียว ทั้งภาพรวมโทนสี 85/15%, ปุ่มทั้งหมด, การ์ดแจ้งเตือนทุกสี,
/// และ Mews Interactive Grid Canvas + Controls Table สามารถสลับดูได้ใน Sidebar เดียวกัน!
class TeacherStorybookPage extends StatefulWidget {
  const TeacherStorybookPage({super.key});

  @override
  State<TeacherStorybookPage> createState() => _TeacherStorybookPageState();
}

class _TeacherStorybookPageState extends State<TeacherStorybookPage> {
  // Navigation State
  String _selectedComponent = 'System Overview';
  String _selectedStory = 'Overview Gallery';

  // Storybook Bottom Tab State
  int _selectedTabIdx =
      0; // 0: Controls, 1: Actions, 2: Interactions, 3: Accessibility

  // Interactive Control States (Knobs)
  bool _closeNestedOnClickAway = true;
  bool _closeOnSelect = true;
  bool _isDisabled = false;
  final bool _isLoading = false;
  String _buttonLabel = 'A very long action label that truncates';

  // Dropdown Gallery State
  final List<String> _galleryDropdownOptions = const [
    '6. 🌐 Full System Overview (แสดงผลรวม 10 รูปแบบในหน้าเดียว)',
    '1. 📊 Nutrient & Metric Summaries (Gauges & Rings)',
    '2. 🎛️ Analytics & Calendar Dashboard Widgets',
    '3. 🔘 Master Button Matrix (13 Actions x 4 States)',
    '4. ⚡ Automation Workflow Node Cards (Triggers & Actions)',
    '5. 🔔 Modern Soft & Minimalist Toast Notifications',
    '7. 💎 Soft Glassmorphism Assignment Cards (การ์ดจัดการใบงาน)',
    '8. 📚 Active Classes & Course Cards (การ์ดห้องเรียนและรายวิชา)',
    '9. 📲 Modern Three-Dots Action Menu (เมนูปุ่ม 3 จุด แก้ไข/ลบ)',
    '10. 🏷️ Animated Status Badges (ป้ายแอนิเมชัน 6 สถานะ)',
    '11. 📈 Single-Line Combined Water-Electricity Score Chart (การ์ดคะแนนน้ำ-ไฟเส้นเดียวผสมส้ม-ฟ้า)',
  ];
  String _selectedGalleriesDropdown =
      '6. 🌐 Full System Overview (แสดงผลรวม 10 รูปแบบในหน้าเดียว)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // 📁 LEFT SIDEBAR: Navigation Tree View
          _buildMewsSidebarTree(),

          // 📐 RIGHT CONTENT AREA
          Expanded(
            child:
                (_selectedComponent == 'System Overview' ||
                    _selectedComponent.startsWith('1.') ||
                    _selectedComponent.startsWith('2.') ||
                    _selectedComponent.startsWith('3.') ||
                    _selectedComponent.startsWith('4.') ||
                    _selectedComponent.startsWith('5.'))
                ? _buildFullDesignSystemOverview(context)
                : Column(
                    children: [
                      // Top Grid Canvas Window
                      Expanded(
                        flex: 5,
                        child: Stack(
                          children: [
                            Container(
                              color: const Color(0xFFFAFBFD),
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            CustomPaint(
                              size: Size.infinite,
                              painter: _MewsGridPainter(),
                            ),
                            Center(child: _buildMewsComponentSample()),
                          ],
                        ),
                      ),
                      Container(height: 1, color: const Color(0xFFE2E8F0)),
                      // Bottom Controls Table
                      Expanded(
                        flex: 5,
                        child: Container(
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMewsTabBar(),
                              const Divider(
                                height: 1,
                                color: Color(0xFFE2E8F0),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: _buildMewsControlsTable(),
                                ),
                              ),
                            ],
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

  Widget _buildFullDesignSystemOverview(BuildContext context) {
    return Container(
      color: TeacherPalette.page,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TeacherPalette.border, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F0F172A),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.style_rounded,
                    size: 28,
                    color: TeacherPalette.primary,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ศูนย์รวมระบบดีไซน์และส่วนประกอบทั้งหมด (System Overview)',
                          style: TextStyle(
                            color: TeacherPalette.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'แสดงผลส่วนประกอบดีไซน์ทั้งหมดในหน้าเดียว (โทนสี 85/15%, ปุ่มทุกแบบ, การ์ดเตือนทุกสี, อินพุตฟอร์ม, อวตารโปรไฟล์, และการ์ดแสดงผล)',
                          style: TextStyle(
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
            ),
            // 🔽 TOP GALLERIES DROPDOWN SELECTOR BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: TeacherPalette.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F0F172A),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.collections_rounded,
                    color: TeacherPalette.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'เลือกสลับแกลเลอรีดีไซน์ตามรูปภาพ:',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGalleriesDropdown,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down_circle_rounded,
                          color: TeacherPalette.primary,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: TeacherPalette.ink,
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedGalleriesDropdown = val);
                          }
                        },
                        items: _galleryDropdownOptions.map((opt) {
                          return DropdownMenuItem<String>(
                            value: opt,
                            child: Text(
                              opt,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // DYNAMIC GALLERY DISPLAY BASED ON DROPDOWN SELECTION
            if (_selectedGalleriesDropdown.startsWith('1.') ||
                _selectedGalleriesDropdown.startsWith('6.')) ...[
              _buildSectionHeader(
                '1. Nutrient & Score Metric Summaries (Gauges & Rings)',
                'สร้างจากภาพถ่ายหน้าจอ Jordi Plaza (Score, Arc Gauge, Rings)',
                Icons.donut_large_rounded,
              ),
              const SizedBox(height: 12),
              _buildNutrientScoreSummariesCard(),
              const SizedBox(height: 24),
            ],

            if (_selectedGalleriesDropdown.startsWith('2.') ||
                _selectedGalleriesDropdown.startsWith('6.')) ...[
              _buildSectionHeader(
                '2. Analytics & Calendar Dashboard Widgets Collection',
                'สร้างจากภาพถ่ายหน้าจอ Dashboard Widgets (Insights, 3D Date, Charts)',
                Icons.dashboard_customize_rounded,
              ),
              const SizedBox(height: 12),
              _buildDashboardWidgetsCollectionCard(),
              const SizedBox(height: 24),
            ],

            if (_selectedGalleriesDropdown.startsWith('3.') ||
                _selectedGalleriesDropdown.startsWith('6.')) ...[
              _buildSectionHeader(
                '3. Master Button Design System Matrix (13 Actions x 4 States)',
                'สร้างจากภาพถ่ายหน้าจอ Master Buttons (Ghost, Outlined, Soft, Solid)',
                Icons.grid_view_rounded,
              ),
              const SizedBox(height: 12),
              _buildMasterButtonMatrixCard(context),
              const SizedBox(height: 24),
            ],

            if (_selectedGalleriesDropdown.startsWith('4.') ||
                _selectedGalleriesDropdown.startsWith('6.')) ...[
              _buildSectionHeader(
                '4. Automation Workflow Node Cards (Triggers, Actions & Outputs)',
                'สร้างจากภาพถ่ายหน้าจอ Automation Node Cards (POST Webhook, Notion, Audio, Image)',
                Icons.account_tree_rounded,
              ),
              const SizedBox(height: 12),
              _buildWorkflowNodeCardsCard(context),
              const SizedBox(height: 24),
            ],

            if (_selectedGalleriesDropdown.startsWith('5.') ||
                _selectedGalleriesDropdown.startsWith('6.')) ...[
              _buildSectionHeader(
                '5. Modern Soft & Minimalist Toast Notifications',
                'สร้างจากภาพถ่ายหน้าจอ Toast Alert Banners (Success, Warning, Info, Alert)',
                Icons.notifications_rounded,
              ),
              const SizedBox(height: 12),
              _buildModernToastAlertsCard(),
              const SizedBox(height: 24),
            ],

            if (_selectedGalleriesDropdown.startsWith('7.') ||
                _selectedGalleriesDropdown.startsWith('6.')) ...[
              _buildSectionHeader(
                '12. 💎 Soft Glassmorphism Assignment Cards (การ์ดจัดการใบงานและโจทย์ทดลอง)',
                'การ์ดสไตล์กระจก Soft Glassmorphic พร้อมป้ายพาสเทล ชิปเซนเซอร์ AIoT และหลอดความคืบหน้า',
                Icons.assignment_rounded,
              ),
              const SizedBox(height: 12),
              _buildSoftGlassAssignmentCardsSection(),
              const SizedBox(height: 24),
            ],

            if (_selectedGalleriesDropdown.startsWith('8.') ||
                _selectedGalleriesDropdown.startsWith('6.')) ...[
              _buildSectionHeader(
                '13. 📚 Active Classes & Course Cards (การ์ดห้องเรียนและรายวิชา)',
                'การ์ดวิชาเรียนแบบไล่เฉดสี Gradient พร้อมรหัสวิชา จำนวนนักเรียน และป้ายแจ้งเตือนงานค้าง',
                Icons.menu_book_rounded,
              ),
              const SizedBox(height: 12),
              _buildClassesCarouselSection(),
              const SizedBox(height: 24),
            ],

            if (_selectedGalleriesDropdown.startsWith('9.') ||
                _selectedGalleriesDropdown.startsWith('6.')) ...[
              _buildSectionHeader(
                '14. 📲 Modern Three-Dots Action Menu (เมนูปุ่ม 3 จุด แก้ไข/ลบ)',
                'เมนูปุ่ม 3 จุดทรงเรียบหรู พร้อมการแบ่งกลุ่มคำสั่ง (แก้ไข, ทำซ้ำ, ดูรายละเอียด, แชร์, ลบสีแดงเตือน)',
                Icons.more_vert_rounded,
              ),
              const SizedBox(height: 12),
              _buildThreeDotsActionMenuSection(context),
              const SizedBox(height: 24),
            ],

            if (_selectedGalleriesDropdown.startsWith('10.') ||
                _selectedGalleriesDropdown.startsWith('6.')) ...[
              _buildSectionHeader(
                '15. 🏷️ Animated Status Badges & Pills (ป้ายแอนิเมชัน 6 สถานะ)',
                'ป้ายบอกสถานะเคลื่อนไหว (สำเร็จ, ไม่สำเร็จ, กำลังโหลด, กำลังอัปโหลด, อัปโหลดไม่สำเร็จ, โหลดไม่สำเร็จ)',
                Icons.label_important_rounded,
              ),
              const SizedBox(height: 12),
              _buildAnimatedStatusBadgesSection(context),
              const SizedBox(height: 24),
            ],

            if (_selectedGalleriesDropdown.startsWith('11.') ||
                _selectedGalleriesDropdown.startsWith('6.')) ...[
              _buildSectionHeader(
                '16. 📈 Single-Line Combined Utility Score Chart (การ์ดคะแนนน้ำ-ไฟเส้นเดียวผสมส้ม-ฟ้า)',
                'การ์ดแสดงคะแนนการใช้น้ำ-ไฟเส้นเดียวกราฟโค้งมนผสมสีส้ม-ฟ้า พร้อมระดับคะแนน 45 (ควรปรับปรุง) และไฮไลต์วัน ศ.',
                Icons.analytics_rounded,
              ),
              const SizedBox(height: 12),
              const InteractiveSingleLineScoreCard(),
              const SizedBox(height: 24),
            ],

            if (_selectedGalleriesDropdown.startsWith('6.')) ...[
              _buildSectionHeader(
                '6. โทนสีและสไตล์ดีไซน์ (Color Tokens & Theme)',
                'ฐานสีหลัก Ocean Navy 85% ผสานสีสถานะ 15%',
                Icons.palette_rounded,
              ),
              const SizedBox(height: 12),
              _buildColorSwatchesCard(),
              const SizedBox(height: 24),

              _buildSectionHeader(
                '7. ปุ่มกดมาตรฐานและป้ายสถานะ (System Buttons & Badges)',
                'ปุ่มดำเนินการหลัก ปุ่มรอง ปุ่มลบ และป้ายบอกสถานะสากล',
                Icons.smart_button_rounded,
              ),
              const SizedBox(height: 12),
              _buildButtonsAndBadgesCard(),
              const SizedBox(height: 24),

              _buildSectionHeader(
                '8. การ์ดและแบนเนอร์แจ้งเตือนระบบ (Alert & Banners)',
                'แบนเนอร์เตือนสีส้ม เขียว ฟ้า แดง ครบทุกรูปแบบ',
                Icons.notifications_active_rounded,
              ),
              const SizedBox(height: 12),
              _buildAlertBannersCard(),
              const SizedBox(height: 24),

              _buildSectionHeader(
                '9. สื่อและรูปโปรไฟล์ผู้ใช้งาน (Media & Avatars)',
                'อวตารทุกขนาด ตัวอักษรย่อ สถานะออนไลน์ และ Avatar Group',
                Icons.account_circle_rounded,
              ),
              const SizedBox(height: 12),
              _buildMediaAvatarsOverviewCard(),
              const SizedBox(height: 24),

              _buildSectionHeader(
                '10. ระบบแบบฟอร์มและการรับข้อมูล (Form Controls & Inputs)',
                'ช่องกรอกข้อความ รหัสผ่าน ช่องค้นหา Checkbox, Radio, Switch',
                Icons.edit_note_rounded,
              ),
              const SizedBox(height: 12),
              _buildInputsOverviewCard(),
              const SizedBox(height: 24),

              _buildSectionHeader(
                '11. การ์ดแสดงผลบทเรียนและข้อสอบ (Item & Question Cards)',
                'การ์ดใบงานความสูงเท่ากันเป๊ะ 100% และการ์ดโจทย์ข้อสอบ',
                Icons.space_dashboard_rounded,
              ),
              const SizedBox(height: 12),
              _buildContentCardsSection(),
              const SizedBox(height: 36),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: TeacherPalette.ink,
                fontWeight: FontWeight.w900,
                fontSize: 15.5,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TeacherPalette.border),
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
          const Row(
            children: [
              Expanded(
                child: _ColorTile(
                  name: 'Primary Ocean',
                  hex: '#235284',
                  color: TeacherPalette.primary,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ColorTile(
                  name: 'Sky Bright',
                  hex: '#B8E2F4',
                  color: TeacherPalette.skyBright,
                  textColor: TeacherPalette.ink,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ColorTile(
                  name: 'Page Slate',
                  hex: '#F8FAFC',
                  color: TeacherPalette.page,
                  textColor: TeacherPalette.ink,
                  border: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'โทนสีฟังก์ชันแจ้งเตือน (15% Functional Accents)',
            style: TextStyle(
              color: TeacherPalette.ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: _ColorTile(
                  name: 'Success Mint',
                  hex: '#10B981',
                  color: TeacherPalette.green,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _ColorTile(
                  name: 'Warning Amber',
                  hex: '#F97316',
                  color: TeacherPalette.orange,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(width: 8),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                label: const Text('ปุ่มหลัก (Primary Button)'),
                style: FilledButton.styleFrom(
                  backgroundColor: TeacherPalette.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
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
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
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
                    fontSize: 11.5,
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
                    Text(
                      'วิชา โครงงานเซนเซอร์ (PBL-110)',
                      style: TextStyle(
                        color: TeacherPalette.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: TeacherPalette.orange,
                ),
                child: const Text('ตรวจงาน ->'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentCardsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'บทเรียนที่ 1: การต่อวงจรเซนเซอร์ GP2Y1014AU0F',
            style: TextStyle(
              color: TeacherPalette.ink,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            label: const Text('ตรวจงาน'),
            style: FilledButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
            ),
          ),
        ],
      ),
    );
  }

  // --- LEFT SIDEBAR TREE VIEW ---
  Widget _buildMewsSidebarTree() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mews & Design',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Storybook Workbench',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildCategoryHeader('GETTING STARTED'),
                _buildTreeStoryItem(
                  'System Overview',
                  'Overview Gallery',
                  _selectedComponent == 'System Overview',
                ),
                _buildTreeStoryItem(
                  'Welcome',
                  'Introduction',
                  _selectedStory == 'Introduction',
                ),
                _buildTreeStoryItem(
                  'Design Tokens',
                  'Colors & Spacing',
                  _selectedStory == 'Colors & Spacing',
                ),
                const SizedBox(height: 12),

                _buildCategoryHeader(
                  'IMAGE DESIGN GALLERIES (5 ต้นแบบภาพถ่าย)',
                ),
                _buildTreeStoryItem(
                  '1. Nutrient & Score Gauges',
                  'Jordi Plaza Image',
                  _selectedComponent == '1. Nutrient & Score Gauges',
                ),
                _buildTreeStoryItem(
                  '2. Dashboard & Calendar Widgets',
                  'Dashboard Widgets Image',
                  _selectedComponent == '2. Dashboard & Calendar Widgets',
                ),
                _buildTreeStoryItem(
                  '3. Master Button Matrix (13x4)',
                  'Master Buttons Image',
                  _selectedComponent == '3. Master Button Matrix (13x4)',
                ),
                _buildTreeStoryItem(
                  '4. Workflow Node Automation',
                  'Node Cards Image',
                  _selectedComponent == '4. Workflow Node Automation',
                ),
                _buildTreeStoryItem(
                  '5. Modern Toast Notifications',
                  'Toast Banners Image',
                  _selectedComponent == '5. Modern Toast Notifications',
                ),
                const SizedBox(height: 12),

                _buildCategoryHeader('BUTTONS & ACTIONS'),
                _buildTreeComponentFolder(
                  'Button',
                  stories: [
                    'Playground',
                    'Master 13x4 Matrix',
                    'Primary',
                    'Secondary',
                    'Clear/Ghost',
                    'Critical',
                    'Sizes',
                    'Loading State',
                    'Disabled State',
                  ],
                  isOpen: _selectedComponent == 'Button',
                ),
                _buildTreeComponentFolder(
                  'Dropdown Button',
                  stories: [
                    'Playground',
                    'Playground With Groups',
                    'Truncated label',
                    'Icon Only',
                    'Full Width',
                  ],
                  isOpen: _selectedComponent == 'Dropdown Button',
                ),
                _buildTreeComponentFolder(
                  'Icon Button',
                  stories: [
                    'Playground',
                    'Icon Only Variants',
                    'Primary',
                    'Ghost',
                  ],
                  isOpen: _selectedComponent == 'Icon Button',
                ),
                _buildTreeComponentFolder(
                  'Split Button',
                  stories: ['Playground', 'With Menu'],
                  isOpen: _selectedComponent == 'Split Button',
                ),
                _buildTreeComponentFolder(
                  'Action List',
                  stories: ['Playground', 'Item With Icon', 'Item With Badge'],
                  isOpen: _selectedComponent == 'Action List',
                ),
                _buildTreeComponentFolder(
                  'Segmented Control',
                  stories: [
                    'Playground',
                    '2 Options',
                    '3 Options',
                    '4 Options',
                  ],
                  isOpen: _selectedComponent == 'Segmented Control',
                ),
                const SizedBox(height: 12),

                _buildCategoryHeader('FEEDBACK & NOTIFICATIONS'),
                _buildTreeComponentFolder(
                  'Alerts',
                  stories: [
                    'Overview',
                    'Playground',
                    'Success Alert',
                    'Warning Alert',
                    'Info Alert',
                    'Critical Alert',
                    'With Action',
                    'Dismissible',
                  ],
                  isOpen: _selectedComponent == 'Alerts',
                ),
                _buildTreeComponentFolder(
                  'Badge',
                  stories: [
                    'Overview',
                    'Playground',
                    'Numeric Badge',
                    'Status Badge',
                    'Dot Badge',
                  ],
                  isOpen: _selectedComponent == 'Badge',
                ),
                _buildTreeComponentFolder(
                  'Banner',
                  stories: [
                    'Overview',
                    'Playground',
                    'Top Fixed Banner',
                    'Inline Banner',
                  ],
                  isOpen: _selectedComponent == 'Banner',
                ),
                _buildTreeComponentFolder(
                  'Chip',
                  stories: [
                    'Playground',
                    'Filter Chip',
                    'Choice Chip',
                    'Removable Chip',
                  ],
                  isOpen: _selectedComponent == 'Chip',
                ),
                _buildTreeComponentFolder(
                  'Empty State',
                  stories: [
                    'Overview',
                    'Playground',
                    'No Data',
                    'No Search Results',
                  ],
                  isOpen: _selectedComponent == 'Empty State',
                ),
                _buildTreeComponentFolder(
                  'Progress Indicator',
                  stories: [
                    'Playground',
                    'Linear Progress',
                    'Circular Spinner',
                  ],
                  isOpen: _selectedComponent == 'Progress Indicator',
                ),
                _buildTreeComponentFolder(
                  'Skeleton Loading',
                  stories: ['Playground', 'Card Skeleton', 'List Skeleton'],
                  isOpen: _selectedComponent == 'Skeleton Loading',
                ),
                _buildTreeComponentFolder(
                  'Tooltip',
                  stories: ['Playground', 'Top Tooltip', 'Bottom Tooltip'],
                  isOpen: _selectedComponent == 'Tooltip',
                ),
                const SizedBox(height: 12),

                _buildCategoryHeader('INPUTS & FORMS'),
                _buildTreeComponentFolder(
                  'Text Input',
                  stories: [
                    'Playground',
                    'Default Input',
                    'Password Input',
                    'Search Input',
                    'Error Input',
                    'Disabled Input',
                  ],
                  isOpen: _selectedComponent == 'Text Input',
                ),
                _buildTreeComponentFolder(
                  'Text Area',
                  stories: ['Playground', 'Multi-line Input'],
                  isOpen: _selectedComponent == 'Text Area',
                ),
                _buildTreeComponentFolder(
                  'Select / Dropdown',
                  stories: ['Playground', 'Single Select', 'Multi Select'],
                  isOpen: _selectedComponent == 'Select / Dropdown',
                ),
                _buildTreeComponentFolder(
                  'Checkbox',
                  stories: ['Playground', 'Checked', 'Unchecked', 'Disabled'],
                  isOpen: _selectedComponent == 'Checkbox',
                ),
                _buildTreeComponentFolder(
                  'Radio Button',
                  stories: ['Playground', 'Radio Group'],
                  isOpen: _selectedComponent == 'Radio Button',
                ),
                _buildTreeComponentFolder(
                  'Switch / Toggle',
                  stories: ['Playground', 'On State', 'Off State'],
                  isOpen: _selectedComponent == 'Switch / Toggle',
                ),
                const SizedBox(height: 12),

                _buildCategoryHeader('MEDIA'),
                _buildTreeComponentFolder(
                  'Avatar',
                  stories: [
                    'Overview',
                    'Playground',
                    'Fallback Initials',
                    'Status Indicator',
                    'Sizes',
                  ],
                  isOpen: _selectedComponent == 'Avatar',
                ),
                _buildTreeComponentFolder(
                  'Avatar Group',
                  stories: ['Overview', 'Playground'],
                  isOpen: _selectedComponent == 'Avatar Group',
                ),
                const SizedBox(height: 12),

                _buildCategoryHeader('NAVIGATION & CARDS'),
                _buildTreeComponentFolder(
                  'Tabs',
                  stories: ['Playground', 'Horizontal Tabs', 'Icon Tabs'],
                  isOpen: _selectedComponent == 'Tabs',
                ),
                _buildTreeComponentFolder(
                  'Card',
                  stories: [
                    'Overview',
                    'Soft Glass Assignment Card',
                    'Interactive Card',
                    'Equal-Height Card',
                  ],
                  isOpen: _selectedComponent == 'Card',
                ),
                _buildTreeComponentFolder(
                  'Modal / Dialog',
                  stories: ['Playground', 'Confirmation Modal', 'Form Modal'],
                  isOpen: _selectedComponent == 'Modal / Dialog',
                ),
                _buildTreeComponentFolder(
                  'Drawer / Sheet',
                  stories: ['Playground', 'Bottom Sheet', 'Side Drawer'],
                  isOpen: _selectedComponent == 'Drawer / Sheet',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTreeComponentFolder(
    String folderName, {
    required List<String> stories,
    bool isOpen = false,
  }) {
    final isSelectedFolder = _selectedComponent == folderName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() {
            _selectedComponent = folderName;
            _selectedStory = stories.first;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Icon(
                  isOpen
                      ? Icons.indeterminate_check_box_outlined
                      : Icons.add_box_outlined,
                  size: 14,
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Text(
                  folderName,
                  style: TextStyle(
                    color: isSelectedFolder
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF1E293B),
                    fontWeight: isSelectedFolder
                        ? FontWeight.w800
                        : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Column(
            children: stories.map((story) {
              return _buildTreeStoryItem(
                folderName,
                story,
                _selectedStory == story && isSelectedFolder,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTreeStoryItem(
    String componentName,
    String storyName,
    bool isSelected,
  ) {
    return Material(
      color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          _selectedComponent = componentName;
          _selectedStory = storyName;
          if (componentName.startsWith('1.')) {
            _selectedGalleriesDropdown = _galleryDropdownOptions[1];
          }
          if (componentName.startsWith('2.')) {
            _selectedGalleriesDropdown = _galleryDropdownOptions[2];
          }
          if (componentName.startsWith('3.')) {
            _selectedGalleriesDropdown = _galleryDropdownOptions[3];
          }
          if (componentName.startsWith('4.')) {
            _selectedGalleriesDropdown = _galleryDropdownOptions[4];
          }
          if (componentName.startsWith('5.')) {
            _selectedGalleriesDropdown = _galleryDropdownOptions[5];
          }
          if (componentName == 'System Overview') {
            _selectedGalleriesDropdown = _galleryDropdownOptions[0];
          }
          if (storyName == 'Master 13x4 Matrix') {
            _selectedComponent = '3. Master Button Matrix (13x4)';
            _selectedGalleriesDropdown = _galleryDropdownOptions[3];
          }
        }),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 38,
            right: 16,
            top: 7,
            bottom: 7,
          ),
          child: Row(
            children: [
              Icon(
                Icons.bookmark_outline_rounded,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  storyName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CENTER CANVAS SAMPLE: UNIQUE REAL COMPONENT FOR EVERY STORY ---
  Widget _buildMewsComponentSample() {
    final comp = _selectedComponent;
    final story = _selectedStory;

    // --- BUTTONS ---
    if (comp == 'Button') {
      if (story == 'Secondary') {
        return OutlinedButton(
          onPressed: _isDisabled
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(_buttonLabel),
        );
      } else if (story == 'Clear/Ghost') {
        return TextButton(
          onPressed: _isDisabled
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(_buttonLabel),
        );
      } else if (story == 'Critical') {
        return FilledButton.icon(
          onPressed: _isDisabled
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text('Delete Item'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (story == 'Sizes') {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontSize: 11),
              ),
              child: const Text('Small (32px)'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: const Text('Medium (40px)'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontSize: 15),
              ),
              child: const Text('Large (48px)'),
            ),
          ],
        );
      } else if (story == 'Loading State') {
        return FilledButton(
          onPressed: null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        );
      }
      return FilledButton(
        onPressed: _isDisabled
            ? null
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(_buttonLabel),
      );
    }

    // --- DROPDOWN BUTTON ---
    if (comp == 'Dropdown Button') {
      if (story == 'Playground With Groups') {
        return const _MewsGroupedListSample();
      }
      if (story == 'Icon Only') {
        return FilledButton(
          onPressed: _isDisabled
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.all(14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Icon(Icons.more_vert_rounded, size: 20),
        );
      }
      if (story == 'Full Width') {
        return SizedBox(
          width: 380,
          child: FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Text('Full Width Action Dropdown'),
            label: const Icon(Icons.keyboard_arrow_down_rounded),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }
      return Container(
        constraints: const BoxConstraints(maxWidth: 240),
        child: FilledButton.icon(
          onPressed: _isDisabled
              ? null
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          icon: _isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const SizedBox.shrink(),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _buttonLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ],
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    // --- ICON BUTTON ---
    if (comp == 'Icon Button') {
      if (story == 'Icon Only Variants') {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filled(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
            ),
            const SizedBox(width: 10),
            IconButton.outlined(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.edit_rounded),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.share_rounded),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline_rounded),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
            ),
          ],
        );
      }
      return IconButton.filled(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.star_rounded),
        style: IconButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
      );
    }

    // --- SPLIT BUTTON ---
    if (comp == 'Split Button') {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                _buttonLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(width: 1, height: 24, color: Colors.white30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
            ),
          ],
        ),
      );
    }

    // --- ALERTS ---
    if (comp == 'Alerts') {
      if (story == 'Overview') {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAlertBannerTile(
              'Success',
              'บันทึกข้อมูลเรียบร้อยแล้ว',
              const Color(0xFF10B981),
              Icons.check_circle_rounded,
            ),
            const SizedBox(height: 10),
            _buildAlertBannerTile(
              'Warning',
              'มี 12 งานส่งเข้ามาใหม่ รอคุณครูตรวจคะแนน',
              const Color(0xFFF97316),
              Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 10),
            _buildAlertBannerTile(
              'Info',
              'ระบบสลับข้อสอบและตัวเลือกทำงานอยู่',
              const Color(0xFF2563EB),
              Icons.info_rounded,
            ),
            const SizedBox(height: 10),
            _buildAlertBannerTile(
              'Critical',
              'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์',
              const Color(0xFFEF4444),
              Icons.error_outline_rounded,
            ),
          ],
        );
      }
      return _buildAlertBannerTile(
        'Alert',
        'มี 12 งานส่งเข้ามาใหม่ รอคุณครูตรวจคะแนนในรายวิชานี้',
        const Color(0xFFF97316),
        Icons.warning_amber_rounded,
      );
    }

    // --- BADGE ---
    if (comp == 'Badge') {
      if (story == 'Numeric Badge') {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '12 NEW',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBadgePill('Primary', const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          _buildBadgePill('Success', const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _buildBadgePill('Warning', const Color(0xFFF97316)),
          const SizedBox(width: 8),
          _buildBadgePill('Critical', const Color(0xFFEF4444)),
        ],
      );
    }

    // --- CHIP ---
    if (comp == 'Chip') {
      return Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('การทดลองทั้งหมด'),
            selected: true,
            onSelected: (_) {},
          ),
          FilterChip(
            label: const Text('บทเรียน'),
            selected: false,
            onSelected: (_) {},
          ),
          FilterChip(
            label: const Text('แบบทดสอบ'),
            selected: false,
            onSelected: (_) {},
          ),
        ],
      );
    }

    // --- EMPTY STATE ---
    if (comp == 'Empty State') {
      return Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_rounded,
              size: 48,
              color: TeacherPalette.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'ไม่พบข้อมูลรายการข้อสอบ',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'ยังไม่มีการสร้างแบบทดสอบในวิชานี้ กดปุ่มด้านล่างเพื่อสร้างใหม่',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('+ สร้างข้อสอบใหม่'),
            ),
          ],
        ),
      );
    }

    // --- PROGRESS INDICATOR ---
    if (comp == 'Progress Indicator') {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 260,
            child: LinearProgressIndicator(value: 0.75, minHeight: 8),
          ),
          SizedBox(height: 20),
          CircularProgressIndicator(),
        ],
      );
    }

    // --- SKELETON LOADING ---
    if (comp == 'Skeleton Loading') {
      return Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 240,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 180,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    // --- TEXT INPUT ---
    if (comp == 'Text Input') {
      if (story == 'Password Input') {
        return SizedBox(
          width: 320,
          child: TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'รหัสผ่าน (Password)',
              suffixIcon: const Icon(Icons.visibility_off_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        );
      }
      if (story == 'Search Input') {
        return SizedBox(
          width: 320,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'ค้นหารายวิชา หรือนักเรียน...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        );
      }
      return SizedBox(
        width: 320,
        child: TextField(
          decoration: InputDecoration(
            labelText: 'ชื่อบทเรียน / ข้อสอบ',
            hintText: 'พิมพ์ระบุชื่อที่ต้องการ...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      );
    }

    // --- CHECKBOX & RADIO & SWITCH ---
    if (comp == 'Checkbox') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(value: true, onChanged: (_) {}),
          const Text(
            'สลับข้อสอบอัตโนมัติ (Checked)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      );
    }

    if (comp == 'Radio Button') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio(value: 1, groupValue: 1, onChanged: (_) {}),
              const Text('ก. ตัวเลือกข้อที่ 1'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio(value: 2, groupValue: 1, onChanged: (_) {}),
              const Text('ข. ตัวเลือกข้อที่ 2'),
            ],
          ),
        ],
      );
    }

    if (comp == 'Switch / Toggle') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: true, onChanged: (_) {}),
          const SizedBox(width: 8),
          const Text(
            'เผยแพร่ทันที (ON)',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      );
    }

    // --- MODAL / DIALOG ---
    if (comp == 'Modal / Dialog') {
      return Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.help_outline_rounded,
              size: 36,
              color: TeacherPalette.primary,
            ),
            const SizedBox(height: 10),
            const Text(
              'ยืนยันการเผยแพร่ข้อสอบ?',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'เมื่อเผยแพร่แล้ว นักเรียนในห้อง ม.5/1 จะสามารถเริ่มทำข้อสอบได้ทันที',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('ยืนยัน'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // --- MEDIA: AVATAR & AVATAR GROUP ---
    if (comp == 'Avatar') {
      if (story == 'Fallback Initials') {
        return InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('แตะรูปโปรไฟล์ตัวอักษรย่อ "SF" (Sayfa) ✓'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: const CircleAvatar(
            radius: 30,
            backgroundColor: TeacherPalette.primary,
            child: Text(
              'SF',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
        );
      }
      if (story == 'Status Indicator') {
        return InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'แตะรูปโปรไฟล์พร้อมป้ายสถานะออนไลน์ (Online Green) ✓',
                ),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: TeacherPalette.skyBright,
                child: Icon(
                  Icons.person_rounded,
                  color: TeacherPalette.primary,
                  size: 30,
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: TeacherPalette.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      if (story == 'Sizes' || story == 'Overview') {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => _toast(context, 'แตะโปรไฟล์ขนาด Small (24px)'),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: TeacherPalette.primary,
                child: Text(
                  'S',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _toast(context, 'แตะโปรไฟล์ขนาด Medium (36px)'),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: TeacherPalette.skyDeep,
                child: Text(
                  'M',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _toast(context, 'แตะโปรไฟล์ขนาด Large (48px)'),
              child: const CircleAvatar(
                radius: 28,
                backgroundColor: TeacherPalette.primary,
                child: Text(
                  'L',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _toast(context, 'แตะโปรไฟล์ขนาด Extra Large (64px)'),
              child: const CircleAvatar(
                radius: 36,
                backgroundColor: TeacherPalette.orange,
                child: Text(
                  'XL',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ],
        );
      }
      return InkWell(
        onTap: () => _toast(context, 'แตะโปรไฟล์หลักครูผู้สอน'),
        child: const CircleAvatar(
          radius: 30,
          backgroundColor: TeacherPalette.primary,
          child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
        ),
      );
    }

    if (comp == 'Avatar Group') {
      return InkWell(
        onTap: () =>
            _toast(context, 'แตะกลุ่มรูปโปรไฟล์นักเรียน (3 คน +5 เพิ่มเติม)'),
        child: SizedBox(
          width: 130,
          height: 48,
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: TeacherPalette.primary,
                  child: Text(
                    'SF',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const Positioned(
                left: 24,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: TeacherPalette.green,
                  child: Text(
                    'KR',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const Positioned(
                left: 48,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: TeacherPalette.orange,
                  child: Text(
                    'AA',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              Positioned(
                left: 72,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1E293B),
                  child: const Text(
                    '+5',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (comp == 'Card') {
      if (story == 'Soft Glass Assignment Card') {
        return SizedBox(
          width: 750,
          child: SingleChildScrollView(
            child: _buildSoftGlassAssignmentCardsSection(),
          ),
        );
      }
      return const SizedBox(width: 480, child: AnimatedScopeTrendCard());
    }

    // Default Catch-All Sample
    return FilledButton.icon(
      onPressed: _isDisabled
          ? null
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
      icon: const Icon(Icons.check_circle_rounded, size: 16),
      label: Text('$comp: $story'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildAlertBannerTile(
    String title,
    String body,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              body,
              style: const TextStyle(
                color: TeacherPalette.ink,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgePill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMewsTabBar() {
    final tabs = ['Controls 18', 'Actions', 'Interactions', 'Accessibility'];
    return Row(
      children: List.generate(tabs.length, (i) {
        final selected = _selectedTabIdx == i;
        return InkWell(
          onTap: () => setState(() => _selectedTabIdx = i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected
                      ? const Color(0xFF2563EB)
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Text(
              tabs[i],
              style: TextStyle(
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMewsControlsTable() {
    return Column(
      children: [
        _buildControlTableRow(
          name: 'closeNestedOnClickAway',
          type: 'boolean',
          description:
              'Clicking outside will close all nested overlays, like Select',
          defaultValue: '-',
          controlWidget: OutlinedButton(
            onPressed: () => setState(
              () => _closeNestedOnClickAway = !_closeNestedOnClickAway,
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF1E293B),
              side: BorderSide.none,
            ),
            child: const Text(
              'Set boolean',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        _buildControlTableRow(
          name: 'closeOnSelect',
          type: 'boolean',
          description: 'Automatically close dropdown when item is selected',
          defaultValue: 'true',
          controlWidget: OutlinedButton(
            onPressed: () => setState(() => _closeOnSelect = !_closeOnSelect),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF1E293B),
              side: BorderSide.none,
            ),
            child: const Text(
              'Set boolean',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        _buildControlTableRow(
          name: 'disabled',
          type: 'boolean',
          description: 'Disable user interaction',
          defaultValue: 'false',
          controlWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _segmentedBtn(
                'False',
                !_isDisabled,
                () => setState(() => _isDisabled = false),
              ),
              _segmentedBtn(
                'True',
                _isDisabled,
                () => setState(() => _isDisabled = true),
              ),
            ],
          ),
        ),
        _buildControlTableRow(
          name: 'label',
          type: 'string',
          description: 'Custom text label displayed inside component',
          defaultValue: 'Action',
          controlWidget: SizedBox(
            height: 34,
            child: TextField(
              controller: TextEditingController(text: _buttonLabel),
              onChanged: (val) => setState(() => _buttonLabel = val),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlTableRow({
    required String name,
    required String type,
    required String description,
    required String defaultValue,
    required Widget controlWidget,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  type,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 11.5),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              defaultValue,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
            ),
          ),
          SizedBox(
            width: 220,
            child: Align(alignment: Alignment.centerLeft, child: controlWidget),
          ),
        ],
      ),
    );
  }

  Widget _segmentedBtn(String text, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
          ),
        ),
      ),
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
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MewsGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1894A3B8)
      ..strokeWidth = 0.8;
    const double step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MewsGroupedListSample extends StatelessWidget {
  const _MewsGroupedListSample();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            icon: Icons.person_outline_rounded,
            title: 'Title one',
            description: 'Description one',
            badgeLabel: 'Basic bold',
            badgeBg: const Color(0xFFE0E7FF),
            badgeColor: const Color(0xFF3730A3),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildItem(
            icon: Icons.receipt_long_rounded,
            title: 'Title two',
            description: 'Description two',
            badgeLabel: 'Basic subtle',
            badgeBg: const Color(0xFFF1F5F9),
            badgeColor: const Color(0xFF475569),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _buildItem(
            icon: Icons.credit_card_rounded,
            title: 'Title three',
            description: 'Description three',
            badgeLabel: 'Primary',
            badgeBg: const Color(0xFFEEF2FF),
            badgeColor: const Color(0xFF4F46E5),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required String description,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeColor,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF0F172A)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildMediaAvatarsOverviewCard() {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: TeacherPalette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ขนาดรูปโปรไฟล์ (Avatar Sizes & Fallback Initials)',
          style: TextStyle(
            color: TeacherPalette.ink,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: TeacherPalette.primary,
              child: Text(
                'S',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: TeacherPalette.skyDeep,
              child: Text(
                'M',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            SizedBox(width: 12),
            CircleAvatar(
              radius: 28,
              backgroundColor: TeacherPalette.primary,
              child: Text(
                'SF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(width: 12),
            CircleAvatar(
              radius: 36,
              backgroundColor: TeacherPalette.orange,
              child: Text(
                'KR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'กลุ่มโปรไฟล์นักเรียน (Avatar Group + Counter Badge)',
          style: TextStyle(
            color: TeacherPalette.ink,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 160,
          height: 44,
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: TeacherPalette.primary,
                  child: Text(
                    'SF',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const Positioned(
                left: 24,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: TeacherPalette.green,
                  child: Text(
                    'KR',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const Positioned(
                left: 48,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: TeacherPalette.orange,
                  child: Text(
                    'AA',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              Positioned(
                left: 72,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1E293B),
                  child: const Text(
                    '+5',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
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

Widget _buildInputsOverviewCard() {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: TeacherPalette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'ช่องกรอกทั่วไป',
                  hintText: 'พิมพ์ข้อความ...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน',
                  suffixIcon: const Icon(
                    Icons.visibility_off_rounded,
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Row(
              children: [
                Checkbox(value: true, onChanged: (_) {}),
                const Text(
                  'Checkbox (เปิดใช้งาน)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                Radio(value: 1, groupValue: 1, onChanged: (_) {}),
                const Text(
                  'Radio (เลือก)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                Switch(value: true, onChanged: (_) {}),
                const Text(
                  'Switch (ON)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$message ✓'),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// --- MASTER BUTTON DESIGN SYSTEM MATRIX (13 Actions x 4 States) ---
Widget _buildMasterButtonMatrixCard(BuildContext context) {
  final matrixItems = [
    const _MatrixRowSpec(label: 'Master', color: Color(0xFF64748B)),
    const _MatrixRowSpec(label: 'Hover', color: Color(0xFF475569)),
    const _MatrixRowSpec(
      label: 'Back',
      icon: Icons.arrow_back_rounded,
      color: Color(0xFF1D4ED8),
    ),
    const _MatrixRowSpec(
      label: 'Next',
      icon: Icons.arrow_forward_rounded,
      iconRight: true,
      color: Color(0xFF1D4ED8),
    ),
    const _MatrixRowSpec(
      label: 'Submit',
      icon: Icons.check_rounded,
      color: Color(0xFF15803D),
    ),
    const _MatrixRowSpec(
      label: 'Cancel',
      icon: Icons.close_rounded,
      color: Color(0xFFDC2626),
    ),
    const _MatrixRowSpec(
      label: 'Delete',
      icon: Icons.delete_outline_rounded,
      color: Color(0xFF92400E),
    ),
    const _MatrixRowSpec(
      label: 'Add',
      icon: Icons.add_rounded,
      color: Color(0xFF1D4ED8),
    ),
    const _MatrixRowSpec(
      label: 'Edit',
      icon: Icons.edit_outlined,
      color: Color(0xFF1D4ED8),
    ),
    const _MatrixRowSpec(
      label: 'Expand',
      icon: Icons.keyboard_arrow_down_rounded,
      color: Color(0xFF1D4ED8),
    ),
    const _MatrixRowSpec(
      label: 'Date',
      icon: Icons.calendar_today_rounded,
      color: Color(0xFF1D4ED8),
    ),
    const _MatrixRowSpec(
      label: 'More',
      icon: Icons.more_vert_rounded,
      color: Color(0xFF1D4ED8),
    ),
    const _MatrixRowSpec(
      label: 'Open',
      icon: Icons.open_in_new_rounded,
      iconRight: true,
      color: Color(0xFF1D4ED8),
    ),
  ];

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: TeacherPalette.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 20,
              color: TeacherPalette.primary,
            ),
            SizedBox(width: 8),
            Text(
              'Master Button Design System Matrix (13 Actions x 4 States)',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: TeacherPalette.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'แสดงผลปุ่มกดมาตรฐานทุกสถานะ (Ghost / Outlined / Soft Tonal / Solid Filled) ตรงตามต้นแบบภาพถ่ายหน้าจอ 100%',
          style: TextStyle(
            fontSize: 12,
            color: TeacherPalette.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FixedColumnWidth(140),
              1: FixedColumnWidth(145),
              2: FixedColumnWidth(145),
              3: FixedColumnWidth(145),
            },
            children: matrixItems.map((item) {
              return TableRow(
                children: [
                  // Column 1: Ghost / Flat
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    child: _AnimatedMatrixButton(
                      spec: item,
                      variant: 'Ghost',
                      onTap: () =>
                          _notifyButtonClick(context, item.label, 'Ghost'),
                    ),
                  ),
                  // Column 2: Outlined
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    child: _AnimatedMatrixButton(
                      spec: item,
                      variant: 'Outlined',
                      onTap: () =>
                          _notifyButtonClick(context, item.label, 'Outlined'),
                    ),
                  ),
                  // Column 3: Soft Tonal
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    child: _AnimatedMatrixButton(
                      spec: item,
                      variant: 'Soft Tonal',
                      onTap: () =>
                          _notifyButtonClick(context, item.label, 'Soft Tonal'),
                    ),
                  ),
                  // Column 4: Solid Filled
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    child: _AnimatedMatrixButton(
                      spec: item,
                      variant: 'Solid Filled',
                      onTap: () => _notifyButtonClick(
                        context,
                        item.label,
                        'Solid Filled',
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

void _notifyButtonClick(BuildContext context, String label, String variant) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('กดปุ่ม $label ($variant) เรียบร้อยแล้ว ✓'),
      duration: const Duration(milliseconds: 1200),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// --- 1. NUTRIENT & SCORE METRIC SUMMARIES (JORDI PLAZA IMAGE - 6 CARDS PIXEL-PERFECT) ---
Widget _buildNutrientScoreSummariesCard() {
  return const NutrientScoreSummariesGallery();
}

// --- 2. ANALYTICS & CALENDAR DASHBOARD WIDGETS ---
Widget _buildDashboardWidgetsCollectionCard() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: TeacherPalette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Widget 2A: Insights Forecast Card
            _buildMetricCardBox(
              width: 310,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Insights',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: TeacherPalette.muted,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.more_horiz_rounded,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '64%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: TeacherPalette.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.call_made_rounded,
                        size: 18,
                        color: Color(0xFF059669),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'increase in your revenue by end of this month is forecasted',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'There is an increase of customer traffic as compared to last year data which results in a 64% increase in invoice raised',
                    style: TextStyle(fontSize: 11, color: TeacherPalette.muted),
                  ),
                ],
              ),
            ),

            // Widget 2B: August 3D Date Flip Card
            _buildMetricCardBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 20),
                      const Text(
                        'August',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.ink,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.more_horiz_rounded,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x100F172A),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Text(
                          '05',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: TeacherPalette.ink,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'Monday',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TeacherPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Widget 2C: Dark Mode World Clock & Earth Widget
            Container(
              width: 320,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x300F172A),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Local time',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '14:29',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.public_rounded,
                          color: Color(0xFF60A5FA),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    '📍 Lagos, Nigeria',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildCityChip('08:29', 'GMT-2', 'New York'),
                      const SizedBox(width: 8),
                      _buildCityChip('10:29', 'GMT+2', 'Johannesburg'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildCityChip(String time, String gmt, String city) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$time  $gmt',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(city, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    ),
  );
}

// --- 4. AUTOMATION WORKFLOW NODE CARDS ---
Widget _buildWorkflowNodeCardsCard(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFBFD),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: TeacherPalette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Trigger Node
            _buildNodeCardBox(
              badgeLabel: '⚡ Trigger',
              badgeColor: const Color(0xFFFEF08A),
              badgeTextColor: const Color(0xFF854D0E),
              title: 'Incoming Webhook',
              icon: Icons.link_rounded,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text(
                      'POST ',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'https://api.website.io/hooks/7f8a9...',
                        style: TextStyle(
                          fontSize: 11,
                          color: TeacherPalette.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              footer: '⏱ 0.0 sec',
            ),

            // Action Node (Not Connected Warning)
            _buildNodeCardBox(
              badgeLabel: '🔵 Action',
              badgeColor: const Color(0xFFDBEAFE),
              badgeTextColor: const Color(0xFF1E40AF),
              title: 'Write to Notion',
              icon: Icons.edit_note_rounded,
              child: OutlinedButton.icon(
                onPressed: () =>
                    showTeacherMockAction(context, 'Connect Notion Account'),

                icon: const Icon(Icons.link_rounded, size: 14),
                label: const Text(
                  'Connect Notion Account',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                ),
              ),
              footer: '⏱ 0.0 sec',
              warningBadge: '⚠️ Account not connected',
            ),

            // Output Node
            _buildNodeCardBox(
              badgeLabel: '🟢 Output',
              badgeColor: const Color(0xFFDCFCE7),
              badgeTextColor: const Color(0xFF166534),
              title: 'Audio Output',
              icon: Icons.graphic_eq_rounded,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Eleven v3 (alpha)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '🎙 Sarah',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              footer: '⏱ 0.0 sec • 382 Tokens',
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildNodeCardBox({
  required String badgeLabel,
  required Color badgeColor,
  required Color badgeTextColor,
  required String title,
  required IconData icon,
  required Widget child,
  required String footer,
  String? warningBadge,
}) {
  return Container(
    width: 320,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x060F172A),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: badgeTextColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                ),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.more_vert_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(icon, size: 18, color: TeacherPalette.ink),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                color: TeacherPalette.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              footer,
              style: const TextStyle(
                fontSize: 11,
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (warningBadge != null) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  warningBadge,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

// --- 5. MODERN TOAST NOTIFICATION BANNERS ---
Widget _buildModernToastAlertsCard() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: TeacherPalette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column 1: Soft Tinted Glassmorphic Banners
            Expanded(
              child: Column(
                children: [
                  _buildSoftToastItem(
                    'Payment processed',
                    'Transaction ID: #14402',
                    Icons.check_circle_outline_rounded,
                    const Color(0xFF10B981),
                    const Color(0xFFECFDF5),
                  ),
                  const SizedBox(height: 12),
                  _buildSoftToastItem(
                    'Connection failed',
                    'Check your Internet connection',
                    Icons.warning_amber_rounded,
                    const Color(0xFFD97706),
                    const Color(0xFFFFFBEB),
                  ),
                  const SizedBox(height: 12),
                  _buildSoftToastItem(
                    'Update available',
                    'Version 2.1.0 ready to install',
                    Icons.info_outline_rounded,
                    const Color(0xFF2563EB),
                    const Color(0xFFEFF6FF),
                  ),
                  const SizedBox(height: 12),
                  _buildSoftToastItem(
                    'Something went wrong',
                    'Please try again later',
                    Icons.error_outline_rounded,
                    const Color(0xFFDC2626),
                    const Color(0xFFFEF2F2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Column 2: Minimalist White Banners
            Expanded(
              child: Column(
                children: [
                  _buildWhiteToastItem(
                    'Payment processed',
                    'Transaction ID: #14402',
                    Icons.check_circle_rounded,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  _buildWhiteToastItem(
                    'Connection failed',
                    'Check your Internet connection',
                    Icons.warning_rounded,
                    const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 12),
                  _buildWhiteToastItem(
                    'Update available',
                    'Version 2.1.0 ready to install',
                    Icons.info_rounded,
                    const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 12),
                  _buildWhiteToastItem(
                    'Something went wrong',
                    'Please try again later',
                    Icons.dangerous_rounded,
                    const Color(0xFFDC2626),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildSoftToastItem(
  String title,
  String subtitle,
  IconData icon,
  Color color,
  Color bg,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.close_rounded,
          color: color.withValues(alpha: 0.6),
          size: 16,
        ),
      ],
    ),
  );
}

Widget _buildWhiteToastItem(
  String title,
  String subtitle,
  IconData icon,
  Color color,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.close_rounded, color: TeacherPalette.muted, size: 16),
      ],
    ),
  );
}

Widget _buildMetricCardBox({required Widget child, double? width}) {
  return Container(
    width: width,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x060F172A),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class _AnimatedMatrixButton extends StatefulWidget {
  const _AnimatedMatrixButton({
    required this.spec,
    required this.variant,
    required this.onTap,
  });

  final _MatrixRowSpec spec;
  final String variant;
  final VoidCallback onTap;

  @override
  State<_AnimatedMatrixButton> createState() => _AnimatedMatrixButtonState();
}

class _AnimatedMatrixButtonState extends State<_AnimatedMatrixButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final variant = widget.variant;

    Color bgColor;
    Color textColor = spec.color;
    Border? border;
    List<BoxShadow> shadow = [];

    if (variant == 'Ghost') {
      bgColor = _isPressed
          ? spec.color.withValues(alpha: 0.18)
          : (_isHovered
                ? spec.color.withValues(alpha: 0.08)
                : Colors.transparent);
    } else if (variant == 'Outlined') {
      bgColor = _isPressed
          ? spec.color.withValues(alpha: 0.08)
          : (_isHovered ? const Color(0xFFF8FAFC) : Colors.white);
      border = Border.all(
        color: _isHovered ? spec.color : spec.color.withValues(alpha: 0.4),
        width: _isHovered ? 1.5 : 1.2,
      );
      shadow = _isHovered
          ? [
              BoxShadow(
                color: spec.color.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
          : [
              const BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ];
    } else if (variant == 'Soft Tonal') {
      bgColor = _isPressed
          ? spec.color.withValues(alpha: 0.24)
          : (_isHovered
                ? spec.color.withValues(alpha: 0.18)
                : spec.color.withValues(alpha: 0.12));
      shadow = _isHovered
          ? [
              BoxShadow(
                color: spec.color.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
          : [];
    } else {
      // Solid Filled
      bgColor = _isPressed
          ? Color.alphaBlend(Colors.black.withValues(alpha: 0.2), spec.color)
          : (_isHovered
                ? Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.15),
                    spec.color,
                  )
                : spec.color);
      textColor = Colors.white;
      shadow = [
        BoxShadow(
          color: spec.color.withValues(
            alpha: _isPressed ? 0.2 : (_isHovered ? 0.45 : 0.3),
          ),
          blurRadius: _isPressed ? 3 : (_isHovered ? 10 : 6),
          offset: _isPressed
              ? const Offset(0, 1)
              : (_isHovered ? const Offset(0, 5) : const Offset(0, 3)),
        ),
      ];
    }

    final textWidget = Text(
      spec.label,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    );

    Widget childWidget;
    if (spec.icon == null) {
      childWidget = textWidget;
    } else {
      final iconWidget = Icon(spec.icon, size: 16, color: textColor);
      childWidget = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: spec.iconRight
            ? [textWidget, const SizedBox(width: 6), iconWidget]
            : [iconWidget, const SizedBox(width: 6), textWidget],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.93 : (_isHovered ? 1.04 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: border,
              boxShadow: shadow,
            ),
            child: childWidget,
          ),
        ),
      ),
    );
  }
}

class _MatrixRowSpec {
  final String label;
  final IconData? icon;
  final bool iconRight;
  final Color color;

  const _MatrixRowSpec({
    required this.label,
    this.icon,
    this.iconRight = false,
    required this.color,
  });
}

// --- 🌟 PIXEL-PERFECT & LIVE ANIMATED 6-CARD GALLERY FOR JORDI PLAZA IMAGE ---
class NutrientScoreSummariesGallery extends StatefulWidget {
  const NutrientScoreSummariesGallery({super.key});

  @override
  State<NutrientScoreSummariesGallery> createState() =>
      _NutrientScoreSummariesGalleryState();
}

class _NutrientScoreSummariesGalleryState
    extends State<NutrientScoreSummariesGallery> {
  // Live Score State (1 to 10)
  double _score = 6.0;

  // Live Metrics State
  int _calories = 1200;
  int _protein = 24;
  int _netCarbs = 8;
  int _fat = 13;

  void _updateScore(double newScore) {
    setState(() {
      _score = newScore.clamp(1.0, 10.0);
    });
  }

  void _tweakMetric(String type, int delta) {
    setState(() {
      if (type == 'cal') _calories = (_calories + delta).clamp(500, 3000);
      if (type == 'protein') _protein = (_protein + delta).clamp(0, 100);
      if (type == 'carbs') _netCarbs = (_netCarbs + delta).clamp(0, 100);
      if (type == 'fat') _fat = (_fat + delta).clamp(0, 100);
    });
  }

  Widget _buildBaseWhiteCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCardHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: Color(0xFFCBD5E1),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, double val) {
    final isSelected = (_score - val).abs() < 0.5;
    return InkWell(
      onTap: () => _updateScore(val),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎛️ TOP LIVE INTERACTIVE SIMULATION CONTROL BAR
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C0F172A),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ทดลองเลื่อนคะแนน (Live Score):',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: const SliderThemeData(
                          activeTrackColor: Color(0xFF2563EB),
                          thumbColor: Color(0xFF2563EB),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _score,
                          min: 1.0,
                          max: 10.0,
                          divisions: 9,
                          label: '${_score.toInt()}/10',
                          onChanged: (val) => _updateScore(val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip('Low (3)', 3.0),
                    const SizedBox(width: 6),
                    _buildPresetChip('Normal (6)', 6.0),
                    const SizedBox(width: 6),
                    _buildPresetChip('Goal (9)', 9.0),
                  ],
                ),
              ),

              // Row 1: Card 1 (Score Bar) + Card 2 (Rainbow Arc Gauge)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCard1ScoreBar()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCard2RainbowArcGauge()),
                ],
              ),
              const SizedBox(height: 16),

              // Row 2: Card 3 (Concentric Rings Right) + Card 4 (4 Circular Gauges)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCard3ConcentricRingsRight()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCard4FourCircularGauges()),
                ],
              ),
              const SizedBox(height: 16),

              // Row 3: Card 5 (Left Ring + Inline Metrics) + Card 6 (4 Horizontal Bars)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCard5LeftRingInlineMetrics()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCard6HorizontalBars()),
                ],
              ),
              const SizedBox(height: 16),

              // Row 4: Card 7 (Project Scope & Progress Trend Line Chart with Running Glow Lines)
              const AnimatedScopeTrendCard(),
              const SizedBox(height: 16),

              // Row 5: Card 8 (Members Growth Area Chart - Sunset Gradient Fill & Interactive Month Focus)
              const AnimatedMembersGrowthCard(),
            ],
          ),
        ),
      ),
    );
  }

  // --- CARD 1: Daily Glucose (Score Bar - Interactive Drag & Click) ---
  Widget _buildCard1ScoreBar() {
    return _buildBaseWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Card 1: Daily Glucose (Score Bar)'),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: _score),
            duration: const Duration(milliseconds: 250),
            builder: (context, val, child) {
              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${val.toInt()}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const TextSpan(
                      text: '/10',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 18,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                final normScore = (_score - 1) / 9.0;
                final pinPos = (barWidth - 10) * normScore;

                return GestureDetector(
                  onTapDown: (details) {
                    final clickX = details.localPosition.dx;
                    final clickRatio = (clickX / barWidth).clamp(0.0, 1.0);
                    final newScore = (1 + clickRatio * 9).roundToDouble();
                    _updateScore(newScore);
                  },
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Container(
                                height: 8,
                                color: const Color(0xFFF87171),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 8,
                                color: const Color(0xFFFBBF24),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 8,
                                color: const Color(0xFF34D399),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: pinPos,
                        child: Container(
                          width: 8,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- CARD 2: Daily Glucose (Rainbow Arc Gauge - Animated Arc Sweep & Interactive Tap) ---
  Widget _buildCard2RainbowArcGauge() {
    final arcProgress = (_score / 10.0).clamp(0.1, 1.0);
    return GestureDetector(
      onTap: () {
        final nextScore = _score >= 10.0 ? 2.0 : (_score + 2.0);
        _updateScore(nextScore);
      },
      child: _buildBaseWhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader('Card 2: Daily Glucose (Rainbow Arc Gauge)'),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 60,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.1, end: arcProgress),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return CustomPaint(
                        painter: _RainbowArcGaugePainter(value: val),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${(val * 10).toInt()}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: '/10',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Overall\nperformance\nfor the day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD 3: Nutrient Summary (Concentric Rings Right - Smooth Arc Animations) ---
  Widget _buildCard3ConcentricRingsRight() {
    final pVal = (_protein / 50.0).clamp(0.1, 1.0);
    final fVal = (_fat / 30.0).clamp(0.1, 1.0);
    final cVal = (_netCarbs / 30.0).clamp(0.1, 1.0);

    return _buildBaseWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Card 3: Concentric Rings Right'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _tweakMetric('protein', 2),
                      borderRadius: BorderRadius.circular(6),
                      child: _NutrientDotItem(
                        color: const Color(0xFFF87171),
                        label: 'Protein',
                        value: '$_protein',
                        unit: 'g',
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _tweakMetric('fat', 1),
                      borderRadius: BorderRadius.circular(6),
                      child: _NutrientDotItem(
                        color: const Color(0xFFFBBF24),
                        label: 'Fat',
                        value: '$_fat',
                        unit: 'g',
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _tweakMetric('carbs', 1),
                      borderRadius: BorderRadius.circular(6),
                      child: _NutrientDotItem(
                        color: const Color(0xFF38BDF8),
                        label: 'Net Carbs',
                        value: '$_netCarbs',
                        unit: 'g',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 68,
                height: 68,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.1, end: pVal),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (context, valP, child) {
                    return CustomPaint(
                      painter: _ConcentricRingsRightPainter(
                        proteinVal: valP,
                        fatVal: fVal,
                        carbsVal: cVal,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- CARD 4: Nutrient Summary (4 Circular Gauges with Interactive Increments) ---
  Widget _buildCard4FourCircularGauges() {
    return _buildBaseWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Card 4: 4 Circular Gauges'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: () => _tweakMetric('cal', 100),
                child: _MiniCircularGaugeItem(
                  label: 'Calories',
                  value: '$_calories',
                  unit: 'cal',
                  color: const Color(0xFF3B82F6),
                  progress: (_calories / 2000).clamp(0.2, 1.0),
                ),
              ),
              InkWell(
                onTap: () => _tweakMetric('protein', 2),
                child: _MiniCircularGaugeItem(
                  label: 'Protein',
                  value: '$_protein',
                  unit: 'g',
                  color: const Color(0xFFFBBF24),
                  progress: (_protein / 50).clamp(0.2, 1.0),
                ),
              ),
              InkWell(
                onTap: () => _tweakMetric('carbs', 1),
                child: _MiniCircularGaugeItem(
                  label: 'Net Carbs',
                  value: '$_netCarbs',
                  unit: 'g',
                  color: const Color(0xFF34D399),
                  progress: (_netCarbs / 30).clamp(0.2, 1.0),
                ),
              ),
              InkWell(
                onTap: () => _tweakMetric('fat', 1),
                child: _MiniCircularGaugeItem(
                  label: 'Fat',
                  value: '$_fat',
                  unit: 'g',
                  color: const Color(0xFFF472B6),
                  progress: (_fat / 30).clamp(0.2, 1.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- CARD 5: Nutrient Summary (Left Ring + Inline Metrics - Animated Multi-Ring) ---
  Widget _buildCard5LeftRingInlineMetrics() {
    final pVal = (_protein / 50.0).clamp(0.1, 1.0);
    final cVal = (_netCarbs / 30.0).clamp(0.1, 1.0);
    final fVal = (_fat / 30.0).clamp(0.1, 1.0);

    return _buildBaseWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Card 5: Left Ring Inline Metrics'),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.1, end: pVal),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (context, valP, child) {
                    return CustomPaint(
                      painter: _LeftRingChartPainter(
                        proteinVal: valP,
                        carbsVal: cVal,
                        fatVal: fVal,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _tweakMetric('cal', 50),
                      borderRadius: BorderRadius.circular(6),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Calories ',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            TextSpan(
                              text: '$_calories ',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const TextSpan(
                              text: 'cal',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _tweakMetric('protein', 2),
                          child: _DotMetricInline(
                            color: const Color(0xFF3B82F6),
                            label: 'Protein',
                            value: '${_protein}g',
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _tweakMetric('carbs', 1),
                          child: _DotMetricInline(
                            color: const Color(0xFF34D399),
                            label: 'Net Carbs',
                            value: '${_netCarbs}g',
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _tweakMetric('fat', 1),
                          child: _DotMetricInline(
                            color: const Color(0xFFFBBF24),
                            label: 'Fat',
                            value: '${_fat}g',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- CARD 6: Nutrient Summary (4 Horizontal Animated Progress Bars) ---
  Widget _buildCard6HorizontalBars() {
    return _buildBaseWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Card 6: 4 Horizontal Progress Bars'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _tweakMetric('cal', 100),
                  child: _BarMetricColumn(
                    label: 'Calories',
                    value: '$_calories',
                    unit: 'cal',
                    color: const Color(0xFF38BDF8),
                    progress: (_calories / 2000).clamp(0.1, 1.0),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _tweakMetric('protein', 2),
                  child: _BarMetricColumn(
                    label: 'Protein',
                    value: '$_protein',
                    unit: 'g',
                    color: const Color(0xFFFBBF24),
                    progress: (_protein / 50).clamp(0.1, 1.0),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _tweakMetric('carbs', 1),
                  child: _BarMetricColumn(
                    label: 'Net Carbs',
                    value: '$_netCarbs',
                    unit: 'g',
                    color: const Color(0xFF34D399),
                    progress: (_netCarbs / 30).clamp(0.1, 1.0),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _tweakMetric('fat', 1),
                  child: _BarMetricColumn(
                    label: 'Fat',
                    value: '$_fat',
                    unit: 'g',
                    color: const Color(0xFFF472B6),
                    progress: (_fat / 30).clamp(0.1, 1.0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RainbowArcGaugePainter extends CustomPainter {
  final double value;
  _RainbowArcGaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeW = 6.0;
    final rx = (size.width - strokeW - 4) / 2;
    final ry = 30.0;
    final centerX = size.width / 2;
    final centerY = 36.0;

    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: rx * 2,
      height: ry * 2,
    );

    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final sweepGradient = const SweepGradient(
      startAngle: math.pi * 0.8,
      endAngle: math.pi * 2.2,
      colors: [Color(0xFFFBBF24), Color(0xFFF87171), Color(0xFF34D399)],
    );

    final progressPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi * 0.85;
    const sweepTotal = math.pi * 1.3;

    canvas.drawArc(rect, startAngle, sweepTotal, false, bgPaint);
    canvas.drawArc(rect, startAngle, sweepTotal * value, false, progressPaint);

    final currentAngle = startAngle + sweepTotal * value;
    final dotX = centerX + rx * math.cos(currentAngle);
    final dotY = centerY + ry * math.sin(currentAngle);

    final dotPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(dotX, dotY), 4.5, dotPaint);
    canvas.drawCircle(
      Offset(dotX, dotY),
      4.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ConcentricRingsRightPainter extends CustomPainter {
  final double proteinVal;
  final double fatVal;
  final double carbsVal;

  _ConcentricRingsRightPainter({
    required this.proteinVal,
    required this.fatVal,
    required this.carbsVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = 5.0;

    final p1 = Paint()
      ..color = const Color(0xFFF87171)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    final p2 = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    final p3 = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;

    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;

    canvas.drawCircle(center, 28, bgPaint);
    canvas.drawCircle(center, 19, bgPaint);
    canvas.drawCircle(center, 10, bgPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 28),
      -1.57,
      5.2 * proteinVal,
      false,
      p1,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 19),
      -1.57,
      4.2 * fatVal,
      false,
      p2,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 10),
      -1.57,
      3.2 * carbsVal,
      false,
      p3,
    );
  }

  @override
  bool shouldRepaint(covariant _ConcentricRingsRightPainter oldDelegate) =>
      oldDelegate.proteinVal != proteinVal ||
      oldDelegate.fatVal != fatVal ||
      oldDelegate.carbsVal != carbsVal;
}

class _LeftRingChartPainter extends CustomPainter {
  final double proteinVal;
  final double carbsVal;
  final double fatVal;

  _LeftRingChartPainter({
    required this.proteinVal,
    required this.carbsVal,
    required this.fatVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = 4.5;

    final p1 = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    final p2 = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    final p3 = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;

    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;

    canvas.drawCircle(center, 26, bgPaint);
    canvas.drawCircle(center, 17, bgPaint);
    canvas.drawCircle(center, 8, bgPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 26),
      0.5,
      5.0 * proteinVal,
      false,
      p1,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 17),
      0.5,
      4.0 * carbsVal,
      false,
      p2,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 8),
      0.5,
      3.0 * fatVal,
      false,
      p3,
    );
  }

  @override
  bool shouldRepaint(covariant _LeftRingChartPainter oldDelegate) =>
      oldDelegate.proteinVal != proteinVal ||
      oldDelegate.carbsVal != carbsVal ||
      oldDelegate.fatVal != fatVal;
}

class _NutrientDotItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String unit;

  const _NutrientDotItem({
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextSpan(
                text: unit,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniCircularGaugeItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final double progress;

  const _MiniCircularGaugeItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 44,
          height: 44,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.1, end: progress),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return CustomPaint(
                painter: _SingleMiniArcPainter(color: color, progress: val),
                child: Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$value\n',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        TextSpan(
                          text: unit,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SingleMiniArcPainter extends CustomPainter {
  final Color color;
  final double progress;
  _SingleMiniArcPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      6.28,
      false,
      bgPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      6.28 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DotMetricInline extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _DotMetricInline({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _BarMetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final double progress;

  const _BarMetricColumn({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 6,
            color: const Color(0xFFF1F5F9),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * progress,
                      color: color,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// --- CARD 7: Project Scope & Progress Trend Line Chart (Interactive + Running Pulse Glow) ---
// ============================================================================
class AnimatedScopeTrendCard extends StatefulWidget {
  final Color blueGlowColor;
  final Color redGlowColor;
  final Color greenGlowColor;

  const AnimatedScopeTrendCard({
    super.key,
    this.blueGlowColor = const Color(0xFF38BDF8),
    this.redGlowColor = const Color(0xFFF87171),
    this.greenGlowColor = const Color(0xFF34D399),
  });

  @override
  State<AnimatedScopeTrendCard> createState() => _AnimatedScopeTrendCardState();
}

class _AnimatedScopeTrendCardState extends State<AnimatedScopeTrendCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _hoverXRatio = 0.68;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildCardHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: Color(0xFFCBD5E1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            'Card 7: Scope & Progress Trend (Running Glow Lines)',
          ),
          const SizedBox(height: 14),
          // Header Metrics Row (Scope 356 +32%, Started 64, Completed 192)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Scope Metric
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Scope',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '356',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '+32%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Started Metric
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Started',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '64',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),

              // Completed Metric
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '192',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Interactive Chart Area with Running Pulse Glow Line Animations + Tooltip Pin ("Tam")
          SizedBox(
            height: 120,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return MouseRegion(
                  onHover: (event) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final localPos = box.globalToLocal(event.position);
                      setState(() {
                        _hoverXRatio = (localPos.dx / box.size.width).clamp(
                          0.0,
                          1.0,
                        );
                        _isHovered = true;
                      });
                    }
                  },
                  onExit: (_) {
                    setState(() {
                      _isHovered = false;
                      _hoverXRatio = 0.68;
                    });
                  },
                  child: CustomPaint(
                    painter: _RunningGlowLineChartPainter(
                      pulsePhase: _controller.value,
                      hoverXRatio: _hoverXRatio,
                      isHovered: _isHovered,
                      blueGlowColor: widget.blueGlowColor,
                      redGlowColor: widget.redGlowColor,
                      greenGlowColor: widget.greenGlowColor,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // X-Axis Timeline Labels (Nov 15, Dec 15, Jan 15, Feb 15)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nov 15',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Text(
                'Dec 15',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Text(
                'Jan 15',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Text(
                'Feb 15',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RunningGlowLineChartPainter extends CustomPainter {
  final double pulsePhase;
  final double hoverXRatio;
  final bool isHovered;
  final Color blueGlowColor;
  final Color redGlowColor;
  final Color greenGlowColor;

  _RunningGlowLineChartPainter({
    required this.pulsePhase,
    required this.hoverXRatio,
    required this.isHovered,
    required this.blueGlowColor,
    required this.redGlowColor,
    required this.greenGlowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Define 3 path lines matching screenshot:
    final bluePath = Path();
    bluePath.moveTo(0, h * 0.95);
    bluePath.cubicTo(w * 0.1, h * 0.70, w * 0.18, h * 0.45, w * 0.25, h * 0.45);
    bluePath.lineTo(w * 0.45, h * 0.45);
    bluePath.cubicTo(
      w * 0.52,
      h * 0.45,
      w * 0.58,
      h * 0.20,
      w * 0.65,
      h * 0.20,
    );

    final redPath = Path();
    redPath.moveTo(0, h * 0.95);
    redPath.cubicTo(w * 0.12, h * 0.85, w * 0.22, h * 0.65, w * 0.30, h * 0.65);
    redPath.lineTo(w * 0.48, h * 0.65);
    redPath.cubicTo(w * 0.54, h * 0.65, w * 0.60, h * 0.50, w * 0.65, h * 0.50);

    final greenPath = Path();
    greenPath.moveTo(0, h * 0.95);
    greenPath.cubicTo(
      w * 0.15,
      h * 0.78,
      w * 0.30,
      h * 0.35,
      w * 0.42,
      h * 0.35,
    );
    greenPath.lineTo(w * 0.72, h * 0.35);
    greenPath.cubicTo(
      w * 0.82,
      h * 0.35,
      w * 0.92,
      h * 0.20,
      w * 1.0,
      h * 0.12,
    );

    // Base Paints
    final blueBasePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final redBasePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final greenBasePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(bluePath, blueBasePaint);
    canvas.drawPath(redPath, redBasePaint);
    canvas.drawPath(greenPath, greenBasePaint);

    // --- "เส้นแบบวิ้งได้" RUNNING GLOWING PULSE ANIMATIONS ---
    _drawRunningGlowEffect(canvas, bluePath, blueGlowColor, pulsePhase, 2.5);
    _drawRunningGlowEffect(
      canvas,
      redPath,
      redGlowColor,
      (pulsePhase + 0.33) % 1.0,
      2.5,
    );
    _drawRunningGlowEffect(
      canvas,
      greenPath,
      greenGlowColor,
      (pulsePhase + 0.66) % 1.0,
      2.5,
    );

    // End node circles for Blue & Red
    final blueEnd = Offset(w * 0.65, h * 0.20);
    final redEnd = Offset(w * 0.65, h * 0.50);

    canvas.drawCircle(blueEnd, 4.5, Paint()..color = const Color(0xFF3B82F6));
    canvas.drawCircle(
      blueEnd,
      4.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(redEnd, 4.5, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(
      redEnd,
      4.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // --- INTERACTIVE HOVER CROSSHAIR & TOOLTIP PIN ("Tam") ---
    final targetX = hoverXRatio * w;
    final focusY = _getGreenLineYAtX(targetX, w, h);
    final pinCenter = Offset(targetX, focusY);

    // Vertical Crosshair
    final crossPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(targetX, 0), Offset(targetX, h), crossPaint);

    // Green Node Pin
    canvas.drawCircle(pinCenter, 5.0, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(pinCenter, 7.5, Paint()..color = const Color(0x3310B981));
    canvas.drawCircle(
      pinCenter,
      5.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Floating Tooltip Badge ("Tam")
    _drawTooltipBadge(canvas, pinCenter, 'Tam');
  }

  void _drawRunningGlowEffect(
    Canvas canvas,
    Path path,
    Color glowColor,
    double phase,
    double strokeWidth,
  ) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final totalLen = metric.length;
      final headDist = totalLen * phase;
      final tailLen = totalLen * 0.28;

      final pulsePath = metric.extractPath(
        (headDist - tailLen).clamp(0.0, totalLen),
        headDist.clamp(0.0, totalLen),
      );

      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.0);

      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawPath(pulsePath, glowPaint);
      canvas.drawPath(pulsePath, corePaint);
    }
  }

  double _getGreenLineYAtX(double x, double w, double h) {
    if (x <= w * 0.42) {
      final t = (x / (w * 0.42)).clamp(0.0, 1.0);
      return h * 0.95 - (h * 0.60) * t;
    } else if (x <= w * 0.72) {
      return h * 0.35;
    } else {
      final t = ((x - w * 0.72) / (w * 0.28)).clamp(0.0, 1.0);
      return h * 0.35 - (h * 0.23) * t;
    }
  }

  void _drawTooltipBadge(Canvas canvas, Offset pinCenter, String text) {
    final tooltipOffset = Offset(pinCenter.dx - 18, pinCenter.dy + 12);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(tooltipOffset.dx, tooltipOffset.dy, 42, 22),
      const Radius.circular(8),
    );

    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()..color = const Color(0xFFFFFFFF);

    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        tooltipOffset.dx + (42 - textPainter.width) / 2,
        tooltipOffset.dy + (22 - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _RunningGlowLineChartPainter oldDelegate) =>
      true;
}

// ============================================================================
// --- CARD 8: Members Growth Area Chart (Dual-Line Gradient Fill + 2 Running Glow Beams) ---
// ============================================================================
// ============================================================================
// --- CARD 8: Homeroom Utility 2-Line Chart (การใช้น้ำ-ไฟ ห้องประจำชั้น) ---
// ============================================================================
class AnimatedMembersGrowthCard extends StatefulWidget {
  final Color pulseGlowColor;
  final Color secondaryGlowColor;

  const AnimatedMembersGrowthCard({
    super.key,
    this.pulseGlowColor = const Color(0xFFF97316),
    this.secondaryGlowColor = const Color(0xFF0EA5E9),
  });

  @override
  State<AnimatedMembersGrowthCard> createState() =>
      _AnimatedMembersGrowthCardState();
}

class _AnimatedMembersGrowthCardState extends State<AnimatedMembersGrowthCard>
    with SingleTickerProviderStateMixin {
  static const _days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];
  static const _electricByDay = [26.0, 24.0, 30.0, 28.0, 34.0]; // รวม 142
  static const _waterByDay = [0.6, 0.5, 0.7, 0.6, 0.8]; // รวม 3.2

  late AnimationController _pulseController;
  int _selectedDayIdx = 1; // อ. (Tuesday - 24 kWh / 0.5 m³)

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildCardHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: Color(0xFFCBD5E1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            'Card 8: Homeroom Utility 2-Line Chart (การใช้น้ำ-ไฟ)',
          ),
          const SizedBox(height: 16),

          // 1. Sleek Header Row with Dual Material Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Combined Dual Icon Badge (Bolt + Water drop)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7ED), Color(0xFFF0F9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: Color(0xFFF97316),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.water_drop_rounded,
                      size: 15,
                      color: Color(0xFF0EA5E9),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สรุปการใช้พลังงานและทรัพยากร',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'สัปดาห์นี้',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. Executive Integrated Dual Metric Panel (Clean Split Bar)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                // Electricity Metric Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF97316),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'ไฟฟ้า',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 10,
                                  color: Color(0xFFEF4444),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '+8%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: '142 ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                height: 1.0,
                              ),
                            ),
                            TextSpan(
                              text: 'kWh',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Micro Progress Indicator
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.65,
                          minHeight: 4,
                          backgroundColor: const Color(
                            0xFFF97316,
                          ).withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFFF97316),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Crisp Divider
                Container(
                  height: 56,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0xFFE2E8F0),
                ),

                // Water Metric Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0EA5E9),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'น้ำ',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 10,
                                  color: Color(0xFF10B981),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '-4%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: '18.5 ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                height: 1.0,
                              ),
                            ),
                            TextSpan(
                              text: 'm³',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Micro Progress Indicator
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.42,
                          minHeight: 4,
                          backgroundColor: const Color(
                            0xFF0EA5E9,
                          ).withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF0EA5E9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Chart Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ค่าเฉลี่ยรายวัน',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF97316),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'ไฟฟ้า',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0EA5E9),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'น้ำ',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Dual-Line Chart Canvas
          SizedBox(
            height: 130,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return MouseRegion(
                  onHover: (event) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final localX = box.globalToLocal(event.position).dx;
                      final ratio = (localX / box.size.width).clamp(0.0, 1.0);
                      final index = (ratio * (_days.length - 1)).round();
                      if (index != _selectedDayIdx) {
                        setState(() {
                          _selectedDayIdx = index;
                        });
                      }
                    }
                  },
                  child: CustomPaint(
                    painter: _MembersGradientAreaChartPainter(
                      electricValues: _electricByDay,
                      waterValues: _waterByDay,
                      selectedDayIdx: _selectedDayIdx,
                      pulsePhase: _pulseController.value,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // X-Axis Timeline Day Pills (จ., อ., พ., พฤ., ศ.)
          Row(
            children: List.generate(_days.length, (idx) {
              final isSelected = idx == _selectedDayIdx;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIdx = idx;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF3E8FF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _days[idx],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF9333EA)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MembersGradientAreaChartPainter extends CustomPainter {
  final List<double> electricValues;
  final List<double> waterValues;
  final int selectedDayIdx;
  final double pulsePhase;

  _MembersGradientAreaChartPainter({
    required this.electricValues,
    required this.waterValues,
    required this.selectedDayIdx,
    required this.pulsePhase,
  });

  static const _electricColor = Color(0xFFF97316);
  static const _waterColor = Color(0xFF0EA5E9);
  static const _electricGlow = Color(0xFFFDBA74);
  static const _waterGlow = Color(0xFF7DD3FC);

  List<Offset> _buildPoints(
    List<double> values,
    double w,
    double h,
    double topFraction,
    double bottomFraction,
  ) {
    final maxVal = values.reduce(math.max) * 1.15;
    final minVal = values.reduce(math.min) * 0.7;
    final count = values.length;
    final band = bottomFraction - topFraction;
    return [
      for (var i = 0; i < count; i++)
        Offset(
          (w / (count - 1)) * i,
          h * bottomFraction -
              (h * band) * ((values[i] - minVal) / (maxVal - minVal)),
        ),
    ];
  }

  Path _buildCurve(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final electricPoints = _buildPoints(electricValues, w, h, 0.06, 0.52);
    final waterPoints = _buildPoints(waterValues, w, h, 0.58, 0.92);
    final electricCurve = _buildCurve(electricPoints);
    final waterCurve = _buildCurve(waterPoints);

    final waterFillPath = Path.from(waterCurve)
      ..lineTo(w, h * 0.92)
      ..lineTo(0, h * 0.92)
      ..close();

    final electricFillPath = Path.from(electricCurve)
      ..lineTo(w, h * 0.92)
      ..lineTo(0, h * 0.92)
      ..close();

    final gradientRect = Rect.fromLTWH(0, 0, w, h);

    // 1. Water Gradient Fill (Cyan Soft Shading Under Water Curve)
    canvas.drawPath(
      waterFillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _waterColor.withValues(alpha: 0.22),
            _waterColor.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.50, w, h * 0.45))
        ..style = PaintingStyle.fill,
    );

    // 2. Electric Gradient Fill (Orange Soft Shading Overlapping smoothly with Water Shading)
    canvas.drawPath(
      electricFillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _electricColor.withValues(alpha: 0.26),
            _electricColor.withValues(alpha: 0.03),
          ],
        ).createShader(gradientRect)
        ..style = PaintingStyle.fill,
    );

    // Horizontal Gradient Stroke for Electric Curve (Light Orange -> Rich Deep Orange)
    final electricStrokeGradient = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFFFFD8A8), // Light Pastel Orange (อ่อน)
        Color(0xFFFB923C), // Vibrant Orange (กลาง)
        Color(0xFFEA580C), // Deep Rich Orange (เข้ม)
      ],
      stops: [0.0, 0.5, 1.0],
    );

    // Horizontal Gradient Stroke for Water Curve (Light Cyan -> Rich Deep Blue)
    final waterStrokeGradient = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFFBAE6FD), // Light Pastel Cyan (อ่อน)
        Color(0xFF38BDF8), // Vibrant Cyan (กลาง)
        Color(0xFF0284C7), // Deep Rich Blue (เข้ม)
      ],
      stops: [0.0, 0.5, 1.0],
    );

    canvas.drawPath(
      electricCurve,
      Paint()
        ..shader = electricStrokeGradient.createShader(gradientRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      waterCurve,
      Paint()
        ..shader = waterStrokeGradient.createShader(gradientRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    _drawGlowBeam(canvas, electricCurve, _electricGlow, pulsePhase, 3.0);
    _drawGlowBeam(
      canvas,
      waterCurve,
      _waterGlow,
      (pulsePhase + 0.5) % 1.0,
      2.4,
    );

    final idx = selectedDayIdx.clamp(0, electricPoints.length - 1);
    final electricNode = electricPoints[idx];
    final waterNode = waterPoints[idx];

    final focusPaint = Paint()
      ..color = const Color(0xFFE2D9F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(electricNode.dx, math.min(electricNode.dy, waterNode.dy) - 14),
      Offset(electricNode.dx, h),
      focusPaint,
    );

    canvas.drawCircle(electricNode, 5.0, Paint()..color = _electricColor);
    canvas.drawCircle(
      electricNode,
      5.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(waterNode, 4.5, Paint()..color = _waterColor);
    canvas.drawCircle(
      waterNode,
      4.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _drawTooltipPill(
      canvas,
      electricNode,
      '${electricValues[idx].toStringAsFixed(0)} kWh',
      _electricColor,
    );
    _drawTooltipPill(
      canvas,
      waterNode,
      '${waterValues[idx].toStringAsFixed(1)} m³',
      _waterColor,
    );
  }

  void _drawGlowBeam(
    Canvas canvas,
    Path path,
    Color color,
    double phase,
    double strokeWidth,
  ) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final totalLen = metric.length;
      final headDist = totalLen * phase;
      final tailLen = totalLen * 0.26;
      final pulsePath = metric.extractPath(
        (headDist - tailLen).clamp(0.0, totalLen),
        headDist.clamp(0.0, totalLen),
      );
      canvas.drawPath(
        pulsePath,
        Paint()
          ..color = color.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3.5),
      );
      canvas.drawPath(
        pulsePath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  void _drawTooltipPill(Canvas canvas, Offset point, String text, Color bg) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillW = textPainter.width + 16;
    const pillH = 22.0;
    final pillOffset = Offset(
      (point.dx - pillW / 2).clamp(0.0, double.infinity),
      point.dy - pillH - 8,
    );
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillOffset.dx, pillOffset.dy, pillW, pillH),
      const Radius.circular(11),
    );

    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0x1F000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(rect, Paint()..color = bg);
    textPainter.paint(
      canvas,
      Offset(
        pillOffset.dx + (pillW - textPainter.width) / 2,
        pillOffset.dy + (pillH - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _MembersGradientAreaChartPainter oldDelegate) =>
      true;
}

Widget _buildSoftGlassAssignmentCardsSection() {
  final mockAssignments = [
    AssignmentModel(
      id: 'assign-1',
      title: 'ใบงานทดลองที่ 3: การวัดและวิเคราะห์ค่าฝุ่น PM2.5 ในห้องเรียน',
      instructions:
          'ให้นักเรียนใช้ชุดทดลอง AIoT อ่านค่า PM2.5 บันทึกค่าลงตาราง และวิเคราะห์ช่วงเวลาที่มีฝุ่นสูง พร้อมเสนอแนวทางแก้ไข',
      type: 'ใบงานทดลอง',
      courseName: 'ม.5/2 การออกแบบเทคโนโลยี',
      dueDate: '15 ส.ค. 2026 (23:59 น.)',
      isGroupWork: true,
      rubricTitle: 'เกณฑ์ประเมินโครงงาน STEM & AIoT (มาตรฐานโรงเรียน)',
      attachedSensorMetrics: ['PM2.5', 'อุณหภูมิ', 'ความชื้น'],
      status: 'เผยแพร่แล้ว',
      submittedCount: 22,
      totalStudents: 28,
      updatedAt: '10 ส.ค. 2026',
    ),
    AssignmentModel(
      id: 'assign-2',
      title: 'การบ้านบทที่ 2: วงจรรวมและการต่อสายสัญญาณไมโครคอนโทรลเลอร์',
      instructions:
          'วาดไดอะแกรมการต่อวงจรเซนเซอร์วัดความชื้นป้อนเข้ากับ ESP32 พร้อมเขียนคำอธิบายการทำงาน',
      type: 'การบ้าน',
      courseName: 'ม.5/2 การออกแบบเทคโนโลยี',
      dueDate: '18 ส.ค. 2026 (17:00 น.)',
      isGroupWork: false,
      rubricTitle: 'เกณฑ์ตรวจใบงานทดลองเซนเซอร์ (ม.5/2)',
      attachedSensorMetrics: ['อุณหภูมิ'],
      status: 'เผยแพร่แล้ว',
      submittedCount: 14,
      totalStudents: 28,
      updatedAt: '08 ส.ค. 2026',
    ),
    AssignmentModel(
      id: 'assign-3',
      title: 'โครงงานปลายภาค: ระบบเตือนภัยและเปิดพัดลมระบายอากาศอัตโนมัติ',
      instructions:
          'ออกแบบและสร้างต้นแบบฮาร์ดแวร์ AIoT ที่สามารถตรวจจับอุณหภูมิเกิน threshold แล้วสั่งเปิดพัดลมโมดูลรีเลย์อัตโนมัติ',
      type: 'โครงงาน AIoT',
      courseName: 'ม.5/2 การออกแบบเทคโนโลยี',
      dueDate: '30 ส.ค. 2026 (23:59 น.)',
      isGroupWork: true,
      rubricTitle: 'เกณฑ์ประเมินโครงงาน STEM & AIoT (มาตรฐานโรงเรียน)',
      attachedSensorMetrics: ['อุณหภูมิ', 'รีเลย์พัดลม', 'PM2.5'],
      status: 'ร่าง',
      submittedCount: 0,
      totalStudents: 28,
      updatedAt: '05 ส.ค. 2026',
    ),
  ];

  return Column(
    children: mockAssignments
        .map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _SoftGlassAssignmentCardItem(assignment: a),
          ),
        )
        .toList(),
  );
}

class _SoftGlassAssignmentCardItem extends StatelessWidget {
  const _SoftGlassAssignmentCardItem({required this.assignment});

  final AssignmentModel assignment;

  @override
  Widget build(BuildContext context) {
    final isPublished = assignment.isPublished;
    final progress = assignment.totalStudents > 0
        ? assignment.submittedCount / assignment.totalStudents
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPublished
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPublished
                      ? Icons.assignment_turned_in_rounded
                      : Icons.edit_document,
                  color: isPublished
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            assignment.type,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7E22CE),
                            ),
                          ),
                        ),
                        if (assignment.isGroupWork) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.groups_rounded,
                                  size: 11,
                                  color: Color(0xFF0284C7),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'งานกลุ่ม',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      assignment.title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assignment.instructions,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: TeacherPalette.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPublished
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPublished
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFFED7AA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPublished
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      assignment.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isPublished
                            ? const Color(0xFF047857)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Meta Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: TeacherPalette.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'กำหนดส่ง: ${assignment.dueDate}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.fact_check_outlined,
                      size: 13,
                      color: TeacherPalette.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      assignment.rubricTitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: TeacherPalette.primary,
                      ),
                    ),
                  ],
                ),
                if (assignment.attachedSensorMetrics.isNotEmpty) ...[
                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                  Row(
                    children: [
                      const Icon(
                        Icons.sensors_rounded,
                        size: 13,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'ผูกเซนเซอร์ AIoT:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          children: assignment.attachedSensorMetrics.map((m) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Footer Action & Progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ส่งแล้ว ${assignment.submittedCount}/${assignment.totalStudents} คน',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: TeacherPalette.ink,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: TeacherPalette.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          TeacherPalette.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              OutlinedButton.icon(
                onPressed: () =>
                    showTeacherMockAction(context, 'แก้ไขเกณฑ์การประเมิน'),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('แก้ไข'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TeacherPalette.ink,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () =>
                    showTeacherMockAction(context, 'ตรวจงานการ์ดนี้'),
                icon: const Icon(Icons.playlist_add_check_rounded, size: 15),
                label: const Text('ตรวจงาน'),

                style: FilledButton.styleFrom(
                  backgroundColor: TeacherPalette.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildClassesCarouselSection() {
  final sampleClasses = [
    (
      title: 'AIoT สมาร์ตแล็บเพื่อการเรียนรู้',
      code: 'AIOT-501',
      students: 'ม.5/2 · 32 คน',
      status: '2 งานค้าง',
      statusColor: const Color(0xFFEF4444),
      icon: Icons.memory_rounded,
      gradient: const [Color(0xFF3B1E63), Color(0xFF281245)],
    ),
    (
      title: 'ฟิสิกส์ประยุกต์และการทดลอง',
      code: 'PHYS-302',
      students: 'ม.5/1 · 30 คน',
      status: 'ส่งครบแล้ว',
      statusColor: const Color(0xFF10B981),
      icon: Icons.bolt_rounded,
      gradient: const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    ),
    (
      title: 'ชีววิทยาและสิ่งแวดล้อม',
      code: 'BIO-204',
      students: 'ม.4/3 · 35 คน',
      status: 'มีแจ้งเตือน',
      statusColor: const Color(0xFFF59E0B),
      icon: Icons.eco_rounded,
      gradient: const [Color(0xFFA855F7), Color(0xFF7E22CE)],
    ),
  ];

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TeacherPalette.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: TeacherPalette.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ห้องเรียนและรายวิชา',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: TeacherPalette.ink,
                  ),
                ),
                Text(
                  'รายวิชาที่กำลังสอนและสถานะของแต่ละห้อง',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TeacherPalette.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 620
                ? 2
                : 1;
            final itemWidth =
                (constraints.maxWidth - ((columns - 1) * 14)) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: sampleClasses
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      child: Container(
                        height: 166,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: item.gradient,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: item.gradient.last.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item.code,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      color: item.statusColor,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.people_alt_rounded,
                                  size: 13,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  item.students,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}

Widget _buildThreeDotsActionMenuSection(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ตัวอย่างการใช้งานเมนูปุ่ม 3 จุด (Kebab / More Options Menu)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'คลิกที่ไอคอน 3 จุด (⋮) ในการ์ดแต่ละใบเพื่อทดสอบเปิดเมนูดำเนินการ (แก้ไข, คัดลอก, ดูรายละเอียด, แชร์, ลบ)',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Card 1: Course Card
            Container(
              width: 330,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.laptop_chromebook_rounded,
                          color: Color(0xFF4F46E5),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AIoT System Design',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'รหัสวิชา: AIOT-501 • ม.5/2',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TeacherThreeDotsMenu(
                        itemTitle: 'วิชา AIoT System Design',
                        onSelected: (action) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'กดเลือก: "${action.name}" วิชา AIoT System Design',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF0F172A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card 2: Assignment Card
            Container(
              width: 330,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_rounded,
                          color: Color(0xFF059669),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ใบงานที่ 3: ESP32 Sensor',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'กำหนดส่ง: 15 ส.ค. 2569',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TeacherThreeDotsMenu(
                        itemTitle: 'ใบงานที่ 3: ESP32 Sensor',
                        onSelected: (action) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'กดเลือก: "${action.name}" ใบงานที่ 3',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor:
                                  action == TeacherActionType.delete
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF0F172A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildAnimatedStatusBadgesSection(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ป้ายบอกสถานะแบบแอนิเมชัน 6 รูปแบบ (Animated Status Badges & Pills)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'มาพร้อมเอฟเฟกต์แอนิเมชันเคลื่อนไหว (Pulse Glowing, Floating Icon, Spinning Ring, Progress Bar)',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // 1. สำเร็จ
            const AnimatedStatusBadge(
              type: StatusBadgeType.success,
              customText: 'ทำสำเร็จ (Success)',
            ),
            // 2. ไม่สำเร็จ
            const AnimatedStatusBadge(
              type: StatusBadgeType.failed,
              customText: 'ทำไม่สำเร็จ (Failed)',
            ),
            // 3. กำลังโหลด
            const AnimatedStatusBadge(
              type: StatusBadgeType.loading,
              customText: 'กำลังโหลด... (Loading)',
            ),
            // 4. กำลังอัปโหลด
            const AnimatedStatusBadge(
              type: StatusBadgeType.uploading,
              progress: 0.68,
            ),
            // 5. อัปโหลดไม่สำเร็จ
            AnimatedStatusBadge(
              type: StatusBadgeType.uploadFailed,
              customText: 'อัปโหลดไม่สำเร็จ',
              onRetry: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('กำลังลองอัปโหลดใหม่อีกครั้ง...'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFFD97706),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
            // 6. โหลดไม่สำเร็จ
            AnimatedStatusBadge(
              type: StatusBadgeType.loadFailed,
              customText: 'โหลดไม่สำเร็จ',
              onRetry: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('กำลังลองโหลดข้อมูลใหม่อีกครั้ง...'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF475569),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ),
  );
}

class InteractiveSingleLineScoreCard extends StatefulWidget {
  const InteractiveSingleLineScoreCard({super.key});

  @override
  State<InteractiveSingleLineScoreCard> createState() =>
      _InteractiveSingleLineScoreCardState();
}

class _InteractiveSingleLineScoreCardState
    extends State<InteractiveSingleLineScoreCard>
    with SingleTickerProviderStateMixin {
  static const _days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];
  static const _scores = [70, 78, 58, 64, 45];
  static const _levels = [
    'ดี',
    'ประหยัดมาก',
    'ปานกลาง',
    'ปานกลาง',
    'ควรปรับปรุง',
  ];
  static const _levelColors = [
    Color(0xFF059669),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFD97706),
    Color(0xFFDC2626),
  ];

  int _selectedDayIdx = 4;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentScore = _scores[_selectedDayIdx];
    final currentLevel = _levels[_selectedDayIdx];
    final currentColor = _levelColors[_selectedDayIdx];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📌 HEADER ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: Color(0xFFF97316),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.water_drop_rounded,
                      size: 16,
                      color: Color(0xFF0EA5E9),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'การใช้น้ำ-ไฟของห้องเรียนฉัน',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'รวมเป็นคะแนนเดียว (วัน${_days[_selectedDayIdx]}: ยิ่งสูง ยิ่งประหยัดดี)',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$currentScore',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: currentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'คะแนน',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: currentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: currentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: currentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ระดับ: $currentLevel',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: currentColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.circle, size: 8, color: currentColor),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 📈 CHART AREA
          SizedBox(
            height: 180,
            child: Row(
              children: [
                const SizedBox(
                  width: 110,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100 (ประหยัดมาก)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                      Text(
                        '50 (ปานกลาง)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '0 (ใช้เยอะมาก)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return MouseRegion(
                        onHover: (event) {
                          final box = context.findRenderObject() as RenderBox?;
                          if (box != null) {
                            final localX = box.globalToLocal(event.position).dx;
                            final ratio = (localX / box.size.width).clamp(
                              0.0,
                              1.0,
                            );
                            final index = (ratio * (_days.length - 1)).round();
                            if (index != _selectedDayIdx) {
                              setState(() {
                                _selectedDayIdx = index;
                              });
                            }
                          }
                        },
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: 1,
                                  color: const Color(0xFFE2E8F0),
                                ),
                                Container(
                                  height: 1,
                                  color: const Color(0xFFF1F5F9),
                                ),
                                Container(
                                  height: 1,
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ],
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _InteractiveSingleGradientLinePainter(
                                  scores: _scores,
                                  selectedDayIdx: _selectedDayIdx,
                                  pulsePhase: _pulseController.value,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 📅 X-AXIS DAY LABELS (Elevated White Pill for Selected Day matching Image)
          Row(
            children: [
              const SizedBox(width: 118),
              Expanded(
                child: Row(
                  children: List.generate(_days.length, (idx) {
                    final isSelected = idx == _selectedDayIdx;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDayIdx = idx;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? const [
                                    BoxShadow(
                                      color: Color(0x1A0F172A),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            _days[idx],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.tips_and_updates_rounded,
                  size: 16,
                  color: Color(0xFF059669),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '💡 คิดจากปริมาณน้ำและไฟที่ห้องใช้จริง ยิ่งใช้น้อย คะแนนยิ่งสูงขึ้น! 💡',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF059669),
                    ),
                    textAlign: TextAlign.center,
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

class _InteractiveSingleGradientLinePainter extends CustomPainter {
  _InteractiveSingleGradientLinePainter({
    required this.scores,
    required this.selectedDayIdx,
    required this.pulsePhase,
  });

  final List<int> scores;
  final int selectedDayIdx;
  final double pulsePhase;

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final xRatios = [0.08, 0.28, 0.48, 0.68, 0.92];
    final absolutePoints = List.generate(scores.length, (i) {
      final yRatio = (100 - scores[i]) / 100.0;
      return Offset(xRatios[i] * size.width, yRatio * size.height);
    });

    // 1. Create Smooth Bezier Curve Path
    final path = Path();
    path.moveTo(absolutePoints.first.dx, absolutePoints.first.dy);

    for (int i = 0; i < absolutePoints.length - 1; i++) {
      final p1 = absolutePoints[i];
      final p2 = absolutePoints[i + 1];
      final controlX = (p1.dx + p2.dx) / 2;
      path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
    }

    // 2. Draw Multi-Color Horizontal + Vertical Fading Area Gradient Fill (Matching User's Reference Screenshot)
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final Rect fillRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.saveLayer(fillRect, Paint());
    // Layer A: Horizontal Multi-Color Gradient (Coral -> Magenta -> Purple -> Blue)
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFB923C), // Coral / Orange (Jan / Mon)
            Color(0xFFF43F5E), // Pink / Magenta (Mar / Wed)
            Color(0xFFA855F7), // Purple / Indigo (May / Thu)
            Color(0xFF60A5FA), // Blue / Sky (Jul / Fri)
          ],
        ).createShader(fillRect)
        ..style = PaintingStyle.fill,
    );
    // Layer B: Vertical Top-to-Bottom Alpha Mask (Opaque top fading down to transparent bottom)
    canvas.drawRect(
      fillRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x88000000), // ~53% Opacity at top
            Color(0x05000000), // ~2% Opacity near bottom
          ],
        ).createShader(fillRect)
        ..blendMode = BlendMode.dstIn,
    );
    canvas.restore();

    // 3. Draw Multi-Color Gradient Stroke Line (Coral -> Pink -> Purple -> Blue)
    final linePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFFB923C),
          Color(0xFFF43F5E),
          Color(0xFFA855F7),
          Color(0xFF60A5FA),
        ],
      ).createShader(fillRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 4. Draw Thin Dark Vertical Focus Line from Tooltip down to bottom
    final idx = selectedDayIdx.clamp(0, absolutePoints.length - 1);
    final selectedPoint = absolutePoints[idx];

    final focusPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(selectedPoint.dx, selectedPoint.dy),
      Offset(selectedPoint.dx, size.height),
      focusPaint,
    );

    // 5. Draw Subtle Coral/Pink Data Point Nodes
    final nodeColors = [
      const Color(0xFFFB923C),
      const Color(0xFFF43F5E),
      const Color(0xFFA855F7),
      const Color(0xFF3B82F6),
      const Color(0xFF60A5FA),
    ];

    for (int i = 0; i < absolutePoints.length; i++) {
      final p = absolutePoints[i];
      final color = nodeColors[i % nodeColors.length];
      final isSelected = i == selectedDayIdx;

      if (isSelected) {
        // Selected Pulsing Node (Matching screenshot dot)
        canvas.drawCircle(
          p,
          7.0 + (pulsePhase * 2.5),
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          p,
          5.0,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          p,
          2.0,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
      } else {
        canvas.drawCircle(
          p,
          3.5,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      }
    }

    // 6. Draw Solid Black Floating Tooltip Pill (Matching Screenshot `632` Pill)
    _drawBlackTooltipPill(
      canvas,
      selectedPoint,
      '${scores[selectedDayIdx]} คะแนน',
    );
  }

  void _drawBlackTooltipPill(Canvas canvas, Offset point, String text) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    const paddingH = 14.0;
    const paddingV = 7.0;
    final bgWidth = textPainter.width + (paddingH * 2);
    final bgHeight = textPainter.height + (paddingV * 2);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(point.dx, point.dy - 24),
        width: bgWidth,
        height: bgHeight,
      ),
      const Radius.circular(16),
    );

    // Dark Elevated Drop Shadow
    canvas.drawRRect(
      rect.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
    );

    // Deep Black Pill Container Background
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFF09090B)
        ..style = PaintingStyle.fill,
    );

    // White Text
    textPainter.paint(
      canvas,
      Offset(
        point.dx - (textPainter.width / 2),
        point.dy - 24 - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant _InteractiveSingleGradientLinePainter oldDelegate,
  ) =>
      oldDelegate.selectedDayIdx != selectedDayIdx ||
      oldDelegate.pulsePhase != pulsePhase;
}
