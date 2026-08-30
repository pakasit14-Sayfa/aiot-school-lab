import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../widgets/app_drawer.dart';
import 'theme/app_palette.dart';
import 'widgets/dev_ui.dart';
import 'super_admin_schools_page.dart';
import 'super_admin_device_control_page.dart';
import 'super_admin_devices_page.dart';
import 'super_admin_device_test_page.dart';
import 'super_admin_permissions_page.dart';
import 'super_admin_alerts_logs_page.dart';
import 'super_admin_settings_page.dart';

class SuperAdminHubPage extends StatefulWidget {
  const SuperAdminHubPage({super.key});

  @override
  State<SuperAdminHubPage> createState() => _SuperAdminHubPageState();
}

typedef DevDashboardPage = SuperAdminHubPage;

class _SuperAdminHubPageState extends State<SuperAdminHubPage> {
  final SchoolAdminPlatformService _platformService =
      SchoolAdminPlatformService();

  bool _isLoading = true;
  String? _loadError;

  List<SchoolPlatformRecord> _schools = [];
  List<SchoolSensorAlertRecord> _alerts = [];
  List<SchoolAdminAuditLog> _logs = [];

  int _totalDevices = 0;
  int _onlineDevices = 0;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final schools = await _platformService.fetchSchools();
      List<SchoolSensorAlertRecord> alertRecords = [];
      try {
        alertRecords = await IncidentService.listSchoolAlerts();
      } catch (_) {
        alertRecords = [];
      }

      List<SchoolAdminAuditLog> logRecords = [];
      try {
        logRecords = await _platformService.fetchAuditLogs(limit: 10);
      } catch (_) {
        logRecords = [];
      }

      int totalDev = 0;
      int onlineDev = 0;
      int totalU = 0;

      for (final s in schools) {
        totalDev += s.devicesTotal;
        onlineDev += s.devicesOnline;
        totalU += s.usersCount;
      }

      if (!mounted) return;

      setState(() {
        _schools = schools;
        _alerts = alertRecords;
        _logs = logRecords;
        _totalDevices = totalDev;
        _onlineDevices = onlineDev;
        _totalUsers = totalU;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text(
          'ศูนย์ควบคุมภาพรวม (Platform Hub)',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'รีเฟรชข้อมูล',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadDashboardData(),
          ),
        ],
      ),
      drawer: AppDrawer(
        items: [
          DrawerItem(
            icon: Icons.account_balance_rounded,
            title: 'จัดการโรงเรียน (Schools)',
            color: const Color(0xFF0F5B8F),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminSchoolsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.toggle_on_rounded,
            title: 'ควบคุมและอนุมัติอุปกรณ์ (Device Control)',
            color: const Color(0xFF1E88E5),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminDeviceControlPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.qr_code_2_rounded,
            title: 'ทะเบียนและ QR Code (Devices & QR)',
            color: const Color(0xFF028090),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminDevicesPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.science_rounded,
            title: 'ทดสอบอุปกรณ์ (Device Diagnostics)',
            color: const Color(0xFF6A4C93),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminDeviceTestPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.admin_panel_settings_rounded,
            title: 'กำหนดสิทธิ์และบทบาท (Permissions)',
            color: const Color(0xFFB0232B),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminPermissionsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.notifications_active_rounded,
            title: 'การแจ้งเตือนและประวัติ (Alerts & Logs)',
            color: const Color(0xFFF18701),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminAlertsLogsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.settings_rounded,
            title: 'ตั้งค่าระบบส่วนกลาง (Settings)',
            color: const Color(0xFF4361EE),
            onTap: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const SuperAdminSettingsPage()),
            ),
          ),
          DrawerItem(
            icon: Icons.people_alt_rounded,
            title: 'จัดการผู้ใช้ (User Management)',
            color: Colors.blueGrey,
            onTap: (ctx) => Navigator.pushNamed(ctx, '/users'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _schools.isEmpty && _loadError == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => _loadDashboardData(showLoading: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          if (_loadError != null && _schools.isEmpty) ...[
            _buildErrorNotice(),
            const SizedBox(height: 16),
          ],
          _buildHeroBanner(),
          const SizedBox(height: 18),
          _buildSummaryMetrics(),
          const SizedBox(height: 18),
          _buildQuickActionCards(),
          const SizedBox(height: 18),
          _buildSchoolMonitoringSection(),
          const SizedBox(height: 18),
          _buildRecentAuditLogsSection(),
        ],
      ),
    );
  }

  Widget _buildErrorNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.carnivalRed.withAlpha(20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.carnivalRed.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppPalette.carnivalRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ไม่สามารถเชื่อมต่อฐานข้อมูลภาพรวมได้ (${_loadError ?? "Offline"})',
              style: const TextStyle(
                fontSize: 12,
                color: AppPalette.carnivalRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            onPressed: () => _loadDashboardData(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. Hero Banner
  // ===========================================================================

  Widget _buildHeroBanner() {
    final user = currentUserModel;
    final name = user?.name ?? 'Super Admin';

    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.deepBlue, Color(0xFF1676B5)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppPalette.deepBlue.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -60,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  color: AppPalette.circusYellow.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusBadge(
                        label: 'Super Admin Platform Hub',
                        color: AppPalette.circusYellow,
                      ),
                      StatusBadge(
                        label: 'ระบบปฏิบัติการส่วนกลาง',
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'ยินดีต้อนรับ, $name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ควบคุมโรงเรียน อุปกรณ์ IoT การแจ้งเตือน และสิทธิ์ผู้ใช้ทั่วทั้งระบบจากที่เดียว',
                    style: TextStyle(
                      color: Colors.white.withAlpha(210),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SuperAdminSchoolsPage()),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.circusYellow,
                          foregroundColor: AppPalette.textPrimary,
                        ),
                        icon: const Icon(Icons.apartment_rounded),
                        label: const Text('จัดการโรงเรียน',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SuperAdminAlertsLogsPage()),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withAlpha(160)),
                        ),
                        icon: const Icon(Icons.notifications_active_rounded),
                        label: const Text('ดูการแจ้งเตือน'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. Summary Metrics
  // ===========================================================================

  Widget _buildSummaryMetrics() {
    final int activeSchools =
        _schools.where((s) => s.status == 'active').length;
    final int openAlerts =
        _alerts.where((a) => a.status == 'open' || a.status == 'pending').length;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 1100 ? 4 : 2;
        const double gap = 12;
        final double width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        final List<Widget> cards = <Widget>[
          _metricCard(
            Icons.apartment_rounded,
            'โรงเรียนในระบบ',
            '${_schools.length}',
            'เปิดใช้งาน $activeSchools โรงเรียน',
            AppPalette.deepBlue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SuperAdminSchoolsPage()),
            ),
          ),
          _metricCard(
            Icons.memory_rounded,
            'อุปกรณ์ IoT',
            '$_totalDevices',
            'ออนไลน์ $_onlineDevices เครื่อง',
            AppPalette.gardenGreen,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SuperAdminDeviceControlPage()),
            ),
          ),
          _metricCard(
            Icons.people_alt_rounded,
            'ผู้ใช้งานทั้งหมด',
            '$_totalUsers',
            'บุคลากรและนักเรียน',
            AppPalette.circusYellow,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SuperAdminPermissionsPage()),
            ),
          ),
          _metricCard(
            Icons.warning_amber_rounded,
            'เหตุแจ้งเตือน',
            '$openAlerts',
            'รอดำเนินการตรวจสอบ',
            openAlerts > 0 ? AppPalette.carnivalRed : AppPalette.gardenGreen,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SuperAdminAlertsLogsPage()),
            ),
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((Widget card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _metricCard(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: StatCard(
        icon: icon,
        title: title,
        value: value,
        footnote: subtitle,
        accent: color,
      ),
    );
  }

  // ===========================================================================
  // 3. Quick Action Hub
  // ===========================================================================

  Widget _buildQuickActionCards() {
    return AppPanel(
      title: 'ศูนย์สั่งการหลัก (Platform Control Hub)',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columns = constraints.maxWidth >= 900 ? 3 : 1;
          const double gap = 12;
          final double width =
              (constraints.maxWidth - gap * (columns - 1)) / columns;

          final List<Widget> items = [
            _actionCard(
              icon: Icons.account_balance_rounded,
              title: 'จัดการโรงเรียน (Schools)',
              description: 'โควต้า, ไลเซนส์, สถานะโรงเรียน และการตั้งค่าพื้นฐาน',
              color: const Color(0xFF0F5B8F),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SuperAdminSchoolsPage()),
              ),
            ),
            _actionCard(
              icon: Icons.toggle_on_rounded,
              title: 'ควบคุมอุปกรณ์ (Device Control)',
              description: 'สั่งการเปิด/ปิด, ตรวจสอบสถานะ และอนุมัติคำสั่งอุปกรณ์',
              color: const Color(0xFF1E88E5),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SuperAdminDeviceControlPage()),
              ),
            ),
            _actionCard(
              icon: Icons.qr_code_2_rounded,
              title: 'ทะเบียน & QR Code (Devices & QR)',
              description: 'ค้นหารหัสกำกับอุปกรณ์, สร้างและพิมพ์ QR Code สติกเกอร์',
              color: const Color(0xFF028090),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SuperAdminDevicesPage()),
              ),
            ),
            _actionCard(
              icon: Icons.science_rounded,
              title: 'ทดสอบอุปกรณ์ (Device Diagnostics)',
              description: 'ตรวจวินิจฉัยสถานะเชื่อมต่อ, วัด Latency และทดสอบ API',
              color: const Color(0xFF6A4C93),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SuperAdminDeviceTestPage()),
              ),
            ),
            _actionCard(
              icon: Icons.admin_panel_settings_rounded,
              title: 'จัดการสิทธิ์ (Permissions)',
              description: 'กำหนดบทบาท RBAC, จัดการคำเชิญ และบัญชีผู้ใช้ข้ามโรงเรียน',
              color: const Color(0xFFB0232B),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SuperAdminPermissionsPage()),
              ),
            ),
            _actionCard(
              icon: Icons.notifications_active_rounded,
              title: 'การแจ้งเตือน (Alerts & Logs)',
              description: 'มอนิเตอร์เซนเซอร์ผิดปกติ, รับทราบเหตุ และดู Audit Log',
              color: const Color(0xFFF18701),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SuperAdminAlertsLogsPage()),
              ),
            ),
            _actionCard(
              icon: Icons.settings_rounded,
              title: 'ตั้งค่าระบบส่วนกลาง (Settings)',
              description: 'กำหนดเกณฑ์ Thresholds, ช่องทางแจ้งเตือน และนโยบายความปลอดภัย',
              color: const Color(0xFF4361EE),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SuperAdminSettingsPage()),
              ),
            ),
            _actionCard(
              icon: Icons.people_alt_rounded,
              title: 'รายชื่อผู้ใช้ (Users)',
              description: 'ค้นหาและตรวจสอบสถานะผู้ใช้งานทั้งหมดในแพลตฟอร์ม',
              color: Colors.blueGrey,
              onTap: () => Navigator.pushNamed(context, '/users'),
            ),
          ];

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: items
                .map((Widget item) => SizedBox(width: width, child: item))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withAlpha(30),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. School Monitoring Section
  // ===========================================================================

  Widget _buildSchoolMonitoringSection() {
    return AppPanel(
      title: 'สถานะโรงเรียนในระบบ (School Overview)',
      trailing: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminSchoolsPage()),
        ),
        child: const Text('ดูทั้งหมด'),
      ),
      child: _schools.isEmpty
          ? _empty(
              Icons.apartment_rounded,
              'ยังไม่มีข้อมูลโรงเรียน',
              'โรงเรียนที่ลงทะเบียนในระบบจะแสดงที่นี่',
            )
          : Column(
              children: [
                for (int i = 0; i < _schools.length && i < 5; i++) ...[
                  _schoolRow(_schools[i]),
                  if (i < _schools.length.clamp(0, 5) - 1)
                    const Divider(height: 16),
                ],
              ],
            ),
    );
  }

  Widget _schoolRow(SchoolPlatformRecord school) {
    final bool isActive = school.status == 'active';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppPalette.deepBlue.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.apartment_rounded,
              color: AppPalette.deepBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                school.name,
                style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${school.province} • ${school.devicesOnline}/${school.devicesTotal} อุปกรณ์ออนไลน์',
                style: const TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        StatusBadge(
          label: isActive ? 'เปิดใช้งาน' : 'ระงับ',
          color: isActive ? AppPalette.gardenGreen : AppPalette.carnivalRed,
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. Recent Audit Logs Section
  // ===========================================================================

  Widget _buildRecentAuditLogsSection() {
    return AppPanel(
      title: 'กิจกรรมระบบล่าสุด (Recent Activity Logs)',
      trailing: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminAlertsLogsPage()),
        ),
        child: const Text('ดูประวัติทั้งหมด'),
      ),
      child: _logs.isEmpty
          ? _empty(
              Icons.history_toggle_off_rounded,
              'ยังไม่มีประวัติกิจกรรม',
              'การเปลี่ยนแปลงสิทธิ์และคำสั่งควบคุมจะแสดงที่นี่',
            )
          : Column(
              children: [
                for (int i = 0; i < _logs.length && i < 4; i++) ...[
                  _logRow(_logs[i]),
                  if (i < _logs.length.clamp(0, 4) - 1) const Divider(height: 16),
                ],
              ],
            ),
    );
  }

  Widget _logRow(SchoolAdminAuditLog log) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppPalette.deepBlue.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.history_rounded,
              color: AppPalette.deepBlue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.action,
                style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                log.detail.isNotEmpty ? log.detail : log.target,
                style: const TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'โดย ${log.actorName}',
                style: const TextStyle(
                  color: AppPalette.gardenGreen,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  Widget _empty(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: AppPalette.softBeige.withAlpha(50),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppPalette.deepBlue.withAlpha(25),
            child: Icon(icon, color: AppPalette.deepBlue, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
