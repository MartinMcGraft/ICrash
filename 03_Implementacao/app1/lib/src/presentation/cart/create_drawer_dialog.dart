import 'package:flutter/material.dart';

import '../../common/l10n/app_localizations.dart';

class NewDrawerInput {
  const NewDrawerInput({required this.name, required this.rows, required this.columns});

  final String name;
  final int rows;
  final int columns;
}

const _gridSizeOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

/// Collects a name and the base grid size (spec section 36) for a new
/// drawer. Individual slots start as one cell each; merging into bigger
/// slots happens afterwards in the slot editor.
Future<NewDrawerInput?> showCreateDrawerDialog(BuildContext context) {
  final nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var rows = 5;
  var columns = 7;

  return showDialog<NewDrawerInput>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.createDrawerTitle),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l10n.createDrawerNameLabel),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.validationEnterName : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: rows,
                        decoration: InputDecoration(labelText: l10n.createDrawerRowsLabel),
                        items: [for (final n in _gridSizeOptions) DropdownMenuItem(value: n, child: Text('$n'))],
                        onChanged: (value) => setState(() => rows = value ?? rows),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: columns,
                        decoration: InputDecoration(labelText: l10n.createDrawerColumnsLabel),
                        items: [for (final n in _gridSizeOptions) DropdownMenuItem(value: n, child: Text('$n'))],
                        onChanged: (value) => setState(() => columns = value ?? columns),
                      ),
                    ),
                  ],
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
                  Navigator.of(context).pop(NewDrawerInput(name: nameController.text.trim(), rows: rows, columns: columns));
                }
              },
              child: Text(l10n.actionCreate),
            ),
          ],
        );
      },
    ),
  );
}
