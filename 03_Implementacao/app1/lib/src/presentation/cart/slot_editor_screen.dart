import 'dart:math';

import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_drawer.dart';
import '../../domain/entities/cart_product_assignment.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/role.dart';
import '../../domain/entities/slot.dart';
import 'assignment_dialog.dart';
import 'bump_layout_version.dart';

/// Edits the rectangular slot layout of one [CartDrawer] (spec sections
/// 36-37): every cell starts as its own 1x1 slot; adjacent slots whose
/// combined footprint is itself a rectangle can be merged into one bigger
/// slot, and a merged slot can be split back into unit cells. Changes are
/// local until "Guardar" writes the full new slot set in one call.
class SlotEditorScreen extends StatefulWidget {
  const SlotEditorScreen({super.key, required this.cart, required this.drawer});

  final Cart cart;
  final CartDrawer drawer;

  @override
  State<SlotEditorScreen> createState() => _SlotEditorScreenState();
}

class _SlotEditorScreenState extends State<SlotEditorScreen> {
  late final Future<List<Slot>> _initialSlots = AppServicesScope.of(context)
      .drawers
      .watchSlots(widget.cart.institutionId, widget.cart.id, widget.drawer.id)
      .first;
  late final Future<Membership?> _myMembership =
      AppServicesScope.of(context).institutions.getMyMembership(widget.cart.institutionId);
  late final Stream<List<CartProductAssignment>> _assignments =
      AppServicesScope.of(context).inventory.watchAssignments(widget.cart.institutionId, widget.cart.id);
  late final Future<List<Product>> _products =
      AppServicesScope.of(context).products.watchProducts(widget.cart.institutionId).first;

  List<Slot>? _slots;
  Set<String> _selectedIds = {};
  bool _saving = false;

  List<Slot> _unitGrid() => [
        for (var r = 0; r < widget.drawer.rows; r++)
          for (var c = 0; c < widget.drawer.columns; c++) Slot(id: 'r${r}c$c', drawerId: widget.drawer.id, row: r, column: c),
      ];

  bool _canManage(Membership? membership) {
    if (membership == null || !membership.isActive) return false;
    return membership.role == Role.institutionAdmin ||
        membership.role == Role.manager ||
        membership.role == Role.platformSuperAdmin;
  }

  bool _selectionFormsRectangle(List<Slot> selected) {
    if (selected.length < 2) return false;
    final minRow = selected.map((s) => s.row).reduce(min);
    final maxRow = selected.map((s) => s.row + s.rowSpan).reduce(max);
    final minCol = selected.map((s) => s.column).reduce(min);
    final maxCol = selected.map((s) => s.column + s.columnSpan).reduce(max);
    final rectangleArea = (maxRow - minRow) * (maxCol - minCol);
    final selectedArea = selected.fold<int>(0, (sum, s) => sum + s.rowSpan * s.columnSpan);
    return rectangleArea == selectedArea;
  }

  void _toggleSelect(String slotId) {
    setState(() {
      final next = Set<String>.of(_selectedIds);
      if (!next.remove(slotId)) next.add(slotId);
      _selectedIds = next;
    });
  }

  void _merge() {
    final slots = _slots!;
    final selected = slots.where((s) => _selectedIds.contains(s.id)).toList();
    if (!_selectionFormsRectangle(selected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A seleção tem de formar um retângulo sem espaços.')),
      );
      return;
    }
    final minRow = selected.map((s) => s.row).reduce(min);
    final maxRow = selected.map((s) => s.row + s.rowSpan).reduce(max);
    final minCol = selected.map((s) => s.column).reduce(min);
    final maxCol = selected.map((s) => s.column + s.columnSpan).reduce(max);
    final merged = Slot(
      id: selected.first.id,
      drawerId: widget.drawer.id,
      row: minRow,
      column: minCol,
      rowSpan: maxRow - minRow,
      columnSpan: maxCol - minCol,
    );
    setState(() {
      _slots = [
        ...slots.where((s) => !_selectedIds.contains(s.id)),
        merged,
      ];
      _selectedIds = {merged.id};
    });
  }

  void _split() {
    final slot = _slots!.firstWhere((s) => s.id == _selectedIds.single);
    final unitCells = [
      for (var r = 0; r < slot.rowSpan; r++)
        for (var c = 0; c < slot.columnSpan; c++)
          Slot(id: 'r${slot.row + r}c${slot.column + c}', drawerId: widget.drawer.id, row: slot.row + r, column: slot.column + c),
    ];
    setState(() {
      _slots = [
        ..._slots!.where((s) => s.id != slot.id),
        ...unitCells,
      ];
      _selectedIds = {};
    });
  }

  Future<void> _save(BuildContext context) async {
    setState(() => _saving = true);
    final services = AppServicesScope.of(context);
    try {
      await services.drawers.replaceSlots(widget.cart.institutionId, widget.cart.id, widget.drawer.id, _slots!);
      await bumpCartLayoutVersion(services, widget.cart);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gaveta guardada.')));
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível guardar a gaveta. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.drawer.name),
        actions: [
          FutureBuilder<Membership?>(
            future: _myMembership,
            builder: (context, snapshot) {
              if (!_canManage(snapshot.data) || _slots == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Guardar',
                icon: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                onPressed: _saving ? null : () => _save(context),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Slot>>(
        future: _initialSlots,
        builder: (context, snapshot) {
          if (_slots == null) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Não foi possível carregar os slots: ${snapshot.error}'),
                ),
              );
            }
            final loaded = snapshot.data!;
            _slots = loaded.isEmpty ? _unitGrid() : loaded;
          }
          return _buildEditor(_slots!);
        },
      ),
    );
  }

  Future<void> _openAssignment(Slot slot, CartProductAssignment? assignment, List<Product> products, bool canManage) {
    return showAssignmentDialog(
      context,
      institutionId: widget.cart.institutionId,
      cartId: widget.cart.id,
      slot: slot,
      assignment: assignment,
      products: products,
      canManage: canManage,
    );
  }

  Widget _buildEditor(List<Slot> slots) {
    final selected = slots.where((s) => _selectedIds.contains(s.id)).toList();
    final canSplit = selected.length == 1 && (selected.single.rowSpan > 1 || selected.single.columnSpan > 1);
    return FutureBuilder<Membership?>(
      future: _myMembership,
      builder: (context, membershipSnapshot) {
        final canManage = _canManage(membershipSnapshot.data);
        return StreamBuilder<List<CartProductAssignment>>(
          stream: _assignments,
          builder: (context, assignmentsSnapshot) {
            final assignmentsBySlot = {
              for (final assignment in assignmentsSnapshot.data ?? const <CartProductAssignment>[])
                assignment.slotId: assignment,
            };
            return FutureBuilder<List<Product>>(
              future: _products,
              builder: (context, productsSnapshot) {
                final products = productsSnapshot.data ?? const <Product>[];
                return Column(
                  children: [
                    if (canManage)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _selectedIds.length >= 2 ? _merge : null,
                              icon: const Icon(Icons.call_merge),
                              label: const Text('Juntar'),
                            ),
                            FilledButton.icon(
                              onPressed: canSplit ? _split : null,
                              icon: const Icon(Icons.call_split),
                              label: const Text('Dividir'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // The drawer's whole footprint always fills the
                            // available space, split proportionally by
                            // rows/columns — a single slot takes the entire
                            // area, two slots split it in half, and so on,
                            // matching a real physical drawer's layout rather
                            // than a fixed-size scrollable grid.
                            final cellWidth = constraints.maxWidth / widget.drawer.columns;
                            final cellHeight = constraints.maxHeight / widget.drawer.rows;
                            return Stack(
                              children: [
                                for (final slot in slots)
                                  Positioned(
                                    left: slot.column * cellWidth,
                                    top: slot.row * cellHeight,
                                    width: slot.columnSpan * cellWidth,
                                    height: slot.rowSpan * cellHeight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: _SlotCell(
                                        slot: slot,
                                        assignment: assignmentsBySlot[slot.id],
                                        product: assignmentsBySlot[slot.id] == null
                                            ? null
                                            : _productFor(products, assignmentsBySlot[slot.id]!.productId),
                                        selected: _selectedIds.contains(slot.id),
                                        onTap: canManage ? () => _toggleSelect(slot.id) : null,
                                        onLongPress: () =>
                                            _openAssignment(slot, assignmentsBySlot[slot.id], products, canManage),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

Product? _productFor(List<Product> products, String productId) {
  for (final product in products) {
    if (product.id == productId) return product;
  }
  return null;
}

class _SlotCell extends StatelessWidget {
  const _SlotCell({
    required this.slot,
    required this.assignment,
    required this.product,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final Slot slot;
  final CartProductAssignment? assignment;
  final Product? product;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assignment = this.assignment;
    return Tooltip(
      message: 'Linha ${slot.row + 1}, coluna ${slot.column + 1}',
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected
              ? theme.colorScheme.primaryContainer
              : assignment == null
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.secondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(4),
            child: Center(
              child: assignment == null
                  ? Text(
                      slot.label ?? '${slot.row + 1},${slot.column + 1}',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    )
                  : Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product?.name ?? 'Produto removido',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${assignment.currentQuantity}/${assignment.targetQuantity}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
