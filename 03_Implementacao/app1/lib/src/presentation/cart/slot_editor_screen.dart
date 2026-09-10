import 'dart:math';

import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/l10n/app_localizations.dart';
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

/// Minimum touch-target side, in logical pixels, for a slot cell — below the
/// WCAG 2.1 (2.5.5) / Material recommended 44-48dp minimum, a densely
/// configured drawer would otherwise shrink cells proportionally to fit the
/// available space with no floor, making them unreliably tappable.
const double _minSlotCellExtent = 48;

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
  late final Future<Membership?> _myMembership = AppServicesScope.of(context)
      .institutions
      .getMyMembership(widget.cart.institutionId);
  late final Stream<List<CartProductAssignment>> _assignments =
      AppServicesScope.of(context).inventory
          .watchAssignments(widget.cart.institutionId, widget.cart.id);
  late final Future<List<Product>> _products = AppServicesScope.of(context)
      .products
      .watchProducts(widget.cart.institutionId)
      .first;

  List<Slot>? _slots;
  Set<String> _selectedIds = {};
  bool _saving = false;

  /// Every slot id that currently exists anywhere in this cart, across every
  /// drawer — used to detect an assignment whose `slotId` was left behind by
  /// a merge/split (spec sections 36-37): the id it points to no longer
  /// exists in any drawer, not just this one, since ids are only unique
  /// within their own drawer's grid.
  late Future<Set<String>> _allCartSlotIds = _loadAllCartSlotIds();

  Future<Set<String>> _loadAllCartSlotIds() async {
    final services = AppServicesScope.of(context);
    final drawers = await services.drawers
        .watchDrawers(widget.cart.institutionId, widget.cart.id)
        .first;
    final ids = <String>{};
    for (final drawer in drawers) {
      final slots = await services.drawers
          .watchSlots(widget.cart.institutionId, widget.cart.id, drawer.id)
          .first;
      ids.addAll(slots.map((s) => s.id));
    }
    return ids;
  }

  void _refreshAllCartSlotIds() {
    final next = _loadAllCartSlotIds();
    setState(() {
      _allCartSlotIds = next;
    });
  }

  List<Slot> _unitGrid() => [
    for (var r = 0; r < widget.drawer.rows; r++)
      for (var c = 0; c < widget.drawer.columns; c++)
        Slot(id: 'r${r}c$c', drawerId: widget.drawer.id, row: r, column: c),
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
    final selectedArea = selected.fold<int>(
      0,
      (sum, s) => sum + s.rowSpan * s.columnSpan,
    );
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
        SnackBar(
          content: Text(AppLocalizations.of(context).slotSelectionNotRectangle),
        ),
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
      _slots = [...slots.where((s) => !_selectedIds.contains(s.id)), merged];
      _selectedIds = {merged.id};
    });
  }

  void _split() {
    final slot = _slots!.firstWhere((s) => s.id == _selectedIds.single);
    final unitCells = [
      for (var r = 0; r < slot.rowSpan; r++)
        for (var c = 0; c < slot.columnSpan; c++)
          Slot(
            id: 'r${slot.row + r}c${slot.column + c}',
            drawerId: widget.drawer.id,
            row: slot.row + r,
            column: slot.column + c,
          ),
    ];
    setState(() {
      _slots = [..._slots!.where((s) => s.id != slot.id), ...unitCells];
      _selectedIds = {};
    });
  }

  Future<void> _save(BuildContext context) async {
    setState(() => _saving = true);
    final services = AppServicesScope.of(context);
    try {
      await services.drawers.replaceSlots(
        widget.cart.institutionId,
        widget.cart.id,
        widget.drawer.id,
        _slots!,
      );
      await bumpCartLayoutVersion(services, widget.cart);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).drawerSavedMessage),
        ),
      );
      _refreshAllCartSlotIds();
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).drawerSaveError)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reassignOrphan(
    CartProductAssignment assignment,
    Slot newSlot,
  ) async {
    final services = AppServicesScope.of(context);
    try {
      await services.inventory.reassignSlot(
        institutionId: widget.cart.institutionId,
        cartId: widget.cart.id,
        assignmentId: assignment.id,
        newSlotId: newSlot.id,
        actorUid: services.auth.currentUser!.uid,
      );
      if (!mounted) return;
      _refreshAllCartSlotIds();
    } on RepositoryFailure catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).reassignSlotError)),
      );
    }
  }

  Future<void> _deleteOrphan(
    BuildContext context,
    CartProductAssignment assignment,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeAssignmentTitle),
        content: Text(l10n.removeAssignmentMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final services = AppServicesScope.of(context);
    try {
      await services.inventory.deleteAssignment(
        institutionId: widget.cart.institutionId,
        cartId: widget.cart.id,
        assignmentId: assignment.id,
      );
      if (!mounted) return;
      _refreshAllCartSlotIds();
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.deleteAssignmentError)));
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
              if (!_canManage(snapshot.data) || _slots == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: AppLocalizations.of(context).actionSave,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
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
                  child: Text(
                    AppLocalizations.of(context)
                        .loadSlotsError(snapshot.error!),
                  ),
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

  Future<void> _openAssignment(
    Slot slot,
    CartProductAssignment? assignment,
    List<Product> products,
    bool canManage,
  ) {
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
    final canSplit =
        selected.length == 1 &&
        (selected.single.rowSpan > 1 || selected.single.columnSpan > 1);
    return FutureBuilder<Membership?>(
      future: _myMembership,
      builder: (context, membershipSnapshot) {
        final canManage = _canManage(membershipSnapshot.data);
        return StreamBuilder<List<CartProductAssignment>>(
          stream: _assignments,
          builder: (context, assignmentsSnapshot) {
            final assignmentsBySlot = {
              for (final assignment
                  in assignmentsSnapshot.data ??
                      const <CartProductAssignment>[])
                assignment.slotId: assignment,
            };
            final currentSlotIds = slots.map((s) => s.id).toSet();
            final emptySlots = slots
                .where((s) => assignmentsBySlot[s.id] == null)
                .toList();
            return FutureBuilder<List<Product>>(
              future: _products,
              builder: (context, productsSnapshot) {
                final products = productsSnapshot.data ?? const <Product>[];
                return FutureBuilder<Set<String>>(
                  future: _allCartSlotIds,
                  builder: (context, allSlotIdsSnapshot) {
                    final allCartSlotIds = allSlotIdsSnapshot.data;
                    // Orphaned strictly within this drawer's own slots: the
                    // assignment's slotId isn't one of this drawer's current
                    // cells *and* doesn't exist in any other drawer of the
                    // cart either, so it can't legitimately belong elsewhere.
                    final orphaned = allCartSlotIds == null
                        ? const <CartProductAssignment>[]
                        : (assignmentsSnapshot.data ??
                                  const <CartProductAssignment>[])
                              .where(
                                (a) =>
                                    !currentSlotIds.contains(a.slotId) &&
                                    !allCartSlotIds.contains(a.slotId),
                              )
                              .toList();
                    return Column(
                      children: [
                        if (canManage && orphaned.isNotEmpty)
                          _OrphanedAssignmentsBanner(
                            orphaned: orphaned,
                            products: products,
                            emptySlots: emptySlots,
                            onReassign: _reassignOrphan,
                            onDelete: (assignment) =>
                                _deleteOrphan(context, assignment),
                          ),
                        if (canManage)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: _selectedIds.length >= 2
                                      ? _merge
                                      : null,
                                  icon: const Icon(Icons.call_merge),
                                  label: Text(
                                    AppLocalizations.of(context).actionMerge,
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: canSplit ? _split : null,
                                  icon: const Icon(Icons.call_split),
                                  label: Text(
                                    AppLocalizations.of(context).actionSplit,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // The drawer's whole footprint fills the
                                // available space, split proportionally by
                                // rows/columns — a single slot takes the
                                // entire area, two slots split it in half,
                                // and so on, matching a real physical
                                // drawer's layout — but never below
                                // `_minSlotCellExtent`: a dense drawer scrolls
                                // instead of shrinking cells past a reliably
                                // tappable size.
                                final idealCellWidth =
                                    constraints.maxWidth /
                                    widget.drawer.columns;
                                final idealCellHeight =
                                    constraints.maxHeight / widget.drawer.rows;
                                final cellWidth = max(
                                  idealCellWidth,
                                  _minSlotCellExtent,
                                );
                                final cellHeight = max(
                                  idealCellHeight,
                                  _minSlotCellExtent,
                                );
                                final grid = SizedBox(
                                  width: cellWidth * widget.drawer.columns,
                                  height: cellHeight * widget.drawer.rows,
                                  child: Stack(
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
                                              assignment:
                                                  assignmentsBySlot[slot.id],
                                              product:
                                                  assignmentsBySlot[slot.id] ==
                                                      null
                                                  ? null
                                                  : _productFor(
                                                      products,
                                                      assignmentsBySlot[slot
                                                              .id]!
                                                          .productId,
                                                    ),
                                              selected: _selectedIds.contains(
                                                slot.id,
                                              ),
                                              onTap: canManage
                                                  ? () => _toggleSelect(slot.id)
                                                  : null,
                                              onLongPress: () =>
                                                  _openAssignment(
                                                    slot,
                                                    assignmentsBySlot[slot.id],
                                                    products,
                                                    canManage,
                                                  ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                                if (idealCellWidth >= _minSlotCellExtent &&
                                    idealCellHeight >= _minSlotCellExtent) {
                                  return grid;
                                }
                                return Scrollbar(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(child: grid),
                                  ),
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

/// Warns a manager about assignments left behind by a past merge/split whose
/// slot no longer exists anywhere in the cart, and lets them either move the
/// assignment onto a currently-empty slot in this drawer or delete it.
class _OrphanedAssignmentsBanner extends StatelessWidget {
  const _OrphanedAssignmentsBanner({
    required this.orphaned,
    required this.products,
    required this.emptySlots,
    required this.onReassign,
    required this.onDelete,
  });

  final List<CartProductAssignment> orphaned;
  final List<Product> products;
  final List<Slot> emptySlots;
  final void Function(CartProductAssignment assignment, Slot newSlot)
  onReassign;
  final void Function(CartProductAssignment assignment) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orphanedAssignmentsHeader,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          for (final assignment in orphaned)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    _productFor(products, assignment.productId)?.name ??
                        l10n.productRemoved,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                  if (emptySlots.isNotEmpty)
                    PopupMenuButton<Slot>(
                      tooltip: l10n.reassignTooltip,
                      onSelected: (slot) => onReassign(assignment, slot),
                      itemBuilder: (context) => [
                        for (final slot in emptySlots)
                          PopupMenuItem(
                            value: slot,
                            child: Text(
                              slot.label ??
                                  '${slot.row + 1},${slot.column + 1}',
                            ),
                          ),
                      ],
                      child: Chip(
                        avatar: const Icon(Icons.swap_horiz, size: 18),
                        label: Text(l10n.actionReassign),
                      ),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.delete_outline, size: 18),
                    label: Text(l10n.actionRemove),
                    onPressed: () => onDelete(assignment),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
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
      message: AppLocalizations.of(context)
          .slotPositionTooltip(slot.row + 1, slot.column + 1),
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
            side: BorderSide(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
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
                            product?.name ??
                                AppLocalizations.of(context).productRemoved,
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
