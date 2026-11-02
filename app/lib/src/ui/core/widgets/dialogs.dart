import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../common/repository_failure.dart';
import '../mvvm/view_model.dart';
import 'ic_button.dart';
import 'layout.dart';

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
      'slotInUse' => l10n.slotInUseHint,
      'drawerInUse' => l10n.drawerInUseHint,
      'drawerNumberTaken' => l10n.drawerNumberTaken,
      'drawerNumberInvalid' => l10n.drawerNumberHelp,
      'newExpiryRequired' => l10n.checkNewExpiryRequired,
      'newExpiryNotLater' => l10n.checkNewExpiryNotLater,
      'checkIncomplete' => l10n.checkIncomplete,
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

/// Asks for a code typed by hand ("Manual" on A11, "Introduzir código" on
/// A3). Returns the trimmed text, or null when cancelled or empty.
///
/// The text field's controller belongs to the dialog's own State, so it is
/// disposed only after the closing animation: disposing it as soon as
/// `showDialog` returned crashed the app, because the field still writes to
/// its controller when it loses focus on the way out (2 Nov 2026).
Future<String?> showCodeEntryDialog(BuildContext context, {required String title, required String label, String? hint}) async {
  final text = await showDialog<String>(
    context: context,
    builder: (_) => _CodeEntryDialog(title: title, label: label, hint: hint),
  );
  final trimmed = text?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

class _CodeEntryDialog extends StatefulWidget {
  const _CodeEntryDialog({required this.title, required this.label, this.hint});

  final String title;
  final String label;
  final String? hint;

  @override
  State<_CodeEntryDialog> createState() => _CodeEntryDialogState();
}

class _CodeEntryDialogState extends State<_CodeEntryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: LabeledField(
          label: widget.label,
          hint: widget.hint,
          controller: _controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
      ),
      actions: [
        IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
        IcButton(label: l10n.actionConfirm, onPressed: () => Navigator.of(context).pop(_controller.text)),
      ],
    );
  }
}
