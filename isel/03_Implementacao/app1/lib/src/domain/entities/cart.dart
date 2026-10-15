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
    this.service,
    this.location,
    this.archived = false,
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

  /// Hospital service/department the cart belongs to (e.g. "Urgência").
  /// Design v2: shown under the cart name ("Urgência · Piso 0").
  final String? service;

  /// Physical location (e.g. "Piso 0 · Sala de reanimação").
  final String? location;

  /// Archived carts are hidden from every list. Firestore Rules forbid
  /// deleting a cart (history must survive), so "Arquivar carrinho" in the
  /// dashboard sets this flag instead (audit decision D15: archive, never
  /// hard delete).
  final bool archived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// "Urgência · Piso 0", or null when neither is set.
  String? get placeLabel {
    final parts = [service, location].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Cart copyWith({
    String? name,
    CartStatus? status,
    int? layoutVersion,
    String? templateId,
    String? service,
    String? location,
    bool? archived,
  }) {
    return Cart(
      id: id,
      institutionId: institutionId,
      name: name ?? this.name,
      status: status ?? this.status,
      layoutVersion: layoutVersion ?? this.layoutVersion,
      templateId: templateId ?? this.templateId,
      service: service ?? this.service,
      location: location ?? this.location,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Cart.fromMap(String id, String institutionId, Map<String, Object?> map) {
    return Cart(
      id: id,
      institutionId: institutionId,
      name: map['name'] as String? ?? '',
      status: CartStatusCodec.fromId(map['status'] as String? ?? CartStatus.operational.id),
      layoutVersion: (map['layoutVersion'] as num?)?.toInt() ?? 1,
      templateId: map['templateId'] as String?,
      service: map['service'] as String?,
      location: map['location'] as String?,
      archived: map['archived'] as bool? ?? false,
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        'name': name,
        'status': status.id,
        'layoutVersion': layoutVersion,
        if (templateId != null) 'templateId': templateId,
        if (service != null) 'service': service,
        if (location != null) 'location': location,
        'archived': archived,
      };
}
