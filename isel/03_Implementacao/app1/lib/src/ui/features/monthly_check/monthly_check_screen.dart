import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/inventory_health.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import '../../shells/shell_navigation.dart';
import '../reports/report_screen.dart';
import 'monthly_check_view_model.dart';

/// A8 · Verificação mensal.
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
        final drawer = vm.drawer;
        final cart = vm.data.cart!;
        final compact = isCompactHeight(context);
        if (drawer == null) {
          return Padding(
            padding: contentPadding(context),
            child: Column(
              children: [
                PageHeader(title: l10n.monthlyCheckTitle, subtitle: cart.name, onBack: () => Navigator.of(context).maybePop()),
                Expanded(child: StateView.message(message: l10n.cartDetailDrawersEmpty, icon: IcIcon.gaveta)),
              ],
            ),
          );
        }
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: l10n.monthlyCheckTitle,
                subtitle: l10n.monthlyCheckSubtitle(cart.name, vm.drawerIndex + 1, vm.drawers.length, drawer.name),
                onBack: () => Navigator.of(context).maybePop(),
                trailing: [
                  IcButton(
                    label: l10n.saveAndExit,
                    style: IcButtonStyle.secondary,
                    onPressed: () async {
                      await vm.saveDraft();
                      if (context.mounted) Navigator.of(context).maybePop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: IcSpace.s16),
              _Progress(index: vm.drawerIndex, total: vm.drawers.length),
              SizedBox(height: compact ? IcSpace.s12 : IcSpace.s16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SurfaceCard(
                        elevated: false,
                        padding: const EdgeInsets.symmetric(vertical: IcSpace.s8),
                        child: _Rows(vm: vm),
                      ),
                    ),
                    SizedBox(width: compact ? IcSpace.s12 : IcSpace.s20),
                    SidePanel(child: _Summary(vm: vm, drawerLabel: l10n.drawerTitle(vm.drawerIndex + 1, drawer.name))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.index, required this.total});
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).progressSemantics(index + 1, total),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: i < index ? IcColors.okFg : (i == index ? IcColors.actionPrimary : IcColors.bgSurfaceSunken),
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

class _Rows extends StatelessWidget {
  const _Rows({required this.vm});
  final MonthlyCheckViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    final rows = vm.rows;
    if (rows.isEmpty) return StateView.message(message: l10n.monthlyCheckEmptyDrawer, icon: IcIcon.gaveta);
    // Phones scroll; tablets show the positions in columns, paged if needed.
    return FitList(
      itemCount: rows.length,
      itemExtent: 52,
      spacing: 0,
      minColumnWidth: 380,
      itemBuilder: (context, index) {
        final row = rows[index];
        final a = row.assignment;
        final expiry = a.earliestKnownExpiry;
        final String meta;
        final Color color;
        if ((row.health == SlotHealth.expired || row.health == SlotHealth.expiring) && expiry != null) {
          meta = '${row.position} · ${l10n.expiresOn(format.numeric(expiry))}';
          color = row.health == SlotHealth.expired ? IcColors.dangerFg : IcColors.warningFg;
        } else if (row.state == CheckState.unchecked) {
          meta = '${row.position} · ${l10n.expectedUnits(a.targetQuantity)}';
          color = IcColors.textSecondary;
        } else {
          final validity = expiry == null ? '' : ' · ${l10n.expiryShort('${expiry.month.toString().padLeft(2, '0')}/${expiry.year}')}';
          meta = '${row.position} · ${l10n.unitsOf(a.currentQuantity, a.targetQuantity)}$validity';
          color = IcColors.textSecondary;
        }
        return Semantics(
          button: true,
          label: '${row.productName}, $meta',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => vm.toggle(row),
            onLongPress: () => vm.clear(row),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: IcSpace.s16, vertical: 6),
              child: Row(
                children: [
                  CheckBox3(state: row.state),
                  const SizedBox(width: IcSpace.s12),
                  Expanded(child: Text(row.productName, style: IcText.bodyM, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: IcSpace.s12),
                  Flexible(child: Text(meta, style: IcText.bodyS.copyWith(color: color), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
  const _Summary({required this.vm, required this.drawerLabel});
  final MonthlyCheckViewModel vm;
  final String drawerLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = isCompactHeight(context);
    final checked = vm.count(CheckState.checked);
    final problems = vm.count(CheckState.problem);
    final pending = vm.count(CheckState.unchecked);
    Widget line(IcIcon icon, Color color, String text) => Padding(
          padding: const EdgeInsets.only(bottom: IcSpace.s8),
          child: Row(children: [
            IcIconView(icon, size: 18, color: color),
            const SizedBox(width: IcSpace.s8),
            Expanded(child: Text(text, style: IcText.labelM.copyWith(color: color))),
          ]),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(drawerLabel, style: IcText.titleS),
        const SizedBox(height: IcSpace.s12),
        line(IcIcon.okCirculo, IcColors.okFg, l10n.checkVerified(checked)),
        line(IcIcon.alerta, IcColors.warningFg, l10n.checkProblems(problems)),
        line(IcIcon.relogio, IcColors.textSecondary, l10n.checkPending(pending)),
        if (!compact) ...[
          const SizedBox(height: IcSpace.s4),
          Text(l10n.monthlyCheckHelp, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
        ],
        if (pending > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: vm.markAllRemaining,
              child: Text(l10n.checkMarkAll),
            ),
          ),
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
          label: vm.isLastDrawer ? l10n.finishCheck : l10n.nextDrawer,
          icon: vm.isLastDrawer ? IcIcon.confirmar : IcIcon.seguinte,
          size: compact ? IcButtonSize.m : IcButtonSize.l,
          expand: true,
          busy: vm.busy,
          onPressed: !vm.drawerComplete
              ? null
              : () async {
                  if (!vm.isLastDrawer) return vm.nextDrawer();
                  final result = await vm.finish();
                  if (!context.mounted) return;
                  if (!result.isOk) return showResult(context, result);
                  Navigator.of(context).pushReplacement(sectionRoute((_) => ReportScreen(reportId: result.value!)));
                },
        ),
        if (vm.drawerIndex > 0) ...[
          const SizedBox(height: IcSpace.s8),
          IcButton(label: l10n.previousDrawer, style: IcButtonStyle.ghost, expand: true, onPressed: vm.previousDrawer),
        ],
      ],
    );
  }

  Future<void> _editNote(BuildContext context, MonthlyCheckViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: vm.notes);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addNote),
        content: SizedBox(
          width: 420,
          child: TextField(controller: controller, autofocus: true, maxLines: 4, decoration: InputDecoration(hintText: l10n.noteHint)),
        ),
        actions: [
          IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
          IcButton(label: l10n.actionSave, onPressed: () => Navigator.of(context).pop(controller.text)),
        ],
      ),
    );
    controller.dispose();
    if (text != null) vm.setNotes(text);
  }
}
