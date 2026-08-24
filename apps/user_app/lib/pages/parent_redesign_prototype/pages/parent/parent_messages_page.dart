import 'package:flutter/material.dart';
import '../../widgets/parent_common_widgets.dart';

/// หมวดหมู่ข้อความ — ใช้โทนสีเดิมของแอป
class _MsgCategory {
  final String label;
  final IconData icon;
  final Color color;
  const _MsgCategory(this.label, this.icon, this.color);
}

const _catTeacher =
    _MsgCategory('ครูประจำชั้น', Icons.person_rounded, Color(0xFF2E83C5));
const _catAcademic =
    _MsgCategory('ฝ่ายวิชาการ', Icons.school_rounded, Color(0xFF8A65C7));
const _catClub =
    _MsgCategory('ชมรม/กิจกรรม', Icons.palette_rounded, Color(0xFFF09A37));
const _catPr =
    _MsgCategory('ประชาสัมพันธ์', Icons.campaign_rounded, Color(0xFF18A06F));
const _catFinance =
    _MsgCategory('การเงิน', Icons.payments_rounded, Color(0xFFDA5961));

const _allCategories = <_MsgCategory>[
  _catTeacher,
  _catAcademic,
  _catClub,
  _catPr,
  _catFinance,
];

class _Message {
  final _MsgCategory category;
  final String sender;
  final String subject;
  final String preview;
  final String time;
  final bool unread;
  final bool important;
  final bool hasAttachment;

  const _Message({
    required this.category,
    required this.sender,
    required this.subject,
    required this.preview,
    required this.time,
    this.unread = false,
    this.important = false,
    this.hasAttachment = false,
  });
}

const _messages = <_Message>[
  _Message(
    category: _catTeacher,
    sender: 'ครูสมหญิง (ครูประจำชั้น ม.2/1)',
    subject: 'เตรียมอุปกรณ์วิชาวิทยาศาสตร์',
    preview:
        'พรุ่งนี้ให้นักเรียนเตรียมอุปกรณ์การทดลอง ได้แก่ ถุงมือยาง แว่นตานิรภัย และสมุดบันทึกผลการทดลอง คาบเรียนที่ 3–4',
    time: '10:20',
    unread: true,
    important: true,
  ),
  _Message(
    category: _catAcademic,
    sender: 'ฝ่ายวิชาการ',
    subject: 'กำหนดการสอบกลางภาค',
    preview:
        'แจ้งกำหนดการสอบกลางภาค ระหว่างวันที่ 7–11 ก.ย. รายละเอียดตารางสอบและห้องสอบตามเอกสารแนบ',
    time: 'เมื่อวาน',
    unread: true,
    hasAttachment: true,
  ),
  _Message(
    category: _catClub,
    sender: 'ชมรมศิลปะ',
    subject: 'เลื่อนเวลากิจกรรมวันศุกร์',
    preview:
        'กิจกรรมชมรมวันศุกร์นี้เลื่อนเป็นเวลา 15:30 น. ณ ห้องศิลปะ อาคาร 2 นักเรียนที่สนใจสามารถเข้าร่วมได้',
    time: '19 ส.ค.',
  ),
  _Message(
    category: _catPr,
    sender: 'งานประชาสัมพันธ์',
    subject: 'เชิญร่วมงานวันวิทยาศาสตร์',
    preview:
        'ขอเชิญผู้ปกครองและนักเรียนร่วมกิจกรรมวันวิทยาศาสตร์ วันที่ 25 ส.ค. เวลา 08:30–15:00 น. ณ หอประชุมโรงเรียน',
    time: '18 ส.ค.',
    hasAttachment: true,
  ),
  _Message(
    category: _catFinance,
    sender: 'ฝ่ายการเงิน',
    subject: 'แจ้งกำหนดชำระค่ากิจกรรม',
    preview:
        'กรุณาชำระค่ากิจกรรมทัศนศึกษา จำนวน 450 บาท ภายในวันที่ 29 ส.ค. ผ่านช่องทางที่โรงเรียนกำหนด',
    time: '16 ส.ค.',
    important: true,
  ),
  _Message(
    category: _catTeacher,
    sender: 'ครูวิชาคณิตศาสตร์',
    subject: 'ติดตามการส่งการบ้าน',
    preview:
        'นักเรียนยังค้างส่งแบบฝึกหัดบทที่ 4 กรุณาส่งภายในสัปดาห์นี้ หากมีข้อสงสัยสามารถสอบถามได้ในคาบเรียน',
    time: '15 ส.ค.',
  ),
];

class ParentMessagesPage extends StatefulWidget {
  const ParentMessagesPage({super.key});

  @override
  State<ParentMessagesPage> createState() => _ParentMessagesPageState();
}

class _ParentMessagesPageState extends State<ParentMessagesPage> {
  // ตัวกรองหมวดหมู่ — null = ทั้งหมด
  String? _filterLabel;

  List<_Message> get _filtered => _filterLabel == null
      ? _messages
      : _messages.where((m) => m.category.label == _filterLabel).toList();

  @override
  Widget build(BuildContext context) {
    final unreadCount = _messages.where((m) => m.unread).length;
    final importantCount = _messages.where((m) => m.important).length;
    final list = _filtered;

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
                    subtitle:
                        'ประกาศ ข้อความจากครู และเรื่องที่ผู้ปกครองควรทราบ',
                    icon: Icons.chat_bubble_rounded,
                  ),
                  const SizedBox(height: 18),

                  // ---- แถบสรุปตัวเลข ----
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          value: '$unreadCount',
                          label: 'ยังไม่ได้อ่าน',
                          icon: Icons.mark_email_unread_rounded,
                          color: const Color(0xFF2E83C5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          value: '$importantCount',
                          label: 'เรื่องสำคัญ',
                          icon: Icons.priority_high_rounded,
                          color: const Color(0xFFDA5961),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          value: '${_messages.length}',
                          label: 'ทั้งหมด',
                          icon: Icons.inbox_rounded,
                          color: const Color(0xFF18A06F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ---- ชิปตัวกรองหมวดหมู่ ----
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CategoryChip(
                        label: 'ทั้งหมด',
                        icon: Icons.all_inbox_rounded,
                        color: const Color(0xFF2867B2),
                        selected: _filterLabel == null,
                        onTap: () => setState(() => _filterLabel = null),
                      ),
                      for (final cat in _allCategories)
                        _CategoryChip(
                          label: cat.label,
                          icon: cat.icon,
                          color: cat.color,
                          selected: _filterLabel == cat.label,
                          onTap: () =>
                              setState(() => _filterLabel = cat.label),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ---- รายการข้อความ ----
                  if (list.isEmpty)
                    const ParentCard(
                      padding: EdgeInsets.symmetric(
                          vertical: 40, horizontal: 18),
                      child: Center(
                        child: Text(
                          'ไม่มีข้อความในหมวดนี้',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7F899A),
                          ),
                        ),
                      ),
                    )
                  else
                    ParentCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          for (int i = 0; i < list.length; i++)
                            _MessageTile(
                              message: list[i],
                              showDivider: i != list.length - 1,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== วิดเจ็ตย่อย ====================

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B2536),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF7F899A),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : const Color(0xFFE7EAF0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF56606F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final _Message message;
  final bool showDivider;

  const _MessageTile({required this.message, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final cat = message.category;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFEDF0F4)),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- อวตาร์ ----
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(cat.icon, color: cat.color, size: 22),
            ),
            const SizedBox(width: 12),
            // ---- เนื้อหา ----
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (message.unread)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDA5961),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          message.sender,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: message.unread
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: const Color(0xFF1B2536),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        message.time,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9AA2AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cat.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: Color(0xFF7F899A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Tag(label: cat.label, color: cat.color),
                      if (message.important)
                        const _Tag(
                          label: 'สำคัญ',
                          color: Color(0xFFDA5961),
                          icon: Icons.flag_rounded,
                        ),
                      if (message.hasAttachment)
                        const _Tag(
                          label: 'ไฟล์แนบ',
                          color: Color(0xFF56606F),
                          icon: Icons.attach_file_rounded,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Tag({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
