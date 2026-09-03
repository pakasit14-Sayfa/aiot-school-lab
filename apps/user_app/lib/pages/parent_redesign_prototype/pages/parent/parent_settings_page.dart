import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../widgets/parent_common_widgets.dart';

typedef ParentSettingsStudentsLoader =
    Future<List<LinkedStudentItem>> Function();
typedef ParentProfileUpdater = Future<void> Function(String uid, String name);
typedef ParentSignOut = Future<void> Function();

class ParentSettingsPage extends StatefulWidget {
  final ParentSettingsStudentsLoader? studentsLoader;
  final UserModel? Function()? userProvider;
  final ParentProfileUpdater? profileUpdater;
  final ParentSignOut? signOut;
  final VoidCallback? onSignedOut;

  const ParentSettingsPage({
    super.key,
    this.studentsLoader,
    this.userProvider,
    this.profileUpdater,
    this.signOut,
    this.onSignedOut,
  });

  @override
  State<ParentSettingsPage> createState() => _ParentSettingsPageState();
}

class _ParentSettingsPageState extends State<ParentSettingsPage> {
  List<LinkedStudentItem> _students = const [];
  bool _loading = true;
  bool _unauthenticated = false;
  bool _savingProfile = false;
  Object? _loadError;
  String? _updatedName;

  UserModel? get _user => (widget.userProvider ?? () => currentUserModel)();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _unauthenticated = false;
      _loadError = null;
    });
    if (widget.studentsLoader == null && AuthService.sessionToken == null) {
      setState(() {
        _loading = false;
        _unauthenticated = true;
      });
      return;
    }
    try {
      final students =
          await (widget.studentsLoader ??
              ParentPortalService.listMyLinkedStudents)();
      if (!mounted) return;
      setState(() {
        _students = students;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('ParentSettingsPage load failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _students = const [];
        _loadError = error;
        _loading = false;
      });
    }
  }

  Future<void> _editName() async {
    final user = _user;
    if (user == null) return;
    var editedName = _updatedName ?? user.name;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขชื่อบัญชี'),
        content: TextFormField(
          initialValue: editedName,
          onChanged: (value) => editedName = value,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, editedName.trim()),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == (_updatedName ?? user.name)) {
      return;
    }
    setState(() => _savingProfile = true);
    try {
      final updater =
          widget.profileUpdater ??
          (String uid, String name) =>
              AuthService.updateProfile(uid: uid, name: name);
      await updater(user.uid, name);
      if (!mounted) return;
      setState(() => _updatedName = name);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลแล้ว')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่สามารถบันทึกข้อมูลได้')));
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await (widget.signOut ?? AuthService.signOut)();
    if (!mounted) return;
    if (widget.onSignedOut != null) {
      widget.onSignedOut!();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final name = _updatedName ?? user?.name;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ParentPageHeader(
                    title: 'ตั้งค่าผู้ปกครอง',
                    subtitle: 'จัดการข้อมูลบัญชีและดูข้อมูลที่เชื่อมกับระบบ',
                    icon: Icons.settings_rounded,
                  ),
                  const SizedBox(height: 20),
                  _loadState(),
                  const SizedBox(height: 14),
                  _accountCard(user, name),
                  const SizedBox(height: 14),
                  _studentsCard(),
                  const SizedBox(height: 14),
                  _notificationSettingsCard(),
                  const SizedBox(height: 14),
                  _securityCard(user),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadState() {
    if (_loading) {
      return const _StateCard(
        icon: Icons.sync_rounded,
        message: 'กำลังโหลดข้อมูล',
      );
    }
    if (_unauthenticated) {
      return const _StateCard(
        icon: Icons.lock_outline_rounded,
        message: 'กรุณาเข้าสู่ระบบเพื่อดูข้อมูล',
      );
    }
    if (_loadError != null) {
      return _StateCard(
        icon: Icons.error_outline_rounded,
        message: 'ไม่สามารถโหลดข้อมูลได้',
        action: TextButton(
          onPressed: _loadData,
          child: const Text('ลองอีกครั้ง'),
        ),
      );
    }
    if (_students.isEmpty) {
      return const _StateCard(
        icon: Icons.person_off_outlined,
        message: 'ยังไม่มีนักเรียนที่เชื่อมกับบัญชีนี้',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _accountCard(UserModel? user, String? name) => ParentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.account_circle_rounded,
          title: 'ข้อมูลบัญชี',
          subtitle: 'ข้อมูลจากเซสชันผู้ใช้ปัจจุบัน',
        ),
        const SizedBox(height: 14),
        if (user == null)
          const _EmptyState()
        else ...[
          _InfoRow(
            label: 'ชื่อ',
            value: name?.isEmpty ?? true ? 'ยังไม่มีข้อมูล' : name!,
          ),
          _InfoRow(
            label: 'อีเมล',
            value: user.email.isEmpty ? 'ยังไม่มีข้อมูล' : user.email,
          ),
          _InfoRow(label: 'บทบาท', value: user.role.label),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _savingProfile ? null : _editName,
            icon: _savingProfile
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_rounded),
            label: const Text('แก้ไขชื่อ'),
          ),
        ],
      ],
    ),
  );

  Widget _studentsCard() => ParentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.family_restroom_rounded,
          title: 'ข้อมูลบุตรหลาน',
          subtitle: 'นักเรียนที่อนุมัติการเชื่อมบัญชีแล้ว',
        ),
        const SizedBox(height: 12),
        if (_students.isEmpty)
          const _EmptyState()
        else
          ..._students.map(
            (student) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEAF3FF),
                child: Icon(Icons.face_rounded, color: Color(0xFF2867B2)),
              ),
              title: Text(
                student.fullName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                student.relationship == null || student.relationship!.isEmpty
                    ? 'ยังไม่มีข้อมูล'
                    : student.relationship!,
              ),
            ),
          ),
      ],
    ),
  );

  Widget _notificationSettingsCard() => const ParentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.notifications_rounded,
          title: 'การตั้งค่าการแจ้งเตือน',
          subtitle: 'ระบบยังไม่มี API สำหรับบันทึกค่ารายบุคคล',
        ),
        SizedBox(height: 14),
        _EmptyState(),
      ],
    ),
  );

  Widget _securityCard(UserModel? user) => ParentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          icon: Icons.security_rounded,
          title: 'ความปลอดภัยบัญชี',
          subtitle: 'จัดการเซสชันของบัญชีปัจจุบัน',
        ),
        const SizedBox(height: 14),
        const _InfoRow(label: 'เปลี่ยนรหัสผ่าน', value: 'ยังไม่มีข้อมูล'),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: user == null ? null : _confirmSignOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('ออกจากระบบ'),
        ),
      ],
    ),
  );
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  const _StateCard({required this.icon, required this.message, this.action});
  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF2867B2)),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
        ?action,
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2867B2), size: 17),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(subtitle, style: const TextStyle(color: Color(0xFF8993A4))),
          ],
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(label, style: const TextStyle(color: Color(0xFF7F899A))),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 22),
    child: Center(
      child: Text('ยังไม่มีข้อมูล', style: TextStyle(color: Color(0xFF8A94A5))),
    ),
  );
}
