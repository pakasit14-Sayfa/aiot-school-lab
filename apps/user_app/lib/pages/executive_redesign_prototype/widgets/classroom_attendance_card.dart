import 'package:flutter/material.dart';
import '../controllers/classroom_attendance_controller.dart';
import 'director_workspace_widgets.dart';

class ClassroomAttendanceCard extends StatefulWidget {
  const ClassroomAttendanceCard({super.key, required this.controller});
  final ClassroomAttendanceController controller;
  @override
  State<ClassroomAttendanceCard> createState() =>
      _ClassroomAttendanceCardState();
}

class _ClassroomAttendanceCardState extends State<ClassroomAttendanceCard> {
  late final ClassroomAttendanceController controller = widget.controller;
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final c = controller;
      final row = c.data;
      return DirectorWorkspaceCard(
        title: 'เช็คชื่อรายห้อง',
        icon: Icons.fact_check_outlined,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${c.date.day}/${c.date.month}/${c.date.year + 543}'),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: const Text('เลือกวันที่'),
                onPressed: c.loading
                    ? null
                    : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: c.date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null && mounted) await c.load(date);
                      },
              ),
              TextButton(
                onPressed: c.loading ? null : () => c.load(),
                child: const Text('โหลดใหม่'),
              ),
            ],
          ),
          if (c.loading)
            const LinearProgressIndicator()
          else if (c.error != null)
            Text(c.error!)
          else if (row == null)
            const Text('ยังไม่มีข้อมูลกลุ่มนักเรียนของห้องนี้')
          else ...[
            Text('นักเรียนที่ใช้งานอยู่ ${row.studentCount} คน'),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('มา ${row.present}'),
                Text('สาย ${row.late}'),
                Text('ขาด ${row.absent}'),
                Text('ลา ${row.excused}'),
                Text('ยังไม่เช็คชื่อ ${row.unknown}'),
              ],
            ),
            Text(
              row.attendancePercent == null
                  ? 'ยังไม่มีผลเช็คชื่อสำหรับคำนวณอัตรามาเรียน'
                  : 'อัตรามาเรียน ${row.attendancePercent!.toStringAsFixed(1)}% จากผู้ที่เช็คชื่อแล้ว ${row.recorded} คน',
            ),
            const Text(
              'นับมาและสายเป็นมาเรียน ไม่รวมผู้ที่ยังไม่เช็คชื่อในฐานคำนวณ · ใช้กลุ่มนักเรียนปัจจุบัน',
            ),
          ],
        ],
      );
    },
  );
}
