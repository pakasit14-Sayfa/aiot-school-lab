import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/app_palette.dart';
import 'widgets/dev_ui.dart';

class SuperAdminPermissionsPage extends StatefulWidget {
  const SuperAdminPermissionsPage({super.key});

  @override
  State<SuperAdminPermissionsPage> createState() =>
      _SuperAdminPermissionsPageState();
}

typedef PermissionsPage = SuperAdminPermissionsPage;

class _SuperAdminPermissionsPageState extends State<SuperAdminPermissionsPage> {
  final TextEditingController _searchController = TextEditingController();

  final SchoolAdminPlatformService _platformService =
      SchoolAdminPlatformService();

  bool _isLoading = true;
  String? _loadError;

  final List<_UserAccount> _users = <_UserAccount>[];
  final List<SchoolPlatformRecord> _schools = <SchoolPlatformRecord>[];
  final List<StaffInvitation> _invitations = <StaffInvitation>[];
  final List<SchoolAdminAuditLog> _logs = <SchoolAdminAuditLog>[];

  String _roleFilter = 'ทุกบทบาท';
  String _schoolFilter = 'ทุกโรงเรียน';
  String _statusFilter = 'ทุกสถานะ';
  String _sortMode = 'ใช้งานล่าสุด';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final List<UserModel> userModels = await UserAdminService.getAllUsers();
      final List<SchoolPlatformRecord> schoolRecords =
          await _platformService.fetchSchools();

      List<StaffInvitation> invitationRecords = [];
      try {
        invitationRecords = await InvitationService.listInvitations();
      } catch (_) {
        invitationRecords = [];
      }

      List<SchoolAdminAuditLog> logRecords = [];
      try {
        logRecords = await _platformService.fetchAuditLogs(limit: 10);
      } catch (_) {
        logRecords = [];
      }

      if (!mounted) return;

      final Map<String, String> schoolNameById = {
        for (final s in schoolRecords) s.id: s.name,
      };

      final List<_UserAccount> loadedUsers = [];
      for (int i = 0; i < userModels.length; i++) {
        final u = userModels[i];
        final sName = schoolNameById[u.schoolId] ??
            (u.schoolId.isEmpty ? 'ทุกโรงเรียน' : 'โรงเรียนในระบบ');

        final displayRole = _mapUserRoleToDisplay(u.role);
        final isActive = u.status == 'active';
        final isMfa = u.hasRole(UserRole.superAdmin) ||
            u.hasRole(UserRole.schoolAdmin) ||
            u.hasRole(UserRole.teacher) ||
            u.hasRole(UserRole.executive);

        loadedUsers.add(_UserAccount(
          id: 'USR-${(i + 1).toString().padLeft(4, '0')}',
          dbId: u.uid,
          name: u.name.isNotEmpty ? u.name : u.email.split('@').first,
          email: u.email,
          role: displayRole,
          rawRole: u.role,
          allRoles: u.allRoles,
          school: sName,
          schoolId: u.schoolId,
          scope: u.schoolId.isNotEmpty
              ? 'เฉพาะโรงเรียน $sName'
              : 'ทุกโรงเรียนและทุกอุปกรณ์',
          status: isActive ? _UserStatus.active : _UserStatus.suspended,
          mfaEnabled: isMfa,
          lastActive: isActive ? 'ออนไลน์อยู่' : 'ระงับการใช้งาน',
          lastActiveMinutes: 0,
          createdAt: '2569',
          permissions: _defaultPermissionsForRole(displayRole),
        ));
      }

      setState(() {
        _users
          ..clear()
          ..addAll(loadedUsers);

        _schools
          ..clear()
          ..addAll(schoolRecords);

        _invitations
          ..clear()
          ..addAll(invitationRecords);

        _logs
          ..clear()
          ..addAll(logRecords);

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

  String _mapUserRoleToDisplay(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.schoolAdmin:
        return 'School Admin';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.executive:
        return 'Executive';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
    }
  }

  UserRole _mapDisplayToUserRole(String display) {
    switch (display) {
      case 'Super Admin':
        return UserRole.superAdmin;
      case 'School Admin':
        return UserRole.schoolAdmin;
      case 'Teacher':
        return UserRole.teacher;
      case 'Executive':
        return UserRole.executive;
      case 'Parent':
        return UserRole.parent;
      case 'Student':
      default:
        return UserRole.student;
    }
  }

  int get _activeCount =>
      _users.where((item) => item.status == _UserStatus.active).length;

  int get _suspendedCount =>
      _users.where((item) => item.status == _UserStatus.suspended).length;

  int get _adminCount => _users
      .where((item) => item.hasRole(UserRole.superAdmin) || item.hasRole(UserRole.schoolAdmin))
      .length;

  int get _noMfaCount => _users
      .where((item) =>
          item.status == _UserStatus.active &&
          !item.mfaEnabled &&
          item.role != 'Student' &&
          item.role != 'Parent')
      .length;

  List<String> get _schoolOptions => <String>[
        'ทุกโรงเรียน',
        ...(_schools.map((s) => s.name).toSet().toList()..sort()),
      ];

  List<_UserAccount> get _filteredUsers {
    final String query = _searchController.text.trim().toLowerCase();

    final List<_UserAccount> result = _users.where((item) {
      final bool matchesText = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.email.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query) ||
          item.school.toLowerCase().contains(query) ||
          item.role.toLowerCase().contains(query);

      bool matchesRole = true;
      if (_roleFilter != 'ทุกบทบาท') {
        final targetRole = _mapDisplayToUserRole(_roleFilter);
        matchesRole = item.hasRole(targetRole);
      }

      final bool matchesSchool = _schoolFilter == 'ทุกโรงเรียน' ||
          item.school == _schoolFilter ||
          item.school == 'ทุกโรงเรียน';

      bool matchesStatus = true;
      if (_statusFilter == 'เปิดใช้งาน') {
        matchesStatus = item.status == _UserStatus.active;
      } else if (_statusFilter == 'ระงับใช้งาน') {
        matchesStatus = item.status == _UserStatus.suspended;
      } else if (_statusFilter == 'ยังไม่เปิด MFA') {
        matchesStatus = !item.mfaEnabled;
      }

      return matchesText && matchesRole && matchesSchool && matchesStatus;
    }).toList();

    if (_sortMode == 'ชื่อผู้ใช้') {
      result.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortMode == 'บทบาทสำคัญก่อน') {
      result.sort((a, b) => a.rolePriority.compareTo(b.rolePriority));
    } else if (_sortMode == 'ยังไม่เปิด MFA ก่อน') {
      result.sort(
          (a, b) => a.mfaEnabled == b.mfaEnabled ? 0 : (a.mfaEnabled ? 1 : -1));
    } else {
      result.sort((a, b) => a.lastActiveMinutes.compareTo(b.lastActiveMinutes));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text(
          'กำหนดสิทธิ์และบทบาท (Permissions)',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'รีเฟรชข้อมูล',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadAllData(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _users.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 52, color: AppPalette.carnivalRed),
              const SizedBox(height: 14),
              const Text(
                'ไม่สามารถโหลดข้อมูลสิทธิ์และผู้ใช้ได้',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppPalette.textSecondary),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _loadAllData(),
                style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.deepBlue),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('ลองใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    final List<_UserAccount> filteredUsers = _filteredUsers;

    return RefreshIndicator(
      onRefresh: () => _loadAllData(showLoading: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: <Widget>[
          _buildHeroCard(),
          const SizedBox(height: 18),
          _buildSummaryCards(),
          const SizedBox(height: 18),
          _buildPriorityPanel(),
          const SizedBox(height: 18),
          _buildSearchAndFilterPanel(),
          const SizedBox(height: 18),
          _buildUsersPanel(filteredUsers),
          const SizedBox(height: 18),
          _buildInvitationsPanel(),
          const SizedBox(height: 18),
          _buildRoleMatrixPanel(),
          const SizedBox(height: 18),
          _buildAccessLogsPanel(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. Hero Card
  // ===========================================================================

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppPalette.deepBlue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: _shadow,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool mobile = constraints.maxWidth < 860;

          final Widget information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _badge(
                    'ศูนย์ควบคุมสิทธิ์และความปลอดภัย',
                    AppPalette.circusYellow,
                  ),
                  _badge(
                    'Super Admin Access',
                    Colors.white.withAlpha(50),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'จัดการบทบาท สิทธิ์ และความปลอดภัยระดับแพลตฟอร์ม',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'เชิญผู้ใช้ กำหนดบทบาทข้ามโรงเรียน ตรวจสอบ MFA และดูประวัติการเข้าใช้งานได้จากหน้าเดียว',
                style: TextStyle(
                  color: Colors.white.withAlpha(210),
                  fontSize: mobile ? 12 : 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _openInviteDialog,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.circusYellow,
                      foregroundColor: AppPalette.textPrimary,
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text(
                      'เชิญผู้ใช้ใหม่',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exportUsers,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('ส่งออกรายชื่อ'),
                  ),
                ],
              ),
            ],
          );

          final Widget metrics = Container(
            width: mobile ? double.infinity : 320,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppPalette.softBeige),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (
                BuildContext context,
                BoxConstraints metricConstraints,
              ) {
                const double gap = 10;
                final double width = (metricConstraints.maxWidth - gap) / 2;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: <Widget>[
                    SizedBox(
                      width: width,
                      child: _heroMetric(
                        Icons.people_alt_rounded,
                        '${_users.length}',
                        'ผู้ใช้ทั้งหมด',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _heroMetric(
                        Icons.verified_user_rounded,
                        '$_activeCount',
                        'เปิดใช้งาน',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _heroMetric(
                        Icons.admin_panel_settings_rounded,
                        '$_adminCount',
                        'ผู้ดูแล',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _heroMetric(
                        Icons.mark_email_unread_rounded,
                        '${_invitations.length}',
                        'คำเชิญค้างอยู่',
                      ),
                    ),
                  ],
                );
              },
            ),
          );

          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                information,
                const SizedBox(height: 18),
                metrics,
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: information),
              const SizedBox(width: 24),
              metrics,
            ],
          );
        },
      ),
    );
  }

  Widget _heroMetric(IconData icon, String value, String label) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.deepBlue.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppPalette.circusYellow.withAlpha(55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppPalette.deepBlue, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.deepBlue,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. Summary Cards
  // ===========================================================================

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 1100 ? 4 : 2;
        const double gap = 12;
        final double width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        final List<Widget> cards = <Widget>[
          _summaryCard(
            Icons.verified_user_rounded,
            'เปิดใช้งาน',
            '$_activeCount',
            'บัญชีที่เข้าสู่ระบบได้ตามปกติ',
            AppPalette.gardenGreen,
          ),
          _summaryCard(
            Icons.admin_panel_settings_rounded,
            'บัญชีผู้ดูแล',
            '$_adminCount',
            'Super Admin และ School Admin',
            AppPalette.deepBlue,
          ),
          _summaryCard(
            Icons.shield_outlined,
            'ยังไม่เปิด MFA',
            '$_noMfaCount',
            'บัญชีสำคัญที่ควรเพิ่มความปลอดภัย',
            AppPalette.circusYellow,
          ),
          _summaryCard(
            Icons.block_rounded,
            'ระงับใช้งาน',
            '$_suspendedCount',
            'บัญชีที่ไม่สามารถเข้าสู่ระบบได้',
            AppPalette.carnivalRed,
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

  Widget _summaryCard(
    IconData icon,
    String title,
    String value,
    String detail,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withAlpha(30),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. Priority Panel
  // ===========================================================================

  Widget _buildPriorityPanel() {
    final List<_PriorityItem> priorities = <_PriorityItem>[];

    for (final _UserAccount user in _users) {
      if (user.status == _UserStatus.active &&
          !user.mfaEnabled &&
          user.role != 'Student' &&
          user.role != 'Parent') {
        priorities.add(
          _PriorityItem(
            icon: Icons.shield_outlined,
            title: '${user.name} ยังไม่เปิด MFA',
            subtitle: '${user.email} • ${user.role}',
            detail: 'ควรเปิดการยืนยันตัวตนสองขั้นตอนสำหรับบัญชีนี้',
            color: AppPalette.circusYellow,
            onTap: () => _showUserDetails(user),
          ),
        );
      }

      if (user.status == _UserStatus.suspended) {
        priorities.add(
          _PriorityItem(
            icon: Icons.block_rounded,
            title: '${user.name} ถูกระงับใช้งาน',
            subtitle: '${user.email} • ${user.school}',
            detail: 'ตรวจสอบว่ายังต้องระงับบัญชีนี้หรือไม่',
            color: AppPalette.carnivalRed,
            onTap: () => _showUserDetails(user),
          ),
        );
      }
    }

    for (final StaffInvitation invitation in _invitations) {
      final daysRemaining =
          invitation.expiresAt.difference(DateTime.now()).inDays;
      if (daysRemaining <= 1) {
        priorities.add(
          _PriorityItem(
            icon: Icons.mark_email_unread_rounded,
            title: 'คำเชิญใกล้หมดอายุ',
            subtitle: '${invitation.email} • ${invitation.role.label}',
            detail: daysRemaining < 0
                ? 'คำเชิญหมดอายุแล้ว'
                : 'เหลือเวลาอีก $daysRemaining วัน',
            color: AppPalette.carnivalRed,
            onTap: () => _showInvitationDetails(invitation),
          ),
        );
      }
    }

    return _panel(
      title: 'รายการที่ควรจัดการก่อน',
      trailing: _badge(
        '${priorities.length} รายการ',
        priorities.isEmpty ? AppPalette.gardenGreen : AppPalette.carnivalRed,
      ),
      child: priorities.isEmpty
          ? _empty(
              Icons.task_alt_rounded,
              'ไม่มีรายการที่ต้องดำเนินการ',
              'บัญชีผู้ใช้และสิทธิ์อยู่ในสถานะปกติ',
            )
          : Column(
              children: <Widget>[
                for (int index = 0;
                    index < priorities.length && index < 5;
                    index++) ...<Widget>[
                  _priorityRow(priorities[index]),
                  if (index < priorities.length.clamp(0, 5) - 1)
                    const Divider(height: 20),
                ],
              ],
            ),
    );
  }

  Widget _priorityRow(_PriorityItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.color.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppPalette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: AppPalette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.detail,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppPalette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. Search & Filters
  // ===========================================================================

  Widget _buildSearchAndFilterPanel() {
    return _panel(
      title: 'ค้นหาและกรองผู้ใช้งาน',
      trailing: TextButton.icon(
        onPressed: _clearFilters,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('ล้างตัวกรอง'),
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อ อีเมล รหัสผู้ใช้ โรงเรียน หรือบทบาท',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
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
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 600
                      ? 2
                      : 1;
              const double gap = 10;
              final double width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: <Widget>[
                  SizedBox(
                    width: width,
                    child: _dropdown(
                      label: 'บทบาท',
                      icon: Icons.badge_rounded,
                      value: _roleFilter,
                      items: const <String>[
                        'ทุกบทบาท',
                        'Super Admin',
                        'School Admin',
                        'Teacher',
                        'Executive',
                        'Student',
                        'Parent',
                      ],
                      onChanged: (String value) {
                        setState(() {
                          _roleFilter = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _dropdown(
                      label: 'โรงเรียน',
                      icon: Icons.apartment_rounded,
                      value: _schoolFilter,
                      items: _schoolOptions,
                      onChanged: (String value) {
                        setState(() {
                          _schoolFilter = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _dropdown(
                      label: 'สถานะ',
                      icon: Icons.filter_alt_rounded,
                      value: _statusFilter,
                      items: const <String>[
                        'ทุกสถานะ',
                        'เปิดใช้งาน',
                        'ระงับใช้งาน',
                        'ยังไม่เปิด MFA',
                      ],
                      onChanged: (String value) {
                        setState(() {
                          _statusFilter = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _dropdown(
                      label: 'เรียงตาม',
                      icon: Icons.sort_rounded,
                      value: _sortMode,
                      items: const <String>[
                        'ใช้งานล่าสุด',
                        'ชื่อผู้ใช้',
                        'บทบาทสำคัญก่อน',
                        'ยังไม่เปิด MFA ก่อน',
                      ],
                      onChanged: (String value) {
                        setState(() {
                          _sortMode = value;
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      value: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items
          .map(
            (String item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _roleFilter = 'ทุกบทบาท';
      _schoolFilter = 'ทุกโรงเรียน';
      _statusFilter = 'ทุกสถานะ';
      _sortMode = 'ใช้งานล่าสุด';
    });
  }

  // ===========================================================================
  // 5. Users List Panel
  // ===========================================================================

  Widget _buildUsersPanel(List<_UserAccount> filteredUsers) {
    return _panel(
      title: 'รายการผู้ใช้งาน',
      trailing: Text(
        'พบ ${filteredUsers.length} รายการ',
        style: const TextStyle(
          color: AppPalette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: filteredUsers.isEmpty
          ? _empty(
              Icons.person_search_rounded,
              'ไม่พบผู้ใช้งาน',
              'ลองเปลี่ยนคำค้นหาหรือตัวกรองอีกครั้ง',
            )
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = constraints.maxWidth >= 1050 ? 2 : 1;
                const double gap = 14;
                final double width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: filteredUsers
                      .map(
                        (_UserAccount user) => SizedBox(
                          width: width,
                          child: _userCard(user),
                        ),
                      )
                      .toList(),
                );
              },
            ),
    );
  }

  Widget _userCard(_UserAccount user) {
    final Color statusColor = user.status == _UserStatus.active
        ? AppPalette.gardenGreen
        : AppPalette.carnivalRed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: !user.mfaEnabled && user.role != 'Student' && user.role != 'Parent'
              ? AppPalette.circusYellow.withAlpha(140)
              : user.status == _UserStatus.suspended
                  ? AppPalette.carnivalRed.withAlpha(110)
                  : AppPalette.softBeige.withAlpha(180),
        ),
        boxShadow: _shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _roleColor(user.role).withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _roleIcon(user.role),
                  color: _roleColor(user.role),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'ตัวเลือกเพิ่มเติม',
                onSelected: (String action) {
                  if (action == 'details') {
                    _showUserDetails(user);
                  } else if (action == 'edit') {
                    _openEditUserDialog(user);
                  } else if (action == 'toggle') {
                    _toggleUserStatus(user);
                  } else if (action == 'reset') {
                    _resetPassword(user);
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'details',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.visibility_rounded),
                      title: Text('ดูรายละเอียด'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_rounded),
                      title: Text('แก้ไขผู้ใช้และสิทธิ์'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'reset',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.password_rounded),
                      title: Text('ส่งลิงก์รีเซ็ตรหัสผ่าน'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'toggle',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        user.status == _UserStatus.active
                            ? Icons.block_rounded
                            : Icons.check_circle_rounded,
                      ),
                      title: Text(
                        user.status == _UserStatus.active
                            ? 'ระงับการใช้งาน'
                            : 'เปิดใช้งาน',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _badge(
                user.status == _UserStatus.active ? 'เปิดใช้งาน' : 'ระงับใช้งาน',
                statusColor,
              ),
              _badge(user.role, _roleColor(user.role)),
              if (user.allRoles.length > 1)
                _badge(
                  '+ ${user.allRoles.length - 1} บทบาท',
                  AppPalette.deepBlue,
                ),
              _badge(
                user.mfaEnabled ? 'MFA เปิดแล้ว' : 'ยังไม่เปิด MFA',
                user.mfaEnabled
                    ? AppPalette.gardenGreen
                    : AppPalette.circusYellow,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.softBeige.withAlpha(75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: <Widget>[
                _infoRow(Icons.apartment_rounded, 'โรงเรียน', user.school),
                const SizedBox(height: 8),
                _infoRow(Icons.rule_rounded, 'ขอบเขต', user.scope),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.schedule_rounded,
                  'สถานะการใช้งาน',
                  user.lastActive,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _permissionSummary(user.permissions),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showUserDetails(user),
                  icon: const Icon(Icons.visibility_rounded, size: 17),
                  label: const Text('รายละเอียด'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openEditUserDialog(user),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.deepBlue,
                  ),
                  icon: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 17,
                  ),
                  label: const Text('จัดการสิทธิ์'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 16, color: AppPalette.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _permissionSummary(_PermissionSet permissions) {
    final List<String> granted = permissions.grantedLabels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'สิทธิ์ที่ได้รับ',
          style: TextStyle(
            color: AppPalette.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: granted
              .take(4)
              .map(
                (String label) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.deepBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppPalette.deepBlue,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        if (granted.length > 4) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            '+ อีก ${granted.length - 4} สิทธิ์',
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 9.5,
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // 6. Invitations Panel
  // ===========================================================================

  Widget _buildInvitationsPanel() {
    return _panel(
      title: 'คำเชิญที่รอตอบรับ',
      trailing: TextButton.icon(
        onPressed: _openInviteDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('ส่งคำเชิญ'),
      ),
      child: _invitations.isEmpty
          ? _empty(
              Icons.mark_email_read_rounded,
              'ไม่มีคำเชิญค้างอยู่',
              'ผู้ใช้ที่ได้รับคำเชิญตอบรับครบแล้ว',
            )
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = constraints.maxWidth >= 900 ? 2 : 1;
                const double gap = 12;
                final double width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: _invitations
                      .map(
                        (StaffInvitation invitation) => SizedBox(
                          width: width,
                          child: _invitationCard(invitation),
                        ),
                      )
                      .toList(),
                );
              },
            ),
    );
  }

  Widget _invitationCard(StaffInvitation invitation) {
    final daysRemaining =
        invitation.expiresAt.difference(DateTime.now()).inDays;
    final isExpired = daysRemaining < 0;
    final Color color = (isExpired || daysRemaining <= 1)
        ? AppPalette.carnivalRed
        : AppPalette.circusYellow;

    final String statusLabel = isExpired ? 'หมดอายุ' : 'รอตอบรับ';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: color.withAlpha(30),
                child: Icon(Icons.mark_email_unread_rounded, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      invitation.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'บทบาท: ${invitation.role.label}',
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              _badge(statusLabel, color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'สร้างเมื่อ ${invitation.createdAt.day}/${invitation.createdAt.month}/${invitation.createdAt.year}',
            style: const TextStyle(
              color: AppPalette.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isExpired
                ? 'คำเชิญหมดอายุแล้ว'
                : 'คำเชิญหมดอายุในอีก $daysRemaining วัน',
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancelInvitation(invitation),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('ยกเลิกคำเชิญ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. Role Matrix Panel
  // ===========================================================================

  Widget _buildRoleMatrixPanel() {
    final List<_RoleTemplate> roles = <_RoleTemplate>[
      _RoleTemplate(
        name: 'Super Admin',
        description: 'จัดการระบบทั้งหมดและทุกโรงเรียนในแพลตฟอร์ม',
        color: AppPalette.carnivalRed,
        permissions: _PermissionSet.fullAccess(),
      ),
      _RoleTemplate(
        name: 'School Admin',
        description: 'จัดการโรงเรียน ผู้ใช้ และอุปกรณ์ภายในโรงเรียน',
        color: AppPalette.deepBlue,
        permissions: _PermissionSet(
          viewDashboard: true,
          manageSchools: false,
          manageDevices: true,
          controlDevices: true,
          manageUsers: true,
          viewLogs: true,
          exportReports: true,
          supportMode: false,
        ),
      ),
      _RoleTemplate(
        name: 'Teacher',
        description: 'จัดการการสอน บทเรียน การบ้าน และนักเรียนในชั้น',
        color: AppPalette.gardenGreen,
        permissions: _PermissionSet(
          viewDashboard: true,
          manageSchools: false,
          manageDevices: false,
          controlDevices: true,
          manageUsers: false,
          viewLogs: true,
          exportReports: true,
          supportMode: false,
        ),
      ),
      _RoleTemplate(
        name: 'Executive',
        description: 'ดูรายงานภาพรวม สถิติพลังงาน และแดชบอร์ดผู้บริหาร',
        color: AppPalette.circusYellow,
        permissions: _PermissionSet(
          viewDashboard: true,
          manageSchools: false,
          manageDevices: false,
          controlDevices: false,
          manageUsers: false,
          viewLogs: true,
          exportReports: true,
          supportMode: false,
        ),
      ),
      _RoleTemplate(
        name: 'Student & Parent',
        description: 'เข้าถึงบทเรียน การส่งงาน และการติดตามผลการเรียน',
        color: AppPalette.textSecondary,
        permissions: _PermissionSet(
          viewDashboard: false,
          manageSchools: false,
          manageDevices: false,
          controlDevices: false,
          manageUsers: false,
          viewLogs: false,
          exportReports: false,
          supportMode: false,
        ),
      ),
    ];

    return _panel(
      title: 'บทบาทและขอบเขตสิทธิ์ของระบบ (Role Matrix)',
      trailing: TextButton.icon(
        onPressed: () => _message(
          'บทบาทในระบบถูกกำหนดตามมาตรฐานความปลอดภัย RBAC',
        ),
        icon: const Icon(Icons.info_outline_rounded),
        label: const Text('คำอธิบายสิทธิ์'),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth < 820) {
            return Column(
              children: <Widget>[
                for (int index = 0; index < roles.length; index++) ...<Widget>[
                  _roleCard(roles[index]),
                  if (index < roles.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 72,
              dataRowMaxHeight: 78,
              columnSpacing: 30,
              horizontalMargin: 16,
              headingTextStyle: const TextStyle(
                color: AppPalette.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              columns: const <DataColumn>[
                DataColumn(label: Text('บทบาท')),
                DataColumn(label: Text('ดูภาพรวม')),
                DataColumn(label: Text('โรงเรียน')),
                DataColumn(label: Text('อุปกรณ์')),
                DataColumn(label: Text('ควบคุม')),
                DataColumn(label: Text('ผู้ใช้')),
                DataColumn(label: Text('Log')),
                DataColumn(label: Text('รายงาน')),
                DataColumn(label: Text('Support')),
              ],
              rows: roles
                  .map(
                    (_RoleTemplate role) => DataRow(
                      cells: <DataCell>[
                        DataCell(
                          SizedBox(
                            width: 190,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  role.name,
                                  style: TextStyle(
                                    color: role.color,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  role.description,
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppPalette.textSecondary,
                                    fontSize: 9.5,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(_permissionIcon(role.permissions.viewDashboard)),
                        DataCell(_permissionIcon(role.permissions.manageSchools)),
                        DataCell(_permissionIcon(role.permissions.manageDevices)),
                        DataCell(_permissionIcon(role.permissions.controlDevices)),
                        DataCell(_permissionIcon(role.permissions.manageUsers)),
                        DataCell(_permissionIcon(role.permissions.viewLogs)),
                        DataCell(_permissionIcon(role.permissions.exportReports)),
                        DataCell(_permissionIcon(role.permissions.supportMode)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _roleCard(_RoleTemplate role) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: role.color.withAlpha(15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: role.color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: role.color.withAlpha(30),
                child: Icon(_roleIcon(role.name), color: role.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      role.name,
                      style: TextStyle(
                        color: role.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role.description,
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: role.permissions.grantedLabels
                .map(
                  (String permission) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      permission,
                      style: TextStyle(
                        color: role.color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _permissionIcon(bool allowed) {
    return Icon(
      allowed ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
      color: allowed ? AppPalette.gardenGreen : AppPalette.softBeige,
      size: 19,
    );
  }

  // ===========================================================================
  // 8. Audit & Access Logs Panel
  // ===========================================================================

  Widget _buildAccessLogsPanel() {
    return _panel(
      title: 'ประวัติการเข้าใช้งานและการเปลี่ยนสิทธิ์ (Audit Logs)',
      trailing: TextButton.icon(
        onPressed: () => _message('ส่งออกประวัติ Audit Log เรียบร้อย'),
        icon: const Icon(Icons.download_rounded),
        label: const Text('ส่งออก Log'),
      ),
      child: _logs.isEmpty
          ? _empty(
              Icons.history_toggle_off_rounded,
              'ยังไม่มีประวัติการเข้าใช้งาน',
              'บันทึกกิจกรรมความปลอดภัยและสิทธิ์จะปรากฏที่นี่',
            )
          : Column(
              children: <Widget>[
                for (int index = 0; index < _logs.length; index++) ...<Widget>[
                  _logRow(_logs[index]),
                  if (index < _logs.length - 1) const Divider(height: 20),
                ],
              ],
            ),
    );
  }

  void _showInvitationDetails(StaffInvitation invitation) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('รายละเอียดคำเชิญ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _dialogInfoRow('อีเมล', invitation.email),
              _dialogInfoRow('บทบาท', invitation.role.label),
              _dialogInfoRow('สร้างเมื่อ',
                  '${invitation.createdAt.day}/${invitation.createdAt.month}/${invitation.createdAt.year}'),
              _dialogInfoRow('หมดอายุเมื่อ',
                  '${invitation.expiresAt.day}/${invitation.expiresAt.month}/${invitation.expiresAt.year}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ปิด'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _cancelInvitation(invitation);
              },
              style: FilledButton.styleFrom(backgroundColor: AppPalette.carnivalRed),
              icon: const Icon(Icons.close_rounded),
              label: const Text('ยกเลิกคำเชิญ'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: AppPalette.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
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

  Widget _logRow(SchoolAdminAuditLog log) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppPalette.deepBlue.withAlpha(25),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.history_rounded,
            color: AppPalette.deepBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                log.action,
                style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                log.detail.isNotEmpty ? log.detail : log.target,
                style: const TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'โดย ${log.actorName} • ${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')} น.',
                style: const TextStyle(
                  color: AppPalette.gardenGreen,
                  fontSize: 10,
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
  // Dialogs & Actions
  // ===========================================================================

  Future<void> _openInviteDialog() async {
    final TextEditingController emailController = TextEditingController();
    UserRole selectedRole = UserRole.schoolAdmin;
    String? selectedSchoolId = _schools.isNotEmpty ? _schools.first.id : null;

    final bool? sent = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor:
                                AppPalette.deepBlue.withAlpha(30),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: AppPalette.deepBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'เชิญบุคลากร / ผู้ใช้ใหม่',
                              style: TextStyle(
                                color: AppPalette.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'อีเมลที่ต้องการเชิญ',
                          prefixIcon: Icon(Icons.email_rounded),
                          helperText:
                              'ระบบจะสร้างคำเชิญสำหรับให้ผู้ใช้ตั้งรหัสผ่านเข้าสู่ระบบ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'บทบาท',
                          prefixIcon: Icon(Icons.badge_rounded),
                        ),
                        items: const <DropdownMenuItem<UserRole>>[
                          DropdownMenuItem<UserRole>(
                            value: UserRole.schoolAdmin,
                            child: Text('แอดมินโรงเรียน (School Admin)'),
                          ),
                          DropdownMenuItem<UserRole>(
                            value: UserRole.teacher,
                            child: Text('ครูผู้สอน (Teacher)'),
                          ),
                          DropdownMenuItem<UserRole>(
                            value: UserRole.executive,
                            child: Text('ผู้บริหาร (Executive)'),
                          ),
                          DropdownMenuItem<UserRole>(
                            value: UserRole.superAdmin,
                            child: Text('ผู้ดูแลระบบสูงสุด (Super Admin)'),
                          ),
                        ],
                        onChanged: (UserRole? value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedRole = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_schools.isNotEmpty)
                        DropdownButtonFormField<String?>(
                          value: selectedSchoolId,
                          decoration: const InputDecoration(
                            labelText: 'โรงเรียนที่สังกัด',
                            prefixIcon: Icon(Icons.apartment_rounded),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('ทุกโรงเรียน / ส่วนกลาง'),
                            ),
                            ..._schools.map(
                              (s) => DropdownMenuItem<String?>(
                                value: s.id,
                                child: Text(s.name),
                              ),
                            ),
                          ],
                          onChanged: (String? value) {
                            setDialogState(() {
                              selectedSchoolId = value;
                            });
                          },
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('ยกเลิก'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                final String email =
                                    emailController.text.trim();
                                if (!email.contains('@') ||
                                    !email.contains('.')) {
                                  _message('กรุณากรอกอีเมลให้ถูกต้อง');
                                  return;
                                }
                                Navigator.of(dialogContext).pop(true);
                              },
                              icon: const Icon(Icons.send_rounded),
                              label: const Text('ส่งคำเชิญ'),
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

    final String email = emailController.text.trim();
    emailController.dispose();

    if (sent != true || !mounted) return;

    try {
      await InvitationService.createInvitation(
        email: email,
        role: selectedRole,
        schoolId: selectedSchoolId,
      );
      _message('สร้างคำเชิญไปยัง $email เรียบร้อยแล้ว');
      _loadAllData(showLoading: false);
    } catch (e) {
      _message('เกิดข้อผิดพลาดในการสร้างคำเชิญ: $e');
    }
  }

  Future<void> _cancelInvitation(StaffInvitation invitation) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ยกเลิกคำเชิญ'),
          content: Text('ต้องการยกเลิกคำเชิญของ ${invitation.email} หรือไม่'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('กลับ'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.carnivalRed,
              ),
              child: const Text('ยืนยันยกเลิก'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await InvitationService.revokeInvitation(invitation.id);
      _message('ยกเลิกคำเชิญของ ${invitation.email} แล้ว');
      _loadAllData(showLoading: false);
    } catch (e) {
      _message('ไม่สามารถยกเลิกคำเชิญได้: $e');
    }
  }

  Future<void> _openEditUserDialog(_UserAccount user) async {
    final TextEditingController nameController =
        TextEditingController(text: user.name);

    UserRole selectedRole = user.rawRole;
    UserRole? secondaryRoleToAdd;
    String? selectedSchoolId = user.schoolId;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: _roleColor(
                              _mapUserRoleToDisplay(selectedRole),
                            ).withAlpha(30),
                            child: Icon(
                              _roleIcon(_mapUserRoleToDisplay(selectedRole)),
                              color: _roleColor(
                                _mapUserRoleToDisplay(selectedRole),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'แก้ไขบทบาทและสิทธิ์ผู้ใช้',
                                  style: TextStyle(
                                    color: AppPalette.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    color: AppPalette.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: nameController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อผู้ใช้งาน',
                          prefixIcon: Icon(Icons.person_rounded),
                          helperText: 'ชื่อบัญชีดึงจากข้อมูลโปรไฟล์',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'บทบาทหลัก (Primary Role)',
                          prefixIcon: Icon(Icons.badge_rounded),
                        ),
                        items: const <DropdownMenuItem<UserRole>>[
                          DropdownMenuItem<UserRole>(
                            value: UserRole.superAdmin,
                            child: Text('Super Admin (ผู้ดูแลระบบสูงสุด)'),
                          ),
                          DropdownMenuItem<UserRole>(
                            value: UserRole.schoolAdmin,
                            child: Text('School Admin (แอดมินโรงเรียน)'),
                          ),
                          DropdownMenuItem<UserRole>(
                            value: UserRole.teacher,
                            child: Text('Teacher (ครูผู้สอน)'),
                          ),
                          DropdownMenuItem<UserRole>(
                            value: UserRole.executive,
                            child: Text('Executive (ผู้บริหาร)'),
                          ),
                          DropdownMenuItem<UserRole>(
                            value: UserRole.student,
                            child: Text('Student (นักเรียน)'),
                          ),
                          DropdownMenuItem<UserRole>(
                            value: UserRole.parent,
                            child: Text('Parent (ผู้ปกครอง)'),
                          ),
                        ],
                        onChanged: (UserRole? value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedRole = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole?>(
                        value: secondaryRoleToAdd,
                        decoration: const InputDecoration(
                          labelText: 'เพิ่มบทบาทรอง (Add Secondary Role)',
                          prefixIcon: Icon(Icons.add_moderator_rounded),
                          helperText:
                              'ผู้ใช้ 1 บัญชีสามารถถือได้หลายบทบาทพร้อมกัน',
                        ),
                        items: [
                          const DropdownMenuItem<UserRole?>(
                            value: null,
                            child: Text('ไม่เพิ่มบทบาทรอง'),
                          ),
                          ...UserRole.values
                              .where((r) =>
                                  r != selectedRole && !user.allRoles.contains(r))
                              .map(
                                (r) => DropdownMenuItem<UserRole?>(
                                  value: r,
                                  child: Text('+ ${_mapUserRoleToDisplay(r)}'),
                                ),
                              ),
                        ],
                        onChanged: (UserRole? value) {
                          setDialogState(() {
                            secondaryRoleToAdd = value;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'บทบาทที่ผู้ใช้นี้ได้รับในปัจจุบัน:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: user.allRoles
                            .map((r) => _badge(
                                  _mapUserRoleToDisplay(r),
                                  _roleColor(_mapUserRoleToDisplay(r)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('ยกเลิก'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('บันทึกการแก้ไข'),
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

    nameController.dispose();

    if (saved != true || !mounted) return;

    try {
      if (user.dbId != null) {
        if (selectedRole != user.rawRole) {
          await UserAdminService.updateRole(
            uid: user.dbId!,
            role: selectedRole,
          );
        }
        if (secondaryRoleToAdd != null) {
          await UserAdminService.addSecondaryRole(
            uid: user.dbId!,
            role: secondaryRoleToAdd!,
            schoolId: selectedSchoolId,
          );
        }
      }
      _message('บันทึกบทบาทและสิทธิ์ของ ${user.name} แล้ว');
      _loadAllData(showLoading: false);
    } catch (e) {
      _message('ไม่สามารถบันทึกสิทธิ์ได้: $e');
    }
  }

  void _showUserDetails(_UserAccount user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: <Widget>[
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
                    children: <Widget>[
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: _roleColor(user.role).withAlpha(30),
                        child: Icon(
                          _roleIcon(user.role),
                          color: _roleColor(user.role),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: AppPalette.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${user.id} • ${user.email}',
                              style: const TextStyle(
                                color: AppPalette.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _badge(
                        user.status == _UserStatus.active
                            ? 'เปิดใช้งาน'
                            : 'ระงับใช้งาน',
                        user.status == _UserStatus.active
                            ? AppPalette.gardenGreen
                            : AppPalette.carnivalRed,
                      ),
                      _badge(user.role, _roleColor(user.role)),
                      if (user.allRoles.length > 1)
                        _badge(
                          '+ ${user.allRoles.length - 1} บทบาท',
                          AppPalette.deepBlue,
                        ),
                      _badge(
                        user.mfaEnabled ? 'MFA เปิดแล้ว' : 'ยังไม่เปิด MFA',
                        user.mfaEnabled
                            ? AppPalette.gardenGreen
                            : AppPalette.circusYellow,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailSection('ข้อมูลบัญชีผู้ใช้', <MapEntry<String, String>>[
                    MapEntry<String, String>('อีเมล', user.email),
                    MapEntry<String, String>('บทบาทหลัก', user.role),
                    MapEntry<String, String>(
                      'บทบาททั้งหมด',
                      user.allRoles.map(_mapUserRoleToDisplay).join(', '),
                    ),
                    MapEntry<String, String>('โรงเรียน', user.school),
                    MapEntry<String, String>('ขอบเขต', user.scope),
                    MapEntry<String, String>('สถานะบัญชี',
                        user.status == _UserStatus.active ? 'ใช้งานได้' : 'ถูกระงับ'),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.softBeige.withAlpha(65),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'สิทธิ์การเข้าถึงในระบบ',
                          style: TextStyle(
                            color: AppPalette.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final _PermissionEntry entry
                            in user.permissions.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  entry.allowed
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_outlined,
                                  color: entry.allowed
                                      ? AppPalette.gardenGreen
                                      : AppPalette.softBeige,
                                  size: 19,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.label,
                                    style: TextStyle(
                                      color: entry.allowed
                                          ? AppPalette.textPrimary
                                          : AppPalette.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: entry.allowed
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _toggleUserStatus(user);
                          },
                          icon: Icon(
                            user.status == _UserStatus.active
                                ? Icons.block_rounded
                                : Icons.check_circle_rounded,
                          ),
                          label: Text(
                            user.status == _UserStatus.active
                                ? 'ระงับบัญชี'
                                : 'เปิดบัญชี',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _openEditUserDialog(user);
                          },
                          icon: const Icon(Icons.admin_panel_settings_rounded),
                          label: const Text('จัดการสิทธิ์'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailSection(String title, List<MapEntry<String, String>> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.softBeige.withAlpha(65),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                color: AppPalette.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final MapEntry<String, String> row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      row.key,
                      style: const TextStyle(
                        color: AppPalette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(_UserAccount user) async {
    if (user.hasRole(UserRole.superAdmin) &&
        user.status == _UserStatus.active) {
      _message('ไม่สามารถระงับ Super Admin หลักจากหน้านี้ได้');
      return;
    }

    final bool willSuspend = user.status == _UserStatus.active;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(willSuspend ? 'ระงับการใช้งานบัญชี' : 'เปิดใช้งานบัญชี'),
          content: Text(
            willSuspend
                ? '${user.name} จะไม่สามารถเข้าสู่ระบบและใช้งานสิทธิ์ต่าง ๆ ได้ชั่วคราว'
                : 'ต้องการเปิดใช้งานบัญชีของ ${user.name} อีกครั้งหรือไม่',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: willSuspend
                    ? AppPalette.carnivalRed
                    : AppPalette.gardenGreen,
              ),
              child: Text(willSuspend ? 'ระงับบัญชี' : 'เปิดบัญชี'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      if (user.dbId != null) {
        if (willSuspend) {
          await UserAdminService.deleteUser(user.dbId!);
        } else {
          await UserAdminService.reactivateUser(user.dbId!);
        }
      }
      _message('${willSuspend ? 'ระงับ' : 'เปิดใช้งาน'}บัญชี ${user.name} แล้ว');
      _loadAllData(showLoading: false);
    } catch (e) {
      _message('ไม่สามารถเปลี่ยนสถานะบัญชีได้: $e');
    }
  }

  void _resetPassword(_UserAccount user) {
    _message('ส่งคำขอรีเซ็ตรหัสผ่านไปยัง ${user.email} เรียบร้อยแล้ว');
  }

  void _exportUsers() {
    _message('ส่งออกรายชื่อผู้ใช้ทั้งหมด $filteredUserCount รายการแล้ว');
  }

  int get filteredUserCount => _filteredUsers.length;

  _PermissionSet _defaultPermissionsForRole(String role) {
    if (role == 'Super Admin') {
      return _PermissionSet.fullAccess();
    }
    if (role == 'School Admin') {
      return _PermissionSet(
        viewDashboard: true,
        manageSchools: false,
        manageDevices: true,
        controlDevices: true,
        manageUsers: true,
        viewLogs: true,
        exportReports: true,
        supportMode: false,
      );
    }
    if (role == 'Teacher') {
      return _PermissionSet(
        viewDashboard: true,
        manageSchools: false,
        manageDevices: false,
        controlDevices: true,
        manageUsers: false,
        viewLogs: true,
        exportReports: true,
        supportMode: false,
      );
    }
    if (role == 'Executive') {
      return _PermissionSet(
        viewDashboard: true,
        manageSchools: false,
        manageDevices: false,
        controlDevices: false,
        manageUsers: false,
        viewLogs: true,
        exportReports: true,
        supportMode: false,
      );
    }
    return _PermissionSet(
      viewDashboard: false,
      manageSchools: false,
      manageDevices: false,
      controlDevices: false,
      manageUsers: false,
      viewLogs: false,
      exportReports: false,
      supportMode: false,
    );
  }

  Color _roleColor(String role) {
    if (role == 'Super Admin') return AppPalette.carnivalRed;
    if (role == 'School Admin') return AppPalette.deepBlue;
    if (role == 'Teacher') return AppPalette.gardenGreen;
    if (role == 'Executive') return AppPalette.circusYellow;
    return AppPalette.textSecondary;
  }

  IconData _roleIcon(String role) {
    if (role == 'Super Admin') return Icons.security_rounded;
    if (role == 'School Admin') return Icons.admin_panel_settings_rounded;
    if (role == 'Teacher') return Icons.school_rounded;
    if (role == 'Executive') return Icons.insights_rounded;
    return Icons.person_rounded;
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: AppPalette.softBeige.withAlpha(50),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 25,
            backgroundColor: AppPalette.deepBlue.withAlpha(25),
            child: Icon(icon, color: AppPalette.deepBlue, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 13.5,
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

  List<BoxShadow> get _shadow => <BoxShadow>[
        BoxShadow(
          color: Colors.black.withAlpha(12),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
}

enum _UserStatus { active, suspended }

class _UserAccount {
  final String id;
  final String? dbId;
  final String email;
  final String createdAt;

  String name;
  String role;
  UserRole rawRole;
  List<UserRole> allRoles;
  String school;
  String? schoolId;
  String scope;
  _UserStatus status;
  bool mfaEnabled;
  String lastActive;
  int lastActiveMinutes;
  _PermissionSet permissions;

  _UserAccount({
    required this.id,
    this.dbId,
    required this.name,
    required this.email,
    required this.role,
    required this.rawRole,
    required this.allRoles,
    required this.school,
    this.schoolId,
    required this.scope,
    required this.status,
    required this.mfaEnabled,
    required this.lastActive,
    required this.lastActiveMinutes,
    required this.createdAt,
    required this.permissions,
  });

  bool hasRole(UserRole targetRole) {
    return allRoles.contains(targetRole) || rawRole == targetRole;
  }

  int get rolePriority {
    if (hasRole(UserRole.superAdmin)) return 0;
    if (hasRole(UserRole.schoolAdmin)) return 1;
    if (hasRole(UserRole.executive)) return 2;
    if (hasRole(UserRole.teacher)) return 3;
    return 4;
  }
}

class _PermissionSet {
  bool viewDashboard;
  bool manageSchools;
  bool manageDevices;
  bool controlDevices;
  bool manageUsers;
  bool viewLogs;
  bool exportReports;
  bool supportMode;

  _PermissionSet({
    required this.viewDashboard,
    required this.manageSchools,
    required this.manageDevices,
    required this.controlDevices,
    required this.manageUsers,
    required this.viewLogs,
    required this.exportReports,
    required this.supportMode,
  });

  factory _PermissionSet.fullAccess() {
    return _PermissionSet(
      viewDashboard: true,
      manageSchools: true,
      manageDevices: true,
      controlDevices: true,
      manageUsers: true,
      viewLogs: true,
      exportReports: true,
      supportMode: true,
    );
  }

  List<_PermissionEntry> get entries => <_PermissionEntry>[
        _PermissionEntry('ดูหน้าภาพรวม', viewDashboard),
        _PermissionEntry('จัดการโรงเรียน', manageSchools),
        _PermissionEntry('จัดการอุปกรณ์', manageDevices),
        _PermissionEntry('ควบคุมอุปกรณ์', controlDevices),
        _PermissionEntry('จัดการผู้ใช้และสิทธิ์', manageUsers),
        _PermissionEntry('ดูประวัติ Log', viewLogs),
        _PermissionEntry('ส่งออกรายงาน', exportReports),
        _PermissionEntry('เข้า Support Mode', supportMode),
      ];

  List<String> get grantedLabels => entries
      .where((_PermissionEntry entry) => entry.allowed)
      .map((_PermissionEntry entry) => entry.label)
      .toList();
}

class _PermissionEntry {
  final String label;
  final bool allowed;

  const _PermissionEntry(this.label, this.allowed);
}

class _PriorityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;
  final Color color;
  final VoidCallback onTap;

  const _PriorityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.color,
    required this.onTap,
  });
}

class _RoleTemplate {
  final String name;
  final String description;
  final Color color;
  final _PermissionSet permissions;

  const _RoleTemplate({
    required this.name,
    required this.description,
    required this.color,
    required this.permissions,
  });
}
