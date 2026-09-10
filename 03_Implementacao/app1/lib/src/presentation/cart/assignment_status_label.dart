import 'package:flutter/widgets.dart';

import '../../common/l10n/app_localizations.dart';
import '../../domain/entities/cart_product_assignment.dart';
import '../../domain/entities/usage_event.dart';

/// Localized (spec section 13) display label for [AssignmentStatus], for
/// widget use. [assignmentStatusLabelPt] below is the fixed-Portuguese
/// counterpart used by the CSV/PDF export builders, which are deliberately
/// kept independent of the current UI locale — see
/// `docs/ARCHITECTURE.md`'s "Export language" note.
String assignmentStatusLabel(BuildContext context, AssignmentStatus status) {
  final l10n = AppLocalizations.of(context);
  switch (status) {
    case AssignmentStatus.ok:
      return l10n.assignmentStatusOk;
    case AssignmentStatus.replenishmentRequired:
      return l10n.assignmentStatusReplenishmentRequired;
    case AssignmentStatus.expiringSoon:
      return l10n.assignmentStatusExpiringSoon;
    case AssignmentStatus.expired:
      return l10n.assignmentStatusExpired;
  }
}

/// Localized (spec section 13) display label for [UsageEventType], for
/// widget use — see [usageEventTypeLabelPt] for the export-only counterpart.
String usageEventTypeLabel(BuildContext context, UsageEventType type) {
  final l10n = AppLocalizations.of(context);
  switch (type) {
    case UsageEventType.consumption:
      return l10n.usageEventConsumption;
    case UsageEventType.replenishment:
      return l10n.usageEventReplenishment;
    case UsageEventType.correction:
      return l10n.usageEventCorrection;
    case UsageEventType.auditReconciliation:
      return l10n.usageEventAuditReconciliation;
  }
}

/// Fixed Portuguese label, independent of the app's current locale — used
/// only by `history_csv_export.dart`/`history_pdf_export.dart`, which are
/// deliberately `BuildContext`-free so they stay unit-testable without a
/// widget tree (see those files' own doc comments).
String assignmentStatusLabelPt(AssignmentStatus status) {
  switch (status) {
    case AssignmentStatus.ok:
      return 'OK';
    case AssignmentStatus.replenishmentRequired:
      return 'Reposição necessária';
    case AssignmentStatus.expiringSoon:
      return 'A expirar em breve';
    case AssignmentStatus.expired:
      return 'Expirado';
  }
}

/// Fixed-Portuguese counterpart of [usageEventTypeLabel] — see
/// [assignmentStatusLabelPt] for why this pair exists.
String usageEventTypeLabelPt(UsageEventType type) {
  switch (type) {
    case UsageEventType.consumption:
      return 'Consumo';
    case UsageEventType.replenishment:
      return 'Reposição';
    case UsageEventType.correction:
      return 'Correção';
    case UsageEventType.auditReconciliation:
      return 'Reconciliação';
  }
}
