// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';

import 'widgets/widgets.dart';
export 'widgets/widgets.dart';

// PROTOTYPE ONLY: Student redesigned experiences, switchable with
// /prototype/student-redesign?variant=A, B, C, or D. Keep this isolated until a
// winner is selected and rewritten into the real student pages.

class SchoolPalette {
  static const green = Color(0xFF43AC60);
  static const yellow = Color(0xFFFFC939);
  static const orange = Color(0xFFDB6D24);
  static const blue = Color(0xFF4CA4F1);
  static const cream = Color(0xFFFBEAA8);
  static const sky = Color(0xFFAADBF9);
  static const lime = Color(0xFFA9CD30);
  static const lavender = Color(0xFFC8BADD);
  static const ink = Color(0xFF263238);
  static const muted = Color(0xFF607D8B);
  static const page = Colors.white;
}

enum StudentPrototypeVariant {
  a('A', 'หน้าแรกนักเรียน'),
  b('B', 'แผนการเรียนวันนี้'),
  c('C', 'พื้นที่เรียนรายวิชา'),
  d('D', 'หน้าแรกแบบโรงเรียน');

  const StudentPrototypeVariant(this.key, this.label);

  final String key;
  final String label;

  static StudentPrototypeVariant fromQuery(String? value) {
    return StudentPrototypeVariant.values.firstWhere(
      (variant) => variant.key.toLowerCase() == value?.toLowerCase(),
      orElse: () => StudentPrototypeVariant.a,
    );
  }
}

class StudentRedesignPrototypePage extends StatefulWidget {
  const StudentRedesignPrototypePage({super.key, this.initialVariant});

  final StudentPrototypeVariant? initialVariant;

  @override
  State<StudentRedesignPrototypePage> createState() =>
      _StudentRedesignPrototypePageState();
}

class _StudentRedesignPrototypePageState
    extends State<StudentRedesignPrototypePage> {
  late StudentPrototypeVariant variant =
      widget.initialVariant ?? StudentPrototypeVariant.a;

  void setVariant(StudentPrototypeVariant next) {
    setState(() => variant = next);
  }

  void cycle(int direction) {
    final variants = StudentPrototypeVariant.values;
    final current = variants.indexOf(variant);
    final nextIndex = (current + direction + variants.length) % variants.length;
    setVariant(variants[nextIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (variant) {
        StudentPrototypeVariant.a => const StudentNavigationPrototype(),
        StudentPrototypeVariant.b => const StudentVariantLearningPath(),
        StudentPrototypeVariant.c => const StudentVariantFocusWorkspace(),
        StudentPrototypeVariant.d => const StudentVariantCommandCenter(),
      },
    );
  }
}

class PrototypeVariantSwitcher extends StatelessWidget {
  const PrototypeVariantSwitcher({
    super.key,
    required this.variant,
    required this.onPrevious,
    required this.onNext,
    required this.onSelected,
  });

  final StudentPrototypeVariant variant;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<StudentPrototypeVariant> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Previous variant',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left, color: Colors.white),
            ),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: StudentPrototypeVariant.values.map((item) {
                    final isSelected = item == variant;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text('${item.key} - ${item.label}'),
                        onSelected: (_) => onSelected(item),
                        selectedColor: const Color(0xFF38BDF8),
                        backgroundColor: Colors.white10,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF082F49)
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next variant',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentVariantCommandCenter extends StatelessWidget {
  const StudentVariantCommandCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return PrototypeShell(
      background: const Color(0xFFEAF6F1),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 128),
            children: const [_SchoolMobileFrame()],
          ),
        ),
      ),
    );
  }
}

class _SchoolMobileFrame extends StatelessWidget {
  const _SchoolMobileFrame();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFB),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A43AC60),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: const Column(
        children: [
          _SchoolDashboardTopNav(),
          SizedBox(height: 24),
          _SchoolDashboardHero(),
          SizedBox(height: 18),
          _SchoolQuickActions(),
          SizedBox(height: 18),
          _SchoolDashboardBodyGrid(),
          SizedBox(height: 18),
          _SchoolBottomNavMock(),
        ],
      ),
    );
  }
}

class _SchoolDashboardTopNav extends StatelessWidget {
  const _SchoolDashboardTopNav();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SoftIconButton(
          icon: Icons.menu_rounded,
          color: SchoolPalette.green,
          background: SchoolPalette.green.withOpacity(0.14),
        ),
        const Spacer(),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: SchoolPalette.cream,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.face_rounded, color: SchoolPalette.orange),
        ),
        const SizedBox(width: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: SchoolPalette.muted,
              size: 30,
            ),
            Positioned(
              top: -4,
              right: -5,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: SchoolPalette.orange,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SchoolDashboardHero extends StatelessWidget {
  const _SchoolDashboardHero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(right: isWide ? 300 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สวัสดี,\nสายฟ้า',
                    style: TextStyle(
                      color: SchoolPalette.ink,
                      fontSize: isWide ? 44 : 38,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'วันนี้มีงานเรียนที่ต้องทำ และมีข้อมูลห้องเรียนให้ติดตาม',
                    style: TextStyle(
                      color: SchoolPalette.muted,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _ProgressGoalCard(),
                ],
              ),
            ),
            if (isWide)
              const Positioned(right: 10, top: 4, child: _StudentIllustration())
            else
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Opacity(
                    opacity: 0.22,
                    child: _StudentIllustration(size: 160),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StudentIllustration extends StatelessWidget {
  const _StudentIllustration({this.size = 260});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: const BoxDecoration(
              color: SchoolPalette.sky,
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            top: size * 0.18,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: const BoxDecoration(
                color: SchoolPalette.cream,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: SchoolPalette.orange,
                size: 72,
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.2,
            child: Container(
              width: size * 0.56,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: SchoolPalette.green.withOpacity(0.88),
                borderRadius: BorderRadius.circular(size * 0.12),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 54,
              ),
            ),
          ),
          Positioned(
            right: size * 0.05,
            top: size * 0.26,
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: SchoolPalette.yellow,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressGoalCard extends StatelessWidget {
  const _ProgressGoalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: SchoolPalette.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: const [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: 0.72,
                    strokeWidth: 9,
                    backgroundColor: Color(0xFFE2F3E7),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SchoolPalette.green,
                    ),
                  ),
                ),
                Text(
                  '72%',
                  style: TextStyle(
                    color: SchoolPalette.green,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'เป้าหมายวันนี้',
                  style: TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '3',
                        style: TextStyle(
                          color: SchoolPalette.green,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(text: ' / 5 งานเสร็จแล้ว'),
                    ],
                  ),
                  style: TextStyle(color: SchoolPalette.muted),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    value: 0.6,
                    minHeight: 9,
                    backgroundColor: Color(0xFFE7F2EE),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SchoolPalette.green,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ทำต่ออีกนิดเดียว',
                  style: TextStyle(
                    color: SchoolPalette.muted,
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
}

// ignore: unused_element
class _SchoolQuickActions extends StatelessWidget {
  const _SchoolQuickActions();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'เมนูด่วน',
                  style: TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('แก้ไข')),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'ส่งงาน',
                  color: SchoolPalette.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'ตารางเรียน',
                  color: SchoolPalette.lavender,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.flag_rounded,
                  label: 'เป้าหมาย',
                  color: SchoolPalette.yellow,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.insights_rounded,
                  label: 'รายงาน',
                  color: SchoolPalette.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 74,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SchoolPalette.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SchoolDashboardBodyGrid extends StatelessWidget {
  const _SchoolDashboardBodyGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 740;
        if (!isWide) {
          return const Column(
            children: [
              _UpcomingSchoolTasksCard(),
              SizedBox(height: 16),
              _ClassroomClimateCard(),
              SizedBox(height: 16),
              _SchoolEncouragementCard(),
            ],
          );
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _UpcomingSchoolTasksCard()),
            SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _ClassroomClimateCard(),
                  SizedBox(height: 16),
                  _SchoolEncouragementCard(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ignore: unused_element
class _UpcomingSchoolTasksCard extends StatelessWidget {
  const _UpcomingSchoolTasksCard();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: SchoolPalette.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x6643AC60),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ข้อมูลเซนเซอร์สภาพอากาศ AIoT',
                  style: TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: SchoolPalette.green,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3343AC60),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'LIVE ⚡',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _SchoolTaskItem(
            icon: Icons.air_rounded,
            title: 'ฝุ่น PM2.5',
            value: '18',
            unit: 'µg/m³',
            subtitle: 'ห้องเรียนปลอดภัย · คุณภาพอากาศ 98%',
            level: 'ดีมาก',
            color: Color(0xFF0284C7),
          ),
          const _SchoolTaskItem(
            icon: Icons.thermostat_rounded,
            title: 'อุณหภูมิห้องเรียน',
            value: '28.5',
            unit: '°C',
            subtitle: 'เครื่องปรับอากาศทำงานปกติ',
            level: 'เหมาะสม',
            color: Color(0xFFEA580C),
          ),
          const _SchoolTaskItem(
            icon: Icons.water_drop_rounded,
            title: 'ความชื้นสัมพัทธ์',
            value: '62',
            unit: '%RH',
            subtitle: 'ระดับความชื้นในอากาศสมดุล',
            level: 'ปกติ',
            color: Color(0xFF059669),
          ),
          const _SchoolTaskItem(
            icon: Icons.wb_sunny_rounded,
            title: 'ดัชนีรังสี UV',
            value: 'UV 2',
            subtitle: 'รังสีระดับต่ำ ปลอดภัยต่อสายตา',
            level: 'ปลอดภัย',
            color: Color(0xFFD97706),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
              ),
              label: const Text(
                'ไปหน้า AIoT Dashboard',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: SchoolPalette.green,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: SchoolPalette.green.withOpacity(0.35),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolTaskItem extends StatelessWidget {
  const _SchoolTaskItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.color,
    this.value,
    this.unit,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String level;
  final Color color;
  final String? value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: value!,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            height: 1.15,
                          ),
                        ),
                        if (unit != null)
                          TextSpan(
                            text: ' $unit',
                            style: TextStyle(
                              color: color.withOpacity(0.88),
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              level,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ClassroomClimateCard extends StatelessWidget {
  const _ClassroomClimateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SchoolPalette.sky.withOpacity(0.38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SchoolPalette.sky),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '23 PM2.5',
                  style: TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ห้องเรียนปลอดภัย',
                  style: TextStyle(
                    color: SchoolPalette.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.place_rounded,
                      color: SchoolPalette.green,
                      size: 15,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'ห้องวิทย์ AIoT',
                      style: TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.cloud_queue_rounded,
              color: SchoolPalette.blue,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolEncouragementCard extends StatefulWidget {
  const _SchoolEncouragementCard();

  @override
  State<_SchoolEncouragementCard> createState() =>
      _SchoolEncouragementCardState();
}

class _SchoolEncouragementCardState extends State<_SchoolEncouragementCard> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'badge': 'คติพจน์ประจำวัน 🌟',
      'icon': Icons.format_quote_rounded,
      'bgIcon': Icons.landscape_rounded,
      'bgColor': const Color(0xFF14532D),
      'accentColor': SchoolPalette.lime,
      'title': 'เรียนทีละนิด\nทำสม่ำเสมอ\nผลลัพธ์จะชัดขึ้น',
      'subtitle': null,
    },
    {
      'badge': 'ประหยัดพลังงาน ม.5/2 ⚡',
      'icon': Icons.bolt_rounded,
      'bgIcon': Icons.eco_rounded,
      'bgColor': const Color(0xFF9A3412),
      'accentColor': const Color(0xFFFDE047),
      'title': 'ห้อง ม.5/2 วันนี้\nประหยัดไฟ 14.8%\nลด 3.2 kg CO₂',
      'subtitle': 'ช่วยกันปิดไฟและแอร์เมื่อเลิกใช้งาน 💡',
    },
    {
      'badge': 'เกร็ดความรู้ AIoT 🍃',
      'icon': Icons.lightbulb_rounded,
      'bgIcon': Icons.sensors_rounded,
      'bgColor': const Color(0xFF075985),
      'accentColor': const Color(0xFF38BDF8),
      'title': 'อุณหภูมิ 25°C\nประหยัดไฟสูงสุด\nสมองตื่นตัวพร้อมเรียน',
      'subtitle': 'สภาพแวดล้อมดี ช่วยเพิ่มสมาธิ 🎯',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentPage];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      width: double.infinity,
      height: 182,
      decoration: BoxDecoration(
        color: currentSlide['bgColor'] as Color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (currentSlide['bgColor'] as Color).withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -16,
              child: Icon(
                currentSlide['bgIcon'] as IconData,
                size: 100,
                color: (currentSlide['accentColor'] as Color).withOpacity(0.22),
              ),
            ),
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            slide['icon'] as IconData,
                            color: slide['accentColor'] as Color,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: (slide['accentColor'] as Color)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: (slide['accentColor'] as Color)
                                    .withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              slide['badge'] as String,
                              style: TextStyle(
                                color: slide['accentColor'] as Color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        slide['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.22,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (slide['subtitle'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          slide['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? (currentSlide['accentColor'] as Color)
                          : Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Row(
                children: [
                  InkWell(
                    onTap: _currentPage > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: _currentPage > 0 ? Colors.white : Colors.white30,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: _currentPage < _slides.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: _currentPage < _slides.length - 1
                            ? Colors.white
                            : Colors.white30,
                        size: 18,
                      ),
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

class _SchoolBottomNavMock extends StatelessWidget {
  const _SchoolBottomNavMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: _BottomNavItem(
              icon: Icons.home_rounded,
              label: 'หน้าแรก',
              active: true,
            ),
          ),
          Expanded(
            child: _BottomNavItem(icon: Icons.check_box_outlined, label: 'งาน'),
          ),
          Expanded(
            child: _BottomNavItem(
              icon: Icons.calendar_today_rounded,
              label: 'ตาราง',
            ),
          ),
          Expanded(
            child: _BottomNavItem(
              icon: Icons.person_outline_rounded,
              label: 'โปรไฟล์',
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: active ? SchoolPalette.green.withOpacity(0.16) : null,
        borderRadius: BorderRadius.circular(999),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? SchoolPalette.green : SchoolPalette.muted,
              size: 20,
            ),
            if (active) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: SchoolPalette.green,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SoftIconButton extends StatelessWidget {
  const _SoftIconButton({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}

class StudentVariantSchoolHome extends StatefulWidget {
  const StudentVariantSchoolHome({super.key});

  @override
  State<StudentVariantSchoolHome> createState() =>
      _StudentVariantSchoolHomeState();
}

class _StudentVariantSchoolHomeState extends State<StudentVariantSchoolHome> {
  String _previewMode = 'full';

  @override
  Widget build(BuildContext context) {
    return PrototypeShell(
      background: const Color(0xFFF1F5F9),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isMobileDevice = screenWidth < 600;

          double? effectiveMaxWidth;
          if (_previewMode == 'mobile') {
            effectiveMaxWidth = 420;
          } else if (_previewMode == 'tablet') {
            effectiveMaxWidth = 680;
          } else {
            // 'full' mode: 100% full desktop width
            effectiveMaxWidth = null;
          }

          final isFullWidth = effectiveMaxWidth == null;

          return Column(
            children: [
              if (!isMobileDevice)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🖥️ เลือกโหมดการแสดงผล: ',
                        style: TextStyle(
                          color: SchoolPalette.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ModeChip(
                        label: '🖥️ เต็มจอคอม (100% Full Width)',
                        active: _previewMode == 'full',
                        onTap: () => setState(() => _previewMode = 'full'),
                      ),
                      const SizedBox(width: 6),
                      _ModeChip(
                        label: '💻 กรอบแท็บเล็ต (680px)',
                        active: _previewMode == 'tablet',
                        onTap: () => setState(() => _previewMode = 'tablet'),
                      ),
                      const SizedBox(width: 6),
                      _ModeChip(
                        label: '⚡ ตอบสนองอัตโนมัติ (Auto)',
                        active: _previewMode == 'auto',
                        onTap: () => setState(() => _previewMode = 'auto'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Container(
                  width: effectiveMaxWidth ?? double.infinity,
                  height: double.infinity,
                  constraints: effectiveMaxWidth != null
                      ? BoxConstraints(maxWidth: effectiveMaxWidth)
                      : null,
                  margin: isMobileDevice || isFullWidth
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF7),
                    borderRadius: isMobileDevice || isFullWidth
                        ? BorderRadius.zero
                        : BorderRadius.circular(28),
                    boxShadow: isMobileDevice || isFullWidth
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x18000000),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: isMobileDevice || isFullWidth
                        ? BorderRadius.zero
                        : BorderRadius.circular(28),
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isFullWidth && screenWidth > 800 ? 32 : 16,
                        vertical: 16,
                      ),
                      children: [
                        const _AcademyHeroCard(),
                        const SizedBox(height: 16),
                        const _AcademyTodayExecutiveSummaryBar(),
                        const SizedBox(height: 18),
                        if (screenWidth >= 760)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Expanded(
                                flex: 3,
                                child: AiotWeatherSensorsCard(),
                              ),
                              SizedBox(width: 18),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _AcademyWeatherSensorCard(),
                                    SizedBox(height: 16),
                                    SchoolEncouragementCard(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...const [
                          AiotWeatherSensorsCard(),
                          SizedBox(height: 18),
                          _AcademyWeatherSensorCard(),
                          SizedBox(height: 16),
                          SchoolEncouragementCard(),
                        ],
                        const SizedBox(height: 18),
                        const AcademyQuickActions(),
                        const SizedBox(height: 18),
                        const AcademyContinueLearningCard(),
                        const SizedBox(height: 18),
                        const AcademyTasksDueCard(),
                        const SizedBox(height: 18),
                        const _AcademySchoolAnnouncementsCard(),
                        const SizedBox(height: 24),
                        const _AcademyBottomNavMock(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? SchoolPalette.green : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : SchoolPalette.ink,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _AcademyTopBar extends StatelessWidget {
  const _AcademyTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: SchoolPalette.green, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x15000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: SchoolPalette.cream,
              child: Icon(
                Icons.face_rounded,
                color: SchoolPalette.orange,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'นายสายฟ้า เรียนดี',
                      style: TextStyle(
                        color: SchoolPalette.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF8F3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFC7E2D0)),
                      ),
                      child: const Text(
                        'ม.5/1',
                        style: TextStyle(
                          color: SchoolPalette.green,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'โรงเรียน AIoT Smart School Lab • ภาคเรียนที่ 1/2569',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _SoftIconButton(
                icon: Icons.notifications_none_rounded,
                color: SchoolPalette.ink,
                background: const Color(0xFFF8FAFC),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: SchoolPalette.orange,
                    shape: BoxShape.circle,
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

class _AcademyTodayExecutiveSummaryBar extends StatelessWidget {
  const _AcademyTodayExecutiveSummaryBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.today_rounded, color: SchoolPalette.green, size: 16),
              SizedBox(width: 6),
              Text(
                'สรุปภาพรวมวันนี้สำหรับนักเรียน',
                style: TextStyle(
                  color: SchoolPalette.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _SummaryChip(
                  icon: Icons.assignment_late_rounded,
                  label: 'งานต้องส่งวันนี้: 2 ชิ้น',
                  color: Color(0xFFC2410C),
                  bgColor: Color(0xFFFFEDD5),
                ),
                SizedBox(width: 8),
                _SummaryChip(
                  icon: Icons.timer_rounded,
                  label: 'ด่วนที่สุด: ใบงานชีววิทยา (เหลือ 3 ชม.)',
                  color: Color(0xFFBE123C),
                  bgColor: Color(0xFFFFE4E6),
                ),
                SizedBox(width: 8),
                _SummaryChip(
                  icon: Icons.schedule_rounded,
                  label: 'คาบถัดไป: 13:30 น. AIoT ชีววิทยา',
                  color: Color(0xFF0369A1),
                  bgColor: Color(0xFFE0F2FE),
                ),
                SizedBox(width: 8),
                _SummaryChip(
                  icon: Icons.campaign_rounded,
                  label: 'ครูอรพรรณ: งดใช้แล็บ 2 ชั่วคราว',
                  color: Color(0xFF047857),
                  bgColor: Color(0xFFD1FAE5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.28), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademyHeroCard extends StatelessWidget {
  const _AcademyHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF07533F), Color(0xFF0D6852)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E07533F),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.85,
              child: CustomPaint(painter: _LabPatternPainter()),
            ),
          ),
          Positioned(
            left: 20,
            top: 20,
            bottom: 20,
            right: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'สวัสดีตอนเช้า,',
                      style: TextStyle(
                        color: SchoolPalette.cream,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'สายฟ้า!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'มาต่อบทเรียน AIoT และงานทดลองวันนี้กัน',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFE9FFF5),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: 0.72,
                              strokeWidth: 5.0,
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: SchoolPalette.green,
                            ),
                            const Text(
                              '72%',
                              style: TextStyle(
                                color: SchoolPalette.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFEAB308),
                                  size: 17,
                                ),
                                const SizedBox(width: 4),
                                const Expanded(
                                  child: Text(
                                    'ทำได้ดีมาก, สายฟ้า!',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: SchoolPalette.ink,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFA7F3D0),
                                    ),
                                  ),
                                  child: const Text(
                                    'เกรด A+',
                                    style: TextStyle(
                                      color: Color(0xFF059669),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: const [
                                  _MiniStatBadge(
                                    icon: Icons.menu_book_rounded,
                                    label: '12 บทเรียน',
                                    color: Color(0xFF0284C7),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 10,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _MiniStatBadge(
                                    icon: Icons.assignment_turned_in_rounded,
                                    label: 'ส่งแล้ว 8/8',
                                    color: Color(0xFF059669),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 10,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _MiniStatBadge(
                                    icon: Icons.workspace_premium_rounded,
                                    label: 'G-Score 92',
                                    color: Color(0xFFEA580C),
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
              ],
            ),
          ),
          Positioned(
            right: -10,
            bottom: -10,
            child: const _AcademyStudent3DVisual(),
          ),
        ],
      ),
    );
  }
}

class _MiniStatBadge extends StatelessWidget {
  const _MiniStatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3.5),
        Text(
          label,
          style: const TextStyle(
            color: SchoolPalette.ink,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AcademyStudent3DVisual extends StatefulWidget {
  const _AcademyStudent3DVisual();

  @override
  State<_AcademyStudent3DVisual> createState() =>
      __AcademyStudent3DVisualState();
}

class __AcademyStudent3DVisualState extends State<_AcademyStudent3DVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  int _speechIndex = 0;
  bool _showBubble = false;
  double _scale = 1.0;

  final List<String> _greetings = [
    'สวัสดีสายฟ้า! พร้อมทดลองวันนี้หรือยัง? 🚀',
    'วันนี้ตั้งใจมาก รับไปเลย 5 ดาว ⭐!',
    'อากาศสดใส ค่า PM2.5 แค่ 18 เองนะ ☁️',
    'อย่าลืมทบทวนบทเรียน AIoT นะ 😉',
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _onTapMascot() {
    setState(() {
      _scale = 1.12;
      _speechIndex = (_speechIndex + 1) % _greetings.length;
      _showBubble = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _scale = 1.0);
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showBubble = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTapMascot,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 185,
        height: 275,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: AnimatedScale(
                      scale: _scale,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOutBack,
                      child: Image.asset(
                        'assets/images/mascot_lion_clean.png',
                        fit: BoxFit.contain,
                        height: 252,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.pets_rounded,
                            size: 120,
                            color: SchoolPalette.orange,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: -12,
              right: 10,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showBubble ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x25000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: SchoolPalette.green,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _greetings[_speechIndex],
                      style: const TextStyle(
                        color: SchoolPalette.ink,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 26,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SchoolPalette.blue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x20000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.cloud_done_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'PM2.5: 18',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _AcademyWeatherSensorCard extends StatelessWidget {
  const _AcademyWeatherSensorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
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
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: SchoolPalette.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x6643AC60),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'คะแนนและผลการเรียน G-Score (ภาคเรียนที่ 1/2569)',
                  style: TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8F3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC7E2D0)),
                ),
                child: const Text(
                  'GRADE A+ 🌟',
                  style: TextStyle(
                    color: SchoolPalette.green,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 540;
              final tiles = [
                const _SensorItemTile(
                  icon: Icons.military_tech_rounded,
                  label: 'คะแนน G-Score รวม',
                  value: '92 / 100',
                  status: 'ระดับดีเยี่ยม',
                  color: Color(0xFF0284C7),
                  bgTint: Color(0xFFE0F2FE),
                ),
                const _SensorItemTile(
                  icon: Icons.grade_rounded,
                  label: 'เกรดเฉลี่ยสะสม',
                  value: 'GPA 3.85',
                  status: 'เกียรตินิยม',
                  color: Color(0xFFEA580C),
                  bgTint: Color(0xFFFFEDD5),
                ),
                const _SensorItemTile(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'ภาระงานที่ส่งแล้ว',
                  value: '18 / 20 งาน',
                  status: 'ส่งครบ 100%',
                  color: Color(0xFF059669),
                  bgTint: Color(0xFFD1FAE5),
                ),
                const _SensorItemTile(
                  icon: Icons.emoji_events_rounded,
                  label: 'เหรียญ & แบดจ์',
                  value: '15 แบดจ์',
                  status: 'ผู้เชี่ยวชาญ AIoT',
                  color: Color(0xFFD97706),
                  bgTint: Color(0xFFFEF3C7),
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: tiles[0]),
                        const SizedBox(width: 8),
                        Expanded(child: tiles[1]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: tiles[2]),
                        const SizedBox(width: 8),
                        Expanded(child: tiles[3]),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: tiles
                    .map(
                      (tile) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: tile,
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
}

class _SensorItemTile extends StatelessWidget {
  const _SensorItemTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
    required this.color,
    required this.bgTint,
  });

  final IconData icon;
  final String label;
  final String value;
  final String status;
  final Color color;
  final Color bgTint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.9),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
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

class _AcademySchoolAnnouncementsCard extends StatelessWidget {
  const _AcademySchoolAnnouncementsCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ประกาศจากครู/โรงเรียน',
                style: TextStyle(
                  color: SchoolPalette.ink,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'ดูทั้งหมด',
                style: TextStyle(
                  color: SchoolPalette.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: SchoolPalette.orange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'แจ้งย้ายห้องเรียนแล็บ 2 ชั่วคราว (ครูอรพรรณ)',
                      style: TextStyle(
                        color: SchoolPalette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'เนื่องจากมีการซ่อมบำรุงเซนเซอร์ AIoT ในห้องแล็บ 2 วันนี้ ให้เปลี่ยนไปใช้ห้องแล็บ 1 อาคารวิทยาศาสตร์แทนครับ',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _AcademyProgressCard extends StatelessWidget {
  const _AcademyProgressCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ความก้าวหน้าของคุณ',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontSize: 17.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF4FAF6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2EFE7), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: 0.72,
                        strokeWidth: 10,
                        backgroundColor: Color(0xFFE5F4EA),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          SchoolPalette.green,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '72%',
                          style: TextStyle(
                            color: SchoolPalette.green,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'ความก้าวหน้าทั้งหมด',
                          style: TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: SchoolPalette.yellow,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'ทำได้ดีมาก, สายฟ้า!',
                          style: TextStyle(
                            color: SchoolPalette.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3),
                    Text(
                      'ตั้งใจเรียนต่อไป ผลงานของคุณยอดเยี่ยมมาก',
                      style: TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 14),
                    _ProgressStatsRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressStatsRow extends StatelessWidget {
  const _ProgressStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _SmallStat(
            icon: Icons.menu_book_rounded,
            value: '12 บท',
            label: 'บทเรียนที่เรียนแล้ว',
            color: SchoolPalette.green,
          ),
        ),
        Expanded(
          child: _SmallStat(
            icon: Icons.task_alt_rounded,
            value: '8 / 8',
            label: 'ส่งงานครบถ้วน',
            color: SchoolPalette.green,
          ),
        ),
        Expanded(
          child: _SmallStat(
            icon: Icons.verified_rounded,
            value: '92/100',
            label: 'คะแนนครูยืนยันแล้ว',
            color: SchoolPalette.orange,
          ),
        ),
      ],
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color == SchoolPalette.yellow
                  ? const Color(0xFFD97706)
                  : color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: SchoolPalette.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SchoolPalette.muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _AcademyNextClassCard extends StatelessWidget {
  const _AcademyNextClassCard();

  final bool hasUpcomingClass = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'คาบเรียนถัดไป',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontSize: 17.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (!hasUpcomingClass)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: SchoolPalette.blue,
                    size: 24,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ไม่มีคาบเรียนคงเหลือในวันนี้',
                        style: TextStyle(
                          color: SchoolPalette.ink,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'คุณทำกิจกรรมการเรียนของวันนี้ครบถ้วนแล้ว',
                        style: TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8F3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD3ECE0), width: 1.2),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SchoolPalette.green.withOpacity(0.4),
                          width: 1.8,
                        ),
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Color(0xFFE2F4E9),
                        child: Icon(
                          Icons.person_rounded,
                          color: SchoolPalette.green,
                          size: 28,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: SchoolPalette.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ครูอรพรรณ สายวิทย์',
                        style: TextStyle(
                          color: SchoolPalette.ink,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'SC30201 - AIoT ชีววิทยา',
                        style: TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: SchoolPalette.blue,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'วันนี้',
                            style: TextStyle(
                              color: SchoolPalette.blue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: SchoolPalette.blue,
                          ),
                          SizedBox(width: 3),
                          Text(
                            '13:30 น.',
                            style: TextStyle(
                              color: SchoolPalette.blue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.videocam_rounded, size: 16),
                  label: const Text(
                    'เข้าเรียน',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF07533F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AcademyBottomNavMock extends StatelessWidget {
  const _AcademyBottomNavMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8EDE8), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: _BottomNavItem(
              icon: Icons.home_rounded,
              label: 'หน้าแรก',
              active: true,
            ),
          ),
          Expanded(
            child: _BottomNavItem(icon: Icons.school_rounded, label: 'รายวิชา'),
          ),
          Expanded(
            child: _BottomNavItem(icon: Icons.assignment_rounded, label: 'งาน'),
          ),
          Expanded(
            child: _BottomNavItem(
              icon: Icons.bar_chart_rounded,
              label: 'คะแนน/สถิติ',
            ),
          ),
          Expanded(
            child: _BottomNavItem(icon: Icons.person_rounded, label: 'โปรไฟล์'),
          ),
        ],
      ),
    );
  }
}

class _LabPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft yellow doodle cloud (#FFC939)
    final yellowPaint = Paint()
      ..color = SchoolPalette.yellow.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.85, 30), 22, yellowPaint);
    canvas.drawCircle(Offset(size.width * 0.85 - 18, 36), 16, yellowPaint);
    canvas.drawCircle(Offset(size.width * 0.85 + 18, 36), 16, yellowPaint);

    // 2. Orange swirl doodle (#DB6D24)
    final orangePaint = Paint()
      ..color = SchoolPalette.orange.withOpacity(0.35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.72, 70)
      ..quadraticBezierTo(size.width * 0.76, 50, size.width * 0.80, 75)
      ..quadraticBezierTo(size.width * 0.84, 95, size.width * 0.88, 65);
    canvas.drawPath(path, orangePaint);

    // 3. Sky blue doodle cloud outline (#AADBF9)
    final skyPaint = Paint()
      ..color = SchoolPalette.sky.withOpacity(0.3)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width * 0.2, 190), 16, skyPaint);
    canvas.drawCircle(Offset(size.width * 0.2 - 12, 194), 11, skyPaint);
    canvas.drawCircle(Offset(size.width * 0.2 + 12, 194), 11, skyPaint);

    // 4. Subtle background diagonal grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (var x = -40.0; x < size.width + 40; x += 64) {
      canvas.drawLine(Offset(x, 0), Offset(x + 120, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StudentVariantLearningPath extends StatelessWidget {
  const StudentVariantLearningPath({super.key});

  @override
  Widget build(BuildContext context) {
    return PrototypeShell(
      background: const Color(0xFFF8FAFC),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        children: [
          const PrototypeHeader(
            eyebrow: 'AIoT Safe & Green School Lab',
            title: 'แผนการเรียนวันนี้',
            subtitle: 'เรียงลำดับกิจกรรมที่นักเรียนควรทำก่อนหลัง ลดการหลงเมนู',
          ),
          const SizedBox(height: 16),
          const _SchoolIdentityBar(),
          const SizedBox(height: 20),
          const _PathSummaryCard(),
          const SizedBox(height: 18),
          ...PrototypeData.learningSteps.map(_LearningStepCard.new),
        ],
      ),
    );
  }
}

class StudentVariantFocusWorkspace extends StatelessWidget {
  const StudentVariantFocusWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return PrototypeShell(
      background: const Color(0xFFF1F5F9),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (!isWide) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              children: const [
                PrototypeHeader(
                  eyebrow: 'AIoT Safe & Green School Lab',
                  title: 'พื้นที่เรียนรายวิชา',
                  subtitle:
                      'เหมาะกับการเปิดบทเรียน ไฟล์ ใบงาน และข้อมูลเซนเซอร์ของวิชาเดียว',
                ),
                SizedBox(height: 16),
                _SchoolIdentityBar(),
                SizedBox(height: 18),
                _CurrentCourseWorkspace(),
                SizedBox(height: 18),
                _SideInsightRail(),
              ],
            );
          }
          return Row(
            children: [
              Container(
                width: 320,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
                color: Colors.white,
                child: const _SideInsightRail(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                  children: const [
                    PrototypeHeader(
                      eyebrow: 'AIoT Safe & Green School Lab',
                      title: 'พื้นที่เรียนรายวิชา',
                      subtitle:
                          'เหมาะกับการเปิดบทเรียน ไฟล์ ใบงาน และข้อมูลเซนเซอร์ของวิชาเดียว',
                    ),
                    SizedBox(height: 16),
                    _SchoolIdentityBar(),
                    SizedBox(height: 20),
                    _CurrentCourseWorkspace(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PrototypeShell extends StatelessWidget {
  const PrototypeShell({
    super.key,
    required this.child,
    required this.background,
  });

  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: SafeArea(child: child),
    );
  }
}

class PrototypeHeader extends StatelessWidget {
  const PrototypeHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            color: const Color(0xFF0284C7),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SchoolIdentityBar extends StatelessWidget {
  const _SchoolIdentityBar();

  @override
  Widget build(BuildContext context) {
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: Color(0xFF0369A1)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'โรงเรียนสาธิต AIoT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'นักเรียน: สายฟ้า ป. · ม.2/1 · ภาคเรียนที่ 1/2569',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          const _StatusPill(text: 'วันพฤหัสบดี', color: Color(0xFF0284C7)),
        ],
      ),
    );
  }
}

class _PathSummaryCard extends StatelessWidget {
  const _PathSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '3/5',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เส้นทางการเรียนวันนี้',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                SizedBox(height: 4),
                Text(
                  'ทำเสร็จแล้ว 3 กิจกรรม เหลือ 2 กิจกรรมที่ควรทำต่อ',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningStepCard extends StatelessWidget {
  const _LearningStepCard(this.step);

  final LearningStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: step.done ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: step.done
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFE0F2FE),
            child: Icon(
              step.done ? Icons.check_rounded : step.icon,
              color: step.done
                  ? const Color(0xFF15803D)
                  : const Color(0xFF0369A1),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  step.description,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusPill(
            text: step.done ? 'เสร็จแล้ว' : step.time,
            color: step.done
                ? const Color(0xFF10B981)
                : const Color(0xFF0284C7),
          ),
        ],
      ),
    );
  }
}

class _CurrentCourseWorkspace extends StatelessWidget {
  const _CurrentCourseWorkspace();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StatusPill(text: 'กำลังเรียน', color: Color(0xFF0284C7)),
          const SizedBox(height: 14),
          Text(
            'วิชา AIoT ชีววิทยาและสิ่งแวดล้อม',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'บทเรียนล่าสุด: การอ่านค่า PM2.5 จากเซนเซอร์จริง และการแปลผลด้วยกราฟ',
            style: TextStyle(color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 22),
          const _WorkspaceLessonCard(
            icon: Icons.menu_book_rounded,
            title: 'บทเรียน',
            body: 'อ่านบทเรียนและทำเครื่องหมายเรียนจบ',
            action: 'เปิดบทเรียน',
          ),
          const SizedBox(height: 12),
          const _WorkspaceLessonCard(
            icon: Icons.assignment_rounded,
            title: 'ใบงาน',
            body: 'ส่งคำตอบพร้อมอ้างอิง dataset ที่ครูเตรียมไว้',
            action: 'เริ่มส่งงาน',
          ),
          const SizedBox(height: 12),
          const _WorkspaceLessonCard(
            icon: Icons.folder_rounded,
            title: 'ไฟล์เอกสาร',
            body: 'คู่มือทดลองและใบความรู้ PDF',
            action: 'ดูไฟล์',
          ),
        ],
      ),
    );
  }
}

class _SideInsightRail extends StatelessWidget {
  const _SideInsightRail();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PrototypeHeader(
          eyebrow: 'Student state',
          title: 'ข้อมูลนักเรียน',
          subtitle: 'สายฟ้า ป. · ม.2/1 · ห้องวิทย์ AIoT',
        ),
        const SizedBox(height: 20),
        const _Panel(title: 'คะแนนล่าสุด', child: _ScoreSummary()),
        const SizedBox(height: 14),
        const _Panel(title: 'สถานะห้องเรียน', child: _SensorMiniList()),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _WorkspaceLessonCard extends StatelessWidget {
  const _WorkspaceLessonCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE0F2FE),
            child: Icon(icon, color: const Color(0xFF0284C7)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(onPressed: () {}, child: Text(action)),
        ],
      ),
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  const _ScoreSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          '87.5%',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0284C7),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'คะแนนที่ครูยืนยันแล้วเท่านั้น',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _SensorMiniList extends StatelessWidget {
  const _SensorMiniList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _MiniMetric(label: 'PM2.5', value: '23 ug/m3'),
        _MiniMetric(label: 'AQI', value: 'Good'),
        _MiniMetric(label: 'Light', value: '420 lux'),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ExpandedIf extends StatelessWidget {
  const ExpandedIf({
    super.key,
    required this.enabled,
    required this.child,
    this.flex = 1,
  });

  final bool enabled;
  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Expanded(flex: flex, child: child);
  }
}

class PrototypeData {
  static const todayTasks = [
    TodayTask(
      icon: Icons.menu_book_rounded,
      title: 'อ่านบทเรียนที่ 3',
      subtitle: 'เผยแพร่แล้วในรายวิชา AIoT',
      status: '10 นาที',
      color: Color(0xFF0284C7),
    ),
    TodayTask(
      icon: Icons.assignment_rounded,
      title: 'ส่งใบงาน PM2.5',
      subtitle: 'งานเดี่ยว ใช้ข้อมูล sensor จริง',
      status: 'ด่วน',
      color: Color(0xFFF59E0B),
    ),
    TodayTask(
      icon: Icons.grade_rounded,
      title: 'ดูคะแนนที่ยืนยันแล้ว',
      subtitle: 'คะแนน lab ก่อนหน้า',
      status: 'ใหม่',
      color: Color(0xFF10B981),
    ),
  ];

  static const courses = [
    PrototypeCourse(name: 'AIoT ชีววิทยาและสิ่งแวดล้อม', progress: 68),
    PrototypeCourse(name: 'วิทยาศาสตร์พื้นฐาน', progress: 52),
    PrototypeCourse(name: 'เทคโนโลยีดิจิทัล', progress: 81),
  ];

  static const learningSteps = [
    LearningStep(
      icon: Icons.login_rounded,
      title: 'เข้าสู่ระบบและเช็คงาน',
      description: 'ระบบแสดงเฉพาะข้อมูลของนักเรียนและวิชาที่ลงทะเบียน',
      time: '08:10',
      done: true,
    ),
    LearningStep(
      icon: Icons.menu_book_rounded,
      title: 'อ่านบทเรียน AIoT',
      description: 'เปิดบทเรียนที่ครูเผยแพร่แล้ว พร้อมเอกสารประกอบ',
      time: '12 นาที',
      done: true,
    ),
    LearningStep(
      icon: Icons.sensors_rounded,
      title: 'ดูข้อมูล sensor ที่ผูกกับบทเรียน',
      description: 'ดูเฉพาะข้อมูลที่ใช้ในบทเรียนหรือใบงานของตนเอง',
      time: 'ตอนนี้',
      done: false,
    ),
    LearningStep(
      icon: Icons.upload_file_rounded,
      title: 'ส่งใบงาน',
      description: 'ส่งคำตอบและแนบหลักฐานก่อนกำหนด',
      time: 'เหลือ 2 วัน',
      done: false,
    ),
  ];
}

class TodayTask {
  const TodayTask({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color color;
}

class PrototypeCourse {
  const PrototypeCourse({required this.name, required this.progress});

  final String name;
  final int progress;
}

class LearningStep {
  const LearningStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    required this.done,
  });

  final IconData icon;
  final String title;
  final String description;
  final String time;
  final bool done;
}
