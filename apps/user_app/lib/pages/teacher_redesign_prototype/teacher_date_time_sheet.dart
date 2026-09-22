// ชีตเลือกวัน-เวลาแบบ iOS สำหรับเลนครู (2026-09-22)
//
// แทน showDatePicker + showTimePicker ของ Material ที่เป็นกล่องสี่เหลี่ยม
// สีฟ้าแบบ Android และต้องกดสองรอบ (เลือกวันจบ แล้วกล่องเวลาเด้งตามมาอีกกล่อง)
// ที่นี่คือชีตเดียว: ปฏิทินแบบ iOS + เวลาแบบล้อหมุน กด "เสร็จ" ครั้งเดียวได้ทั้งคู่
//
// ปีแสดงเป็น พ.ศ. ทั้งชีต ให้ตรงกับที่แอปใช้ทุกหน้า (iOS จะโชว์ ค.ศ. ตามระบบ
// ซึ่งไม่ตรงกับที่ครูอ่านในใบงาน)

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;

const _thaiMonthsFull = [
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

const _thaiMonthsShort = [
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];

/// อาทิตย์ขึ้นก่อน ตามปฏิทินไทย
const _weekdayLabels = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

const _weekdayShortThai = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

String _summary(DateTime d) {
  final w = _weekdayShortThai[d.weekday - 1];
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '$w ${d.day} ${_thaiMonthsShort[d.month - 1]} ${d.year + 543} · '
      '$hh:$mm น.';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// เปิดชีตเลือกวัน-เวลา คืน `null` ถ้าผู้ใช้ยกเลิก
Future<DateTime?> showTeacherDateTimeSheet({
  required BuildContext context,
  required DateTime initial,
  required Color accent,
  String title = 'เลือกวันและเวลา',
  DateTime? first,
  DateTime? last,
}) {
  final firstDate = first ?? DateTime(DateTime.now().year - 2);
  final lastDate = last ?? DateTime(DateTime.now().year + 5, 12, 31);
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _DateTimeSheet(
      initial: initial,
      accent: accent,
      title: title,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _DateTimeSheet extends StatefulWidget {
  const _DateTimeSheet({
    required this.initial,
    required this.accent,
    required this.title,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initial;
  final Color accent;
  final String title;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_DateTimeSheet> createState() => _DateTimeSheetState();
}

class _DateTimeSheetState extends State<_DateTimeSheet> {
  late DateTime _selected = widget.initial;
  late DateTime _month = DateTime(widget.initial.year, widget.initial.month);
  bool _timeOpen = false;

  bool get _canPrev =>
      _month.isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));

  bool get _canNext =>
      _month.isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

  bool _enabled(DateTime day) =>
      !day.isBefore(
        DateTime(
          widget.firstDate.year,
          widget.firstDate.month,
          widget.firstDate.day,
        ),
      ) &&
      !day.isAfter(
        DateTime(
          widget.lastDate.year,
          widget.lastDate.month,
          widget.lastDate.day,
        ),
      );

  void _pickDay(DateTime day) {
    setState(() {
      _selected = DateTime(
        day.year,
        day.month,
        day.day,
        _selected.hour,
        _selected.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // weekday ของ Dart: จันทร์=1 … อาทิตย์=7 แต่ตารางเริ่มที่อาทิตย์
    final leading = DateTime(_month.year, _month.month, 1).weekday % 7;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCDBE4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: TeacherPalette.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _summary(_selected),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: TeacherPalette.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDECF5)),

          // ปฏิทินกับล้อเวลาอยู่ในส่วนที่เลื่อนได้ — จอเตี้ย ๆ หรือตอนกางล้อ
          // เวลา เนื้อรวมจะสูงเกินความสูงสูงสุดของ bottom sheet
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── แถวเดือน + ลูกศรเลื่อน ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_thaiMonthsFull[_month.month - 1]} ${_month.year + 543}',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: widget.accent,
                            ),
                          ),
                        ),
                        _ArrowButton(
                          icon: Icons.chevron_left_rounded,
                          accent: widget.accent,
                          onTap: _canPrev
                              ? () => setState(
                                  () => _month = DateTime(
                                    _month.year,
                                    _month.month - 1,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 4),
                        _ArrowButton(
                          icon: Icons.chevron_right_rounded,
                          accent: widget.accent,
                          onTap: _canNext
                              ? () => setState(
                                  () => _month = DateTime(
                                    _month.year,
                                    _month.month + 1,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),

                  // ── ชื่อวัน ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        for (final w in _weekdayLabels)
                          Expanded(
                            child: Center(
                              child: Text(
                                w,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: TeacherPalette.muted,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── ตารางวัน ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1.05,
                          ),
                      itemCount: leading + daysInMonth,
                      itemBuilder: (_, i) {
                        if (i < leading) return const SizedBox.shrink();
                        final day = DateTime(
                          _month.year,
                          _month.month,
                          i - leading + 1,
                        );
                        final selected = _sameDay(day, _selected);
                        final isToday = _sameDay(day, today);
                        final enabled = _enabled(day);
                        return Center(
                          child: GestureDetector(
                            onTap: enabled ? () => _pickDay(day) : null,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? widget.accent
                                    : Colors.transparent,
                                border: !selected && isToday
                                    ? Border.all(
                                        color: widget.accent,
                                        width: 1.4,
                                      )
                                    : null,
                              ),
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: selected || isToday
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: !enabled
                                      ? const Color(0xFFC9C7D2)
                                      : selected
                                      ? Colors.white
                                      : (isToday
                                            ? widget.accent
                                            : TeacherPalette.ink),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),
                  const Divider(
                    height: 1,
                    indent: 20,
                    color: Color(0xFFEDECF5),
                  ),

                  // ── เวลา (กดเพื่อกางล้อหมุนแบบ iOS) ──
                  InkWell(
                    onTap: () => setState(() => _timeOpen = !_timeOpen),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 19,
                            color: TeacherPalette.muted,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'เวลา',
                              style: TextStyle(
                                fontSize: 16,
                                color: TeacherPalette.ink,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _timeOpen
                                  ? widget.accent.withValues(alpha: 0.12)
                                  : const Color(0xFFF2F1F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_selected.hour.toString().padLeft(2, '0')}:'
                              '${_selected.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _timeOpen
                                    ? widget.accent
                                    : TeacherPalette.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    child: _timeOpen
                        ? SizedBox(
                            height: 132,
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              use24hFormat: true,
                              initialDateTime: _selected,
                              onDateTimeChanged: (v) => setState(() {
                                _selected = DateTime(
                                  _selected.year,
                                  _selected.month,
                                  _selected.day,
                                  v.hour,
                                  v.minute,
                                );
                              }),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TeacherPalette.ink,
                      side: const BorderSide(color: Color(0xFFDDDCE4)),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'เสร็จ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      width: 40,
      height: 40,
      child: Icon(
        icon,
        size: 26,
        color: onTap == null ? const Color(0xFFCFCDD8) : accent,
      ),
    ),
  );
}
