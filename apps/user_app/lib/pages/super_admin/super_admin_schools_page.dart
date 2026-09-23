import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/web_download.dart';
import 'theme/app_palette.dart';
import 'widgets/dev_ui.dart';

class SuperAdminSchoolsPage extends StatefulWidget {
  const SuperAdminSchoolsPage({
    super.key,
    this.loadSchools,
    this.createSchool,
    this.updateSchool,
    this.setSchoolStatus,
  });

  /// Injectable seams for tests — production leaves these null and uses the
  /// real service (same pattern as school_admin's connection tests).
  final Future<List<SchoolPlatformRecord>> Function()? loadSchools;
  final Future<Map<String, dynamic>> Function({
    required String name,
    String? province,
    String? adminEmail,
    String packageName,
    int maxUsers,
    int maxDevices,
    DateTime? licenseExpiresAt,
  })?
  createSchool;
  final Future<bool> Function({
    required String schoolId,
    required String name,
    String? province,
    String? adminEmail,
    String? packageName,
    int? maxUsers,
    int? maxDevices,
    DateTime? licenseExpiresAt,
  })?
  updateSchool;
  final Future<bool> Function({required String schoolId, required String status})?
  setSchoolStatus;

  @override
  State<SuperAdminSchoolsPage> createState() => _SuperAdminSchoolsPageState();
}

typedef SchoolsPage = SuperAdminSchoolsPage;

/// Sentinel value for "all packages" filter. Using a space prefix ensures it
/// never collides with actual package names from the database.
const String _allPackagesValue = ' all';

class _SuperAdminSchoolsPageState extends State<SuperAdminSchoolsPage> {
  final TextEditingController _searchController = TextEditingController();

  final SchoolAdminPlatformService _service = SchoolAdminPlatformService();

  String _statusFilter = 'ทั้งหมด';
  String _packageFilter = _allPackagesValue;

  final List<_SchoolData> _schools = <_SchoolData>[];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void didUpdateWidget(SuperAdminSchoolsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loadSchools != oldWidget.loadSchools) {
      _loadSchools();
    }
  }

  Future<void> _loadSchools({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final List<SchoolPlatformRecord> records =
          await (widget.loadSchools ?? _service.fetchSchools)();

      if (!mounted) {
        return;
      }

      setState(() {
        _schools
          ..clear()
          ..addAll(records.map(_SchoolData.fromRecord));

        final Set<String> availablePackages = _schools
            .map((s) => s.packageName.trim())
            .where((p) => p.isNotEmpty)
            .toSet();

        if (_packageFilter != _allPackagesValue &&
            !availablePackages.contains(_packageFilter)) {
          _packageFilter = _allPackagesValue;
        }

        _isLoading = false;
        _loadError = null;
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = '${error.message}\nรหัส: ${error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _packageFilterOptions {
    final Set<String> packages = _schools
        .map((s) => s.packageName.trim())
        .where((p) => p.isNotEmpty)
        .toSet();
    final List<String> sorted = packages.toList()..sort();
    return <String>[_allPackagesValue, ...sorted];
  }

  List<_SchoolData> get _filteredSchools {
    final String query = _searchController.text.trim().toLowerCase();

    return _schools.where((school) {
      final bool matchesSearch =
          query.isEmpty ||
          school.name.toLowerCase().contains(query) ||
          school.id.toLowerCase().contains(query) ||
          school.province.toLowerCase().contains(query) ||
          school.adminEmail.toLowerCase().contains(query);

      final bool matchesPackage =
          _packageFilter == _allPackagesValue ||
          !_packageFilterOptions.contains(_packageFilter) ||
          school.packageName.trim() == _packageFilter;

      bool matchesStatus = true;

      if (_statusFilter == 'เปิดใช้งาน') {
        matchesStatus = school.status == _SchoolStatus.active;
      } else if (_statusFilter == 'ระงับใช้งาน') {
        matchesStatus = school.status == _SchoolStatus.suspended;
      } else if (_statusFilter == 'ใกล้หมดอายุ') {
        matchesStatus =
            school.licenseDaysLeft > 0 && school.licenseDaysLeft <= 7;
      } else if (_statusFilter == 'ต้องตรวจสอบ') {
        matchesStatus = school.needsAttention;
      }

      return matchesSearch && matchesPackage && matchesStatus;
    }).toList();
  }

  int get _activeSchoolCount =>
      _schools.where((school) => school.status == _SchoolStatus.active).length;

  int get _suspendedSchoolCount =>
      _schools
          .where((school) => school.status == _SchoolStatus.suspended)
          .length;

  int get _expiringSchoolCount =>
      _schools
          .where(
            (school) =>
                school.licenseDaysLeft > 0 && school.licenseDaysLeft <= 7,
          )
          .length;

  int get _totalUsers => _schools.fold(0, (sum, school) => sum + school.users);

  int get _totalDevices =>
      _schools.fold(0, (sum, school) => sum + school.devicesTotal);

  int get _onlineDevices =>
      _schools.fold(0, (sum, school) => sum + school.devicesOnline);

  int get _totalAlerts =>
      _schools.fold(0, (sum, school) => sum + school.alerts);

  // This page has no `embedded` toggle of its own — it's placed directly
  // inside SuperAdminNavigationShell's desktop sidebar (which provides a
  // Material ancestor via its own Scaffold) but is also pushed as a
  // standalone route from SuperAdminHubPage's mobile fallback via
  // `Navigator.push(MaterialPageRoute(builder: (_) => const
  // SuperAdminSchoolsPage()))`, which does not wrap its child in a
  // Scaffold/Material. Without this, the package/status filter
  // DropdownButtons throw `debugCheckHasMaterial` the moment they render —
  // a real crash on any narrow-width Super Admin session, not just a test
  // artifact. A bare Scaffold is enough; it doesn't change the page's
  // visuals (already fully colored via ColoredBox) or add an AppBar,
  // since none was ever shown here.
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading && _schools.isEmpty) {
      return const ColoredBox(
        color: AppPalette.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(color: AppPalette.deepBlue),
              SizedBox(height: 14),
              Text(
                'กำลังโหลดข้อมูลโรงเรียนจาก Supabase...',
                style: TextStyle(color: AppPalette.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null && _schools.isEmpty) {
      return ColoredBox(
        color: AppPalette.background,
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: AppPalette.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: AppPalette.carnivalRed,
                      size: 52,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'โหลดข้อมูลโรงเรียนไม่สำเร็จ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _loadSchools,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final List<_SchoolData> filteredSchools = _filteredSchools;

    return ColoredBox(
      color: AppPalette.background,
      child: Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: () => _loadSchools(showLoading: false),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: <Widget>[
                _buildHeroCard(),
                const SizedBox(height: 18),
                _buildSummaryCards(),
                const SizedBox(height: 18),
                _buildPrioritySection(),
                const SizedBox(height: 18),
                _buildSearchAndFilterPanel(),
                const SizedBox(height: 18),
                _buildSchoolListSection(filteredSchools),
                const SizedBox(height: 18),
                _buildPackageAndCapacitySection(),
              ],
            ),
          ),
          if (_isSaving)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.10),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppPalette.deepBlue,
                            ),
                          ),
                          SizedBox(width: 14),
                          Text(
                            'กำลังบันทึกข้อมูล...',
                            style: TextStyle(
                              color: AppPalette.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // การ์ดหลักด้านบน
  // ===========================================================================

  Widget _buildHeroCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 270),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.deepBlue, Color(0xFF1676B5)],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppPalette.deepBlue.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            Positioned(
              top: -85,
              right: -65,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -55,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: AppPalette.circusYellow.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isMobile = constraints.maxWidth < 720;

                  final Widget textContent = Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.circusYellow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'ศูนย์จัดการโรงเรียน',
                          style: TextStyle(
                            color: AppPalette.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'จัดการโรงเรียน\nในระบบทั้งหมด',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 25 : 34,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'เพิ่มโรงเรียน แก้ไขข้อมูล ตรวจสอบอุปกรณ์ '
                        'จัดการแพ็กเกจ ใบอนุญาต และเข้าสู่โหมดช่วยเหลือได้จากหน้าเดียว',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: isMobile ? 12 : 14,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 17),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _heroStatusChip(
                            icon: Icons.apartment_rounded,
                            label: '$_activeSchoolCount โรงเรียนกำลังใช้งาน',
                          ),
                          _heroStatusChip(
                            icon: Icons.warning_amber_rounded,
                            label: '$_expiringSchoolCount แห่งใกล้หมดอายุ',
                          ),
                        ],
                      ),
                      const SizedBox(height: 19),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _openSchoolForm(),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppPalette.circusYellow,
                              foregroundColor: AppPalette.textPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 17,
                                vertical: 13,
                              ),
                            ),
                            icon: const Icon(
                              Icons.add_business_rounded,
                              size: 19,
                            ),
                            label: const Text(
                              'สร้างโรงเรียนใหม่',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _exportSchoolReport,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 17,
                                vertical: 13,
                              ),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 19),
                            label: const Text(
                              'ส่งออกรายงาน',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );

                  final Widget visual = Container(
                    width: isMobile ? double.infinity : 310,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppPalette.softBeige),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            _heroMetric(
                              title: 'โรงเรียนทั้งหมด',
                              value: '${_schools.length}',
                              icon: Icons.apartment_rounded,
                            ),
                            const SizedBox(width: 10),
                            _heroMetric(
                              title: 'อุปกรณ์ออนไลน์',
                              value: '$_onlineDevices',
                              icon: Icons.wifi_tethering_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _heroMetric(
                              title: 'ผู้ใช้งาน',
                              value: '$_totalUsers',
                              icon: Icons.people_alt_rounded,
                            ),
                            const SizedBox(width: 10),
                            _heroMetric(
                              title: 'แจ้งเตือน',
                              value: '$_totalAlerts',
                              icon: Icons.notifications_active_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        textContent,
                        const SizedBox(height: 18),
                        visual,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: textContent),
                      const SizedBox(width: 24),
                      visual,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStatusChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMetric({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppPalette.deepBlue.withValues(alpha: 0.10),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppPalette.circusYellow.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppPalette.deepBlue, size: 19),
            ),
            const SizedBox(height: 11),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppPalette.deepBlue,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // การ์ดสรุป
  // ===========================================================================

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 1100 ? 4 : 2;
        const double spacing = 12;

        final double width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        final List<_SchoolSummaryCard> cards = [
          _SchoolSummaryCard(
            icon: Icons.verified_rounded,
            title: 'เปิดใช้งาน',
            value: '$_activeSchoolCount',
            detail: 'พร้อมให้บริการตามปกติ',
            color: AppPalette.gardenGreen,
          ),
          _SchoolSummaryCard(
            icon: Icons.pause_circle_rounded,
            title: 'ระงับใช้งาน',
            value: '$_suspendedSchoolCount',
            detail: 'รอตรวจสอบหรือต่ออายุ',
            color: AppPalette.carnivalRed,
          ),
          _SchoolSummaryCard(
            icon: Icons.workspace_premium_rounded,
            title: 'ใกล้หมดอายุ',
            value: '$_expiringSchoolCount',
            detail: 'เหลือเวลาไม่เกิน 7 วัน',
            color: AppPalette.circusYellow,
          ),
          _SchoolSummaryCard(
            icon: Icons.devices_rounded,
            title: 'อุปกรณ์ทั้งหมด',
            value: '$_totalDevices',
            detail: 'ออนไลน์ $_onlineDevices เครื่อง',
            color: AppPalette.deepBlue,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              cards.map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }

  // ===========================================================================
  // ส่วนที่ควรจัดการก่อน
  // ===========================================================================

  Widget _buildPrioritySection() {
    final List<_SchoolData> prioritySchools =
        _schools.where((school) => school.needsAttention).toList()
          ..sort((a, b) => a.priorityScore.compareTo(b.priorityScore));

    return AppPanel(
      title: 'รายการที่ควรจัดการก่อน',
      trailing: StatusBadge(
        label: '${prioritySchools.length} โรงเรียน',
        color: AppPalette.carnivalRed,
      ),
      child:
          prioritySchools.isEmpty
              ? const _EmptyState(
                icon: Icons.task_alt_rounded,
                title: 'ไม่มีรายการเร่งด่วน',
                subtitle: 'ทุกโรงเรียนทำงานได้ตามปกติ',
              )
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (
                    int index = 0;
                    index < prioritySchools.length && index < 4;
                    index++
                  ) ...[
                    _buildPriorityTile(prioritySchools[index]),
                    if (index < prioritySchools.length.clamp(0, 4) - 1)
                      const Divider(height: 24),
                  ],
                ],
              ),
    );
  }

  Widget _buildPriorityTile(_SchoolData school) {
    final Color color =
        school.status == _SchoolStatus.suspended
            ? AppPalette.carnivalRed
            : school.licenseDaysLeft == 0
            ? AppPalette.carnivalRed
            : school.licenseDaysLeft <= 7
            ? AppPalette.circusYellow
            : AppPalette.deepBlue;

    final String issue =
        school.status == _SchoolStatus.suspended
            ? 'โรงเรียนถูกระงับการใช้งาน'
            : school.licenseDaysLeft == 0
            ? 'แพ็กเกจหมดอายุ'
            : school.licenseDaysLeft <= 7
            ? 'ใบอนุญาตเหลือ ${school.licenseDaysLeft} วัน'
            : '${school.devicesOffline} อุปกรณ์ออฟไลน์';

    final bool canSendSuspensionWarning =
        school.status == _SchoolStatus.active &&
        school.licenseDaysLeft > 0 &&
        school.licenseDaysLeft <= 7;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSchoolDetails(school),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  school.status == _SchoolStatus.suspended
                      ? Icons.block_rounded
                      : school.licenseDaysLeft <= 7
                      ? Icons.workspace_premium_rounded
                      : Icons.portable_wifi_off_rounded,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
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
                    const SizedBox(height: 5),
                    Text(
                      '${school.id} • ${school.province} • ${school.packageName}',
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      issue,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (canSendSuspensionWarning) ...[
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              _sendSuspensionWarningEmail(school);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  school.reminderSent
                                      ? AppPalette.gardenGreen
                                      : AppPalette.deepBlue,
                              side: BorderSide(
                                color:
                                    school.reminderSent
                                        ? AppPalette.gardenGreen
                                        : AppPalette.deepBlue,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: Icon(
                              school.reminderSent
                                  ? Icons.mark_email_read_rounded
                                  : Icons.outgoing_mail,
                              size: 17,
                            ),
                            label: Text(
                              school.reminderSent
                                  ? 'เปิดอีเมลแล้ว'
                                  : 'ส่งอีเมลแจ้งเตือน',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            school.reminderSent
                                ? 'ส่งล่าสุด ${school.reminderSentLabel}'
                                : 'แจ้งก่อนถูกระงับไม่เกิน 1 สัปดาห์',
                            style: const TextStyle(
                              color: AppPalette.textSecondary,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendSuspensionWarningEmail(_SchoolData school) async {
    final DateTime suspensionDate = DateTime.now().add(
      Duration(days: school.licenseDaysLeft),
    );

    final String suspensionDateText = _formatThaiDate(suspensionDate);

    final String subject =
        'แจ้งเตือนก่อนระงับการใช้งาน AIoT Smart Lab - ${school.name}';

    final String body = '''
เรียน ผู้ดูแล ${school.name}

ขอแจ้งเตือนว่าสิทธิ์การใช้งานระบบ AIoT Smart Lab ของโรงเรียนจะหมดอายุภายใน ${school.licenseDaysLeft} วัน และบัญชีอาจถูกระงับการใช้งานตั้งแต่วันที่ $suspensionDateText เป็นต้นไป

ข้อมูลโรงเรียน
- รหัสโรงเรียน: ${school.id}
- แพ็กเกจ: ${school.packageName}
- อีเมลผู้ดูแล: ${school.adminEmail}

กรุณาติดต่อผู้ดูแลระบบเพื่อดำเนินการต่ออายุสิทธิ์ก่อนวันดังกล่าว เพื่อให้การใช้งานระบบและอุปกรณ์เป็นไปอย่างต่อเนื่อง

ขอบคุณ
ทีมดูแลระบบ AIoT Smart Lab
''';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: school.adminEmail,
      queryParameters: <String, String>{'subject': subject, 'body': body},
    );

    try {
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.platformDefault,
      );

      if (!mounted) {
        return;
      }

      if (!launched) {
        _showMessage(
          'ไม่สามารถเปิดโปรแกรมอีเมลได้ กรุณาตรวจสอบแอปอีเมลในเครื่อง',
        );
        return;
      }

      setState(() {
        school.reminderSent = true;
        school.reminderSentAt = DateTime.now();
      });

      _showMessage('เปิดอีเมลแจ้งเตือนสำหรับ ${school.name} แล้ว');
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'เปิดอีเมลไม่สำเร็จ กรุณาตรวจสอบโปรแกรมอีเมลหรือเบราว์เซอร์',
      );
    }
  }

  String _formatThaiDate(DateTime date) {
    const List<String> months = <String>[
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }

  // ===========================================================================
  // ค้นหาและตัวกรอง
  // ===========================================================================

  Widget _buildSearchAndFilterPanel() {
    return AppPanel(
      title: 'ค้นหาและกรองโรงเรียน',
      trailing: TextButton.icon(
        onPressed: _clearFilters,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('ล้างตัวกรอง'),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'ค้นหาชื่อโรงเรียน รหัส จังหวัด หรืออีเมลผู้ดูแล',
              suffixIcon:
                  _searchController.text.isEmpty
                      ? null
                      : IconButton(
                        tooltip: 'ล้างคำค้นหา',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
            ),
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isMobile = constraints.maxWidth < 650;

              final Widget statusFilter = _filterDropdown(
                label: 'สถานะ',
                value: _statusFilter,
                items: const [
                  'ทั้งหมด',
                  'เปิดใช้งาน',
                  'ระงับใช้งาน',
                  'ใกล้หมดอายุ',
                  'ต้องตรวจสอบ',
                ],
                onChanged: (value) {
                  setState(() {
                    _statusFilter = value;
                  });
                },
              );

              final List<String> filterOptions = _packageFilterOptions;
              final String effectiveFilter =
                  filterOptions.contains(_packageFilter)
                      ? _packageFilter
                      : _allPackagesValue;

              if (_packageFilter != effectiveFilter) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _packageFilter != effectiveFilter) {
                    setState(() {
                      _packageFilter = effectiveFilter;
                    });
                  }
                });
              }

              final Widget packageFilter = _filterDropdown(
                label: 'แพ็กเกจ',
                value: effectiveFilter,
                items: filterOptions,
                onChanged: (value) {
                  setState(() {
                    _packageFilter = value;
                  });
                },
              );

              if (isMobile) {
                return Column(
                  children: [
                    statusFilter,
                    const SizedBox(height: 10),
                    packageFilter,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: statusFilter),
                  const SizedBox(width: 12),
                  Expanded(child: packageFilter),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final String effectiveValue =
        items.contains(value) ? value : (items.isNotEmpty ? items.first : value);

    String _getDisplayText(String val) =>
        val == _allPackagesValue ? 'ทุกแพ็กเกจ' : val;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          label == 'สถานะ'
              ? Icons.filter_alt_rounded
              : Icons.workspace_premium_rounded,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isDense: true,
          isExpanded: true,
          items:
              items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(_getDisplayText(item)),
                    ),
                  )
                  .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _statusFilter = 'ทั้งหมด';
      _packageFilter = _allPackagesValue;
    });
  }

  // ===========================================================================
  // รายการโรงเรียน
  // ===========================================================================

  Widget _buildSchoolListSection(List<_SchoolData> filteredSchools) {
    return AppPanel(
      title: 'รายการโรงเรียน',
      trailing: Text(
        'พบ ${filteredSchools.length} รายการ',
        style: const TextStyle(
          color: AppPalette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      child:
          filteredSchools.isEmpty
              ? const _EmptyState(
                icon: Icons.search_off_rounded,
                title: 'ไม่พบโรงเรียน',
                subtitle: 'ลองเปลี่ยนคำค้นหาหรือตัวกรองอีกครั้ง',
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = constraints.maxWidth >= 1050 ? 2 : 1;
                  const double spacing = 14;

                  final double width =
                      (constraints.maxWidth - (spacing * (columns - 1))) /
                      columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children:
                        filteredSchools
                            .map(
                              (school) => SizedBox(
                                width: width,
                                child: _buildSchoolCard(school),
                              ),
                            )
                            .toList(),
                  );
                },
              ),
    );
  }

  Widget _buildSchoolCard(_SchoolData school) {
    final Color statusColor =
        school.status == _SchoolStatus.active
            ? AppPalette.gardenGreen
            : AppPalette.carnivalRed;

    final String statusText =
        school.status == _SchoolStatus.active ? 'เปิดใช้งาน' : 'ระงับใช้งาน';

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color:
              school.needsAttention
                  ? AppPalette.circusYellow.withValues(alpha: 0.58)
                  : AppPalette.softBeige.withValues(alpha: 0.70),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: AppPalette.deepBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppPalette.deepBlue,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${school.id} • ${school.province}',
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'ตัวเลือกเพิ่มเติม',
                onSelected: (action) {
                  if (action == 'edit') {
                    _openSchoolForm(school: school);
                  } else if (action == 'toggle') {
                    _confirmToggleSchoolStatus(school);
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_rounded),
                          title: Text('แก้ไขข้อมูล'),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            school.status == _SchoolStatus.active
                                ? Icons.pause_circle_rounded
                                : Icons.play_circle_rounded,
                          ),
                          title: Text(
                            school.status == _SchoolStatus.active
                                ? 'ระงับการใช้งาน'
                                : 'เปิดใช้งาน',
                          ),
                        ),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(label: statusText, color: statusColor),
              StatusBadge(
                label: 'แพ็กเกจ ${school.packageName}',
                color: AppPalette.deepBlue,
              ),
              if (school.licenseDaysLeft <= 7)
                StatusBadge(
                  label:
                      school.licenseDaysLeft == 0
                          ? 'แพ็กเกจหมดอายุ'
                          : 'เหลือ ${school.licenseDaysLeft} วัน',
                  color:
                      school.licenseDaysLeft == 0
                          ? AppPalette.carnivalRed
                          : AppPalette.circusYellow,
                ),
              if (school.alerts > 0)
                StatusBadge(
                  label: '${school.alerts} การแจ้งเตือน',
                  color: AppPalette.carnivalRed,
                ),
            ],
          ),
          const SizedBox(height: 17),
          _buildCapacityProgress(
            title: 'ผู้ใช้งาน',
            value: school.users,
            maxValue: school.maxUsers,
            color: AppPalette.deepBlue,
          ),
          const SizedBox(height: 12),
          _buildCapacityProgress(
            title: 'อุปกรณ์ที่ลงทะเบียน',
            value: school.devicesTotal,
            maxValue: school.maxDevices,
            color: AppPalette.gardenGreen,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppPalette.softBeige.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _schoolMetric(
                    label: 'อุปกรณ์ออนไลน์',
                    value: '${school.devicesOnline}/${school.devicesTotal}',
                  ),
                ),
                Container(width: 1, height: 36, color: AppPalette.softBeige),
                Expanded(
                  child: _schoolMetric(
                    label: 'อาคาร / ห้อง',
                    value: '${school.buildings} / ${school.rooms}',
                  ),
                ),
                Container(width: 1, height: 36, color: AppPalette.softBeige),
                Expanded(
                  child: _schoolMetric(
                    label: 'ซิงก์ล่าสุด',
                    value: school.lastSync,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showSchoolDetails(school),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.deepBlue,
              ),
              icon: const Icon(Icons.visibility_rounded, size: 18),
              label: const Text('ดูรายละเอียด'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityProgress({
    required String title,
    required int value,
    required int maxValue,
    required Color color,
  }) {
    final double progress = maxValue <= 0 ? 0 : (value / maxValue).clamp(0, 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '$value / $maxValue',
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: progress,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _schoolMetric({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 8.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // สรุปแพ็กเกจและความจุระบบ
  // ===========================================================================

  Widget _buildPackageAndCapacitySection() {
    final Map<String, int> packageCounts = {
      'Basic': _schools
          .where((school) =>
              school.packageName == 'Basic' ||
              school.packageName.toLowerCase() == 'basic package')
          .length,
      'Pro': _schools
          .where((school) =>
              school.packageName == 'Pro' ||
              school.packageName.toLowerCase() == 'pro package')
          .length,
      'Enterprise': _schools
          .where((school) =>
              school.packageName == 'Enterprise' ||
              school.packageName.toLowerCase() == 'enterprise package')
          .length,
    };

    return ResponsiveWrap(
      desktopColumns: 2,
      tabletColumns: 1,
      children: [
        AppPanel(
          title: 'การใช้งานแพ็กเกจ',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _packageRow(
                name: 'Basic',
                count: packageCounts['Basic'] ?? 0,
                color: AppPalette.circusYellow,
              ),
              const Divider(height: 24),
              _packageRow(
                name: 'Pro',
                count: packageCounts['Pro'] ?? 0,
                color: AppPalette.deepBlue,
              ),
              const Divider(height: 24),
              _packageRow(
                name: 'Enterprise',
                count: packageCounts['Enterprise'] ?? 0,
                color: AppPalette.gardenGreen,
              ),
            ],
          ),
        ),
        AppPanel(
          title: 'ภาพรวมทรัพยากร',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _resourceRow(
                icon: Icons.people_alt_rounded,
                title: 'ผู้ใช้งานทั้งหมด',
                value: '$_totalUsers คน',
                subtitle: 'รวมทุกโรงเรียน',
                color: AppPalette.deepBlue,
              ),
              const Divider(height: 24),
              _resourceRow(
                icon: Icons.devices_rounded,
                title: 'อุปกรณ์ทั้งหมด',
                value: '$_totalDevices เครื่อง',
                subtitle: 'ออนไลน์ $_onlineDevices เครื่อง',
                color: AppPalette.gardenGreen,
              ),
              const Divider(height: 24),
              _resourceRow(
                icon: Icons.notifications_active_rounded,
                title: 'การแจ้งเตือนค้างอยู่',
                value: '$_totalAlerts รายการ',
                subtitle: 'ควรตรวจสอบและมอบหมายงาน',
                color: AppPalette.carnivalRed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _packageRow({
    required String name,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.workspace_premium_rounded, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'แพ็กเกจ $name',
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$count โรงเรียน',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _resourceRow({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ฟังก์ชันโต้ตอบ
  // ===========================================================================

  Future<void> _openSchoolForm({_SchoolData? school}) async {
    final bool isEditing = school != null;

    final TextEditingController nameController = TextEditingController(
      text: school?.name ?? '',
    );
    final TextEditingController provinceController = TextEditingController(
      text: school?.province ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: school?.adminEmail ?? '',
    );
    final TextEditingController usersController = TextEditingController(
      text: '${school?.maxUsers ?? 30}',
    );
    final TextEditingController devicesController = TextEditingController(
      text: '${school?.maxDevices ?? 30}',
    );
    final TextEditingController licenseController = TextEditingController(
      text: '${school?.licenseDaysLeft ?? 365}',
    );

    final String originalPackage = school?.packageName ?? 'Basic';
    String selectedPackage = originalPackage;

    const List<String> canonicalPackages = <String>[
      'Basic',
      'Pro',
      'Enterprise',
    ];

    final List<String> packageOptions = <String>[
      ...canonicalPackages,
      if (school != null && !canonicalPackages.contains(originalPackage))
        originalPackage,
    ];

    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<_SchoolFormResult>(
      context: context,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppPalette.deepBlue.withValues(
                              alpha: 0.12,
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: AppPalette.deepBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEditing
                                  ? 'แก้ไขข้อมูลโรงเรียน'
                                  : 'สร้างโรงเรียนใหม่',
                              style: const TextStyle(
                                color: AppPalette.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'ปิด',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อโรงเรียน',
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: provinceController,
                        decoration: const InputDecoration(
                          labelText: 'จังหวัด',
                          prefixIcon: Icon(Icons.location_on_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'อีเมลผู้ดูแลโรงเรียน',
                          prefixIcon: Icon(Icons.email_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: packageOptions.contains(selectedPackage)
                            ? selectedPackage
                            : packageOptions.first,
                        decoration: const InputDecoration(
                          labelText: 'แพ็กเกจ',
                          prefixIcon: Icon(Icons.workspace_premium_rounded),
                        ),
                        items: packageOptions
                            .map(
                              (pkg) => DropdownMenuItem<String>(
                                value: pkg,
                                child: Text(
                                  pkg.isEmpty ? 'ไม่ระบุแพ็กเกจ' : pkg,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedPackage = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final bool narrow = constraints.maxWidth < 520;

                          final Widget usersField = TextField(
                            controller: usersController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'จำนวนผู้ใช้สูงสุด',
                              prefixIcon: Icon(Icons.people_alt_rounded),
                            ),
                          );

                          final Widget devicesField = TextField(
                            controller: devicesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'จำนวนอุปกรณ์สูงสุด',
                              prefixIcon: Icon(Icons.devices_rounded),
                            ),
                          );

                          if (narrow) {
                            return Column(
                              children: [
                                usersField,
                                const SizedBox(height: 12),
                                devicesField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: usersField),
                              const SizedBox(width: 12),
                              Expanded(child: devicesField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: licenseController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'จำนวนวันคงเหลือของใบอนุญาต',
                          prefixIcon: Icon(Icons.event_available_rounded),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  () => Navigator.of(dialogContext).pop(),
                              child: const Text('ยกเลิก'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                final String name = nameController.text.trim();
                                final String province =
                                    provinceController.text.trim();
                                final String email =
                                    emailController.text.trim();

                                if (name.isEmpty ||
                                    province.isEmpty ||
                                    email.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'กรุณากรอกชื่อโรงเรียน จังหวัด และอีเมลให้ครบ',
                                        ),
                                      ),
                                    );
                                  return;
                                }

                                Navigator.of(dialogContext).pop(
                                  _SchoolFormResult(
                                    name: name,
                                    province: province,
                                    email: email,
                                    packageName: selectedPackage,
                                    maxUsers:
                                        int.tryParse(usersController.text) ??
                                        30,
                                    maxDevices:
                                        int.tryParse(devicesController.text) ??
                                        30,
                                    licenseDays:
                                        int.tryParse(licenseController.text) ??
                                        365,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.save_rounded),
                              label: Text(
                                isEditing ? 'บันทึกการแก้ไข' : 'สร้างโรงเรียน',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    final result = await navigator.push(route);
    // pop returns before the reverse transition removes the TextFields.
    // Keep their controllers alive until the dialog's overlay is unmounted.
    await route.completed;
    nameController.dispose();
    provinceController.dispose();
    emailController.dispose();
    usersController.dispose();
    devicesController.dispose();
    licenseController.dispose();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final DateTime licenseExpiresAt = DateTime.now().toUtc().add(
        Duration(days: result.licenseDays),
      );

      if (school == null) {
        await (widget.createSchool ?? _service.createSchool)(
          name: result.name,
          province: result.province,
          adminEmail: result.email,
          packageName: result.packageName,
          maxUsers: result.maxUsers,
          maxDevices: result.maxDevices,
          licenseExpiresAt: licenseExpiresAt,
        );
      } else {
        final bool ok = await (widget.updateSchool ?? _service.updateSchool)(
          schoolId: school.databaseId,
          name: result.name,
          province: result.province,
          adminEmail: result.email,
          packageName: result.packageName,
          maxUsers: result.maxUsers,
          maxDevices: result.maxDevices,
          licenseExpiresAt: licenseExpiresAt,
        );
        // updateSchool returns false (no thrown error) when the RPC ran but
        // did not apply — must not be reported as saved.
        if (!ok) {
          throw StateError('update_school_not_confirmed');
        }
      }

      await _loadSchools(showLoading: false);

      if (!mounted) {
        return;
      }

      _showMessage(
        school == null
            ? 'สร้างโรงเรียนใหม่ใน Supabase เรียบร้อยแล้ว'
            : 'บันทึกข้อมูลโรงเรียนใน Supabase เรียบร้อยแล้ว',
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('บันทึกไม่สำเร็จ: ${error.message}');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('บันทึกไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _confirmToggleSchoolStatus(_SchoolData school) async {
    final bool willSuspend = school.status == _SchoolStatus.active;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            willSuspend ? 'ระงับการใช้งานโรงเรียน' : 'เปิดใช้งานโรงเรียน',
          ),
          content: Text(
            willSuspend
                ? 'โรงเรียน ${school.name} จะไม่สามารถใช้งานระบบได้ชั่วคราว ต้องการดำเนินการต่อหรือไม่'
                : 'ต้องการเปิดใช้งานโรงเรียน ${school.name} อีกครั้งหรือไม่',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor:
                    willSuspend
                        ? AppPalette.carnivalRed
                        : AppPalette.gardenGreen,
              ),
              child: Text(willSuspend ? 'ระงับการใช้งาน' : 'เปิดใช้งาน'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String newStatus = willSuspend ? 'suspended' : 'active';

      final bool ok = await (widget.setSchoolStatus ?? _service.setSchoolStatus)(
        schoolId: school.databaseId,
        status: newStatus,
      );
      // Same as updateSchool: false means the RPC ran but did not confirm
      // the change, and must not be reported as success.
      if (!ok) {
        throw StateError('set_school_status_not_confirmed');
      }

      await _loadSchools(showLoading: false);

      if (!mounted) {
        return;
      }

      _showMessage(
        willSuspend
            ? 'ระงับการใช้งาน ${school.name} ใน Supabase แล้ว'
            : 'เปิดใช้งาน ${school.name} ใน Supabase แล้ว',
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('เปลี่ยนสถานะไม่สำเร็จ: ${error.message}');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('เปลี่ยนสถานะไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSchoolDetails(_SchoolData school) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.76,
          minChildSize: 0.48,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppPalette.softBeige,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 53,
                        height: 53,
                        decoration: BoxDecoration(
                          color: AppPalette.deepBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: AppPalette.deepBlue,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              school.name,
                              style: const TextStyle(
                                color: AppPalette.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${school.id} • ${school.province}',
                              style: const TextStyle(
                                color: AppPalette.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'ปิด',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _detailsSection(
                    title: 'ข้อมูลทั่วไป',
                    children: [
                      _detailRow('อีเมลผู้ดูแล', school.adminEmail),
                      _detailRow('แพ็กเกจ', school.packageName),
                      _detailRow(
                        'ใบอนุญาตคงเหลือ',
                        '${school.licenseDaysLeft} วัน',
                      ),
                      _detailRow('ซิงก์ข้อมูลล่าสุด', school.lastSync),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailsSection(
                    title: 'การใช้งานระบบ',
                    children: [
                      _detailRow(
                        'ผู้ใช้งาน',
                        '${school.users}/${school.maxUsers} คน',
                      ),
                      _detailRow(
                        'อุปกรณ์',
                        '${school.devicesTotal}/${school.maxDevices} เครื่อง',
                      ),
                      _detailRow(
                        'อุปกรณ์ออนไลน์',
                        '${school.devicesOnline} เครื่อง',
                      ),
                      _detailRow(
                        'อาคารและห้อง',
                        '${school.buildings} อาคาร • ${school.rooms} ห้อง',
                      ),
                      _detailRow('การแจ้งเตือน', '${school.alerts} รายการ'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _openSchoolForm(school: school);
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('แก้ไขข้อมูล'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppPalette.softBeige.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _csvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _exportSchoolReport() {
    final List<_SchoolData> schools = _filteredSchools;
    if (schools.isEmpty) {
      _showMessage('ไม่มีโรงเรียนให้ส่งออกตามตัวกรองปัจจุบัน');
      return;
    }

    final List<String> header = <String>[
      'school_id',
      'name',
      'province',
      'admin_email',
      'package',
      'users',
      'max_users',
      'devices_online',
      'devices_total',
      'buildings',
      'rooms',
      'open_alerts',
      'license_days_left',
      'status',
    ];
    final List<List<String>> rows = <List<String>>[
      header,
      for (final _SchoolData s in schools)
        <String>[
          s.id,
          s.name,
          s.province,
          s.adminEmail,
          s.packageName,
          '${s.users}',
          '${s.maxUsers}',
          '${s.devicesOnline}',
          '${s.devicesTotal}',
          '${s.buildings}',
          '${s.rooms}',
          '${s.alerts}',
          '${s.licenseDaysLeft}',
          s.status.name,
        ],
    ];
    final String csv = rows.map((row) => row.map(_csvField).join(',')).join('\r\n');

    downloadBytes(
      filename: 'schools_${DateTime.now().toIso8601String().split('T').first}.csv',
      bytes: utf8.encode('﻿$csv'),
      mimeType: 'text/csv',
    );

    _showMessage('ส่งออกรายงานโรงเรียน ${schools.length} รายการแล้ว');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

// =============================================================================
// Widget ย่อย
// =============================================================================

class _SchoolSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;

  const _SchoolSummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 165),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: AppPalette.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: AppPalette.softBeige.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: AppPalette.deepBlue.withValues(alpha: 0.10),
            child: Icon(icon, color: AppPalette.deepBlue, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
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

// =============================================================================
// View models (populated from SchoolPlatformRecord, see _SchoolData.fromRecord)
// =============================================================================

enum _SchoolStatus { active, suspended }

class _SchoolData {
  final String databaseId;
  final String id;

  String name;
  String province;
  String adminEmail;
  String packageName;

  int users;
  int maxUsers;
  int devicesOnline;
  int devicesTotal;
  int maxDevices;
  int buildings;
  int rooms;
  int alerts;
  int licenseDaysLeft;

  String lastSync;
  _SchoolStatus status;

  bool reminderSent = false;
  DateTime? reminderSentAt;

  _SchoolData({
    required this.databaseId,
    required this.id,
    required this.name,
    required this.province,
    required this.adminEmail,
    required this.packageName,
    required this.users,
    required this.maxUsers,
    required this.devicesOnline,
    required this.devicesTotal,
    required this.maxDevices,
    required this.buildings,
    required this.rooms,
    required this.alerts,
    required this.licenseDaysLeft,
    required this.lastSync,
    required this.status,
  });

  factory _SchoolData.fromRecord(SchoolPlatformRecord record) {
    final DateTime? lastSync = record.lastSyncAt;
    final String lastSyncStr = lastSync != null
        ? '${lastSync.day}/${lastSync.month} ${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}'
        : '-';

    return _SchoolData(
      databaseId: record.id,
      id: record.schoolCode,
      name: record.name,
      province: record.province,
      adminEmail: record.adminEmail,
      packageName: record.packageName,
      users: record.usersCount,
      maxUsers: record.maxUsers,
      devicesOnline: record.devicesOnline,
      devicesTotal: record.devicesTotal,
      maxDevices: record.maxDevices,
      buildings: record.buildingsCount,
      rooms: record.roomsCount,
      alerts: record.alertsCount,
      licenseDaysLeft: record.licenseDaysLeft,
      lastSync: lastSyncStr,
      status:
          record.status == 'suspended'
              ? _SchoolStatus.suspended
              : _SchoolStatus.active,
    );
  }

  int get devicesOffline => devicesTotal - devicesOnline;

  String get reminderSentLabel {
    final DateTime? sentAt = reminderSentAt;

    if (sentAt == null) {
      return '-';
    }

    final String hour = sentAt.hour.toString().padLeft(2, '0');

    final String minute = sentAt.minute.toString().padLeft(2, '0');

    return '${sentAt.day}/${sentAt.month}/${sentAt.year + 543} '
        '$hour:$minute น.';
  }

  bool get needsAttention =>
      status == _SchoolStatus.suspended ||
      licenseDaysLeft <= 7 ||
      devicesOffline >= 3 ||
      alerts >= 2;

  int get priorityScore {
    if (status == _SchoolStatus.suspended) {
      return 0;
    }

    if (licenseDaysLeft == 0) {
      return 1;
    }

    if (licenseDaysLeft <= 7) {
      return 2;
    }

    if (alerts >= 2) {
      return 3;
    }

    return 4;
  }
}

class _SchoolFormResult {
  final String name;
  final String province;
  final String email;
  final String packageName;
  final int maxUsers;
  final int maxDevices;
  final int licenseDays;

  const _SchoolFormResult({
    required this.name,
    required this.province,
    required this.email,
    required this.packageName,
    required this.maxUsers,
    required this.maxDevices,
    required this.licenseDays,
  });
}
