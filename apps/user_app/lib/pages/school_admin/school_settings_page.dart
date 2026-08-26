import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../theme/school_admin_palette.dart';

class SchoolSettingsPage extends StatefulWidget {
  const SchoolSettingsPage({super.key});

  @override
  State<SchoolSettingsPage> createState() => _SchoolSettingsPageState();
}

class _SchoolSettingsPageState extends State<SchoolSettingsPage> {
  final TextEditingController _schoolNameController = TextEditingController(
    text: 'โรงเรียนตัวอย่าง AIoT Smart Lab',
  );
  final TextEditingController _schoolCodeController = TextEditingController(
    text: 'SCH-0001',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'admin@school.ac.th',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '02-000-0000',
  );
  final TextEditingController _addressController = TextEditingController(
    text: '99 ถนนตัวอย่าง แขวงตัวอย่าง เขตตัวอย่าง กรุงเทพมหานคร 10000',
  );
  final TextEditingController _directorController = TextEditingController(
    text: 'นางสาวสุภาวดี ใจดี',
  );

  String _academicYear = '2569';
  String _semester = 'ภาคเรียนที่ 1';
  String _language = 'ภาษาไทย';
  String _timeZone = 'ประเทศไทย (UTC+7)';
  String _dateFormat = 'วัน/เดือน/ปี';
  String _defaultLandingPage = 'หน้าหลัก';

  bool _emailNotifications = true;
  bool _systemNotifications = true;
  bool _urgentOnlyAfterHours = true;
  bool _deviceOfflineAlert = true;
  bool _resourceAlert = true;
  bool _airQualityAlert = true;
  bool _loginFailureAlert = true;
  bool _attendanceForwarding = true;

  bool _requireStrongPassword = true;
  bool _requireReviewerName = true;
  bool _autoLogout = true;
  bool _twoStepForAdmins = false;
  bool _allowExport = true;
  bool _allowBulkImport = true;

  int _autoLogoutMinutes = 30;
  int _offlineThresholdMinutes = 15;
  int _loginFailureThreshold = 3;

  List<_SettingsLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final summary = await SchoolAdminPlatformService()
          .fetchDashboardSummary();
      final logs = await SchoolAdminPlatformService().fetchAuditLogs(limit: 5);
      if (!mounted) return;
      if (summary.schoolName.isNotEmpty) {
        setState(() {
          _schoolNameController.text = summary.schoolName;
          if (summary.schoolCode.isNotEmpty) {
            _schoolCodeController.text = summary.schoolCode;
          }
        });
      }
      setState(() {
        _logs = logs
            .map(
              (l) => _SettingsLog(
                time:
                    '${l.createdAt.hour.toString().padLeft(2, '0')}:${l.createdAt.minute.toString().padLeft(2, '0')} น.',
                action: l.action,
                detail: l.detail.isNotEmpty ? l.detail : l.target,
                by: l.actorName,
                type: 'success',
              ),
            )
            .toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolCodeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _directorController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmAction({
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

  Future<void> _saveSchoolInfo() async {
    if (_schoolNameController.text.trim().isEmpty ||
        _schoolCodeController.text.trim().isEmpty) {
      _showMessage('กรุณากรอกชื่อโรงเรียนและรหัสโรงเรียน');
      return;
    }

    final bool confirmed = await _confirmAction(
      title: 'ยืนยันการบันทึกข้อมูลโรงเรียน',
      message:
          'ต้องการบันทึกข้อมูลโรงเรียนที่แก้ไขแล้วหรือไม่\n(หมายเหตุ: ระบบการตั้งค่าโรงเรียนยังไม่เชื่อมต่อระบบหลังบ้าน ข้อมูลจะไม่ถูกบันทึกจริง)',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _logs.insert(
        0,
        const _SettingsLog(
          time: 'เมื่อสักครู่',
          action: 'แก้ไขข้อมูลโรงเรียน (จำลอง)',
          detail: 'บันทึกข้อมูลโรงเรียนและข้อมูลติดต่อในเครื่อง',
          by: 'ผู้ดูแลโรงเรียน',
          type: 'success',
        ),
      );
    });

    _showMessage('บันทึกข้อมูลโรงเรียนแล้ว (ระบบยังไม่เชื่อมต่อระบบหลังบ้าน)');
  }

  Future<void> _saveSystemSettings() async {
    final bool confirmed = await _confirmAction(
      title: 'ยืนยันการบันทึกการตั้งค่า',
      message:
          'ต้องการบันทึกการตั้งค่าระบบ การแจ้งเตือน และความปลอดภัยล่าสุดหรือไม่\n(หมายเหตุ: ระบบการตั้งค่ายังไม่เชื่อมต่อระบบหลังบ้าน ข้อมูลจะไม่ถูกบันทึกจริง)',
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _logs.insert(
        0,
        const _SettingsLog(
          time: 'เมื่อสักครู่',
          action: 'บันทึกการตั้งค่า (จำลอง)',
          detail: 'อัปเดตการตั้งค่าระบบ การแจ้งเตือน และความปลอดภัยในเครื่อง',
          by: 'ผู้ดูแลโรงเรียน',
          type: 'success',
        ),
      );
    });

    _showMessage('บันทึกการตั้งค่าแล้ว (ระบบยังไม่เชื่อมต่อระบบหลังบ้าน)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 115),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  _buildSettingsDisclosureBanner(),
                  const SizedBox(height: 14),
                  _buildSummary(),
                  const SizedBox(height: 14),
                  _buildSchoolInfo(),
                  const SizedBox(height: 14),
                  _buildAcademicSettings(),
                  const SizedBox(height: 14),
                  _buildNotificationSettings(),
                  const SizedBox(height: 14),
                  _buildSecuritySettings(),
                  const SizedBox(height: 14),
                  _buildDataSettings(),
                  const SizedBox(height: 14),
                  _buildPackageInfo(),
                  const SizedBox(height: 14),
                  _buildDangerZone(),
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

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget title = const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: SchoolAdminPalette.primarySoft,
                    child: Icon(
                      Icons.settings_rounded,
                      color: SchoolAdminPalette.primaryDark,
                    ),
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ตั้งค่าโรงเรียน',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'จัดการข้อมูลโรงเรียน ปีการศึกษา การแจ้งเตือน '
                          'ความปลอดภัย การนำเข้าข้อมูล และการใช้งานระบบ',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: SchoolAdminPalette.textSecondary,
                          ),
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
                    onPressed: () {
                      _showMessage('เรียกคืนค่าล่าสุดที่บันทึกไว้แล้ว');
                    },
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('เรียกคืนค่าล่าสุด'),
                  ),
                  FilledButton.icon(
                    onPressed: _saveSystemSettings,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('บันทึกทั้งหมด'),
                  ),
                ],
              );

              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 14), actions],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
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

  Widget _buildSummary() {
    const List<_SettingsSummaryData> items = [
      _SettingsSummaryData(
        title: 'ข้อมูลโรงเรียน',
        value: 'ครบถ้วน',
        detail: 'ชื่อ รหัส และข้อมูลติดต่อพร้อมใช้งาน',
        icon: Icons.apartment_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _SettingsSummaryData(
        title: 'แจ้งเตือนอัตโนมัติ',
        value: '8 รายการ',
        detail: 'เปิดใช้งานตามเงื่อนไขที่กำหนด',
        icon: Icons.notifications_active_rounded,
        color: SchoolAdminPalette.secondary,
      ),
      _SettingsSummaryData(
        title: 'ความปลอดภัย',
        value: 'พร้อมใช้',
        detail: 'รหัสผ่านและออกจากระบบอัตโนมัติ',
        icon: Icons.security_rounded,
        color: SchoolAdminPalette.green,
      ),
      _SettingsSummaryData(
        title: 'วันแพ็กเกจคงเหลือ',
        value: '238 วัน',
        detail: 'หมดอายุ 5 เม.ย. 2570',
        icon: Icons.event_available_rounded,
        color: Color(0xFF4F6078),
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1050) {
          columns = 2;
        }
        if (constraints.maxWidth < 300) {
          columns = 1;
        }

        const double spacing = 12;
        final double width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((_SettingsSummaryData item) {
            return SizedBox(
              width: width,
              child: _SettingsSummaryCard(data: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSchoolInfo() {
    return _SettingsSectionCard(
      title: 'ข้อมูลโรงเรียน',
      subtitle: 'ข้อมูลหลักที่ใช้แสดงในระบบ รายงาน และเอกสารของโรงเรียน',
      trailing: FilledButton.icon(
        onPressed: _saveSchoolInfo,
        icon: const Icon(Icons.save_rounded, size: 17),
        label: const Text('บันทึกข้อมูล'),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool oneColumn = constraints.maxWidth < 760;
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
                  controller: _schoolNameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อโรงเรียน',
                    prefixIcon: Icon(Icons.school_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: TextField(
                  controller: _schoolCodeController,
                  decoration: const InputDecoration(
                    labelText: 'รหัสโรงเรียน',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: TextField(
                  controller: _directorController,
                  decoration: const InputDecoration(
                    labelText: 'ผู้อำนวยการโรงเรียน',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'อีเมลโรงเรียน',
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
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SchoolAdminPalette.border),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: SchoolAdminPalette.primarySoft,
                        child: Icon(
                          Icons.image_rounded,
                          color: SchoolAdminPalette.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'โลโก้โรงเรียน',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                color: SchoolAdminPalette.textPrimary,
                              ),
                            ),
                            Text(
                              'ใช้ในรายงานและหน้าระบบ',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: SchoolAdminPalette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          _showMessage('เลือกไฟล์โลโก้ตัวอย่างแล้ว');
                        },
                        child: const Text('เปลี่ยน'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: constraints.maxWidth,
                child: TextField(
                  controller: _addressController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ที่อยู่โรงเรียน',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAcademicSettings() {
    return _SettingsSectionCard(
      title: 'ปีการศึกษาและรูปแบบระบบ',
      subtitle: 'กำหนดค่าพื้นฐานที่ใช้กับข้อมูลและหน้าจอของโรงเรียน',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          int columns = 3;
          if (constraints.maxWidth < 950) {
            columns = 2;
          }
          if (constraints.maxWidth < 620) {
            columns = 1;
          }

          const double spacing = 10;
          final double width =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              SizedBox(
                width: width,
                child: _SettingsDropdown(
                  label: 'ปีการศึกษา',
                  icon: Icons.calendar_month_rounded,
                  value: _academicYear,
                  items: const ['2569', '2570', '2571'],
                  onChanged: (String value) {
                    setState(() => _academicYear = value);
                  },
                ),
              ),
              SizedBox(
                width: width,
                child: _SettingsDropdown(
                  label: 'ภาคเรียน',
                  icon: Icons.menu_book_rounded,
                  value: _semester,
                  items: const ['ภาคเรียนที่ 1', 'ภาคเรียนที่ 2', 'ภาคฤดูร้อน'],
                  onChanged: (String value) {
                    setState(() => _semester = value);
                  },
                ),
              ),
              SizedBox(
                width: width,
                child: _SettingsDropdown(
                  label: 'ภาษา',
                  icon: Icons.language_rounded,
                  value: _language,
                  items: const ['ภาษาไทย', 'English'],
                  onChanged: (String value) {
                    setState(() => _language = value);
                  },
                ),
              ),
              SizedBox(
                width: width,
                child: _SettingsDropdown(
                  label: 'เขตเวลา',
                  icon: Icons.schedule_rounded,
                  value: _timeZone,
                  items: const ['ประเทศไทย (UTC+7)', 'UTC'],
                  onChanged: (String value) {
                    setState(() => _timeZone = value);
                  },
                ),
              ),
              SizedBox(
                width: width,
                child: _SettingsDropdown(
                  label: 'รูปแบบวันที่',
                  icon: Icons.date_range_rounded,
                  value: _dateFormat,
                  items: const ['วัน/เดือน/ปี', 'ปี-เดือน-วัน'],
                  onChanged: (String value) {
                    setState(() => _dateFormat = value);
                  },
                ),
              ),
              SizedBox(
                width: width,
                child: _SettingsDropdown(
                  label: 'หน้าแรกหลังเข้าสู่ระบบ',
                  icon: Icons.home_rounded,
                  value: _defaultLandingPage,
                  items: const [
                    'หน้าหลัก',
                    'การแจ้งเตือน',
                    'รายงาน',
                    'การใช้ทรัพยากร',
                  ],
                  onChanged: (String value) {
                    setState(() => _defaultLandingPage = value);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _SettingsSectionCard(
      title: 'การแจ้งเตือน',
      subtitle: 'กำหนดเรื่องที่ระบบต้องแจ้งและช่องทางที่ใช้ส่งให้ผู้รับผิดชอบ',
      child: Column(
        children: [
          _SettingsSwitchRow(
            icon: Icons.notifications_rounded,
            title: 'แจ้งเตือนในระบบ',
            detail: 'แสดงการแจ้งเตือนในหน้าแอดมินและหน้าผู้รับผิดชอบ',
            value: _systemNotifications,
            onChanged: (bool value) {
              setState(() => _systemNotifications = value);
            },
          ),
          const SizedBox(height: 9),
          _SettingsSwitchRow(
            icon: Icons.email_rounded,
            title: 'แจ้งเตือนทางอีเมล',
            detail: 'ส่งอีเมลเมื่อมีเหตุสำคัญหรือรายการเร่งด่วน',
            value: _emailNotifications,
            onChanged: (bool value) {
              setState(() => _emailNotifications = value);
            },
          ),
          const SizedBox(height: 9),
          _SettingsSwitchRow(
            icon: Icons.wifi_off_rounded,
            title: 'อุปกรณ์ออฟไลน์',
            detail: 'แจ้งครูประจำอาคารและแอดมินเมื่ออุปกรณ์ไม่ส่งข้อมูล',
            value: _deviceOfflineAlert,
            onChanged: (bool value) {
              setState(() => _deviceOfflineAlert = value);
            },
            trailing: _NumberSetting(
              value: _offlineThresholdMinutes,
              suffix: 'นาที',
              onMinus: () {
                if (_offlineThresholdMinutes > 5) {
                  setState(() => _offlineThresholdMinutes -= 5);
                }
              },
              onPlus: () {
                setState(() => _offlineThresholdMinutes += 5);
              },
            ),
          ),
          const SizedBox(height: 9),
          _SettingsSwitchRow(
            icon: Icons.energy_savings_leaf_rounded,
            title: 'ไฟฟ้าและน้ำผิดปกติ',
            detail: 'แจ้งเมื่อการใช้งานสูงกว่าค่าที่ระบบกำหนด',
            value: _resourceAlert,
            onChanged: (bool value) {
              setState(() => _resourceAlert = value);
            },
          ),
          const SizedBox(height: 9),
          _SettingsSwitchRow(
            icon: Icons.air_rounded,
            title: 'คุณภาพอากาศผิดปกติ',
            detail: 'แจ้งเมื่อ PM2.5 หรือคุณภาพอากาศเกินค่าที่กำหนด',
            value: _airQualityAlert,
            onChanged: (bool value) {
              setState(() => _airQualityAlert = value);
            },
          ),
          const SizedBox(height: 9),
          _SettingsSwitchRow(
            icon: Icons.security_rounded,
            title: 'เข้าสู่ระบบผิดหลายครั้ง',
            detail: 'แจ้งแอดมินเมื่อบัญชีใส่รหัสผ่านผิดเกินจำนวนที่กำหนด',
            value: _loginFailureAlert,
            onChanged: (bool value) {
              setState(() => _loginFailureAlert = value);
            },
            trailing: _NumberSetting(
              value: _loginFailureThreshold,
              suffix: 'ครั้ง',
              onMinus: () {
                if (_loginFailureThreshold > 1) {
                  setState(() => _loginFailureThreshold--);
                }
              },
              onPlus: () {
                setState(() => _loginFailureThreshold++);
              },
            ),
          ),
          const SizedBox(height: 9),
          _SettingsSwitchRow(
            icon: Icons.co_present_rounded,
            title: 'ส่งข้อมูลนักเรียนไม่มาเรียนให้ครูประจำชั้น',
            detail:
                'ระบบส่งต่อรายการให้อัตโนมัติโดยไม่ต้องให้แอดมินติดตามทุกวัน',
            value: _attendanceForwarding,
            onChanged: (bool value) {
              setState(() => _attendanceForwarding = value);
            },
          ),
          const SizedBox(height: 9),
          _SettingsSwitchRow(
            icon: Icons.nights_stay_rounded,
            title: 'นอกเวลาทำการแจ้งเฉพาะเรื่องสำคัญ',
            detail: 'ลดการแจ้งเตือนทั่วไปในช่วงกลางคืน',
            value: _urgentOnlyAfterHours,
            onChanged: (bool value) {
              setState(() => _urgentOnlyAfterHours = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return _SettingsSectionCard(
      title: 'ความปลอดภัย',
      subtitle: 'ตั้งค่าการเข้าสู่ระบบและการยืนยันการดำเนินการสำคัญ',
      child: Column(
        children: [
          _SettingsSwitchRow(
            icon: Icons.password_rounded,
            title: 'บังคับใช้รหัสผ่านที่คาดเดายาก',
            detail: 'กำหนดให้บัญชีใหม่ใช้รหัสผ่านที่มีความปลอดภัยเพียงพอ',
            value: _requireStrongPassword,
            onChanged: (bool value) {
              setState(() => _requireStrongPassword = value);
            },
          ),
          const SizedBox(height: 9),
          _SettingsSwitchRow(
            icon: Icons.draw_rounded,
            title: 'ต้องลงชื่อผู้ตรวจสอบก่อนยืนยัน',
            detail:
                'ใช้กับการรับทราบ ตรวจสอบ และยืนยันว่าแก้ไขการแจ้งเตือนแล้ว',
            value: _requireReviewerName,
            onChanged: (bool value) {
              setState(() => _requireReviewerName = value);
            },
          ),
          const SizedBox(height: 9),
          _SettingsSwitchRow(
            icon: Icons.logout_rounded,
            title: 'ออกจากระบบอัตโนมัติเมื่อไม่มีการใช้งาน',
            detail: 'ช่วยลดความเสี่ยงจากการเปิดหน้าระบบทิ้งไว้',
            value: _autoLogout,
            onChanged: (bool value) {
              setState(() => _autoLogout = value);
            },
            trailing: _NumberSetting(
              value: _autoLogoutMinutes,
              suffix: 'นาที',
              onMinus: () {
                if (_autoLogoutMinutes > 10) {
                  setState(() => _autoLogoutMinutes -= 10);
                }
              },
              onPlus: () {
                setState(() => _autoLogoutMinutes += 10);
              },
            ),
          ),
          const SizedBox(height: 9),
          _SettingsSwitchRow(
            icon: Icons.phonelink_lock_rounded,
            title: 'ยืนยันสองขั้นตอนสำหรับผู้ดูแล',
            detail: 'เตรียมสำหรับเพิ่มการยืนยันตัวตนอีกหนึ่งขั้นตอน',
            value: _twoStepForAdmins,
            onChanged: (bool value) {
              setState(() => _twoStepForAdmins = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataSettings() {
    return _SettingsSectionCard(
      title: 'ข้อมูลและการนำเข้า',
      subtitle: 'ควบคุมการนำเข้า ส่งออก และสำรองข้อมูลของโรงเรียน',
      child: Column(
        children: [
          _SettingsSwitchRow(
            icon: Icons.upload_file_rounded,
            title: 'อนุญาตนำเข้าข้อมูลจำนวนมาก',
            detail: 'ใช้กับนักเรียน ครู อาคาร ห้อง อุปกรณ์ และชุดฝึก',
            value: _allowBulkImport,
            onChanged: (bool value) {
              setState(() => _allowBulkImport = value);
            },
          ),
          const SizedBox(height: 9),
          _SettingsSwitchRow(
            icon: Icons.download_rounded,
            title: 'อนุญาตส่งออกรายงาน',
            detail: 'ให้ผู้มีสิทธิ์สามารถสร้าง PDF หรือ Excel ได้',
            value: _allowExport,
            onChanged: (bool value) {
              setState(() => _allowExport = value);
            },
          ),
          const SizedBox(height: 9),
          _SettingsActionRow(
            icon: Icons.backup_rounded,
            title: 'สำรองข้อมูล',
            detail: 'สร้างข้อมูลสำรองของโรงเรียนแบบจำลอง',
            buttonText: 'สำรองข้อมูล',
            onPressed: () {
              _showMessage('สร้างข้อมูลสำรองตัวอย่างแล้ว');
            },
          ),
          const SizedBox(height: 9),
          _SettingsActionRow(
            icon: Icons.history_rounded,
            title: 'ประวัติการนำเข้า',
            detail: 'เปิดดูไฟล์ที่เคยนำเข้าและผลการตรวจสอบ',
            buttonText: 'ดูประวัติ',
            onPressed: () {
              _showMessage('เปิดประวัติการนำเข้าข้อมูล');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPackageInfo() {
    return const _SettingsSectionCard(
      title: 'แพ็กเกจและการใช้งาน',
      subtitle: 'ดูสถานะสิทธิ์การใช้งานของโรงเรียน',
      child: Column(
        children: [
          _PackageRow(label: 'แพ็กเกจ', value: 'AIoT Smart Lab School'),
          SizedBox(height: 8),
          _PackageRow(label: 'สถานะ', value: 'ใช้งานปกติ'),
          SizedBox(height: 8),
          _PackageRow(label: 'วันแพ็กเกจคงเหลือ', value: '238 วัน'),
          SizedBox(height: 8),
          _PackageRow(label: 'วันหมดอายุ', value: '5 เมษายน 2570'),
          SizedBox(height: 8),
          _PackageRow(label: 'จำนวนผู้ใช้งาน', value: '96 / 300 บัญชี'),
          SizedBox(height: 8),
          _PackageRow(label: 'จำนวนอุปกรณ์', value: '152 / 500 รายการ'),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return _SettingsSectionCard(
      title: 'การตั้งค่าที่ต้องระวัง',
      subtitle: 'รายการต่อไปนี้มีผลต่อการใช้งานของผู้ใช้ทั้งโรงเรียน',
      child: Column(
        children: [
          _DangerActionRow(
            icon: Icons.lock_reset_rounded,
            title: 'บังคับออกจากระบบทุกบัญชี',
            detail: 'ผู้ใช้งานทุกคนต้องเข้าสู่ระบบใหม่',
            buttonText: 'ออกจากระบบทั้งหมด',
            onPressed: () async {
              final bool confirmed = await _confirmAction(
                title: 'ยืนยันออกจากระบบทั้งหมด',
                message:
                    'ผู้ใช้งานทุกบัญชีในโรงเรียนจะต้องเข้าสู่ระบบใหม่ ต้องการดำเนินการต่อหรือไม่',
              );
              if (confirmed && mounted) {
                _showMessage('ส่งคำสั่งออกจากระบบทุกบัญชีแล้ว');
              }
            },
          ),
          const SizedBox(height: 9),
          _DangerActionRow(
            icon: Icons.restart_alt_rounded,
            title: 'คืนค่าการตั้งค่าระบบ',
            detail: 'คืนค่าการแจ้งเตือนและความปลอดภัยเป็นค่ามาตรฐานของโรงเรียน',
            buttonText: 'คืนค่า',
            onPressed: () async {
              final bool confirmed = await _confirmAction(
                title: 'ยืนยันคืนค่าการตั้งค่า',
                message: 'ต้องการคืนค่าการตั้งค่าระบบเป็นค่ามาตรฐานหรือไม่',
              );

              if (!confirmed || !mounted) return;

              setState(() {
                _emailNotifications = true;
                _systemNotifications = true;
                _urgentOnlyAfterHours = true;
                _deviceOfflineAlert = true;
                _resourceAlert = true;
                _airQualityAlert = true;
                _loginFailureAlert = true;
                _attendanceForwarding = true;
                _requireStrongPassword = true;
                _requireReviewerName = true;
                _autoLogout = true;
                _twoStepForAdmins = false;
                _allowExport = true;
                _allowBulkImport = true;
                _autoLogoutMinutes = 30;
                _offlineThresholdMinutes = 15;
                _loginFailureThreshold = 3;
              });

              _showMessage('คืนค่าการตั้งค่ามาตรฐานแล้ว');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsDisclosureBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDCA)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFD92D20), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'หมายเหตุ: ระบบการตั้งค่าโรงเรียน การแจ้งเตือน และความปลอดภัยยังไม่เชื่อมต่อระบบหลังบ้าน การแก้ไขจะไม่ถูกบันทึกจริงลงฐานข้อมูล',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFFB42318),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogs() {
    return _SettingsSectionCard(
      title: 'Log การเปลี่ยนการตั้งค่า',
      subtitle: 'บันทึกว่าใครแก้ไขการตั้งค่าอะไร และเมื่อไร',
      child: _logs.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              alignment: Alignment.center,
              child: const Text(
                'ยังไม่มีประวัติการแก้ไขการตั้งค่า',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            )
          : Column(
              children: _logs.take(6).map((_SettingsLog log) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _SettingsLogRow(log: log),
                );
              }).toList(),
            ),
    );
  }
}

class _SettingsSummaryCard extends StatelessWidget {
  const _SettingsSummaryCard({required this.data});

  final _SettingsSummaryData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 240;

        return Container(
          constraints: BoxConstraints(minHeight: compact ? 148 : 130),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingsIconBox(icon: data.icon, color: data.color),
                    const SizedBox(height: 10),
                    Text(
                      data.value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 12,
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
                        fontSize: 12.5,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _SettingsIconBox(icon: data.icon, color: data.color),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.value,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            data.title,
                            style: const TextStyle(
                              fontSize: 12.5,
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
                              fontSize: 12.5,
                              color: SchoolAdminPalette.textSecondary,
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
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: SchoolAdminPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: SchoolAdminPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 10),
                    trailing!,
                  ],
                ],
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

class _SettingsDropdown extends StatelessWidget {
  const _SettingsDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (String? value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool mobile = constraints.maxWidth < 650;

        final Widget text = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingsIconBox(
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
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: SchoolAdminPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: mobile
              ? Column(
                  children: [
                    text,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (trailing != null)
                          Expanded(child: trailing!)
                        else
                          const Spacer(),
                        const SizedBox(width: 10),
                        Switch(value: value, onChanged: onChanged),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: text),
                    if (trailing != null) ...[
                      const SizedBox(width: 14),
                      trailing!,
                    ],
                    const SizedBox(width: 14),
                    Switch(value: value, onChanged: onChanged),
                  ],
                ),
        );
      },
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.buttonText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          _SettingsIconBox(icon: icon, color: SchoolAdminPalette.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(onPressed: onPressed, child: Text(buttonText)),
        ],
      ),
    );
  }
}

class _DangerActionRow extends StatelessWidget {
  const _DangerActionRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.buttonText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SchoolAdminPalette.red.withAlpha(80)),
      ),
      child: Row(
        children: [
          _SettingsIconBox(icon: icon, color: SchoolAdminPalette.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: SchoolAdminPalette.red,
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

class _NumberSetting extends StatelessWidget {
  const _NumberSetting({
    required this.value,
    required this.suffix,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final String suffix;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: SchoolAdminPalette.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onMinus,
            icon: const Icon(Icons.remove_rounded, size: 17),
          ),
          Text(
            '$value $suffix',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onPlus,
            icon: const Icon(Icons.add_rounded, size: 17),
          ),
        ],
      ),
    );
  }
}

class _PackageRow extends StatelessWidget {
  const _PackageRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsLogRow extends StatelessWidget {
  const _SettingsLogRow({required this.log});

  final _SettingsLog log;

  Color get color {
    return log.type == 'success'
        ? SchoolAdminPalette.green
        : SchoolAdminPalette.primaryDark;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool mobile = constraints.maxWidth < 760;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: SchoolAdminPalette.border),
          ),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.action,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.detail,
                      style: const TextStyle(
                        fontSize: 13,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${log.time} • โดย ${log.by}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _SettingsIconBox(icon: Icons.history_rounded, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        log.action,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: SchoolAdminPalette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Text(
                        log.detail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: SchoolAdminPalette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        log.time,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        log.by,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: SchoolAdminPalette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _SettingsIconBox extends StatelessWidget {
  const _SettingsIconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80), width: 1.1),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _SettingsSummaryData {
  const _SettingsSummaryData({
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

class _SettingsLog {
  const _SettingsLog({
    required this.time,
    required this.action,
    required this.detail,
    required this.by,
    required this.type,
  });

  final String time;
  final String action;
  final String detail;
  final String by;
  final String type;
}
