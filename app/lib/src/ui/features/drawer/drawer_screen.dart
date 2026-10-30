import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../common/repository_failure.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/inventory_health.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/slot_grid.dart';
import '../../core/widgets/status.dart';
import '../scanner/product_scan_sheet.dart';
import 'drawer_view_model.dart';

/// A6 · Gaveta (grid + slot panel) and A7 · Repor stock (same screen, panel
/// in replenish mode). Tap a slot → panel; no hidden long-press (audit D12).
class DrawerScreen extends StatelessWidget {
  const DrawerScreen({super.key, required this.cartId, required this.drawerId, this.initialSlotId});

  final String cartId;
  final String drawerId;
  final String? initialSlotId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<DrawerViewModel>(
      create: (services) => DrawerViewModel(services, session, cartId: cartId, drawerId: drawerId, initialSlotId: initialSlotId),
      builder: (context, vm) {
        if (vm.drawerMissing) return StateView.message(message: l10n.stateLoadError, icon: IcIcon.gaveta);
        final drawer = vm.drawer;
        if (!vm.ready || drawer == null) return const StateView.loading();
        final compact = isCompactHeight(context);
        final cart = vm.data.cart!;
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: l10n.drawerShort(vm.drawerNumber),
                subtitle: compact
                    ? l10n.drawerSubtitleShort(cart.name, drawer.rows, drawer.columns)
                    : l10n.drawerSubtitle(cart.name, drawer.rows, drawer.columns, vm.slots.length),
                onBack: () => Navigator.of(context).maybePop(),
                trailing: [
                  IcButton(
                    label: l10n.navScan,
                    icon: IcIcon.ler,
                    style: IcButtonStyle.secondary,
                    onPressed: () => _scan(context, vm),
                  ),
                ],
              ),
              SizedBox(height: compact ? IcSpace.s12 : IcSpace.s20),
              Expanded(
                child: OverlayPanelLayout(
                  panelWidth: 360,
                  onClose: vm.clearSelection,
                  body: SlotGrid(
                    rows: drawer.rows,
                    columns: drawer.columns,
                    cells: vm.cells,
                    compact: compact,
                    selectedSlotIds: {if (vm.selectedSlotId != null) vm.selectedSlotId!},
                    // Tapping the open slot again closes the panel.
                    onTap: (cell) => cell.slot.id == vm.selectedSlotId ? vm.clearSelection() : vm.select(cell.slot.id),
                  ),
                  panel: vm.selectedSlot == null ? null : _Panel(key: ValueKey(vm.selectedSlotId), vm: vm),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scan(BuildContext context, DrawerViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    final parsed = await showProductScanSheet(context);
    if (parsed == null || !context.mounted) return;
    await vm.applyScan(parsed);
    if (!context.mounted) return;
    if (vm.scanUnknownGtin) showMessage(context, l10n.gs1UnknownGtin);
    if (vm.scanWarningProduct != null) showMessage(context, l10n.gs1WrongProductWarning(vm.scanWarningProduct!));
    vm.clearScanWarnings();
  }
}

class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.vm});
  final DrawerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (vm.selectedSlot == null) {
      return StateView.message(message: l10n.drawerSelectHint, icon: IcIcon.grelha);
    }
    return switch (vm.panel) {
      DrawerPanel.detail => _DetailPanel(vm: vm),
      DrawerPanel.consume => _ConsumePanel(vm: vm),
      DrawerPanel.replenish => _ReplenishPanel(vm: vm),
      DrawerPanel.assign => _AssignPanel(vm: vm),
    };
  }
}

/// A6 detail.
class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.vm});
  final DrawerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    final session = SessionScope.of(context);
    final compact = isCompactHeight(context);
    final slot = vm.selectedSlot!;
    final assignment = vm.selectedAssignment;
    final position = l10n.slotPositionInDrawer(slotPositionLabel(slot), vm.drawerNumber);

    if (assignment == null) {
      return PanelColumn(
        children: [
          const Align(alignment: Alignment.centerLeft, child: SlotHealthBadge(health: SlotHealth.free)),
          const SizedBox(height: IcSpace.s12),
          Text(l10n.slotFreeTitle, style: IcText.titleM),
          const SizedBox(height: IcSpace.s4),
          Text(position, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
          const SizedBox(height: IcSpace.s12),
          Text(l10n.emptySlotMessage, style: IcText.bodyM.copyWith(color: IcColors.textSecondary)),
          const Spacer(),
          if (session.canEditStructure)
            IcButton(
              label: l10n.assignDialogTitle,
              icon: IcIcon.mais,
              size: IcButtonSize.l,
              expand: true,
              onPressed: () => vm.showPanel(DrawerPanel.assign),
            ),
        ],
      );
    }

    final health = vm.selectedHealth;
    final expiry = assignment.earliestKnownExpiry;
    final daysLeft = expiry?.difference(DateTime.now()).inDays;
    // P9: a batch may have no lot number; it still has its expiry date.
    final first = vm.batches.firstOrNull;
    final lot = first == null
        ? '—'
        : first.quantity == null
            ? (first.lotNumber ?? l10n.noLot)
            : l10n.lotWithUnits(first.lotNumber ?? l10n.noLot, first.quantity!);
    final expiryColor = switch (health) {
      SlotHealth.expired => IcColors.dangerFg,
      SlotHealth.expiring => IcColors.warningFg,
      _ => IcColors.textPrimary,
    };
    return PanelColumn(
      children: [
        if (health != SlotHealth.ok) Align(alignment: Alignment.centerLeft, child: SlotHealthBadge(health: health)),
        if (health != SlotHealth.ok) const SizedBox(height: IcSpace.s12),
        Text(vm.data.productName(assignment.productId, removed: l10n.productRemoved), style: IcText.titleM, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: IcSpace.s4),
        Text(
          compact ? '$position · ${l10n.unitsOf(assignment.currentQuantity, assignment.targetQuantity)}' : position,
          style: IcText.bodyS.copyWith(color: IcColors.textSecondary),
        ),
        if (!compact) ...[
          const SizedBox(height: IcSpace.s16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${assignment.currentQuantity}', style: IcText.numberL),
              const SizedBox(width: 6),
              Text(l10n.ofTargetUnits(assignment.targetQuantity), style: IcText.bodyM.copyWith(color: IcColors.textSecondary)),
            ],
          ),
          const SizedBox(height: IcSpace.s16),
        ],
        InfoRow(
          label: l10n.expiryLabel,
          value: expiry == null ? '—' : (compact ? format.dayMonth(expiry) : '${format.date(expiry)} (${l10n.daysCount(daysLeft!)})'),
          valueColor: expiryColor,
        ),
        if (!compact) InfoRow(label: l10n.lotLabel, value: lot),
        const Spacer(),
        if (session.canConsume)
          IcButton(
            label: l10n.recordConsumptionTitle,
            icon: IcIcon.menos,
            size: compact ? IcButtonSize.m : IcButtonSize.l,
            expand: true,
            onPressed: assignment.currentQuantity > 0 ? () => vm.showPanel(DrawerPanel.consume) : null,
          ),
        if (session.canReplenish) ...[
          const SizedBox(height: IcSpace.s12),
          IcButton(
            label: l10n.replenishStockTitle,
            icon: IcIcon.mais,
            style: IcButtonStyle.secondary,
            expand: true,
            // P5: a full slot can't take more units.
            onPressed: vm.replenishMax > 0 ? () => vm.showPanel(DrawerPanel.replenish) : null,
          ),
        ],
        // D21: the same actions on phones. D23/P15: no "Corrigir" and no
        // "Reconciliar" (a signed report never changes).
        if (session.canEditStructure) ...[
          const SizedBox(height: IcSpace.s12),
          IcButton(
            label: l10n.changeProductAction,
            style: IcButtonStyle.ghost,
            expand: true,
            // P1: a slot with History keeps its product.
            onPressed: vm.selectedInUse ? () => showMessage(context, l10n.slotInUseHint) : () => vm.showPanel(DrawerPanel.assign),
          ),
        ],
      ],
    );
  }
}

/// Shared panel scaffold: title, subtitle, body, confirm + cancel.
class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.vm,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.confirmLabel,
    required this.onConfirm,
    this.danger = false,
  });

  final DrawerViewModel vm;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = isCompactHeight(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: IcText.titleM),
        const SizedBox(height: IcSpace.s4),
        Text(subtitle, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
        const SizedBox(height: IcSpace.s16),
        Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children))),
        const SizedBox(height: IcSpace.s12),
        IcButton(
          label: confirmLabel,
          icon: IcIcon.confirmar,
          style: danger ? IcButtonStyle.danger : IcButtonStyle.primary,
          size: compact ? IcButtonSize.m : IcButtonSize.l,
          expand: true,
          busy: vm.busy,
          onPressed: onConfirm,
        ),
        const SizedBox(height: IcSpace.s12),
        IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, expand: true, onPressed: vm.cancelPanel),
      ],
    );
  }
}

String _subtitle(AppLocalizations l10n, DrawerViewModel vm) {
  final a = vm.selectedAssignment;
  final position = slotPositionLabel(vm.selectedSlot!);
  if (a == null) return position;
  return l10n.panelSubtitle(vm.data.productName(a.productId, removed: l10n.productRemoved), position, a.currentQuantity, a.targetQuantity);
}

Widget _labeledRow(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: IcSpace.s12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: IcText.bodyM.copyWith(color: IcColors.textSecondary))),
          child,
        ],
      ),
    );

class _ConsumePanel extends StatelessWidget {
  const _ConsumePanel({required this.vm});
  final DrawerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = vm.selectedAssignment?.currentQuantity ?? 0;
    return _FormPanel(
      vm: vm,
      title: l10n.recordConsumptionTitle,
      subtitle: _subtitle(l10n, vm),
      confirmLabel: l10n.confirmConsumption,
      onConfirm: () async {
        final result = await vm.consume(vm.amount);
        if (!context.mounted) return;
        showResult(context, result, success: l10n.consumptionRecorded, failure: result.code == 'exceeds' ? l10n.consumeExceedsError : null);
      },
      children: [
        _labeledRow(
          l10n.quantityLabel,
          QuantityStepper(label: l10n.quantityLabel, value: vm.amount, min: 1, max: current, onChanged: vm.setAmount),
        ),
      ],
    );
  }
}

/// A7 · Repor stock.
class _ReplenishPanel extends StatefulWidget {
  const _ReplenishPanel({required this.vm});
  final DrawerViewModel vm;

  @override
  State<_ReplenishPanel> createState() => _ReplenishPanelState();
}

class _ReplenishPanelState extends State<_ReplenishPanel> {
  late final _lot = TextEditingController(text: widget.vm.lot);

  @override
  void didUpdateWidget(_ReplenishPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vm.lot != _lot.text) _lot.text = widget.vm.lot;
  }

  @override
  void dispose() {
    _lot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    final vm = widget.vm;
    return _FormPanel(
      vm: vm,
      title: l10n.replenishStockTitle,
      subtitle: _subtitle(l10n, vm),
      confirmLabel: l10n.confirmReplenishment,
      onConfirm: () async {
        vm.setLot(_lot.text);
        final result = await vm.replenish();
        if (!context.mounted) return;
        showResult(
          context,
          result,
          success: l10n.replenishmentRecorded,
          failure: switch (result.code) {
            'expiryRequired' => l10n.replenishMissingExpiry,
            _ => null,
          },
        );
      },
      children: [
        _labeledRow(
          l10n.quantityLabel,
          QuantityStepper(label: l10n.quantityLabel, value: vm.amount, min: 1, max: vm.replenishMax.clamp(1, 9999), onChanged: vm.setAmount),
        ),
        LabeledField(
          label: l10n.lotOptionalLabel,
          controller: _lot,
          onChanged: vm.setLot,
          trailing: IcIconButton(
            icon: IcIcon.ler,
            tooltip: l10n.gs1ScanTitle,
            background: IcColors.actionSecondary,
            foreground: IcColors.textLink,
            bordered: false,
            onPressed: () async {
              final parsed = await showProductScanSheet(context);
              if (parsed != null) await vm.applyScan(parsed);
            },
          ),
        ),
        const SizedBox(height: IcSpace.s12),
        LabeledField(
          key: ValueKey(vm.expiry),
          label: l10n.expiryLabel,
          initialValue: vm.expiry == null ? '' : format.numeric(vm.expiry!),
          hint: l10n.chooseExpiryLabel,
          readOnly: true,
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: vm.expiry ?? now.add(const Duration(days: 365)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 3650)),
            );
            if (picked != null) vm.setExpiry(picked);
          },
        ),
        const SizedBox(height: IcSpace.s12),
        Text(l10n.replenishScanHelp, style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
      ],
    );
  }
}

/// "Trocar produto" / "Atribuir produto".
class _AssignPanel extends StatefulWidget {
  const _AssignPanel({required this.vm});
  final DrawerViewModel vm;

  @override
  State<_AssignPanel> createState() => _AssignPanelState();
}

class _AssignPanelState extends State<_AssignPanel> {
  Product? _product;
  String _query = '';
  late int _target = widget.vm.selectedAssignment?.targetQuantity ?? 1;
  int _initial = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = widget.vm;
    final swapping = vm.selectedAssignment != null;
    final products = vm.assignableProducts.where((p) => _query.isEmpty || p.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return _FormPanel(
      vm: vm,
      title: swapping ? l10n.changeProductAction : l10n.assignDialogTitle,
      subtitle: _subtitle(l10n, vm),
      confirmLabel: swapping ? l10n.changeProductAction : l10n.actionAssign,
      danger: swapping,
      onConfirm: _product == null
          ? null
          : () async {
              if (swapping &&
                  !await confirmAction(
                    context,
                    title: l10n.changeProductAction,
                    message: l10n.changeProductConfirm,
                    confirmLabel: l10n.changeProductAction,
                    destructive: true,
                  )) {
                return;
              }
              final result = await vm.assign(_product!, target: _target, initial: _initial);
              if (!context.mounted) return;
              showResult(
                context,
                result,
                failure: result.failure == RepositoryFailureReason.conflict && result.code == null ? l10n.assignConflictError : null,
              );
            },
      children: [
        SearchField(hint: l10n.catalogSearchHint, width: null, onChanged: (v) => setState(() => _query = v)),
        const SizedBox(height: IcSpace.s8),
        if (products.isEmpty)
          Text(l10n.noProductsMessage, style: IcText.bodyS.copyWith(color: IcColors.textSecondary))
        else
          for (final product in products.take(8))
            InkWell(
              onTap: () => setState(() => _product = product),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(product == _product ? Icons.radio_button_checked : Icons.radio_button_off, size: 20,
                        color: product == _product ? IcColors.actionPrimary : IcColors.borderStrong),
                    const SizedBox(width: IcSpace.s8),
                    Expanded(child: Text(product.name, style: IcText.bodyM)),
                  ],
                ),
              ),
            ),
        const SizedBox(height: IcSpace.s12),
        _labeledRow(
          l10n.targetQuantityLabel,
          QuantityStepper(
            label: l10n.targetQuantityLabel,
            value: _target,
            min: 1,
            onChanged: (v) => setState(() {
              _target = v;
              if (_initial > v) _initial = v;
            }),
          ),
        ),
        // P5: the initial quantity can't exceed the target.
        _labeledRow(
          l10n.initialQuantityLabel,
          QuantityStepper(label: l10n.initialQuantityLabel, value: _initial, max: _target, onChanged: (v) => setState(() => _initial = v)),
        ),
      ],
    );
  }
}
