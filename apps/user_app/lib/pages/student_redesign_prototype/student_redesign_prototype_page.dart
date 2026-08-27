// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

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
    // ล็อกช่วงการขยายตัวอักษรของระบบ (การตั้งค่า "ขนาดตัวอักษรใหญ่" บน
    // Android/iOS) ไว้ในช่วงแคบๆ เพื่อคง proportion ของ UI ที่ออกแบบไว้ —
    // ถ้าปล่อยตามระบบเต็มๆ บนจอเล็ก ป้าย/การ์ดที่บีบพอดีตัวอักษรจะล้น
    // หรือแตกเลย์เอาต์ได้ แต่ก็ยังให้ขยายได้บ้างเพื่อการเข้าถึง (accessibility)
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.15,
        ),
      ),
      child: Scaffold(
        body: switch (variant) {
          StudentPrototypeVariant.a => const StudentNavigationPrototype(),
          StudentPrototypeVariant.b => const StudentVariantLearningPath(),
          StudentPrototypeVariant.c => const StudentVariantFocusWorkspace(),
          StudentPrototypeVariant.d => const StudentVariantCommandCenter(),
        },
      ),
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
class _UpcomingSchoolTasksCard extends StatefulWidget {
  const _UpcomingSchoolTasksCard();

  @override
  State<_UpcomingSchoolTasksCard> createState() =>
      _UpcomingSchoolTasksCardState();
}

class _UpcomingSchoolTasksCardState extends State<_UpcomingSchoolTasksCard> {
  SensorModel? _sensor;
  Set<String> _availableMetrics = const {};

  @override
  void initState() {
    super.initState();
    _loadRealSensor();
  }

  Future<void> _loadRealSensor() async {
    try {
      // Empty room/building = aggregate across every device in the school
      // (see RealtimeService.modelForRoom — an empty room string skips the
      // location filter and returns the newest value per metric school-wide).
      final results = await Future.wait([
        RealtimeService.getSensorOnce(
          schoolId: '',
          building: '',
          floor: '',
          room: '',
        ),
        RealtimeService.getWeatherMetricsWithData(),
      ]);
      if (!mounted) return;
      setState(() {
        _sensor = results[0] as SensorModel?;
        // SensorModel defaults an absent metric to 0, indistinguishable
        // from a real 0 — only trust a metric this card shows if it was
        // actually present in the raw readings, not just "some device
        // reported something."
        _availableMetrics = results[1] as Set<String>;
      });
    } catch (_) {
      // Keep the honest "no data" state on error.
    }
  }

  String _levelLabel(SensorLevel level) =>
      level == SensorLevel.good ? 'ปกติ' : 'ไม่ปลอดภัย';

  @override
  Widget build(BuildContext context) {
    final sensor = _sensor;
    final hasAnyData = _availableMetrics.isNotEmpty;
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: hasAnyData
                      ? SchoolPalette.green
                      : const Color(0xFF94A3B8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (hasAnyData
                                  ? SchoolPalette.green
                                  : const Color(0xFF94A3B8))
                              .withOpacity(0.4),
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
                  color: hasAnyData
                      ? SchoolPalette.green
                      : const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (hasAnyData
                                  ? SchoolPalette.green
                                  : const Color(0xFF94A3B8))
                              .withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  hasAnyData ? 'LIVE ⚡' : 'ไม่มีข้อมูล',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SchoolTaskItem(
            icon: Icons.air_rounded,
            title: 'ฝุ่น PM2.5',
            value: _availableMetrics.contains('pm25')
                ? '${sensor!.pm25.toInt()}'
                : null,
            unit: 'µg/m³',
            subtitle: _availableMetrics.contains('pm25')
                ? 'ค่าล่าสุดจากเซนเซอร์จริง'
                : 'ยังไม่มีข้อมูลเซนเซอร์จริง',
            level: _availableMetrics.contains('pm25')
                ? _levelLabel(sensor!.pm25Level)
                : 'ไม่มีข้อมูล',
            color: const Color(0xFF0284C7),
          ),
          _SchoolTaskItem(
            icon: Icons.thermostat_rounded,
            title: 'อุณหภูมิห้องเรียน',
            value: _availableMetrics.contains('temperature')
                ? '${sensor!.temperature}'
                : null,
            unit: '°C',
            subtitle: _availableMetrics.contains('temperature')
                ? 'ค่าล่าสุดจากเซนเซอร์จริง'
                : 'ยังไม่มีข้อมูลเซนเซอร์จริง',
            level: _availableMetrics.contains('temperature')
                ? _levelLabel(sensor!.tempLevel)
                : 'ไม่มีข้อมูล',
            color: const Color(0xFFEA580C),
          ),
          _SchoolTaskItem(
            icon: Icons.water_drop_rounded,
            title: 'ความชื้นสัมพัทธ์',
            value: _availableMetrics.contains('humidity')
                ? '${sensor!.humidity}'
                : null,
            unit: '%RH',
            subtitle: _availableMetrics.contains('humidity')
                ? 'ค่าล่าสุดจากเซนเซอร์จริง'
                : 'ยังไม่มีข้อมูลเซนเซอร์จริง',
            level: _availableMetrics.contains('humidity')
                ? _levelLabel(sensor!.humidityLevel)
                : 'ไม่มีข้อมูล',
            color: const Color(0xFF059669),
          ),
          _SchoolTaskItem(
            icon: Icons.wb_sunny_rounded,
            title: 'ความเข้มแสง',
            value: _availableMetrics.contains('light_lux')
                ? '${sensor!.lux.toInt()}'
                : null,
            unit: 'lux',
            subtitle: _availableMetrics.contains('light_lux')
                ? 'ค่าล่าสุดจากเซนเซอร์จริง'
                : 'ยังไม่มีข้อมูลเซนเซอร์จริง',
            level: _availableMetrics.contains('light_lux')
                ? _levelLabel(sensor!.luxLevel)
                : 'ไม่มีข้อมูล',
            color: const Color(0xFFD97706),
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
