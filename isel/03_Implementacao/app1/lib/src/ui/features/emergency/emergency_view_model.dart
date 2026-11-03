import 'dart:async';

import '../../../common/app_services.dart';
import '../../../common/repository_failure.dart';
import '../../../domain/entities/cart_drawer.dart';
import '../../../domain/entities/cart_report.dart';
import '../../../domain/entities/cart_status.dart';
import '../../../domain/entities/emergency_session.dart';
import '../../../domain/entities/usage_event.dart';
import '../../../domain/inventory_health.dart';
import '../../core/cart_live_data.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/widgets/slot_grid.dart';

/// A10 · Modo de emergência (proposal §9: consumption only; tap = −1 unit;
/// ending it sets the cart to "Reposição necessária" and creates a summary).
class EmergencyViewModel extends ViewModel {
  EmergencyViewModel(this.services, this.session, this.cartId) {
    data = CartLiveData(services: services, institutionId: session.institution.id, cartId: cartId, onChanged: notify);
    session.addListener(notify);
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => notify());
  }

  final AppServices services;
  final SessionController session;
  final String cartId;
  late final CartLiveData data;
  late final Timer _ticker;

  int drawerIndex = 0;

  /// Consumptions that could not be written to the server (e.g. offline:
  /// consumption still uses a Firestore transaction — audit §3.1). They stay
  /// in the local emergency log and the summary report.
  int failedWrites = 0;

  void _failed(Object _) {
    failedWrites++;
    notify();
  }

  EmergencySession? get emergency => session.emergencyFor(cartId);
  bool get ready => data.ready;
  List<CartDrawer> get drawers => data.drawers;
  CartDrawer? get drawer => drawerIndex < drawers.length ? drawers[drawerIndex] : null;

  void selectDrawer(int index) {
    drawerIndex = index;
    notify();
  }

  /// Only positions with a product, in drawer order (fast to scan).
  List<SlotCellData> get cells {
    final d = drawer;
    if (d == null) return const [];
    final bySlot = data.assignmentsBySlot;
    final now = DateTime.now();
    return [
      for (final slot in data.slotsOf(d))
        if (bySlot[slot.id] case final a?)
          SlotCellData(
            slot: slot,
            position: slotPositionLabel(slot),
            health: InventoryHealth.slotHealth(a, expiryWarningDays: session.institution.expiryWarningDays, now: now),
            productName: data.productName(a.productId),
            current: a.currentQuantity,
            target: a.targetQuantity,
          ),
    ];
  }

  /// Error code `empty` when there is nothing left to take.
  Future<ActionResult<void>> consume(SlotCellData cell, int units) {
    final a = data.assignmentsBySlot[cell.slot.id];
    return run(() async {
      if (a == null) return;
      if (a.currentQuantity < units || units <= 0) throw const ActionError('empty');
      await services.emergency.addConsumption(
        session.institution.id,
        cartId,
        EmergencyConsumption(
          assignmentId: a.id,
          productId: a.productId,
          productName: data.productName(a.productId),
          amount: units,
          at: DateTime.now(),
        ),
      );
      // Not awaited on purpose: offline, Firestore only completes the write
      // when the server acknowledges it; the sync indicator shows it pending.
      unawaited(services.sync
          .track(services.inventory.recordConsumption(
            institutionId: session.institution.id,
            cartId: cartId,
            assignmentId: a.id,
            amount: units,
            actorUid: session.user.uid,
          ))
          .catchError(_failed));
    });
  }

  /// "Desfazer último": removes the last line and records a compensating
  /// correction (history stays immutable).
  Future<ActionResult<void>> undoLast() => run(() async {
        final removed = await services.emergency.removeLast(session.institution.id, cartId);
        if (removed == null) return;
        List<UsageEvent> events;
        try {
          events = await services.usage.watchEventsForAssignment(session.institution.id, removed.assignmentId).first;
        } on RepositoryFailure {
          events = const [];
        }
        final original = events
            .where((e) => e.type == UsageEventType.consumption && e.actorUid == session.user.uid && e.amount == -removed.amount)
            .firstOrNull;
        if (original == null) return;
        unawaited(services.sync
            .track(services.inventory.recordCorrection(
              institutionId: session.institution.id,
              cartId: cartId,
              assignmentId: removed.assignmentId,
              amount: removed.amount,
              correctsEventId: original.id,
              actorUid: session.user.uid,
            ))
            .catchError((Object _) {}));
      });

  /// Ends the session, sets the cart to "Reposição necessária" (when the
  /// role may) and creates the summary report. Returns the report id.
  Future<ActionResult<String?>> end() => run(() async {
        final ended = await services.emergency.end(session.institution.id, cartId);
        if (ended == null) return null;
        final cart = data.cart;
        if (cart != null && session.isManager && ended.consumptions.isNotEmpty) {
          unawaited(services.sync
              .track(services.carts.updateCart(session.institution.id, cart.copyWith(status: CartStatus.replenishmentRequired)))
              .catchError((Object _) {}));
        }
        final report = await services.reports.createReport(CartReport(
          id: '',
          institutionId: session.institution.id,
          cartId: cartId,
          cartName: ended.cartName,
          kind: ReportKind.emergencySummary,
          status: ReportStatus.pendingSignature,
          createdAt: DateTime.now(),
          createdByUid: ended.startedByUid,
          createdByName: ended.startedByName,
          periodStart: ended.startedAt,
          periodEnd: DateTime.now(),
          lines: [for (final (_, name, amount) in ended.totalsByProduct()) ReportLine(productName: name, amount: amount)],
        ));
        return report.id;
      });

  @override
  void dispose() {
    _ticker.cancel();
    session.removeListener(notify);
    data.dispose();
    super.dispose();
  }
}
