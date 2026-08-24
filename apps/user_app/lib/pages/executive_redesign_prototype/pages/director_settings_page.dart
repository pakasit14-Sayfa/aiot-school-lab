import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorSettingsPage extends StatefulWidget {
  const DirectorSettingsPage({super.key});

  @override
  State<DirectorSettingsPage> createState() =>
      _DirectorSettingsPageState();
}

class _DirectorSettingsPageState
    extends State<DirectorSettingsPage> {
  late final TextEditingController displayNameController;
  late final TextEditingController phoneController;

  bool emergencyNotification = true;
  bool studentNotification = true;
  bool personnelNotification = true;
  bool utilityNotification = true;
  bool environmentNotification = true;
  bool reportMeetingNotification = true;

  bool inAppNotification = true;
  bool emailNotification = true;
  bool loginNotification = true;
  bool twoFactorEnabled = false;

  bool dailyDigest = true;
  bool weeklyDigest = true;

  String urgentLevel = 'สูงและเร่งด่วน';
  String dailyDigestTime = '17:00';
  String weeklyDigestDay = 'ศุกร์';
  String weeklyDigestTime = '16:30';

  String defaultPage = 'ภาพรวม';
  String defaultPeriod = 'วันนี้';
  String dashboardDensity = 'ปกติ';

  String defaultReportFile = 'PDF';
  String reportRange = 'เดือนปัจจุบัน';

  bool hasChanges = false;

  @override
  void initState() {
    super.initState();

    displayNameController =
        TextEditingController(text: 'ผู้อำนวยการโรงเรียน');
    phoneController =
        TextEditingController(text: '08X-XXX-XXXX');

    displayNameController.addListener(_markChanged);
    phoneController.addListener(_markChanged);
  }

  @override
  void dispose() {
    displayNameController.removeListener(_markChanged);
    phoneController.removeListener(_markChanged);

    displayNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!hasChanges && mounted) {
      setState(() => hasChanges = true);
    }
  }

  void _setChanged(VoidCallback callback) {
    setState(() {
      callback();
      hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 14),
          _scopeInfoCard(),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 980) {
                return Column(
                  children: [
                    _profileCard(),
                    const SizedBox(height: 16),
                    _notificationCard(),
                  ],
                );
              }

              return SizedBox(
                height: 780,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _profileCard(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: _notificationCard(),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 980) {
                return Column(
                  children: [
                    _dashboardPreferenceCard(),
                    const SizedBox(height: 16),
                    _reportPreferenceCard(),
                  ],
                );
              }

              return SizedBox(
                height: 560,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _dashboardPreferenceCard(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _reportPreferenceCard(),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          _securityCard(),
          const SizedBox(height: 16),
          _saveArea(),
        ],
      ),
    );
  }

  Widget _header() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;

        final title = const DirectorSectionHeader(
          title: 'ตั้งค่า',
          subtitle:
              'ตั้งค่าเฉพาะสิ่งที่ผู้อำนวยการควรปรับเอง เช่น ข้อมูลส่วนตัว การแจ้งเตือน รูปแบบ Dashboard รายงาน และความปลอดภัยของบัญชี',
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 10),
              if (hasChanges)
                _unsavedTag(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            if (hasChanges) _unsavedTag(),
          ],
        );
      },
    );
  }

  Widget _unsavedTag() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppPalette.tint(
          AppPalette.warning,
          0.10,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'มีการเปลี่ยนแปลงที่ยังไม่บันทึก',
        style: TextStyle(
          fontSize: 8.8,
          fontWeight: FontWeight.w700,
          color: AppPalette.warning,
        ),
      ),
    );
  }

  Widget _scopeInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.tint(
          AppPalette.learningBlue,
          0.055,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppPalette.tint(
            AppPalette.learningBlue,
            0.14,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 19,
              color: AppPalette.learningBlue,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'หน้านี้เป็นการตั้งค่าส่วนตัวของผู้อำนวยการ',
                  style: TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'จะไม่มีเมนูเพิ่มผู้ใช้ กำหนดสิทธิ์ แก้ฐานข้อมูล ตั้งค่าอุปกรณ์ หรือเปลี่ยนโครงสร้างโรงเรียน เพราะควรเป็นหน้าที่ของผู้ดูแลระบบ',
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.4,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.person_outline_rounded,
            color: AppPalette.primaryPink,
            title: 'ข้อมูลบัญชีส่วนตัว',
            subtitle:
                'แก้เฉพาะข้อมูลที่ใช้แสดงและติดต่อผู้อำนวยการ',
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: AppPalette.primaryPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'บัญชีผู้อำนวยการ',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'สิทธิ์ Director',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _showMessage(
                    'ตัวอย่าง: เปิดหน้าต่างเปลี่ยนรูปโปรไฟล์',
                  );
                },
                icon: const Icon(
                  Icons.photo_camera_outlined,
                  size: 15,
                ),
                label: const Text(
                  'เปลี่ยนรูป',
                  style: TextStyle(fontSize: 9),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _textField(
            label: 'ชื่อที่แสดง',
            controller: displayNameController,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 10),
          _textField(
            label: 'เบอร์โทรศัพท์',
            controller: phoneController,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 10),

          _readOnlyField(
            label: 'อีเมล',
            value: 'director@school.ac.th',
            icon: Icons.email_outlined,
            helper: 'ใช้อีเมลบัญชีหลัก ไม่สามารถแก้จากหน้านี้',
          ),
          const SizedBox(height: 10),

          _readOnlyField(
            label: 'โรงเรียน',
            value: 'โรงเรียนตัวอย่าง',
            icon: Icons.school_outlined,
            helper: 'ข้อมูลโรงเรียนแก้โดยผู้ดูแลระบบ',
          ),
        ],
      ),
    );
  }

  Widget _notificationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.notifications_none_rounded,
            color: AppPalette.chartPink,
            title: 'การแจ้งเตือนที่ต้องการรับ',
            subtitle:
                'เลือกเฉพาะเรื่องที่ผู้อำนวยการต้องการเห็นบน Dashboard และ Notification',
          ),
          const SizedBox(height: 14),

          _toggleSetting(
            title: 'เหตุฉุกเฉิน',
            subtitle:
                'ทะเลาะวิวาท ล้ม หมดสติ ควัน หรือเหตุเสี่ยง',
            value: emergencyNotification,
            icon: Icons.warning_amber_rounded,
            color: AppPalette.danger,
            onChanged: (value) {
              _setChanged(
                () => emergencyNotification = value,
              );
            },
          ),
          _toggleSetting(
            title: 'นักเรียน',
            subtitle:
                'ขาดเรียนสูง งานค้าง ผลการเรียน และเคสที่ต้องดูแล',
            value: studentNotification,
            icon: Icons.groups_rounded,
            color: AppPalette.primaryPink,
            onChanged: (value) {
              _setChanged(
                () => studentNotification = value,
              );
            },
          ),
          _toggleSetting(
            title: 'ครูและบุคลากร',
            subtitle:
                'การลา มาสาย การสอน และรายการที่ควรติดตาม',
            value: personnelNotification,
            icon: Icons.co_present_rounded,
            color: AppPalette.learningBlue,
            onChanged: (value) {
              _setChanged(
                () => personnelNotification = value,
              );
            },
          ),
          _toggleSetting(
            title: 'น้ำ / ไฟ',
            subtitle:
                'ใช้สูงผิดปกติ แนวโน้มผิดปกติ และเหตุที่ควรตรวจสอบ',
            value: utilityNotification,
            icon: Icons.bolt_rounded,
            color: AppPalette.warning,
            onChanged: (value) {
              _setChanged(
                () => utilityNotification = value,
              );
            },
          ),
          _toggleSetting(
            title: 'สิ่งแวดล้อม',
            subtitle:
                'PM2.5 อุณหภูมิ CO₂ แสง ก๊าซ และควัน',
            value: environmentNotification,
            icon: Icons.eco_outlined,
            color: AppPalette.environmentGreen,
            onChanged: (value) {
              _setChanged(
                () => environmentNotification = value,
              );
            },
          ),
          _toggleSetting(
            title: 'รายงาน / ประชุม',
            subtitle:
                'รายงานรอตรวจ นัดหมาย คำขอพบ และประชุมสำคัญ',
            value: reportMeetingNotification,
            icon: Icons.event_note_rounded,
            color: AppPalette.chartCream,
            onChanged: (value) {
              _setChanged(
                () => reportMeetingNotification = value,
              );
            },
          ),

          const SizedBox(height: 12),
          const Divider(color: AppPalette.border),
          const SizedBox(height: 12),

          _settingDropdown(
            title: 'ระดับที่ต้องแจ้งทันที',
            subtitle:
                'รายการต่ำกว่าระดับนี้ยังดูได้ในหน้าแจ้งเตือน แต่ไม่เด้งรบกวน',
            value: urgentLevel,
            items: const [
              'เร่งด่วนเท่านั้น',
              'สูงและเร่งด่วน',
              'ทุกระดับ',
            ],
            icon: Icons.priority_high_rounded,
            onChanged: (value) {
              if (value == null) return;
              _setChanged(() => urgentLevel = value);
            },
          ),

          const SizedBox(height: 12),

          _channelSettings(),
        ],
      ),
    );
  }

  Widget _channelSettings() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ช่องทางแจ้งเตือน',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          _smallSwitchRow(
            title: 'แจ้งเตือนในระบบ',
            value: inAppNotification,
            onChanged: (value) {
              _setChanged(
                () => inAppNotification = value,
              );
            },
          ),
          _smallSwitchRow(
            title: 'ส่งสรุปเข้าอีเมล',
            value: emailNotification,
            onChanged: (value) {
              _setChanged(
                () => emailNotification = value,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dashboardPreferenceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.dashboard_outlined,
            color: AppPalette.learningBlue,
            title: 'รูปแบบ Dashboard ส่วนตัว',
            subtitle:
                'กำหนดหน้าที่เปิดก่อนและรูปแบบข้อมูลเริ่มต้น',
          ),
          const SizedBox(height: 14),

          _settingDropdown(
            title: 'หน้าเริ่มต้นหลังเข้าสู่ระบบ',
            subtitle:
                'เปิดหน้านี้อัตโนมัติหลังเข้าสู่ระบบ',
            value: defaultPage,
            items: const [
              'ภาพรวม',
              'ภาพรวมนักเรียน',
              'ห้องเรียนและรายวิชา',
              'รายงาน',
              'การแจ้งเตือน',
            ],
            icon: Icons.home_outlined,
            onChanged: (value) {
              if (value == null) return;
              _setChanged(() => defaultPage = value);
            },
          ),

          const SizedBox(height: 12),

          _settingDropdown(
            title: 'ช่วงข้อมูลเริ่มต้น',
            subtitle:
                'ใช้เป็นค่าเริ่มต้นของกราฟและข้อมูลภาพรวม',
            value: defaultPeriod,
            items: const [
              'วันนี้',
              'สัปดาห์นี้',
              'เดือนนี้',
              'ภาคเรียนนี้',
            ],
            icon: Icons.date_range_outlined,
            onChanged: (value) {
              if (value == null) return;
              _setChanged(() => defaultPeriod = value);
            },
          ),

          const SizedBox(height: 12),

          _settingDropdown(
            title: 'ความหนาแน่นของข้อมูล',
            subtitle:
                'กำหนดว่าการ์ดจะแสดงข้อมูลมากหรือน้อย',
            value: dashboardDensity,
            items: const [
              'กระชับ',
              'ปกติ',
              'ละเอียด',
            ],
            icon: Icons.view_agenda_outlined,
            onChanged: (value) {
              if (value == null) return;
              _setChanged(
                () => dashboardDensity = value,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _reportPreferenceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.description_outlined,
            color: AppPalette.environmentGreen,
            title: 'รายงานและสรุปสำหรับผู้อำนวยการ',
            subtitle:
                'ตั้งค่ารูปแบบรายงานที่ใช้บ่อยและเวลารับสรุป',
          ),
          const SizedBox(height: 14),

          _settingDropdown(
            title: 'ไฟล์รายงานเริ่มต้น',
            subtitle:
                'ใช้เมื่อเปิดหรือส่งออกรายงานจากระบบ',
            value: defaultReportFile,
            items: const [
              'PDF',
              'Excel',
            ],
            icon: Icons.picture_as_pdf_outlined,
            onChanged: (value) {
              if (value == null) return;
              _setChanged(
                () => defaultReportFile = value,
              );
            },
          ),

          const SizedBox(height: 12),

          _settingDropdown(
            title: 'ช่วงข้อมูลรายงานเริ่มต้น',
            subtitle:
                'ใช้เป็นช่วงเวลาเริ่มต้นเมื่อเข้าหน้ารายงาน',
            value: reportRange,
            items: const [
              'วันนี้',
              'สัปดาห์ปัจจุบัน',
              'เดือนปัจจุบัน',
              'ภาคเรียนปัจจุบัน',
            ],
            icon: Icons.calendar_month_outlined,
            onChanged: (value) {
              if (value == null) return;
              _setChanged(() => reportRange = value);
            },
          ),

          const SizedBox(height: 13),
          const Divider(color: AppPalette.border),
          const SizedBox(height: 10),

          _digestSetting(
            title: 'สรุปรายวัน',
            subtitle:
                'รับสรุปเหตุสำคัญ นักเรียน น้ำ/ไฟ และรายการค้าง',
            enabled: dailyDigest,
            value: dailyDigestTime,
            items: const [
              '16:00',
              '17:00',
              '18:00',
            ],
            onToggle: (value) {
              _setChanged(() => dailyDigest = value);
            },
            onChanged: (value) {
              if (value == null) return;
              _setChanged(
                () => dailyDigestTime = value,
              );
            },
          ),

          const SizedBox(height: 10),

          _weeklyDigestSetting(),
        ],
      ),
    );
  }

  Widget _digestSetting({
    required String title,
    required String subtitle,
    required bool enabled,
    required String value,
    required List<String> items,
    required ValueChanged<bool> onToggle,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 8.4,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeColor:
                    AppPalette.primaryPink,
                onChanged: onToggle,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 7),
            _compactDropdown(
              value: value,
              items: items,
              icon: Icons.schedule_outlined,
              onChanged: onChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _weeklyDigestSetting() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สรุปรายสัปดาห์',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'สรุปแนวโน้มสำคัญก่อนจบสัปดาห์',
                      style: TextStyle(
                        fontSize: 8.4,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: weeklyDigest,
                activeColor:
                    AppPalette.primaryPink,
                onChanged: (value) {
                  _setChanged(
                    () => weeklyDigest = value,
                  );
                },
              ),
            ],
          ),
          if (weeklyDigest) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _compactDropdown(
                    value: weeklyDigestDay,
                    items: const [
                      'ศุกร์',
                      'เสาร์',
                      'อาทิตย์',
                    ],
                    icon:
                        Icons.calendar_today_outlined,
                    onChanged: (value) {
                      if (value == null) return;
                      _setChanged(
                        () => weeklyDigestDay = value,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _compactDropdown(
                    value: weeklyDigestTime,
                    items: const [
                      '15:30',
                      '16:30',
                      '17:30',
                    ],
                    icon: Icons.schedule_outlined,
                    onChanged: (value) {
                      if (value == null) return;
                      _setChanged(
                        () => weeklyDigestTime = value,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _securityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.security_outlined,
            color: AppPalette.warning,
            title: 'ความปลอดภัยของบัญชี',
            subtitle:
                'ผู้อำนวยการควรจัดการเฉพาะรหัสผ่าน การยืนยันตัวตน และการแจ้งเตือนการเข้าสู่ระบบของบัญชีตนเอง',
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 760) {
                return Column(
                  children: [
                    _securityActionTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'เปลี่ยนรหัสผ่าน',
                      subtitle:
                          'แนะนำให้เปลี่ยนเป็นระยะและไม่ใช้ร่วมกับบัญชีอื่น',
                      buttonText: 'เปลี่ยนรหัส',
                      onTap: _showPasswordDialog,
                    ),
                    const SizedBox(height: 10),
                    _securityToggleTile(
                      icon: Icons.verified_user_outlined,
                      title: 'ยืนยันตัวตน 2 ขั้นตอน',
                      subtitle:
                          'เพิ่มความปลอดภัยเมื่อลงชื่อเข้าใช้จากอุปกรณ์ใหม่',
                      value: twoFactorEnabled,
                      onChanged: (value) {
                        _setChanged(
                          () => twoFactorEnabled = value,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _securityToggleTile(
                      icon:
                          Icons.notifications_active_outlined,
                      title:
                          'แจ้งเตือนเมื่อมีการเข้าสู่ระบบ',
                      subtitle:
                          'แจ้งเตือนหากบัญชีถูกใช้จากอุปกรณ์หรือ Browser ใหม่',
                      value: loginNotification,
                      onChanged: (value) {
                        _setChanged(
                          () => loginNotification = value,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _securityActionTile(
                      icon: Icons.logout_rounded,
                      title: 'ออกจากระบบทุกอุปกรณ์',
                      subtitle:
                          'ใช้เมื่อสงสัยว่าบัญชีถูกเปิดอยู่บนอุปกรณ์อื่น',
                      buttonText: 'ออกจากทุกเครื่อง',
                      onTap: _showLogoutAllDialog,
                    ),
                  ],
                );
              }

              final securityItems = <Widget>[
                _securityActionTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'เปลี่ยนรหัสผ่าน',
                  subtitle:
                      'แนะนำให้เปลี่ยนเป็นระยะและไม่ใช้ร่วมกับบัญชีอื่น',
                  buttonText: 'เปลี่ยนรหัส',
                  onTap: _showPasswordDialog,
                ),
                _securityToggleTile(
                  icon: Icons.verified_user_outlined,
                  title: 'ยืนยันตัวตน 2 ขั้นตอน',
                  subtitle:
                      'เพิ่มความปลอดภัยเมื่อลงชื่อเข้าใช้จากอุปกรณ์ใหม่',
                  value: twoFactorEnabled,
                  onChanged: (value) {
                    _setChanged(
                      () => twoFactorEnabled = value,
                    );
                  },
                ),
                _securityToggleTile(
                  icon:
                      Icons.notifications_active_outlined,
                  title: 'แจ้งเตือนเมื่อมีการเข้าสู่ระบบ',
                  subtitle:
                      'แจ้งเตือนหากบัญชีถูกใช้จากอุปกรณ์หรือ Browser ใหม่',
                  value: loginNotification,
                  onChanged: (value) {
                    _setChanged(
                      () => loginNotification = value,
                    );
                  },
                ),
                _securityActionTile(
                  icon: Icons.logout_rounded,
                  title: 'ออกจากระบบทุกอุปกรณ์',
                  subtitle:
                      'ใช้เมื่อสงสัยว่าบัญชีถูกเปิดอยู่บนอุปกรณ์อื่น',
                  buttonText: 'ออกจากทุกเครื่อง',
                  onTap: _showLogoutAllDialog,
                ),
              ];

              return GridView.builder(
                itemCount: securityItems.length,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 148,
                ),
                itemBuilder: (context, index) {
                  return securityItems[index];
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppPalette.tint(color, 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 19,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.35,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 10.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 9.5),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: AppPalette.primaryPink,
        ),
        filled: true,
        fillColor: AppPalette.pageBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppPalette.border),
        ),
      ),
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required String helper,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppPalette.textMuted,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8.3,
                    color: AppPalette.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  helper,
                  style: const TextStyle(
                    fontSize: 7.8,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: AppPalette.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _toggleSetting({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.045),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 17,
              color: color,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 8.3,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor:
                AppPalette.primaryPink,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _smallSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 9.3,
              color: AppPalette.textMuted,
            ),
          ),
        ),
        Switch(
          value: value,
          activeColor:
              AppPalette.primaryPink,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _settingDropdown({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 8.4,
            color: AppPalette.textMuted,
          ),
        ),
        const SizedBox(height: 7),
        _compactDropdown(
          value: value,
          items: items,
          icon: icon,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _compactDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppPalette.primaryPink,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppPalette.textDark,
                ),
                items: items
                    .map(
                      (item) =>
                          DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppPalette.primaryPinkSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppPalette.primaryPinkDark,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.4,
                    height: 1.35,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onTap,
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppPalette.softBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppPalette.learningBlue,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.4,
                    height: 1.35,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor:
                AppPalette.primaryPink,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _saveArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasChanges
            ? AppPalette.tint(
                AppPalette.primaryPink,
                0.055,
              )
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasChanges
                    ? 'มีการเปลี่ยนแปลงที่ยังไม่บันทึก'
                    : 'การตั้งค่าปัจจุบันถูกบันทึกแล้ว',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'การเปลี่ยนแปลงมีผลเฉพาะบัญชีผู้อำนวยการ ไม่กระทบสิทธิ์หรือบัญชีผู้ใช้อื่น',
                style: TextStyle(
                  fontSize: 8.5,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          );

          final buttons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed:
                    hasChanges ? _resetSettings : null,
                child: const Text('ยกเลิกการแก้ไข'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      AppPalette.primaryPink,
                ),
                onPressed:
                    hasChanges ? _saveSettings : null,
                icon: const Icon(
                  Icons.save_outlined,
                  size: 16,
                ),
                label: const Text('บันทึกการตั้งค่า'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: buttons,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              buttons,
            ],
          );
        },
      ),
    );
  }

  void _saveSettings() {
    setState(() => hasChanges = false);
    _showMessage('บันทึกการตั้งค่าของผู้อำนวยการแล้ว');
  }

  void _resetSettings() {
    setState(() {
      displayNameController.text =
          'ผู้อำนวยการโรงเรียน';
      phoneController.text = '08X-XXX-XXXX';

      emergencyNotification = true;
      studentNotification = true;
      personnelNotification = true;
      utilityNotification = true;
      environmentNotification = true;
      reportMeetingNotification = true;

      inAppNotification = true;
      emailNotification = true;

      urgentLevel = 'สูงและเร่งด่วน';
      defaultPage = 'ภาพรวม';
      defaultPeriod = 'วันนี้';
      dashboardDensity = 'ปกติ';

      defaultReportFile = 'PDF';
      reportRange = 'เดือนปัจจุบัน';

      dailyDigest = true;
      dailyDigestTime = '17:00';

      weeklyDigest = true;
      weeklyDigestDay = 'ศุกร์';
      weeklyDigestTime = '16:30';

      twoFactorEnabled = false;
      loginNotification = true;

      hasChanges = false;
    });

    _showMessage('คืนค่าก่อนแก้ไขแล้ว');
  }

  void _showPasswordDialog() {
    final currentController =
        TextEditingController();
    final newController = TextEditingController();
    final confirmController =
        TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'เปลี่ยนรหัสผ่าน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _passwordField(
                  controller: currentController,
                  label: 'รหัสผ่านปัจจุบัน',
                ),
                const SizedBox(height: 10),
                _passwordField(
                  controller: newController,
                  label: 'รหัสผ่านใหม่',
                ),
                const SizedBox(height: 10),
                _passwordField(
                  controller: confirmController,
                  label: 'ยืนยันรหัสผ่านใหม่',
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'แนะนำอย่างน้อย 8 ตัวอักษร และควรมีตัวเลขหรือสัญลักษณ์ร่วมด้วย',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    AppPalette.primaryPink,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _showMessage(
                  'เปลี่ยนรหัสผ่านเรียบร้อยแล้ว',
                );
              },
              child: const Text('เปลี่ยนรหัสผ่าน'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
    });
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: AppPalette.primaryPink,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  void _showLogoutAllDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'ออกจากระบบทุกอุปกรณ์?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'บัญชีนี้จะถูกออกจากระบบในอุปกรณ์และ Browser อื่นทั้งหมด อุปกรณ์ที่กำลังใช้อยู่สามารถเข้าสู่ระบบใหม่ได้ภายหลัง',
            style: TextStyle(
              fontSize: 10,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.danger,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _showMessage(
                  'ออกจากระบบอุปกรณ์อื่นทั้งหมดแล้ว',
                );
              },
              child:
                  const Text('ออกจากทุกอุปกรณ์'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
