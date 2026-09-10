// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'I-Crash';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionClose => 'Fechar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionBack => 'Voltar';

  @override
  String get assignmentStatusOk => 'OK';

  @override
  String get assignmentStatusReplenishmentRequired => 'Reposição necessária';

  @override
  String get assignmentStatusExpiringSoon => 'A expirar em breve';

  @override
  String get assignmentStatusExpired => 'Expirado';

  @override
  String get usageEventConsumption => 'Consumo';

  @override
  String get usageEventReplenishment => 'Reposição';

  @override
  String get usageEventCorrection => 'Correção';

  @override
  String get usageEventAuditReconciliation => 'Reconciliação';

  @override
  String get cartStatusOperational => 'Operacional';

  @override
  String get cartStatusReplenishmentRequired => 'Reposição necessária';

  @override
  String get cartStatusAuditRequired => 'Auditoria necessária';

  @override
  String get cartStatusOutOfService => 'Fora de serviço';

  @override
  String get roleSuperAdmin => 'Super administrador';

  @override
  String get roleInstitutionAdmin => 'Administrador da instituição';

  @override
  String get roleManager => 'Gestor';

  @override
  String get roleUser => 'Utilizador';

  @override
  String get membershipStatusActive => 'Ativo';

  @override
  String get membershipStatusInvited => 'Convidado';

  @override
  String get membershipStatusDisabled => 'Desativado';
}
