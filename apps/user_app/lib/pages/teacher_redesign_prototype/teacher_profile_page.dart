import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../widgets/change_password_dialog.dart';
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({
    super.key,
    this.loadCourses,
    this.loadTerms,
    this.loadDevices,
    this.loadCourseStudents,
    this.updateName,
    this.changePassword,
    this.signOut,
  });

  /// Read/write seams so tests can drive loading / data / empty / failure
  /// without a Supabase client. Each defaults to the real service call.
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<TermOption>> Function()? loadTerms;
  final Future<List<AiotLabDeviceItem>> Function()? loadDevices;
  final Future<List<CourseStudent>> Function(String courseId)? loadCourseStudents;
  final Future<void> Function(String name)? updateName;
  final PasswordChanger? changePassword;
  final Future<void> Function()? signOut;

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
      if (AuthService.sessionToken != null || widget.loadCourses != null) {
        // No per-call `.catchError((_) => [])` any more: that made a failed
        // read of courses/terms/devices indistinguishable from "none", so a
        // broken backend rendered as an empty-but-healthy profile. Any
        // failure now fails the whole load and shows the error state.
        final results = await Future.wait([
          (widget.loadCourses ?? CourseService.listMyCourses)(),
          (widget.loadTerms ?? CourseService.listTerms)(),
          (widget.loadDevices ?? AiotLabService.listTeachingKitDevices)(),
        ]);

        final courses = results[0] as List<CourseSummary>;
        final terms = results[1] as List<TermOption>;
        final devices = results[2] as List<AiotLabDeviceItem>;

        var studentCount = 0;
        if (courses.isNotEmpty) {
          final loadStudents =
              widget.loadCourseStudents ?? CourseService.listCourseStudents;
          final counts = await Future.wait(
            courses.map((c) async => (await loadStudents(c.id)).length),
          );
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
    } catch (e) {
      debugPrint('TeacherProfilePage load failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// `update_user_profile` — the only profile field the backend stores is
  /// the name (first + last). No phone, avatar or subject column exists.
  Future<void> _editName() async {
    final user = currentUserModel;
    if (user == null) return;
    final ctrl = TextEditingController(text: user.name);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var submitting = false;
        String? error;
        return StatefulBuilder(
          builder: (dialogContext, setDialog) {
            Future<void> submit() async {
              final name = ctrl.text.trim();
              if (name.isEmpty) {
                setDialog(() => error = 'กรุณากรอกชื่อ');
                return;
              }
              setDialog(() {
                submitting = true;
                error = null;
              });
              try {
                final update =
                    widget.updateName ??
                    (String n) => AuthService.updateProfile(uid: user.uid, name: n);
                await update(name);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
              } catch (e) {
                debugPrint('TeacherProfilePage: update_user_profile ล้ม — $e');
                if (!dialogContext.mounted) return;
                setDialog(() {
                  submitting = false;
                  error = 'บันทึกชื่อไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
                });
              }
            }

            return _OwnController(
              controller: ctrl,
              child: AlertDialog(
                title: const Text('แก้ไขชื่อที่แสดง'),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: ctrl,
                        autofocus: true,
                        decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล'),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: TeacherPalette.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: submitting
                        ? null
                        : () => Navigator.of(dialogContext).pop(false),
                    child: const Text('ยกเลิก'),
                  ),
                  FilledButton(
                    onPressed: submitting ? null : submit,
                    child: Text(submitting ? 'กำลังบันทึก…' : 'บันทึก'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (saved != true || !mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกชื่อแล้ว')),
    );
  }

  Future<void> _changePassword() async {
    final changed = await showChangePasswordDialog(
      context,
      change: widget.changePassword,
    );
    if (!changed || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เปลี่ยนรหัสผ่านแล้ว — เครื่องอื่นที่ล็อกอินอยู่ถูกออกจากระบบ'),
      ),
    );
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
                fontSize: 17,
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
        await (widget.signOut ?? AuthService.signOut)();
      } catch (e) {
        // ออกจากระบบฝั่งเครื่องต่อได้เสมอ แต่ session ฝั่งเซิร์ฟเวอร์อาจยังอยู่
        debugPrint('TeacherProfilePage: signOut ไม่สำเร็จ — $e');
      }
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
                onEditName: _editName,
                onChangePassword: _changePassword,
              )
            : _MobileLayout(
                isLoading: _isLoading,
                hasError: _hasError,
                courses: _courses,
                totalStudents: _totalStudents,
                terms: _terms,
                devices: _devices,
                onLogout: () => _handleLogout(context),
                onEditName: _editName,
                onChangePassword: _changePassword,
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
    required this.onEditName,
    required this.onChangePassword,
  });

  final bool isLoading;
  final bool hasError;
  final List<CourseSummary> courses;
  final int totalStudents;
  final List<TermOption> terms;
  final List<AiotLabDeviceItem> devices;
  final VoidCallback onLogout;
  final VoidCallback onEditName;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IdentityCard(courses: courses, totalStudents: totalStudents, hasError: hasError),
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
        _AiotHardwareCard(devices: devices, hasError: hasError),
        // The "ช่วยเหลือ" card (เคล็ดลับ / คำถามที่พบบ่อย / ติดต่อทีมงาน) was
        // three tiles with no page, no content and no channel behind them,
        // shown greyed as "ยังไม่เปิดใช้งาน". Removed.
        const SizedBox(height: 14),
        _SectionCard(
          title: 'ตั้งค่า',
          icon: Icons.settings_rounded,
          children: [
            // การแจ้งเตือน / ซิงก์ออฟไลน์ / PDPA tiles used to sit here greyed
            // as "ยังไม่เปิดใช้งาน" — no preference table, no offline store,
            // no consent screen. Only what the backend can do is listed.
            _MenuTile(
              icon: Icons.person_rounded,
              title: 'แก้ไขชื่อที่แสดง',
              subtitle: 'ชื่อ-นามสกุลที่แสดงในระบบ (update_user_profile)',
              onTap: onEditName,
            ),
            const _DividerLine(),
            _MenuTile(
              icon: Icons.lock_outline_rounded,
              title: 'เปลี่ยนรหัสผ่าน',
              subtitle: 'ตรวจรหัสเดิมก่อน และออกจากระบบเครื่องอื่นให้',
              onTap: onChangePassword,
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
    required this.onEditName,
    required this.onChangePassword,
  });

  final bool isLoading;
  final bool hasError;
  final List<CourseSummary> courses;
  final int totalStudents;
  final List<TermOption> terms;
  final List<AiotLabDeviceItem> devices;
  final VoidCallback onLogout;
  final VoidCallback onEditName;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IdentityCard(
          isDesktop: true,
          hasError: hasError,
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
                  _AiotHardwareCard(devices: devices, hasError: hasError),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _AcademicSettingCard(terms: terms),
                  // "ช่วยเหลือ" card removed — see the mobile layout note.
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
            // การแจ้งเตือน / ซิงก์ออฟไลน์ / PDPA tiles used to sit here greyed
            // as "ยังไม่เปิดใช้งาน" — no preference table, no offline store,
            // no consent screen. Only what the backend can do is listed.
            _MenuTile(
              icon: Icons.person_rounded,
              title: 'แก้ไขชื่อที่แสดง',
              subtitle: 'ชื่อ-นามสกุลที่แสดงในระบบ (update_user_profile)',
              onTap: onEditName,
            ),
            const _DividerLine(),
            _MenuTile(
              icon: Icons.lock_outline_rounded,
              title: 'เปลี่ยนรหัสผ่าน',
              subtitle: 'ตรวจรหัสเดิมก่อน และออกจากระบบเครื่องอื่นให้',
              onTap: onChangePassword,
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
    this.hasError = false,
  });

  final bool isDesktop;
  final List<CourseSummary> courses;
  final bool hasError;
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
          fontSize: 12,
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
                  fontSize: 22,
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

    // A failed load must not read as "no courses" — the two used to be
    // identical because every read swallowed its own error.
    final subjectsText = hasError
        ? 'โหลดวิชาไม่สำเร็จ'
        : courses.isNotEmpty
        ? courses.map((c) => c.subjectName).take(2).join(', ')
        : 'ยังไม่มีวิชาที่สอน';

    final classroomText = hasError
        ? 'ยังไม่ทราบจำนวนวิชาและนักเรียน'
        : courses.isNotEmpty
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
      // ไม่มี schoolName ใน UserModel และไม่มี service ไหนที่หน้านี้เรียกอยู่
      // ที่ resolve ชื่อโรงเรียนจาก schoolId ได้ — ตัดแถวนี้ออกแทนที่จะโชว์
      // ชื่อโรงเรียนปลอมตายตัวทุกบัญชี
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
        value: isLoading ? '...' : (hasError ? '—' : '$courseCount วิชา'),
        caption: hasError ? 'โหลดไม่สำเร็จ' : '$courseCount คอร์สในระบบ',
      ),
      (
        icon: Icons.groups_2_rounded,
        color: TeacherPalette.skyDeep,
        label: 'นักเรียนทั้งหมด',
        value: isLoading ? '...' : (hasError ? '—' : '$totalStudents คน'),
        caption: hasError ? 'โหลดไม่สำเร็จ' : 'ลงทะเบียนในวิชา',
      ),
      (
        icon: Icons.developer_board_rounded,
        color: TeacherPalette.orange,
        label: 'อุปกรณ์ AIoT',
        value: isLoading ? '...' : (hasError ? '—' : '$deviceCount ชิ้น'),
        caption: hasError
            ? 'โหลดไม่สำเร็จ'
            : onlineDevices > 0
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
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;

  /// Required: a tile with nothing behind it is not rendered at all any
  /// more (it used to be greyed out with "· ยังไม่เปิดใช้งาน").
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = danger ? TeacherPalette.red : TeacherPalette.ink;
    final titleColor = danger ? TeacherPalette.red : TeacherPalette.ink;

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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA9B4),
                size: 22,
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
                  fontSize: 11,
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
                  fontSize: 13,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentVal,
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // "ยังเปลี่ยนภาคเรียนจากหน้านี้ไม่ได้ (ยังไม่เปิดใช้งาน)" used to
                // follow. The current term is a school-wide setting, not a
                // per-teacher choice — there is nothing here to enable.
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiotHardwareCard extends StatelessWidget {
  const _AiotHardwareCard({this.devices = const [], this.hasError = false});

  final List<AiotLabDeviceItem> devices;
  final bool hasError;

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

    return _SectionCard(
      title: 'อุปกรณ์ & บอร์ดแล็บ AIoT',
      icon: Icons.developer_board_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            hasError
                ? 'โหลดรายการอุปกรณ์ไม่สำเร็จ'
                : 'ยังไม่มีอุปกรณ์แล็บ AIoT ที่ผูกกับบัญชีนี้',
            style: const TextStyle(
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

/// Disposes the dialog's controller with the dialog's own element instead
/// of right after `showDialog` returns (which tears it down mid-animation).
class _OwnController extends StatefulWidget {
  const _OwnController({required this.controller, required this.child});
  final TextEditingController controller;
  final Widget child;
  @override
  State<_OwnController> createState() => _OwnControllerState();
}

class _OwnControllerState extends State<_OwnController> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
