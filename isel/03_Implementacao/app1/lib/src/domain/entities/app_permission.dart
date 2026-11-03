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

/// Defaults per role, matching the B7 mockup for "Profissional de saúde".
Set<AppPermission> defaultPermissionsFor(Role role) => switch (role) {
      Role.user => {
          AppPermission.viewCarts,
          AppPermission.recordConsumption,
          AppPermission.replenish,
          AppPermission.monthlyCheck,
          AppPermission.signReports,
          AppPermission.emergencyMode,
        },
      Role.manager || Role.institutionAdmin || Role.platformSuperAdmin => AppPermission.values.toSet(),
    };
