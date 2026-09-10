// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'I-Crash';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionSave => 'Save';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionBack => 'Back';

  @override
  String get assignmentStatusOk => 'OK';

  @override
  String get assignmentStatusReplenishmentRequired => 'Replenishment required';

  @override
  String get assignmentStatusExpiringSoon => 'Expiring soon';

  @override
  String get assignmentStatusExpired => 'Expired';

  @override
  String get usageEventConsumption => 'Consumption';

  @override
  String get usageEventReplenishment => 'Replenishment';

  @override
  String get usageEventCorrection => 'Correction';

  @override
  String get usageEventAuditReconciliation => 'Reconciliation';

  @override
  String get cartStatusOperational => 'Operational';

  @override
  String get cartStatusReplenishmentRequired => 'Replenishment required';

  @override
  String get cartStatusAuditRequired => 'Audit required';

  @override
  String get cartStatusOutOfService => 'Out of service';

  @override
  String get roleSuperAdmin => 'Super administrator';

  @override
  String get roleInstitutionAdmin => 'Institution administrator';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleUser => 'User';

  @override
  String get membershipStatusActive => 'Active';

  @override
  String get membershipStatusInvited => 'Invited';

  @override
  String get membershipStatusDisabled => 'Disabled';
}
