/// The user types (D16, 30 Oct 2026):
/// - [platformSuperAdmin] = **Super**, the I-Crash team's IT staff, granted
///   by a `platformAdmins/{uid}` document, not a membership; reaches an
///   institution only with its support grant (D18);
/// - [institutionAdmin] = **Admin**, the institution's IT staff: everything
///   in one institution;
/// - [manager] = **Manager**, a health professional with full access to the
///   carts they're registered to.
///
/// The old `user` role is gone: stored `user` memberships read as [manager].
enum Role { platformSuperAdmin, institutionAdmin, manager }

extension RoleCodec on Role {
  String get id => name;

  /// Unknown and old values (`user`) read as [manager], the narrowest type.
  static Role fromId(String id) => Role.values.firstWhere(
        (role) => role.name == id,
        orElse: () => Role.manager,
      );
}

enum MembershipStatus { active, invited, disabled }

extension MembershipStatusCodec on MembershipStatus {
  String get id => name;

  static MembershipStatus fromId(String id) => MembershipStatus.values.firstWhere(
        (status) => status.name == id,
        orElse: () => MembershipStatus.disabled,
      );
}
