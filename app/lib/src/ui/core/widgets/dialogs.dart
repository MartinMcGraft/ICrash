import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../common/repository_failure.dart';
import '../mvvm/view_model.dart';
import 'ic_button.dart';

/// Confirmation dialog with the shared button styles.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Text(message)),
      actions: [
        IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop(false)),
        IcButton(
          label: confirmLabel,
          style: destructive ? IcButtonStyle.danger : IcButtonStyle.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Standard message for a failed action.
String failureText(AppLocalizations l10n, RepositoryFailureReason? reason) => switch (reason) {
      RepositoryFailureReason.offline => l10n.actionOfflineError,
      RepositoryFailureReason.permissionDenied || RepositoryFailureReason.unauthenticated => l10n.actionPermissionError,
      _ => l10n.actionGenericError,
    };

/// Message for a business-rule code shared by several screens (see
/// `StockRuleViolation` and the ViewModels' `ActionError` codes), or null
/// when the code has no shared message.
String? actionCodeText(AppLocalizations l10n, String? code) => switch (code) {
      'exceedsTarget' => l10n.errorExceedsTarget,
      'belowZero' => l10n.errorBelowZero,
      'targetBelowCurrent' => l10n.errorTargetBelowCurrent,
      'invalidTarget' => l10n.errorInvalidTarget,
      'slotTaken' => l10n.slotTaken,
      'quantityRequired' => l10n.errorQuantityRequired,
      'drawerNumberTaken' => l10n.drawerNumberTaken,
      'drawerNumberInvalid' => l10n.drawerNumberHelp,
      _ => null,
    };

/// Shows [success] (if any) or the failure message for [result]: [failure]
/// if given, else the shared message for its code, else the generic one.
void showResult(BuildContext context, ActionResult<Object?> result, {String? success, String? failure}) {
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final text = result.isOk ? success : (failure ?? actionCodeText(l10n, result.code) ?? failureText(l10n, result.failure));
  if (text == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

void showMessage(BuildContext context, String text) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
