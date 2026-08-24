import 'package:flutter/material.dart';
import '../../widgets/parent_common_widgets.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  static const Color _navy = Color(0xFF173B69);
  static const Color _bg = Color(0xFFF5F7FB);

  // เปลี่ยน path ตรงนี้ให้ตรงกับไฟล์มาสคอตของโปรเจกต์ได้เลย
  static const String mascotAsset = 'assets/images/mascot_parent.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ParentPageHeader(
                    title: 'ภาพรวมผู้ปกครอง',
                    subtitle:
                        'ติดตามข้อมูลสำคัญของบุตรหลานแบบรายวันในหน้าเดียว',
                    icon: Icons.dashboard_rounded,
                  ),
                  const SizedBox(height: 18),

                  // ----------------------------------------------------------
                  // HERO / การ์ดใหญ่ + มาสคอต
                  // ----------------------------------------------------------
                  _buildHeroCard(context),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // QUICK STATUS
                  // ----------------------------------------------------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 1180
                          ? 4
                          : constraints.maxWidth >= 760
                              ? 3
                              : constraints.maxWidth >= 500
                                  ? 2
                                  : 1;

                      const gap = 12.0;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                              columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: width,
                            child: const _StatusMetricCard(
                              title: 'มาเรียนวันนี้',
                              value: '07:41 น.',
                              subtitle: 'เข้าประตูโรงเรียนแล้ว',
                              icon: Icons.login_rounded,
                              color: Color(0xFF18A06F),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: const _StatusMetricCard(
                              title: 'อัตรามาเรียน',
                              value: '96%',
                              subtitle: 'ภาคเรียน 1/2569',
                              icon: Icons.fact_check_rounded,
                              color: Color(0xFF2E83C5),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: const _StatusMetricCard(
                              title: 'GPA ล่าสุด',
                              value: '3.62',
                              subtitle: 'ผลการเรียนดีมาก',
                              icon: Icons.star_rounded,
                              color: Color(0xFFF0A03B),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: const _StatusMetricCard(
                              title: 'งานที่ต้องทำ',
                              value: '2 งาน',
                              subtitle: '1 งานครบกำหนดพรุ่งนี้',
                              icon: Icons.assignment_rounded,
                              color: Color(0xFF8A65C7),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // ENVIRONMENT SENSOR
                  // Desktop: 4 ค่าเรียงแนวนอน
                  // Mobile: 2 คอลัมน์ x 2 แถว
                  // ----------------------------------------------------------
                  const _EnvironmentSensorCard(),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // TODAY + ATTENDANCE
                  // ----------------------------------------------------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 760) {
                        return const Column(
                          children: [
                            _TodayStatusCard(),
                            SizedBox(height: 14),
                            _AttendanceSummaryCard(),
                          ],
                        );
                      }

                      return const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _TodayStatusCard(),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            flex: 4,
                            child: _AttendanceSummaryCard(),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // LEARNING + SCHEDULE
                  // ----------------------------------------------------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return const Column(
                          children: [
                            _LearningOverviewCard(),
                            SizedBox(height: 14),
                            _ScheduleCard(),
                          ],
                        );
                      }

                      return const IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _LearningOverviewCard(),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              flex: 5,
                              child: _ScheduleCard(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ----------------------------------------------------------
                  // HOMEWORK + SCHOOL MESSAGE + IMPORTANT ACTIVITY
                  // ----------------------------------------------------------
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 980) {
                        return const Column(
                          children: [
                            _HomeworkCard(),
                            SizedBox(height: 14),
                            _SchoolMessageCard(),
                            SizedBox(height: 14),
                            _UpcomingActivityCard(),
                          ],
                        );
                      }

                      return const IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _HomeworkCard()),
                            SizedBox(width: 14),
                            Expanded(child: _SchoolMessageCard()),
                            SizedBox(width: 14),
                            Expanded(child: _UpcomingActivityCard()),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 760;

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: mobile ? 310 : 255,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF173B69),
                Color(0xFF215D9E),
                Color(0xFF2E83C5),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.16),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -90,
                top: -120,
                child: Container(
                  width: 330,
                  height: 330,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.055),
                  ),
                ),
              ),
              Positioned(
                right: 120,
                bottom: -150,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.035),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  mobile ? 20 : 30,
                  mobile ? 22 : 28,
                  mobile ? 20 : 26,
                  mobile ? 18 : 25,
                ),
                child: mobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heroTextSection(context, compact: true),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.center,
                            child: _mascot(height: 145),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: _heroTextSection(context),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _mascot(height: 225),
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
  }

  Widget _heroTextSection(
    BuildContext context, {
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.family_restroom_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PARENT PORTAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (!compact)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF42C88A).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFF7EE4AE),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'สถานะปกติ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          'สวัสดีครับ ผู้ปกครอง',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.80),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'วันนี้น้องมะลิมาโรงเรียนเรียบร้อยแล้ว',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: compact ? 22 : 30,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'ม.2/1 · เลขที่ 18 · ปีการศึกษา 2569',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 18),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _HeroBadge(
              icon: Icons.login_rounded,
              text: 'เข้าโรงเรียน 07:41 น.',
            ),
            _HeroBadge(
              icon: Icons.location_on_rounded,
              text: 'อยู่ในอาคารเรียน ม.2',
            ),
            _HeroBadge(
              icon: Icons.menu_book_rounded,
              text: 'กำลังเรียนคณิตศาสตร์',
            ),
          ],
        ),

        const SizedBox(height: 18),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeroActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'ติดต่อครูประจำชั้น',
              filled: true,
              onTap: () => _showMessage(
                context,
                'เปิดเมนูติดต่อครูประจำชั้น',
              ),
            ),
            _HeroActionButton(
              icon: Icons.edit_note_rounded,
              label: 'แจ้งลาเรียน',
              onTap: () => _showMessage(
                context,
                'เปิดแบบฟอร์มแจ้งลาเรียน',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mascot({required double height}) {
    return SizedBox(
      height: height,
      child: Image.asset(
        mascotAsset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // ถ้ายังไม่ได้ใส่ไฟล์มาสคอต จะมีตัวสำรอง ไม่ทำให้หน้าแดง
          return Container(
            width: height * .78,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.family_restroom_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: height * .42,
                ),
                Positioned(
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'MASCOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (
        Icons.edit_note_rounded,
        'แจ้งลาเรียน',
        'แจ้งการลาและเหตุผล',
        const Color(0xFF2D82C4)
      ),
      (
        Icons.support_agent_rounded,
        'ติดต่อครู',
        'ส่งข้อความถึงครูประจำชั้น',
        const Color(0xFF17A06F)
      ),
      (
        Icons.draw_rounded,
        'เอกสารยินยอม',
        'ตรวจเอกสารที่รอการยืนยัน',
        const Color(0xFF8A65C7)
      ),
      (
        Icons.directions_car_rounded,
        'แจ้งรับกลับ',
        'แจ้งบุคคลหรือรถที่มารับ',
        const Color(0xFFF09A37)
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.flash_on_rounded,
            title: 'เมนูด่วนสำหรับผู้ปกครอง',
            subtitle: 'จัดการเรื่องสำคัญได้จากหน้าแรก',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 500
                      ? 2
                      : 1;
              const gap = 10.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final action in actions)
                    SizedBox(
                      width: width,
                      child: _QuickActionTile(
                        icon: action.$1,
                        title: action.$2,
                        subtitle: action.$3,
                        color: action.$4,
                        onTap: () =>
                            _showMessage(context, 'เปิดเมนู ${action.$2}'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================================
// HERO COMPONENTS
// ============================================================================

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      child: filled
          ? FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF245E9F),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: onTap,
              icon: Icon(icon, size: 17),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: onTap,
              icon: Icon(icon, size: 17),
              label: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

// ============================================================================
// STATUS METRIC
// ============================================================================

class _StatusMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatusMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF7E889A),
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1E2736),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8C95A5),
                    fontSize: 8.5,
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

// ============================================================================
// ENVIRONMENT SENSOR
// ============================================================================

class _EnvironmentSensorCard extends StatelessWidget {
  const _EnvironmentSensorCard();

  @override
  Widget build(BuildContext context) {
    const sensors = [
      _SensorData(
        icon: Icons.thermostat_rounded,
        title: 'อุณหภูมิ',
        value: '29.8',
        unit: '°C',
        status: 'ปกติ',
        statusColor: Color(0xFF18A06F),
        iconColor: Color(0xFFF09A37),
      ),
      _SensorData(
        icon: Icons.blur_on_rounded,
        title: 'ฝุ่น PM2.5',
        value: '18',
        unit: 'µg/m³',
        status: 'อากาศดี',
        statusColor: Color(0xFF18A06F),
        iconColor: Color(0xFF2E83C5),
      ),
      _SensorData(
        icon: Icons.light_mode_rounded,
        title: 'ความเข้มแสง',
        value: '620',
        unit: 'lux',
        status: 'เหมาะสม',
        statusColor: Color(0xFF18A06F),
        iconColor: Color(0xFFE5A52A),
      ),
      _SensorData(
        icon: Icons.air_rounded,
        title: 'แก๊สและควัน',
        value: 'ปกติ',
        unit: '',
        status: 'ไม่พบความผิดปกติ',
        statusColor: Color(0xFF18A06F),
        iconColor: Color(0xFF8A65C7),
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.sensors_rounded,
            title: 'สิ่งแวดล้อมภายในโรงเรียน',
            subtitle: 'ข้อมูลที่ตรวจวัดจากเซนเซอร์ภายในพื้นที่โรงเรียน',
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              // มือถือ = 2 ค่า/แถว
              // คอม = 4 ค่า/แถวเดียว
              final bool mobile = constraints.maxWidth < 650;
              final int columns = mobile ? 2 : 4;
              const double gap = 10;

              final double itemWidth =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final sensor in sensors)
                    SizedBox(
                      width: itemWidth,
                      child: _SensorValueTile(
                        icon: sensor.icon,
                        title: sensor.title,
                        value: sensor.value,
                        unit: sensor.unit,
                        status: sensor.status,
                        statusColor: sensor.statusColor,
                        iconColor: sensor.iconColor,
                        compact: mobile,
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.update_rounded,
                  size: 14,
                  color: Color(0xFF7F899A),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'อัปเดตจากเซนเซอร์ล่าสุด 10:52 น.',
                    style: TextStyle(
                      fontSize: 8.3,
                      color: Color(0xFF7F899A),
                    ),
                  ),
                ),
                _SensorOnlineBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorValueTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;
  final Color iconColor;
  final bool compact;

  const _SensorValueTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.iconColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? 112 : 105,
      ),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE9ECF1),
        ),
      ),
      child: compact
          ? _buildMobileContent()
          : _buildDesktopContent(),
    );
  }

  Widget _buildDesktopContent() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 21,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8.7,
                  color: Color(0xFF7D8798),
                ),
              ),
              const SizedBox(height: 2),
              _buildValue(),
              const SizedBox(height: 5),
              _buildStatus(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
            ),
            const Spacer(),
            _buildStatus(),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8.2,
            color: Color(0xFF7D8798),
          ),
        ),
        const SizedBox(height: 2),
        _buildValue(),
      ],
    );
  }

  Widget _buildValue() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF202A38),
            ),
          ),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              unit,
              style: TextStyle(
                fontSize: compact ? 7.5 : 8.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7D8798),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: statusColor,
          fontSize: compact ? 6.2 : 7.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SensorOnlineBadge extends StatelessWidget {
  const _SensorOnlineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: Color(0xFF18A06F),
          ),
          SizedBox(width: 4),
          Text(
            'Online',
            style: TextStyle(
              color: Color(0xFF169A6E),
              fontSize: 7.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorData {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;
  final Color iconColor;

  const _SensorData({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.iconColor,
  });
}


// ============================================================================
// TODAY
// ============================================================================

class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        '07:41',
        'เข้าโรงเรียน',
        'บันทึกการเข้าโรงเรียนเรียบร้อย',
        Icons.login_rounded,
        Color(0xFF18A06F)
      ),
      (
        '09:30',
        'คณิตศาสตร์',
        'กำลังเรียน · ห้อง ม.2/1',
        Icons.calculate_rounded,
        Color(0xFF2E83C5)
      ),
      (
        '10:30',
        'วิทยาศาสตร์',
        'คาบถัดไป · Lab 2',
        Icons.science_rounded,
        Color(0xFF8566C3)
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.timeline_rounded,
            title: 'สถานะของลูกวันนี้',
            subtitle: 'กิจกรรมและสถานะล่าสุด',
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      item.$1,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF8993A4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.$5.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.$4,
                      size: 17,
                      color: item.$5,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF8791A2),
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
}

// ============================================================================
// ATTENDANCE
// ============================================================================

class _AttendanceSummaryCard extends StatelessWidget {
  const _AttendanceSummaryCard();

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.fact_check_rounded,
            title: 'สรุปการมาเรียน',
            subtitle: 'ภาคเรียน 1/2569',
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '96%',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF18996C),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ปกติ',
                    style: TextStyle(
                      color: Color(0xFF169A6E),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: const LinearProgressIndicator(
              value: .96,
              minHeight: 9,
              backgroundColor: Color(0xFFEDF0F5),
              valueColor: AlwaysStoppedAnimation(
                Color(0xFF2B8FC2),
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Row(
            children: [
              Expanded(
                child: _AttendanceBox(
                  value: '48',
                  label: 'มาเรียน',
                  color: Color(0xFF18A06F),
                ),
              ),
              SizedBox(width: 7),
              Expanded(
                child: _AttendanceBox(
                  value: '2',
                  label: 'ลา',
                  color: Color(0xFFF09A37),
                ),
              ),
              SizedBox(width: 7),
              Expanded(
                child: _AttendanceBox(
                  value: '0',
                  label: 'สาย',
                  color: Color(0xFFDA5961),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _AttendanceBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              color: Color(0xFF7E8898),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LEARNING
// ============================================================================

class _LearningOverviewCard extends StatelessWidget {
  const _LearningOverviewCard();

  @override
  Widget build(BuildContext context) {
    const subjects = [
      ('คณิตศาสตร์', 88, '+5', Color(0xFF2E83C5)),
      ('วิทยาศาสตร์', 91, '+7', Color(0xFF18A06F)),
      ('ภาษาอังกฤษ', 82, '+2', Color(0xFF8A65C7)),
      ('ภาษาไทย', 86, '+3', Color(0xFFF09A37)),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  icon: Icons.analytics_rounded,
                  title: 'ภาพรวมการเรียนของลูก',
                  subtitle: 'คะแนนล่าสุดและแนวโน้มรายวิชา',
                ),
              ),
              _SmallChip(text: 'GPA 3.62'),
            ],
          ),
          const SizedBox(height: 14),
          for (final subject in subjects)
            SizedBox(
              height: 38,
              child: Row(
                children: [
                  SizedBox(
                    width: 105,
                    child: Text(
                      subject.$1,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: LinearProgressIndicator(
                        value: subject.$2 / 100,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFEDF0F5),
                        valueColor: AlwaysStoppedAnimation(
                          subject.$4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${subject.$2}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 26,
                    child: Text(
                      subject.$3,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Color(0xFF169A6E),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFDCE9F8),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: Color(0xFF2D76B8),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Insight: วิทยาศาสตร์พัฒนาขึ้นต่อเนื่อง ส่วนภาษาอังกฤษควรเสริม Vocabulary และ Reading เพิ่มอีกเล็กน้อย',
                    style: TextStyle(
                      fontSize: 9.5,
                      height: 1.55,
                      color: Color(0xFF52647A),
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
}

// ============================================================================
// SCHEDULE
// ============================================================================

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard();

  @override
  Widget build(BuildContext context) {
    const lessons = [
      ('08:30', 'ภาษาไทย', 'ครูศิริพร', false),
      ('09:30', 'คณิตศาสตร์', 'ครูอนุชา', true),
      ('10:30', 'วิทยาศาสตร์', 'ครูปวีณา · Lab 2', false),
      ('13:00', 'ภาษาอังกฤษ', 'Teacher Anna', false),
      ('14:00', 'สังคมศึกษา', 'ครูสมชาย', false),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.schedule_rounded,
            title: 'ตารางเรียนวันนี้',
            subtitle: 'ศุกร์ 21 สิงหาคม 2569',
          ),
          const SizedBox(height: 13),
          for (final lesson in lessons)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 43,
                    child: Text(
                      lesson.$1,
                      style: const TextStyle(
                        color: Color(0xFF8993A4),
                        fontSize: 8.7,
                      ),
                    ),
                  ),
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: lesson.$4
                          ? const Color(0xFFFF9B3D)
                          : const Color(0xFF63A0DA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                lesson.$2,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (lesson.$4) ...[
                              const SizedBox(width: 6),
                              const _SmallChip(
                                text: 'กำลังเรียน',
                                orange: true,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lesson.$3,
                          style: const TextStyle(
                            fontSize: 8.5,
                            color: Color(0xFF8993A4),
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
}

// ============================================================================
// HOMEWORK
// ============================================================================

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard();

  @override
  Widget build(BuildContext context) {
    const tasks = [
      (
        'แบบฝึกหัดคณิตศาสตร์ บทที่ 5',
        'ส่งพรุ่งนี้ 16:00',
        'ใกล้ถึงกำหนด',
        Color(0xFFF09A37)
      ),
      (
        'รายงานวิทยาศาสตร์',
        'ส่ง 25 ส.ค.',
        'ทำแล้ว',
        Color(0xFF18A06F)
      ),
      (
        'อ่านบทความภาษาอังกฤษ',
        'ส่ง 27 ส.ค.',
        'รอดำเนินการ',
        Color(0xFF5E8CC4)
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.assignment_rounded,
            title: 'งานและการบ้าน',
            subtitle: 'รายการที่ต้องติดตาม',
          ),
          const SizedBox(height: 12),
          for (final task in tasks)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFEDF0F4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: task.$4,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          task.$2,
                          style: const TextStyle(
                            fontSize: 8.2,
                            color: Color(0xFF8A94A5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: task.$4.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      task.$3,
                      style: TextStyle(
                        color: task.$4,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
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
}

// ============================================================================
// MESSAGE
// ============================================================================

class _SchoolMessageCard extends StatelessWidget {
  const _SchoolMessageCard();

  @override
  Widget build(BuildContext context) {
    const messages = [
      (
        Icons.person_rounded,
        'ครูประจำชั้น',
        'พรุ่งนี้เตรียมอุปกรณ์วิทยาศาสตร์'
      ),
      (
        Icons.school_rounded,
        'ฝ่ายวิชาการ',
        'สอบกลางภาค 7–11 ก.ย.'
      ),
      (
        Icons.campaign_rounded,
        'ประชาสัมพันธ์',
        'กิจกรรมวันวิทยาศาสตร์'
      ),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.chat_bubble_rounded,
            title: 'ข้อความจากโรงเรียน',
            subtitle: 'ประกาศและข้อความล่าสุด',
          ),
          const SizedBox(height: 12),
          for (final message in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      message.$1,
                      size: 18,
                      color: const Color(0xFF2B73B5),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.$2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 9.5,
                          ),
                        ),
                        Text(
                          message.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 8.3,
                            color: Color(0xFF8993A4),
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
}


// ============================================================================
// IMPORTANT ACTIVITY / SCHEDULE
// ============================================================================

class _UpcomingActivityCard extends StatelessWidget {
  const _UpcomingActivityCard();

  @override
  Widget build(BuildContext context) {
    const activities = [
      ('25 ส.ค.', 'กิจกรรมวันวิทยาศาสตร์', 'หอประชุมใหญ่'),
      ('28 ส.ค.', 'ประชุมผู้ปกครองออนไลน์', 'Google Meet'),
      ('7 ก.ย.', 'เริ่มสอบกลางภาค', 'ตามตารางสอบ'),
    ];

    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.event_rounded,
            title: 'กิจกรรมและกำหนดการสำคัญ',
            subtitle: 'สิ่งที่ผู้ปกครองควรทราบล่วงหน้า',
          ),
          const SizedBox(height: 12),
          for (final activity in activities)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5FA),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      activity.$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4A607A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.$2,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          activity.$3,
                          style: const TextStyle(
                            fontSize: 8.5,
                            color: Color(0xFF8993A4),
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
}


// ============================================================================
// COMMON SMALL COMPONENTS
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 17,
            color: const Color(0xFF2867B2),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF202A39),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 8.5,
                  color: Color(0xFF8A94A4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _SmallChip extends StatelessWidget {
  final String text;
  final bool orange;

  const _SmallChip({
    required this.text,
    this.orange = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        orange ? const Color(0xFFDF7C21) : const Color(0xFF2B75B8);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 7.8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE8EBF1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: color,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 7.8,
                        color: Color(0xFF8A94A4),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: Color(0xFF9BA4B2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
