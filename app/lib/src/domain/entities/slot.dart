/// A physical compartment position inside a [CartDrawer].
/// Path: `institutions/{institutionId}/carts/{cartId}/drawers/{drawerId}/slots/{id}`.
///
/// Rectangular-only for the current prototype (spec section 37): `rowSpan`/
/// `columnSpan` cover merged cells without needing arbitrary L/T shapes.
class Slot {
  const Slot({
    required this.id,
    required this.drawerId,
    required this.row,
    required this.column,
    this.rowSpan = 1,
    this.columnSpan = 1,
    this.label,
  });

  final String id;
  final String drawerId;
  final int row;
  final int column;
  final int rowSpan;
  final int columnSpan;
  final String? label;

  factory Slot.fromMap(String id, String drawerId, Map<String, Object?> map) {
    return Slot(
      id: id,
      drawerId: drawerId,
      row: (map['row'] as num?)?.toInt() ?? 0,
      column: (map['column'] as num?)?.toInt() ?? 0,
      rowSpan: (map['rowSpan'] as num?)?.toInt() ?? 1,
      columnSpan: (map['columnSpan'] as num?)?.toInt() ?? 1,
      label: map['label'] as String?,
    );
  }

  /// One 1×1 slot per grid cell, ids `r{row}c{col}`, rows and columns
  /// 0-based (they become 1-based when the data moves to PostgreSQL). Used
  /// when a drawer is created, so every drawer has slot documents.
  static List<Slot> unitGrid(String drawerId, int rows, int columns) => [
        for (var r = 0; r < rows; r++)
          for (var c = 0; c < columns; c++) Slot(id: 'r${r}c$c', drawerId: drawerId, row: r, column: c),
      ];

  Map<String, Object?> toMap() => {
        'row': row,
        'column': column,
        'rowSpan': rowSpan,
        'columnSpan': columnSpan,
        if (label != null) 'label': label,
      };
}
