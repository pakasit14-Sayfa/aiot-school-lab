import 'package:flutter/material.dart';
import 'teacher_redesign_prototype_page.dart';

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
  int _selectedTabIdx = 0; // 0: Controls, 1: Actions, 2: Interactions, 3: Accessibility

  // Interactive Control States (Knobs)
  bool _closeNestedOnClickAway = true;
  bool _closeOnSelect = true;
  bool _isDisabled = false;
  final bool _isLoading = false;
  String _buttonLabel = 'A very long action label that truncates';
  
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
            child: _selectedComponent == 'System Overview'
                ? _buildFullDesignSystemOverview()
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
                            Center(
                              child: _buildMewsComponentSample(),
                            ),
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
                              const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  // --- FULL DESIGN SYSTEM OVERVIEW (หน้ารวมส่วนประกอบทุกชิ้น 100%) ---
  Widget _buildFullDesignSystemOverview() {
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
                  BoxShadow(color: Color(0x0F0F172A), blurRadius: 14, offset: Offset(0, 5)),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.style_rounded, size: 28, color: TeacherPalette.primary),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ศูนย์รวมระบบดีไซน์และส่วนประกอบทั้งหมด (System Overview)',
                          style: TextStyle(color: TeacherPalette.ink, fontWeight: FontWeight.w900, fontSize: 17),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'แสดงผลส่วนประกอบดีไซน์ทั้งหมดในหน้าเดียว (โทนสี 85/15%, ปุ่มทุกแบบ, การ์ดเตือนทุกสี, อินพุตฟอร์ม, อวตารโปรไฟล์, และการ์ดแสดงผล)',
                          style: TextStyle(color: TeacherPalette.muted, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 1: COLORS
            _buildSectionHeader('1. โทนสีและสไตล์ดีไซน์ (Color Tokens & Theme)', 'ฐานสีหลัก Ocean Navy 85% ผสานสีสถานะ 15%', Icons.palette_rounded),
            const SizedBox(height: 12),
            _buildColorSwatchesCard(),
            const SizedBox(height: 24),

            // SECTION 2: BUTTONS & BADGES
            _buildSectionHeader('2. ปุ่มกดมาตรฐานและป้ายสถานะ (System Buttons & Badges)', 'ปุ่มดำเนินการหลัก ปุ่มรอง ปุ่มลบ และป้ายบอกสถานะสากล', Icons.smart_button_rounded),
            const SizedBox(height: 12),
            _buildButtonsAndBadgesCard(),
            const SizedBox(height: 24),

            // SECTION 3: ALERTS & BANNERS
            _buildSectionHeader('3. การ์ดและแบนเนอร์แจ้งเตือนระบบ (Alert & Banners)', 'แบนเนอร์เตือนสีส้ม เขียว ฟ้า แดง ครบทุกรูปแบบ', Icons.notifications_active_rounded),
            const SizedBox(height: 12),
            _buildAlertBannersCard(),
            const SizedBox(height: 24),

            // SECTION 4: MEDIA & AVATARS
            _buildSectionHeader('4. สื่อและรูปโปรไฟล์ผู้ใช้งาน (Media & Avatars)', 'อวตารทุกขนาด ตัวอักษรย่อ สถานะออนไลน์ และ Avatar Group', Icons.account_circle_rounded),
            const SizedBox(height: 12),
            _buildMediaAvatarsOverviewCard(),
            const SizedBox(height: 24),

            // SECTION 5: INPUTS & FORM CONTROLS
            _buildSectionHeader('5. ระบบแบบฟอร์มและการรับข้อมูล (Form Controls & Inputs)', 'ช่องกรอกข้อความ รหัสผ่าน ช่องค้นหา Checkbox, Radio, Switch', Icons.edit_note_rounded),
            const SizedBox(height: 12),
            _buildInputsOverviewCard(),
            const SizedBox(height: 24),

            // SECTION 6: CONTENT CARDS
            _buildSectionHeader('6. การ์ดแสดงผลบทเรียนและข้อสอบ (Item & Question Cards)', 'การ์ดใบงานความสูงเท่ากันเป๊ะ 100% และการ์ดโจทย์ข้อสอบ', Icons.space_dashboard_rounded),
            const SizedBox(height: 12),
            _buildContentCardsSection(),
            const SizedBox(height: 36),
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
            Text(title, style: const TextStyle(color: TeacherPalette.ink, fontWeight: FontWeight.w900, fontSize: 15.5)),
            Text(subtitle, style: const TextStyle(color: TeacherPalette.muted, fontWeight: FontWeight.w600, fontSize: 11.5)),
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
          const Text('โทนสีหลักธีมระบบ (85% Theme Base)', style: TextStyle(color: TeacherPalette.ink, fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _ColorTile(name: 'Primary Ocean', hex: '#235284', color: TeacherPalette.primary, textColor: Colors.white)),
              SizedBox(width: 8),
              Expanded(child: _ColorTile(name: 'Sky Bright', hex: '#B8E2F4', color: TeacherPalette.skyBright, textColor: TeacherPalette.ink)),
              SizedBox(width: 8),
              Expanded(child: _ColorTile(name: 'Page Slate', hex: '#F8FAFC', color: TeacherPalette.page, textColor: TeacherPalette.ink, border: true)),
            ],
          ),
          const SizedBox(height: 14),
          const Text('โทนสีฟังก์ชันแจ้งเตือน (15% Functional Accents)', style: TextStyle(color: TeacherPalette.ink, fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _ColorTile(name: 'Success Mint', hex: '#10B981', color: TeacherPalette.green, textColor: Colors.white)),
              SizedBox(width: 8),
              Expanded(child: _ColorTile(name: 'Warning Amber', hex: '#F97316', color: TeacherPalette.orange, textColor: Colors.white)),
              SizedBox(width: 8),
              Expanded(child: _ColorTile(name: 'Alert Red', hex: '#EF4444', color: TeacherPalette.red, textColor: Colors.white)),
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
                onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
                icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                label: const Text('ปุ่มหลัก (Primary Button)'),
                style: FilledButton.styleFrom(
                  backgroundColor: TeacherPalette.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('ปุ่มรอง (Outlined Button)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TeacherPalette.primary,
                  side: const BorderSide(color: TeacherPalette.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('ปุ่มลบ (Danger Button)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TeacherPalette.red,
                  side: const BorderSide(color: TeacherPalette.red),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TeacherPalette.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('เผยแพร่แล้ว', style: TextStyle(color: TeacherPalette.green, fontSize: 11.5, fontWeight: FontWeight.w900)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TeacherPalette.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('รอตรวจ 12 ชิ้น', style: TextStyle(color: TeacherPalette.orange, fontSize: 11.5, fontWeight: FontWeight.w900)),
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
            border: Border.all(color: TeacherPalette.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: TeacherPalette.orange, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('มี 12 งานส่งเข้ามาใหม่ รอคุณครูตรวจคะแนน', style: TextStyle(color: TeacherPalette.ink, fontWeight: FontWeight.w900, fontSize: 13)),
                    Text('วิชา โครงงานเซนเซอร์ (PBL-110)', style: TextStyle(color: TeacherPalette.muted, fontSize: 11.5)),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
                style: FilledButton.styleFrom(backgroundColor: TeacherPalette.orange),
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
          const Text('บทเรียนที่ 1: การต่อวงจรเซนเซอร์ GP2Y1014AU0F', style: TextStyle(color: TeacherPalette.ink, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            label: const Text('ตรวจงาน'),
            style: FilledButton.styleFrom(backgroundColor: TeacherPalette.primary),
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
                  decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mews & Design', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 14)),
                    Text('Storybook Workbench', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 11)),
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
                _buildTreeStoryItem('System Overview', 'Overview Gallery', _selectedComponent == 'System Overview'),
                _buildTreeStoryItem('Welcome', 'Introduction', _selectedStory == 'Introduction'),
                _buildTreeStoryItem('Design Tokens', 'Colors & Spacing', _selectedStory == 'Colors & Spacing'),
                const SizedBox(height: 12),

                _buildCategoryHeader('BUTTONS & ACTIONS'),
                _buildTreeComponentFolder(
                  'Button',
                  stories: ['Playground', 'Primary', 'Secondary', 'Clear/Ghost', 'Critical', 'Sizes', 'Loading State', 'Disabled State'],
                  isOpen: _selectedComponent == 'Button',
                ),
                _buildTreeComponentFolder(
                  'Dropdown Button',
                  stories: ['Playground', 'Playground With Groups', 'Truncated label', 'Icon Only', 'Full Width'],
                  isOpen: _selectedComponent == 'Dropdown Button',
                ),
                _buildTreeComponentFolder(
                  'Icon Button',
                  stories: ['Playground', 'Icon Only Variants', 'Primary', 'Ghost'],
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
                  stories: ['Playground', '2 Options', '3 Options', '4 Options'],
                  isOpen: _selectedComponent == 'Segmented Control',
                ),
                const SizedBox(height: 12),

                _buildCategoryHeader('FEEDBACK & NOTIFICATIONS'),
                _buildTreeComponentFolder(
                  'Alerts',
                  stories: ['Overview', 'Playground', 'Success Alert', 'Warning Alert', 'Info Alert', 'Critical Alert', 'With Action', 'Dismissible'],
                  isOpen: _selectedComponent == 'Alerts',
                ),
                _buildTreeComponentFolder(
                  'Badge',
                  stories: ['Overview', 'Playground', 'Numeric Badge', 'Status Badge', 'Dot Badge'],
                  isOpen: _selectedComponent == 'Badge',
                ),
                _buildTreeComponentFolder(
                  'Banner',
                  stories: ['Overview', 'Playground', 'Top Fixed Banner', 'Inline Banner'],
                  isOpen: _selectedComponent == 'Banner',
                ),
                _buildTreeComponentFolder(
                  'Chip',
                  stories: ['Playground', 'Filter Chip', 'Choice Chip', 'Removable Chip'],
                  isOpen: _selectedComponent == 'Chip',
                ),
                _buildTreeComponentFolder(
                  'Empty State',
                  stories: ['Overview', 'Playground', 'No Data', 'No Search Results'],
                  isOpen: _selectedComponent == 'Empty State',
                ),
                _buildTreeComponentFolder(
                  'Progress Indicator',
                  stories: ['Playground', 'Linear Progress', 'Circular Spinner'],
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
                  stories: ['Playground', 'Default Input', 'Password Input', 'Search Input', 'Error Input', 'Disabled Input'],
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
                  stories: ['Overview', 'Playground', 'Fallback Initials', 'Status Indicator', 'Sizes'],
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
                  stories: ['Overview', 'Interactive Card', 'Equal-Height Card'],
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
      child: Text(title, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.1)),
    );
  }

  Widget _buildTreeComponentFolder(String folderName, {required List<String> stories, bool isOpen = false}) {
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
                Icon(isOpen ? Icons.indeterminate_check_box_outlined : Icons.add_box_outlined, size: 14, color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(folderName, style: TextStyle(color: isSelectedFolder ? const Color(0xFF2563EB) : const Color(0xFF1E293B), fontWeight: isSelectedFolder ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
        if (isOpen)
          Column(
            children: stories.map((story) {
              return _buildTreeStoryItem(folderName, story, _selectedStory == story && isSelectedFolder);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTreeStoryItem(String componentName, String storyName, bool isSelected) {
    return Material(
      color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          _selectedComponent = componentName;
          _selectedStory = storyName;
        }),
        child: Padding(
          padding: const EdgeInsets.only(left: 38, right: 16, top: 7, bottom: 7),
          child: Row(
            children: [
              Icon(Icons.bookmark_outline_rounded, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  storyName,
                  style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155), fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, fontSize: 12.5),
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
          onPressed: _isDisabled ? null : () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(_buttonLabel),
        );
      } else if (story == 'Clear/Ghost') {
        return TextButton(
          onPressed: _isDisabled ? null : () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(_buttonLabel),
        );
      } else if (story == 'Critical') {
        return FilledButton.icon(
          onPressed: _isDisabled ? null : () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text('Delete Item'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else if (story == 'Sizes') {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 11),
              ),
              child: const Text('Small (32px)'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: const Text('Medium (40px)'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
          ),
        );
      }
      return FilledButton(
        onPressed: _isDisabled ? null : () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          onPressed: _isDisabled ? null : () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            padding: const EdgeInsets.all(14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Icon(Icons.more_vert_rounded, size: 20),
        );
      }
      if (story == 'Full Width') {
        return SizedBox(
          width: 380,
          child: FilledButton.icon(
            onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
            icon: const Text('Full Width Action Dropdown'),
            label: const Icon(Icons.keyboard_arrow_down_rounded),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      }
      return Container(
        constraints: const BoxConstraints(maxWidth: 240),
        child: FilledButton.icon(
          onPressed: _isDisabled ? null : () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
          icon: _isLoading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
              : const SizedBox.shrink(),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _buttonLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            IconButton.filled(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); }, icon: const Icon(Icons.add_rounded)),
            const SizedBox(width: 10),
            IconButton.outlined(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); }, icon: const Icon(Icons.edit_rounded)),
            const SizedBox(width: 10),
            IconButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); }, icon: const Icon(Icons.share_rounded)),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
              icon: const Icon(Icons.delete_outline_rounded),
              style: IconButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            ),
          ],
        );
      }
      return IconButton.filled(
        onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
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
              child: Text(_buttonLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
            _buildAlertBannerTile('Success', 'บันทึกข้อมูลเรียบร้อยแล้ว', const Color(0xFF10B981), Icons.check_circle_rounded),
            const SizedBox(height: 10),
            _buildAlertBannerTile('Warning', 'มี 12 งานส่งเข้ามาใหม่ รอคุณครูตรวจคะแนน', const Color(0xFFF97316), Icons.warning_amber_rounded),
            const SizedBox(height: 10),
            _buildAlertBannerTile('Info', 'ระบบสลับข้อสอบและตัวเลือกทำงานอยู่', const Color(0xFF2563EB), Icons.info_rounded),
            const SizedBox(height: 10),
            _buildAlertBannerTile('Critical', 'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', const Color(0xFFEF4444), Icons.error_outline_rounded),
          ],
        );
      }
      return _buildAlertBannerTile('Alert', 'มี 12 งานส่งเข้ามาใหม่ รอคุณครูตรวจคะแนนในรายวิชานี้', const Color(0xFFF97316), Icons.warning_amber_rounded);
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
          child: const Text('12 NEW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
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
          FilterChip(label: const Text('การทดลองทั้งหมด'), selected: true, onSelected: (_) {}),
          FilterChip(label: const Text('บทเรียน'), selected: false, onSelected: (_) {}),
          FilterChip(label: const Text('แบบทดสอบ'), selected: false, onSelected: (_) {}),
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
            Icon(Icons.folder_off_rounded, size: 48, color: TeacherPalette.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('ไม่พบข้อมูลรายการข้อสอบ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('ยังไม่มีการสร้างแบบทดสอบในวิชานี้ กดปุ่มด้านล่างเพื่อสร้างใหม่', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); }, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('+ สร้างข้อสอบใหม่')),
          ],
        ),
      );
    }

    // --- PROGRESS INDICATOR ---
    if (comp == 'Progress Indicator') {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 260, child: LinearProgressIndicator(value: 0.75, minHeight: 8)),
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
            Container(width: 120, height: 16, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 10),
            Container(width: 240, height: 12, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 6),
            Container(width: 180, height: 12, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6))),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          const Text('สลับข้อสอบอัตโนมัติ (Checked)', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
    }

    if (comp == 'Radio Button') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [Radio(value: 1, groupValue: 1, onChanged: (_) {}), const Text('ก. ตัวเลือกข้อที่ 1')]),
          Row(mainAxisSize: MainAxisSize.min, children: [Radio(value: 2, groupValue: 1, onChanged: (_) {}), const Text('ข. ตัวเลือกข้อที่ 2')]),
        ],
      );
    }

    if (comp == 'Switch / Toggle') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: true, onChanged: (_) {}),
          const SizedBox(width: 8),
          const Text('เผยแพร่ทันที (ON)', style: TextStyle(fontWeight: FontWeight.w800)),
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
          boxShadow: const [BoxShadow(color: Color(0x29000000), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline_rounded, size: 36, color: TeacherPalette.primary),
            const SizedBox(height: 10),
            const Text('ยืนยันการเผยแพร่ข้อสอบ?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('เมื่อเผยแพร่แล้ว นักเรียนในห้อง ม.5/1 จะสามารถเริ่มทำข้อสอบได้ทันที', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); }, child: const Text('ยกเลิก'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดทดลองใช้งานปุ่มเรียบร้อยแล้ว ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); }, child: const Text('ยืนยัน'))),
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
              const SnackBar(content: Text('แตะรูปโปรไฟล์ตัวอักษรย่อ "SF" (Sayfa) ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: const CircleAvatar(
            radius: 30,
            backgroundColor: TeacherPalette.primary,
            child: Text('SF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
          ),
        );
      }
      if (story == 'Status Indicator') {
        return InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('แตะรูปโปรไฟล์พร้อมป้ายสถานะออนไลน์ (Online Green) ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: TeacherPalette.skyBright,
                child: Icon(Icons.person_rounded, color: TeacherPalette.primary, size: 30),
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
              child: const CircleAvatar(radius: 14, backgroundColor: TeacherPalette.primary, child: Text('S', style: TextStyle(color: Colors.white, fontSize: 10))),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _toast(context, 'แตะโปรไฟล์ขนาด Medium (36px)'),
              child: const CircleAvatar(radius: 20, backgroundColor: TeacherPalette.skyDeep, child: Text('M', style: TextStyle(color: Colors.white, fontSize: 13))),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _toast(context, 'แตะโปรไฟล์ขนาด Large (48px)'),
              child: const CircleAvatar(radius: 28, backgroundColor: TeacherPalette.primary, child: Text('L', style: TextStyle(color: Colors.white, fontSize: 16))),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _toast(context, 'แตะโปรไฟล์ขนาด Extra Large (64px)'),
              child: const CircleAvatar(radius: 36, backgroundColor: TeacherPalette.orange, child: Text('XL', style: TextStyle(color: Colors.white, fontSize: 20))),
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
        onTap: () => _toast(context, 'แตะกลุ่มรูปโปรไฟล์นักเรียน (3 คน +5 เพิ่มเติม)'),
        child: SizedBox(
          width: 130,
          height: 48,
          child: Stack(
            children: [
              const Positioned(left: 0, child: CircleAvatar(radius: 20, backgroundColor: TeacherPalette.primary, child: Text('SF', style: TextStyle(color: Colors.white, fontSize: 12)))),
              const Positioned(left: 24, child: CircleAvatar(radius: 20, backgroundColor: TeacherPalette.green, child: Text('KR', style: TextStyle(color: Colors.white, fontSize: 12)))),
              const Positioned(left: 48, child: CircleAvatar(radius: 20, backgroundColor: TeacherPalette.orange, child: Text('AA', style: TextStyle(color: Colors.white, fontSize: 12)))),
              Positioned(
                left: 72,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1E293B),
                  child: const Text('+5', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default Catch-All Sample
    return FilledButton.icon(
      onPressed: _isDisabled ? null : () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กดปุ่มทดสอบระบบ Storybook สำเร็จ ✓'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)); },
      icon: const Icon(Icons.check_circle_rounded, size: 16),
      label: Text('$comp: $story'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildAlertBannerTile(String title, String body, Color color, IconData icon) {
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
          Expanded(child: Text(body, style: const TextStyle(color: TeacherPalette.ink, fontWeight: FontWeight.w800, fontSize: 12.5))),
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
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
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
              border: Border(bottom: BorderSide(color: selected ? const Color(0xFF2563EB) : Colors.transparent, width: 2.5)),
            ),
            child: Text(tabs[i], style: TextStyle(color: selected ? const Color(0xFF2563EB) : const Color(0xFF64748B), fontWeight: selected ? FontWeight.w900 : FontWeight.w700, fontSize: 13)),
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
          description: 'Clicking outside will close all nested overlays, like Select',
          defaultValue: '-',
          controlWidget: OutlinedButton(
            onPressed: () => setState(() => _closeNestedOnClickAway = !_closeNestedOnClickAway),
            style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), foregroundColor: const Color(0xFF1E293B), side: BorderSide.none),
            child: const Text('Set boolean', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        ),
        _buildControlTableRow(
          name: 'closeOnSelect',
          type: 'boolean',
          description: 'Automatically close dropdown when item is selected',
          defaultValue: 'true',
          controlWidget: OutlinedButton(
            onPressed: () => setState(() => _closeOnSelect = !_closeOnSelect),
            style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), foregroundColor: const Color(0xFF1E293B), side: BorderSide.none),
            child: const Text('Set boolean', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
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
              _segmentedBtn('False', !_isDisabled, () => setState(() => _isDisabled = false)),
              _segmentedBtn('True', _isDisabled, () => setState(() => _isDisabled = true)),
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
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          SizedBox(width: 220, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 12.5)), Text(type, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5))])),
          Expanded(child: Text(description, style: const TextStyle(color: Color(0xFF475569), fontSize: 11.5))),
          SizedBox(width: 100, child: Text(defaultValue, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5))),
          SizedBox(width: 220, child: Align(alignment: Alignment.centerLeft, child: controlWidget)),
        ],
      ),
    );
  }

  Widget _segmentedBtn(String text, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: active ? Colors.white : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(color: active ? const Color(0xFF2563EB) : const Color(0xFF64748B), fontWeight: FontWeight.w800, fontSize: 11.5)),
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({required this.name, required this.hex, required this.color, required this.textColor, this.border = false});
  final String name;
  final String hex;
  final Color color;
  final Color textColor;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14), border: border ? Border.all(color: TeacherPalette.border) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 2),
          Text(hex, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontWeight: FontWeight.w700, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _MewsGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x1894A3B8)..strokeWidth = 0.8;
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
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
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
          const Text('ขนาดรูปโปรไฟล์ (Avatar Sizes & Fallback Initials)', style: TextStyle(color: TeacherPalette.ink, fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 12),
          const Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: TeacherPalette.primary, child: Text('S', style: TextStyle(color: Colors.white, fontSize: 10))),
              SizedBox(width: 12),
              CircleAvatar(radius: 20, backgroundColor: TeacherPalette.skyDeep, child: Text('M', style: TextStyle(color: Colors.white, fontSize: 13))),
              SizedBox(width: 12),
              CircleAvatar(radius: 28, backgroundColor: TeacherPalette.primary, child: Text('SF', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900))),
              SizedBox(width: 12),
              CircleAvatar(radius: 36, backgroundColor: TeacherPalette.orange, child: Text('KR', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 18),
          const Text('กลุ่มโปรไฟล์นักเรียน (Avatar Group + Counter Badge)', style: TextStyle(color: TeacherPalette.ink, fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 10),
          SizedBox(
            width: 160,
            height: 44,
            child: Stack(
              children: [
                const Positioned(left: 0, child: CircleAvatar(radius: 20, backgroundColor: TeacherPalette.primary, child: Text('SF', style: TextStyle(color: Colors.white, fontSize: 12)))),
                const Positioned(left: 24, child: CircleAvatar(radius: 20, backgroundColor: TeacherPalette.green, child: Text('KR', style: TextStyle(color: Colors.white, fontSize: 12)))),
                const Positioned(left: 48, child: CircleAvatar(radius: 20, backgroundColor: TeacherPalette.orange, child: Text('AA', style: TextStyle(color: Colors.white, fontSize: 12)))),
                Positioned(
                  left: 72,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF1E293B),
                    child: const Text('+5', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่าน',
                    suffixIcon: const Icon(Icons.visibility_off_rounded, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Row(children: [Checkbox(value: true, onChanged: (_) {}), const Text('Checkbox (เปิดใช้งาน)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))]),
              const SizedBox(width: 16),
              Row(children: [Radio(value: 1, groupValue: 1, onChanged: (_) {}), const Text('Radio (เลือก)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))]),
              const SizedBox(width: 16),
              Row(children: [Switch(value: true, onChanged: (_) {}), const Text('Switch (ON)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))]),
            ],
          ),
        ],
      ),
    );
  }
  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message ✓'), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating),
    );
  }
