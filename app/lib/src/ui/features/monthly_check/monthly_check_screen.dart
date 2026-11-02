import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/cart_drawer.dart';
import '../../../domain/entities/cart_report.dart';
import '../../../domain/monthly_check.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/labels.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import '../../shells/shell_navigation.dart';
import '../reports/report_screen.dart';
import 'monthly_check_view_model.dart';

/// A8 · Verificação mensal ("Gestão mensal", D4/D22/D23, 30 Oct 2026): only
/// expired and expiring lots, one drawer per step, an outcome for each; every
/// answer is saved at once; back goes to the previous step.
class MonthlyCheckScreen extends StatelessWidget {
  const MonthlyCheckScreen({super.key, required this.cartId});
  final String cartId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<MonthlyCheckViewModel>(
      create: (services) => MonthlyCheckViewModel(services, session, cartId),
      builder: (context, vm) {
        if (!vm.ready) return const StateView.loading();
        final cart = vm.data.cart!;
        final compact = isCompactHeight(context);
        final drawer = vm.stepDrawer;
        Future<void> goBack() async {
          // RV-18: back goes to the previous drawer; from the first one it
          // leaves, and the draft (every answer) stays for "Retomar".
          if (!await vm.back() && context.mounted) Navigator.of(context).pop();
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) goBack();
          },
          child: Padding(
            padding: contentPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: l10n.monthlyCheckTitle,
                  subtitle: drawer == null
                      ? cart.name
                      : l10n.checkStepSubtitle(
                          cart.name,
                          drawerTitleWithNumber(l10n, drawer.name, vm.data.numberOf(drawer)),
                          vm.step + 1,
                          vm.steps.length,
                        ),
                  onBack: goBack,
                ),
                if (vm.steps.length > 1) ...[
                  const SizedBox(height: IcSpace.s16),
                  _Progress(vm: vm),
                ],
                SizedBox(height: compact ? IcSpace.s12 : IcSpace.s16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SurfaceCard(
                          elevated: false,
                          padding: const EdgeInsets.symmetric(vertical: IcSpace.s8),
                          child: drawer == null
                              ? StateView.message(message: l10n.checkNothingToHandle, icon: IcIcon.okCirculo)
                              : _Items(vm: vm),
                        ),
                      ),
                      SizedBox(width: compact ? IcSpace.s12 : IcSpace.s20),
                      SidePanel(child: _Summary(vm: vm, drawer: drawer)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One bar per drawer step: done steps green, the current one blue.
class _Progress extends StatelessWidget {
  const _Progress({required this.vm});
  final MonthlyCheckViewModel vm;

  @override
  Widget build(BuildContext context) {
    final steps = vm.steps;
    return Semantics(
      label: AppLocalizations.of(context).progressSemantics(vm.step + 1, steps.length),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: vm.items.where((it) => it.drawerId == steps[i].id).every((it) => it.answered)
                      ? IcColors.okFg
                      : (i == vm.step ? IcColors.actionPrimary : IcColors.bgSurfaceSunken),
                  borderRadius: BorderRadius.circular(IcRadius.full),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "B3 · Lote L1 · expira a 12/10/2026".
String _itemMeta(AppLocalizations l10n, IcFormat format, CheckItem item) => [
      item.position,
      item.lotNumber == null ? l10n.noLot : l10n.scanLot(item.lotNumber!),
      l10n.expiresOn(format.numeric(item.expiryDate)),
    ].join(' · ');

/// One clear state per line: what is wrong (expired / expiring) on the left,
/// and either "Por resolver" or the chosen outcome on the right (RV-16).
class _Items extends StatelessWidget {
  const _Items({required this.vm});
  final MonthlyCheckViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    final items = vm.stepItems;
    return FitList(
      itemCount: items.length,
      itemExtent: 60,
      spacing: 0,
      minColumnWidth: 420,
      itemBuilder: (context, index) {
        final item = items[index];
        final expired = item.issue == FindingIssue.expired;
        final stateColor = expired ? IcColors.dangerFg : IcColors.warningFg;
        final stateText = expired ? l10n.slotHealthExpired : l10n.slotHealthExpiring;
        final outcome = item.outcome;
        return Semantics(
          button: true,
          label: '${item.productName}, $stateText, ${outcome == null ? l10n.checkPendingLabel : checkOutcomeText(l10n, outcome)}',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => _answer(context, vm, item),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: IcSpace.s16, vertical: 6),
              child: Row(
                children: [
                  IcIconView(expired ? IcIcon.alerta : IcIcon.relogio, size: 20, color: stateColor),
                  const SizedBox(width: IcSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.productName, style: IcText.labelL, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          '$stateText · ${_itemMeta(l10n, format, item)}',
                          style: IcText.bodyS.copyWith(color: stateColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: IcSpace.s12),
                  if (outcome == null)
                    Text(l10n.checkPendingLabel, style: IcText.labelM.copyWith(color: IcColors.textSecondary))
                  else
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const IcIconView(IcIcon.okCirculo, size: 18, color: IcColors.okFg),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              checkOutcomeText(l10n, outcome),
                              style: IcText.labelM.copyWith(color: IcColors.okFg),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.vm, required this.drawer});
  final MonthlyCheckViewModel vm;
  final CartDrawer? drawer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = isCompactHeight(context);
    final stepItems = vm.stepItems;
    final handled = stepItems.where((i) => i.answered).length;
    final pending = stepItems.length - handled;
    Widget line(IcIcon icon, Color color, String text) => Padding(
          padding: const EdgeInsets.only(bottom: IcSpace.s8),
          child: Row(children: [
            IcIconView(icon, size: 18, color: color),
            const SizedBox(width: IcSpace.s8),
            Expanded(child: Text(text, style: IcText.labelM.copyWith(color: color))),
          ]),
        );
    final finishing = vm.isLastStep || drawer == null;
    return PanelColumn(
      children: [
        Text(
          drawer == null ? l10n.monthlyCheckTitle : drawerTitleWithNumber(l10n, drawer!.name, vm.data.numberOf(drawer!)),
          style: IcText.titleS,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: IcSpace.s12),
        if (drawer != null) ...[
          line(IcIcon.relogio, pending > 0 ? IcColors.warningFg : IcColors.textSecondary, l10n.checkToHandle(pending)),
          line(IcIcon.okCirculo, IcColors.okFg, l10n.checkHandled(handled)),
        ],
        if (!compact) Text(l10n.checkOnlyFlaggedHelp, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
        const Spacer(),
        IcButton(
          label: vm.notes.isEmpty ? l10n.addNote : l10n.editNote,
          icon: IcIcon.editar,
          style: IcButtonStyle.secondary,
          expand: true,
          onPressed: () => _editNote(context, vm),
        ),
        const SizedBox(height: IcSpace.s12),
        IcButton(
          // Phones: "Concluir", so the label fits the narrower panel (RV-8).
          label: finishing ? (compact ? l10n.finishCheckShort : l10n.finishCheck) : l10n.nextDrawer,
          icon: finishing ? IcIcon.confirmar : IcIcon.seguinte,
          size: compact ? IcButtonSize.m : IcButtonSize.l,
          expand: true,
          busy: vm.busy,
          onPressed: finishing
              ? (vm.canFinish
                  ? () async {
                      final result = await vm.finish();
                      if (!context.mounted) return;
                      if (!result.isOk) return showResult(context, result);
                      Navigator.of(context).pushReplacement(sectionRoute((_) => ReportScreen(reportId: result.value!)));
                    }
                  : null)
              : (vm.stepDone ? vm.next : null),
        ),
        if (vm.step > 0) ...[
          const SizedBox(height: IcSpace.s8),
          IcButton(
            label: l10n.previousDrawer,
            style: IcButtonStyle.ghost,
            expand: true,
            onPressed: () => vm.back(),
          ),
        ],
      ],
    );
  }

  Future<void> _editNote(BuildContext context, MonthlyCheckViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    var text = vm.notes;
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(l10n.addNote),
        content: SizedBox(
          width: 420,
          child: TextFormField(
            initialValue: vm.notes,
            autofocus: true,
            maxLines: 4,
            onChanged: (v) => text = v,
            decoration: InputDecoration(hintText: l10n.noteHint),
          ),
        ),
        actions: [
          IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
          IcButton(label: l10n.actionSave, onPressed: () => Navigator.of(context).pop(text)),
        ],
      ),
    );
    if (saved != null) await vm.setNotes(saved);
  }
}

/// The outcome of one lot. "Mantido" can be changed later; "Substituído" and
/// "Retirado sem reposição" update the stock and lock the answer.
Future<void> _answer(BuildContext context, MonthlyCheckViewModel vm, CheckItem item) async {
  final l10n = AppLocalizations.of(context);
  final format = IcFormat.of(context);
  final allowed = checkOutcomes[item.issue]!;
  if (item.locked) {
    final outcome = item.outcome!;
    return showMessage(
      context,
      [
        checkOutcomeText(l10n, outcome),
        if (item.units != null) l10n.checkUnits(item.units!),
        if (item.newExpiry != null) l10n.checkNewExpiryShort(format.numeric(item.newExpiry!)),
      ].join(' · '),
    );
  }
  var choice = item.outcome ?? allowed.first;
  final max = vm.maxUnits(item);
  var units = vm.defaultUnits(item).clamp(max == 0 ? 0 : 1, max);
  DateTime? newExpiry;
  var newLot = '';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final changesStock = outcomeChangesStock(choice);
        return AlertDialog(
          title: Text(item.productName),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${item.issue == FindingIssue.expired ? l10n.slotHealthExpired : l10n.slotHealthExpiring} · ${_itemMeta(l10n, format, item)}',
                    style: IcText.bodyM.copyWith(color: item.issue == FindingIssue.expired ? IcColors.dangerFg : IcColors.warningFg),
                  ),
                  const SizedBox(height: IcSpace.s16),
                  SegmentedTabs<CheckOutcome>(
                    items: [for (final o in allowed) TabItem(o, checkOutcomeText(l10n, o))],
                    selected: choice,
                    onChanged: (o) => setState(() => choice = o),
                  ),
                  const SizedBox(height: IcSpace.s16),
                  if (choice == CheckOutcome.kept)
                    Text(l10n.checkKeptHelp, style: IcText.bodyS.copyWith(color: IcColors.textSecondary))
                  else ...[
                    Row(
                      children: [
                        Expanded(child: Text(l10n.quantityLabel, style: IcText.bodyM)),
                        QuantityStepper(
                          label: l10n.quantityLabel,
                          value: units,
                          min: max == 0 ? 0 : 1,
                          max: max,
                          onChanged: (v) => setState(() => units = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: IcSpace.s12),
                    if (choice == CheckOutcome.replaced) ...[
                      LabeledField(
                        key: ValueKey(newExpiry),
                        label: l10n.checkNewExpiryLabel,
                        initialValue: newExpiry == null ? '' : format.numeric(newExpiry!),
                        hint: l10n.chooseExpiryLabel,
                        readOnly: true,
                        onTap: () async {
                          final now = DateTime.now();
                          final first = item.expiryDate.isAfter(now) ? item.expiryDate.add(const Duration(days: 1)) : now;
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: newExpiry ?? now.add(const Duration(days: 365)),
                            firstDate: first,
                            lastDate: now.add(const Duration(days: 3650)),
                          );
                          if (picked != null) setState(() => newExpiry = picked);
                        },
                      ),
                      const SizedBox(height: IcSpace.s12),
                      LabeledField(
                        label: l10n.lotOptionalLabel,
                        onChanged: (v) => newLot = v,
                        inputFormatters: [LengthLimitingTextInputFormatter(40)],
                      ),
                    ] else
                      Text(l10n.checkRemovedHelp, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
                    const SizedBox(height: IcSpace.s12),
                    Notice(kind: NoticeKind.warning, title: l10n.checkStockWarning),
                  ],
                  if (changesStock && max == 0) ...[
                    const SizedBox(height: IcSpace.s8),
                    Text(l10n.errorQuantityRequired, style: IcText.bodyS.copyWith(color: IcColors.dangerFg)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (item.outcome == CheckOutcome.kept)
              IcButton(
                label: l10n.checkClearAnswer,
                style: IcButtonStyle.ghost,
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
            IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(dialogContext).pop()),
            IcButton(
              label: l10n.actionConfirm,
              icon: IcIcon.confirmar,
              onPressed: changesStock && max == 0 ? null : () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    ),
  );
  if (confirmed == null || !context.mounted) return;
  if (confirmed == false) return vm.setKept(item, false);
  switch (choice) {
    case CheckOutcome.kept:
      await vm.setKept(item, true);
    case CheckOutcome.replaced:
      final result = await vm.replace(item, units: units, newExpiry: newExpiry, newLot: newLot);
      if (context.mounted) showResult(context, result);
    case CheckOutcome.removed:
      final result = await vm.remove(item, units: units);
      if (context.mounted) showResult(context, result);
  }
}
