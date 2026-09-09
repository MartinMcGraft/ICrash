import 'role.dart';

/// A user's institution-scoped membership. Document id is the user's uid,
/// stored under `institutions/{institutionId}/memberships/{uid}`.
class Membership {
  const Membership({
    required this.uid,
    required this.institutionId,
    required this.role,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String institutionId;
  final Role role;
  final MembershipStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == MembershipStatus.active;

  factory Membership.fromMap(String uid, String institutionId, Map<String, Object?> map) {
    return Membership(
      uid: uid,
      institutionId: institutionId,
      role: RoleCodec.fromId(map['role'] as String? ?? Role.user.id),
      status: MembershipStatusCodec.fromId(map['status'] as String? ?? MembershipStatus.disabled.id),
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        'uid': uid,
        'role': role.id,
        'status': status.id,
      };
}
