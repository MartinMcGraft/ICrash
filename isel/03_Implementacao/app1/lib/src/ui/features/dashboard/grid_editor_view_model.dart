import 'dart:math';

import '../../../common/app_services.dart';
import '../../../domain/entities/cart_drawer.dart';
import '../../../domain/entities/cart_product_assignment.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/slot.dart';
import '../../../domain/inventory_health.dart';
import '../../core/cart_live_data.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/widgets/slot_grid.dart';

/// B4 · Editor de grelha — layout (rows/columns, merge, split) and slot
/// configuration (product, target, minimum, expiry warning).
class GridEditorViewModel extends ViewModel {
  GridEditorViewModel(this.services, this.session, {required this.cartId, required this.drawerId, String? initialSlotId}) {
    if (initialSlotId != null) selected = {initialSlotId};
    data = CartLiveData(services: services, institutionId: session.institution.id, cartId: cartId, onChanged: _onData);
  }

  final AppServices services;
  final SessionController session;
  final String cartId;
  final String drawerId;
  late final CartLiveData data;

  List<Slot>? _slots;
  int rows = 1;
  int columns = 1;
  Set<String> selected = {};
  bool dirty = false;

  CartDrawer? get drawer => data.drawers.where((d) => d.id == drawerId).firstOrNull;
  int get drawerNumber => data.drawers.indexWhere((d) => d.id == drawerId) + 1;
  bool get ready => _slots != null && data.ready;
  List<Slot> get slots => _slots ?? const [];

  void _onData() {
    final d = drawer;
    if (_slots == null && d != null && data.slotsLoaded(drawerId)) {
      _slots = List.of(data.slotsOf(d));
      rows = d.rows;
      columns = d.columns;
    }
    notify();
  }

  List<SlotCellData> get cells {
    final bySlot = data.assignmentsBySlot;
    final now = DateTime.now();
    return [
      for (final slot in slots)
        SlotCellData(
          slot: slot,
          position: slotPositionLabel(slot),
          health: InventoryHealth.slotHealth(bySlot[slot.id], expiryWarningDays: session.institution.expiryWarningDays, now: now),
          productName: bySlot[slot.id] == null ? null : data.productName(bySlot[slot.id]!.productId),
          current: bySlot[slot.id]?.currentQuantity,
          target: bySlot[slot.id]?.targetQuantity,
        ),
    ];
  }

  Slot? get selectedSlot => selected.length == 1 ? slots.where((s) => s.id == selected.single).firstOrNull : null;
  CartProductAssignment? get selectedAssignment => selectedSlot == null ? null : data.assignmentsBySlot[selectedSlot!.id];

  List<Product> get catalog => data.products.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  /// Products already used elsewhere in this cart (one slot per product).
  Set<String> get usedProductIds => {
        for (final a in data.assignments)
          if (a.slotId != selectedSlot?.id) a.productId,
      };

  /// Assignments whose slot no longer exists in any saved drawer layout.
  List<CartProductAssignment> get orphans {
    final ids = {for (final d in data.drawers) ...data.slotsOf(d).map((s) => s.id)};
    return data.assignments.where((a) => !ids.contains(a.slotId)).toList();
  }

  void toggle(String slotId) {
    final next = {...selected};
    if (!next.remove(slotId)) next.add(slotId);
    selected = next;
    notify();
  }

  void clearSelection() {
    selected = {};
    notify();
  }

  void selectOnly(String slotId) {
    selected = {slotId};
    notify();
  }

  bool get canSplit {
    final s = selectedSlot;
    return s != null && (s.rowSpan > 1 || s.columnSpan > 1);
  }

  bool get canMerge => selected.length >= 2 && _isRectangle(slots.where((s) => selected.contains(s.id)).toList());

  static bool _isRectangle(List<Slot> list) {
    if (list.length < 2) return false;
    final minRow = list.map((s) => s.row).reduce(min);
    final maxRow = list.map((s) => s.row + s.rowSpan).reduce(max);
    final minCol = list.map((s) => s.column).reduce(min);
    final maxCol = list.map((s) => s.column + s.columnSpan).reduce(max);
    final area = list.fold<int>(0, (sum, s) => sum + s.rowSpan * s.columnSpan);
    return (maxRow - minRow) * (maxCol - minCol) == area;
  }

  void merge() {
    final list = slots.where((s) => selected.contains(s.id)).toList();
    if (!_isRectangle(list)) return;
    final minRow = list.map((s) => s.row).reduce(min);
    final maxRow = list.map((s) => s.row + s.rowSpan).reduce(max);
    final minCol = list.map((s) => s.column).reduce(min);
    final maxCol = list.map((s) => s.column + s.columnSpan).reduce(max);
    // Keep the top-left slot's id so its assignment stays attached.
    final topLeft = list.firstWhere((s) => s.row == minRow && s.column == minCol);
    final merged = Slot(
      id: topLeft.id,
      drawerId: drawerId,
      row: minRow,
      column: minCol,
      rowSpan: maxRow - minRow,
      columnSpan: maxCol - minCol,
    );
    _slots = [...slots.where((s) => !selected.contains(s.id)), merged];
    selected = {merged.id};
    dirty = true;
    notify();
  }

  void split() {
    final s = selectedSlot;
    if (s == null) return;
    final next = slots.where((x) => x.id != s.id).toList();
    for (var r = 0; r < s.rowSpan; r++) {
      for (var c = 0; c < s.columnSpan; c++) {
        // The top-left part keeps the original id (and its assignment).
        final id = r == 0 && c == 0 ? s.id : _freeId(next, s.row + r, s.column + c);
        next.add(Slot(id: id, drawerId: drawerId, row: s.row + r, column: s.column + c));
      }
    }
    _slots = next;
    selected = {s.id};
    dirty = true;
    notify();
  }

  /// Resizes the grid: slots outside the new bounds go, new cells appear.
  void resize({int? newRows, int? newColumns}) {
    rows = (newRows ?? rows).clamp(1, 12);
    columns = (newColumns ?? columns).clamp(1, 12);
    final kept = slots.where((s) => s.row + s.rowSpan <= rows && s.column + s.columnSpan <= columns).toList();
    final covered = <String>{
      for (final s in kept)
        for (var r = s.row; r < s.row + s.rowSpan; r++)
          for (var c = s.column; c < s.column + s.columnSpan; c++) '$r:$c',
    };
    final next = List.of(kept);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        if (!covered.contains('$r:$c')) next.add(Slot(id: _freeId(next, r, c), drawerId: drawerId, row: r, column: c));
      }
    }
    _slots = next;
    selected = selected.where((id) => _slots!.any((s) => s.id == id)).toSet();
    dirty = true;
    notify();
  }

  /// `r{row}c{column}`, or a suffixed variant if a slot already uses it.
  static String _freeId(List<Slot> existing, int row, int column) {
    final taken = {for (final s in existing) s.id};
    final base = 'r${row}c$column';
    if (!taken.contains(base)) return base;
    var n = 2;
    while (taken.contains('${base}_$n')) {
      n++;
    }
    return '${base}_$n';
  }

  void cancelEdits() {
    final d = drawer;
    if (d == null) return;
    _slots = List.of(data.slotsOf(d));
    rows = d.rows;
    columns = d.columns;
    dirty = false;
    notify();
  }

  Future<ActionResult<void>> save() {
    final d = drawer;
    final cart = data.cart;
    final next = List.of(slots);
    return run(() async {
      if (d == null || cart == null) return;
      final institutionId = session.institution.id;
      if (d.rows != rows || d.columns != columns) {
        await services.drawers.updateDrawer(
          institutionId,
          cartId,
          CartDrawer(id: d.id, cartId: cartId, name: d.name, rows: rows, columns: columns),
        );
      }
      await services.drawers.replaceSlots(institutionId, cartId, drawerId, next);
      await services.carts.updateCart(institutionId, cart.copyWith(layoutVersion: cart.layoutVersion + 1));
      dirty = false;
    });
  }

  /// "Aplicar à posição".
  Future<ActionResult<void>> apply({
    required Product product,
    required int target,
    int? minimum,
    int? expiryWarningDays,
  }) {
    final slot = selectedSlot;
    final existing = selectedAssignment;
    return run(() async {
      if (slot == null) return;
      final institutionId = session.institution.id;
      if (existing != null && existing.productId == product.id) {
        await services.inventory.updateAssignmentSettings(
          institutionId: institutionId,
          cartId: cartId,
          assignmentId: existing.id,
          targetQuantity: target,
          minimumQuantity: minimum,
        );
      } else {
        if (existing != null) {
          await services.inventory.deleteAssignment(institutionId: institutionId, cartId: cartId, assignmentId: existing.id);
        }
        await services.inventory.createAssignment(
          institutionId,
          cartId,
          CartProductAssignment(
            id: '',
            cartId: cartId,
            slotId: slot.id,
            productId: product.id,
            currentQuantity: 0,
            targetQuantity: target,
            minimumQuantity: minimum,
          ),
        );
      }
      if (expiryWarningDays != null && expiryWarningDays != product.expiryWarningDays) {
        await services.products.updateProduct(institutionId, product.copyWith(expiryWarningDays: expiryWarningDays));
      }
    });
  }

  /// "Limpar posição": removes the product (and its lots) from the slot.
  Future<ActionResult<void>> clearPosition() {
    final existing = selectedAssignment;
    return run(() async {
      if (existing == null) return;
      await services.inventory.deleteAssignment(institutionId: session.institution.id, cartId: cartId, assignmentId: existing.id);
    });
  }

  Future<ActionResult<void>> reassignOrphan(CartProductAssignment orphan) {
    final slot = selectedSlot;
    return run(() async {
      if (slot == null) return;
      await services.inventory.reassignSlot(
        institutionId: session.institution.id,
        cartId: cartId,
        assignmentId: orphan.id,
        newSlotId: slot.id,
        actorUid: session.user.uid,
      );
    });
  }

  Future<ActionResult<void>> removeOrphan(CartProductAssignment orphan) => run(() => services.inventory
      .deleteAssignment(institutionId: session.institution.id, cartId: cartId, assignmentId: orphan.id));

  @override
  void dispose() {
    data.dispose();
    super.dispose();
  }
}
