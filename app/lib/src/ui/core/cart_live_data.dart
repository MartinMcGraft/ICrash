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

  /// The drawer's number as shown ("Gaveta N"): its stored [CartDrawer.number],
  /// or, for a drawer created before numbers were stored, its position in
  /// [drawers] (the old creation-order rule).
  int numberOf(CartDrawer drawer) => drawer.number ?? (drawers.indexWhere((d) => d.id == drawer.id) + 1);

  /// Numbers already used by the cart's drawers (as shown), for the
  /// "unique within its cart" check in B3.
  Set<int> get usedNumbers => {for (final d in drawers) numberOf(d)};

  /// Lowest number not used yet (the default in "Adicionar gaveta").
  int get nextFreeNumber {
    var n = 1;
    while (usedNumbers.contains(n)) {
      n++;
    }
    return n;
  }

  /// The drawer a placement is in. New placements store `drawerId`. An old
  /// one without it (slot ids repeat in every drawer) goes to the first
  /// drawer, in number order, that has a slot with its id, as before.
  String? drawerOf(CartProductAssignment assignment) {
    if (assignment.drawerId != null) return assignment.drawerId;
    for (final drawer in drawers) {
      if (slotsOf(drawer).any((s) => s.id == assignment.slotId)) return drawer.id;
    }
    return null;
  }

  /// Placements of one drawer, keyed by slot id.
  Map<String, CartProductAssignment> assignmentsIn(String drawerId) => {
        for (final a in assignments)
          if (drawerOf(a) == drawerId) a.slotId: a,
      };

  /// Saved slots. Every drawer created since 29 Oct 2026 has slot documents;
  /// an older drawer whose layout was never edited has none, and gets one
  /// slot per grid cell here (ids `r{row}c{col}`), as before.
  List<Slot> slotsOf(CartDrawer drawer) {
    final saved = _slots[drawer.id];
    if (saved != null && saved.isNotEmpty) return saved;
    return unitGrid(drawer);
  }

  bool slotsLoaded(String drawerId) => _slots.containsKey(drawerId);

  static List<Slot> unitGrid(CartDrawer drawer) => Slot.unitGrid(drawer.id, drawer.rows, drawer.columns);

  /// Which drawer + slot an assignment sits in, if any.
  (CartDrawer, Slot)? locate(CartProductAssignment assignment) {
    final drawerId = drawerOf(assignment);
    final drawer = drawers.where((d) => d.id == drawerId).firstOrNull;
    if (drawer == null) return null;
    final slot = slotsOf(drawer).where((s) => s.id == assignment.slotId).firstOrNull;
    return slot == null ? null : (drawer, slot);
  }

  DrawerHealth healthOf(CartDrawer drawer, {required int expiryWarningDays, DateTime? now}) => InventoryHealth.drawerHealth(
        drawer,
        slotsOf(drawer),
        assignmentsIn(drawer.id),
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
    // By number (P17); drawers without one (created before numbers were
    // stored) keep the old creation order, after the numbered ones.
    final sorted = List.of(list)
      ..sort((a, b) {
        final an = a.number, bn = b.number;
        if (an != null && bn != null && an != bn) return an.compareTo(bn);
        if (an != null && bn == null) return -1;
        if (an == null && bn != null) return 1;
        final byDate = (a.createdAt ?? DateTime(2000)).compareTo(b.createdAt ?? DateTime(2000));
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
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
