import 'package:flutter/material.dart';
import 'package:shared_core/models/notification_model.dart';
import 'package:shared_core/services/notification_service.dart';
import 'package:shared_core/services/meeting_service.dart';
import '../controllers/director_notifications_controller.dart';
import '../widgets/director_workspace_widgets.dart';
import '../widgets/meeting_notices_dialog.dart' show noticeCategory;
import '../theme/app_palette.dart';
import 'meeting_detail_page.dart';

// Same pattern as director_emergency_page.dart's _timeAgo — kept local
// rather than shared because neither file imports the other.
String _timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t.toLocal());
  if (diff.inMinutes < 1) return 'เมื่อสักครู่';
  if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
  if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
  return '${diff.inDays} วันที่แล้ว';
}

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
    final color = _categoryColor(item.category ?? 'other');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        contentPadding: EdgeInsets.zero,
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 480,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppPalette.tint(color, 0.12), Colors.white],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          _bentoCategoryIcon(item.category ?? 'other'),
                          size: 21,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: AppPalette.textDark,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppPalette.tint(color, 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    noticeCategory(item.category ?? 'other'),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  dateLabel(item.createdAt),
                                  style: const TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        item.body?.isNotEmpty == true
                            ? item.body!
                            : 'ไม่มีรายละเอียดเพิ่มเติม',
                        style: const TextStyle(fontSize: 13, height: 1.7, color: AppPalette.textDark),
                      ),
                      if (controller.actionError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppPalette.tint(AppPalette.danger, 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            controller.actionError!,
                            style: const TextStyle(fontSize: 11.5, color: AppPalette.danger),
                          ),
                        ),
                      ],
                      if (source == null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppPalette.pageBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 15, color: AppPalette.textMuted),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'รายการนี้ยังไม่มีลิงก์เรื่องต้นทางที่รองรับ',
                                  style: TextStyle(fontSize: 11, color: AppPalette.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // The "เปิดเรื่องต้นทาง" button used to always render, permanently
        // disabled whenever there was no source — a control nobody can ever
        // press adds nothing the info box above doesn't already say, so it's
        // simply absent now instead of shown greyed out.
        actions: [
          if (source != null)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
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
            style: TextButton.styleFrom(foregroundColor: AppPalette.textMuted),
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
              _bentoHeader(controller, locked),
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
              else
                _filtersAndList(controller, filtered, priorities, selectedPriority, locked),
            ],
          ),
        );
      },
    ),
  );

  // Filters + list, side by side on wide screens instead of the filter card
  // sitting above the list — what's currently selected stays visible while
  // scrolling instead of only showing at the top. Below 760px there isn't
  // enough room for a fixed-width rail next to a readable list, so it falls
  // back to the original horizontal chip panel above a full-width list —
  // a rail would need a separate modal/bottom-sheet treatment on mobile,
  // which is a bigger change than this pass covers.
  Widget _filtersAndList(
    DirectorNotificationsController controller,
    List<AppNotification> filtered,
    Set<String> priorities,
    String? selectedPriority,
    bool locked,
  ) {
    // Empty states are shared between the two widths — only the non-empty
    // list gets a genuinely different implementation per width (iOS-style
    // grouped list on mobile, the existing dense table on desktop), since
    // that's the whole point of the mobile redesign, not just a restyle.
    final emptyState = controller.items.isEmpty
        ? const DirectorWorkspaceCard(
            title: 'ยังไม่มีการแจ้งเตือน',
            children: [Text('เมื่อมีข้อความถึงคุณ รายการจะแสดงที่นี่')],
          )
        : filtered.isEmpty
        ? const DirectorWorkspaceCard(
            title: 'ไม่พบรายการที่ตรงกับตัวกรอง',
            children: [Text('ลองเปลี่ยนคำค้น สถานะ หรือช่วงเวลา')],
          )
        : null;

    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 760) {
          return Column(
            children: [
              _mobileFilterHeader(priorities, selectedPriority, locked),
              const SizedBox(height: 16),
              emptyState ?? _iosGroupedList(filtered, locked),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 200, child: _filterRail(priorities, selectedPriority)),
            const SizedBox(width: 16),
            Expanded(child: emptyState ?? _notificationTable(filtered, locked)),
          ],
        );
      },
    );
  }

  Widget _filterRail(Set<String> priorities, String? selectedPriority) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _railLabel('สถานะ'),
          for (final entry in {
            'all': 'ทุกสถานะ',
            'unread': 'ยังไม่อ่าน',
            'read': 'อ่านแล้ว',
          }.entries)
            _railOption(
              label: entry.value,
              selected: status == entry.key,
              onTap: () => setState(() => status = entry.key),
            ),
          _railLabel('ช่วงเวลา', spacingTop: true),
          for (final entry in {
            0: 'ทุกช่วงเวลา',
            -1: 'วันนี้',
            1: '24 ชั่วโมงล่าสุด',
            7: '7 วันล่าสุด',
          }.entries)
            _railOption(
              label: entry.value,
              selected: days == entry.key,
              onTap: () => setState(() => days = entry.key),
            ),
          if (priorities.isNotEmpty) ...[
            _railLabel('ความสำคัญ', spacingTop: true),
            _railOption(
              label: 'ทุกความสำคัญ',
              selected: selectedPriority == null,
              onTap: () => setState(() => priority = null),
            ),
            for (final p in priorities)
              _railOption(
                label: importanceLabel(p),
                selected: selectedPriority == p,
                onTap: () => setState(() => priority = p),
              ),
          ],
          const SizedBox(height: 14),
          const Text(
            'ค้นหาและกรองใน 50 รายการล่าสุดของหมวดที่เลือก · ปุ่มอ่านทั้งหมดครอบคลุมทุกหมวดและรายการเก่า',
            style: TextStyle(fontSize: 9.5, color: AppPalette.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _railLabel(String text, {bool spacingTop = false}) {
    return Padding(
      padding: EdgeInsets.only(top: spacingTop ? 16 : 0, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppPalette.textMuted,
          letterSpacing: .3,
        ),
      ),
    );
  }

  Widget _railOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppPalette.tint(AppPalette.learningBlueDark, 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: selected ? AppPalette.learningBlueDark : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppPalette.learningBlueDark : AppPalette.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Mobile (<760px): native-iOS-styled filter header + a grouped-by-day
  // notification list with swipe-to-mark-read, used only in _filtersAndList's
  // narrow branch. The desktop rail + dense table above are untouched — this
  // is a genuinely separate implementation, not a restyle of the shared one.
  // ===========================================================================

  Widget _mobileFilterHeader(
    Set<String> priorities,
    String? selectedPriority,
    bool locked,
  ) {
    final timeLabel = switch (days) {
      -1 => 'วันนี้',
      1 => '24 ชั่วโมงล่าสุด',
      7 => '7 วันล่าสุด',
      _ => 'ทุกช่วงเวลา',
    };
    final hasExtraFilter = days != 0 || selectedPriority != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iosSegmentedControl<String>(
          options: const [
            MapEntry('all', 'ทุกสถานะ'),
            MapEntry('unread', 'ยังไม่อ่าน'),
            MapEntry('read', 'อ่านแล้ว'),
          ],
          selected: status,
          onChanged: locked ? null : (v) => setState(() => status = v),
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: locked
              ? null
              : () => _openMobileFilterSheet(priorities, selectedPriority),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppPalette.border, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  size: 15,
                  color: hasExtraFilter ? AppPalette.learningBlueDark : AppPalette.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'ช่วงเวลา: $timeLabel',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: hasExtraFilter ? AppPalette.learningBlueDark : AppPalette.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Generic segmented control — capsule track, selected option gets a white
  // pill + soft shadow, matching UISegmentedControl rather than this app's
  // usual spaced-out pill chips (that style stays on the desktop rail).
  Widget _iosSegmentedControl<T>({
    required List<MapEntry<T, String>> options,
    required T selected,
    required ValueChanged<T>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onChanged == null ? null : () => onChanged(o.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: o.key == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: o.key == selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    o.value,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: o.key == selected ? FontWeight.w800 : FontWeight.w600,
                      color: o.key == selected ? AppPalette.textDark : AppPalette.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openMobileFilterSheet(
    Set<String> priorities,
    String? selectedPriority,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppPalette.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const Text('ช่วงเวลา', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              for (final entry in {
                0: 'ทุกช่วงเวลา',
                -1: 'วันนี้',
                1: '24 ชั่วโมงล่าสุด',
                7: '7 วันล่าสุด',
              }.entries)
                _sheetOption(
                  label: entry.value,
                  selected: days == entry.key,
                  onTap: () {
                    setState(() => days = entry.key);
                    Navigator.pop(sheetContext);
                  },
                ),
              if (priorities.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('ความสำคัญ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                _sheetOption(
                  label: 'ทุกความสำคัญ',
                  selected: selectedPriority == null,
                  onTap: () {
                    setState(() => priority = null);
                    Navigator.pop(sheetContext);
                  },
                ),
                for (final p in priorities)
                  _sheetOption(
                    label: importanceLabel(p),
                    selected: selectedPriority == p,
                    onTap: () {
                      setState(() => priority = p);
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppPalette.learningBlueDark : AppPalette.textDark,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, size: 18, color: AppPalette.learningBlueDark),
          ],
        ),
      ),
    );
  }

  // Buckets by calendar day (not the RPC's fixed order) — items already
  // arrive newest-first, so building this as an insertion-ordered Map while
  // iterating keeps same-day items adjacent without a separate sort.
  String _dayGroupLabel(DateTime createdAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = createdAt.toLocal();
    final thatDay = DateTime(that.year, that.month, that.day);
    final diff = today.difference(thatDay).inDays;
    if (diff <= 0) return 'วันนี้';
    if (diff == 1) return 'เมื่อวาน';
    return '$diff วันที่แล้ว';
  }

  Widget _iosGroupedList(List<AppNotification> items, bool locked) {
    final groups = <String, List<AppNotification>>{};
    for (final n in items) {
      groups.putIfAbsent(_dayGroupLabel(n.createdAt), () => []).add(n);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(
              entry.key,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppPalette.textMuted,
                letterSpacing: .3,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.border, width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < entry.value.length; i++)
                  _iosRow(entry.value[i], locked, showDivider: i < entry.value.length - 1),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // Read rows are plain (nothing left to swipe for); unread rows wrap in a
  // Dismissible that always snaps back (confirmDismiss returns false) — the
  // swipe never actually removes the item, it just triggers mark(n.id) as a
  // side effect, same as the desktop checkmark icon does.
  Widget _iosRow(AppNotification n, bool locked, {required bool showDivider}) {
    final unread = n.isUnread;
    final color = _categoryColor(n.category ?? 'other');
    final content = InkWell(
      onTap: locked ? null : () => details(n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppPalette.border, width: 1))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Icon(_bentoCategoryIcon(n.category ?? 'other'), size: 16, color: Colors.white),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    n.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      color: unread ? AppPalette.textDark : AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    noticeCategory(n.category ?? 'other'),
                    style: const TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 6),
                decoration: const BoxDecoration(
                  color: AppPalette.learningBlueDark,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              _timeAgo(n.createdAt),
              style: const TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );

    if (!unread) return content;

    return Dismissible(
      key: ValueKey('mobile-notif-${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppPalette.success,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_rounded, size: 16, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'อ่านแล้ว',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (locked) return false;
        await mark(n.id);
        return false;
      },
      child: content,
    );
  }

  // Bento summary strip — replaces the old full-width pink hero + a
  // separate button row + the stat/search/category block that used to open
  // the "กล่องข้อความของฉัน" card. Same materials as the rest of this lane
  // (DirectorWorkspaceHero's gradient, DirectorWorkspaceCard's shadow/border
  // recipe), just reshaped into tiles instead of stacked full-width blocks.
  // Stacks to a single column under 900px — raised from an earlier 760px
  // because at tablet widths (768/820) the hero and the actions+category
  // column were both too cramped side by side; matches the 980px breakpoint
  // director_learning_page.dart's hero uses for the same reason.
  Widget _bentoHeader(DirectorNotificationsController controller, bool locked) {
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 900;
        final hero = _bentoHero(controller);
        final categoryTilesRow = _bentoCategoryTilesRow(controller, locked, stretch: !narrow);
        final resetLink = controller.category == null
            ? null
            : InkWell(
                onTap: locked ? null : () => controller.load(),
                child: const Text(
                  'แสดงทุกหมวด',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.learningBlueDark,
                    decoration: TextDecoration.underline,
                  ),
                ),
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero takes the full row alone once there are no category
            // tiles to sit beside it — used to always share the row with
            // an actions tile (refresh / mark-all-read). Removed by request:
            // no replacement surfaced for either action, so there is
            // currently no manual refresh and no bulk mark-read in the UI —
            // marking read now only happens per-row (dense list below) or
            // implicitly whenever a category/status/time filter is tapped
            // (each triggers controller.load, which re-fetches).
            //
            // On wide screens the tiles used to size to their own natural
            // (much shorter) content height, leaving them visibly shorter
            // than the hero next to them. IntrinsicHeight + stretch makes
            // both match the taller one's height — safe here specifically
            // because neither hero nor the tiles row contains a Column with
            // its own Expanded/Flexible child or a LayoutBuilder; either one
            // would make Flutter's intrinsic-height query throw ("RenderFlex
            // children have non-zero flex but incoming height constraints
            // are unbounded" / "LayoutBuilder does not support returning
            // intrinsic dimensions"). The reset link is deliberately kept
            // outside this row so it never has to participate in that
            // query.
            if (categoryTilesRow == null)
              hero
            else if (narrow)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [hero, const SizedBox(height: 12), categoryTilesRow],
              )
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: hero),
                    const SizedBox(width: 12),
                    Expanded(child: categoryTilesRow),
                  ],
                ),
              ),
            if (resetLink != null) ...[const SizedBox(height: 8), resetLink],
            const SizedBox(height: 12),
            _bentoSearchField(),
          ],
        );
      },
    );
  }

  Widget _bentoHero(DirectorNotificationsController controller) {
    final total = controller.total, unread = controller.unread;
    final ratio = total == 0 ? 0.0 : unread / total;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.primaryPinkDark, AppPalette.heroPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'การแจ้งเตือน',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'ข้อความถึงคุณจากระบบโรงเรียน',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.notifications_none, color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ยังไม่อ่าน จากทั้งหมด $total',
                      style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              _bentoUnreadRing(ratio),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bentoUnreadRing(double ratio) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: ratio,
              strokeWidth: 5,
              backgroundColor: Colors.white.withAlpha(46),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppPalette.primaryPinkDark,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${(ratio * 100).round()}%',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }


  // Categories used to be pill chips with a permanent "ทุกหมวด" chip; here
  // each category is its own tile and tapping the already-selected one
  // toggles back to "all" (the "แสดงทุกหมวด" link below covers the same
  // reset without needing a dedicated all-categories tile).
  //
  // Tile width used to be a fixed 128px, which either left odd gaps on wide
  // screens or wrapped unevenly on narrow ones (this tile row sits inside a
  // column roughly half the page width on desktop, not the full width, so
  // "narrow" happens more often than the outer breakpoint alone suggests).
  // Column count now comes from the row's own available width so 2-5
  // categories always lay out evenly instead of wrapping arbitrarily.
  // Plain Row of Expanded tiles instead of a Wrap over a LayoutBuilder-
  // computed column count — Expanded already distributes width evenly at
  // any tile count without needing that manual computation, and (more
  // importantly) it's what lets this row participate safely in the
  // IntrinsicHeight/stretch pairing with the hero in _bentoHeader; a
  // LayoutBuilder in this subtree would make that height query throw.
  // `stretch` must be false whenever this row isn't wrapped in an
  // IntrinsicHeight giving it a bounded height (the narrow/stacked branch in
  // _bentoHeader) — CrossAxisAlignment.stretch under an unbounded height
  // throws "BoxConstraints forces an infinite height", it doesn't just look
  // wrong. Only the wide/side-by-side branch can safely pass true.
  Widget? _bentoCategoryTilesRow(
    DirectorNotificationsController controller,
    bool locked, {
    required bool stretch,
  }) {
    final categories = controller.categories;
    if (categories.isEmpty) return null;
    return Row(
      crossAxisAlignment: stretch ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < categories.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _bentoCategoryTile(controller, categories[i], locked)),
        ],
      ],
    );
  }

  IconData _bentoCategoryIcon(String category) => switch (category) {
    'meeting' => Icons.groups_rounded,
    'request' => Icons.assignment_outlined,
    'incident' => Icons.warning_amber_rounded,
    'learning' => Icons.school_outlined,
    _ => Icons.notifications_none,
  };

  // Per-category solid tint instead of the single learningBlueDark accent
  // every tile used before — same colors _categoryColor already uses for
  // the dense list's dots/labels below, so a category reads as the same
  // color everywhere on the page, not just in one spot. Shows total count
  // only (no unread breakdown) by request, to match the reference design.
  Widget _bentoCategoryTile(
    DirectorNotificationsController controller,
    NotificationCategory c,
    bool locked,
  ) {
    final selected = controller.category == c.category;
    final color = _categoryColor(c.category);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: locked ? null : () => controller.load(filter: selected ? null : c.category),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.tint(color, selected ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(18),
          border: selected ? Border.all(color: color, width: 1.6) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppPalette.tint(color, 0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_bentoCategoryIcon(c.category), size: 16, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              noticeCategory(c.category),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppPalette.textDark),
            ),
            const SizedBox(height: 2),
            Text(
              '${c.total}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppPalette.textDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bentoSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'ค้นหาหัวข้อหรือข้อความ',
          hintStyle: TextStyle(fontSize: 12),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppPalette.learningBlueDark),
          isDense: true,
          filled: false,
          // roleTheme's InputDecorationTheme sets enabledBorder/focusedBorder
          // explicitly, so `border: InputBorder.none` alone doesn't suppress
          // them — Flutter only falls back to `border` when those are null.
          // Left unset, the theme's grey outline box gets drawn nested
          // inside this tile's own border/shadow, i.e. two boxes stacked.
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (v) => setState(() => query = v),
      ),
    );
  }

  // Dense table rows — replaces the soft floating card-per-row list. One
  // bordered container with thin dividers instead of a shadowed card per
  // item, so scanning many notifications doesn't mean scrolling through as
  // much whitespace. Category used to only be readable via a text badge;
  // here it also gets a color (dot + label), reusing colors already in
  // AppPalette (warning/danger/success/learningBlueDark) rather than
  // inventing a new palette. The "ความสำคัญ" badge that used to show next
  // to the category badge is dropped here — there's no room on a single
  // dense line, and every real notification type in this codebase writes
  // `severity` into its payload, never `priority` (the key this page reads),
  // so that badge was already always empty on any row generated by real
  // backend code, never just by this seed data.
  Widget _notificationTable(List<AppNotification> items, bool locked) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border, width: 1.2),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _notificationRow(items[i], locked, showDivider: i < items.length - 1),
        ],
      ),
    );
  }

  Color _categoryColor(String category) => switch (category) {
    'meeting' => AppPalette.learningBlueDark,
    'request' => AppPalette.warning,
    'incident' => AppPalette.danger,
    'learning' => AppPalette.success,
    _ => AppPalette.textMuted,
  };

  Widget _notificationRow(AppNotification n, bool locked, {required bool showDivider}) {
    final unread = n.isUnread;
    final color = _categoryColor(n.category ?? 'other');
    return InkWell(
      onTap: locked ? null : () => details(n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppPalette.border, width: 1))
              : null,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            // Category label dropped under ~380px so the title keeps
            // enough room to stay readable — the color dot still carries
            // category identity even without the text.
            final showCategoryLabel = box.maxWidth >= 380;
            return Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    n.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      color: unread ? AppPalette.textDark : AppPalette.textMuted,
                    ),
                  ),
                ),
                if (showCategoryLabel) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 76,
                    child: Text(
                      noticeCategory(n.category ?? 'other'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    _timeAgo(n.createdAt),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 10, color: AppPalette.textMuted),
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: locked ? null : () => mark(n.id),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppPalette.tint(color, 0.14),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Tooltip(
                        message: 'ทำเครื่องหมายอ่านแล้ว',
                        child: Icon(Icons.done_rounded, size: 13, color: color),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

}
