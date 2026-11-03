import 'dart:async';

import '../../../common/app_services.dart';
import '../../../common/repository_failure.dart';
import '../../../domain/entities/batch.dart';
import '../../../domain/entities/cart_drawer.dart';
import '../../../domain/entities/cart_product_assignment.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/slot.dart';
import '../../../domain/entities/usage_event.dart';
import '../../../domain/inventory_health.dart';
import '../../../services/gs1_data_matrix_parser.dart';
import '../../core/cart_live_data.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/widgets/slot_grid.dart';

/// What the right-hand panel shows (design v2: A6 detail, A7 replenish).
enum DrawerPanel { detail, consume, replenish, correct, assign, reconcile }

/// A6 · Gaveta + A7 · Repor stock.
class DrawerViewModel extends ViewModel {
  DrawerViewModel(this.services, this.session, {required this.cartId, required this.drawerId, String? initialSlotId})
      : selectedSlotId = initialSlotId {
    data = CartLiveData(services: services, institutionId: session.institution.id, cartId: cartId, onChanged: _onData);
    session.addListener(notify);
  }

  final AppServices services;
  final SessionController session;
  final String cartId;
  final String drawerId;
  late final CartLiveData data;

  String? selectedSlotId;
  DrawerPanel panel = DrawerPanel.detail;

  /// Batches of the selected assignment (lot / expiry lines).
  List<Batch> batches = const [];
  StreamSubscription<List<Batch>>? _batchSub;
  String? _batchesFor;

  /// Events of the selected assignment (for "Corrigir").
  List<UsageEvent> events = const [];

  /// Replenish form values (A7), prefilled by a GS1 scan.
  String lot = '';
  DateTime? expiry;
  String? scannedGtin;
  int amount = 1;

  /// Warnings raised by a scan (shown once by the View, then cleared).
  String? scanWarningProduct;
  bool scanUnknownGtin = false;

  int get _warningDays => session.institution.expiryWarningDays;
  bool get ready => data.ready && drawer != null && data.slotsLoaded(drawerId);
  bool get drawerMissing => data.ready && data.drawersLoaded && drawer == null;

  CartDrawer? get drawer => data.drawers.where((d) => d.id == drawerId).firstOrNull;
  int get drawerNumber => data.drawers.indexWhere((d) => d.id == drawerId) + 1;
  List<Slot> get slots => drawer == null ? const [] : data.slotsOf(drawer!);

  List<SlotCellData> get cells {
    final bySlot = data.assignmentsBySlot;
    final now = DateTime.now();
    SlotCellData cell(Slot slot) {
      final a = bySlot[slot.id];
      return SlotCellData(
        slot: slot,
        position: slotPositionLabel(slot),
        health: InventoryHealth.slotHealth(a, expiryWarningDays: _warningDays, now: now),
        productName: a == null ? null : data.productName(a.productId),
        current: a?.currentQuantity,
        target: a?.targetQuantity,
      );
    }

    return [for (final slot in slots) cell(slot)];
  }

  Slot? get selectedSlot => slots.where((s) => s.id == selectedSlotId).firstOrNull;
  CartProductAssignment? get selectedAssignment => selectedSlotId == null ? null : data.assignmentsBySlot[selectedSlotId];
  Product? get selectedProduct => selectedAssignment == null ? null : data.products[selectedAssignment!.productId];
  SlotHealth get selectedHealth =>
      InventoryHealth.slotHealth(selectedAssignment, expiryWarningDays: _warningDays, now: DateTime.now());

  /// Products not yet in this cart (a product may only sit in one slot).
  List<Product> get assignableProducts {
    final used = data.assignments.map((a) => a.productId).toSet();
    return data.products.values.where((p) => !used.contains(p.id)).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  void _onData() {
    _ensureBatches();
    notify();
  }

  /// Closes the slot panel (design: the panel sits over the grid).
  void clearSelection() {
    selectedSlotId = null;
    panel = DrawerPanel.detail;
    notify();
  }

  void select(String slotId) {
    selectedSlotId = slotId;
    panel = DrawerPanel.detail;
    _ensureBatches();
    notify();
  }

  void showPanel(DrawerPanel next) {
    panel = next;
    final a = selectedAssignment;
    if (next == DrawerPanel.replenish && a != null) {
      amount = (a.targetQuantity - a.currentQuantity).clamp(1, 9999);
      if (scannedGtin == null) {
        lot = '';
        expiry = null;
      }
    } else if (next == DrawerPanel.consume) {
      amount = 1;
    } else if (next == DrawerPanel.correct) {
      unawaited(_loadEvents());
    } else if (next == DrawerPanel.assign) {
      amount = 1;
    }
    notify();
  }

  void cancelPanel() {
    panel = DrawerPanel.detail;
    scannedGtin = null;
    notify();
  }

  void setAmount(int value) {
    amount = value;
    notify();
  }

  void setLot(String value) => lot = value;

  void setExpiry(DateTime value) {
    expiry = value;
    notify();
  }

  void _ensureBatches() {
    final a = selectedAssignment;
    if (a?.id == _batchesFor) return;
    unawaited(_batchSub?.cancel());
    _batchesFor = a?.id;
    batches = const [];
    if (a == null) return;
    _batchSub = services.inventory.watchBatches(session.institution.id, cartId, a.id).listen((list) {
      batches = List.of(list)..sort((x, y) => x.expiryDate.compareTo(y.expiryDate));
      notify();
    }, onError: (_) {});
  }

  Future<void> _loadEvents() async {
    final a = selectedAssignment;
    if (a == null) return;
    try {
      events = await services.usage.watchEventsForAssignment(session.institution.id, a.id).first;
    } on RepositoryFailure {
      events = const [];
    }
    notify();
  }

  Future<ActionResult<void>> consume(int units) {
    final a = selectedAssignment;
    return run(() async {
      if (a == null) return;
      if (units > a.currentQuantity) throw const ActionError('exceeds');
      await services.sync.track(services.inventory.recordConsumption(
        institutionId: session.institution.id,
        cartId: cartId,
        assignmentId: a.id,
        amount: units,
        actorUid: session.user.uid,
      ));
      panel = DrawerPanel.detail;
    });
  }

  Future<ActionResult<void>> replenish() {
    final a = selectedAssignment;
    final lotValue = lot.trim();
    final expiryValue = expiry;
    return run(() async {
      if (a == null) return;
      if (lotValue.isEmpty) throw const ActionError('lotRequired');
      if (expiryValue == null) throw const ActionError('expiryRequired');
      await services.sync.track(services.inventory.recordReplenishment(
        institutionId: session.institution.id,
        cartId: cartId,
        assignmentId: a.id,
        amount: amount,
        batch: Batch(
          id: '',
          assignmentId: a.id,
          lotNumber: lotValue,
          expiryDate: expiryValue,
          quantity: amount,
          gtin: scannedGtin,
          source: scannedGtin == null ? BatchSource.manual : BatchSource.gs1DataMatrix,
        ),
        actorUid: session.user.uid,
      ));
      scannedGtin = null;
      panel = DrawerPanel.detail;
    });
  }

  Future<ActionResult<void>> correct(UsageEvent event, int adjustment) {
    final a = selectedAssignment;
    return run(() async {
      if (a == null) return;
      if (adjustment == 0) throw const ActionError('zero');
      await services.sync.track(services.inventory.recordCorrection(
        institutionId: session.institution.id,
        cartId: cartId,
        assignmentId: a.id,
        amount: adjustment,
        correctsEventId: event.id,
        actorUid: session.user.uid,
      ));
      panel = DrawerPanel.detail;
    });
  }

  /// Assigns a product to the selected free slot, or swaps the product of an
  /// assigned slot (the old assignment and its batches go; history stays).
  Future<ActionResult<void>> assign(Product product, {required int target, required int initial}) {
    final slotId = selectedSlotId;
    final existing = selectedAssignment;
    return run(() async {
      if (slotId == null) return;
      if (existing != null) {
        await services.inventory.deleteAssignment(
          institutionId: session.institution.id,
          cartId: cartId,
          assignmentId: existing.id,
        );
      }
      await services.inventory.createAssignment(
        session.institution.id,
        cartId,
        CartProductAssignment(
          id: '',
          cartId: cartId,
          slotId: slotId,
          productId: product.id,
          currentQuantity: initial,
          targetQuantity: target,
        ),
      );
      panel = DrawerPanel.detail;
    });
  }

  Future<ActionResult<void>> reconcile({required int confirmedQuantity, required Set<String> confirmedBatchIds}) {
    final a = selectedAssignment;
    final confirmed = batches.where((b) => confirmedBatchIds.contains(b.id)).toList();
    return run(() async {
      if (a == null) return;
      await services.sync.track(services.inventory.reconcileAfterAudit(
        institutionId: session.institution.id,
        cartId: cartId,
        assignmentId: a.id,
        confirmedQuantity: confirmedQuantity,
        confirmedBatches: confirmed,
        actorUid: session.user.uid,
      ));
      panel = DrawerPanel.detail;
    });
  }

  /// A GS1 / barcode scan from "Ler código": selects the slot holding that
  /// product and opens "Repor stock" with lot and expiry filled in.
  Future<void> applyScan(Gs1ParsedData parsed) async {
    scanWarningProduct = null;
    scanUnknownGtin = false;
    if (parsed.gtin != null) {
      final productId = data.products.values.where((p) => p.gtin == parsed.gtin).firstOrNull?.id;
      final assignment = productId == null ? null : data.assignments.where((a) => a.productId == productId).firstOrNull;
      final inThisDrawer = assignment != null && slots.any((s) => s.id == assignment.slotId);
      if (inThisDrawer) {
        selectedSlotId = assignment.slotId;
        _ensureBatches();
      } else if (productId == null) {
        scanUnknownGtin = true;
      } else if (selectedAssignment != null && selectedAssignment!.productId != productId) {
        scanWarningProduct = data.productName(productId);
      }
    }
    scannedGtin = parsed.gtin;
    if (parsed.lotNumber != null) lot = parsed.lotNumber!;
    if (parsed.expiryDate != null) expiry = parsed.expiryDate;
    if (selectedAssignment != null && session.canReplenish) {
      panel = DrawerPanel.replenish;
      amount = (selectedAssignment!.targetQuantity - selectedAssignment!.currentQuantity).clamp(1, 9999);
    }
    notify();
  }

  void clearScanWarnings() {
    scanWarningProduct = null;
    scanUnknownGtin = false;
  }

  @override
  void dispose() {
    session.removeListener(notify);
    unawaited(_batchSub?.cancel());
    data.dispose();
    super.dispose();
  }
}
