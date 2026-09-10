import '../../domain/entities/product.dart';
import '../../domain/entities/usage_event.dart';

/// Per-product totals within a list of usage events (spec section 51's
/// aggregate-reports requirement, scoped to a single grouping dimension —
/// product — for this prototype; per-cart/per-period aggregates are still
/// deferred). Pure and Flutter-independent, so it is unit-tested directly.
class ProductUsageSummary {
  const ProductUsageSummary({
    required this.productId,
    required this.productName,
    required this.consumed,
    required this.replenished,
    required this.otherAdjustments,
  });

  final String productId;
  final String productName;

  /// Total consumed, always non-negative (consumption events carry a
  /// negative [UsageEvent.amount]; this is its magnitude).
  final int consumed;

  /// Total replenished, always non-negative.
  final int replenished;

  /// Net of correction/reconciliation events — can be positive or negative.
  final int otherAdjustments;
}

List<ProductUsageSummary> summarizeByProduct(List<UsageEvent> events, List<Product> products) {
  final consumedByProduct = <String, int>{};
  final replenishedByProduct = <String, int>{};
  final otherByProduct = <String, int>{};

  for (final event in events) {
    switch (event.type) {
      case UsageEventType.consumption:
        consumedByProduct[event.productId] = (consumedByProduct[event.productId] ?? 0) - event.amount;
      case UsageEventType.replenishment:
        replenishedByProduct[event.productId] = (replenishedByProduct[event.productId] ?? 0) + event.amount;
      case UsageEventType.correction:
      case UsageEventType.auditReconciliation:
        otherByProduct[event.productId] = (otherByProduct[event.productId] ?? 0) + event.amount;
    }
  }

  String nameFor(String productId) {
    for (final product in products) {
      if (product.id == productId) return product.name;
    }
    return 'Produto removido';
  }

  final productIds = {...consumedByProduct.keys, ...replenishedByProduct.keys, ...otherByProduct.keys};
  final summaries = [
    for (final productId in productIds)
      ProductUsageSummary(
        productId: productId,
        productName: nameFor(productId),
        consumed: consumedByProduct[productId] ?? 0,
        replenished: replenishedByProduct[productId] ?? 0,
        otherAdjustments: otherByProduct[productId] ?? 0,
      ),
  ];
  summaries.sort((a, b) => a.productName.compareTo(b.productName));
  return summaries;
}
