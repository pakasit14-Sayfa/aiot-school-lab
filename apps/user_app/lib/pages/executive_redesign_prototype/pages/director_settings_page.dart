import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../theme/app_palette.dart';
import '../widgets/director_common_widgets.dart';

class DirectorSettingsPage extends StatefulWidget {
  const DirectorSettingsPage({super.key});

  @override
  State<DirectorSettingsPage> createState() => _DirectorSettingsPageState();
}

class _DirectorSettingsPageState extends State<DirectorSettingsPage> {
  late final TextEditingController displayNameController;

  /// The name currently confirmed by the backend. `hasChanges` compares
  /// against this rather than a bool that was flipped by any keystroke and
  /// never reset by a real save.
  String _savedName = '';
  bool _saving = false;
  String? _saveError;

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

    // Was seeded with the literal 'ผู้อำนวยการโรงเรียน' and a placeholder
    // phone number, so the page showed the same fictional account to every
    // director who opened it.
    _savedName = currentUserModel?.name ?? '';
    displayNameController = TextEditingController(text: _savedName);
    displayNameController.addListener(_markChanged);
  }

  @override
  void dispose() {
    displayNameController.removeListener(_markChanged);
    displayNameController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!mounted) return;
    final changed = displayNameController.text.trim() != _savedName;
    if (changed != hasChanges) setState(() => hasChanges = changed);
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
                    Expanded(flex: 4, child: _profileCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: _notificationCard()),
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
                    Expanded(child: _dashboardPreferenceCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _reportPreferenceCard()),
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
              if (hasChanges) _unsavedTag(),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.tint(AppPalette.warning, 0.10),
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
        color: AppPalette.tint(AppPalette.learningBlue, 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppPalette.tint(AppPalette.learningBlue, 0.14),
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
                  style: TextStyle(fontSize: 10.8, fontWeight: FontWeight.w800),
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
            subtitle: 'แก้เฉพาะข้อมูลที่ใช้แสดงและติดต่อผู้อำนวยการ',
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
                  _showMessage('ตัวอย่าง: เปิดหน้าต่างเปลี่ยนรูปโปรไฟล์');
                },
                icon: const Icon(Icons.photo_camera_outlined, size: 15),
                label: const Text('เปลี่ยนรูป', style: TextStyle(fontSize: 9)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Name is the only profile field the backend can store:
          // `update_user_profile` takes first and last name, and `users` has
          // no phone or avatar column at all. The phone field and the
          // "เปลี่ยนรูป" button used to accept input that had nowhere to go.
          _textField(
            label: 'ชื่อที่แสดง',
            controller: displayNameController,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 10),

          _readOnlyField(
            label: 'อีเมล',
            value: currentUserModel?.email ?? 'ยังไม่มีข้อมูล',
            icon: Icons.email_outlined,
            helper: 'ใช้อีเมลบัญชีหลัก ไม่สามารถแก้จากหน้านี้',
          ),
          const SizedBox(height: 10),

          _readOnlyField(
            label: 'เบอร์โทรศัพท์',
            value: 'ยังไม่รองรับ',
            icon: Icons.phone_outlined,
            helper: 'ระบบยังไม่ได้เก็บเบอร์โทรศัพท์ของผู้ใช้',
          ),
        ],
      ),
    );
  }

  /// A card explaining that this group of settings has nowhere to be stored.
  ///
  /// The notification, dashboard, report and digest sections were fully
  /// interactive — toggles, dropdowns, times, a weekly digest day — and none
  /// of it persisted. There is no per-user preferences table anywhere in the
  /// schema; `school_settings` holds `email_notify`/`line_notify` but they are
  /// school-wide and school_admin-scoped. Reopening the page silently reset
  /// everything, so a director who switched off emergency notifications was
  /// told it was saved and kept receiving them.
  /// A security fact the user cannot change, stated instead of offered as a
  /// switch.
  Widget _securityStatusTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppPalette.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppPalette.tint(statusColor, 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unavailableSettingsCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String reason,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: icon,
            color: color,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
            decoration: BoxDecoration(
              color: AppPalette.pageBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.settings_suggest_outlined,
                  size: 28,
                  color: AppPalette.textMuted,
                ),
                const SizedBox(height: 8),
                const Text(
                  'ยังไม่เปิดใช้งาน',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.5,
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

  Widget _notificationCard() => _unavailableSettingsCard(
    icon: Icons.notifications_active_outlined,
    color: AppPalette.primaryPink,
    title: 'การแจ้งเตือน',
    subtitle: 'เลือกเรื่องที่ต้องการรับแจ้งเตือนและช่องทางที่ใช้',
    reason:
        'ระบบยังไม่มีที่เก็บการตั้งค่าการแจ้งเตือนรายบุคคล '
        'การแจ้งเตือนทั้งหมดจึงยังส่งตามค่าเริ่มต้นของระบบ',
  );

  Widget _dashboardPreferenceCard() => _unavailableSettingsCard(
    icon: Icons.dashboard_customize_outlined,
    color: AppPalette.learningBlue,
    title: 'การแสดงผลหน้าหลัก',
    subtitle: 'หน้าเริ่มต้น ช่วงข้อมูล และความหนาแน่นของการ์ด',
    reason:
        'ระบบยังไม่มีที่เก็บการตั้งค่าส่วนตัวของผู้ใช้ '
        'หน้าหลักจึงเปิดด้วยค่าเริ่มต้นเสมอ',
  );

  Widget _reportPreferenceCard() => _unavailableSettingsCard(
    icon: Icons.description_outlined,
    color: AppPalette.behaviorYellow,
    title: 'รายงานและสรุปประจำงวด',
    subtitle: 'รูปแบบไฟล์ ช่วงข้อมูล และสรุปรายวัน/รายสัปดาห์',
    reason: 'ระบบยังไม่มีตัวสร้างไฟล์รายงานและยังไม่มีตัวส่งอีเมลสรุปตามรอบ',
  );

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
                    // The 2FA switch rendered OFF and could be toggled, while
                    // `auth_sign_in` requires MFA for `executive` on every
                    // sign-in — it misrepresented the account as less
                    // protected than it is, and offered control it never had.
                    // The login-alert switch had no backend at all.
                    _securityStatusTile(
                      icon: Icons.verified_user_outlined,
                      title: 'ยืนยันตัวตน 2 ขั้นตอน',
                      subtitle:
                          'บังคับใช้กับบัญชีผู้บริหารทุกครั้งที่เข้าสู่ระบบ ปิดไม่ได้',
                      status: 'เปิดใช้งานอยู่',
                      statusColor: AppPalette.success,
                    ),
                    const SizedBox(height: 10),
                    _securityStatusTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'แจ้งเตือนเมื่อมีการเข้าสู่ระบบ',
                      subtitle:
                          'ระบบยังไม่ได้แจ้งเตือนเมื่อมีการเข้าสู่ระบบจากอุปกรณ์ใหม่',
                      status: 'ยังไม่เปิดใช้งาน',
                      statusColor: AppPalette.textMuted,
                    ),
                    const SizedBox(height: 10),
                    _securityActionTile(
                      icon: Icons.logout_rounded,
                      title: 'ออกจากระบบทุกอุปกรณ์',
                      subtitle: 'ใช้เมื่อสงสัยว่าบัญชีถูกเปิดอยู่บนอุปกรณ์อื่น',
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
                  subtitle: 'แนะนำให้เปลี่ยนเป็นระยะและไม่ใช้ร่วมกับบัญชีอื่น',
                  buttonText: 'เปลี่ยนรหัส',
                  onTap: _showPasswordDialog,
                ),
                _securityStatusTile(
                  icon: Icons.verified_user_outlined,
                  title: 'ยืนยันตัวตน 2 ขั้นตอน',
                  subtitle:
                      'บังคับใช้กับบัญชีผู้บริหารทุกครั้งที่เข้าสู่ระบบ ปิดไม่ได้',
                  status: 'เปิดใช้งานอยู่',
                  statusColor: AppPalette.success,
                ),
                _securityStatusTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'แจ้งเตือนเมื่อมีการเข้าสู่ระบบ',
                  subtitle:
                      'ระบบยังไม่ได้แจ้งเตือนเมื่อมีการเข้าสู่ระบบจากอุปกรณ์ใหม่',
                  status: 'ยังไม่เปิดใช้งาน',
                  statusColor: AppPalette.textMuted,
                ),
                _securityActionTile(
                  icon: Icons.logout_rounded,
                  title: 'ออกจากระบบทุกอุปกรณ์',
                  subtitle: 'ใช้เมื่อสงสัยว่าบัญชีถูกเปิดอยู่บนอุปกรณ์อื่น',
                  buttonText: 'ออกจากทุกเครื่อง',
                  onTap: _showLogoutAllDialog,
                ),
              ];

              return GridView.builder(
                itemCount: securityItems.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
        prefixIcon: Icon(icon, size: 18, color: AppPalette.primaryPink),
        filled: true,
        fillColor: AppPalette.pageBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.border),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppPalette.textMuted),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _securityActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            child: Icon(icon, size: 20, color: AppPalette.primaryPinkDark),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _saveArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasChanges
            ? AppPalette.tint(AppPalette.primaryPink, 0.055)
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
                    ? 'ชื่อที่แสดงยังไม่ได้บันทึก'
                    : (_saveError ?? 'ชื่อที่แสดงตรงกับที่บันทึกไว้'),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'การเปลี่ยนแปลงมีผลเฉพาะบัญชีผู้อำนวยการ ไม่กระทบสิทธิ์หรือบัญชีผู้ใช้อื่น',
                style: TextStyle(fontSize: 8.5, color: AppPalette.textMuted),
              ),
            ],
          );

          final buttons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: hasChanges ? _resetSettings : null,
                child: const Text('ยกเลิกการแก้ไข'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.primaryPink,
                ),
                onPressed: (hasChanges && !_saving) ? _saveSettings : null,
                icon: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                label: const Text('บันทึกชื่อที่แสดง'),
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

  /// Saves the one thing that can be saved.
  ///
  /// This used to set `hasChanges = false` and announce "บันทึกการตั้งค่าของ
  /// ผู้อำนวยการแล้ว" without calling anything. Every toggle and dropdown on
  /// this page reverted the moment it was reopened, so a director who turned
  /// off a notification believed it was off and it never was.
  Future<void> _saveSettings() async {
    final name = displayNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _saveError = 'กรุณากรอกชื่อที่แสดง');
      return;
    }
    final uid = currentUserModel?.uid;
    if (uid == null) {
      setState(() => _saveError = 'ยังไม่ได้เข้าสู่ระบบ');
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await AuthService.updateProfile(uid: uid, name: name);
      if (!mounted) return;
      setState(() {
        // Only treated as saved once the write returned. `_savedName` is what
        // `hasChanges` is measured against, so a failure leaves the page
        // correctly showing unsaved changes.
        _savedName = name;
        hasChanges = false;
        _saving = false;
      });
      _showMessage('บันทึกชื่อที่แสดงแล้ว');
    } catch (e) {
      debugPrint('DirectorSettingsPage save failed: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'บันทึกไม่สำเร็จ กรุณาลองใหม่';
      });
    }
  }

  Future<void> _signOutAllDevices() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ออกจากระบบทุกอุปกรณ์'),
        content: const Text(
          'ทุกเครื่องที่เข้าสู่ระบบด้วยบัญชีนี้จะถูกออกจากระบบทันที '
          'รวมถึงเครื่องนี้ด้วย',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppPalette.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AuthService.signOutAllDevices();
    } catch (e) {
      debugPrint('DirectorSettingsPage signOutAll failed: $e');
      if (!mounted) return;
      _showMessage('ออกจากระบบไม่สำเร็จ กรุณาลองใหม่');
    }
  }

  void _resetSettings() {
    setState(() {
      displayNameController.text = _savedName;

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

  /// Password change is not available from this page.
  ///
  /// The dialog that used to open here collected current/new/confirm and then
  /// announced "เปลี่ยนรหัสผ่านเรียบร้อยแล้ว" without calling anything — the
  /// password never changed, and a director who believed it had would keep
  /// using the old one thinking it was retired.
  ///
  /// There is no in-session `change_password(p_token, old, new)` RPC. The
  /// supported path is `request_password_reset_otp` + `confirm_password_reset`,
  /// which is an email-OTP flow rather than a three-field dialog, so it needs
  /// its own screen rather than being faked behind this button.
  void _showPasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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

  /// Was a dialog whose confirm button popped itself and announced
  /// "ออกจากระบบอุปกรณ์อื่นทั้งหมดแล้ว" without calling anything — so a
  /// director who suspected their account was open on someone else's device
  /// was told it had been closed while every session stayed live.
  void _showLogoutAllDialog() => _signOutAllDevices();

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
