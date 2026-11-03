import 'slot.dart';

/// A cart template (design v2 B6 "Modelos"): drawers, positions and target
/// quantities. Carts created from a template copy those; stock and history
/// are never copied. Backed by a local stub repository for now.
class CartTemplate {
  const CartTemplate({
    required this.id,
    required this.institutionId,
    required this.name,
    required this.drawers,
    required this.updatedAt,
    required this.updatedByName,
  });

  final String id;
  final String institutionId;
  final String name;
  final List<TemplateDrawer> drawers;
  final DateTime updatedAt;
  final String updatedByName;

  int get positionCount => drawers.fold(0, (sum, d) => sum + d.positionCount);

  CartTemplate copyWith({String? id, String? name, List<TemplateDrawer>? drawers, DateTime? updatedAt, String? updatedByName}) =>
      CartTemplate(
        id: id ?? this.id,
        institutionId: institutionId,
        name: name ?? this.name,
        drawers: drawers ?? this.drawers,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedByName: updatedByName ?? this.updatedByName,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'institutionId': institutionId,
        'name': name,
        'drawers': [for (final d in drawers) d.toJson()],
        'updatedAt': updatedAt.toIso8601String(),
        'updatedByName': updatedByName,
      };

  factory CartTemplate.fromJson(Map<String, Object?> json) => CartTemplate(
        id: json['id'] as String,
        institutionId: json['institutionId'] as String,
        name: json['name'] as String? ?? '',
        drawers: [
          for (final d in (json['drawers'] as List? ?? const [])) TemplateDrawer.fromJson((d as Map).cast<String, Object?>()),
        ],
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        updatedByName: json['updatedByName'] as String? ?? '',
      );
}

class TemplateDrawer {
  const TemplateDrawer({required this.name, required this.rows, required this.columns, this.slots = const [], this.products = const []});

  final String name;
  final int rows;
  final int columns;

  /// Layout (merged slots). Empty = one slot per grid cell.
  final List<Slot> slots;

  /// Target products per slot id.
  final List<TemplateSlotProduct> products;

  int get positionCount => slots.isEmpty ? rows * columns : slots.length;

  Map<String, Object?> toJson() => {
        'name': name,
        'rows': rows,
        'columns': columns,
        'slots': [
          for (final s in slots) {'id': s.id, ...s.toMap()},
        ],
        'products': [for (final p in products) p.toJson()],
      };

  factory TemplateDrawer.fromJson(Map<String, Object?> json) => TemplateDrawer(
        name: json['name'] as String? ?? '',
        rows: (json['rows'] as num?)?.toInt() ?? 1,
        columns: (json['columns'] as num?)?.toInt() ?? 1,
        slots: (json['slots'] as List? ?? const []).map((s) {
          final map = (s as Map).cast<String, Object?>();
          return Slot.fromMap(map['id'] as String, '', map);
        }).toList(),
        products: [
          for (final p in (json['products'] as List? ?? const []))
            TemplateSlotProduct.fromJson((p as Map).cast<String, Object?>()),
        ],
      );
}

class TemplateSlotProduct {
  const TemplateSlotProduct({required this.slotId, required this.productId, required this.targetQuantity, this.minimumQuantity});
  final String slotId;
  final String productId;
  final int targetQuantity;
  final int? minimumQuantity;

  Map<String, Object?> toJson() =>
      {'slotId': slotId, 'productId': productId, 'targetQuantity': targetQuantity, 'minimumQuantity': minimumQuantity};

  factory TemplateSlotProduct.fromJson(Map<String, Object?> json) => TemplateSlotProduct(
        slotId: json['slotId'] as String,
        productId: json['productId'] as String,
        targetQuantity: (json['targetQuantity'] as num?)?.toInt() ?? 1,
        minimumQuantity: (json['minimumQuantity'] as num?)?.toInt(),
      );
}
