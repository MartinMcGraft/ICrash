import 'package:flutter/material.dart';

import '../../common/l10n/app_localizations.dart';

/// Collects a name for a cart duplicate (spec section 39). Duplication
/// copies drawer/slot configuration only — never product assignments, stock,
/// batches, or usage/audit history — so the new cart starts empty and ready
/// to be stocked from scratch. [existingNames] blocks a duplicate name that
/// (trimmed, case-insensitive) already belongs to another cart.
Future<String?> showDuplicateCartDialog(
  BuildContext context, {
  required String defaultName,
  required List<String> existingNames,
}) {
  final nameController = TextEditingController(text: defaultName);
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
        title: Text(l10n.duplicateCartTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.duplicateCartDescription),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.duplicateCartNameLabel),
                validator: validate,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(nameController.text.trim());
              }
            },
            child: Text(l10n.actionDuplicate),
          ),
        ],
      );
    },
  );
}
