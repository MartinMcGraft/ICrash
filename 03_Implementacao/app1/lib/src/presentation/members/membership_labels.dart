import 'package:flutter/widgets.dart';

import '../../common/l10n/app_localizations.dart';
import '../../domain/entities/role.dart';

/// Localized (spec section 13) display label for [Role].
String roleLabel(BuildContext context, Role role) {
  final l10n = AppLocalizations.of(context);
  switch (role) {
    case Role.platformSuperAdmin:
      return l10n.roleSuperAdmin;
    case Role.institutionAdmin:
      return l10n.roleInstitutionAdmin;
    case Role.manager:
      return l10n.roleManager;
    case Role.user:
      return l10n.roleUser;
  }
}

/// Roles an institution admin may assign from this screen. Platform-wide
/// super admin is never granted via a membership document (spec section 16;
/// see `platformAdmins` in docs/FIREBASE_MODEL.md), so it is excluded here.
const assignableRoles = [Role.institutionAdmin, Role.manager, Role.user];

/// Localized (spec section 13) display label for [MembershipStatus].
String membershipStatusLabel(BuildContext context, MembershipStatus status) {
  final l10n = AppLocalizations.of(context);
  switch (status) {
    case MembershipStatus.active:
      return l10n.membershipStatusActive;
    case MembershipStatus.invited:
      return l10n.membershipStatusInvited;
    case MembershipStatus.disabled:
      return l10n.membershipStatusDisabled;
  }
}
