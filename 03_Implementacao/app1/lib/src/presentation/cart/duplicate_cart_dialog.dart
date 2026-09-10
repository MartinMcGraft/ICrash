import 'package:flutter/material.dart';

import '../../common/l10n/app_localizations.dart';

/// Collects a name for a cart duplicate (spec section 39). Duplication
/// copies drawer/slot configuration only — never product assignments, stock,
/// batches, or usage/audit history — so the new cart starts empty and ready
/// to be stocked from scratch.
Future<String?> showDuplicateCartDialog(BuildContext context, {required String defaultName}) {
  final nameController = TextEditingController(text: defaultName);
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
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
                validator: (value) => (value == null || value.trim().isEmpty) ? l10n.validationEnterName : null,
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
