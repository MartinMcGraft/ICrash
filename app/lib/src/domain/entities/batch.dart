/// The units of one slot that share an expiry date (DB1), for inventory and
/// audit purposes. Path:
/// `institutions/{institutionId}/carts/{cartId}/assignments/{assignmentId}/batches/{id}`.
///
/// Deliberately not kept in lockstep with `currentQuantity` (spec section 23):
/// real emergency workflow does not attribute consumption to a specific lot.
///
/// Batches are never deleted (DB1, DATABASE.md §1.5): a batch confirmed gone
/// (used up, discarded or not found) gets [removedAt] and stays as history.
/// Same-date batches are not merged yet (P10, which lot number the merged
/// batch keeps, is open).
class Batch {
  const Batch({
    required this.id,
    required this.assignmentId,
    required this.expiryDate,
    this.lotNumber,
    this.quantity,
    this.gtin,
    this.source = BatchSource.manual,
    this.removedAt,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  final String id;
  final String assignmentId;

  /// The manufacturer's lot code. Optional (P9): some items show only an
  /// expiry date; then the batch is entered and checked by hand.
  final String? lotNumber;
  final DateTime expiryDate;

  /// Units put in the slot with this date; required and > 0 for new batches
  /// (A7). Old batches may have none.
  final int? quantity;
  final String? gtin;
  final BatchSource source;

  /// When the batch was confirmed gone. `null` while it's in the slot.
  final DateTime? removedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  bool get isActive => removedAt == null;

  factory Batch.fromMap(String id, String assignmentId, Map<String, Object?> map, DateTime expiryDate, {DateTime? removedAt}) {
    final lot = (map['lotNumber'] as String?)?.trim();
    return Batch(
      id: id,
      assignmentId: assignmentId,
      lotNumber: lot == null || lot.isEmpty ? null : lot,
      expiryDate: expiryDate,
      quantity: (map['quantity'] as num?)?.toInt(),
      gtin: map['gtin'] as String?,
      source: BatchSourceCodec.fromId(map['source'] as String? ?? BatchSource.manual.id),
      removedAt: removedAt,
      createdBy: map['createdBy'] as String?,
    );
  }

  Map<String, Object?> toMap() => {
        if (lotNumber != null) 'lotNumber': lotNumber,
        if (quantity != null) 'quantity': quantity,
        if (gtin != null) 'gtin': gtin,
        'source': source.id,
        if (createdBy != null) 'createdBy': createdBy,
      };

  Batch removed(DateTime at) => Batch(
        id: id,
        assignmentId: assignmentId,
        lotNumber: lotNumber,
        expiryDate: expiryDate,
        quantity: quantity,
        gtin: gtin,
        source: source,
        removedAt: at,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
      );
}

enum BatchSource { manual, gs1DataMatrix, periodicAudit }

extension BatchSourceCodec on BatchSource {
  String get id => name;

  static BatchSource fromId(String id) => BatchSource.values.firstWhere(
        (source) => source.name == id,
        orElse: () => BatchSource.manual,
      );
}
