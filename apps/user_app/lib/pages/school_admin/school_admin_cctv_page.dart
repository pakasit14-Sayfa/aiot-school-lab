import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'controllers/school_admin_async_state.dart';
import 'controllers/school_admin_cctv_controller.dart';
import 'theme/school_admin_palette.dart';

class SchoolAdminCctvPage extends StatefulWidget {
  const SchoolAdminCctvPage({
    super.key,
    this.controller,
    this.initialGrants,
    this.initialUsers,
  });

  final SchoolAdminCctvController? controller;
  final List<CameraAccessGrantItem>? initialGrants;
  final List<UserModel>? initialUsers;

  @override
  State<SchoolAdminCctvPage> createState() => _SchoolAdminCctvPageState();
}

class _SchoolAdminCctvPageState extends State<SchoolAdminCctvPage> {
  late final SchoolAdminCctvController _controller;
  late final bool _ownsController;

  List<CameraAccessGrantItem> _grants = [];
  bool _isLoading = true;
  String? _loadError;
  List<UserModel> _users = [];
  String _searchQuery = '';
  String _statusFilter = 'ทั้งหมด'; // ทั้งหมด, ใช้งานอยู่, หมดอายุ, เพิกถอนแล้ว

  static List<UserModel> _eligibleUsers(Iterable<UserModel> users) {
    return users
        .where(
          (user) =>
              user.status == 'active' &&
              (user.hasRole(UserRole.teacher) ||
                  user.hasRole(UserRole.schoolAdmin) ||
                  user.hasRole(UserRole.executive) ||
                  user.hasRole(UserRole.superAdmin)),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        SchoolAdminCctvController(
          loadGrants: ExecutiveService.listCameraAccessGrants,
          loadUsers: () async =>
              _eligibleUsers(await UserAdminService.getAllUsers()),
          grantAccess: ExecutiveService.grantCameraAccess,
          revokeAccess: ExecutiveService.revokeCameraAccess,
        );
    _controller.addListener(_syncFromController);
    if (widget.initialGrants != null) {
      _grants = widget.initialGrants!;
      _users = _eligibleUsers(widget.initialUsers ?? const <UserModel>[]);
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (widget.initialGrants != null) return;
    await _controller.load();
  }

  void _syncFromController() {
    if (!mounted) return;
    final state = _controller.state;
    SchoolAdminCctvSnapshot? snapshot;
    var isLoading = false;
    String? loadError;

    if (state is SchoolAdminData<SchoolAdminCctvSnapshot>) {
      snapshot = state.value;
    } else if (state is SchoolAdminLoading<SchoolAdminCctvSnapshot>) {
      snapshot = state.previousData;
      isLoading = state.previousData == null;
    } else if (state is SchoolAdminError<SchoolAdminCctvSnapshot>) {
      snapshot = state.previousData;
      loadError = state.message;
    }

    setState(() {
      _isLoading = isLoading;
      _loadError = loadError;
      if (snapshot != null) {
        _grants = snapshot.grants;
        _users = snapshot.users;
      }
    });
  }

  String _mutationError(String fallback) {
    final state = _controller.state;
    return state is SchoolAdminError<SchoolAdminCctvSnapshot>
        ? state.message
        : fallback;
  }

  @override
  void dispose() {
    _controller.removeListener(_syncFromController);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  List<CameraAccessGrantItem> get _filteredGrants {
    return _grants.where((g) {
      final query = _searchQuery.trim().toLowerCase();
      final matchQuery =
          query.isEmpty ||
          g.userName.toLowerCase().contains(query) ||
          g.userEmail.toLowerCase().contains(query) ||
          g.reason.toLowerCase().contains(query) ||
          g.userRole.toLowerCase().contains(query);

      if (!matchQuery) return false;

      final isExpired = g.validUntil.isBefore(DateTime.now());
      if (_statusFilter == 'ใช้งานอยู่') {
        return g.isActive && !isExpired;
      } else if (_statusFilter == 'หมดอายุ') {
        return isExpired && g.isActive;
      } else if (_statusFilter == 'เพิกถอนแล้ว') {
        return !g.isActive;
      }
      return true;
    }).toList();
  }

  int get _activeCount => _grants
      .where((g) => g.isActive && g.validUntil.isAfter(DateTime.now()))
      .length;

  int get _expiredCount => _grants
      .where((g) => g.validUntil.isBefore(DateTime.now()) && g.isActive)
      .length;

  int get _revokedCount => _grants.where((g) => !g.isActive).length;

  void _showGrantDialog() {
    String? selectedUserId = _users.isNotEmpty ? _users.first.uid : null;
    final reasonController = TextEditingController();
    int validDays = 7;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      color: SchoolAdminPalette.primaryDark,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'อนุญาตสิทธิ์เข้าถึงกล้อง CCTV',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'บันทึกสิทธิ์ตามมาตรฐาน PDPA และความปลอดภัย',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เลือกผู้ใช้งานที่ได้รับสิทธิ์',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedUserId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        items: _users.map((u) {
                          return DropdownMenuItem(
                            value: u.uid,
                            child: Text(
                              '${u.name} (${u.role.label})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedUserId = v),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'เหตุผลความจำเป็น (ตามหลักเกณฑ์ PDPA)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'ระบุเหตุผลความจำเป็นในการเข้าถึงภาพกล้อง',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ระยะเวลาที่อนุญาต',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: validDays,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('1 วัน (ชั่วคราว / ตรวจสอบเหตุการณ์)'),
                          ),
                          DropdownMenuItem(
                            value: 7,
                            child: Text('7 วัน (1 สัปดาห์)'),
                          ),
                          DropdownMenuItem(
                            value: 30,
                            child: Text('30 วัน (1 เดือน)'),
                          ),
                          DropdownMenuItem(
                            value: 90,
                            child: Text('90 วัน (1 ภาคการศึกษา)'),
                          ),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => validDays = v ?? 7),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
                FilledButton.icon(
                  onPressed: selectedUserId == null
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(dialogContext);
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('กรุณาระบุเหตุผลความจำเป็น'),
                              ),
                            );
                            return;
                          }
                          final validUntil = DateTime.now().add(
                            Duration(days: validDays),
                          );
                          final succeeded = await _controller.grant(
                            userId: selectedUserId!,
                            reason: reason,
                            validUntil: validUntil,
                          );
                          if (!mounted) return;
                          if (succeeded) {
                            nav.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'บันทึกการอนุญาตสิทธิ์เข้าถึงกล้อง CCTV เรียบร้อยแล้ว',
                                ),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  _mutationError('บันทึกสิทธิ์ไม่สำเร็จ'),
                                ),
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('ยืนยันอนุญาตสิทธิ์'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SchoolAdminPalette.primaryDark,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmRevokeGrant(CameraAccessGrantItem grant) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'ยืนยันเพิกถอนสิทธิ์',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Text(
            'ต้องการเพิกถอนสิทธิ์การเข้าถึงกล้อง CCTV ของ "${grant.userName}" (${grant.userEmail}) ทันทีหรือไม่?',
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(dialogContext);
                final succeeded = await _controller.revoke(grant.grantId);
                if (!mounted) return;
                if (succeeded) {
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('เพิกถอนสิทธิ์เรียบร้อยแล้ว'),
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(_mutationError('เพิกถอนสิทธิ์ไม่สำเร็จ')),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.lock_person_rounded, size: 16),
              label: const Text('เพิกถอนสิทธิ์'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildKpiSummaryGrid(),
                  const SizedBox(height: 16),
                  _buildNoticeBanner(),
                  if (_loadError != null) ...[
                    const SizedBox(height: 16),
                    _buildLoadErrorBanner(),
                  ],
                  const SizedBox(height: 16),
                  _buildFilterBar(),
                  const SizedBox(height: 16),
                  _buildGrantsList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadError!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _controller.isMutating ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleArea = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SchoolAdminPalette.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: SchoolAdminPalette.primaryDark,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'กล้อง CCTV & สิทธิ์การเข้าถึง',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            '${_grants.length} รายการสิทธิ์',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ระบบบริหารจัดการสิทธิ์การเข้าชมกล้องวงจรปิดตามมาตรฐานความปลอดภัยและ PDPA',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionButtons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _controller.isMutating ? null : _loadData,
                tooltip: 'รีเฟรชข้อมูล',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _users.isEmpty || _controller.isMutating
                    ? null
                    : _showGrantDialog,
                icon: const Icon(Icons.add_moderator_rounded, size: 16),
                label: const Text('อนุญาตสิทธิ์ใหม่'),
                style: FilledButton.styleFrom(
                  backgroundColor: SchoolAdminPalette.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 750) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleArea, const SizedBox(height: 14), actionButtons],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleArea),
              const SizedBox(width: 16),
              actionButtons,
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiSummaryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKpiCard(
              title: 'สิทธิ์ที่ใช้งานอยู่',
              value: '$_activeCount',
              subtitle: 'Active Grants',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF16A34A),
              bgColor: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFFBBF7D0),
              width: isMobile
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4,
            ),
            _buildKpiCard(
              title: 'สิทธิ์ที่หมดอายุ',
              value: '$_expiredCount',
              subtitle: 'Expired Grants',
              icon: Icons.history_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              width: isMobile
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4,
            ),
            _buildKpiCard(
              title: 'เพิกถอนสิทธิ์แล้ว',
              value: '$_revokedCount',
              subtitle: 'Revoked Grants',
              icon: Icons.block_rounded,
              color: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
              width: isMobile
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4,
            ),
            _buildKpiCard(
              title: 'ผู้ใช้งานในระบบ',
              value: '${_users.length}',
              subtitle: 'Total Eligible Users',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
              width: isMobile
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อกำหนดการคุ้มครองข้อมูลส่วนบุคคล (PDPA & CCTV Policy)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'การเข้าถึงภาพจากกล้องวงจรปิดต้องได้รับอนุญาตตามหลักเกณฑ์ความจำเป็น มีบันทึก Audit Log ทุกครั้ง และจะสิ้นสุดสิทธิ์ทันทีเมื่อหมดอายุ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อผู้รับสิทธิ์, อีเมล หรือเหตุผล...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButton<String>(
                value: _statusFilter,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                items: ['ทั้งหมด', 'ใช้งานอยู่', 'หมดอายุ', 'เพิกถอนแล้ว'].map((
                  s,
                ) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (v) =>
                    setState(() => _statusFilter = v ?? 'ทั้งหมด'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrantsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null && _grants.isEmpty) {
      return const SizedBox.shrink();
    }

    final filtered = _filteredGrants;
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'ยังไม่มีข้อมูล',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _grants.isEmpty
                  ? 'ยังไม่มีรายการสิทธิ์กล้อง CCTV'
                  : 'ไม่พบรายการสิทธิ์ที่ตรงกับตัวกรอง',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final grant = filtered[index];
        return _buildGrantCard(grant);
      },
    );
  }

  Widget _buildGrantCard(CameraAccessGrantItem grant) {
    final isExpired = grant.validUntil.isBefore(DateTime.now());
    final bool isActive = grant.isActive && !isExpired;

    String statusLabel;
    Color statusBgColor;
    Color statusBorderColor;
    Color statusTextColor;

    if (isActive) {
      statusLabel = 'ใช้งานอยู่';
      statusBgColor = const Color(0xFFF0FDF4);
      statusBorderColor = const Color(0xFFBBF7D0);
      statusTextColor = const Color(0xFF16A34A);
    } else if (isExpired && grant.isActive) {
      statusLabel = 'หมดอายุแล้ว';
      statusBgColor = const Color(0xFFFFFBEB);
      statusBorderColor = const Color(0xFFFDE68A);
      statusTextColor = const Color(0xFFD97706);
    } else {
      statusLabel = 'เพิกถอนสิทธิ์แล้ว';
      statusBgColor = const Color(0xFFFEF2F2);
      statusBorderColor = const Color(0xFFFECACA);
      statusTextColor = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isActive
                ? SchoolAdminPalette.primary.withAlpha(25)
                : const Color(0xFFF1F5F9),
            radius: 22,
            child: Icon(
              isActive ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              color: isActive
                  ? SchoolAdminPalette.primaryDark
                  : const Color(0xFF94A3B8),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        grant.userName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isActive
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                          decoration: isActive
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusBorderColor),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${grant.userEmail} • ${grant.userRole}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Text(
                    'เหตุผลความจำเป็น: ${grant.reason}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'หมดอายุ: ${grant.validUntil.day}/${grant.validUntil.month}/${grant.validUntil.year}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (grant.isActive && !isExpired) ...[
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC2626),
              ),
              tooltip: 'เพิกถอนสิทธิ์',
              onPressed: () => _confirmRevokeGrant(grant),
            ),
          ],
        ],
      ),
    );
  }
}
