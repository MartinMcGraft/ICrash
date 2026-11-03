import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../common/app_services.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_drawer.dart';
import '../../domain/entities/cart_product_assignment.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/slot.dart';
import '../../domain/inventory_health.dart';

/// Live view of one cart (cart, drawers, slots, assignments, products) that
/// several ViewModels compose: A5 cart, A6/A7 drawer, A8 monthly check,
/// A10 emergency, B3 configuration, B4 grid editor.
class CartLiveData {
  CartLiveData({
    required this.services,
    required this.institutionId,
    required this.cartId,
    required this.onChanged,
  }) {
    unawaited(_loadCart());
    _subs.add(services.carts.watchAccessibleCarts(institutionId).listen((carts) {
      final match = carts.where((c) => c.id == cartId).firstOrNull;
      if (match != null) {
        cart = match;
        _changed();
      }
    }, onError: (_) {}));
    _subs.add(services.drawers.watchDrawers(institutionId, cartId).listen(_onDrawers, onError: _onError));
    _subs.add(services.inventory.watchAssignments(institutionId, cartId).listen((list) {
      assignments = list;
      assignmentsLoaded = true;
      _changed();
    }, onError: _onError));
    _subs.add(services.products.watchProducts(institutionId).listen((list) {
      products = {for (final p in list) p.id: p};
      _changed();
    }, onError: (_) {}));
  }

  final AppServices services;
  final String institutionId;
  final String cartId;
  final VoidCallback onChanged;

  Cart? cart;
  bool cartMissing = false;
  List<CartDrawer> drawers = const [];
  bool drawersLoaded = false;
  final Map<String, List<Slot>> _slots = {};
  List<CartProductAssignment> assignments = const [];
  bool assignmentsLoaded = false;
  Map<String, Product> products = const {};
  Object? error;

  final List<StreamSubscription<Object?>> _subs = [];
  final Map<String, StreamSubscription<List<Slot>>> _slotSubs = {};
  bool _disposed = false;

  bool get ready => cart != null && drawersLoaded && assignmentsLoaded;

  Map<String, CartProductAssignment> get assignmentsBySlot => {for (final a in assignments) a.slotId: a};

  /// Saved slots, or one slot per grid cell when the drawer layout was never
  /// edited (ids `r{row}c{col}`, the convention of the original editor).
  List<Slot> slotsOf(CartDrawer drawer) {
    final saved = _slots[drawer.id];
    if (saved != null && saved.isNotEmpty) return saved;
    return unitGrid(drawer);
  }

  bool slotsLoaded(String drawerId) => _slots.containsKey(drawerId);

  static List<Slot> unitGrid(CartDrawer drawer) => [
        for (var r = 0; r < drawer.rows; r++)
          for (var c = 0; c < drawer.columns; c++) Slot(id: 'r${r}c$c', drawerId: drawer.id, row: r, column: c),
      ];

  /// Which drawer + slot an assignment sits in, if any.
  (CartDrawer, Slot)? locate(String slotId) {
    for (final drawer in drawers) {
      for (final slot in slotsOf(drawer)) {
        if (slot.id == slotId) return (drawer, slot);
      }
    }
    return null;
  }

  DrawerHealth healthOf(CartDrawer drawer, {required int expiryWarningDays, DateTime? now}) => InventoryHealth.drawerHealth(
        drawer,
        slotsOf(drawer),
        assignmentsBySlot,
        expiryWarningDays: expiryWarningDays,
        now: now ?? DateTime.now(),
      );

  HealthCounts cartCounts({required int expiryWarningDays, DateTime? now}) =>
      InventoryHealth.count(assignments, expiryWarningDays: expiryWarningDays, now: now ?? DateTime.now());

  String productName(String productId, {String removed = '—'}) => products[productId]?.name ?? removed;

  Future<void> _loadCart() async {
    try {
      final loaded = await services.carts.getCart(institutionId, cartId);
      if (_disposed) return;
      if (loaded == null) {
        cartMissing = true;
      } else {
        cart ??= loaded;
      }
    } catch (e) {
      error = e;
    }
    _changed();
  }

  void _onDrawers(List<CartDrawer> list) {
    final sorted = List.of(list)
      ..sort((a, b) {
        final byDate = (a.createdAt ?? DateTime(2000)).compareTo(b.createdAt ?? DateTime(2000));
        return byDate != 0 ? byDate : a.name.compareTo(b.name);
      });
    drawers = sorted;
    drawersLoaded = true;
    final ids = sorted.map((d) => d.id).toSet();
    for (final removed in _slotSubs.keys.where((id) => !ids.contains(id)).toList()) {
      unawaited(_slotSubs.remove(removed)!.cancel());
      _slots.remove(removed);
    }
    for (final drawer in sorted) {
      _slotSubs.putIfAbsent(
        drawer.id,
        () => services.drawers.watchSlots(institutionId, cartId, drawer.id).listen((slots) {
          _slots[drawer.id] = slots;
          _changed();
        }, onError: (_) {}),
      );
    }
    _changed();
  }

  void _onError(Object e) {
    error = e;
    _changed();
  }

  void _changed() {
    if (!_disposed) onChanged();
  }

  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    for (final s in _slotSubs.values) {
      unawaited(s.cancel());
    }
  }
}
