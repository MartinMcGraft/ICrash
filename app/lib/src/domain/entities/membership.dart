import 'role.dart';

/// A user's institution-scoped membership. Document id is the user's uid,
/// stored under `institutions/{institutionId}/memberships/{uid}`.
class Membership {
  const Membership({
    required this.uid,
    required this.institutionId,
    required this.role,
    required this.status,
    this.displayName,
    this.email,
    this.service,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String institutionId;
  final Role role;
  final MembershipStatus status;

  /// Person's name, so lists show people instead of database ids (audit C5).
  /// Optional: memberships created before the v2 design have none.
  final String? displayName;
  final String? email;

  /// Hospital service the person works in (e.g. "Urgência"), when known.
  final String? service;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == MembershipStatus.active;

  /// Best human-readable label: name, else e-mail, else the uid.
  String get label {
    if (displayName != null && displayName!.trim().isNotEmpty) return displayName!;
    if (email != null && email!.trim().isNotEmpty) return email!;
    return uid;
  }

  factory Membership.fromMap(String uid, String institutionId, Map<String, Object?> map) {
    return Membership(
      uid: uid,
      institutionId: institutionId,
      role: RoleCodec.fromId(map['role'] as String? ?? Role.user.id),
      status: MembershipStatusCodec.fromId(map['status'] as String? ?? MembershipStatus.disabled.id),
      displayName: map['displayName'] as String?,
      email: map['email'] as String?,
      service: map['service'] as String?,
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        'uid': uid,
        'role': role.id,
        'status': status.id,
        if (displayName != null) 'displayName': displayName,
        if (email != null) 'email': email,
        if (service != null) 'service': service,
      };
}
