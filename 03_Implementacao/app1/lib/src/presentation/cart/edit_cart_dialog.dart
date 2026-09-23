import 'package:flutter/material.dart';

import '../../common/l10n/app_localizations.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_status.dart';

class EditCartInput {
  const EditCartInput({required this.name, required this.status});

  final String name;
  final CartStatus status;
}

/// Renames a cart and/or marks it out of service (spec section 40). Every
/// other status value is derived automatically from inventory alerts (see
/// `InventoryRules.computeEffectiveCartStatus`) — "out of service" is the
/// one case nothing in the inventory data can infer, so it stays a manual,
/// administrative override here, same as the name.
Future<EditCartInput?> showEditCartDialog(BuildContext context, Cart cart) {
  final nameController = TextEditingController(text: cart.name);
  final formKey = GlobalKey<FormState>();
  var outOfService = cart.status == CartStatus.outOfService;

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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.editCartOutOfServiceLabel),
                  value: outOfService,
                  onChanged: (value) => setState(() => outOfService = value),
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
                      status: outOfService ? CartStatus.outOfService : CartStatus.operational,
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
