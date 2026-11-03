import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../common/repository_failure.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/usage_event.dart';
import '../../../domain/inventory_health.dart';
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
                title: l10n.drawerTitle(vm.drawerNumber, drawer.name),
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
      DrawerPanel.correct => _CorrectPanel(vm: vm),
      DrawerPanel.assign => _AssignPanel(vm: vm),
      DrawerPanel.reconcile => _ReconcilePanel(vm: vm),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
    final lot = vm.batches.isEmpty
        ? '—'
        : vm.batches.first.quantity == null
            ? vm.batches.first.lotNumber
            : l10n.lotWithUnits(vm.batches.first.lotNumber, vm.batches.first.quantity!);
    final expiryColor = switch (health) {
      SlotHealth.expired => IcColors.dangerFg,
      SlotHealth.expiring => IcColors.warningFg,
      _ => IcColors.textPrimary,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        if (!compact) ...[
          InfoRow(label: l10n.lotLabel, value: lot),
          InfoRow(label: l10n.minimumLabel, value: assignment.minimumQuantity?.toString() ?? '—'),
        ],
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
            onPressed: () => vm.showPanel(DrawerPanel.replenish),
          ),
        ],
        if (!compact) ...[
          const SizedBox(height: IcSpace.s12),
          Row(
            children: [
              if (session.canEditStructure) ...[
                Expanded(
                  child: IcButton(
                    label: l10n.changeProductAction,
                    style: IcButtonStyle.ghost,
                    expand: true,
                    onPressed: () => vm.showPanel(DrawerPanel.assign),
                  ),
                ),
                const SizedBox(width: IcSpace.s8),
              ],
              Expanded(
                child: IcButton(
                  label: l10n.actionCorrect,
                  icon: IcIcon.editar,
                  style: IcButtonStyle.ghost,
                  expand: true,
                  onPressed: () => vm.showPanel(DrawerPanel.correct),
                ),
              ),
            ],
          ),
          if (session.canReplenish)
            Align(
              alignment: Alignment.center,
              child: TextButton(onPressed: () => vm.showPanel(DrawerPanel.reconcile), child: Text(l10n.actionReconcile)),
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
            'lotRequired' => l10n.lotRequiredValidation,
            'expiryRequired' => l10n.replenishMissingExpiry,
            _ => null,
          },
        );
      },
      children: [
        _labeledRow(
          l10n.quantityLabel,
          QuantityStepper(label: l10n.quantityLabel, value: vm.amount, min: 1, onChanged: vm.setAmount),
        ),
        LabeledField(
          label: l10n.lotLabel,
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

class _CorrectPanel extends StatefulWidget {
  const _CorrectPanel({required this.vm});
  final DrawerViewModel vm;

  @override
  State<_CorrectPanel> createState() => _CorrectPanelState();
}

class _CorrectPanelState extends State<_CorrectPanel> {
  UsageEvent? _event;
  int _adjust = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    final vm = widget.vm;
    final events = vm.events;
    _event ??= events.isEmpty ? null : events.first;
    return _FormPanel(
      vm: vm,
      title: l10n.correctEventDialogTitle,
      subtitle: _subtitle(l10n, vm),
      confirmLabel: l10n.actionCorrect,
      onConfirm: _event == null || _adjust == 0
          ? null
          : () async {
              final result = await vm.correct(_event!, _adjust);
              if (!context.mounted) return;
              showResult(context, result, success: l10n.correctionRecorded);
            },
      children: [
        if (events.isEmpty)
          Text(l10n.noEventsToCorrect, style: IcText.bodyM.copyWith(color: IcColors.textSecondary))
        else ...[
          Text(l10n.eventToCorrectLabel, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
          const SizedBox(height: 6),
          for (final event in events.take(6))
            InkWell(
              borderRadius: BorderRadius.circular(IcRadius.sm),
              onTap: () => setState(() {
                _event = event;
                _adjust = -event.amount;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(event == _event ? Icons.radio_button_checked : Icons.radio_button_off, size: 20,
                        color: event == _event ? IcColors.actionPrimary : IcColors.borderStrong),
                    const SizedBox(width: IcSpace.s8),
                    Expanded(child: Text('${usageEventText(l10n, event.type)} ${IcFormat.signed(event.amount)}', style: IcText.bodyM)),
                    if (event.serverTimestamp != null)
                      Text(format.relative(event.serverTimestamp!), style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: IcSpace.s12),
          _labeledRow(
            l10n.adjustmentLabel,
            QuantityStepper(label: l10n.adjustmentLabel, value: _adjust, min: -999, max: 999, onChanged: (v) => setState(() => _adjust = v)),
          ),
        ],
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
              showResult(context, result, failure: result.failure == RepositoryFailureReason.conflict ? l10n.assignConflictError : null);
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
        _labeledRow(l10n.targetQuantityLabel, QuantityStepper(label: l10n.targetQuantityLabel, value: _target, min: 1, onChanged: (v) => setState(() => _target = v))),
        _labeledRow(l10n.initialQuantityLabel, QuantityStepper(label: l10n.initialQuantityLabel, value: _initial, onChanged: (v) => setState(() => _initial = v))),
      ],
    );
  }
}

/// Physical audit reconciliation (kept from the previous app: confirms
/// quantity and which lots are really present).
class _ReconcilePanel extends StatefulWidget {
  const _ReconcilePanel({required this.vm});
  final DrawerViewModel vm;

  @override
  State<_ReconcilePanel> createState() => _ReconcilePanelState();
}

class _ReconcilePanelState extends State<_ReconcilePanel> {
  late int _quantity = widget.vm.selectedAssignment?.currentQuantity ?? 0;
  late final Set<String> _batchIds = widget.vm.batches.map((b) => b.id).toSet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    final vm = widget.vm;
    return _FormPanel(
      vm: vm,
      title: l10n.reconcileDialogTitle,
      subtitle: _subtitle(l10n, vm),
      confirmLabel: l10n.actionConfirm,
      onConfirm: () async {
        final result = await vm.reconcile(confirmedQuantity: _quantity, confirmedBatchIds: _batchIds);
        if (!context.mounted) return;
        showResult(context, result, success: l10n.reconcileRecorded);
      },
      children: [
        _labeledRow(l10n.confirmedQuantityLabel, QuantityStepper(label: l10n.confirmedQuantityLabel, value: _quantity, onChanged: (v) => setState(() => _quantity = v))),
        if (vm.batches.isEmpty)
          Text(l10n.noBatchesMessage, style: IcText.bodyS.copyWith(color: IcColors.textSecondary))
        else ...[
          Text(l10n.confirmedBatchesLabel, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
          for (final batch in vm.batches)
            CheckRow(
              label: '${l10n.batchLotLabel(batch.lotNumber)} · ${format.numeric(batch.expiryDate)}',
              value: _batchIds.contains(batch.id),
              onChanged: (checked) => setState(() => checked ? _batchIds.add(batch.id) : _batchIds.remove(batch.id)),
            ),
        ],
      ],
    );
  }
}
