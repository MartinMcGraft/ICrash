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
    required this.slotId,
    required this.productId,
    required this.currentQuantity,
    required this.targetQuantity,
    this.earliestKnownExpiry,
    this.updatedAt,
    this.updatedBy,
  });

  final String id;
  final String cartId;
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
  final DateTime? updatedAt;
  final String? updatedBy;

  factory CartProductAssignment.fromMap(String id, String cartId, Map<String, Object?> map) {
    return CartProductAssignment(
      id: id,
      cartId: cartId,
      slotId: map['slotId'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      currentQuantity: (map['currentQuantity'] as num?)?.toInt() ?? 0,
      targetQuantity: (map['targetQuantity'] as num?)?.toInt() ?? 0,
      // Old documents may still carry `minimumQuantity` (D10) and a stale
      // `status` that was written once and never updated; both are ignored.
      updatedBy: map['updatedBy'] as String?,
      earliestKnownExpiry: map['earliestKnownExpiry'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        'slotId': slotId,
        'productId': productId,
        'currentQuantity': currentQuantity,
        'targetQuantity': targetQuantity,
        if (updatedBy != null) 'updatedBy': updatedBy,
      };

  CartProductAssignment copyWith({
    String? id,
    String? slotId,
    String? productId,
    int? currentQuantity,
    int? targetQuantity,
    DateTime? earliestKnownExpiry,
    bool clearEarliestKnownExpiry = false,
  }) =>
      CartProductAssignment(
        id: id ?? this.id,
        cartId: cartId,
        slotId: slotId ?? this.slotId,
        productId: productId ?? this.productId,
        currentQuantity: currentQuantity ?? this.currentQuantity,
        targetQuantity: targetQuantity ?? this.targetQuantity,
        earliestKnownExpiry: clearEarliestKnownExpiry ? null : (earliestKnownExpiry ?? this.earliestKnownExpiry),
        updatedAt: updatedAt,
        updatedBy: updatedBy,
      );
}
