import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../theme/school_admin_palette.dart';

/// หน้า "ตั้งค่าโรงเรียน" ของ School Admin
///
/// สิ่งที่ backend มีให้ role `school_admin` จริง ๆ (ตรวจลายเซ็นและ role gate
/// กับฐานข้อมูลที่รันอยู่ ไม่ใช่ไฟล์ migration) มีเพียง:
///
///   * `get_school_admin_dashboard_summary(p_token)` — ชื่อ/รหัสโรงเรียน และ
///     ยอดนับจริง (อ่านอย่างเดียว)
///   * `get_school_utility_rates(p_token)` /
///     `set_school_utility_rates(p_token, p_electricity_rate_thb,
///     p_water_rate_thb)` — แถวเดียวใน `school_settings` ที่ school_admin
///     **เขียนได้จริง** (gate: `role in ('school_admin','super_admin')`)
///   * `list_school_admin_audit_logs(p_token, p_limit)`
///
/// สิ่งที่ **ไม่มี** และเคยถูกทำเป็นหน้าตั้งค่าเต็มรูปแบบในไฟล์นี้:
/// ปีการศึกษา ภาคเรียน ภาษา เขตเวลา รูปแบบวันที่ หน้าแรกหลังเข้าสู่ระบบ
/// สวิตช์แจ้งเตือน 8 ตัว สวิตช์ความปลอดภัย 4 ตัว สวิตช์นำเข้า/ส่งออก 2 ตัว
/// การสำรองข้อมูล ประวัติการนำเข้า การบังคับออกจากระบบทุกบัญชี และการคืนค่า
/// การตั้งค่า — ไม่มีคอลัมน์ใดใน `school_settings` และไม่มี RPC ใดรองรับเลย
/// (`school_settings` มีแค่ `electricity_rate_thb`, `water_rate_thb`,
/// `retention_policy`, `pdpa_camera_*`) ทั้งหมดจึงถูกยุบเป็นรายการ
/// "ยังไม่เปิดใช้งาน" ที่ปิดไว้พร้อมบอกเหตุผล แทนสวิตช์ที่กดได้แล้วหายเมื่อ
/// รีเฟรช และแทน dialog ที่เคยขึ้นว่า "บันทึกแล้ว (จำลอง)"
///
/// **ไม่ใช้ `get_platform_settings` / `update_platform_settings`** — gate คือ
/// `role != 'super_admin' → forbidden` เป็นค่าระดับแพลตฟอร์มของทั้งระบบ
/// ไม่ใช่ค่าของโรงเรียนเดียว
///
/// บล็อก "แพ็กเกจและการใช้งาน" เดิม (238 วันคงเหลือ · หมดอายุ 5 เม.ย. 2570 ·
/// 96/300 บัญชี · 152/500 รายการ) ถูกลบทั้งก้อน — ไม่มีตัวเลขไหนมาจาก
/// ฐานข้อมูล และ RPC ที่อ่านโควตา/วันหมดอายุได้เป็นของ super_admin เท่านั้น
class SchoolSettingsPage extends StatefulWidget {
  const SchoolSettingsPage({
    super.key,
    this.loadSummary,
    this.loadRates,
    this.saveRates,
    this.loadLogs,
  });

  /// Seam สำหรับเทสต์ (แบบเดียวกับ `school_resources_page`) — production
  /// ไม่ส่งอะไรมาแล้วใช้ service จริง
  final Future<SchoolAdminDashboardSummary> Function()? loadSummary;
  final Future<SchoolUtilityRates?> Function()? loadRates;
  final Future<void> Function({
    required double electricityRateThb,
    required double waterRateThb,
  })?
  saveRates;
  final Future<List<SchoolAdminAuditLog>> Function()? loadLogs;

  @override
  State<SchoolSettingsPage> createState() => _SchoolSettingsPageState();
}

enum _LoadPhase { loading, data, error }

class _SchoolSettingsPageState extends State<SchoolSettingsPage> {
  static const String _noData = 'ยังไม่มีข้อมูล';

  final TextEditingController _electricityController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();

  _LoadPhase _summaryPhase = _LoadPhase.loading;
  SchoolAdminDashboardSummary? _summary;

  _LoadPhase _ratesPhase = _LoadPhase.loading;
  SchoolUtilityRates? _rates;

  _LoadPhase _logsPhase = _LoadPhase.loading;
  List<SchoolAdminAuditLog> _logs = const [];

  bool _savingRates = false;
  String? _saveError;

  Future<SchoolAdminDashboardSummary> get _summaryLoader =>
      (widget.loadSummary ??
      () => SchoolAdminPlatformService().fetchDashboardSummary())();

  Future<SchoolUtilityRates?> get _ratesLoader =>
      (widget.loadRates ?? UtilityService.getSchoolUtilityRates)();

  Future<List<SchoolAdminAuditLog>> get _logLoader =>
      (widget.loadLogs ??
      () => SchoolAdminPlatformService().fetchAuditLogs(limit: 6))();

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadRates();
    _loadLogs();
  }

  @override
  void dispose() {
    _electricityController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() => _summaryPhase = _LoadPhase.loading);
    try {
      final summary = await _summaryLoader;
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _summaryPhase = _LoadPhase.data;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = null;
        _summaryPhase = _LoadPhase.error;
      });
    }
  }

  Future<void> _loadRates() async {
    setState(() {
      _ratesPhase = _LoadPhase.loading;
      _saveError = null;
    });
    try {
      final rates = await _ratesLoader;
      if (!mounted) return;
      setState(() {
        _rates = rates;
        _ratesPhase = _LoadPhase.data;
        // ช่องกรอกสะท้อนค่าที่ backend ยืนยันเสมอ ไม่ค้างค่าที่ผู้ใช้พิมพ์
        // ไว้แล้วบันทึกไม่สำเร็จ
        _electricityController.text = rates == null
            ? ''
            : _formatRate(rates.electricityRateThb);
        _waterController.text = rates == null
            ? ''
            : _formatRate(rates.waterRateThb);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rates = null;
        _ratesPhase = _LoadPhase.error;
      });
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _logsPhase = _LoadPhase.loading);
    try {
      final logs = await _logLoader;
      if (!mounted) return;
      setState(() {
        _logs = List<SchoolAdminAuditLog>.unmodifiable(logs);
        _logsPhase = _LoadPhase.data;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _logs = const [];
        _logsPhase = _LoadPhase.error;
      });
    }
  }

  Future<void> _reloadAll() async {
    await Future.wait([_loadSummary(), _loadRates(), _loadLogs()]);
  }

  static String _formatRate(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// เขียน → อ่าน canonical กลับ → ตรวจว่าค่าที่บันทึกตรงกับที่ backend
  /// ยืนยัน → ค่อยบอกว่าสำเร็จ ถ้าอ่านกลับแล้วไม่ตรงถือว่าไม่สำเร็จ
  /// ห้ามขึ้นข้อความสำเร็จเด็ดขาด (ของเดิมขึ้น "บันทึกแล้ว" ทุกครั้งโดยไม่มี
  /// การเขียนอะไรลงฐานข้อมูลเลย)
  Future<void> _saveRates() async {
    final electricity = double.tryParse(_electricityController.text.trim());
    final water = double.tryParse(_waterController.text.trim());

    if (electricity == null ||
        water == null ||
        electricity <= 0 ||
        water <= 0) {
      setState(
        () => _saveError = 'กรุณากรอกอัตราค่าไฟฟ้าและค่าน้ำเป็นตัวเลขมากกว่า 0',
      );
      return;
    }

    setState(() {
      _savingRates = true;
      _saveError = null;
    });

    try {
      final save = widget.saveRates ?? UtilityService.setSchoolUtilityRates;
      await save(electricityRateThb: electricity, waterRateThb: water);

      final confirmed = await _ratesLoader;
      if (confirmed == null) {
        throw StateError('backend_rates_not_confirmed');
      }
      const epsilon = 0.005;
      if ((confirmed.electricityRateThb - electricity).abs() > epsilon ||
          (confirmed.waterRateThb - water).abs() > epsilon) {
        throw StateError('backend_rates_not_confirmed');
      }

      if (!mounted) return;
      setState(() {
        _rates = confirmed;
        _ratesPhase = _LoadPhase.data;
        _electricityController.text = _formatRate(
          confirmed.electricityRateThb,
        );
        _waterController.text = _formatRate(confirmed.waterRateThb);
        _savingRates = false;
      });
      _showMessage('บันทึกอัตราค่าไฟฟ้าและค่าน้ำเรียบร้อยแล้ว');
      await _loadLogs();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingRates = false;
        _saveError =
            'บันทึกอัตราค่าไฟฟ้าและค่าน้ำไม่สำเร็จ ระบบยังไม่ได้บันทึกการเปลี่ยนแปลง';
      });
    }
  }

  // ---------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------

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
                  _buildDisclosureBanner(),
                  const SizedBox(height: 14),
                  _buildSummary(),
                  const SizedBox(height: 14),
                  _buildSchoolInfo(),
                  const SizedBox(height: 14),
                  _buildUtilityRates(),
                  const SizedBox(height: 14),
                  _buildUnavailableSettings(),
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
            builder: (context, constraints) {
              const Widget title = Row(
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
                          'ดูข้อมูลโรงเรียนที่ระบบบันทึกไว้ และตั้งอัตราค่าไฟฟ้า/ค่าน้ำ '
                          'ที่ใช้คำนวณค่าใช้จ่ายในหน้ารายงานทรัพยากร',
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

              final Widget actions = OutlinedButton.icon(
                onPressed: _reloadAll,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('โหลดใหม่'),
              );

              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 14), actions],
                );
              }

              return Row(
                children: [
                  const Expanded(child: title),
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

  Widget _buildDisclosureBanner() {
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
              'หมายเหตุ: ระบบการตั้งค่าโรงเรียน การแจ้งเตือน และความปลอดภัยยังไม่เชื่อมต่อระบบหลังบ้าน '
              'หน้านี้จึงแสดงเฉพาะข้อมูลที่ระบบบันทึกไว้จริง และแก้ไขได้เฉพาะอัตราค่าไฟฟ้า/ค่าน้ำเท่านั้น',
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

  Widget _buildSummary() {
    final loading = _summaryPhase == _LoadPhase.loading;
    final failed = _summaryPhase == _LoadPhase.error;
    final summary = _summary;

    String value(int? count) {
      if (loading || failed || count == null) return '—';
      return '$count';
    }

    String detail(String ok) {
      if (loading) return 'กำลังโหลด…';
      if (failed) return 'โหลดไม่สำเร็จ';
      return ok;
    }

    final items = <_SettingsSummaryData>[
      _SettingsSummaryData(
        title: 'อุปกรณ์ที่ลงทะเบียน',
        value: value(summary?.devicesCount),
        detail: detail(
          summary == null || summary.devicesCount == 0
              ? 'ยังไม่มีอุปกรณ์ในระบบ'
              : 'ออนไลน์ ${summary.devicesOnline} เครื่อง',
        ),
        icon: Icons.memory_rounded,
        color: SchoolAdminPalette.primaryDark,
      ),
      _SettingsSummaryData(
        title: 'อาคาร',
        value: value(summary?.buildingsCount),
        detail: detail(
          summary == null
              ? _noData
              : 'มีห้องทั้งหมด ${summary.roomsCount} ห้อง',
        ),
        icon: Icons.apartment_rounded,
        color: SchoolAdminPalette.secondary,
      ),
      _SettingsSummaryData(
        title: 'ผู้ใช้งานในระบบ',
        value: value(
          summary == null
              ? null
              : summary.studentsCount + summary.teachersCount,
        ),
        detail: detail(
          summary == null
              ? _noData
              : 'นักเรียน ${summary.studentsCount} · ครู ${summary.teachersCount}',
        ),
        icon: Icons.groups_rounded,
        color: SchoolAdminPalette.green,
      ),
      _SettingsSummaryData(
        title: 'การแจ้งเตือนค้างอยู่',
        value: value(summary?.openAlertsCount),
        detail: detail(
          summary == null || summary.openAlertsCount == 0
              ? 'ไม่มีรายการค้าง'
              : 'ยังไม่ได้ปิดเรื่อง',
        ),
        icon: Icons.notifications_active_rounded,
        color: SchoolAdminPalette.yellow,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;
        if (constraints.maxWidth < 1050) columns = 2;
        if (constraints.maxWidth < 300) columns = 1;

        const double spacing = 12;
        final double width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(width: width, child: _SettingsSummaryCard(data: item)),
          ],
        );
      },
    );
  }

  Widget _buildSchoolInfo() {
    final Widget body;
    if (_summaryPhase == _LoadPhase.loading) {
      body = const _LoadingBlock(label: 'กำลังโหลดข้อมูลโรงเรียน…');
    } else if (_summaryPhase == _LoadPhase.error) {
      body = _ErrorBlock(
        message: 'โหลดข้อมูลโรงเรียนไม่สำเร็จ',
        onRetry: _loadSummary,
      );
    } else {
      final summary = _summary;
      final name = (summary?.schoolName ?? '').trim();
      final code = (summary?.schoolCode ?? '').trim();
      body = Column(
        children: [
          _ReadOnlyRow(
            icon: Icons.school_rounded,
            label: 'ชื่อโรงเรียน',
            value: name.isEmpty ? _noData : name,
          ),
          const SizedBox(height: 9),
          _ReadOnlyRow(
            icon: Icons.tag_rounded,
            label: 'รหัสโรงเรียน',
            value: code.isEmpty ? _noData : code,
          ),
        ],
      );
    }

    return _SettingsSectionCard(
      title: 'ข้อมูลโรงเรียน',
      // ของเดิมมีช่องกรอก 6 ช่อง (ชื่อ รหัส ผู้อำนวยการ อีเมล เบอร์โทร ที่อยู่)
      // + ปุ่มเปลี่ยนโลโก้ ทั้งหมดตั้งค่าเริ่มต้นเป็นข้อมูลสมมติ
      // ("โรงเรียนตัวอย่าง AIoT Smart Lab", "นางสาวสุภาวดี ใจดี",
      // "admin@school.ac.th", "02-000-0000", ที่อยู่ปลอม) และปุ่มบันทึกที่
      // เขียนแค่ log ในหน่วยความจำ ตอนนี้เหลือเฉพาะสองค่าที่ RPC คืนมาจริง
      // และเป็นอ่านอย่างเดียว เพราะการแก้ไขตาราง schools ทำได้เฉพาะ
      // super_admin (update_school_for_super_admin)
      subtitle:
          'ข้อมูลจาก get_school_admin_dashboard_summary — แก้ไขได้เฉพาะผู้ดูแลระบบส่วนกลางเท่านั้น',
      child: body,
    );
  }

  Widget _buildUtilityRates() {
    final Widget body;
    if (_ratesPhase == _LoadPhase.loading) {
      body = const _LoadingBlock(label: 'กำลังโหลดอัตราค่าสาธารณูปโภค…');
    } else if (_ratesPhase == _LoadPhase.error) {
      body = _ErrorBlock(
        message: 'โหลดอัตราค่าไฟฟ้าและค่าน้ำไม่สำเร็จ',
        onRetry: _loadRates,
      );
    } else {
      final rates = _rates;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rates == null)
            const _NoticeRow(
              icon: Icons.info_outline_rounded,
              text:
                  'ยังไม่มีข้อมูลอัตราค่าสาธารณูปโภคของโรงเรียนนี้ กรอกค่าแล้วกดบันทึกเพื่อตั้งค่าครั้งแรก',
            )
          else if (rates.isElectricityDefault || rates.isWaterDefault)
            _NoticeRow(
              icon: Icons.info_outline_rounded,
              text: rates.isElectricityDefault && rates.isWaterDefault
                  ? 'โรงเรียนนี้ยังไม่ได้ตั้งอัตราเอง ระบบใช้ค่ากลางอยู่'
                  : (rates.isElectricityDefault
                        ? 'อัตราค่าไฟฟ้ายังไม่ได้ตั้งเอง ระบบใช้ค่ากลางอยู่'
                        : 'อัตราค่าน้ำยังไม่ได้ตั้งเอง ระบบใช้ค่ากลางอยู่'),
            ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool oneColumn = constraints.maxWidth < 620;
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
                      controller: _electricityController,
                      enabled: !_savingRates,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'อัตราค่าไฟฟ้า (บาท/หน่วย)',
                        prefixIcon: Icon(Icons.bolt_rounded),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: TextField(
                      controller: _waterController,
                      enabled: !_savingRates,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'อัตราค่าน้ำ (บาท/ลูกบาศก์เมตร)',
                        prefixIcon: Icon(Icons.water_drop_rounded),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 12),
            _InlineError(message: _saveError!),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _savingRates ? null : _saveRates,
              icon: _savingRates
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 17),
              label: Text(
                _savingRates ? 'กำลังบันทึก…' : 'บันทึกอัตราค่าสาธารณูปโภค',
              ),
            ),
          ),
        ],
      );
    }

    return _SettingsSectionCard(
      title: 'อัตราค่าไฟฟ้าและค่าน้ำ',
      subtitle:
          'ค่าเดียวในหน้านี้ที่บันทึกลงฐานข้อมูลจริง (ตาราง school_settings) '
          'ใช้คำนวณค่าใช้จ่ายในหน้าการใช้ทรัพยากร',
      child: body,
    );
  }

  /// ทุกอย่างที่ไม่มี backend รวมไว้ที่เดียว ปิดการใช้งานพร้อมเหตุผล
  /// ตาม DoD: ปุ่มที่ไม่มี backend ต้อง disable ไม่ใช่กดแล้วขึ้นข้อความขอโทษ
  Widget _buildUnavailableSettings() {
    return const _SettingsSectionCard(
      title: 'การตั้งค่าที่ยังไม่เปิดใช้งาน',
      subtitle:
          'รายการต่อไปนี้ยังไม่มีที่เก็บค่าในฐานข้อมูลของโรงเรียน จึงปิดไว้แทนการทำเป็นสวิตช์ที่กดได้แล้วไม่ถูกบันทึก',
      child: Column(
        children: [
          _UnavailableRow(
            icon: Icons.calendar_month_rounded,
            title: 'ปีการศึกษา ภาคเรียน ภาษา เขตเวลา และรูปแบบวันที่',
            reason: 'ระบบยังไม่เก็บค่าเหล่านี้แยกรายโรงเรียน',
          ),
          SizedBox(height: 9),
          _UnavailableRow(
            icon: Icons.notifications_rounded,
            title: 'การตั้งค่าการแจ้งเตือนทั้งหมด',
            reason: 'ยังไม่มีตารางเก็บเงื่อนไขการแจ้งเตือนของโรงเรียน',
          ),
          SizedBox(height: 9),
          _UnavailableRow(
            icon: Icons.security_rounded,
            title: 'รหัสผ่าน ออกจากระบบอัตโนมัติ และการยืนยันสองขั้นตอน',
            reason: 'เป็นค่าระดับแพลตฟอร์มที่ผู้ดูแลระบบส่วนกลางดูแล',
          ),
          SizedBox(height: 9),
          _UnavailableRow(
            icon: Icons.upload_file_rounded,
            title: 'สิทธิ์นำเข้า/ส่งออก และการสำรองข้อมูล',
            reason: 'ยังไม่มีคำสั่งเปิด-ปิดสิทธิ์หรือสั่งสำรองข้อมูลในระบบ',
          ),
          SizedBox(height: 9),
          _UnavailableRow(
            icon: Icons.lock_reset_rounded,
            title: 'บังคับออกจากระบบทุกบัญชี และคืนค่าการตั้งค่า',
            reason: 'ไม่มีคำสั่งฝั่งเซิร์ฟเวอร์รองรับ',
          ),
          SizedBox(height: 9),
          _UnavailableRow(
            icon: Icons.card_membership_rounded,
            title: 'แพ็กเกจ วันหมดอายุ และโควตาผู้ใช้/อุปกรณ์',
            reason: 'ข้อมูลสิทธิ์การใช้งานเปิดให้เฉพาะผู้ดูแลระบบส่วนกลาง',
          ),
        ],
      ),
    );
  }

  Widget _buildLogs() {
    final Widget body;
    if (_logsPhase == _LoadPhase.loading) {
      body = const _LoadingBlock(label: 'กำลังโหลดประวัติการแก้ไขการตั้งค่า…');
    } else if (_logsPhase == _LoadPhase.error) {
      body = _ErrorBlock(
        message: 'โหลดประวัติการแก้ไขการตั้งค่าไม่สำเร็จ',
        onRetry: _loadLogs,
      );
    } else if (_logs.isEmpty) {
      body = const _EmptyBlock(title: 'ยังไม่มีประวัติการแก้ไขการตั้งค่า');
    } else {
      body = Column(
        children: [
          for (final log in _logs.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _SettingsLogRow(log: log),
            ),
        ],
      );
    }

    return _SettingsSectionCard(
      title: 'Log การเปลี่ยนการตั้งค่า',
      subtitle:
          'บันทึกจริงจาก list_school_admin_audit_logs — ของเดิมเป็นรายการที่หน้าเพจแต่งขึ้นเองตอนกดปุ่ม',
      child: body,
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

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

class _SettingsSummaryCard extends StatelessWidget {
  const _SettingsSummaryCard({required this.data});

  final _SettingsSummaryData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 240;

        final Widget icon = _SettingsIconBox(
          icon: data.icon,
          color: data.color,
        );
        // ค่าตัวใหญ่ต้องสั้นเสมอ (ตัวเลขหรือ "—") ข้อความอธิบายไปอยู่บรรทัด
        // detail — ข้อความไทยยาว ๆ ในช่องนี้ทำการ์ดล้นความสูง
        final Widget value = Text(
          data.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: SchoolAdminPalette.textPrimary,
          ),
        );
        final Widget title = Text(
          data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: SchoolAdminPalette.textPrimary,
          ),
        );
        final Widget detail = Text(
          data.detail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            color: SchoolAdminPalette.textSecondary,
          ),
        );

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
                    icon,
                    const SizedBox(height: 10),
                    value,
                    const SizedBox(height: 5),
                    title,
                    const SizedBox(height: 3),
                    detail,
                  ],
                )
              : Row(
                  children: [
                    icon,
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          value,
                          const SizedBox(height: 5),
                          title,
                          const SizedBox(height: 3),
                          detail,
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
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
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
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: SchoolAdminPalette.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: SchoolAdminPalette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: value == 'ยังไม่มีข้อมูล'
                    ? SchoolAdminPalette.textMuted
                    : SchoolAdminPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableRow extends StatelessWidget {
  const _UnavailableRow({
    required this.icon,
    required this.title,
    required this.reason,
  });

  final IconData icon;
  final String title;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: SchoolAdminPalette.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: SchoolAdminPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SchoolAdminPalette.border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ปิดใช้งาน',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SchoolAdminPalette.sandSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SchoolAdminPalette.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SchoolAdminPalette.redSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3C9C2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: SchoolAdminPalette.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: SchoolAdminPalette.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: SchoolAdminPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: SchoolAdminPalette.textSecondary,
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SchoolAdminPalette.redSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3C9C2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: SchoolAdminPalette.red,
            size: 26,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: SchoolAdminPalette.red,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => onRetry(),
            style: OutlinedButton.styleFrom(
              foregroundColor: SchoolAdminPalette.red,
              side: const BorderSide(color: SchoolAdminPalette.red),
            ),
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }
}

class _SettingsLogRow extends StatelessWidget {
  const _SettingsLogRow({required this.log});

  final SchoolAdminAuditLog log;

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final time =
        '${_two(log.createdAt.hour)}:${_two(log.createdAt.minute)} น.';
    final action = log.action.trim().isEmpty ? 'ยังไม่มีข้อมูล' : log.action;
    final detail = log.detail.trim().isNotEmpty
        ? log.detail
        : (log.target.trim().isNotEmpty ? log.target : 'ยังไม่มีข้อมูล');
    final actor = log.actorName.trim().isEmpty
        ? 'ยังไม่มีข้อมูล'
        : log.actorName;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.history_rounded,
            size: 18,
            color: SchoolAdminPalette.textMuted,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: SchoolAdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'โดย $actor • $time',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: SchoolAdminPalette.textMuted,
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
