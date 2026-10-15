/// Immutable record of a stock change against one [CartProductAssignment]:
/// daily consumption, replenishment, or a correction of an earlier event
/// (spec sections 24, 43-44). Never edited or deleted after creation.
/// Path: `institutions/{institutionId}/usageEvents/{id}`.
class UsageEvent {
  const UsageEvent({
    required this.id,
    required this.institutionId,
    required this.actorUid,
    required this.cartId,
    required this.assignmentId,
    required this.productId,
    required this.type,
    required this.amount,
    this.correctsEventId,
    this.localTimestamp,
    this.serverTimestamp,
  });

  final String id;
  final String institutionId;
  final String actorUid;
  final String cartId;
  final String assignmentId;
  final String productId;
  final UsageEventType type;

  /// Signed change applied to `currentQuantity`: negative for consumption,
  /// positive for replenishment or a correction that adds stock back.
  final int amount;

  /// Set only when [type] is [UsageEventType.correction]; the corrected
  /// event is never mutated or removed, only compensated.
  final String? correctsEventId;
  final DateTime? localTimestamp;
  final DateTime? serverTimestamp;

  factory UsageEvent.fromMap(String id, String institutionId, Map<String, Object?> map, {DateTime? serverTimestamp}) {
    return UsageEvent(
      id: id,
      institutionId: institutionId,
      actorUid: map['actorUid'] as String? ?? '',
      cartId: map['cartId'] as String? ?? '',
      assignmentId: map['assignmentId'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      type: UsageEventTypeCodec.fromId(map['type'] as String? ?? UsageEventType.consumption.id),
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      correctsEventId: map['correctsEventId'] as String?,
      serverTimestamp: serverTimestamp,
    );
  }

  Map<String, Object?> toMap() => {
        'actorUid': actorUid,
        'cartId': cartId,
        'assignmentId': assignmentId,
        'productId': productId,
        'type': type.id,
        'amount': amount,
        if (correctsEventId != null) 'correctsEventId': correctsEventId,
      };
}

enum UsageEventType { consumption, replenishment, correction, auditReconciliation }

extension UsageEventTypeCodec on UsageEventType {
  String get id => name;

  static UsageEventType fromId(String id) => UsageEventType.values.firstWhere(
        (type) => type.name == id,
        orElse: () => UsageEventType.consumption,
      );
}
