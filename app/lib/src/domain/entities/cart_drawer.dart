/// One physical drawer inside a [Cart]. Named `CartDrawer` to avoid clashing
/// with Flutter's own `Drawer` widget.
/// Path: `institutions/{institutionId}/carts/{cartId}/drawers/{id}`.
///
/// A drawer has a [number] and an optional descriptive [name] (D20, 30 Oct
/// 2026; reverses the drawer half of P17): shown as the name, or "Gaveta N"
/// when it has none. Its slots are created together with it (one per grid
/// cell) and edited in B4.
class CartDrawer {
  const CartDrawer({
    required this.id,
    required this.cartId,
    required this.number,
    this.name,
    required this.rows,
    required this.columns,
    this.usedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String cartId;

  /// The drawer's position in the cart (1 = top), as printed on the cart.
  /// Unique within its cart (DATABASE.md UNIQUE (`idCrashCart`, `number`);
  /// checked by the app, since Firestore rules can't). `null` only for
  /// drawers created before 29 Oct 2026: the app then shows their position
  /// in creation order, as it did before (see `CartLiveData.numberOf`).
  final int? number;

  /// Optional descriptive name ("Via aérea", "Circulação"), at most
  /// [maxNameLength] characters; `null` when it has none (D20). Not unique.
  /// It isn't structure, so a used drawer may still be renamed.
  final String? name;

  static const maxNameLength = 50;

  /// Trims [value]; empty → `null`.
  static String? cleanName(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Base grid dimensions; individual [Slot]s can span multiple cells
  /// (spec section 36).
  final int rows;
  final int columns;

  /// Firestore-only marker: set with the first History event in any of the
  /// drawer's slots. A used drawer can't be resized, re-laid-out or
  /// renumbered (P1/P2, Q8); drawers are never deleted.
  final DateTime? usedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Documents from before P17 may carry an old `name`: it's shown again (D20).
  factory CartDrawer.fromMap(String id, String cartId, Map<String, Object?> map) {
    return CartDrawer(
      id: id,
      cartId: cartId,
      number: (map['number'] as num?)?.toInt(),
      name: cleanName(map['name'] as String?),
      rows: (map['rows'] as num?)?.toInt() ?? 1,
      columns: (map['columns'] as num?)?.toInt() ?? 1,
      usedAt: map['usedAt'] as DateTime?,
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  /// Without a name the key is left out; [FirestoreDrawerRepository.updateDrawer]
  /// deletes a stored name in that case.
  Map<String, Object?> toMap() => {
        if (number != null) 'number': number,
        if (name != null) 'name': name,
        'rows': rows,
        'columns': columns,
      };

  /// [clearName] removes the name.
  CartDrawer copyWith({int? number, String? name, bool clearName = false, int? rows, int? columns}) => CartDrawer(
        id: id,
        cartId: cartId,
        number: number ?? this.number,
        name: clearName ? null : (name ?? this.name),
        rows: rows ?? this.rows,
        columns: columns ?? this.columns,
        usedAt: usedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
