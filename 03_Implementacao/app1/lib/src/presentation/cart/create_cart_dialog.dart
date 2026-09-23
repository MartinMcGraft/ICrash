import 'package:flutter/material.dart';

import '../../common/l10n/app_localizations.dart';

/// Shows a minimal name-only dialog and returns the trimmed name, or `null`
/// if cancelled. Cart creation only needs a name up front (spec section 21
/// keeps the model simple); drawers/slots are configured later. [existingNames]
/// blocks creating a cart whose name (trimmed, case-insensitive) already
/// belongs to another cart in the same institution.
Future<String?> showCreateCartDialog(BuildContext context, {required List<String> existingNames}) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final takenNames = existingNames.map((name) => name.trim().toLowerCase()).toSet();

  return showDialog<String>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      String? validate(String? value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) return l10n.validationEnterName;
        if (takenNames.contains(trimmed.toLowerCase())) return l10n.validationDuplicateCartName;
        return null;
      }

      return AlertDialog(
        title: Text(l10n.createCartTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.createCartNameLabel),
            validator: validate,
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
