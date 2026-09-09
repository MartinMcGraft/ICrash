import '../../domain/entities/role.dart';

String roleLabel(Role role) {
  switch (role) {
    case Role.platformSuperAdmin:
      return 'Super administrador';
    case Role.institutionAdmin:
      return 'Administrador da instituição';
    case Role.manager:
      return 'Gestor';
    case Role.user:
      return 'Utilizador';
  }
}

/// Roles an institution admin may assign from this screen. Platform-wide
/// super admin is never granted via a membership document (spec section 16;
/// see `platformAdmins` in docs/FIREBASE_MODEL.md), so it is excluded here.
const assignableRoles = [Role.institutionAdmin, Role.manager, Role.user];

String membershipStatusLabel(MembershipStatus status) {
  switch (status) {
    case MembershipStatus.active:
      return 'Ativo';
    case MembershipStatus.invited:
      return 'Convidado';
    case MembershipStatus.disabled:
      return 'Desativado';
  }
}
