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
    this.category,
    this.expiryWarningDays,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String institutionId;
  final String name;
  final String? description;

  /// Presentation, e.g. "Ampola 1 ml" (design v2 column "Apresentação").
  final String? unitDescription;
  final String? gtin;

  /// Catalogue category (design v2 B5 filter: Fármacos / Material / Fluidos).
  final ProductCategory? category;

  /// Per-product expiry warning in days; null = institution default.
  final int? expiryWarningDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product copyWith({
    String? name,
    String? unitDescription,
    String? gtin,
    ProductCategory? category,
    int? expiryWarningDays,
  }) {
    return Product(
      id: id,
      institutionId: institutionId,
      name: name ?? this.name,
      description: description,
      unitDescription: unitDescription ?? this.unitDescription,
      gtin: gtin ?? this.gtin,
      category: category ?? this.category,
      expiryWarningDays: expiryWarningDays ?? this.expiryWarningDays,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Product.fromMap(String id, String institutionId, Map<String, Object?> map) {
    return Product(
      id: id,
      institutionId: institutionId,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      unitDescription: map['unitDescription'] as String?,
      gtin: map['gtin'] as String?,
      category: ProductCategoryCodec.tryFromId(map['category'] as String?),
      expiryWarningDays: (map['expiryWarningDays'] as num?)?.toInt(),
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        'name': name,
        if (description != null) 'description': description,
        if (unitDescription != null) 'unitDescription': unitDescription,
        if (gtin != null) 'gtin': gtin,
        if (category != null) 'category': category!.id,
        if (expiryWarningDays != null) 'expiryWarningDays': expiryWarningDays,
      };
}

enum ProductCategory { drug, material, fluid }

extension ProductCategoryCodec on ProductCategory {
  String get id => name;

  static ProductCategory? tryFromId(String? id) {
    for (final value in ProductCategory.values) {
      if (value.name == id) return value;
    }
    return null;
  }
}
