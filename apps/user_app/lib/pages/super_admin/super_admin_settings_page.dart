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

  // Until 2026-09-16 this page held 17 settings (sensor thresholds, MQTT
  // host/port, LINE/email/push toggles, backup, maintenance mode, 2FA, audit
  // log, language, timezone, retention, backup time) behind a banner saying
  // they were "saved for reference, not enforced". Nothing in the schema,
  // any RPC or any edge function read them. Only `offline_minutes` has a
  // real consumer — device_effective_status() since 20260916020000 — so it
  // is the only setting left. The other columns stay in platform_settings
  // untouched; they are simply no longer offered as if they did something.
  final TextEditingController _offlineMinutesController =
      TextEditingController(text: '5');
  int _savedOfflineMinutes = 5;

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
        _offlineMinutesController.text = s.offlineMinutes.toString();
        _savedOfflineMinutes = s.offlineMinutes;
        _isLoadingSettings = false;
      });
    } catch (e) {
      debugPrint('SuperAdminSettingsPage: settings load failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingSettings = false;
        _loadError = 'โหลดค่าที่บันทึกไว้ไม่สำเร็จ';
      });
    }
  }

  @override
  void dispose() {
    _offlineMinutesController.dispose();
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
    final minutes = int.tryParse(_offlineMinutesController.text.trim());
    if (minutes == null || minutes < 1 || minutes > 1440) {
      _message('กรอกจำนวนนาทีระหว่าง 1 ถึง 1440');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final save = widget.saveSettings ?? _service.updatePlatformSettings;
      // Write, then trust only the row the backend returns.
      final saved = await save(offlineMinutes: minutes);
      if (!mounted) return;
      if (saved.offlineMinutes != minutes) {
        setState(() => _isSaving = false);
        _message('บันทึกไม่สำเร็จ ค่าในระบบยังเป็น ${saved.offlineMinutes} นาที');
        return;
      }
      setState(() {
        _isSaving = false;
        _savedOfflineMinutes = saved.offlineMinutes;
      });
      _message('บันทึกแล้ว — อุปกรณ์ที่เงียบเกิน $minutes นาทีจะขึ้นออฟไลน์');
      await _loadAuditLogs();
    } catch (e) {
      debugPrint('SuperAdminSettingsPage: save failed: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      _message('บันทึกไม่สำเร็จ ค่าในระบบยังเป็น $_savedOfflineMinutes นาที');
    }
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
                  '$_loadError — แสดงค่าเริ่มต้น 5 นาทีแทน',
                  style: const TextStyle(
                    color: AppPalette.carnivalRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            _buildHeroCard(),
            const SizedBox(height: 18),
            _buildOfflineSection(),
            const SizedBox(height: 18),
            _buildAuditLogsSection(),
          ],
        ),
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
            'ค่ากลางของระบบที่มีผลจริงกับทุกโรงเรียน',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ตอนนี้มีค่าเดียวที่ระบบอ่านไปใช้จริง: เกณฑ์เวลาที่ถือว่าอุปกรณ์ออฟไลน์ (ใช้ในสถานะอุปกรณ์ทุกหน้า)',
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineSection() {
    return _panel(
      title: 'เกณฑ์อุปกรณ์ออฟไลน์',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _offlineMinutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ถือว่าออฟไลน์เมื่อไม่รายงานตัวเกิน (นาที)',
              prefixIcon: Icon(Icons.wifi_off_rounded),
              helperText:
                  'device_effective_status ใช้ค่านี้คำนวณสถานะ online/offline '
                  'ที่แสดงในหน้าอุปกรณ์ของทุกบทบาท',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ค่าที่บันทึกในระบบตอนนี้: $_savedOfflineMinutes นาที',
            style: const TextStyle(fontSize: 12, color: AppPalette.textSecondary),
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
