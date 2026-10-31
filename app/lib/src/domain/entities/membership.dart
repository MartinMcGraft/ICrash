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
    this.userNumber,
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

  /// D17: the employee number (nº mecanográfico) people type on a registered
  /// tablet before their PIN. Optional; unique in the institution (checked by
  /// the app).
  final String? userNumber;
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
      role: RoleCodec.fromId(map['role'] as String? ?? Role.manager.id),
      status: MembershipStatusCodec.fromId(map['status'] as String? ?? MembershipStatus.disabled.id),
      displayName: map['displayName'] as String?,
      email: map['email'] as String?,
      service: map['service'] as String?,
      userNumber: map['userNumber'] as String?,
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
        if (userNumber != null) 'userNumber': userNumber,
      };

  /// Whether [identifier] is this person's e-mail (any case) or number.
  bool matches(String identifier) {
    final id = identifier.trim();
    if (id.isEmpty) return false;
    return (email != null && email!.toLowerCase() == id.toLowerCase()) || (userNumber != null && userNumber == id);
  }
}
