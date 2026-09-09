import 'cart_status.dart';

/// An emergency/crash cart, scoped to one institution.
/// Path: `institutions/{institutionId}/carts/{id}`.
class Cart {
  const Cart({
    required this.id,
    required this.institutionId,
    required this.name,
    this.status = CartStatus.operational,
    this.layoutVersion = 1,
    this.templateId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String institutionId;
  final String name;
  final CartStatus status;

  /// Bumped whenever the drawer/slot structure changes, so historical events
  /// can still describe what the cart looked like when they occurred
  /// (spec section 38).
  final int layoutVersion;
  final String? templateId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Cart.fromMap(String id, String institutionId, Map<String, Object?> map) {
    return Cart(
      id: id,
      institutionId: institutionId,
      name: map['name'] as String? ?? '',
      status: CartStatusCodec.fromId(map['status'] as String? ?? CartStatus.operational.id),
      layoutVersion: (map['layoutVersion'] as num?)?.toInt() ?? 1,
      templateId: map['templateId'] as String?,
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        'name': name,
        'status': status.id,
        'layoutVersion': layoutVersion,
        if (templateId != null) 'templateId': templateId,
      };
}
