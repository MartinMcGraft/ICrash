import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/cart_product_assignment.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/inventory_health.dart';
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
import 'grid_editor_view_model.dart';

/// B4 · Editor de grelha.
class GridEditorScreen extends StatelessWidget {
  const GridEditorScreen({super.key, required this.cartId, required this.drawerId, this.initialSlotId});

  final String cartId;
  final String drawerId;
  final String? initialSlotId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<GridEditorViewModel>(
      create: (services) => GridEditorViewModel(services, session, cartId: cartId, drawerId: drawerId, initialSlotId: initialSlotId),
      builder: (context, vm) {
        if (vm.data.cartMissing) return StateView.message(message: l10n.cartLoginNotFound, icon: IcIcon.carro);
        if (!vm.ready) return const StateView.loading();
        final drawer = vm.drawer!;
        return PopScope(
          canPop: !vm.dirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final leave = await confirmAction(
              context,
              title: l10n.unsavedGridTitle,
              message: l10n.unsavedGridMessage,
              confirmLabel: l10n.discardChanges,
              destructive: true,
            );
            if (!leave || !context.mounted) return;
            vm.cancelEdits();
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: contentPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: l10n.gridEditorTitle(vm.drawerNumber, drawer.name),
                  subtitle: l10n.gridEditorSubtitle(vm.data.cart?.name ?? ''),
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: [
                    IcButton(
                      label: l10n.actionCancel,
                      style: IcButtonStyle.ghost,
                      onPressed: vm.dirty ? vm.cancelEdits : () => Navigator.of(context).maybePop(),
                    ),
                    IcButton(
                      label: l10n.saveGrid,
                      icon: IcIcon.confirmar,
                      busy: vm.busy,
                      onPressed: vm.dirty
                          ? () async {
                              final result = await vm.save();
                              if (context.mounted) showResult(context, result, success: l10n.gridSaved);
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: IcSpace.s20),
                Expanded(child: _GridArea(vm: vm, panelKey: _panelKey(vm))),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _panelKey(GridEditorViewModel vm) {
    final a = vm.selectedAssignment;
    return '${vm.selected.join(',')}|${a?.id}|${a?.productId}|${a?.targetQuantity}|${a?.minimumQuantity}';
  }
}

class _GridArea extends StatelessWidget {
  const _GridArea({required this.vm, required this.panelKey});
  final GridEditorViewModel vm;
  final String panelKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedAssignment = vm.selectedAssignment;
    return SurfaceCard(
      elevated: false,
      padding: const EdgeInsets.all(IcSpace.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: IcSpace.s16,
            runSpacing: IcSpace.s12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Dimension(label: l10n.createDrawerRowsLabel, value: vm.rows, onChanged: (v) => vm.resize(newRows: v)),
              _Dimension(label: l10n.createDrawerColumnsLabel, value: vm.columns, onChanged: (v) => vm.resize(newColumns: v)),
              const SizedBox(width: IcSpace.s8),
              IcButton(
                label: l10n.mergePositions,
                icon: IcIcon.grelha,
                style: IcButtonStyle.secondary,
                onPressed: vm.selected.length >= 2 ? () => _merge(context) : null,
              ),
              IcButton(
                label: l10n.actionSplit,
                style: IcButtonStyle.secondary,
                onPressed: vm.canSplit ? vm.split : null,
              ),
              IcButton(
                label: l10n.clearPosition,
                icon: IcIcon.apagar,
                style: IcButtonStyle.ghost,
                onPressed: selectedAssignment == null
                    ? null
                    : () async {
                        final ok = await confirmAction(
                          context,
                          title: l10n.clearPosition,
                          message: l10n.clearPositionConfirm(
                            vm.data.productName(selectedAssignment.productId),
                            slotPositionLabel(vm.selectedSlot!),
                          ),
                          confirmLabel: l10n.clearPosition,
                          destructive: true,
                        );
                        if (!ok || !context.mounted) return;
                        final result = await vm.clearPosition();
                        if (!context.mounted) return;
                        showResult(context, result);
                      },
              ),
            ],
          ),
          const SizedBox(height: IcSpace.s8),
          Text(l10n.gridSelectionHint, style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
          const SizedBox(height: IcSpace.s16),
          Expanded(
            // The position panel slides in over the grid, so the grid keeps
            // the full width and never scrolls.
            child: OverlayPanelLayout(
              panelWidth: 380,
              onClose: vm.clearSelection,
              body: SlotGrid(
                rows: vm.rows,
                columns: vm.columns,
                cells: vm.cells,
                selectedSlotIds: vm.selected,
                onTap: (cell) => vm.toggle(cell.slot.id),
                onLongPress: (cell) => vm.selectOnly(cell.slot.id),
              ),
              panel: vm.selectedSlot == null ? null : _PositionPanel(key: ValueKey(panelKey), vm: vm),
            ),
          ),
          if (vm.orphans.isNotEmpty) ...[
            const SizedBox(height: IcSpace.s16),
            _Orphans(vm: vm),
          ],
        ],
      ),
    );
  }

  Future<void> _merge(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (!vm.canMerge) return showMessage(context, l10n.slotSelectionNotRectangle);
    // Only the top-left position keeps its product; the others' products
    // become "sem posição" until reassigned.
    final bySlot = vm.data.assignmentsBySlot;
    final selectedSlots = vm.slots.where((s) => vm.selected.contains(s.id)).toList()
      ..sort((a, b) => a.row != b.row ? a.row.compareTo(b.row) : a.column.compareTo(b.column));
    final losing = selectedSlots.skip(1).where((s) => bySlot.containsKey(s.id)).length;
    if (losing > 0) {
      final ok = await confirmAction(
        context,
        title: l10n.mergePositions,
        message: l10n.mergeLosesAssignments(losing),
        confirmLabel: l10n.mergePositions,
      );
      if (!ok) return;
    }
    vm.merge();
  }
}

class _Dimension extends StatelessWidget {
  const _Dimension({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: IcText.labelM.copyWith(color: IcColors.textSecondary)),
        const SizedBox(width: IcSpace.s8),
        QuantityStepper(label: label, value: value, min: 1, max: 12, onChanged: onChanged),
      ],
    );
  }
}

class _Orphans extends StatelessWidget {
  const _Orphans({required this.vm});
  final GridEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final target = vm.selectedSlot;
    final targetFree = target != null && vm.selectedAssignment == null && !vm.dirty;
    return Container(
      padding: const EdgeInsets.all(IcSpace.s12),
      decoration: BoxDecoration(
        color: IcColors.warningBg,
        borderRadius: BorderRadius.circular(IcRadius.md),
        border: Border.all(color: IcColors.warningAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.orphansTitle(vm.orphans.length), style: IcText.labelM),
          const SizedBox(height: 2),
          Text(l10n.orphanReassignHint, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
          const SizedBox(height: IcSpace.s8),
          for (final orphan in vm.orphans)
            Padding(
              padding: const EdgeInsets.only(top: IcSpace.s4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${vm.data.productName(orphan.productId)} · ${orphan.currentQuantity} / ${orphan.targetQuantity}',
                      style: IcText.bodyM,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IcButton(
                    label: l10n.actionReassign,
                    style: IcButtonStyle.secondary,
                    onPressed: targetFree
                        ? () async {
                            final result = await vm.reassignOrphan(orphan);
                            if (!context.mounted) return;
                            showResult(context, result);
                          }
                        : null,
                  ),
                  const SizedBox(width: IcSpace.s8),
                  IcButton(
                    label: l10n.actionRemove,
                    style: IcButtonStyle.ghost,
                    onPressed: () => _remove(context, orphan),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _remove(BuildContext context, CartProductAssignment orphan) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmAction(
      context,
      title: l10n.removeAssignmentTitle,
      message: l10n.removeAssignmentMessage,
      confirmLabel: l10n.actionRemove,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final result = await vm.removeOrphan(orphan);
    if (!context.mounted) return;
    showResult(context, result);
  }
}

/// Right panel "Posição C6": product, target, minimum, expiry warning.
class _PositionPanel extends StatefulWidget {
  const _PositionPanel({super.key, required this.vm});
  final GridEditorViewModel vm;

  @override
  State<_PositionPanel> createState() => _PositionPanelState();
}

class _PositionPanelState extends State<_PositionPanel> {
  Product? _product;
  int _target = 1;
  int _minimum = 0;
  int _expiryDays = 30;

  GridEditorViewModel get vm => widget.vm;

  @override
  void initState() {
    super.initState();
    final assignment = vm.selectedAssignment;
    _expiryDays = vm.session.institution.expiryWarningDays;
    if (assignment != null) {
      _product = vm.data.products[assignment.productId];
      _target = assignment.targetQuantity;
      _minimum = assignment.minimumQuantity ?? 0;
      _expiryDays = _product?.expiryWarningDays ?? _expiryDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slot = vm.selectedSlot;
    if (slot == null) {
      return Center(
        child: Text(
          vm.selected.length > 1 ? l10n.positionsSelected(vm.selected.length) : l10n.positionSelectHint,
          style: IcText.bodyM.copyWith(color: IcColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.positionTitle(slotPositionLabel(slot)), style: IcText.titleS),
          const SizedBox(height: IcSpace.s16),
          if (vm.dirty) ...[
            Notice(kind: NoticeKind.info, title: l10n.gridUnsavedHint),
            const SizedBox(height: IcSpace.s16),
          ],
          Text(l10n.productLabel, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
          const SizedBox(height: 6),
          SurfaceCard(
            elevated: false,
            padding: const EdgeInsets.symmetric(horizontal: IcSpace.s12, vertical: IcSpace.s12),
            onTap: () async {
              final picked = await _pickProduct(context, vm.catalog, vm.usedProductIds);
              if (picked == null) return;
              setState(() {
                _product = picked;
                _expiryDays = picked.expiryWarningDays ?? vm.session.institution.expiryWarningDays;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _product?.name ?? l10n.chooseProduct,
                    style: IcText.bodyM.copyWith(color: _product == null ? IcColors.textMuted : IcColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const IcIconView(IcIcon.pesquisar, size: 18, color: IcColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: IcSpace.s16),
          _StepperRow(label: l10n.targetQuantityLabel, value: _target, min: 1, onChanged: (v) => setState(() {
                _target = v;
                if (_minimum > v) _minimum = v;
              })),
          const SizedBox(height: IcSpace.s12),
          _StepperRow(label: l10n.minimumQuantityLabel, value: _minimum, max: _target, onChanged: (v) => setState(() => _minimum = v)),
          const SizedBox(height: IcSpace.s12),
          _StepperRow(label: l10n.expiryWarningDaysLabel, value: _expiryDays, min: 1, max: 365, onChanged: (v) => setState(() => _expiryDays = v)),
          const SizedBox(height: IcSpace.s12),
          // Always on in this version: replenishment always records lot and expiry.
          CheckRow(label: l10n.askLotOnReplenish, value: true, onChanged: null),
          const SizedBox(height: IcSpace.s20),
          IcButton(
            label: l10n.applyToPosition,
            icon: IcIcon.confirmar,
            size: IcButtonSize.l,
            busy: vm.busy,
            onPressed: _product == null || vm.dirty
                ? null
                : () async {
                    final result = await vm.apply(
                      product: _product!,
                      target: _target,
                      minimum: _minimum == 0 ? null : _minimum,
                      expiryWarningDays: _expiryDays,
                    );
                    if (context.mounted) showResult(context, result, success: l10n.positionApplied);
                  },
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({required this.label, required this.value, required this.onChanged, this.min = 0, this.max = 9999});
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: IcText.bodyM)),
        QuantityStepper(label: label, value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

/// Catalogue picker. Products already placed in another position of this
/// cart are shown but disabled (one position per product per cart).
Future<Product?> _pickProduct(BuildContext context, List<Product> catalog, Set<String> used) {
  final l10n = AppLocalizations.of(context);
  var query = '';
  return showDialog<Product>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final q = query.trim().toLowerCase();
        final list = q.isEmpty
            ? catalog
            : catalog.where((p) => p.name.toLowerCase().contains(q) || (p.gtin ?? '').contains(q)).toList();
        return AlertDialog(
          title: Text(l10n.chooseProduct),
          content: SizedBox(
            width: 480,
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchField(hint: l10n.catalogSearchHint, width: double.infinity, autofocus: true, onChanged: (v) => setState(() => query = v)),
                const SizedBox(height: IcSpace.s12),
                Expanded(
                  child: list.isEmpty
                      ? Center(child: Text(catalog.isEmpty ? l10n.noProductsMessage : l10n.catalogNoMatches, style: IcText.bodyM))
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: IcColors.borderDefault),
                          itemBuilder: (context, i) {
                            final p = list[i];
                            final taken = used.contains(p.id);
                            return ListTile(
                              enabled: !taken,
                              title: Text(p.name, style: IcText.bodyM),
                              subtitle: Text(
                                taken ? l10n.assignConflictError : [p.unitDescription, p.gtin].whereType<String>().join(' · '),
                                style: IcText.bodyS.copyWith(color: IcColors.textMuted),
                              ),
                              onTap: () => Navigator.of(context).pop(p),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop())],
        );
      },
    ),
  );
}
