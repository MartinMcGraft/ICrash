import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';

class DrawerFormResult {
  const DrawerFormResult({required this.name, required this.rows, required this.columns});
  final String name;
  final int rows;
  final int columns;
}

/// "Adicionar gaveta".
Future<DrawerFormResult?> showDrawerFormDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final name = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var rows = 5;
  var columns = 6;
  return showDialog<DrawerFormResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.addDrawer),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: l10n.fieldName,
                  controller: name,
                  autofocus: true,
                  hint: l10n.drawerNameHint,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validationEnterName : null,
                ),
                const SizedBox(height: IcSpace.s16),
                Row(
                  children: [
                    Expanded(child: Text(l10n.createDrawerRowsLabel, style: IcText.bodyM)),
                    QuantityStepper(label: l10n.createDrawerRowsLabel, value: rows, min: 1, max: 12, onChanged: (v) => setState(() => rows = v)),
                  ],
                ),
                const SizedBox(height: IcSpace.s12),
                Row(
                  children: [
                    Expanded(child: Text(l10n.createDrawerColumnsLabel, style: IcText.bodyM)),
                    QuantityStepper(label: l10n.createDrawerColumnsLabel, value: columns, min: 1, max: 12, onChanged: (v) => setState(() => columns = v)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
          IcButton(
            label: l10n.actionCreate,
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(DrawerFormResult(name: name.text.trim(), rows: rows, columns: columns));
              }
            },
          ),
        ],
      ),
    ),
  );
}
