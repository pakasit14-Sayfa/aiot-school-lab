import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class ParentPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  const ParentPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF2867B2)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B2536),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF7F899B)),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class ParentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const ParentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: child,
    );
  }
}

class ParentStudentSwitcher extends StatelessWidget {
  final List<LinkedStudentItem> students;
  final LinkedStudentItem? selectedStudent;
  final ValueChanged<String> onSelected;

  const ParentStudentSwitcher({
    super.key,
    required this.students,
    required this.selectedStudent,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedStudent;
    final badge = _StudentBadge(
      student: selected,
      canChange: students.length > 1,
    );
    if (selected == null || students.length < 2) return badge;

    if (MediaQuery.sizeOf(context).width < 820) {
      return InkWell(
        key: const Key('parent-student-switcher'),
        borderRadius: BorderRadius.circular(13),
        onTap: () => _showMobilePicker(context),
        child: badge,
      );
    }

    return PopupMenuButton<String>(
      key: const Key('parent-student-switcher'),
      tooltip: 'เปลี่ยนนักเรียน',
      onSelected: onSelected,
      itemBuilder: (context) => students
          .map(
            (student) => PopupMenuItem<String>(
              value: student.studentId,
              child: SizedBox(
                width: 230,
                child: ListTile(
                  dense: true,
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
                    student.relationship ?? 'นักเรียนที่เชื่อมโยง',
                  ),
                  trailing: student.studentId == selected.studentId
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF2867B2),
                        )
                      : null,
                ),
              ),
            ),
          )
          .toList(),
      child: badge,
    );
  }

  Future<void> _showMobilePicker(BuildContext context) async {
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        key: const Key('parent-student-bottom-sheet'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    '\u0E40\u0E25\u0E37\u0E2D\u0E01\u0E19\u0E31\u0E01\u0E40\u0E23\u0E35\u0E22\u0E19',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEAF3FF),
                          child: Icon(
                            Icons.face_rounded,
                            color: Color(0xFF2867B2),
                          ),
                        ),
                        title: Text(
                          student.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          student.relationship ??
                              '\u0E19\u0E31\u0E01\u0E40\u0E23\u0E35\u0E22\u0E19\u0E17\u0E35\u0E48\u0E40\u0E0A\u0E37\u0E48\u0E2D\u0E21\u0E42\u0E22\u0E07',
                        ),
                        trailing:
                            student.studentId == selectedStudent?.studentId
                            ? const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF2867B2),
                              )
                            : null,
                        onTap: () => Navigator.pop(context, student.studentId),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selectedId != null) onSelected(selectedId);
  }
}

class _StudentBadge extends StatelessWidget {
  final LinkedStudentItem? student;
  final bool canChange;

  const _StudentBadge({required this.student, required this.canChange});

  @override
  Widget build(BuildContext context) {
    final relationship = student?.relationship;
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE1E6EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.face_rounded, color: Color(0xFF2867B2), size: 18),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student?.fullName ?? 'ยังไม่เลือกนักเรียน',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (relationship != null && relationship.trim().isNotEmpty)
                  Text(
                    relationship,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7F899B),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          if (canChange) ...[
            const SizedBox(width: 5),
            const Icon(Icons.expand_more_rounded, size: 17),
          ],
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const MetricTile({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7B8597),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8C96A6),
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
