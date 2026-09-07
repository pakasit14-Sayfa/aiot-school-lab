/// ฝ่าย (administrative) or กลุ่มสาระการเรียนรู้ (subject group).
///
/// Both are rows in `departments`, told apart by [kind]. They are per-school:
/// the six ฝ่าย and ten กลุ่มสาระ that used to be hardcoded in the UI were one
/// school's structure shown to every tenant.
class SchoolDepartment {
  const SchoolDepartment({
    required this.departmentId,
    required this.name,
    required this.kind,
    required this.sortOrder,
    required this.memberCount,
    this.headName,
  });

  final String departmentId;
  final String name;

  /// `administrative` (ฝ่าย) or `subject_group` (กลุ่มสาระ). Kept as the raw
  /// backend string so the UI cannot invent a third kind.
  final String kind;
  final int sortOrder;

  /// How many staff are assigned. Counted by the RPC, not by the page.
  final int memberCount;

  /// หัวหน้าฝ่าย / หัวหน้ากลุ่มสาระ, or null when nobody is marked as head —
  /// which is different from "the head is unknown to us".
  final String? headName;

  bool get isAdministrative => kind == 'administrative';
  bool get isSubjectGroup => kind == 'subject_group';

  factory SchoolDepartment.fromRow(Map<String, dynamic> row) =>
      SchoolDepartment(
        departmentId: row['department_id'].toString(),
        name: row['name']?.toString() ?? '',
        kind: row['kind']?.toString() ?? 'administrative',
        sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
        memberCount: (row['member_count'] as num?)?.toInt() ?? 0,
        headName: (row['head_name']?.toString().trim().isEmpty ?? true)
            ? null
            : row['head_name'].toString(),
      );
}

/// One staff member as the personnel directory sees them.
///
/// Deliberately carries no attendance, teaching-compliance or workload
/// figures: nothing in the schema records staff attendance, whether a teacher
/// started a period on time, or a workload score, and those were the invented
/// columns this replaced.
class StaffDirectoryEntry {
  const StaffDirectoryEntry({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.status,
    required this.roles,
    required this.administrativeDepartments,
    required this.subjectGroups,
    required this.headsDepartments,
    this.positionTitle,
    this.phone,
  });

  final String userId;
  final String fullName;
  final String email;

  /// `users.status` — active / suspended.
  final String status;

  /// Every role the account holds, not the collapsed "active" one. Collapsing
  /// is what once hid a teacher who had also been granted school_admin from
  /// the teacher list entirely.
  final List<String> roles;

  final List<String> administrativeDepartments;
  final List<String> subjectGroups;

  /// Departments this person heads — a subset of the two lists above.
  final List<String> headsDepartments;

  /// ครูชำนาญการ and so on. Null when the school has not recorded one.
  final String? positionTitle;
  final String? phone;

  bool get isActive => status == 'active';
  bool hasRole(String role) => roles.contains(role);

  static List<String> _stringList(dynamic value) => value is List
      ? value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
      : const <String>[];

  factory StaffDirectoryEntry.fromRow(Map<String, dynamic> row) =>
      StaffDirectoryEntry(
        userId: row['user_id'].toString(),
        fullName: row['full_name']?.toString().trim() ?? '',
        email: row['email']?.toString() ?? '',
        status: row['status']?.toString() ?? 'active',
        roles: _stringList(row['roles']),
        administrativeDepartments: _stringList(
          row['administrative_departments'],
        ),
        subjectGroups: _stringList(row['subject_groups']),
        headsDepartments: _stringList(row['heads_departments']),
        positionTitle:
            (row['position_title']?.toString().trim().isEmpty ?? true)
            ? null
            : row['position_title'].toString(),
        phone: (row['phone']?.toString().trim().isEmpty ?? true)
            ? null
            : row['phone'].toString(),
      );
}
