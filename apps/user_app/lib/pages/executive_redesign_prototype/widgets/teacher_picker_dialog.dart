import 'package:flutter/material.dart';

import '../data/director_mock_data.dart';
import '../models/director_models.dart';
import '../theme/app_palette.dart';

const List<String> _pickerDepartments = [
  'ทุกฝ่าย',
  'ฝ่ายบริหาร',
  'ฝ่ายวิชาการ',
  'ฝ่ายกิจการนักเรียน',
  'ฝ่ายบุคคลและธุรการ',
  'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม',
  'ฝ่ายเทคโนโลยีและระบบ',
];

const List<TeacherData> _additionalPersonnel = [
  TeacherData(
    id: 101,
    name: 'นายสมชาย บริหารดี',
    subjectGroup: 'งานบริหาร',
    position: 'รองผู้อำนวยการ',
    email: 'admin1@school.ac.th',
  ),
  TeacherData(
    id: 102,
    name: 'นางสาววราภรณ์ ผู้นำดี',
    subjectGroup: 'งานบริหาร',
    position: 'หัวหน้าสำนักงานผู้อำนวยการ',
    email: 'admin2@school.ac.th',
  ),
  TeacherData(
    id: 103,
    name: 'นายณัฐวุฒิ มั่นคง',
    subjectGroup: 'กิจการนักเรียน',
    position: 'หัวหน้าฝ่ายกิจการนักเรียน',
    email: 'studentaffairs@school.ac.th',
  ),
  TeacherData(
    id: 104,
    name: 'นางสาวสุภาวดี ศรีสุข',
    subjectGroup: 'งานบุคคล',
    position: 'เจ้าหน้าที่งานบุคคล',
    email: 'hr@school.ac.th',
  ),
  TeacherData(
    id: 105,
    name: 'นางสาวกมลชนก ธุรการดี',
    subjectGroup: 'งานธุรการ',
    position: 'เจ้าหน้าที่ธุรการ',
    email: 'office@school.ac.th',
  ),
  TeacherData(
    id: 106,
    name: 'นายประสิทธิ์ ช่างดี',
    subjectGroup: 'อาคารสถานที่',
    position: 'เจ้าหน้าที่อาคารสถานที่',
    email: 'building@school.ac.th',
  ),
  TeacherData(
    id: 107,
    name: 'นายเอกชัย รักษ์โรงเรียน',
    subjectGroup: 'สิ่งแวดล้อม',
    position: 'เจ้าหน้าที่สิ่งแวดล้อม',
    email: 'environment@school.ac.th',
  ),
  TeacherData(
    id: 108,
    name: 'นายธนกฤต ระบบดี',
    subjectGroup: 'ระบบสารสนเทศ',
    position: 'เจ้าหน้าที่ระบบสารสนเทศ',
    email: 'it@school.ac.th',
  ),
];

String _pickerDepartmentOf(TeacherData person) {
  if (person.id <= 99) {
    return 'ฝ่ายวิชาการ';
  }

  switch (person.id) {
    case 101:
    case 102:
      return 'ฝ่ายบริหาร';
    case 103:
      return 'ฝ่ายกิจการนักเรียน';
    case 104:
    case 105:
      return 'ฝ่ายบุคคลและธุรการ';
    case 106:
    case 107:
      return 'ฝ่ายอาคารสถานที่และสิ่งแวดล้อม';
    case 108:
      return 'ฝ่ายเทคโนโลยีและระบบ';
    default:
      return 'ฝ่ายวิชาการ';
  }
}

Future<List<TeacherData>?> showTeacherPickerDialog({
  required BuildContext context,
  required String title,
  required bool allowMultiple,
}) {
  String searchText = '';
  String selectedDepartment = 'ทุกฝ่าย';
  String selectedGroup = 'All';
  final Set<int> selectedIds = <int>{};

  return showDialog<List<TeacherData>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final query = searchText.trim().toLowerCase();
          final allPeople = <TeacherData>[
            ...DirectorMockData.teachers,
            ..._additionalPersonnel,
          ];

          final filtered = allPeople.where((person) {
            final department = _pickerDepartmentOf(person);

            final matchesSearch = query.isEmpty ||
                person.name.toLowerCase().contains(query) ||
                person.subjectGroup.toLowerCase().contains(query) ||
                person.position.toLowerCase().contains(query) ||
                department.toLowerCase().contains(query);

            final matchesDepartment =
                selectedDepartment == 'ทุกฝ่าย' ||
                department == selectedDepartment;

            // กลุ่มสาระใช้กรองฝ่ายวิชาการเป็นหลัก
            // ถ้าเลือกฝ่ายอื่นและยังเลือก All จะเห็นบุคลากรฝ่ายนั้นตามปกติ
            final matchesGroup =
                selectedGroup == 'All' ||
                person.subjectGroup == selectedGroup;

            return matchesSearch &&
                matchesDepartment &&
                matchesGroup;
          }).toList();

          final allSelected = filtered.isNotEmpty &&
              filtered.every((teacher) => selectedIds.contains(teacher.id));

          final screen = MediaQuery.of(context).size;
          final width = screen.width < 760 ? screen.width - 24 : 720.0;
          final height =
              screen.height < 840 ? screen.height - 24 : 790.0;

          return Dialog(
            insetPadding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            child: SizedBox(
              width: width,
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppPalette.softPink,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            allowMultiple ? Icons.groups_rounded : Icons.person_search_rounded,
                            color: AppPalette.primaryPink,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              Text(
                                allowMultiple
                                    ? 'ค้นหาชื่อ ฝ่าย หรือกลุ่มสาระ แล้วเลือก All หรือรายคน'
                                    : 'ค้นหาชื่อ ฝ่าย หรือกลุ่มสาระ แล้วเลือก 1 คน',
                                style: const TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: (value) => setDialogState(() => searchText = value),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อครู บุคลากร ฝ่าย หรือกลุ่มสาระ...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppPalette.primaryPink),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppPalette.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // กรองตามฝ่าย
                    Row(
                      children: [
                        const SizedBox(
                          width: 52,
                          child: Text(
                            'ฝ่าย',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _pickerDepartments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final department =
                                    _pickerDepartments[index];
                                final active =
                                    selectedDepartment == department;

                                return ChoiceChip(
                                  label: Text(
                                    department,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  selected: active,
                                  selectedColor:
                                      AppPalette.primaryPinkSoft,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: active
                                        ? AppPalette.primaryPink
                                        : AppPalette.border,
                                  ),
                                  onSelected: (_) {
                                    setDialogState(() {
                                      selectedDepartment = department;

                                      // ถ้าเลือกฝ่ายที่ไม่ใช่วิชาการ
                                      // คืนกลุ่มสาระเป็น All เพื่อไม่ให้กรองจนไม่เหลือข้อมูล
                                      if (department != 'ทุกฝ่าย' &&
                                          department != 'ฝ่ายวิชาการ') {
                                        selectedGroup = 'All';
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // กรองตามกลุ่มสาระ
                    Row(
                      children: [
                        const SizedBox(
                          width: 52,
                          child: Text(
                            'กลุ่มสาระ',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  DirectorMockData.subjectGroups.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final group =
                                    DirectorMockData.subjectGroups[index];
                                final active =
                                    selectedGroup == group;

                                return ChoiceChip(
                                  label: Text(
                                    group == 'All'
                                        ? 'ทุกกลุ่มสาระ'
                                        : group,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  selected: active,
                                  selectedColor:
                                      AppPalette.primaryPinkSoft,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: active
                                        ? AppPalette.primaryPink
                                        : AppPalette.border,
                                  ),
                                  onSelected: (_) {
                                    setDialogState(() {
                                      selectedGroup = group;

                                      // เลือกกลุ่มสาระให้กลับไปฝ่ายวิชาการโดยอัตโนมัติ
                                      if (group != 'All') {
                                        selectedDepartment = 'ฝ่ายวิชาการ';
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    if (allowMultiple)
                      Container(
                        decoration: BoxDecoration(
                          color: AppPalette.softPink,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: CheckboxListTile(
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: AppPalette.primaryPink,
                          value: allSelected,
                          title: const Text(
                            'All — เลือกทั้งหมดตามตัวกรอง',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            'เลือกครูและบุคลากรทั้งหมด ${filtered.length} คนในรายการที่กรอง',
                            style: const TextStyle(fontSize: 10, color: AppPalette.textMuted),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                for (final teacher in filtered) {
                                  selectedIds.add(teacher.id);
                                }
                              } else {
                                for (final teacher in filtered) {
                                  selectedIds.remove(teacher.id);
                                }
                              }
                            });
                          },
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'รายชื่อครูและบุคลากร',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text('${filtered.length} คน', style: const TextStyle(fontSize: 10.5, color: AppPalette.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'ไม่พบรายชื่อครูหรือบุคลากร',
                                  style: TextStyle(
                                    color: AppPalette.textMuted,
                                  ),
                                ),
                              )
                            : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: AppPalette.border),
                              itemBuilder: (context, index) {
                                final teacher = filtered[index];
                                final selected = selectedIds.contains(teacher.id);
                                return InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      if (allowMultiple) {
                                        selected ? selectedIds.remove(teacher.id) : selectedIds.add(teacher.id);
                                      } else {
                                        selectedIds
                                          ..clear()
                                          ..add(teacher.id);
                                      }
                                    });
                                  },
                                  child: Container(
                                    color: selected ? AppPalette.softPink : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 21,
                                          backgroundColor: AppPalette.primaryPinkSoft,
                                          child: Text(
                                            teacher.name.replaceFirst('ครู', '').trim().substring(0, 1),
                                            style: const TextStyle(
                                              color: AppPalette.primaryPinkDark,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(teacher.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${_pickerDepartmentOf(teacher)} • '
                                                '${teacher.subjectGroup} • '
                                                '${teacher.position}',
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 9.8,
                                                  color:
                                                      AppPalette.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (allowMultiple)
                                          Checkbox(
                                            value: selected,
                                            activeColor: AppPalette.primaryPink,
                                            onChanged: (value) {
                                              setDialogState(() {
                                                value == true
                                                    ? selectedIds.add(teacher.id)
                                                    : selectedIds.remove(teacher.id);
                                              });
                                            },
                                          )
                                        else
                                          Radio<int>(
                                            value: teacher.id,
                                            groupValue: selectedIds.isEmpty
                                                ? null
                                                : selectedIds.first,
                                            activeColor: AppPalette.primaryPink,
                                            onChanged: (value) {
                                              if (value == null) return;
                                              setDialogState(() {
                                                selectedIds
                                                  ..clear()
                                                  ..add(value);
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            allowMultiple
                                ? 'เลือกแล้ว ${selectedIds.length} คน'
                                : selectedIds.isEmpty
                                    ? 'ยังไม่ได้เลือกบุคคล'
                                    : 'เลือกแล้ว 1 คน',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.primaryPinkDark,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('ยกเลิก'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppPalette.primaryPink),
                          onPressed: selectedIds.isEmpty
                              ? null
                              : () {
                                  final allPeople = <TeacherData>[
                                    ...DirectorMockData.teachers,
                                    ..._additionalPersonnel,
                                  ];
                                  final selectedPeople = allPeople
                                      .where(
                                        (person) =>
                                            selectedIds.contains(person.id),
                                      )
                                      .toList();
                                  Navigator.pop(
                                    dialogContext,
                                    selectedPeople,
                                  );
                                },
                          icon: const Icon(Icons.check_rounded, size: 17),
                          label: Text(
                            allowMultiple
                                ? 'เลือกผู้เข้าร่วม'
                                : 'เลือกบุคคล',
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
}
