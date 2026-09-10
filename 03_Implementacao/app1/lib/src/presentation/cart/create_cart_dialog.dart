import 'package:flutter/material.dart';

import '../../common/l10n/app_localizations.dart';

/// Shows a minimal name-only dialog and returns the trimmed name, or `null`
/// if cancelled. Cart creation only needs a name up front (spec section 21
/// keeps the model simple); drawers/slots are configured later.
Future<String?> showCreateCartDialog(BuildContext context) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(l10n.createCartTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.createCartNameLabel),
            validator: (value) => (value == null || value.trim().isEmpty) ? l10n.validationEnterName : null,
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: Text(l10n.actionCreate),
          ),
        ],
      );
    },
  );
}
