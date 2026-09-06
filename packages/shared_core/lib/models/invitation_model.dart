import 'user_model.dart';

class StaffInvitation {
  final String id;
  final String email;
  final UserRole role;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  const StaffInvitation({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  factory StaffInvitation.fromRow(Map<String, dynamic> row) {
    return StaffInvitation(
      id: row['id'] as String,
      email: row['email'] as String,
      role: UserRoleExt.fromString(row['initial_role'] as String? ?? 'student'),
      status: row['status'] as String,
      expiresAt: DateTime.parse(row['expires_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
}

/// Result of `create_staff_invitation`. The token is shown to the admin once
/// so it can be relayed manually — there is no invitation email infra.
class StaffInvitationTicket {
  const StaffInvitationTicket({required this.token, required this.expiresAt});

  final String token;
  final DateTime? expiresAt;
}
