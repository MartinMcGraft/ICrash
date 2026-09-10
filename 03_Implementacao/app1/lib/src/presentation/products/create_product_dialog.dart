import 'package:flutter/material.dart';

import '../../common/l10n/app_localizations.dart';

class NewProductInput {
  const NewProductInput({required this.name, this.description, this.unitDescription, this.gtin});

  final String name;
  final String? description;
  final String? unitDescription;
  final String? gtin;
}

/// Collects the minimal product fields the prototype needs (spec section
/// 21): a name, plus optional description/unit/GTIN. Product images and
/// richer metadata are explicitly deferred.
Future<NewProductInput?> showCreateProductDialog(BuildContext context) {
  final nameController = TextEditingController();
  final unitController = TextEditingController();
  final gtinController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<NewProductInput>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(l10n.createProductTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.createProductNameLabel),
                validator: (value) => (value == null || value.trim().isEmpty) ? l10n.validationEnterName : null,
              ),
              TextFormField(
                controller: unitController,
                decoration: InputDecoration(labelText: l10n.createProductUnitLabel, hintText: l10n.createProductUnitHint),
              ),
              TextFormField(
                controller: gtinController,
                decoration: InputDecoration(labelText: l10n.createProductGtinLabel),
              ),
            ],
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
                Navigator.of(context).pop(NewProductInput(
                  name: nameController.text.trim(),
                  unitDescription: unitController.text.trim().isEmpty ? null : unitController.text.trim(),
                  gtin: gtinController.text.trim().isEmpty ? null : gtinController.text.trim(),
                ));
              }
            },
            child: Text(l10n.actionCreate),
          ),
        ],
      );
    },
  );
}
