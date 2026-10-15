import 'entities/cart_drawer.dart';
import 'entities/cart_status.dart';
import 'entities/cart_product_assignment.dart';
import 'entities/slot.dart';

/// Visual state of one slot (design v2 component "Estado da posição" /
/// "Célula de posição").
enum SlotHealth {
  ok,

  /// Expires within the warning window.
  expiring,

  /// Earliest known expiry already passed.
  expired,

  /// Below target (or at/below the configured minimum) but not empty.
  lowStock,

  /// Assigned product with zero units.
  missing,

  /// No product assigned to the slot ("Livre").
  free,
}

/// Overall tone of a cart, drawer or alert line.
enum HealthTone { ok, warning, danger }

abstract final class InventoryHealth {
  /// Priority matters: the most urgent condition wins, matching the design's
  /// single status badge per slot (expired > missing > expiring > low).
  static SlotHealth slotHealth(
    CartProductAssignment? assignment, {
    required int expiryWarningDays,
    required DateTime now,
  }) {
    if (assignment == null) return SlotHealth.free;
    final expiry = assignment.earliestKnownExpiry;
    if (expiry != null && !expiry.isAfter(now)) return SlotHealth.expired;
    if (assignment.currentQuantity <= 0) return SlotHealth.missing;
    if (expiry != null && !expiry.isAfter(now.add(Duration(days: expiryWarningDays)))) {
      return SlotHealth.expiring;
    }
    final minimum = assignment.minimumQuantity;
    if (assignment.currentQuantity < assignment.targetQuantity ||
        (minimum != null && assignment.currentQuantity <= minimum)) {
      return SlotHealth.lowStock;
    }
    return SlotHealth.ok;
  }

  static HealthCounts count(
    Iterable<CartProductAssignment> assignments, {
    required int expiryWarningDays,
    required DateTime now,
  }) {
    var expired = 0, missing = 0, expiring = 0, low = 0, ok = 0;
    for (final assignment in assignments) {
      switch (slotHealth(assignment, expiryWarningDays: expiryWarningDays, now: now)) {
        case SlotHealth.expired:
          expired++;
        case SlotHealth.missing:
          missing++;
        case SlotHealth.expiring:
          expiring++;
        case SlotHealth.lowStock:
          low++;
        case SlotHealth.ok:
          ok++;
        case SlotHealth.free:
          break;
      }
    }
    return HealthCounts(expired: expired, missing: missing, expiring: expiring, lowStock: low, ok: ok);
  }

  /// Summary of one drawer: positions, positions with product, health counts.
  static DrawerHealth drawerHealth(
    CartDrawer drawer,
    List<Slot> slots,
    Map<String, CartProductAssignment> assignmentsBySlot, {
    required int expiryWarningDays,
    required DateTime now,
  }) {
    final effectiveSlots = slots.isEmpty ? drawer.rows * drawer.columns : slots.length;
    final inDrawer = [
      for (final slot in slots)
        ?assignmentsBySlot[slot.id],
    ];
    return DrawerHealth(
      positions: effectiveSlots,
      withProduct: inDrawer.length,
      counts: count(inDrawer, expiryWarningDays: expiryWarningDays, now: now),
    );
  }
}

class HealthCounts {
  const HealthCounts({
    this.expired = 0,
    this.missing = 0,
    this.expiring = 0,
    this.lowStock = 0,
    this.ok = 0,
  });

  final int expired;
  final int missing;
  final int expiring;
  final int lowStock;
  final int ok;

  static const zero = HealthCounts();

  HealthTone get tone {
    if (expired > 0 || missing > 0) return HealthTone.danger;
    if (expiring > 0 || lowStock > 0) return HealthTone.warning;
    return HealthTone.ok;
  }

  bool get allOk => tone == HealthTone.ok;

  HealthCounts operator +(HealthCounts other) => HealthCounts(
        expired: expired + other.expired,
        missing: missing + other.missing,
        expiring: expiring + other.expiring,
        lowStock: lowStock + other.lowStock,
        ok: ok + other.ok,
      );
}

class DrawerHealth {
  const DrawerHealth({required this.positions, required this.withProduct, required this.counts});
  final int positions;
  final int withProduct;
  final HealthCounts counts;
}

/// Human position label for a slot: row letter + column number ("A1", "B3"),
/// replacing the old "1,1" coordinates nurses could not read (audit §4.4).
String slotPositionLabel(Slot slot) => slot.label ?? positionLabel(slot.row, slot.column);

String positionLabel(int row, int column) {
  var r = row;
  var letters = '';
  do {
    letters = String.fromCharCode(65 + r % 26) + letters;
    r = r ~/ 26 - 1;
  } while (r >= 0);
  return '$letters${column + 1}';
}

/// Proposal D7 — automatic cart state. "Fora de serviço" is always a manual
/// decision and is never overridden; otherwise an expired or missing product
/// requires replenishment, and an overdue monthly check requires a check.
CartStatus suggestedCartStatus({required CartStatus current, required HealthCounts counts, required bool checkOverdue}) {
  if (current == CartStatus.outOfService) return current;
  if (counts.expired > 0 || counts.missing > 0) return CartStatus.replenishmentRequired;
  if (checkOverdue) return CartStatus.auditRequired;
  return CartStatus.operational;
}

/// Slot ids follow `r{row}c{column}` (grid cells keep their top-left id when
/// merged), so a position label can be derived without loading the layout.
String? positionFromSlotId(String slotId) {
  final match = RegExp(r'^r(\d+)c(\d+)$').firstMatch(slotId);
  if (match == null) return null;
  return positionLabel(int.parse(match.group(1)!), int.parse(match.group(2)!));
}
