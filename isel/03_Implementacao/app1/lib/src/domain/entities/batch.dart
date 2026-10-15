/// A specific lot recorded for a [CartProductAssignment], for inventory/audit
/// purposes only. Path:
/// `institutions/{institutionId}/carts/{cartId}/assignments/{assignmentId}/batches/{id}`.
///
/// Deliberately not kept in lockstep with `currentQuantity` (spec section 23):
/// real emergency workflow does not attribute consumption to a specific lot.
class Batch {
  const Batch({
    required this.id,
    required this.assignmentId,
    required this.lotNumber,
    required this.expiryDate,
    this.quantity,
    this.gtin,
    this.source = BatchSource.manual,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  final String id;
  final String assignmentId;
  final String lotNumber;
  final DateTime expiryDate;

  /// Known quantity where established by replenishment/audit; absent when a
  /// batch was recorded without a confirmed count.
  final int? quantity;
  final String? gtin;
  final BatchSource source;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  factory Batch.fromMap(String id, String assignmentId, Map<String, Object?> map, DateTime expiryDate) {
    return Batch(
      id: id,
      assignmentId: assignmentId,
      lotNumber: map['lotNumber'] as String? ?? '',
      expiryDate: expiryDate,
      quantity: (map['quantity'] as num?)?.toInt(),
      gtin: map['gtin'] as String?,
      source: BatchSourceCodec.fromId(map['source'] as String? ?? BatchSource.manual.id),
      createdBy: map['createdBy'] as String?,
    );
  }

  Map<String, Object?> toMap() => {
        'lotNumber': lotNumber,
        if (quantity != null) 'quantity': quantity,
        if (gtin != null) 'gtin': gtin,
        'source': source.id,
        if (createdBy != null) 'createdBy': createdBy,
      };
}

enum BatchSource { manual, gs1DataMatrix, periodicAudit }

extension BatchSourceCodec on BatchSource {
  String get id => name;

  static BatchSource fromId(String id) => BatchSource.values.firstWhere(
        (source) => source.name == id,
        orElse: () => BatchSource.manual,
      );
}
