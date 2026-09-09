/// Reusable definition of a medicine/material, scoped to one institution.
/// Path: `institutions/{institutionId}/products/{id}`.
///
/// Deliberately minimal for the prototype (spec section 21): the GTIN exists
/// to support GS1 Data Matrix matching, not to dominate the normal UI, and
/// product images are explicitly deferred.
class Product {
  const Product({
    required this.id,
    required this.institutionId,
    required this.name,
    this.description,
    this.unitDescription,
    this.gtin,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String institutionId;
  final String name;
  final String? description;

  /// e.g. "1 mg/mL, ampola 1 mL".
  final String? unitDescription;
  final String? gtin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Product.fromMap(String id, String institutionId, Map<String, Object?> map) {
    return Product(
      id: id,
      institutionId: institutionId,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      unitDescription: map['unitDescription'] as String?,
      gtin: map['gtin'] as String?,
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        'name': name,
        if (description != null) 'description': description,
        if (unitDescription != null) 'unitDescription': unitDescription,
        if (gtin != null) 'gtin': gtin,
      };
}
