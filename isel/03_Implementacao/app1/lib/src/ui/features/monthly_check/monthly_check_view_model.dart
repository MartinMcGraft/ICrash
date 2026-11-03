import 'dart:async';

import '../../../common/app_services.dart';
import '../../../domain/entities/cart_drawer.dart';
import '../../../domain/entities/cart_product_assignment.dart';
import '../../../domain/entities/cart_report.dart';
import '../../../domain/inventory_health.dart';
import '../../core/cart_live_data.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/check_state.dart';

class CheckRowModel {
  const CheckRowModel({
    required this.assignment,
    required this.productName,
    required this.position,
    required this.health,
    required this.state,
  });
  final CartProductAssignment assignment;
  final String productName;
  final String position;
  final SlotHealth health;
  final CheckState state;
}

/// A8 · Verificação mensal (proposal D4: confirm drawer by drawer; positions
/// with differences are flagged in the report).
class MonthlyCheckViewModel extends ViewModel {
  MonthlyCheckViewModel(this.services, this.session, this.cartId) {
    data = CartLiveData(services: services, institutionId: session.institution.id, cartId: cartId, onChanged: notify);
    unawaited(_loadDraft());
  }

  final AppServices services;
  final SessionController session;
  final String cartId;
  late final CartLiveData data;

  int drawerIndex = 0;
  final Map<String, CheckState> _states = {};
  String notes = '';

  bool get ready => data.ready && data.drawers.every((d) => data.slotsLoaded(d.id));
  List<CartDrawer> get drawers => data.drawers;
  CartDrawer? get drawer => drawerIndex < drawers.length ? drawers[drawerIndex] : null;
  bool get isLastDrawer => drawerIndex >= drawers.length - 1;

  List<CheckRowModel> rowsOf(CartDrawer drawer) {
    final bySlot = data.assignmentsBySlot;
    final now = DateTime.now();
    final rows = <CheckRowModel>[];
    for (final slot in data.slotsOf(drawer)) {
      final a = bySlot[slot.id];
      if (a == null) continue;
      rows.add(CheckRowModel(
        assignment: a,
        productName: data.productName(a.productId),
        position: slotPositionLabel(slot),
        health: InventoryHealth.slotHealth(a, expiryWarningDays: session.institution.expiryWarningDays, now: now),
        state: _states[a.id] ?? CheckState.unchecked,
      ));
    }
    return rows;
  }

  List<CheckRowModel> get rows => drawer == null ? const [] : rowsOf(drawer!);

  int count(CheckState state) => rows.where((r) => r.state == state).length;
  bool get drawerComplete => rows.every((r) => r.state != CheckState.unchecked);

  /// Tap: unchecked → verified (or problem, when the slot already shows an
  /// issue) → problem ↔ verified … long-press clears.
  void toggle(CheckRowModel row) {
    final next = switch (row.state) {
      CheckState.unchecked => row.health == SlotHealth.ok ? CheckState.checked : CheckState.problem,
      CheckState.checked => CheckState.problem,
      CheckState.problem => CheckState.checked,
    };
    _states[row.assignment.id] = next;
    notify();
  }

  void clear(CheckRowModel row) {
    _states.remove(row.assignment.id);
    notify();
  }

  void markAllRemaining() {
    for (final row in rows) {
      if (row.state == CheckState.unchecked) {
        _states[row.assignment.id] = row.health == SlotHealth.ok ? CheckState.checked : CheckState.problem;
      }
    }
    notify();
  }

  void setNotes(String value) {
    notes = value;
    notify();
  }

  void nextDrawer() {
    if (!isLastDrawer) {
      drawerIndex++;
      notify();
    }
  }

  void previousDrawer() {
    if (drawerIndex > 0) {
      drawerIndex--;
      notify();
    }
  }

  /// "Guardar e sair".
  Future<void> saveDraft() => services.reports.saveCheckDraft(session.institution.id, cartId, {
        'drawerIndex': drawerIndex,
        'notes': notes,
        'states': {for (final e in _states.entries) e.key: e.value.name},
      });

  Future<void> _loadDraft() async {
    final draft = await services.reports.loadCheckDraft(session.institution.id, cartId);
    if (draft == null || isDisposed) return;
    drawerIndex = (draft['drawerIndex'] as num?)?.toInt() ?? 0;
    notes = draft['notes'] as String? ?? '';
    final states = draft['states'];
    if (states is Map) {
      for (final e in states.entries) {
        final state = CheckState.values.where((s) => s.name == e.value).firstOrNull;
        if (state != null) _states['${e.key}'] = state;
      }
    }
    notify();
  }

  /// Finishes the check and creates the report to sign (A9). Returns its id.
  Future<ActionResult<String>> finish() => run(() async {
        final cart = data.cart!;
        final findings = <ReportFinding>[];
        var checked = 0;
        var total = 0;
        for (final d in drawers) {
          for (final row in rowsOf(d)) {
            total++;
            if (row.state != CheckState.unchecked) checked++;
            if (row.state == CheckState.problem) {
              final expiry = row.assignment.earliestKnownExpiry;
              findings.add(ReportFinding(
                productName: row.productName,
                position: row.position,
                issue: switch (row.health) {
                  SlotHealth.expired => FindingIssue.expired,
                  SlotHealth.expiring => FindingIssue.expiring,
                  SlotHealth.missing => FindingIssue.missing,
                  SlotHealth.lowStock => FindingIssue.lowStock,
                  _ => FindingIssue.other,
                },
                detail: expiry == null
                    ? '${row.assignment.currentQuantity}/${row.assignment.targetQuantity}'
                    : '${row.assignment.currentQuantity}/${row.assignment.targetQuantity} · ${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}',
              ));
            }
          }
        }
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
          drawersChecked: drawers.length,
          drawersTotal: drawers.length,
          positionsChecked: checked,
          positionsTotal: total,
          findings: findings,
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
