import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';

class DrawerFormResult {
  const DrawerFormResult({required this.number, required this.rows, required this.columns});
  final int number;
  final int rows;
  final int columns;
}

/// "Adicionar gaveta": the drawer's number (P17: drawers have a number, no
/// name) and its grid size. [initialNumber] is the lowest free number;
/// [takenNumbers] are refused here and again by the ViewModel.
Future<DrawerFormResult?> showDrawerFormDialog(
  BuildContext context, {
  required int initialNumber,
  required Set<int> takenNumbers,
}) {
  final l10n = AppLocalizations.of(context);
  var number = initialNumber;
  var rows = 5;
  var columns = 6;
  return showDialog<DrawerFormResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final taken = takenNumbers.contains(number);
        return AlertDialog(
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
              onPressed: taken ? null : () => Navigator.of(context).pop(DrawerFormResult(number: number, rows: rows, columns: columns)),
            ),
          ],
        );
      },
    ),
  );
}

/// "Alterar número" on a drawer row in B3 (Q8). Returns the new number.
Future<int?> showDrawerNumberDialog(
  BuildContext context, {
  required int currentNumber,
  required Set<int> takenNumbers,
}) {
  final l10n = AppLocalizations.of(context);
  var number = currentNumber;
  return showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final taken = number != currentNumber && takenNumbers.contains(number);
        return AlertDialog(
          title: Text(l10n.editDrawerNumber),
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
              ],
            ),
          ),
          actions: [
            IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
            IcButton(label: l10n.actionSave, onPressed: taken ? null : () => Navigator.of(context).pop(number)),
          ],
        );
      },
    ),
  );
}
