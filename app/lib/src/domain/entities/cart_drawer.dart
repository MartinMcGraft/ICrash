/// One physical drawer inside a [Cart]. Named `CartDrawer` to avoid clashing
/// with Flutter's own `Drawer` widget.
/// Path: `institutions/{institutionId}/carts/{cartId}/drawers/{id}`.
///
/// A drawer has a [number] and no name (P17): it is always shown as
/// "Gaveta N". Its slots are created together with it (one per grid cell)
/// and edited in B4.
class CartDrawer {
  const CartDrawer({
    required this.id,
    required this.cartId,
    required this.number,
    required this.rows,
    required this.columns,
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

  /// Base grid dimensions; individual [Slot]s can span multiple cells
  /// (spec section 36).
  final int rows;
  final int columns;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Old documents may still carry a `name` (P17); it's ignored.
  factory CartDrawer.fromMap(String id, String cartId, Map<String, Object?> map) {
    return CartDrawer(
      id: id,
      cartId: cartId,
      number: (map['number'] as num?)?.toInt(),
      rows: (map['rows'] as num?)?.toInt() ?? 1,
      columns: (map['columns'] as num?)?.toInt() ?? 1,
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        if (number != null) 'number': number,
        'rows': rows,
        'columns': columns,
      };

  CartDrawer copyWith({int? number, int? rows, int? columns}) => CartDrawer(
        id: id,
        cartId: cartId,
        number: number ?? this.number,
        rows: rows ?? this.rows,
        columns: columns ?? this.columns,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
