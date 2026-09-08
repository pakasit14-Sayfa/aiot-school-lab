import 'package:flutter/material.dart';
import 'package:shared_core/models/notification_model.dart';
import 'package:shared_core/services/notification_service.dart';
import 'package:shared_core/services/meeting_service.dart';
import '../controllers/director_notifications_controller.dart';
import '../widgets/director_workspace_widgets.dart';
import '../widgets/meeting_notices_dialog.dart' show noticeCategory;
import '../theme/app_palette.dart';
import 'meeting_detail_page.dart';

class DirectorNotificationsPage extends StatefulWidget {
  const DirectorNotificationsPage({super.key, this.service});
  final NotificationService? service;
  @override
  State<DirectorNotificationsPage> createState() =>
      _DirectorNotificationsPageState();
}

class _DirectorNotificationsPageState extends State<DirectorNotificationsPage> {
  late final controller = DirectorNotificationsController(
    widget.service ?? NotificationService(),
  );
  String query = '', status = 'all';
  String? priority;
  int days = 0;
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String? importance(AppNotification n) {
    final value = n.payload['priority'];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  String importanceLabel(String value) => switch (value) {
    'urgent' => 'เร่งด่วน',
    'high' => 'สูง',
    'medium' => 'ปานกลาง',
    'low' => 'ต่ำ',
    _ => value,
  };
  String dateLabel(DateTime value) {
    final d = value.toLocal();
    return '${d.day}/${d.month}/${d.year + 543} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String? meetingId(AppNotification n) {
    final value = n.payload['meeting_id'];
    return n.type.startsWith('meeting_') &&
            value is String &&
            RegExp(
              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
            ).hasMatch(value)
        ? value
        : null;
  }

  Future<void> mark([String? id]) async {
    final ok = await controller.markRead(id);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกสถานะอ่านและตรวจสอบแล้ว')),
    );
  }

  Future<void> details(AppNotification item) async {
    if (item.isUnread) await mark(item.id);
    if (!mounted) return;
    final source = meetingId(item);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateLabel(item.createdAt)),
                const SizedBox(height: 16),
                SelectableText(
                  item.body?.isNotEmpty == true
                      ? item.body!
                      : 'ไม่มีรายละเอียดเพิ่มเติม',
                ),
                if (controller.actionError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    controller.actionError!,
                    style: const TextStyle(color: AppPalette.danger),
                  ),
                ],
                const SizedBox(height: 16),
                if (source == null)
                  const Text('รายการนี้ยังไม่มีลิงก์เรื่องต้นทางที่รองรับ'),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: source == null
                ? null
                : () {
                    Navigator.pop(context);
                    Navigator.of(this.context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MeetingDetailPage(
                          service: MeetingService(),
                          meetingId: source,
                        ),
                      ),
                    );
                  },
            child: const Text('เปิดเรื่องต้นทาง'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DirectorWorkspace(
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final priorities = controller.items
            .map(importance)
            .whereType<String>()
            .toSet();
        final selectedPriority = priorities.contains(priority)
            ? priority
            : null;
        final now = DateTime.now();
        final cutoff = days == -1
            ? DateTime(now.year, now.month, now.day)
            : now.subtract(Duration(days: days));
        final filtered = controller.items.where((n) {
          final q = query.trim().toLowerCase();
          return ('${n.title} ${n.body ?? ''}'.toLowerCase().contains(q)) &&
              (status == 'all' || (status == 'unread') == n.isUnread) &&
              (selectedPriority == null || importance(n) == selectedPriority) &&
              (days == 0 ||
                  (!n.createdAt.isBefore(cutoff) && !n.createdAt.isAfter(now)));
        }).toList();
        final locked = controller.busy || controller.loading;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DirectorWorkspaceHero(
                title: 'การแจ้งเตือน',
                subtitle: 'ข้อความถึงคุณจากระบบโรงเรียน',
                icon: Icons.notifications_none,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: locked
                        ? null
                        : () => controller.load(filter: controller.category),
                    icon: const Icon(Icons.refresh),
                    label: const Text('โหลดข้อมูลใหม่'),
                  ),
                  FilledButton.icon(
                    onPressed:
                        locked ||
                            controller.error != null ||
                            controller.unread == 0
                        ? null
                        : () => mark(),
                    icon: const Icon(Icons.done_all),
                    label: const Text('อ่านทั้งหมดในกล่องข้อความ'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (controller.actionError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    controller.actionError!,
                    style: const TextStyle(color: AppPalette.danger),
                  ),
                ),
              if (controller.loading)
                const DirectorWorkspaceCard(
                  title: 'กำลังโหลดการแจ้งเตือน',
                  children: [LinearProgressIndicator()],
                )
              else if (controller.error != null)
                DirectorWorkspaceCard(
                  title: 'โหลดไม่สำเร็จ',
                  children: [
                    Text(controller.error!),
                    TextButton(
                      onPressed: () =>
                          controller.load(filter: controller.category),
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                )
              else ...[
                DirectorWorkspaceCard(
                  title: 'กล่องข้อความของฉัน',
                  children: [
                    Text(
                      'ทั้งหมด ${controller.total} รายการ · ยังไม่อ่าน ${controller.unread} รายการ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'ค้นหาหัวข้อหรือข้อความ',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('ทุกหมวด'),
                          selected: controller.category == null,
                          onSelected: locked ? null : (_) => controller.load(),
                        ),
                        for (final c in controller.categories)
                          ChoiceChip(
                            label: Text(
                              '${noticeCategory(c.category)} (${c.unread})',
                            ),
                            selected: controller.category == c.category,
                            onSelected: locked
                                ? null
                                : (_) => controller.load(filter: c.category),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in {
                          'all': 'ทุกสถานะ',
                          'unread': 'ยังไม่อ่าน',
                          'read': 'อ่านแล้ว',
                        }.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: status == entry.key,
                            onSelected: (_) =>
                                setState(() => status = entry.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in {
                          0: 'ทุกช่วงเวลา',
                          -1: 'วันนี้',
                          1: '24 ชั่วโมงล่าสุด',
                          7: '7 วันล่าสุด',
                        }.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: days == entry.key,
                            onSelected: (_) => setState(() => days = entry.key),
                          ),
                      ],
                    ),
                    if (priorities.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('ทุกความสำคัญ'),
                            selected: selectedPriority == null,
                            onSelected: (_) => setState(() => priority = null),
                          ),
                          for (final p in priorities)
                            ChoiceChip(
                              label: Text(importanceLabel(p)),
                              selected: selectedPriority == p,
                              onSelected: (_) => setState(() => priority = p),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'ค้นหาและกรองใน 50 รายการล่าสุดของหมวดที่เลือก · ปุ่มอ่านทั้งหมดครอบคลุมทุกหมวดและรายการเก่า',
                    ),
                  ],
                ),
                if (controller.items.isEmpty)
                  const DirectorWorkspaceCard(
                    title: 'ยังไม่มีการแจ้งเตือน',
                    children: [Text('เมื่อมีข้อความถึงคุณ รายการจะแสดงที่นี่')],
                  )
                else if (filtered.isEmpty)
                  const DirectorWorkspaceCard(
                    title: 'ไม่พบรายการที่ตรงกับตัวกรอง',
                    children: [Text('ลองเปลี่ยนคำค้น สถานะ หรือช่วงเวลา')],
                  )
                else
                  for (final n in filtered)
                    DirectorWorkspaceCard(
                      title: n.title,
                      icon: n.isUnread
                          ? Icons.mark_email_unread_outlined
                          : Icons.drafts_outlined,
                      accent: n.isUnread
                          ? AppPalette.primaryPinkDark
                          : const Color(0xFF356A9A),
                      children: [
                        Text(
                          '${noticeCategory(n.category ?? 'other')} · ${dateLabel(n.createdAt)}',
                        ),
                        const SizedBox(height: 8),
                        if (n.body?.isNotEmpty == true)
                          Text(
                            n.body!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 12),
                        Text(
                          '${n.isUnread ? 'ยังไม่อ่าน' : 'อ่านแล้ว'} · ความสำคัญ: ${importance(n) == null ? 'ไม่ได้ระบุ' : importanceLabel(importance(n)!)}',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: locked ? null : () => details(n),
                              child: const Text('ดูรายละเอียด'),
                            ),
                            if (n.isUnread)
                              TextButton(
                                onPressed: locked ? null : () => mark(n.id),
                                child: const Text('ทำเครื่องหมายอ่านแล้ว'),
                              ),
                          ],
                        ),
                      ],
                    ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
