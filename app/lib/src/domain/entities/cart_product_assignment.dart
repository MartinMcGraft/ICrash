/// Associates one [Product] with one [Slot] inside one [Cart], and carries
/// the fast operational stock aggregate for that pairing.
/// Path: `institutions/{institutionId}/carts/{cartId}/assignments/{id}`.
///
/// CRITICAL (spec sections 22-28): [currentQuantity] is the authoritative,
/// immediately-updated daily stock number. It is intentionally NOT derived
/// by summing known batches — daily consumption never attributes a lot, so
/// the two can disagree until the next physical reconciliation. Never write
/// code that assumes `currentQuantity == sum(batch quantities)` at all times.
class CartProductAssignment {
  const CartProductAssignment({
    required this.id,
    required this.cartId,
    this.drawerId,
    required this.slotId,
    required this.productId,
    required this.currentQuantity,
    required this.targetQuantity,
    this.earliestKnownExpiry,
    this.usedAt,
    this.updatedAt,
    this.updatedBy,
  });

  final String id;
  final String cartId;

  /// The drawer of [slotId]. Slot ids (`r{row}c{col}`) repeat in every
  /// drawer, so the slot is only unambiguous with its drawer. `null` only on
  /// placements created before 29 Oct 2026; `CartLiveData.drawerOf` then
  /// falls back to the first drawer that has a slot with that id.
  final String? drawerId;
  final String slotId;
  final String productId;

  /// Authoritative operational aggregate. Decremented directly by daily
  /// consumption without touching batch records (spec section 24).
  /// Always `0 ≤ currentQuantity ≤ targetQuantity` (P5: no overfill).
  final int currentQuantity;

  /// The full quantity the slot should hold (DATABASE.md `maxNumberCC`).
  /// There is no minimum stock (D10): below this, the slot needs replenishing.
  final int targetQuantity;

  /// Conservative nearest known expiry across all batches ever recorded for
  /// this assignment that have not been physically confirmed absent
  /// (spec sections 25-28). Only reconciliation may advance it.
  final DateTime? earliestKnownExpiry;

  /// Firestore-only marker (no column in DATABASE.md): set with the first
  /// History event that points to this placement. From then on the placement
  /// keeps its slot and product and can't be deleted (P1/P2); the rules use
  /// it because they can't query `usageEvents`. Placements used before
  /// 29 Oct 2026 lack it; the app also checks their history.
  final DateTime? usedAt;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory CartProductAssignment.fromMap(String id, String cartId, Map<String, Object?> map) {
    return CartProductAssignment(
      id: id,
      cartId: cartId,
      drawerId: map['drawerId'] as String?,
      slotId: map['slotId'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      currentQuantity: (map['currentQuantity'] as num?)?.toInt() ?? 0,
      targetQuantity: (map['targetQuantity'] as num?)?.toInt() ?? 0,
      // Old documents may still carry `minimumQuantity` (D10) and a stale
      // `status` that was written once and never updated; both are ignored.
      updatedBy: map['updatedBy'] as String?,
      earliestKnownExpiry: map['earliestKnownExpiry'] as DateTime?,
      usedAt: map['usedAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        if (drawerId != null) 'drawerId': drawerId,
        'slotId': slotId,
        'productId': productId,
        'currentQuantity': currentQuantity,
        'targetQuantity': targetQuantity,
        if (updatedBy != null) 'updatedBy': updatedBy,
      };

  CartProductAssignment copyWith({
    String? id,
    String? drawerId,
    String? slotId,
    String? productId,
    int? currentQuantity,
    int? targetQuantity,
    DateTime? earliestKnownExpiry,
    bool clearEarliestKnownExpiry = false,
    DateTime? usedAt,
  }) =>
      CartProductAssignment(
        id: id ?? this.id,
        cartId: cartId,
        drawerId: drawerId ?? this.drawerId,
        slotId: slotId ?? this.slotId,
        productId: productId ?? this.productId,
        currentQuantity: currentQuantity ?? this.currentQuantity,
        targetQuantity: targetQuantity ?? this.targetQuantity,
        earliestKnownExpiry: clearEarliestKnownExpiry ? null : (earliestKnownExpiry ?? this.earliestKnownExpiry),
        usedAt: usedAt ?? this.usedAt,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
      );
}
