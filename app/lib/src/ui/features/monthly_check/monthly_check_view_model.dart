import 'dart:async';

import '../../../common/app_services.dart';
import '../../../domain/entities/batch.dart';
import '../../../domain/entities/cart_drawer.dart';
import '../../../domain/entities/cart_product_assignment.dart';
import '../../../domain/entities/cart_report.dart';
import '../../../domain/inventory_health.dart';
import '../../../domain/monthly_check.dart';
import '../../core/cart_live_data.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

/// A8 · Verificação mensal, "Gestão mensal" (D4, D22, D23; 30 Oct 2026).
///
/// Lists only the cart's expired and expiring lots, one drawer at a time
/// (a step). Each lot gets an outcome from [checkOutcomes]; "Substituído" and
/// "Retirado sem reposição" change the stock as soon as they're confirmed.
/// Every answer is saved at once (the draft), so leaving never loses work and
/// the cart menu offers "Retomar verificação". [back] goes to the previous
/// step. The report (A9) can be created once every lot has an outcome.
class MonthlyCheckViewModel extends ViewModel {
  MonthlyCheckViewModel(this.services, this.session, this.cartId) {
    data = CartLiveData(services: services, institutionId: session.institution.id, cartId: cartId, onChanged: _onData);
  }

  final AppServices services;
  final SessionController session;
  final String cartId;
  late final CartLiveData data;

  /// The lots to handle, in drawer then position order. Built once, when the
  /// cart is loaded, so answered lots stay listed after a stock change.
  List<CheckItem> items = const [];

  /// Index into [steps].
  int step = 0;
  String notes = '';

  bool _loading = false;
  bool _loaded = false;

  bool get ready => _loaded;

  /// The drawers that have something to handle, in number order.
  List<CartDrawer> get steps {
    final ids = items.map((i) => i.drawerId).toSet();
    return [for (final d in data.drawers) if (ids.contains(d.id)) d];
  }

  CartDrawer? get stepDrawer => step < steps.length ? steps[step] : null;
  bool get isLastStep => step >= steps.length - 1;
  List<CheckItem> get stepItems {
    final drawer = stepDrawer;
    return drawer == null ? const [] : items.where((i) => i.drawerId == drawer.id).toList();
  }

  bool get stepDone => stepItems.every((i) => i.answered);
  int get answeredCount => items.where((i) => i.answered).length;
  bool get canFinish => items.every((i) => i.answered);

  void _onData() {
    if (!_loaded && !_loading && data.ready && data.drawers.every((d) => data.slotsLoaded(d.id))) {
      unawaited(_load());
    }
    notify();
  }

  int _warningDays(String productId) =>
      data.products[productId]?.expiryWarningDays ?? session.institution.expiryWarningDays;

  String _positionOf(CartProductAssignment assignment) {
    final drawerId = data.drawerOf(assignment);
    final drawer = data.drawers.where((d) => d.id == drawerId).firstOrNull;
    final slot = drawer == null ? null : data.slotsOf(drawer).where((s) => s.id == assignment.slotId).firstOrNull;
    return slot == null ? assignment.slotId : slotPositionLabel(slot);
  }

  Future<void> _load() async {
    _loading = true;
    final institutionId = session.institution.id;
    final batches = <String, List<Batch>>{};
    for (final a in data.assignments) {
      try {
        batches[a.id] = await services.inventory.watchBatches(institutionId, cartId, a.id).first;
      } catch (_) {
        batches[a.id] = const [];
      }
    }
    if (isDisposed) return;
    var built = buildCheckItems(
      drawers: data.drawers,
      numberOf: data.numberOf,
      assignments: data.assignments,
      drawerIdOf: data.drawerOf,
      positionOf: _positionOf,
      productName: data.productName,
      warningDaysOf: _warningDays,
      batchesByAssignment: batches,
      now: DateTime.now(),
    );
    final draft = await services.reports.loadCheckDraft(institutionId, cartId);
    if (isDisposed) return;
    // Drafts from the old drawer-by-drawer check (no version) are ignored.
    if (draft != null && draft['version'] == 2) {
      final answers = draft['answers'];
      if (answers is Map) {
        built = mergeSavedAnswers(built, {
          for (final e in answers.entries)
            if (e.value is Map) '${e.key}': (e.value as Map).cast<String, Object?>(),
        });
      }
      notes = draft['notes'] as String? ?? '';
      step = (draft['step'] as num?)?.toInt() ?? 0;
    }
    items = built;
    if (step >= steps.length) step = steps.isEmpty ? 0 : steps.length - 1;
    _loaded = true;
    _loading = false;
    notify();
  }

  /// Saves the draft (every answer, the step and the note) on this device.
  Future<void> _save() => services.reports.saveCheckDraft(session.institution.id, cartId, {
        'version': 2,
        'step': step,
        'notes': notes,
        'answers': {
          for (final item in items)
            if (item.answered) item.id: item.toJson(),
        },
      });

  void _replace(CheckItem item) {
    items = [for (final i in items) i.id == item.id ? item : i];
    notify();
  }

  /// "Mantido" (expiring lots only), or clears that answer. No stock change,
  /// so it can be changed until the report is created.
  Future<void> setKept(CheckItem item, bool kept) async {
    if (item.locked || !checkOutcomes[item.issue]!.contains(CheckOutcome.kept)) return;
    _replace(item.answer(kept ? CheckOutcome.kept : null));
    await _save();
  }

  /// "Substituído": [units] of the lot are replaced by new ones expiring on
  /// [newExpiry] (later than the old date and not expired). The old lot is
  /// marked removed and the new one added; the quantity stays the same.
  /// Codes `newExpiryRequired`, `newExpiryNotLater`, `quantityRequired`.
  Future<ActionResult<void>> replace(CheckItem item, {required int units, required DateTime? newExpiry, String? newLot}) {
    return run(() async {
      if (item.locked) return;
      if (newExpiry == null) throw const ActionError('newExpiryRequired');
      final today = DateTime.now();
      if (!newExpiry.isAfter(item.expiryDate) || newExpiry.isBefore(DateTime(today.year, today.month, today.day))) {
        throw const ActionError('newExpiryNotLater');
      }
      final lot = newLot?.trim();
      final n = await _takeOut(item, units);
      await services.sync.track(services.inventory.recordReplenishment(
        institutionId: session.institution.id,
        cartId: cartId,
        assignmentId: item.assignmentId,
        amount: n,
        batch: Batch(
          id: '',
          assignmentId: item.assignmentId,
          lotNumber: lot == null || lot.isEmpty ? null : lot,
          expiryDate: newExpiry,
          quantity: n,
        ),
        actorUid: session.user.uid,
      ));
      _replace(item.answer(CheckOutcome.replaced, units: n, newExpiry: newExpiry, newLot: lot == null || lot.isEmpty ? null : lot));
      await _save();
    });
  }

  /// "Retirado sem reposição": [units] of the lot leave the cart and nothing
  /// replaces them. Code `quantityRequired`.
  Future<ActionResult<void>> remove(CheckItem item, {required int units}) {
    return run(() async {
      if (item.locked) return;
      final n = await _takeOut(item, units);
      _replace(item.answer(CheckOutcome.removed, units: n));
      await _save();
    });
  }

  /// Marks the lot removed and lowers the stock by [units] (at most the
  /// current stock) in one write; returns the units taken out.
  Future<int> _takeOut(CheckItem item, int units) async {
    final institutionId = session.institution.id;
    final assignment = await services.inventory.getAssignment(institutionId, cartId, item.assignmentId);
    if (assignment == null) throw const ActionError('notFound');
    final n = units > assignment.currentQuantity ? assignment.currentQuantity : units;
    if (n <= 0) throw const ActionError('quantityRequired');
    final batches = await services.inventory.watchBatches(institutionId, cartId, assignment.id).first;
    await services.sync.track(services.inventory.reconcileAfterAudit(
      institutionId: institutionId,
      cartId: cartId,
      assignmentId: assignment.id,
      confirmedQuantity: assignment.currentQuantity - n,
      confirmedBatches: [for (final b in batches) if (b.id != item.batchId) b],
      actorUid: session.user.uid,
    ));
    return n;
  }

  /// Most units that can be replaced or removed for [item] right now.
  int maxUnits(CheckItem item) {
    final current = data.assignments.where((a) => a.id == item.assignmentId).firstOrNull?.currentQuantity ?? 0;
    return current;
  }

  /// Default for the units field: the lot's units when known, else all.
  int defaultUnits(CheckItem item) {
    final max = maxUnits(item);
    final q = item.quantity;
    return q == null || q > max ? max : q;
  }

  Future<void> setNotes(String value) async {
    notes = value;
    notify();
    await _save();
  }

  Future<void> next() async {
    if (isLastStep) return;
    step++;
    notify();
    await _save();
  }

  /// The previous step; `false` on the first one (the screen then closes,
  /// and the draft stays).
  Future<bool> back() async {
    if (step == 0) return false;
    step--;
    notify();
    await _save();
    return true;
  }

  /// Creates the "Gestão mensal" report to sign (A9) and clears the draft.
  /// Returns its id. Code `checkIncomplete` while a lot has no outcome.
  Future<ActionResult<String>> finish() => run(() async {
        if (!canFinish) throw const ActionError('checkIncomplete');
        final cart = data.cart!;
        final report = await services.reports.createReport(CartReport(
          id: '',
          institutionId: session.institution.id,
          cartId: cartId,
          cartName: cart.name,
          kind: ReportKind.monthlyCheck,
          status: ReportStatus.pendingSignature,
          createdAt: DateTime.now(),
          createdByUid: session.user.uid,
          createdByName: session.myName,
          drawersChecked: data.drawers.length,
          drawersTotal: data.drawers.length,
          positionsChecked: items.length,
          positionsTotal: items.length,
          findings: [for (final item in items) item.toFinding()],
          notes: notes.trim().isEmpty ? null : notes.trim(),
        ));
        await services.reports.clearCheckDraft(session.institution.id, cartId);
        return report.id;
      });

  @override
  void dispose() {
    data.dispose();
    super.dispose();
  }
}
