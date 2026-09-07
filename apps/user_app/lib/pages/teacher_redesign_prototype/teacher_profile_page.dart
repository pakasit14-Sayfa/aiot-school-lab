import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  bool _isLoading = true;
  bool _hasError = false;
  List<CourseSummary> _courses = [];
  int _totalStudents = 0;
  List<TermOption> _terms = [];
  List<AiotLabDeviceItem> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      if (AuthService.sessionToken != null) {
        final results = await Future.wait([
          CourseService.listMyCourses().catchError((_) => <CourseSummary>[]),
          CourseService.listTerms().catchError((_) => <TermOption>[]),
          AiotLabService.listTeachingKitDevices().catchError(
            (_) => <AiotLabDeviceItem>[],
          ),
        ]);

        final courses = results[0] as List<CourseSummary>;
        final terms = results[1] as List<TermOption>;
        final devices = results[2] as List<AiotLabDeviceItem>;

        var studentCount = 0;
        if (courses.isNotEmpty) {
          final studentFutures = courses.map((c) async {
            try {
              final students = await CourseService.listCourseStudents(c.id);
              return students.length;
            } catch (_) {
              return 0;
            }
          });
          final counts = await Future.wait(studentFutures);
          studentCount = counts.fold(0, (sum, count) => sum + count);
        }

        if (mounted) {
          setState(() {
            _courses = courses;
            _terms = terms;
            _devices = devices;
            _totalStudents = studentCount;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: TeacherPalette.red),
            SizedBox(width: 10),
            Text(
              'ยืนยันออกจากระบบ',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: TeacherPalette.ink,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'คุณต้องการออกจากระบบบนอุปกรณ์นี้ใช่หรือไม่?',
          style: TextStyle(color: TeacherPalette.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: TeacherPalette.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherPalette.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'ออกจากระบบ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await AuthService.signOut();
      } catch (_) {}
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'โปรไฟล์ครู',
      builder: (context, isDesktop) {
        return isDesktop
            ? _DesktopLayout(
                isLoading: _isLoading,
                hasError: _hasError,
                courses: _courses,
                totalStudents: _totalStudents,
                terms: _terms,
                devices: _devices,
                onLogout: () => _handleLogout(context),
              )
            : _MobileLayout(
                isLoading: _isLoading,
                hasError: _hasError,
                courses: _courses,
                totalStudents: _totalStudents,
                terms: _terms,
                devices: _devices,
                onLogout: () => _handleLogout(context),
              );
      },
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.isLoading,
    required this.hasError,
    required this.courses,
    required this.totalStudents,
    required this.terms,
    required this.devices,
    required this.onLogout,
  });

  final bool isLoading;
  final bool hasError;
  final List<CourseSummary> courses;
  final int totalStudents;
  final List<TermOption> terms;
  final List<AiotLabDeviceItem> devices;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IdentityCard(courses: courses, totalStudents: totalStudents),
        const SizedBox(height: 14),
        _MetricGrid(
          isLoading: isLoading,
          hasError: hasError,
          courseCount: courses.length,
          totalStudents: totalStudents,
          deviceCount: devices.length,
          onlineDevices: devices
              .where((d) => d.status.toLowerCase() == 'online')
              .length,
        ),
        const SizedBox(height: 14),
        _AcademicSettingCard(terms: terms),
        const SizedBox(height: 14),
        _AiotHardwareCard(devices: devices),
        const SizedBox(height: 14),
        const _SectionCard(
          title: 'ช่วยเหลือ',
          icon: Icons.support_agent_rounded,
          children: [
            _MenuTile(
              icon: Icons.tips_and_updates_rounded,
              title: 'เคล็ดลับการใช้งาน',
              subtitle: 'ใช้แดชบอร์ดและ AIoT Lab ให้คล่องขึ้น',
            ),
            _DividerLine(),
            _MenuTile(
              icon: Icons.help_outline_rounded,
              title: 'คำถามที่พบบ่อย',
              subtitle: 'คำถามที่พบบ่อยเกี่ยวกับบัญชีและห้องเรียน',
            ),
            _DividerLine(),
            _MenuTile(
              icon: Icons.mail_outline_rounded,
              title: 'ติดต่อทีมงาน',
              subtitle: 'ติดต่อทีมงานหรือแจ้งปัญหาการใช้งาน',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'ตั้งค่า',
          icon: Icons.settings_rounded,
          children: [
            const _MenuTile(
              icon: Icons.person_rounded,
              title: 'ข้อมูลส่วนตัว',
              subtitle: 'แก้ไขชื่อ วิชาที่สอน และรูปโปรไฟล์',
            ),
            const _DividerLine(),
            const _MenuTile(
              icon: Icons.notifications_rounded,
              title: 'การแจ้งเตือน',
              subtitle: 'เลือกสิ่งที่อยากให้แจ้งเตือน',
            ),
            const _DividerLine(),
            const _MenuTile(
              icon: Icons.sync_rounded,
              title: 'ซิงก์ข้อมูลออฟไลน์ & ล้างแคช',
              subtitle: 'ซิงก์ข้อมูลใบงานและคะแนนสำหรับการใช้งานออฟไลน์',
            ),
            const _DividerLine(),
            const _MenuTile(
              icon: Icons.lock_outline_rounded,
              title: 'ความเป็นส่วนตัวและ PDPA',
              subtitle: 'สิทธิ์การใช้ข้อมูลและการยินยอม',
            ),
            const _DividerLine(),
            _MenuTile(
              icon: Icons.logout_rounded,
              title: 'ออกจากระบบ',
              subtitle: 'ออกจากระบบบนอุปกรณ์นี้',
              danger: true,
              onTap: onLogout,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _AppInfo(),
      ],
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.isLoading,
    required this.hasError,
    required this.courses,
    required this.totalStudents,
    required this.terms,
    required this.devices,
    required this.onLogout,
  });

  final bool isLoading;
  final bool hasError;
  final List<CourseSummary> courses;
  final int totalStudents;
  final List<TermOption> terms;
  final List<AiotLabDeviceItem> devices;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IdentityCard(
          isDesktop: true,
          courses: courses,
          totalStudents: totalStudents,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  _MetricGrid(
                    isLoading: isLoading,
                    hasError: hasError,
                    courseCount: courses.length,
                    totalStudents: totalStudents,
                    deviceCount: devices.length,
                    onlineDevices: devices
                        .where((d) => d.status.toLowerCase() == 'online')
                        .length,
                  ),
                  const SizedBox(height: 16),
                  _AiotHardwareCard(devices: devices),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _AcademicSettingCard(terms: terms),
                  const SizedBox(height: 16),
                  const _SectionCard(
                    title: 'ช่วยเหลือ',
                    icon: Icons.support_agent_rounded,
                    children: [
                      _MenuTile(
                        icon: Icons.tips_and_updates_rounded,
                        title: 'เคล็ดลับการใช้งาน',
                        subtitle: 'ใช้แดชบอร์ดและ AIoT Lab ให้คล่องขึ้น',
                      ),
                      _DividerLine(),
                      _MenuTile(
                        icon: Icons.help_outline_rounded,
                        title: 'คำถามที่พบบ่อย',
                        subtitle: 'คำถามที่พบบ่อยเกี่ยวกับบัญชีและห้องเรียน',
                      ),
                      _DividerLine(),
                      _MenuTile(
                        icon: Icons.mail_outline_rounded,
                        title: 'ติดต่อทีมงาน',
                        subtitle: 'ติดต่อทีมงานหรือแจ้งปัญหาการใช้งาน',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'ตั้งค่า',
          icon: Icons.settings_rounded,
          children: [
            const _MenuTile(
              icon: Icons.person_rounded,
              title: 'ข้อมูลส่วนตัว',
              subtitle: 'แก้ไขชื่อ วิชาที่สอน และรูปโปรไฟล์',
            ),
            const _DividerLine(),
            const _MenuTile(
              icon: Icons.notifications_rounded,
              title: 'การแจ้งเตือน',
              subtitle: 'เลือกสิ่งที่อยากให้แจ้งเตือน',
            ),
            const _DividerLine(),
            const _MenuTile(
              icon: Icons.sync_rounded,
              title: 'ซิงก์ข้อมูลออฟไลน์ & ล้างแคช',
              subtitle: 'ซิงก์ข้อมูลใบงานและคะแนนสำหรับการใช้งานออฟไลน์',
            ),
            const _DividerLine(),
            const _MenuTile(
              icon: Icons.lock_outline_rounded,
              title: 'ความเป็นส่วนตัวและ PDPA',
              subtitle: 'สิทธิ์การใช้ข้อมูลและการยินยอม',
            ),
            const _DividerLine(),
            _MenuTile(
              icon: Icons.logout_rounded,
              title: 'ออกจากระบบ',
              subtitle: 'ออกจากระบบบนอุปกรณ์นี้',
              danger: true,
              onTap: onLogout,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _AppInfo(),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    this.isDesktop = false,
    this.courses = const [],
    this.totalStudents = 0,
  });

  final bool isDesktop;
  final List<CourseSummary> courses;
  final int totalStudents;

  @override
  Widget build(BuildContext context) {
    final avatarSize = isDesktop ? 84.0 : 92.0;
    final avatar = Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TeacherPalette.primary, TeacherPalette.skyDeep],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.asset(
          'assets/images/teacher_mascot_lion.png',
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.75),
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: avatarSize * 0.5,
          ),
        ),
      ),
    );

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F1FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF9AD4F0)),
      ),
      child: const Text(
        'ครูผู้สอน AIoT',
        style: TextStyle(
          color: TeacherPalette.primary,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    final identity = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        avatar,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentUserModel?.email ?? 'ไม่พบข้อมูลผู้ใช้',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ครู • บัญชีผู้ใช้ยืนยันแล้ว',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              badge,
            ],
          ),
        ),
      ],
    );

    final subjectsText = courses.isNotEmpty
        ? courses.map((c) => c.subjectName).take(2).join(', ')
        : 'ยังไม่มีวิชาที่สอน';

    final classroomText = courses.isNotEmpty
        ? '${courses.length} วิชา · $totalStudents คน'
        : '-';

    final details = <Widget>[
      _DetailRow(
        icon: Icons.badge_outlined,
        label: 'Teacher ID',
        value: currentUserModel?.uid ?? '-',
      ),
      _DetailRow(
        icon: Icons.school_outlined,
        label: 'สอนวิชา',
        value: subjectsText,
      ),
      const _DetailRow(
        icon: Icons.account_balance_outlined,
        label: 'โรงเรียน',
        value: 'โรงเรียนสาธิต AIoT',
      ),
      _DetailRow(
        icon: Icons.groups_2_outlined,
        label: 'ห้องประจำชั้น/นักเรียน',
        value: classroomText,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: identity),
                Container(
                  width: 1,
                  height: 96,
                  margin: const EdgeInsets.symmetric(horizontal: 26),
                  color: TeacherPalette.border,
                ),
                Expanded(
                  flex: 6,
                  child: Wrap(
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < details.length; i += 2)
                        Row(
                          children: [
                            Expanded(child: details[i]),
                            const SizedBox(width: 14),
                            Expanded(
                              child: i + 1 < details.length
                                  ? details[i + 1]
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 18),
                const Divider(height: 1, color: TeacherPalette.border),
                const SizedBox(height: 14),
                for (var i = 0; i < details.length; i++) ...[
                  details[i],
                  if (i != details.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    this.isLoading = false,
    this.hasError = false,
    this.courseCount = 0,
    this.totalStudents = 0,
    this.deviceCount = 0,
    this.onlineDevices = 0,
  });

  final bool isLoading;
  final bool hasError;
  final int courseCount;
  final int totalStudents;
  final int deviceCount;
  final int onlineDevices;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.menu_book_rounded,
        color: TeacherPalette.primary,
        label: 'วิชาที่สอน',
        value: isLoading ? '...' : '$courseCount วิชา',
        caption: '$courseCount คอร์สในระบบ',
      ),
      (
        icon: Icons.groups_2_rounded,
        color: TeacherPalette.skyDeep,
        label: 'นักเรียนทั้งหมด',
        value: isLoading ? '...' : '$totalStudents คน',
        caption: 'ลงทะเบียนในวิชา',
      ),
      (
        icon: Icons.developer_board_rounded,
        color: TeacherPalette.orange,
        label: 'อุปกรณ์ AIoT',
        value: isLoading ? '...' : '$deviceCount ชิ้น',
        caption: onlineDevices > 0
            ? 'ออนไลน์ $onlineDevices ชุด'
            : 'พร้อมเชื่อมต่อ',
      ),
      (
        icon: Icons.verified_user_rounded,
        color: hasError ? TeacherPalette.red : TeacherPalette.violet,
        label: 'สถานะระบบ',
        value: isLoading ? '...' : (hasError ? 'Offline' : 'Online'),
        caption: hasError ? 'ซิงก์ฐานข้อมูลล้มเหลว' : 'ซิงก์ฐานข้อมูลสมบูรณ์',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        if (isNarrow) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _MetricCard(item: items[i]),
                if (i != items.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += 2) {
          rows.add(
            Row(
              children: [
                Expanded(child: _MetricCard(item: items[i])),
                const SizedBox(width: 10),
                Expanded(child: _MetricCard(item: items[i + 1])),
              ],
            ),
          );
          if (i + 2 < items.length) rows.add(const SizedBox(height: 10));
        }
        return Column(children: rows);
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final ({
    IconData icon,
    Color color,
    String label,
    String value,
    String caption,
  })
  item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherPalette.softText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Row(
              children: [
                Icon(icon, size: 15, color: TeacherPalette.primary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // ไม่มี onTap = ยังไม่มีหน้าจริง/ยังไม่ได้ต่อ backend — ปิดการกดไปเลย
    // และบอกตรง ๆ ว่ายังไม่เปิดใช้งาน แทนการขึ้น snackbar ว่า "กำลังเปิด: ..."
    // ซึ่งทำให้ผู้ใช้เข้าใจผิดว่าระบบทำงานให้แล้ว
    final enabled = onTap != null;
    const disabledColor = Color(0xFF9CA9B4);
    final iconColor = !enabled
        ? disabledColor
        : (danger ? TeacherPalette.red : TeacherPalette.ink);
    final titleColor = !enabled
        ? disabledColor
        : (danger ? TeacherPalette.red : TeacherPalette.ink);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F1FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? subtitle : '$subtitle · ยังไม่เปิดใช้งาน',
                      style: const TextStyle(
                        color: TeacherPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                enabled
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
                color: const Color(0xFF9CA9B4),
                size: enabled ? 22 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: TeacherPalette.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 18, thickness: 1, color: Color(0xFFE8EEF3));
  }
}

class _AcademicSettingCard extends StatelessWidget {
  const _AcademicSettingCard({this.terms = const []});

  final List<TermOption> terms;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'การศึกษา & ภาคเรียน',
      icon: Icons.school_rounded,
      children: [_AcademicDropdownTile(terms: terms)],
    );
  }
}

/// แสดงภาคเรียนปัจจุบันจาก `list_terms` (ข้อมูลจริง) แบบอ่านอย่างเดียว —
/// เดิมเป็น dropdown ที่เลือกได้แล้วขึ้นข้อความ "เปลี่ยนปีการศึกษาเป็น: ..."
/// ทั้งที่ไม่ได้บันทึกอะไรเลย (ไม่มี RPC เปลี่ยน/ตั้งภาคเรียนปัจจุบันในระบบ)
class _AcademicDropdownTile extends StatelessWidget {
  const _AcademicDropdownTile({this.terms = const []});

  final List<TermOption> terms;

  @override
  Widget build(BuildContext context) {
    final currentVal = terms.isNotEmpty ? terms.first.name : 'ยังไม่มีข้อมูล';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F1FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TeacherPalette.border),
            ),
            child: const Icon(
              Icons.history_edu_rounded,
              color: TeacherPalette.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ภาคเรียนปัจจุบัน',
                  style: TextStyle(
                    color: TeacherPalette.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentVal,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'ยังเปลี่ยนภาคเรียนจากหน้านี้ไม่ได้ (ยังไม่เปิดใช้งาน)',
                  style: TextStyle(
                    color: TeacherPalette.softText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _AiotHardwareCard extends StatelessWidget {
  const _AiotHardwareCard({this.devices = const []});

  final List<AiotLabDeviceItem> devices;

  @override
  Widget build(BuildContext context) {
    if (devices.isNotEmpty) {
      return _SectionCard(
        title: 'อุปกรณ์ & บอร์ดแล็บ AIoT',
        icon: Icons.developer_board_rounded,
        children: [
          for (var i = 0; i < devices.length; i++) ...[
            _HardwareTile(
              deviceName: devices[i].name.isNotEmpty
                  ? devices[i].name
                  : 'อุปกรณ์แล็บ AIoT #${i + 1}',
              status: devices[i].status.toUpperCase(),
              statusColor: devices[i].status.toLowerCase() == 'online'
                  ? TeacherPalette.green
                  : TeacherPalette.muted,
              macAddress: devices[i].deviceId,
            ),
            if (i != devices.length - 1) const _DividerLine(),
          ],
        ],
      );
    }

    return const _SectionCard(
      title: 'อุปกรณ์ & บอร์ดแล็บ AIoT',
      icon: Icons.developer_board_rounded,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'ยังไม่มีอุปกรณ์แล็บ AIoT ที่ผูกกับบัญชีนี้',
            style: TextStyle(
              color: TeacherPalette.muted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _HardwareTile extends StatelessWidget {
  const _HardwareTile({
    required this.deviceName,
    required this.status,
    required this.statusColor,
    required this.macAddress,
  });

  final String deviceName;
  final String status;
  final Color statusColor;
  final String macAddress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F1FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TeacherPalette.border),
            ),
            child: const Icon(
              Icons.developer_board_rounded,
              color: TeacherPalette.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherPalette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'ID: $macAddress',
                      style: const TextStyle(
                        color: TeacherPalette.softText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppInfo extends StatelessWidget {
  const _AppInfo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Smart School AIoT Teacher App',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TeacherPalette.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Version 1.2.0 (Build 302)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TeacherPalette.softText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
