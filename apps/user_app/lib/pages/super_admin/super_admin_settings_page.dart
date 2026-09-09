import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/app_palette.dart';
import 'widgets/dev_ui.dart';

class SuperAdminSettingsPage extends StatefulWidget {
  const SuperAdminSettingsPage({
    super.key,
    this.embedded = false,
    this.loadSettings,
    this.loadAuditLogs,
    this.saveSettings,
  });

  /// True when embedded in [SuperAdminNavigationShell]'s desktop sidebar
  /// layout — suppresses this page's own AppBar since the sidebar
  /// already shows which page is selected.
  final bool embedded;

  final Future<PlatformSettings> Function()? loadSettings;
  final Future<List<SchoolAdminAuditLog>> Function()? loadAuditLogs;
  final Future<PlatformSettings> Function({
    double? mq2Threshold,
    double? pm25Threshold,
    double? temperatureThreshold,
    int? offlineMinutes,
    String? mqttHost,
    int? mqttPort,
    bool? lineNotify,
    bool? emailNotify,
    bool? pushNotify,
    bool? automaticBackup,
    bool? maintenanceMode,
    bool? twoFactorRequired,
    bool? auditLogEnabled,
    String? language,
    String? timezone,
    int? logRetentionDays,
    String? backupTime,
  })?
  saveSettings;

  @override
  State<SuperAdminSettingsPage> createState() => _SuperAdminSettingsPageState();
}

typedef SettingsPage = SuperAdminSettingsPage;

class _SuperAdminSettingsPageState extends State<SuperAdminSettingsPage> {
  final SchoolAdminPlatformService _service = SchoolAdminPlatformService();

  final TextEditingController _mq2Controller =
      TextEditingController(text: '2.2');
  final TextEditingController _pmController =
      TextEditingController(text: '35');
  final TextEditingController _temperatureController =
      TextEditingController(text: '45');
  final TextEditingController _offlineMinutesController =
      TextEditingController(text: '5');
  final TextEditingController _mqttHostController =
      TextEditingController(text: '192.168.1.180');
  final TextEditingController _mqttPortController =
      TextEditingController(text: '1883');

  bool _lineNotify = true;
  bool _emailNotify = true;
  bool _pushNotify = true;
  bool _automaticBackup = true;
  bool _maintenanceMode = false;
  bool _twoFactorRequired = true;
  bool _auditLogEnabled = true;

  String _language = 'ภาษาไทย';
  String _timezone = 'Asia/Bangkok (UTC+7)';
  String _logRetention = '365 วัน';
  String _backupTime = '02:00 น.';

  bool _isLoadingLogs = true;

  /// เดิม `catch (_)` แค่ปิดสถานะโหลด — "อ่าน audit log ไม่ได้" จึงอ่านเหมือน
  /// "ยังไม่มีใครแก้ไขค่าอะไรเลย"
  bool _logsFailed = false;
  final List<SchoolAdminAuditLog> _logs = [];

  bool _isLoadingSettings = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final s = await (widget.loadSettings ?? _service.getPlatformSettings)();
      if (!mounted) return;
      setState(() {
        _mq2Controller.text = s.mq2Threshold.toString();
        _pmController.text = s.pm25Threshold.toString();
        _temperatureController.text = s.temperatureThreshold.toString();
        _offlineMinutesController.text = s.offlineMinutes.toString();
        _mqttHostController.text = s.mqttHost;
        _mqttPortController.text = s.mqttPort.toString();
        _lineNotify = s.lineNotify;
        _emailNotify = s.emailNotify;
        _pushNotify = s.pushNotify;
        _automaticBackup = s.automaticBackup;
        _maintenanceMode = s.maintenanceMode;
        _twoFactorRequired = s.twoFactorRequired;
        _auditLogEnabled = s.auditLogEnabled;
        _language = s.language;
        _timezone = s.timezone;
        _logRetention = '${s.logRetentionDays} วัน';
        _backupTime = s.backupTime;
        _isLoadingSettings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSettings = false;
        _loadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _mq2Controller.dispose();
    _pmController.dispose();
    _temperatureController.dispose();
    _offlineMinutesController.dispose();
    _mqttHostController.dispose();
    _mqttPortController.dispose();
    super.dispose();
  }

  Future<void> _loadAuditLogs() async {
    try {
      final logs = await (widget.loadAuditLogs ??
          () => _service.fetchAuditLogs(limit: 6))();
      if (!mounted) return;
      setState(() {
        _logs
          ..clear()
          ..addAll(logs);
        _isLoadingLogs = false;
      });
    } catch (e) {
      debugPrint('SuperAdminSettingsPage: audit logs load failed: $e');
      if (mounted) {
        setState(() {
          _logsFailed = true;
          _isLoadingLogs = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final logRetentionDays =
          int.tryParse(_logRetention.replaceAll(RegExp(r'[^0-9]'), '')) ?? 365;
      final save = widget.saveSettings ?? _service.updatePlatformSettings;
      await save(
        mq2Threshold: double.tryParse(_mq2Controller.text),
        pm25Threshold: double.tryParse(_pmController.text),
        temperatureThreshold: double.tryParse(_temperatureController.text),
        offlineMinutes: int.tryParse(_offlineMinutesController.text),
        mqttHost: _mqttHostController.text.trim(),
        mqttPort: int.tryParse(_mqttPortController.text),
        lineNotify: _lineNotify,
        emailNotify: _emailNotify,
        pushNotify: _pushNotify,
        automaticBackup: _automaticBackup,
        maintenanceMode: _maintenanceMode,
        twoFactorRequired: _twoFactorRequired,
        auditLogEnabled: _auditLogEnabled,
        language: _language,
        timezone: _timezone,
        logRetentionDays: logRetentionDays,
        backupTime: _backupTime,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      _message('บันทึกการตั้งค่าแล้ว');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _message('บันทึกไม่สำเร็จ: $e');
    }
  }

  Future<void> _restoreDefaults() async {
    setState(() {
      _mq2Controller.text = '2.2';
      _pmController.text = '35';
      _temperatureController.text = '45';
      _offlineMinutesController.text = '5';
      _mqttHostController.text = '192.168.1.180';
      _mqttPortController.text = '1883';
      _lineNotify = true;
      _emailNotify = true;
      _pushNotify = true;
      _automaticBackup = true;
      _maintenanceMode = false;
      _twoFactorRequired = true;
      _auditLogEnabled = true;
      _language = 'ภาษาไทย';
      _timezone = 'Asia/Bangkok (UTC+7)';
      _logRetention = '365 วัน';
      _backupTime = '02:00 น.';
    });
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text(
                'ตั้งค่าระบบส่วนกลาง (Platform Settings)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  tooltip: 'รีเฟรชประวัติ Log',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => _loadAuditLogs(),
                ),
              ],
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            if (_isLoadingSettings)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else if (_loadError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppPalette.carnivalRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'โหลดค่าที่บันทึกไว้ไม่สำเร็จ: $_loadError (แสดงค่าเริ่มต้นแทน)',
                  style: const TextStyle(
                    color: AppPalette.carnivalRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            _buildTierBDisclosureBanner(),
            const SizedBox(height: 16),
            _buildHeroCard(),
            const SizedBox(height: 18),
            _buildThresholdsSection(),
            const SizedBox(height: 18),
            _buildMqttSection(),
            const SizedBox(height: 18),
            _buildNotificationSection(),
            const SizedBox(height: 18),
            _buildSecuritySection(),
            const SizedBox(height: 18),
            _buildSystemMaintenanceSection(),
            const SizedBox(height: 18),
            _buildAuditLogsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBDisclosureBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'ค่าที่กรอกในหน้านี้ถูกบันทึกจริงแล้ว แต่ระบบยังไม่มีการบังคับใช้อัตโนมัติตามค่าเหล่านี้ '
              '(เช่น ยังไม่ส่งแจ้งเตือนผ่านช่องทางที่เลือกจริง ยังไม่บังคับ MFA จริง) — ใช้เป็นค่าที่บันทึกไว้ '
              'สำหรับอ้างอิง รอการเชื่อมต่อระบบจริงในแต่ละส่วนต่อไป',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppPalette.deepBlue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge('การตั้งค่าระดับระบบ (Platform Settings)',
                  AppPalette.circusYellow),
              _badge('Super Admin Only', Colors.white.withAlpha(50)),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'กำหนดเกณฑ์ความปลอดภัย การแจ้งเตือน และนโยบายระบบ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ปรับแต่งค่าเกณฑ์เซนเซอร์ (Thresholds) ความถี่การสำรองข้อมูล และนโยบายความปลอดภัยของระบบ AIoT Smart Lab',
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.circusYellow,
                  foregroundColor: AppPalette.textPrimary,
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('บันทึกการตั้งค่า',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              OutlinedButton.icon(
                onPressed: _restoreDefaults,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withAlpha(160)),
                ),
                icon: const Icon(Icons.restore_rounded),
                label: const Text('เรียกคืนค่าเริ่มต้น'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdsSection() {
    return _panel(
      title: 'เกณฑ์แจ้งเตือนเซนเซอร์ (Sensor Thresholds)',
      child: Column(
        children: [
          TextField(
            controller: _pmController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'เกณฑ์ PM2.5 สูงสุด (µg/m³)',
              prefixIcon: Icon(Icons.air_rounded),
              helperText: 'หากค่าเกินเกณฑ์จะแจ้งเตือนระดับสูง (High Alert)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _temperatureController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'เกณฑ์อุณหภูมิห้องควบคุมสูงสุด (°C)',
              prefixIcon: Icon(Icons.thermostat_rounded),
              helperText: 'ค่าอุณหภูมิปกติไม่ควรเกิน 45°C',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mq2Controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'เกณฑ์ควันและแก๊ส MQ-2 (Volt)',
              prefixIcon: Icon(Icons.local_fire_department_rounded),
              helperText: 'แรงดันไฟฟ้าเซนเซอร์เกินเกณฑ์จะแจ้งเตือนวิกฤต (Critical)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _offlineMinutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'แจ้งเตือนอุปกรณ์ออฟไลน์หลัง (นาที)',
              prefixIcon: Icon(Icons.wifi_off_rounded),
              helperText: 'อุปกรณ์ที่ไม่ส่งข้อมูลเกินเวลานี้จะถูกแจ้งเตือนว่าออฟไลน์',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMqttSection() {
    return _panel(
      title: 'การเชื่อมต่อ MQTT / Local Gateway',
      child: Column(
        children: [
          TextField(
            controller: _mqttHostController,
            decoration: const InputDecoration(
              labelText: 'MQTT Host',
              prefixIcon: Icon(Icons.dns_rounded),
              helperText: 'ที่อยู่ IP ของ Local Gateway ที่รับส่งข้อมูลอุปกรณ์',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mqttPortController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'MQTT Port',
              prefixIcon: Icon(Icons.numbers_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return _panel(
      title: 'ช่องทางการแจ้งเตือนอัตโนมัติ (Alert Channels)',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('แจ้งเตือนผ่าน LINE Notify / LINE Bot',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('ส่งข้อความแจ้งเตือนเหตุวิกฤตไปยังกลุ่มผู้ดูแล'),
            value: _lineNotify,
            activeColor: AppPalette.deepBlue,
            onChanged: (val) => setState(() => _lineNotify = val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('แจ้งเตือนทางอีเมล (Email Alerts)',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('ส่งสรุปรายงานรายวันและเหตุการณ์สำคัญ'),
            value: _emailNotify,
            activeColor: AppPalette.deepBlue,
            onChanged: (val) => setState(() => _emailNotify = val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('แจ้งเตือนแบบพุชบนมือถือ (Push Notification)',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('ส่งการแจ้งเตือนไปยังแอปพลิเคชันทันที'),
            value: _pushNotify,
            activeColor: AppPalette.deepBlue,
            onChanged: (val) => setState(() => _pushNotify = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _panel(
      title: 'นโยบายความปลอดภัยและระบบ (Security & Policy)',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('บังคับเปิด MFA สำหรับบัญชีผู้ดูแล (MFA Enforcement)',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Super Admin และ School Admin ต้องยืนยันตัวตนสองขั้นตอน'),
            value: _twoFactorRequired,
            activeColor: AppPalette.deepBlue,
            onChanged: (val) => setState(() => _twoFactorRequired = val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('โหมดปิดปรับปรุงระบบ (Maintenance Mode)',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('จำกัดการเข้าถึงเฉพาะ Super Admin ชั่วคราว'),
            value: _maintenanceMode,
            activeColor: AppPalette.carnivalRed,
            onChanged: (val) => setState(() => _maintenanceMode = val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('บันทึกประวัติการดำเนินการ (Audit Logging)',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('บันทึกคำสั่งควบคุมและแก้ไขสิทธิ์ลงระบบอย่างถาวร'),
            value: _auditLogEnabled,
            activeColor: AppPalette.deepBlue,
            onChanged: (val) => setState(() => _auditLogEnabled = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMaintenanceSection() {
    return _panel(
      title: 'ระบบและการสำรองข้อมูล (System & Maintenance)',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('สำรองข้อมูลอัตโนมัติประจำวัน (Daily Auto Backup)',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('รอบเวลาสำรองข้อมูล: $_backupTime'),
            value: _automaticBackup,
            activeColor: AppPalette.deepBlue,
            onChanged: (val) => setState(() => _automaticBackup = val),
          ),
          const Divider(),
          ListTile(
            title: const Text('ภาษาของระบบ',
                style: TextStyle(fontWeight: FontWeight.w700)),
            trailing: Text(_language,
                style: const TextStyle(
                    color: AppPalette.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          const Divider(),
          ListTile(
            title: const Text('เขตเวลา (Timezone)',
                style: TextStyle(fontWeight: FontWeight.w700)),
            trailing: Text(_timezone,
                style: const TextStyle(
                    color: AppPalette.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          const Divider(),
          ListTile(
            title: const Text('ระยะเวลาจัดเก็บ Log',
                style: TextStyle(fontWeight: FontWeight.w700)),
            trailing: Text(_logRetention,
                style: const TextStyle(
                    color: AppPalette.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsSection() {
    return _panel(
      title: 'ประวัติกิจกรรมและการตั้งค่าล่าสุด (Recent Audit Logs)',
      child: _isLoadingLogs
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          : _logs.isEmpty
              ? _empty(
                  _logsFailed
                      ? Icons.error_outline_rounded
                      : Icons.history_toggle_off_rounded,
                  _logsFailed
                      ? 'โหลดประวัติการแก้ไขไม่สำเร็จ'
                      : 'ยังไม่มีประวัติการแก้ไข',
                  _logsFailed
                      ? 'ยังไม่ได้อ่านข้อมูลจากระบบ — ไม่ได้แปลว่าไม่มีการแก้ไข'
                      : 'การเปลี่ยนแปลงค่าและการสั่งการจะแสดงที่นี่',
                )
              : Column(
                  children: [
                    for (int i = 0; i < _logs.length; i++) ...[
                      _logRow(_logs[i]),
                      if (i < _logs.length - 1) const Divider(height: 16),
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
                'โดย ${log.actorName} • ${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')} น.',
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

  Widget _panel({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return AppPanel(title: title, trailing: trailing, child: child);
  }

  Widget _badge(String label, Color color) {
    return StatusBadge(label: label, color: color);
  }

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

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  List<BoxShadow> get _shadow => [
        BoxShadow(
          color: Colors.black.withAlpha(12),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
}
