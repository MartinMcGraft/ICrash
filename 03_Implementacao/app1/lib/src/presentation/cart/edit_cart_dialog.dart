import 'package:flutter/material.dart';

import '../../common/l10n/app_localizations.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_status.dart';
import 'cart_status_label.dart';

class EditCartInput {
  const EditCartInput({required this.name, required this.status});

  final String name;
  final CartStatus status;
}

/// Renames a cart and/or changes its status (spec section 40). Status is
/// meant to be derived automatically where practical; this manual override
/// exists for the cases that cannot be (e.g. explicitly marking a cart out
/// of service).
Future<EditCartInput?> showEditCartDialog(BuildContext context, Cart cart) {
  final nameController = TextEditingController(text: cart.name);
  final formKey = GlobalKey<FormState>();
  var status = cart.status;

  return showDialog<EditCartInput>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.editCartTitle),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l10n.createCartNameLabel),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.validationEnterName : null,
                ),
                DropdownButtonFormField<CartStatus>(
                  initialValue: status,
                  decoration: InputDecoration(labelText: l10n.editCartStatusLabel),
                  items: [
                    for (final value in CartStatus.values)
                      DropdownMenuItem(
                        value: value,
                        child: Text(cartStatusLabel(context, value)),
                      ),
                  ],
                  onChanged: (value) => setState(() => status = value ?? status),
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
                  Navigator.of(context).pop(
                    EditCartInput(
                      name: nameController.text.trim(),
                      status: status,
                    ),
                  );
                }
              },
              child: Text(l10n.actionSave),
            ),
          ],
        );
      },
    ),
  );
}
