import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

class SchoolAdminProfilePage extends StatefulWidget {
  const SchoolAdminProfilePage({
    super.key,
    this.onBack,
    this.loadLogs,
    this.loadSummary,
    this.updateProfile,
    this.signOutAllDevices,
  });

  final VoidCallback? onBack;

  /// Injectable seams for tests — production leaves these null and uses the
  /// real service (same pattern as school_resources_page).
  final Future<List<SchoolAdminAuditLog>> Function()? loadLogs;
  final Future<SchoolAdminDashboardSummary> Function()? loadSummary;
  final Future<void> Function({required String uid, required String name})?
  updateProfile;
  final Future<void> Function()? signOutAllDevices;

  @override
  State<SchoolAdminProfilePage> createState() => _SchoolAdminProfilePageState();
}

class _SchoolAdminProfilePageState extends State<SchoolAdminProfilePage> {
  final TextEditingController _fullNameController = TextEditingController(
    text: 'ผู้ดูแลโรงเรียน',
  );
  final TextEditingController _displayNameController = TextEditingController(
    text: 'ผู้ดูแลโรงเรียน',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'admin@school.ac.th',
  );
  // ว่างไว้ ไม่ใส่ค่าตัวอย่าง — `public.users` มีแค่
  // id/school_id/email/student_code/first_name/last_name/status/building
  // ไม่มีคอลัมน์ phone, ตำแหน่ง หรือรหัสพนักงานเลย (ตรวจกับ information_schema
  // ของฐานข้อมูลที่รันอยู่ ระวัง auth.users ของอีกแอปที่มี phone และชื่อชนกัน)
  //
  // ของเดิมใส่ '089-000-0000' / 'ADM-0001' / 'ผู้ดูแลระบบโรงเรียน' ไว้ และ
  // initState ไม่เคยเขียนทับสามช่องนี้ ผู้ดูแลจึงเห็นเบอร์โทรกับรหัสพนักงาน
  // ที่ดูเหมือนของตัวเองทั้งที่ระบบไม่เคยเก็บ
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _employeeCodeController =
      TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  String? _profileImageUrl;

  List<_ProfileLog> _logs = [];

  /// แยก loading / data / empty / error ออกจากกัน เดิมมีแค่ `_logs` เปล่า ๆ
  /// กับ `catch (_) {}` ที่กลืน error ทำให้ "ยังไม่มี log" กับ "โหลดไม่สำเร็จ"
  /// หน้าตาเหมือนกันทุกประการ
  bool _logsLoading = true;
  bool _logsFailed = false;
  bool _savingProfile = false;

  // ชื่อโรงเรียนจริง — เดิม hardcode 'โรงเรียนตัวอย่าง AIoT Smart Lab' ไว้ 2 จุด
  // ไม่มี field โรงเรียนใน UserModel เลยดึงจาก dashboard summary ที่มีอยู่แล้ว
  String? _schoolName;

  @override
  void initState() {
    super.initState();
    final user = currentUserModel;
    if (user != null) {
      if (user.name.isNotEmpty) _fullNameController.text = user.name;
      _displayNameController.text = user.role == UserRole.schoolAdmin
          ? 'ผู้ดูแลโรงเรียน'
          : user.role.name;
      if (user.email.isNotEmpty) _emailController.text = user.email;
    }
    _loadLogs();
    _loadSchoolName();
  }

  Future<void> _loadSchoolName() async {
    try {
      final summary = await (widget.loadSummary?.call() ??
          SchoolAdminPlatformService().fetchDashboardSummary());
      if (!mounted) return;
      setState(() => _schoolName = summary.schoolName);
    } catch (e) {
      debugPrint('SchoolAdminProfilePage fetchDashboardSummary failed: $e');
      // เงียบพอ ไม่ใช่ข้อมูลหลักของหน้านี้ — ช่อง "โรงเรียน" จะขึ้น
      // 'ยังไม่มีข้อมูล' ต่อไปแทนที่จะพยายามอีกรอบ
    }
  }

  Future<void> _loadLogs() async {
    if (mounted) {
      setState(() {
        _logsLoading = true;
        _logsFailed = false;
      });
    }
    try {
      final logs = await (widget.loadLogs ??
          () => SchoolAdminPlatformService().fetchAuditLogs(limit: 10))();
      if (!mounted) return;
      setState(() {
        _logs = logs
            .map(
              (l) => _ProfileLog(
                time:
                    '${l.createdAt.hour.toString().padLeft(2, '0')}:${l.createdAt.minute.toString().padLeft(2, '0')} น.',
                action: l.action,
                detail: l.detail.isNotEmpty ? l.detail : l.target,
                // เดิม hardcode 'success' ให้ทุกรายการ ทำให้ log ทุกอันถูก
                // ระบายเป็นสีเขียวว่าสำเร็จ แม้จะเป็นเหตุการณ์ล้มเหลวก็ตาม
                // audit_logs ไม่มีคอลัมน์ผลลัพธ์ จึงอนุมานจากชื่อ action
                // เท่าที่บอกได้จริง และไม่เดาเมื่อบอกไม่ได้
                type: _logTypeFor(l.action),
              ),
            )
            .toList();
        _logsLoading = false;
      });
    } catch (e) {
      debugPrint('SchoolAdminProfilePage fetchAuditLogs failed: $e');
      if (!mounted) return;
      setState(() {
        _logsLoading = false;
        _logsFailed = true;
      });
    }
  }

  /// `audit_logs` ไม่ได้เก็บสถานะสำเร็จ/ล้มเหลวไว้ ชื่อ action จึงเป็นสิ่งเดียว
  /// ที่ใช้อนุมานได้ อะไรที่บอกไม่ได้ให้เป็นกลาง ดีกว่าเดาว่าสำเร็จ
  String _logTypeFor(String action) {
    final a = action.toLowerCase();
    if (a.contains('fail') || a.contains('denied') || a.contains('revoke')) {
      return 'error';
    }
    if (a.contains('delete') || a.contains('suspend') || a.contains('archive')) {
      return 'warning';
    }
    return 'neutral';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeCodeController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message, style: const TextStyle(height: 1.45)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.check_rounded),
              label: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _changeProfileImage() async {
    final TextEditingController urlController = TextEditingController(
      text: _profileImageUrl ?? '',
    );

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(16),
          title: const Text('เปลี่ยนรูปโปรไฟล์'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ในหน้า Preview นี้สามารถวางลิงก์รูปภาพเพื่อเปลี่ยนรูปโปรไฟล์ได้ '
                  'เมื่อเชื่อมฐานข้อมูลจริงจึงเปลี่ยนเป็นอัปโหลดไฟล์ไปยัง Storage ได้',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: urlController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'ลิงก์รูปโปรไฟล์',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.image_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            if (_profileImageUrl != null)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop('__REMOVE__'),
                child: const Text('ลบรูป'),
              ),
            FilledButton.icon(
              onPressed: () {
                final String value = urlController.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('ใช้รูปนี้'),
            ),
          ],
        );
      },
    );

    urlController.dispose();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _profileImageUrl = result == '__REMOVE__' ? null : result;
    });

    _message(
      result == '__REMOVE__' ? 'ลบรูปโปรไฟล์แล้ว' : 'เปลี่ยนรูปโปรไฟล์แล้ว',
    );
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      _message('กรุณากรอกชื่อและอีเมลให้ครบ');
      return;
    }

    final bool confirmed = await _confirm(
      title: 'ยืนยันการบันทึกโปรไฟล์',
      message:
          'ต้องการบันทึกข้อมูลโปรไฟล์ที่แก้ไขแล้วหรือไม่\n(หมายเหตุ: ระบบบันทึกข้อมูลโปรไฟล์เพิ่มเติมยังไม่เชื่อมต่อระบบหลังบ้าน ข้อมูลเพิ่มเติมจะไม่ถูกบันทึกจริง)',
    );

    if (!confirmed || !mounted) {
      return;
    }

    // เดิมบรรทัดนี้ขึ้นข้อความว่า "บันทึกข้อมูลโปรไฟล์แล้ว" โดยไม่เขียนอะไรเลย
    //
    // ชื่อ-นามสกุลบันทึกได้จริงผ่าน update_user_profile ซึ่งรับ p_token
    // (ตรวจลายเซ็นกับฐานข้อมูลที่รันอยู่แล้ว) — ระวังอย่าสับสนกับ
    // admin_update_user_profile ที่ไม่มี p_token เลย นั่นเป็น RPC ของ
    // aiot_dev_dashboard เรียกจากแอปนี้จะได้ actor เป็น null เงียบ ๆ
    //
    // ฟิลด์อื่น (อีเมล เบอร์โทร รูปโปรไฟล์ การแจ้งเตือน) ยังไม่มีที่เก็บใน
    // สคีมา จึงไม่อ้างว่าบันทึกให้
    final user = currentUserModel;
    if (user == null) {
      _message('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    setState(() => _savingProfile = true);
    try {
      final save = widget.updateProfile ??
          ({required String uid, required String name}) =>
              AuthService.updateProfile(uid: uid, name: name);
      await save(uid: user.uid, name: _fullNameController.text.trim());
      if (!mounted) return;
      _message('บันทึกชื่อเรียบร้อยแล้ว (ฟิลด์อื่นยังไม่รองรับการบันทึก)');
    } catch (e) {
      debugPrint('updateProfile failed: $e');
      if (!mounted) return;
      _message('บันทึกไม่สำเร็จ กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  /// เดิม dialog นี้เก็บรหัสผ่านปัจจุบัน/ใหม่/ยืนยัน แล้วโชว์ "เปลี่ยนรหัสผ่านแล้ว"
  /// โดยไม่เรียก backend เลยสักครั้ง — ผู้ใช้ที่เชื่อว่าเปลี่ยนแล้วจะยังคง
  /// ใช้รหัสผ่านเดิมต่อไปโดยไม่รู้ตัว
  ///
  /// ไม่มี RPC `change_password(p_token, old, new)` ในระบบ — เส้นทางที่มีจริง
  /// คือ `request_password_reset_otp` + `confirm_password_reset` ซึ่งเป็น
  /// email-OTP flow (ยืนยันผ่านรหัสที่ส่งไปอีเมล) ไม่ใช่กรอกรหัสเดิม จึงต้อง
  /// มีหน้าของตัวเอง ไม่ใช่ปลอมไว้หลังปุ่มนี้ — เหมือนที่แก้ไว้แล้วใน
  /// director_settings_page.dart
  void _changePassword() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('เปลี่ยนรหัสผ่าน'),
        content: const Text(
          'การเปลี่ยนรหัสผ่านต้องยืนยันผ่านรหัส OTP ที่ส่งไปยังอีเมลของบัญชี '
          'ยังไม่เปิดใช้งานจากหน้านี้ — ใช้ "ลืมรหัสผ่าน" ที่หน้าเข้าสู่ระบบแทน',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('รับทราบ'),
          ),
        ],
      ),
    );
  }

  /// เดิมปุ่มนี้แค่โชว์ dialog ยืนยันแล้วบอก "ออกจากระบบอุปกรณ์อื่นแล้ว" โดยไม่
  /// เรียก backend เลย — ตอนนี้เรียก `auth_sign_out_all` จริงผ่าน
  /// `AuthService.signOutAllDevices()` ซึ่งเพิกถอนทุก session ของบัญชีนี้
  /// **รวมถึงเครื่องนี้เองด้วย** (ไม่มีเส้นทาง RPC ที่เพิกถอนเฉพาะเครื่องอื่น)
  /// ป้ายและข้อความยืนยันด้านล่างเลยเขียนตรงตามพฤติกรรมจริง ไม่ใช่ "อุปกรณ์อื่น"
  Future<void> _signOutAllDevices() async {
    final bool confirmed = await _confirm(
      title: 'ยืนยันออกจากระบบทุกอุปกรณ์',
      message:
          'ทุกเครื่องที่เข้าสู่ระบบด้วยบัญชีนี้จะต้องเข้าสู่ระบบใหม่ รวมถึงเครื่องนี้ด้วย ต้องการดำเนินการต่อหรือไม่',
    );
    if (!confirmed || !mounted) return;

    try {
      await (widget.signOutAllDevices?.call() ??
          AuthService.signOutAllDevices());
    } catch (e) {
      debugPrint('SchoolAdminProfilePage signOutAllDevices failed: $e');
      if (!mounted) return;
      _message('ออกจากระบบไม่สำเร็จ กรุณาลองใหม่');
    }
  }

  Widget _profileAvatar(double size) {
    if (_profileImageUrl == null || _profileImageUrl!.trim().isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: SchoolAdminPalette.primary,
        ),
        child: Icon(
          Icons.person_rounded,
          size: size * 0.48,
          color: Colors.white,
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        _profileImageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return Container(
                width: size,
                height: size,
                color: SchoolAdminPalette.primary,
                child: Icon(
                  Icons.person_rounded,
                  size: size * 0.48,
                  color: Colors.white,
                ),
              );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 115),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1250),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 14),
                  _buildDisclosureBanner(),
                  const SizedBox(height: 14),
                  _buildAccountSummary(),
                  const SizedBox(height: 14),
                  _buildPersonalInformation(),
                  const SizedBox(height: 14),
                  _buildAccountInformation(),
                  const SizedBox(height: 14),
                  // ส่วน "การแจ้งเตือนของฉัน" (สวิตช์ 3 ตัว) ถูกถอดออก 2026-09-14:
                  // ไม่มี RPC/ตารางเก็บค่า และไม่มีระบบส่งอีเมล/แจ้งเตือนความ
                  // ปลอดภัยที่จะอ่านค่านั้น — สวิตช์ที่กดแล้วไม่มีผลอะไรเลย
                  // ไม่ควรอยู่บนหน้าจอ เอากลับมาพร้อมที่เก็บค่าและระบบที่ใช้ค่า
                  _buildSecurity(),
                  const SizedBox(height: 14),
                  _buildLogs(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool mobile = constraints.maxWidth < 700;

              final Widget profile = Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _profileAvatar(mobile ? 78 : 92),
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Material(
                          color: SchoolAdminPalette.primaryDark,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _changeProfileImage,
                            child: const SizedBox(
                              width: 34,
                              height: 34,
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 17,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fullNameController.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: mobile ? 18 : 22,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _positionController.text,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: SchoolAdminPalette.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _schoolName ?? 'ยังไม่มีข้อมูล',
                          style: const TextStyle(
                            fontSize: 11,
                            color: SchoolAdminPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _ProfileBadge(
                              label: 'ผู้ดูแลโรงเรียน',
                              color: SchoolAdminPalette.primaryDark,
                            ),
                            _ProfileBadge(
                              label: 'พร้อมใช้งาน',
                              color: SchoolAdminPalette.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final Widget actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('กลับ'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _changeProfileImage,
                    icon: const Icon(Icons.image_rounded),
                    label: const Text('เปลี่ยนรูป'),
                  ),
                  FilledButton.icon(
                    // ปิดปุ่มระหว่างบันทึก กันกดซ้ำแล้วยิง RPC ซ้อน
                    onPressed: _savingProfile ? null : _saveProfile,
                    icon: _savingProfile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_savingProfile ? 'กำลังบันทึก…' : 'บันทึก'),
                  ),
                ],
              );

              if (mobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [profile, const SizedBox(height: 16), actions],
                );
              }

              return Row(
                children: [
                  Expanded(child: profile),
                  const SizedBox(width: 14),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSummary() {
    // 'เข้าใช้ล่าสุด' และ 'ความปลอดภัย' เดิม hardcode '09:20 น.' และ 'ปกติ /
    // ไม่พบการเข้าสู่ระบบผิดปกติ' ตายตัว — ไม่มี RPC ใดคืนเวลาล็อกอินล่าสุด
    // หรือผลตรวจจับความผิดปกติเลย เปลี่ยนเป็น 'ยังไม่มีข้อมูล' แทนการอ้าง
    // สิ่งที่ระบบไม่เคยวัด 'สถานะบัญชี' ใช้ currentUserModel.status จริง
    // (ไม่ hardcode 'ใช้งาน' เพราะ enum อาจเป็นค่าอื่นได้ในอนาคต)
    final String accountStatus = currentUserModel?.status ?? 'ยังไม่มีข้อมูล';
    final List<_ProfileSummary> items = [
      _ProfileSummary(
        title: 'สถานะบัญชี',
        value: accountStatus,
        detail: 'สถานะบัญชีตามระบบปัจจุบัน',
        icon: Icons.verified_user_rounded,
        color: SchoolAdminPalette.green,
      ),
      const _ProfileSummary(
        title: 'เข้าใช้ล่าสุด',
        value: 'ยังไม่มีข้อมูล',
        detail: 'ระบบยังไม่เก็บเวลาเข้าสู่ระบบล่าสุดในเวอร์ชันนี้',
        icon: Icons.schedule_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      const _ProfileSummary(
        title: 'สิทธิ์',
        value: 'ผู้ดูแล',
        detail: 'ดูแลข้อมูลภายในโรงเรียน',
        icon: Icons.admin_panel_settings_rounded,
        color: Color(0xFF4F6078),
      ),
      const _ProfileSummary(
        title: 'ความปลอดภัย',
        value: 'ยังไม่มีข้อมูล',
        detail: 'ระบบยังไม่มีการตรวจจับความผิดปกติในการเข้าสู่ระบบในเวอร์ชันนี้',
        icon: Icons.security_rounded,
        color: SchoolAdminPalette.secondary,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int columns = 4;
        if (constraints.maxWidth < 950) {
          columns = 2;
        }
        if (constraints.maxWidth < 300) {
          columns = 1;
        }

        const double spacing = 10;
        final double width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((_ProfileSummary item) {
            return SizedBox(
              width: width,
              child: _ProfileSummaryCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPersonalInformation() {
    return _ProfileSection(
      title: 'ข้อมูลส่วนตัว',
      subtitle: 'ข้อมูลที่ใช้สำหรับติดต่อและแสดงในระบบ',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool oneColumn = constraints.maxWidth < 700;
          final double width = oneColumn
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: width,
                child: TextField(
                  controller: _fullNameController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ-นามสกุล',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อที่แสดงในระบบ',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'อีเมล',
                    prefixIcon: Icon(Icons.email_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์โทรศัพท์',
                    hintText: 'ยังไม่รองรับการบันทึก',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccountInformation() {
    return _ProfileSection(
      title: 'ข้อมูลการทำงานและบัญชี',
      subtitle: 'ข้อมูลบทบาท ตำแหน่ง และหน่วยงานของผู้ใช้งาน',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool oneColumn = constraints.maxWidth < 700;
          final double width = oneColumn
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: width,
                child: TextField(
                  controller: _employeeCodeController,
                  decoration: const InputDecoration(
                    labelText: 'รหัสผู้ใช้งาน / รหัสบุคลากร',
                    hintText: 'ยังไม่รองรับการบันทึก',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: TextField(
                  controller: _positionController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'ตำแหน่ง',
                    hintText: 'ยังไม่รองรับการบันทึก',
                    prefixIcon: Icon(Icons.workspace_premium_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: TextField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'ฝ่าย / หน่วยงาน',
                    hintText: 'ยังไม่รองรับการบันทึก',
                    prefixIcon: Icon(Icons.account_tree_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: const _ReadOnlyProfileField(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'บทบาทในระบบ',
                  value: 'ผู้ดูแลโรงเรียน',
                ),
              ),
              SizedBox(
                width: width,
                child: _ReadOnlyProfileField(
                  icon: Icons.school_rounded,
                  label: 'โรงเรียน',
                  value: _schoolName ?? 'ยังไม่มีข้อมูล',
                ),
              ),
              SizedBox(
                width: width,
                // ไม่มีคอลัมน์ created_at ของบัญชีที่ RPC ใดส่งมาให้หน้านี้เลย
                // (ต่างจาก audit_logs ที่มีแค่เหตุการณ์ ไม่ใช่วันสร้างบัญชี)
                child: const _ReadOnlyProfileField(
                  icon: Icons.calendar_month_rounded,
                  label: 'สร้างบัญชีเมื่อ',
                  value: 'ยังไม่มีข้อมูล',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSecurity() {
    return _ProfileSection(
      title: 'ความปลอดภัยของบัญชี',
      subtitle: 'จัดการรหัสผ่านและตรวจสอบสถานะบัญชี',
      child: Column(
        children: [
          _ProfileActionRow(
            icon: Icons.password_rounded,
            title: 'เปลี่ยนรหัสผ่าน',
            detail: 'แนะนำให้เปลี่ยนรหัสผ่านเป็นระยะ',
            buttonText: 'เปลี่ยนรหัสผ่าน',
            onPressed: _changePassword,
          ),
          const SizedBox(height: 9),
          // ไม่มี RPC ใดที่คืนรายการ session/อุปกรณ์ที่ล็อกอินอยู่ — ปุ่มเดิม
          // กดแล้วไม่เปิดอะไรจริง ปิดไว้พร้อมเหตุผลแทนการกดแล้วไม่มีอะไรเกิดขึ้น
          _ProfileActionRow(
            icon: Icons.devices_rounded,
            title: 'อุปกรณ์ที่เข้าสู่ระบบ',
            detail: 'ยังไม่มีระบบแสดงรายการอุปกรณ์/เซสชันที่ล็อกอินอยู่ในเวอร์ชันนี้',
            buttonText: 'ดูอุปกรณ์',
            onPressed: null,
          ),
          const SizedBox(height: 9),
          _ProfileActionRow(
            icon: Icons.logout_rounded,
            title: 'ออกจากระบบทุกอุปกรณ์',
            detail: 'เพิกถอน session ทุกเครื่องของบัญชีนี้ รวมถึงเครื่องนี้ด้วย',
            buttonText: 'ออกจากระบบ',
            danger: true,
            onPressed: _signOutAllDevices,
          ),
        ],
      ),
    );
  }

  Widget _buildDisclosureBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB2DDFF)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF175CD3), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'ข้อมูลโปรไฟล์ดึงจากบัญชีปัจจุบัน (ชื่อและอีเมล) ส่วนข้อมูลเพิ่มเติม (เบอร์โทร, ตำแหน่ง, รหัสพนักงาน) ยังอยู่ระหว่างเชื่อมต่อระบบหลังบ้าน',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF1849A9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogs() {
    return _ProfileSection(
      title: 'ประวัติการใช้งานบัญชี',
      subtitle: 'ดูการเข้าสู่ระบบ การแก้ไขโปรไฟล์ และการเปลี่ยนรหัสผ่านล่าสุด',
      child: _logs.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              alignment: Alignment.center,
              child: _logsLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _logsFailed
                              ? 'โหลดประวัติไม่สำเร็จ'
                              : 'ยังไม่มีข้อมูลประวัติกิจกรรม',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _logsFailed
                                ? SchoolAdminPalette.red
                                : SchoolAdminPalette.textSecondary,
                          ),
                        ),
                        if (_logsFailed) ...[
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: _loadLogs,
                            style: TextButton.styleFrom(minimumSize: Size.zero),
                            child: const Text('ลองใหม่'),
                          ),
                        ],
                      ],
                    ),
            )
          : Column(
              children: _logs.map((_ProfileLog log) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _ProfileLogRow(log: log),
                );
              }).toList(),
            ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.45,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.data});

  final _ProfileSummary data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          _ProfileIconBox(icon: data.icon, color: data.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.35,
                    color: SchoolAdminPalette.textSecondary,
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

class _ReadOnlyProfileField extends StatelessWidget {
  const _ReadOnlyProfileField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SchoolAdminPalette.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: SchoolAdminPalette.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            size: 17,
            color: SchoolAdminPalette.textMuted,
          ),
        ],
      ),
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  const _ProfileActionRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.buttonText,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String buttonText;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color color = danger
        ? SchoolAdminPalette.red
        : SchoolAdminPalette.primaryDark;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool mobile = constraints.maxWidth < 600;

        final Widget info = Row(
          children: [
            _ProfileIconBox(icon: icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.4,
                      color: SchoolAdminPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: danger
                  ? SchoolAdminPalette.red.withAlpha(70)
                  : SchoolAdminPalette.border,
            ),
          ),
          child: mobile
              ? Column(
                  children: [
                    info,
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onPressed,
                        style: danger
                            ? OutlinedButton.styleFrom(foregroundColor: color)
                            : null,
                        child: Text(buttonText),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: onPressed,
                      style: danger
                          ? OutlinedButton.styleFrom(foregroundColor: color)
                          : null,
                      child: Text(buttonText),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ProfileLogRow extends StatelessWidget {
  const _ProfileLogRow({required this.log});

  final _ProfileLog log;

  @override
  Widget build(BuildContext context) {
    // ไม่มีสีเขียว "สำเร็จ" แล้ว เพราะ audit_logs ไม่ได้บอกผลลัพธ์ — เขียว
    // ทุกแถวคือการอ้างสิ่งที่ข้อมูลไม่ได้บอก
    final Color color = switch (log.type) {
      'error' => SchoolAdminPalette.red,
      'warning' => SchoolAdminPalette.secondary,
      _ => SchoolAdminPalette.primaryDark,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          _ProfileIconBox(icon: Icons.history_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              log.action,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              log.detail,
              style: const TextStyle(
                fontSize: 10.5,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              log.time,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _ProfileIconBox extends StatelessWidget {
  const _ProfileIconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withAlpha(23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _ProfileSummary {
  const _ProfileSummary({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
}

class _ProfileLog {
  const _ProfileLog({
    required this.time,
    required this.action,
    required this.detail,
    required this.type,
  });

  final String time;
  final String action;
  final String detail;
  final String type;
}
