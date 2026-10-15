import '../../common/l10n/app_localizations.dart';
import '../../domain/entities/role.dart';
import '../../domain/entities/usage_event.dart';

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
