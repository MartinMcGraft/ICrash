// D4 / D22 / D23 "Gestão mensal" (monthly management check), 30 Oct 2026.
//
// The check covers the whole cart but lists only the lots that are expired or
// expiring; everything else counts as valid by default (D4). Each listed lot
// gets one explicit outcome. There is no "Não encontrado" (P8) and no
// correction afterwards (P15): a report is edited until it's signed and never
// changes after. "Substituído" and "Retirado sem reposição" change the stock
// as soon as they are confirmed (Martim, 30 Oct).

import 'entities/batch.dart';
import 'entities/cart_drawer.dart';
import 'entities/cart_product_assignment.dart';
import 'entities/cart_report.dart';

/// What happened to an expired or expiring lot.
enum CheckOutcome {
  /// Replaced by new units with a later expiry date (stock: the old lot is
  /// marked removed and a new one is added; the quantity stays the same).
  replaced,

  /// Taken out with nothing to put in its place (stock goes down; the slot
  /// then needs replenishing).
  removed,

  /// Expiring but still valid: noted and left in the cart.
  kept,
}

/// The outcomes each state offers. **ESEL still has to confirm these (D22);
/// change them here only.** An expired lot can't be kept.
const Map<FindingIssue, List<CheckOutcome>> checkOutcomes = {
  FindingIssue.expired: [CheckOutcome.replaced, CheckOutcome.removed],
  FindingIssue.expiring: [CheckOutcome.kept, CheckOutcome.replaced],
};

/// Outcomes that change the stock, so the item can't be answered again.
bool outcomeChangesStock(CheckOutcome outcome) => outcome != CheckOutcome.kept;

/// One expired or expiring lot of one slot, and what the nurse did with it.
class CheckItem {
  const CheckItem({
    required this.assignmentId,
    required this.drawerId,
    required this.drawerNumber,
    this.drawerName,
    required this.position,
    required this.productName,
    required this.issue,
    required this.expiryDate,
    this.batchId,
    this.lotNumber,
    this.quantity,
    this.outcome,
    this.units,
    this.newExpiry,
    this.newLot,
  });

  final String assignmentId;
  final String drawerId;
  final int drawerNumber;
  final String? drawerName;

  /// "B3".
  final String position;
  final String productName;

  /// [FindingIssue.expired] or [FindingIssue.expiring].
  final FindingIssue issue;
  final DateTime expiryDate;

  /// `null` when the slot has no batch records, only an earliest expiry
  /// (carts set up without lots, P19 follow-up).
  final String? batchId;
  final String? lotNumber;

  /// Units of this lot, when known.
  final int? quantity;

  final CheckOutcome? outcome;

  /// Units replaced or removed.
  final int? units;
  final DateTime? newExpiry;
  final String? newLot;

  /// One item per lot (or per slot without lots).
  String get id => '$assignmentId/${batchId ?? '-'}';
  bool get answered => outcome != null;

  /// Answered with a stock change: shown as done, can't be answered again.
  bool get locked => outcome != null && outcomeChangesStock(outcome!);

  CheckItem answer(CheckOutcome? outcome, {int? units, DateTime? newExpiry, String? newLot}) => CheckItem(
        assignmentId: assignmentId,
        drawerId: drawerId,
        drawerNumber: drawerNumber,
        drawerName: drawerName,
        position: position,
        productName: productName,
        issue: issue,
        expiryDate: expiryDate,
        batchId: batchId,
        lotNumber: lotNumber,
        quantity: quantity,
        outcome: outcome,
        units: units,
        newExpiry: newExpiry,
        newLot: newLot,
      );

  /// What the draft keeps for an answered lot: all of it, because a lot
  /// that was replaced or removed is no longer in the stock to rebuild it.
  Map<String, Object?> toJson() => {
        'assignmentId': assignmentId,
        'drawerId': drawerId,
        'drawerNumber': drawerNumber,
        'drawerName': drawerName,
        'position': position,
        'productName': productName,
        'issue': issue.name,
        'expiryDate': expiryDate.toIso8601String(),
        'batchId': batchId,
        'lotNumber': lotNumber,
        'quantity': quantity,
        'outcome': outcome?.name,
        'units': units,
        'newExpiry': newExpiry?.toIso8601String(),
        'newLot': newLot,
      };

  static DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;

  /// `null` when the saved data is incomplete.
  static CheckItem? fromJson(Map<String, Object?> json) {
    final issue = FindingIssue.values.where((i) => i.name == json['issue']).firstOrNull;
    final expiry = _date(json['expiryDate']);
    final assignmentId = json['assignmentId'];
    final drawerId = json['drawerId'];
    if (issue == null || expiry == null || assignmentId is! String || drawerId is! String) return null;
    return CheckItem(
      assignmentId: assignmentId,
      drawerId: drawerId,
      drawerNumber: (json['drawerNumber'] as num?)?.toInt() ?? 0,
      drawerName: json['drawerName'] as String?,
      position: json['position'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      issue: issue,
      expiryDate: expiry,
      batchId: json['batchId'] as String?,
      lotNumber: json['lotNumber'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
    ).withSavedAnswer(json);
  }

  /// Applies a saved answer; one this lot's state no longer allows (a kept lot
  /// that has since expired) is dropped.
  CheckItem withSavedAnswer(Map<String, Object?> json) {
    final outcome = CheckOutcome.values.where((o) => o.name == json['outcome']).firstOrNull;
    if (outcome != null && !checkOutcomes[issue]!.contains(outcome)) return answer(null);
    return answer(
      outcome,
      units: (json['units'] as num?)?.toInt(),
      newExpiry: _date(json['newExpiry']),
      newLot: json['newLot'] as String?,
    );
  }

  /// The report line (A9, PDF): drawer and position, lot, expiry, outcome.
  ReportFinding toFinding() => ReportFinding(
        productName: productName,
        position: position,
        issue: issue,
        drawerNumber: drawerNumber,
        drawerName: drawerName,
        lotNumber: lotNumber,
        expiryDate: expiryDate,
        outcome: outcome?.name,
        units: units,
        newExpiry: newExpiry,
        newLot: newLot,
      );
}

/// Today at 00:00, so a lot expiring today counts as expired tomorrow.
DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// The state of one expiry date: expired, expiring (within [warningDays]),
/// or `null` when it's still valid.
FindingIssue? expiryIssue(DateTime expiry, {required int warningDays, required DateTime now}) {
  final today = _day(now);
  final day = _day(expiry);
  if (day.isBefore(today)) return FindingIssue.expired;
  if (!day.isAfter(today.add(Duration(days: warningDays)))) return FindingIssue.expiring;
  return null;
}

/// The cart's expired and expiring lots, by drawer number then position,
/// expired first. A slot with no batch records falls back to its earliest
/// known expiry. Removed batches and empty slots are left out.
List<CheckItem> buildCheckItems({
  required List<CartDrawer> drawers,
  required int Function(CartDrawer drawer) numberOf,
  required List<CartProductAssignment> assignments,
  required String? Function(CartProductAssignment assignment) drawerIdOf,
  required String Function(CartProductAssignment assignment) positionOf,
  required String Function(String productId) productName,
  required int Function(String productId) warningDaysOf,
  required Map<String, List<Batch>> batchesByAssignment,
  required DateTime now,
}) {
  final byId = {for (final d in drawers) d.id: d};
  final items = <CheckItem>[];
  for (final a in assignments) {
    if (a.currentQuantity <= 0) continue;
    final drawer = byId[drawerIdOf(a)];
    if (drawer == null) continue;
    final warning = warningDaysOf(a.productId);
    CheckItem item(FindingIssue issue, DateTime expiry, [Batch? batch]) => CheckItem(
          assignmentId: a.id,
          drawerId: drawer.id,
          drawerNumber: numberOf(drawer),
          drawerName: drawer.name,
          position: positionOf(a),
          productName: productName(a.productId),
          issue: issue,
          expiryDate: expiry,
          batchId: batch?.id,
          lotNumber: batch?.lotNumber,
          quantity: batch?.quantity,
        );
    final batches = (batchesByAssignment[a.id] ?? const <Batch>[]).where((b) => b.isActive).toList();
    if (batches.isEmpty) {
      final expiry = a.earliestKnownExpiry;
      final issue = expiry == null ? null : expiryIssue(expiry, warningDays: warning, now: now);
      if (issue != null) items.add(item(issue, expiry!));
      continue;
    }
    for (final batch in batches) {
      final issue = expiryIssue(batch.expiryDate, warningDays: warning, now: now);
      if (issue != null) items.add(item(issue, batch.expiryDate, batch));
    }
  }
  return items..sort(compareCheckItems);
}

/// Drawer number, then position, then expiry (expired first).
int compareCheckItems(CheckItem x, CheckItem y) {
  final byDrawer = x.drawerNumber.compareTo(y.drawerNumber);
  if (byDrawer != 0) return byDrawer;
  final byPosition = x.position.compareTo(y.position);
  if (byPosition != 0) return byPosition;
  return x.expiryDate.compareTo(y.expiryDate);
}

/// The items to show when a check is resumed: the lots [built] from the
/// stock now, with the [saved] answers applied, plus the answered lots that
/// are no longer in the stock (replaced or removed).
List<CheckItem> mergeSavedAnswers(List<CheckItem> built, Map<String, Map<String, Object?>> saved) {
  final ids = {for (final item in built) item.id};
  return [
    for (final item in built) saved.containsKey(item.id) ? item.withSavedAnswer(saved[item.id]!) : item,
    for (final entry in saved.entries)
      if (!ids.contains(entry.key)) ?CheckItem.fromJson(entry.value),
  ]..sort(compareCheckItems);
}
