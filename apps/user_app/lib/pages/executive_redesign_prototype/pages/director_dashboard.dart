import 'dart:math' as math;
import 'package:flutter/material.dart';

class DirectorDashboard extends StatefulWidget {
  const DirectorDashboard({super.key});

  @override
  State<DirectorDashboard> createState() => _DirectorDashboardState();
}

class _DirectorDashboardState extends State<DirectorDashboard> {
  int selectedMenu = 0;
  int selectedPeriod = 0;

  final List<_SideMenuItem> menus = const [
    _SideMenuItem('ภาพรวม', Icons.home_rounded),
    _SideMenuItem('เหตุฉุกเฉิน', Icons.warning_amber_rounded),
    _SideMenuItem('ภาพรวมการเรียน', Icons.school_rounded),
    _SideMenuItem('ครูและการสอน', Icons.co_present_rounded),
    _SideMenuItem('ห้องเรียนและรายวิชา', Icons.meeting_room_rounded),
    _SideMenuItem('ประชุม / ขอพบ', Icons.calendar_month_rounded),
    _SideMenuItem('รายงาน', Icons.bar_chart_rounded),
    _SideMenuItem('การแจ้งเตือน', Icons.notifications_active_rounded),
    _SideMenuItem('ตั้งค่า', Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppColors.pageBg,
              child: SafeArea(
                child: _buildSidebar(closeOnTap: true),
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: 285,
                child: _buildSidebar(),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 18 : 12,
                  12,
                  isDesktop ? 18 : 12,
                  12,
                ),
                child: Column(
                  children: [
                    _buildTopBar(isDesktop),
                    const SizedBox(height: 12),
                    Expanded(child: _buildSelectedPage()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // TOP BAR
  // =========================
  Widget _buildTopBar(bool isDesktop) {
    return Row(
      children: [
        if (!isDesktop)
          Builder(
            builder: (context) => InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.menu_rounded),
              ),
            ),
          ),
        if (!isDesktop) const SizedBox(width: 10),
        Text(
          menus[selectedMenu].title,
          style: TextStyle(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const Spacer(),
        _topIcon(Icons.search_rounded),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _topIcon(Icons.notifications_none_rounded),
            Positioned(
              right: 8,
              top: 7,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        if (isDesktop)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.sidebarPink,
                  child: Icon(
                    Icons.person_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Director',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _topIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 20, color: AppColors.textDark),
    );
  }

  // =========================
  // SIDEBAR
  // =========================
  Widget _buildSidebar({bool closeOnTap = false}) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.sidebarSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.sidebarPink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AIoT Smart Lab',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ศูนย์ควบคุมสำหรับผู้อำนวยการ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: menus.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = menus[index];
                final selected = selectedMenu == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    setState(() => selectedMenu = index);
                    if (closeOnTap && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.sidebarSelectedBg
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.sidebarPink
                                : AppColors.sidebarIconBg,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            item.icon,
                            size: 20,
                            color: selected
                                ? Colors.white
                                : AppColors.sidebarIcon,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w600,
                              color: selected
                                  ? AppColors.sidebarPink
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                        if (index == 1)
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.sidebarPink,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sidebarSelectedBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.sidebarPink,
                  child: Icon(Icons.person_rounded, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ผู้อำนวยการโรงเรียน',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Director',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPage() {
    switch (selectedMenu) {
      case 0:
        return _buildOverviewPage();
      case 1:
        return _buildSimplePage(
          title: 'เหตุฉุกเฉิน',
          subtitle: 'รายการแจ้งเหตุสำคัญของโรงเรียน',
          items: const [
            _PageListData(
              Icons.warning_amber_rounded,
              AppColors.redAccent,
              'ตรวจพบเหตุทะเลาะวิวาท',
              'อาคาร 2 ชั้น 3 • 10:24 น.',
              'กำลังตรวจสอบ',
            ),
            _PageListData(
              Icons.personal_injury_rounded,
              AppColors.chartPink,
              'ตรวจพบนักเรียนล้ม',
              'อาคาร 1 ชั้น 2 • 08:42 น.',
              'ช่วยเหลือแล้ว',
            ),
          ],
        );
      case 2:
        return _buildLearningPage();
      case 3:
        return _buildSimplePage(
          title: 'ครูและการสอน',
          subtitle: 'ภาพรวมการเข้าสอนของครูแยกตามกลุ่มสาระ',
          items: const [
            _PageListData(
              Icons.menu_book_rounded,
              AppColors.chartPink,
              'ภาษาไทย',
              'ครู 8 คน • สอนครบ 98%',
              'ปกติ',
            ),
            _PageListData(
              Icons.calculate_rounded,
              AppColors.chartPink2,
              'คณิตศาสตร์',
              'ครู 10 คน • สอนครบ 96%',
              'ปกติ',
            ),
            _PageListData(
              Icons.science_rounded,
              AppColors.chartCream,
              'วิทยาศาสตร์',
              'ครู 12 คน • สอนครบ 97%',
              'ปกติ',
            ),
          ],
        );
      case 4:
        return _buildSimplePage(
          title: 'ห้องเรียนและรายวิชา',
          subtitle: 'ดูข้อมูลห้องเรียนและรายวิชาต่าง ๆ',
          items: const [
            _PageListData(
              Icons.meeting_room_rounded,
              AppColors.sidebarPink,
              'ม.1/1',
              '36 คน • ห้อง 101',
              'ดูรายละเอียด',
            ),
            _PageListData(
              Icons.meeting_room_rounded,
              AppColors.chartPink2,
              'ม.4/1 วิทย์-คณิต',
              '32 คน • ห้อง 401',
              'ดูรายละเอียด',
            ),
          ],
        );
      case 5:
        return _buildMeetingPage();
      case 6:
        return _buildSimplePage(
          title: 'รายงาน',
          subtitle: 'รายงานรายวัน รายสัปดาห์ และรายเดือน',
          items: const [
            _PageListData(
              Icons.today_rounded,
              AppColors.chartPink,
              'รายงานประจำวัน',
              'ภาพรวมโรงเรียนวันนี้',
              'เปิดรายงาน',
            ),
            _PageListData(
              Icons.calendar_month_rounded,
              AppColors.chartCream,
              'รายงานประจำเดือน',
              'สรุปแนวโน้มรายเดือน',
              'เปิดรายงาน',
            ),
          ],
        );
      case 7:
        return _buildSimplePage(
          title: 'การแจ้งเตือน',
          subtitle: 'รายการแจ้งเตือนสำคัญทั้งหมด',
          items: const [
            _PageListData(
              Icons.notifications_active_rounded,
              AppColors.redAccent,
              'แจ้งเตือนเหตุฉุกเฉินใหม่',
              'อาคาร 2 • 10:24 น.',
              'ใหม่',
            ),
            _PageListData(
              Icons.groups_rounded,
              AppColors.chartPink,
              'นักเรียนขาดเรียนสูง',
              'ม.5/2 ขาด 8 คน',
              'ตรวจสอบ',
            ),
          ],
        );
      case 8:
        return _buildSimplePage(
          title: 'ตั้งค่า',
          subtitle: 'ตั้งค่าบัญชี การแจ้งเตือน และความปลอดภัย',
          items: const [
            _PageListData(
              Icons.person_outline_rounded,
              AppColors.sidebarPink,
              'ข้อมูลบัญชี',
              'แก้ไขข้อมูลผู้ใช้งาน',
              'แก้ไข',
            ),
            _PageListData(
              Icons.security_rounded,
              AppColors.chartPink2,
              'ความปลอดภัย',
              'รหัสผ่านและการเข้าสู่ระบบ',
              'ตั้งค่า',
            ),
          ],
        );
      default:
        return _buildOverviewPage();
    }
  }

  // =========================
  // OVERVIEW
  // =========================
  Widget _buildOverviewPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 980;

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHero(width),
              const SizedBox(height: 16),
              _buildPeriodSelector(),
              const SizedBox(height: 16),
              _buildSummaryCards(width),
              const SizedBox(height: 16),
              if (!compact)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildLearningOverviewCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildUtilityCard()),
                  ],
                )
              else ...[
                _buildLearningOverviewCard(),
                const SizedBox(height: 16),
                _buildUtilityCard(),
              ],
              const SizedBox(height: 16),
              if (!compact)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildTrendChartCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildImportantTodayCard()),
                  ],
                )
              else ...[
                _buildTrendChartCard(),
                const SizedBox(height: 16),
                _buildImportantTodayCard(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(double width) {
    final isPhone = width < 700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.heroPink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: isPhone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroText(),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: _heroMascot(),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _heroText()),
                const SizedBox(width: 20),
                _heroMascot(),
              ],
            ),
    );
  }

  Widget _heroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.heroTag,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'ศูนย์ควบคุมสำหรับผู้อำนวยการโรงเรียน',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'ภาพรวมโรงเรียน\nAIoT Smart Lab',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.12,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'ติดตามการเรียน ครู เหตุฉุกเฉิน พลังงาน น้ำ และสภาพแวดล้อมในหน้าเดียว',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _HeroTag(icon: Icons.cloud_done_rounded, text: 'ระบบออนไลน์'),
            _HeroTag(icon: Icons.schedule_rounded, text: 'อัปเดตล่าสุด 2 นาที'),
            _HeroTag(icon: Icons.verified_rounded, text: 'สถานะปกติ'),
          ],
        ),
      ],
    );
  }

  Widget _heroMascot() {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Center(
        child: CircleAvatar(
          radius: 42,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.smart_toy_rounded,
            size: 58,
            color: AppColors.sidebarPink,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    const labels = ['รายวัน', 'สัปดาห์', 'เดือน'];

    return Row(
      children: [
        const Expanded(
          child: Text(
            'ภาพรวมข้อมูล',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.sidebarSelectedBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: List.generate(labels.length, (index) {
              final active = selectedPeriod == index;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => selectedPeriod = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? AppColors.textDark
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(double width) {
    final items = [
      const _SummaryCardData(
        'นักเรียนมาเรียน',
        '1,248',
        'จาก 1,320 คน',
        '+2.4%',
        Icons.groups_rounded,
        AppColors.softPink,
      ),
      const _SummaryCardData(
        'ครูเข้าสอน',
        '58',
        'จาก 61 คน',
        '97%',
        Icons.co_present_rounded,
        AppColors.softCream,
      ),
      const _SummaryCardData(
        'เหตุฉุกเฉิน',
        '1',
        'กำลังติดตาม',
        'ด่วน',
        Icons.warning_amber_rounded,
        AppColors.softPink2,
      ),
      const _SummaryCardData(
        'ภาพรวมการเรียน',
        '94%',
        'การเข้าเรียนรวม',
        'ดูรายละเอียด',
        Icons.school_rounded,
        AppColors.softBlueCard,
      ),
    ];

    int columns = 4;
    if (width < 650) {
      columns = 1;
    } else if (width < 1000) {
      columns = 2;
    }

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: columns == 1 ? 3.2 : 1.65,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: index == 3 ? () => setState(() => selectedMenu = 2) : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item.bg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 39,
                      height: 39,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(item.icon, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      item.badge,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.sub,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLearningOverviewCard() {
    final grades = [
      const _GradeBarData('ม.1', 95, AppColors.chartPink),
      const _GradeBarData('ม.2', 94, AppColors.chartPink2),
      const _GradeBarData('ม.3', 96, AppColors.chartCream),
      const _GradeBarData('ม.4', 93, AppColors.chartPink3),
      const _GradeBarData('ม.5', 92, AppColors.chartPink),
      const _GradeBarData('ม.6', 97, AppColors.chartPink2),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ภาพรวมการเรียน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'แยกตามระดับชั้น ม.1 - ม.6',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => selectedMenu = 2),
                child: const Text('ดูทั้งหมด'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 215,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: grades.map((item) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${item.percent}%',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: item.percent / 100,
                              widthFactor: 0.72,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: item.color,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ทรัพยากรวันนี้',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'เปรียบเทียบกับค่าเฉลี่ยปกติ',
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          _utilityRow(
            'ไฟฟ้า',
            '427 kWh',
            0.74,
            AppColors.chartPink,
            Icons.bolt_rounded,
          ),
          _utilityRow(
            'น้ำ',
            '16.8 m³',
            0.58,
            AppColors.chartPink2,
            Icons.water_drop_rounded,
          ),
          _utilityRow(
            'PM2.5',
            '18 µg/m³',
            0.36,
            AppColors.chartCream,
            Icons.air_rounded,
          ),
          _utilityRow(
            'อุณหภูมิ',
            '27.5 °C',
            0.64,
            AppColors.chartPink3,
            Icons.thermostat_rounded,
          ),
        ],
      ),
    );
  }

  Widget _utilityRow(
    String title,
    String value,
    double progress,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: AppColors.softTag,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChartCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'แนวโน้มการใช้ทรัพยากร',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'พลังงานและน้ำตามช่วงเวลา',
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _BarChartPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantTodayCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สิ่งที่ควรทราบวันนี้',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _importantItem(
            AppColors.redAccent,
            Icons.sports_martial_arts_rounded,
            'เหตุทะเลาะวิวาท',
            'อาคาร 2 ชั้น 3 • 10:24 น.',
          ),
          _importantItem(
            AppColors.chartPink,
            Icons.groups_rounded,
            'ม.5/2 ขาดเรียนสูง',
            'ขาดเรียน 8 คน',
          ),
          _importantItem(
            AppColors.chartCream,
            Icons.bolt_rounded,
            'ใช้ไฟสูงกว่าปกติ',
            'อาคาร 3 สูงขึ้น 18%',
          ),
          _importantItem(
            AppColors.sidebarPink,
            Icons.calendar_month_rounded,
            'มีนัดประชุมวันนี้',
            'ประชุมฝ่ายบริหาร 15:00 น.',
          ),
        ],
      ),
    );
  }

  Widget _importantItem(
    Color color,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.8,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // LEARNING PAGE
  // =========================
  Widget _buildLearningPage() {
    final grades = [
      const _LearningLevelData('ม.1', 198, 6, 95, AppColors.chartPink),
      const _LearningLevelData('ม.2', 204, 6, 94, AppColors.chartPink2),
      const _LearningLevelData('ม.3', 206, 6, 96, AppColors.chartCream),
      const _LearningLevelData('ม.4', 224, 6, 93, AppColors.chartPink3),
      const _LearningLevelData('ม.5', 238, 6, 92, AppColors.chartPink),
      const _LearningLevelData('ม.6', 250, 6, 97, AppColors.chartPink2),
    ];

    final programs = [
      const _ProgramData(
        'วิทย์ - คณิต',
        154,
        6,
        95,
        Icons.science_rounded,
        AppColors.softPink,
      ),
      const _ProgramData(
        'สายภาษา',
        102,
        4,
        94,
        Icons.translate_rounded,
        AppColors.softCream,
      ),
      const _ProgramData(
        'สายทั่วไป',
        96,
        4,
        92,
        Icons.menu_book_rounded,
        AppColors.softBlueCard,
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'ภาพรวมการเรียน',
            'แยกตามระดับชั้นและสายการเรียน',
          ),
          const SizedBox(height: 16),
          _learningMiniSummary(),
          const SizedBox(height: 20),
          const Text(
            'แยกตามระดับชั้น',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = 3;
              if (constraints.maxWidth < 650) {
                columns = 1;
              } else if (constraints.maxWidth < 1000) {
                columns = 2;
              }

              return GridView.builder(
                itemCount: grades.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: columns == 1 ? 3.0 : 1.65,
                ),
                itemBuilder: (context, index) {
                  final item = grades[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _showGradeDialog(item),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _whiteCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: item.color.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  color: item.color,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${item.attendance}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: item.color,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            item.grade,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${item.students} คน • ${item.rooms} ห้องเรียน',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 9),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: item.attendance / 100,
                              minHeight: 8,
                              backgroundColor: AppColors.softTag,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(item.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'แยกตามสายการเรียน',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              int columns = 3;
              if (constraints.maxWidth < 650) {
                columns = 1;
              } else if (constraints.maxWidth < 1000) {
                columns = 2;
              }

              return GridView.builder(
                itemCount: programs.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: columns == 1 ? 3.0 : 1.55,
                ),
                itemBuilder: (context, index) {
                  final item = programs[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _showProgramDialog(item),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: item.bg,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${item.students} คน • ${item.rooms} ห้องเรียน',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'เข้าเรียน ${item.attendance}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _learningMiniSummary() {
    final items = [
      const _MiniData('นักเรียนทั้งหมด', '1,320', Icons.groups_rounded),
      const _MiniData('มาเรียนวันนี้', '1,248', Icons.how_to_reg_rounded),
      const _MiniData('ห้องเรียน', '36', Icons.meeting_room_rounded),
      const _MiniData('ต้องติดตาม', '28', Icons.flag_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 650) {
          columns = 1;
        } else if (constraints.maxWidth < 950) {
          columns = 2;
        }

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 3.4 : 2.0,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(15),
              decoration: _whiteCard(),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.softPink,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon, color: AppColors.chartPink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGradeDialog(_LearningLevelData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ข้อมูลระดับชั้น ${data.grade}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogRow('นักเรียนทั้งหมด', '${data.students} คน'),
              _dialogRow('จำนวนห้อง', '${data.rooms} ห้อง'),
              _dialogRow('การเข้าเรียน', '${data.attendance}%'),
              const Divider(),
              ...List.generate(
                data.rooms,
                (index) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.meeting_room_rounded),
                  title: Text('${data.grade}/${index + 1}'),
                  subtitle: const Text('ดูข้อมูลห้องเรียน'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _showProgramDialog(_ProgramData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data.title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogRow('นักเรียนทั้งหมด', '${data.students} คน'),
              _dialogRow('ห้องเรียน', '${data.rooms} ห้อง'),
              _dialogRow('การเข้าเรียน', '${data.attendance}%'),
              const Divider(),
              const ListTile(
                dense: true,
                leading: Icon(Icons.school_rounded),
                title: Text('ม.4'),
              ),
              const ListTile(
                dense: true,
                leading: Icon(Icons.school_rounded),
                title: Text('ม.5'),
              ),
              const ListTile(
                dense: true,
                leading: Icon(Icons.school_rounded),
                title: Text('ม.6'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // =========================
  // SIMPLE PAGES
  // =========================
  Widget _buildSimplePage({
    required String title,
    required String subtitle,
    required List<_PageListData> items,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, subtitle),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: _whiteCard(),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(item.icon, color: item.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 9.8,
                        fontWeight: FontWeight.w700,
                        color: item.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('ประชุม / ขอพบ', 'จัดการนัดหมายกับครูและบุคลากร'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 700;
              if (narrow) {
                return Column(
                  children: [
                    _actionMeetingCard(
                      'เรียกประชุม',
                      Icons.groups_rounded,
                      AppColors.softPink,
                    ),
                    const SizedBox(height: 12),
                    _actionMeetingCard(
                      'ขอพบรายบุคคล',
                      Icons.person_search_rounded,
                      AppColors.softBlueCard,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _actionMeetingCard(
                      'เรียกประชุม',
                      Icons.groups_rounded,
                      AppColors.softPink,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _actionMeetingCard(
                      'ขอพบรายบุคคล',
                      Icons.person_search_rounded,
                      AppColors.softBlueCard,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const Text(
            'นัดหมายวันนี้',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _meetingTile('09:00', 'ประชุมฝ่ายบริหาร', 'ห้องประชุม 1'),
          _meetingTile(
            '11:00',
            'พบหัวหน้ากลุ่มสาระวิทยาศาสตร์',
            'ห้องผู้อำนวยการ',
          ),
          _meetingTile('15:00', 'ประชุมครูระดับชั้น ม.6', 'ห้องประชุมใหญ่'),
        ],
      ),
    );
  }

  Widget _actionMeetingCard(String title, IconData icon, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.textDark),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _meetingTile(String time, String title, String location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: _whiteCard(),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.chartPink,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _whiteCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.025),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

// =========================
// DATA
// =========================
class _SideMenuItem {
  final String title;
  final IconData icon;

  const _SideMenuItem(this.title, this.icon);
}

class _SummaryCardData {
  final String title;
  final String value;
  final String sub;
  final String badge;
  final IconData icon;
  final Color bg;

  const _SummaryCardData(
    this.title,
    this.value,
    this.sub,
    this.badge,
    this.icon,
    this.bg,
  );
}

class _GradeBarData {
  final String label;
  final int percent;
  final Color color;

  const _GradeBarData(this.label, this.percent, this.color);
}

class _LearningLevelData {
  final String grade;
  final int students;
  final int rooms;
  final int attendance;
  final Color color;

  const _LearningLevelData(
    this.grade,
    this.students,
    this.rooms,
    this.attendance,
    this.color,
  );
}

class _ProgramData {
  final String title;
  final int students;
  final int rooms;
  final int attendance;
  final IconData icon;
  final Color bg;

  const _ProgramData(
    this.title,
    this.students,
    this.rooms,
    this.attendance,
    this.icon,
    this.bg,
  );
}

class _MiniData {
  final String title;
  final String value;
  final IconData icon;

  const _MiniData(this.title, this.value, this.icon);
}

class _PageListData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String status;

  const _PageListData(
    this.icon,
    this.color,
    this.title,
    this.subtitle,
    this.status,
  );
}

// =========================
// COLORS
// =========================
class AppColors {
  static const Color pageBg = Color(0xFFFBF7F9);

  static const Color sidebarPink = Color(0xFFD85A8C);
  static const Color sidebarSurface = Color(0xFFFFF7FA);
  static const Color sidebarSelectedBg = Color(0xFFFBE6EF);
  static const Color sidebarIconBg = Color(0xFFF6EDF1);
  static const Color sidebarIcon = Color(0xFF8C7C84);

  static const Color heroPink = Color(0xFFE072A0);
  static const Color heroTag = Color(0xFFFFE082);

  static const Color textDark = Color(0xFF2B2430);
  static const Color textMuted = Color(0xFF8B7C86);

  static const Color border = Color(0xFFF0E5EA);

  static const Color softPink = Color(0xFFFCE8F0);
  static const Color softPink2 = Color(0xFFFBE3E1);
  static const Color softCream = Color(0xFFF9F2DD);
  static const Color softBlueCard = Color(0xFFEAF0FB);
  static const Color softTag = Color(0xFFF4EDF0);

  static const Color chartPink = Color(0xFFE35A8B);
  static const Color chartPink2 = Color(0xFFE796B3);
  static const Color chartPink3 = Color(0xFFECC1D1);
  static const Color chartCream = Color(0xFFE8C89B);

  static const Color redAccent = Color(0xFFD94141);
}

// =========================
// HERO TAG
// =========================
class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroTag({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// CHART
// =========================
class _BarChartPainter extends CustomPainter {
  final List<double> values = const [0.46, 0.72, 0.58, 0.84, 0.66, 0.93, 0.62, 0.78];

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final colors = [
      AppColors.chartPink3,
      AppColors.chartPink2,
      AppColors.chartPink3,
      AppColors.chartPink2,
      AppColors.chartPink,
      AppColors.chartPink3,
      AppColors.chartCream,
      AppColors.chartPink,
    ];

    final step = size.width / values.length;
    final barWidth = math.min(44.0, step * 0.55);

    for (int i = 0; i < values.length; i++) {
      final barHeight = size.height * values[i] * 0.88;
      final left = (step * i) + (step - barWidth) / 2;
      final top = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(14),
      );

      final paint = Paint()..color = colors[i];
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}