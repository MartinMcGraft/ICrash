/// Immutable administrative/operational trail entry (spec section 45):
/// role changes, memberships, cart assignments, structure changes, template
/// operations, monthly verification, etc. Never edited or deleted.
/// Path: `institutions/{institutionId}/auditEvents/{id}`.
///
/// Deliberately generic: [type] plus the free-form [metadata] map cover the
/// long tail of event kinds listed in the spec without one entity field per
/// kind.
class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.institutionId,
    required this.actorUid,
    required this.type,
    this.cartId,
    this.drawerId,
    this.slotId,
    this.productId,
    this.previousValue,
    this.newValue,
    this.correctionRef,
    this.metadata = const {},
    this.localTimestamp,
    this.serverTimestamp,
  });

  final String id;
  final String institutionId;
  final String actorUid;
  final String type;
  final String? cartId;
  final String? drawerId;
  final String? slotId;
  final String? productId;
  final Object? previousValue;
  final Object? newValue;
  final String? correctionRef;
  final Map<String, Object?> metadata;
  final DateTime? localTimestamp;
  final DateTime? serverTimestamp;

  factory AuditEvent.fromMap(String id, String institutionId, Map<String, Object?> map, {DateTime? serverTimestamp}) {
    return AuditEvent(
      id: id,
      institutionId: institutionId,
      actorUid: map['actorUid'] as String? ?? '',
      type: map['type'] as String? ?? 'unknown',
      cartId: map['cartId'] as String?,
      drawerId: map['drawerId'] as String?,
      slotId: map['slotId'] as String?,
      productId: map['productId'] as String?,
      previousValue: map['previousValue'],
      newValue: map['newValue'],
      correctionRef: map['correctionRef'] as String?,
      metadata: (map['metadata'] as Map?)?.cast<String, Object?>() ?? const {},
      serverTimestamp: serverTimestamp,
    );
  }

  Map<String, Object?> toMap() => {
        'actorUid': actorUid,
        'type': type,
        if (cartId != null) 'cartId': cartId,
        if (drawerId != null) 'drawerId': drawerId,
        if (slotId != null) 'slotId': slotId,
        if (productId != null) 'productId': productId,
        if (previousValue != null) 'previousValue': previousValue,
        if (newValue != null) 'newValue': newValue,
        if (correctionRef != null) 'correctionRef': correctionRef,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}
