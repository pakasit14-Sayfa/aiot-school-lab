import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';
import 'student_variant_school_home.dart';
import 'student_assignments_page.dart';
import 'student_course_catalog_page.dart';

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

  List<Widget> get _pages => [
    const StudentVariantSchoolHome(),
    StudentCourseCatalogPage(
      showAppBar: false,
      searchPopupTick: _courseSearchPopupTick,
    ),
    const StudentAssignmentsPage(),
    const _DummyGradesTab(),
    const _DummyProfileTab(),
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
              if (_currentIndex == 1)
                IconButton(
                  icon: const Icon(
                    Icons.search_rounded,
                    color: SchoolPalette.ink,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 1;
                      _courseSearchPopupTick.value++;
                    });
                  },
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔔 มีการแจ้งเตือนใหม่ 2 รายการ'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
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
                  child: IndexedStack(index: _currentIndex, children: _pages),
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
            onTap: () {
              setState(() {
                _currentIndex = 1;
                _courseSearchPopupTick.value++;
              });
            },
          ),
          const SizedBox(width: 10),
          _buildDesktopAction(
            icon: Icons.notifications_none_rounded,
            badge: true,
            onTap: () =>
                _showSnackbar(context, '🔔 มีการแจ้งเตือนใหม่ 2 รายการ'),
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

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
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

class _DummyProfileTab extends StatelessWidget {
  const _DummyProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_pin_rounded, size: 64, color: Color(0xFF0284C7)),
          SizedBox(height: 12),
          Text(
            '👤 ข้อมูลส่วนตัวนักเรียน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: SchoolPalette.ink,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'นายสายฟ้า เรียนดี · ชั้น ม.5/1 · เลขที่ 12',
            style: TextStyle(fontSize: 12.5, color: SchoolPalette.muted),
          ),
        ],
      ),
    );
  }
}
