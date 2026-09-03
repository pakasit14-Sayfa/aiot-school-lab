import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../widgets/parent_common_widgets.dart';

typedef ParentNotificationsLoader = Future<List<AppNotification>> Function();
typedef ParentNotificationReadMarker =
    Future<void> Function(String notificationId);

class ParentMessagesPage extends StatefulWidget {
  final ParentNotificationsLoader? notificationsLoader;
  final ParentNotificationReadMarker? markRead;

  const ParentMessagesPage({
    super.key,
    this.notificationsLoader,
    this.markRead,
  });

  @override
  State<ParentMessagesPage> createState() => _ParentMessagesPageState();
}

class _ParentMessagesPageState extends State<ParentMessagesPage> {
  static const _empty = 'ยังไม่มีข้อมูล';

  List<AppNotification> _notifications = const [];
  String? _filterType;
  bool _loading = true;
  bool _unauthenticated = false;
  Object? _loadError;
  final Set<String> _markingRead = {};

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
    if (widget.notificationsLoader == null &&
        AuthService.sessionToken == null) {
      setState(() {
        _loading = false;
        _unauthenticated = true;
      });
      return;
    }
    try {
      final items =
          await (widget.notificationsLoader ??
              NotificationService.listMyNotifications)();
      if (!mounted) return;
      final sorted = [...items]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _notifications = sorted;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('ParentMessagesPage load failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _notifications = const [];
        _loadError = error;
        _loading = false;
      });
    }
  }

  List<String> get _types {
    final values = _notifications.map((item) => item.type).toSet().toList()
      ..sort();
    return values;
  }

  List<AppNotification> get _filtered => _filterType == null
      ? _notifications
      : _notifications.where((item) => item.type == _filterType).toList();

  Future<void> _markRead(AppNotification item) async {
    if (!item.isUnread || _markingRead.contains(item.id)) return;
    setState(() => _markingRead.add(item.id));
    try {
      await (widget.markRead ?? NotificationService.markNotificationRead)(
        item.id,
      );
      if (!mounted) return;
      setState(() {
        _notifications = _notifications.map((current) {
          if (current.id != item.id) return current;
          return AppNotification(
            id: current.id,
            type: current.type,
            title: current.title,
            body: current.body,
            createdAt: current.createdAt,
            readAt: DateTime.now(),
          );
        }).toList();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถบันทึกสถานะการอ่านได้')),
      );
    } finally {
      if (mounted) setState(() => _markingRead.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((item) => item.isUnread).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ParentPageHeader(
                    title: 'ข้อความจากโรงเรียน',
                    subtitle: 'ประกาศและการแจ้งเตือนที่ส่งถึงบัญชีผู้ปกครอง',
                    icon: Icons.notifications_rounded,
                  ),
                  const SizedBox(height: 18),
                  _loadState(),
                  const SizedBox(height: 14),
                  _summary(unread),
                  const SizedBox(height: 14),
                  _filters(),
                  const SizedBox(height: 14),
                  _messageList(),
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
    return const SizedBox.shrink();
  }

  Widget _summary(int unread) {
    final cards = [
      _StatData(
        value: _notifications.isEmpty ? _empty : '$unread',
        label: 'ยังไม่ได้อ่าน',
        icon: Icons.mark_email_unread_rounded,
        color: const Color(0xFF2E83C5),
      ),
      _StatData(
        value: _notifications.isEmpty ? _empty : '${_types.length}',
        label: 'ประเภทข้อความ',
        icon: Icons.category_rounded,
        color: const Color(0xFF8A65C7),
      ),
      _StatData(
        value: _notifications.isEmpty ? _empty : '${_notifications.length}',
        label: 'ทั้งหมด',
        icon: Icons.inbox_rounded,
        color: const Color(0xFF18A06F),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 3 : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _StatBox(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _filters() => ParentCard(
    padding: const EdgeInsets.all(13),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('ทั้งหมด'),
          selected: _filterType == null,
          onSelected: (_) => setState(() => _filterType = null),
        ),
        ..._types.map(
          (type) => ChoiceChip(
            label: Text(_typeLabel(type)),
            selected: _filterType == type,
            onSelected: (_) => setState(() => _filterType = type),
          ),
        ),
      ],
    ),
  );

  Widget _messageList() {
    final items = _filtered;
    return ParentCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(_empty, style: TextStyle(color: Color(0xFF7F899A))),
              ),
            )
          : Column(
              children: items
                  .map(
                    (item) => _NotificationTile(
                      item: item,
                      busy: _markingRead.contains(item.id),
                      onTap: () => _markRead(item),
                    ),
                  )
                  .toList(),
            ),
    );
  }
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

class _StatData {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatData({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _StatBox extends StatelessWidget {
  final _StatData data;
  const _StatBox({required this.data});
  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Icon(data.icon, color: data.color, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                data.label,
                style: const TextStyle(color: Color(0xFF7F899A)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  final bool busy;
  final VoidCallback onTap;
  const _NotificationTile({
    required this.item,
    required this.busy,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final color = _typeColor(item.type);
    return InkWell(
      onTap: item.isUnread ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEDF0F4))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(item.type), color: color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isUnread)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 7),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E83C5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.isUnread
                                ? FontWeight.w900
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _formatDateTime(item.createdAt),
                        style: const TextStyle(color: Color(0xFF8993A4)),
                      ),
                    ],
                  ),
                  if (item.body != null && item.body!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      item.body!,
                      style: const TextStyle(color: Color(0xFF667286)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _typeLabel(item.type),
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            if (busy) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _typeLabel(String type) => switch (type) {
  'announcement' => 'ประกาศ',
  'attendance' => 'การเข้าเรียน',
  'assignment' => 'งานและการบ้าน',
  'grade' => 'ผลการเรียน',
  'emergency' => 'เหตุฉุกเฉิน',
  _ => type.isEmpty ? 'ทั่วไป' : type,
};

IconData _typeIcon(String type) => switch (type) {
  'attendance' => Icons.fact_check_rounded,
  'assignment' => Icons.assignment_rounded,
  'grade' => Icons.analytics_rounded,
  'emergency' => Icons.warning_rounded,
  _ => Icons.campaign_rounded,
};

Color _typeColor(String type) => switch (type) {
  'attendance' => const Color(0xFF18A06F),
  'assignment' => const Color(0xFFF09A37),
  'grade' => const Color(0xFF8A65C7),
  'emergency' => const Color(0xFFDA5961),
  _ => const Color(0xFF2E83C5),
};

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final date = '${local.day}/${local.month}/${local.year + 543}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
