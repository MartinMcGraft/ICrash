import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/cart_drawer.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';

class DrawerFormResult {
  const DrawerFormResult({required this.number, this.name, required this.rows, required this.columns});
  final int number;

  /// Optional descriptive name (D20); empty when none.
  final String? name;
  final int rows;
  final int columns;
}

/// The optional drawer name field (D20): "Nome (opcional)", up to 50 characters.
Widget _nameField(AppLocalizations l10n, String initial, ValueChanged<String> onChanged) => LabeledField(
      label: l10n.drawerNameLabel,
      hint: l10n.drawerNameHint,
      initialValue: initial,
      onChanged: onChanged,
      inputFormatters: [LengthLimitingTextInputFormatter(CartDrawer.maxNameLength)],
    );

/// "Adicionar gaveta": the drawer's number, its optional name (D20) and its
/// grid size. [initialNumber] is the lowest free number;
/// [takenNumbers] are refused here and again by the ViewModel.
Future<DrawerFormResult?> showDrawerFormDialog(
  BuildContext context, {
  required int initialNumber,
  required Set<int> takenNumbers,
}) {
  final l10n = AppLocalizations.of(context);
  var number = initialNumber;
  var name = '';
  var rows = 5;
  var columns = 6;
  return showDialog<DrawerFormResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final taken = takenNumbers.contains(number);
        return AlertDialog(
          scrollable: true,
          title: Text(l10n.addDrawer),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l10n.drawerNumberLabel, style: IcText.bodyM)),
                    QuantityStepper(label: l10n.drawerNumberLabel, value: number, min: 1, max: 99, onChanged: (v) => setState(() => number = v)),
                  ],
                ),
                const SizedBox(height: IcSpace.s4),
                Text(
                  taken ? l10n.drawerNumberTaken : l10n.drawerNumberHelp,
                  style: IcText.bodyS.copyWith(color: taken ? IcColors.dangerFg : IcColors.textMuted),
                ),
                const SizedBox(height: IcSpace.s16),
                _nameField(l10n, name, (v) => name = v),
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
          actions: [
            IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
            IcButton(
              label: l10n.actionCreate,
              onPressed: taken
                  ? null
                  : () => Navigator.of(context).pop(DrawerFormResult(number: number, name: name, rows: rows, columns: columns)),
            ),
          ],
        );
      },
    ),
  );
}

/// "Editar gaveta" on a drawer row in B3: the number, only when
/// [numberEditable] (Q8: an unused drawer, or one that never had a number),
/// and the optional name (D20: always; empty removes it).
Future<({int number, String name})?> showDrawerEditDialog(
  BuildContext context, {
  required int currentNumber,
  required String? currentName,
  required bool numberEditable,
  required Set<int> takenNumbers,
}) {
  final l10n = AppLocalizations.of(context);
  var number = currentNumber;
  var name = currentName ?? '';
  return showDialog<({int number, String name})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final taken = number != currentNumber && takenNumbers.contains(number);
        return AlertDialog(
          scrollable: true,
          title: Text(l10n.editDrawer),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l10n.drawerNumberLabel, style: IcText.bodyM)),
                    if (numberEditable)
                      QuantityStepper(label: l10n.drawerNumberLabel, value: number, min: 1, max: 99, onChanged: (v) => setState(() => number = v))
                    else
                      Text('$number', style: IcText.titleS),
                  ],
                ),
                const SizedBox(height: IcSpace.s4),
                Text(
                  !numberEditable ? l10n.drawerNumberLocked : (taken ? l10n.drawerNumberTaken : l10n.drawerNumberHelp),
                  style: IcText.bodyS.copyWith(color: taken ? IcColors.dangerFg : IcColors.textMuted),
                ),
                const SizedBox(height: IcSpace.s16),
                _nameField(l10n, name, (v) => name = v),
              ],
            ),
          ),
          actions: [
            IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
            IcButton(label: l10n.actionSave, onPressed: taken ? null : () => Navigator.of(context).pop((number: number, name: name))),
          ],
        );
      },
    ),
  );
}
