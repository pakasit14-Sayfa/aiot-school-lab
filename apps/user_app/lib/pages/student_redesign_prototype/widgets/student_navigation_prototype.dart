import 'dart:ui';
import 'package:flutter/material.dart';
import '../../notifications_page.dart';
import 'student_redesign_palette.dart';
import 'student_variant_school_home.dart';
import 'student_assignments_page.dart';
import 'student_course_catalog_page.dart';
import 'student_profile_page.dart';

class StudentNavigationPrototype extends StatefulWidget {
  const StudentNavigationPrototype({super.key});

  @override
  State<StudentNavigationPrototype> createState() =>
      _StudentNavigationPrototypeState();
}

class _StudentNavigationPrototypeState
    extends State<StudentNavigationPrototype> {
  int _currentIndex = 0;
  final ValueNotifier<int> _courseSearchPopupTick = ValueNotifier<int>(0);

  final List<String> _titles = [
    'หน้าแรกนักเรียน',
    'วิชาเรียนและบทเรียน',
    'ใบงานและการบ้าน',
    'สรุปคะแนน G-Score',
    'ข้อมูลส่วนตัวนักเรียน',
  ];

  @override
  void dispose() {
    _courseSearchPopupTick.dispose();
    super.dispose();
  }

  void _openInPlaceSearchDialog() {
    _showGlobalGlassSearchDialog(context);
  }

  void _openGlassNotificationModal() {
    _showGlassNotificationModal(context);
  }

  Future<void> _showGlassNotificationModal(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.topCenter,
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.only(
            left: 14,
            right: 14,
            top: 44,
            bottom: 20,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xF7FFFFFF),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: const Color(0x1F0F172A),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.10),
                      blurRadius: 40,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'การแจ้งเตือน',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ),
                            Material(
                              color: const Color(0xFFF1F5F9),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => Navigator.of(dialogContext).pop(),
                                child: const SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildGlassNotificationTile(
                          icon: Icons.assignment_rounded,
                          iconBg: const Color(0xFF0284C7),
                          title: 'การบ้านบทเรียนที่ 4 ครบกำหนดส่งพรุ่งนี้',
                          subtitle: 'วิชา AIoT สมาร์ตแล็บ • ม.5/1',
                          time: '10 น.',
                        ),
                        const SizedBox(height: 10),
                        _buildGlassNotificationTile(
                          icon: Icons.emoji_events_rounded,
                          iconBg: const Color(0xFFD97706),
                          title: 'บันทึกคะแนนสอบกลางภาควิชา AIoT สำเร็จ',
                          subtitle: 'ได้คะแนน 92/100 (ระดับดีเยี่ยม)',
                          time: '2 ชม.',
                        ),
                        const SizedBox(height: 10),
                        _buildGlassNotificationTile(
                          icon: Icons.campaign_rounded,
                          iconBg: const Color(0xFF2F8F5B),
                          title: 'แจ้งกำหนดการสอบประเมินสมรรถนะดิจิทัล',
                          subtitle: 'โรงเรียนวิทยาศาสตร์ประจำภูมิภาค',
                          time: '1 วัน',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsPage(),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F4F6),
                              foregroundColor: const Color(0xFF0F172A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: const Text(
                              'ดูการแจ้งเตือนทั้งหมด',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassNotificationTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF3), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: iconBg.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
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

  Future<void> _showGlobalGlassSearchDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              alignment: Alignment.topCenter,
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.only(
                left: 14,
                right: 14,
                top: 44,
                bottom: 20,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.10),
                          blurRadius: 40,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'ค้นหารายวิชาและบทเรียน',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                ),
                                Material(
                                  color: const Color(0xFFF1F5F9),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: const SizedBox(
                                      width: 34,
                                      height: 34,
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F5F9),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFE1E7EF),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  autofocus: true,
                                  onChanged: (val) =>
                                      setDialogState(() => query = val),
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF2F5F9),
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    border: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    hintText:
                                        'ค้นหารายวิชา บทเรียน หรือครูผู้สอน',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF8A97A8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(
                                        left: 14,
                                        right: 8,
                                      ),
                                      child: Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF8A97A8),
                                        size: 19,
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    suffixIcon: query.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear_rounded,
                                              size: 18,
                                              color: Color(0xFF64748B),
                                            ),
                                            onPressed: () => setDialogState(
                                              () => query = '',
                                            ),
                                          )
                                        : null,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _SearchFilterChip(
                                  label: 'ทั้งหมด',
                                  onPressed: () {},
                                  selected: true,
                                ),
                                _SearchFilterChip(
                                  label: 'AIoT',
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    setState(() => _currentIndex = 1);
                                  },
                                ),
                                _SearchFilterChip(
                                  label: 'วิทย์',
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    setState(() => _currentIndex = 1);
                                  },
                                ),
                                _SearchFilterChip(
                                  label: 'งานค้าง',
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    setState(() => _currentIndex = 2);
                                  },
                                ),
                                _SearchFilterChip(
                                  label: 'ครูสมชาย',
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    setState(() => _currentIndex = 1);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> get _pages => [
    const StudentVariantSchoolHome(),
    StudentCourseCatalogPage(
      showAppBar: false,
      searchPopupTick: _courseSearchPopupTick,
    ),
    const StudentAssignmentsPage(),
    const _DummyGradesTab(),
    const StudentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        if (isDesktop) {
          return _buildDesktopShell(context);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            centerTitle: true,
            title: Text(
              _titles[_currentIndex],
              style: const TextStyle(
                color: SchoolPalette.ink,
                fontSize: 17.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.search_rounded,
                  color: SchoolPalette.ink,
                  size: 24,
                ),
                tooltip: 'ค้นหารายวิชาและบทเรียน',
                onPressed: _openInPlaceSearchDialog,
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: SchoolPalette.ink,
                      size: 24,
                    ),
                    onPressed: _openGlassNotificationModal,
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE11D48),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFECFDF5),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/mascot_lion_clean.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: SchoolPalette.green,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildPrototypeBanner(context),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9), // Soft Apple Light Slate Grey
                    ),
                    child: IndexedStack(index: _currentIndex, children: _pages),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildDesktopShell(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF8),
      body: SafeArea(
        child: Row(
          children: [
            _buildDesktopSidebar(context),
            Expanded(
              child: Column(
                children: [
                  _buildDesktopTopBar(context),
                  _buildPrototypeBanner(context),
                  Expanded(
                    child: IndexedStack(index: _currentIndex, children: _pages),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          Text(
            _titles[_currentIndex],
            style: const TextStyle(
              color: SchoolPalette.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          _buildDesktopAction(
            icon: Icons.search_rounded,
            onTap: _openInPlaceSearchDialog,
          ),
          const SizedBox(width: 10),
          _buildDesktopAction(
            icon: Icons.notifications_none_rounded,
            badge: true,
            onTap: _openGlassNotificationModal,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: SchoolPalette.green,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'สายฟ้า',
                  style: TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.expand_more_rounded,
                  color: SchoolPalette.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAction({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(icon, color: SchoolPalette.ink, size: 22),
            ),
          ),
        ),
        if (badge)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFE11D48),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    final navItems = <_NavItem>[
      _NavItem(icon: Icons.home_rounded, label: 'หน้าแรก'),
      _NavItem(icon: Icons.menu_book_rounded, label: 'บทเรียน'),
      _NavItem(icon: Icons.assignment_rounded, label: 'ใบงาน'),
      _NavItem(icon: Icons.military_tech_rounded, label: 'คะแนน'),
      _NavItem(icon: Icons.person_rounded, label: 'โปรไฟล์'),
    ];

    return Container(
      width: 292,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3E33), Color(0xFF165042)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/mascot_lion_clean.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person_rounded, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AIoT Smart School',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Student Workspace',
                        style: TextStyle(
                          color: Color(0xFFA7F3D0),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: navItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = _currentIndex == index;
                return _DesktopNavTile(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => setState(() => _currentIndex = index),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFECFDF5),
                  child: Icon(
                    Icons.school_rounded,
                    color: SchoolPalette.green,
                    size: 18,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ห้องเรียนของฉัน',
                        style: TextStyle(
                          color: SchoolPalette.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ม.5/2 · ภาคเรียน 1/2569',
                        style: TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildPrototypeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7ED),
        border: Border(
          bottom: BorderSide(color: Color(0xFFFDBA74), width: 1.0),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_rounded, size: 14, color: Color(0xFFEA580C)),
          SizedBox(width: 6),
          Text(
            '🧪 โต๊ะลองงาน (PROTOTYPE SANDBOX) · สลับหน้าด้วย Bottom Nav & Drawer (3 ขีด)',
            style: TextStyle(
              color: Color(0xFFC2410C),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // 📱 Bottom Navigation Bar สไตล์พรีเมียมมินิมอล
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: SchoolPalette.green,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 11.5,
        unselectedFontSize: 11.5,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book_rounded),
            label: 'บทเรียน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'ใบงาน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.military_tech_outlined),
            activeIcon: Icon(Icons.military_tech_rounded),
            label: 'คะแนน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _SearchFilterChip extends StatelessWidget {
  const _SearchFilterChip({
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAF2FF) : const Color(0xFFF7F8FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? const Color(0xFFB7D1FF) : const Color(0xFFD9E1EA),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF243447),
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopNavTile extends StatelessWidget {
  const _DesktopNavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = const Color(0xFFECFDF5);
    final textColor = isSelected ? SchoolPalette.green : SchoolPalette.ink;
    final iconColor = isSelected
        ? SchoolPalette.green
        : const Color(0xFF64748B);

    return Material(
      color: isSelected ? selectedColor : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFA7F3D0)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: SchoolPalette.green,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DummyGradesTab extends StatelessWidget {
  const _DummyGradesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.military_tech_rounded,
            size: 64,
            color: SchoolPalette.green,
          ),
          SizedBox(height: 12),
          Text(
            '🏆 หน้าสรุปคะแนน G-Score และเหรียญรางวัล',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: SchoolPalette.ink,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'เกรดเฉลี่ยสะสม GPA 3.85 · ได้รับ 15 แบดจ์เกียรติยศ',
            style: TextStyle(fontSize: 12.5, color: SchoolPalette.muted),
          ),
        ],
      ),
    );
  }
}
