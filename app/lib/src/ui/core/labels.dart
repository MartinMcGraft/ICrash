import '../../common/l10n/app_localizations.dart';
import '../../domain/entities/role.dart';
import '../../domain/entities/usage_event.dart';
import '../../domain/monthly_check.dart';

/// A drawer's title (D20): its descriptive name, or "Gaveta N" when it has
/// none. Used next to the number badge (A5).
String drawerTitle(AppLocalizations l10n, String? name, int number) => name ?? l10n.drawerShort(number);

/// "Gaveta 2 · Via aérea", or "Gaveta 2" without a name: page titles where no
/// number badge is shown (A6, B4, A8).
String drawerTitleWithNumber(AppLocalizations l10n, String? name, int number) =>
    name == null ? l10n.drawerShort(number) : '${l10n.drawerShort(number)} · $name';

/// A8 outcome labels, in one place: ESEL still has to confirm them (D22).
String checkOutcomeText(AppLocalizations l10n, CheckOutcome outcome) => switch (outcome) {
      CheckOutcome.replaced => l10n.checkOutcomeReplaced,
      CheckOutcome.removed => l10n.checkOutcomeRemoved,
      CheckOutcome.kept => l10n.checkOutcomeKept,
    };

String roleText(AppLocalizations l10n, Role role) => switch (role) {
      Role.platformSuperAdmin => l10n.roleSuperAdmin,
      Role.institutionAdmin => l10n.roleInstitutionAdmin,
      Role.manager => l10n.roleManager,
      Role.user => l10n.roleUser,
    };

String? roleTextFromId(AppLocalizations l10n, String? id) {
  if (id == null) return null;
  final role = Role.values.where((r) => r.id == id).firstOrNull;
  return role == null ? null : roleText(l10n, role);
}

String membershipStatusText(AppLocalizations l10n, MembershipStatus status) => switch (status) {
      MembershipStatus.active => l10n.membershipStatusActive,
      MembershipStatus.invited => l10n.membershipStatusInvited,
      MembershipStatus.disabled => l10n.membershipStatusDisabled,
    };

String usageEventText(AppLocalizations l10n, UsageEventType type) => switch (type) {
      UsageEventType.consumption => l10n.usageEventConsumption,
      UsageEventType.replenishment => l10n.usageEventReplenishment,
      UsageEventType.correction => l10n.usageEventCorrection,
      UsageEventType.auditReconciliation => l10n.usageEventAuditReconciliation,
    };

/// Roles an institution admin may give (super admin is provisioned outside the app).
const assignableRoles = [Role.user, Role.manager, Role.institutionAdmin];
