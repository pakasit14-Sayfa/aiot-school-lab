import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../theme/school_admin_palette.dart';

class SchoolAdminProfilePage extends StatefulWidget {
  const SchoolAdminProfilePage({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

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
  final TextEditingController _phoneController = TextEditingController(
    text: '089-000-0000',
  );
  final TextEditingController _employeeCodeController = TextEditingController(
    text: 'ADM-0001',
  );
  final TextEditingController _positionController = TextEditingController(
    text: 'ผู้ดูแลระบบโรงเรียน',
  );
  final TextEditingController _departmentController = TextEditingController(
    text: 'ฝ่ายเทคโนโลยีสารสนเทศ',
  );

  String? _profileImageUrl;
  bool _emailNotification = true;
  bool _systemNotification = true;
  bool _securityNotification = true;

  List<_ProfileLog> _logs = [];

  @override
  void initState() {
    super.initState();
    final user = currentUserModel;
    if (user != null) {
      if (user.name.isNotEmpty) _fullNameController.text = user.name;
      _displayNameController.text = user.role == UserRole.schoolAdmin ? 'ผู้ดูแลโรงเรียน' : user.role.name;
      if (user.email.isNotEmpty) _emailController.text = user.email;
    }
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await SchoolAdminPlatformService().fetchAuditLogs(limit: 10);
      if (!mounted) return;
      setState(() {
        _logs = logs.map((l) => _ProfileLog(
          time: '${l.createdAt.hour.toString().padLeft(2, '0')}:${l.createdAt.minute.toString().padLeft(2, '0')} น.',
          action: l.action,
          detail: l.detail.isNotEmpty ? l.detail : l.target,
          type: 'success',
        )).toList();
      });
    } catch (_) {}
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          content: Text(
            message,
            style: const TextStyle(height: 1.45),
          ),
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
    final TextEditingController urlController =
        TextEditingController(text: _profileImageUrl ?? '');

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
      message: 'ต้องการบันทึกข้อมูลโปรไฟล์ที่แก้ไขแล้วหรือไม่\n(หมายเหตุ: ระบบบันทึกข้อมูลโปรไฟล์เพิ่มเติมยังไม่เชื่อมต่อระบบหลังบ้าน ข้อมูลเพิ่มเติมจะไม่ถูกบันทึกจริง)',
    );

    if (!confirmed || !mounted) {
      return;
    }

    _message('บันทึกข้อมูลโปรไฟล์แล้ว (ข้อมูลเพิ่มเติมยังไม่เชื่อมต่อระบบหลังบ้าน)');
  }

  Future<void> _changePassword() async {
    final TextEditingController currentController = TextEditingController();
    final TextEditingController newController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();

    bool hideCurrent = true;
    bool hideNew = true;
    bool hideConfirm = true;

    final bool? saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            return AlertDialog(
              insetPadding: const EdgeInsets.all(16),
              title: const Text('เปลี่ยนรหัสผ่าน'),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: currentController,
                        obscureText: hideCurrent,
                        decoration: InputDecoration(
                          labelText: 'รหัสผ่านปัจจุบัน',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                hideCurrent = !hideCurrent;
                              });
                            },
                            icon: Icon(
                              hideCurrent
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newController,
                        obscureText: hideNew,
                        decoration: InputDecoration(
                          labelText: 'รหัสผ่านใหม่',
                          prefixIcon: const Icon(Icons.password_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                hideNew = !hideNew;
                              });
                            },
                            icon: Icon(
                              hideNew
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmController,
                        obscureText: hideConfirm,
                        decoration: InputDecoration(
                          labelText: 'ยืนยันรหัสผ่านใหม่',
                          prefixIcon: const Icon(Icons.password_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                hideConfirm = !hideConfirm;
                              });
                            },
                            icon: Icon(
                              hideConfirm
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'รหัสผ่านควรมีอย่างน้อย 8 ตัวอักษร และคาดเดาได้ยาก',
                          style: TextStyle(
                            fontSize: 11,
                            color: SchoolAdminPalette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final String current = currentController.text.trim();
                    final String next = newController.text.trim();
                    final String confirm = confirmController.text.trim();

                    if (current.isEmpty || next.length < 8 || next != confirm) {
                      _message(
                        'กรุณาตรวจรหัสผ่านปัจจุบัน และยืนยันรหัสผ่านใหม่ให้ตรงกัน',
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(true);
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('เปลี่ยนรหัสผ่าน'),
                ),
              ],
            );
          },
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();

    if (saved == true && mounted) {
      _message('เปลี่ยนรหัสผ่านแล้ว');
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
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
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
                  _buildNotificationPreferences(),
                  const SizedBox(height: 14),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
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
                    const Text(
                      'AIoT Smart Lab • โรงเรียนตัวอย่าง',
                      style: TextStyle(
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
                onPressed: _saveProfile,
                icon: const Icon(Icons.save_rounded),
                label: const Text('บันทึก'),
              ),
            ],
          );

          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                profile,
                const SizedBox(height: 16),
                actions,
              ],
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
    );
  }

  Widget _buildAccountSummary() {
    const List<_ProfileSummary> items = [
      _ProfileSummary(
        title: 'สถานะบัญชี',
        value: 'ใช้งาน',
        detail: 'บัญชีพร้อมใช้งานตามปกติ',
        icon: Icons.verified_user_rounded,
        color: SchoolAdminPalette.green,
      ),
      _ProfileSummary(
        title: 'เข้าใช้ล่าสุด',
        value: '09:20 น.',
        detail: 'วันนี้ • Chrome',
        icon: Icons.schedule_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _ProfileSummary(
        title: 'สิทธิ์',
        value: 'ผู้ดูแล',
        detail: 'ดูแลข้อมูลภายในโรงเรียน',
        icon: Icons.admin_panel_settings_rounded,
        color: Color(0xFF4F6078),
      ),
      _ProfileSummary(
        title: 'ความปลอดภัย',
        value: 'ปกติ',
        detail: 'ไม่พบการเข้าสู่ระบบผิดปกติ',
        icon: Icons.security_rounded,
        color: SchoolAdminPalette.secondary,
      ),
    ];

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
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
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
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
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
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
                child: const _ReadOnlyProfileField(
                  icon: Icons.school_rounded,
                  label: 'โรงเรียน',
                  value: 'โรงเรียนตัวอย่าง AIoT Smart Lab',
                ),
              ),
              SizedBox(
                width: width,
                child: const _ReadOnlyProfileField(
                  icon: Icons.calendar_month_rounded,
                  label: 'สร้างบัญชีเมื่อ',
                  value: '18 มิถุนายน 2569',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationPreferences() {
    return _ProfileSection(
      title: 'การแจ้งเตือนของฉัน',
      subtitle: 'เลือกช่องทางและประเภทการแจ้งเตือนที่ต้องการรับ',
      child: Column(
        children: [
          _ProfileSwitchRow(
            icon: Icons.notifications_rounded,
            title: 'แจ้งเตือนในระบบ',
            detail: 'แสดงการแจ้งเตือนสำคัญในหน้าแอดมิน',
            value: _systemNotification,
            onChanged: (bool value) {
              setState(() => _systemNotification = value);
            },
          ),
          const SizedBox(height: 9),
          _ProfileSwitchRow(
            icon: Icons.email_rounded,
            title: 'แจ้งเตือนทางอีเมล',
            detail: 'ส่งเรื่องสำคัญและรายการเร่งด่วนทางอีเมล',
            value: _emailNotification,
            onChanged: (bool value) {
              setState(() => _emailNotification = value);
            },
          ),
          const SizedBox(height: 9),
          _ProfileSwitchRow(
            icon: Icons.security_rounded,
            title: 'แจ้งเตือนด้านความปลอดภัย',
            detail:
                'รับแจ้งเมื่อมีการเข้าสู่ระบบผิดปกติหรือใส่รหัสผิดหลายครั้ง',
            value: _securityNotification,
            onChanged: (bool value) {
              setState(() => _securityNotification = value);
            },
          ),
        ],
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
          _ProfileActionRow(
            icon: Icons.devices_rounded,
            title: 'อุปกรณ์ที่เข้าสู่ระบบ',
            detail: 'Chrome บน Windows • ใช้งานล่าสุดวันนี้ 09:20 น.',
            buttonText: 'ดูอุปกรณ์',
            onPressed: () {
              _message('เปิดรายการอุปกรณ์ที่เข้าสู่ระบบ');
            },
          ),
          const SizedBox(height: 9),
          _ProfileActionRow(
            icon: Icons.logout_rounded,
            title: 'ออกจากระบบอุปกรณ์อื่น',
            detail: 'ให้อุปกรณ์อื่นทั้งหมดต้องเข้าสู่ระบบใหม่',
            buttonText: 'ออกจากระบบ',
            danger: true,
            onPressed: () async {
              final bool confirmed = await _confirm(
                title: 'ยืนยันออกจากระบบอุปกรณ์อื่น',
                message:
                    'อุปกรณ์อื่นทั้งหมดของบัญชีนี้จะต้องเข้าสู่ระบบใหม่ ต้องการดำเนินการต่อหรือไม่',
              );

              if (confirmed && mounted) {
                _message('ออกจากระบบอุปกรณ์อื่นแล้ว');
              }
            },
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
              child: const Text(
                'ยังไม่มีประวัติกิจกรรมล่าสุด',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SchoolAdminPalette.textSecondary,
                ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
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
      constraints: const BoxConstraints(
        minHeight: 58,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: SchoolAdminPalette.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: SchoolAdminPalette.primaryDark,
          ),
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

class _ProfileSwitchRow extends StatelessWidget {
  const _ProfileSwitchRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          _ProfileIconBox(
            icon: icon,
            color: value
                ? SchoolAdminPalette.primaryDark
                : SchoolAdminPalette.textMuted,
          ),
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
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
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
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color color =
        danger ? SchoolAdminPalette.red : SchoolAdminPalette.primaryDark;

    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
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
                            ? OutlinedButton.styleFrom(
                                foregroundColor: color,
                              )
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
                          ? OutlinedButton.styleFrom(
                              foregroundColor: color,
                            )
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
    final Color color = log.type == 'success'
        ? SchoolAdminPalette.green
        : SchoolAdminPalette.primaryDark;

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
          _ProfileIconBox(
            icon: Icons.history_rounded,
            color: color,
          ),
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
  const _ProfileBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
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
  const _ProfileIconBox({
    required this.icon,
    required this.color,
  });

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
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
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
