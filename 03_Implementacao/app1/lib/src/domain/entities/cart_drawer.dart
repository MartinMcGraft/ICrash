/// One physical drawer inside a [Cart]. Named `CartDrawer` to avoid clashing
/// with Flutter's own `Drawer` widget.
/// Path: `institutions/{institutionId}/carts/{cartId}/drawers/{id}`.
class CartDrawer {
  const CartDrawer({
    required this.id,
    required this.cartId,
    required this.name,
    required this.rows,
    required this.columns,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String cartId;
  final String name;

  /// Base grid dimensions; individual [Slot]s can span multiple cells
  /// (spec section 36).
  final int rows;
  final int columns;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CartDrawer.fromMap(String id, String cartId, Map<String, Object?> map) {
    return CartDrawer(
      id: id,
      cartId: cartId,
      name: map['name'] as String? ?? '',
      rows: (map['rows'] as num?)?.toInt() ?? 1,
      columns: (map['columns'] as num?)?.toInt() ?? 1,
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        'name': name,
        'rows': rows,
        'columns': columns,
      };
}
