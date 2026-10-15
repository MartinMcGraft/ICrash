/// A tenant of the platform. Document id lives under `institutions/{id}`.
class Institution {
  const Institution({
    required this.id,
    required this.name,
    this.expiryWarningDays = 30,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  final String id;
  final String name;

  /// Institution-configurable horizon (spec section 46: default 1 month)
  /// used to flag products approaching expiry.
  final int expiryWarningDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  factory Institution.fromMap(String id, Map<String, Object?> map) {
    return Institution(
      id: id,
      name: map['name'] as String? ?? '',
      expiryWarningDays: (map['expiryWarningDays'] as num?)?.toInt() ?? 30,
      createdBy: map['createdBy'] as String?,
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        'name': name,
        'expiryWarningDays': expiryWarningDays,
        if (createdBy != null) 'createdBy': createdBy,
      };
}
