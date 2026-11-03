import 'role.dart';

/// Fine-grained permissions shown in design v2 B7 ("Permissões").
///
/// Proposal D2: the per-user-type permission set is still to be confirmed,
/// so these toggles are stored by a local stub and only drive what the UI
/// offers. Firestore Rules remain the real enforcement (role-based).
enum AppPermission {
  viewCarts,
  recordConsumption,
  replenish,
  monthlyCheck,
  signReports,
  emergencyMode,
  changeCartState,
  editDrawers,
  manageUsersAndShifts,
}

/// The cart actions a Manager may be given in B7 (D16: full access to their
/// carts). Structure ([AppPermission.editDrawers]) and users/shifts stay
/// with the Admin: the Firestore Rules allow them only to Admin/Super.
const managerPermissions = [
  AppPermission.viewCarts,
  AppPermission.recordConsumption,
  AppPermission.replenish,
  AppPermission.monthlyCheck,
  AppPermission.signReports,
  AppPermission.emergencyMode,
  AppPermission.changeCartState,
];

/// Defaults per role (D16): a Manager gets every cart action; Admin and
/// Super everything.
Set<AppPermission> defaultPermissionsFor(Role role) => switch (role) {
      Role.manager => managerPermissions.toSet(),
      Role.institutionAdmin || Role.platformSuperAdmin => AppPermission.values.toSet(),
      // A tablet acts only through the person signed in on it.
      Role.device => const {},
    };
