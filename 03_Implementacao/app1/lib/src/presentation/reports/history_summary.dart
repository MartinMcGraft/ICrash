import '../../domain/entities/cart.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/usage_event.dart';

/// Per-product totals within a list of usage events (spec section 51's
/// aggregate-reports requirement). [summarizeByCart] and [summarizeByPeriod]
/// below cover the same requirement's other two grouping dimensions. Pure
/// and Flutter-independent, so all three are unit-tested directly.
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

List<ProductUsageSummary> summarizeByProduct(
  List<UsageEvent> events,
  List<Product> products,
) {
  final consumedByProduct = <String, int>{};
  final replenishedByProduct = <String, int>{};
  final otherByProduct = <String, int>{};

  for (final event in events) {
    switch (event.type) {
      case UsageEventType.consumption:
        consumedByProduct[event.productId] =
            (consumedByProduct[event.productId] ?? 0) - event.amount;
      case UsageEventType.replenishment:
        replenishedByProduct[event.productId] =
            (replenishedByProduct[event.productId] ?? 0) + event.amount;
      case UsageEventType.correction:
      case UsageEventType.auditReconciliation:
        otherByProduct[event.productId] =
            (otherByProduct[event.productId] ?? 0) + event.amount;
    }
  }

  String nameFor(String productId) {
    for (final product in products) {
      if (product.id == productId) return product.name;
    }
    return 'Produto removido';
  }

  final productIds = {
    ...consumedByProduct.keys,
    ...replenishedByProduct.keys,
    ...otherByProduct.keys,
  };
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

/// Per-cart totals, grouping the same three [UsageEvent] categories as
/// [summarizeByProduct] but by [UsageEvent.cartId] instead of product —
/// spec section 51's per-cart aggregate.
class CartUsageSummary {
  const CartUsageSummary({
    required this.cartId,
    required this.cartName,
    required this.consumed,
    required this.replenished,
    required this.otherAdjustments,
  });

  final String cartId;
  final String cartName;
  final int consumed;
  final int replenished;
  final int otherAdjustments;
}

List<CartUsageSummary> summarizeByCart(
  List<UsageEvent> events,
  List<Cart> carts,
) {
  final consumedByCart = <String, int>{};
  final replenishedByCart = <String, int>{};
  final otherByCart = <String, int>{};

  for (final event in events) {
    switch (event.type) {
      case UsageEventType.consumption:
        consumedByCart[event.cartId] =
            (consumedByCart[event.cartId] ?? 0) - event.amount;
      case UsageEventType.replenishment:
        replenishedByCart[event.cartId] =
            (replenishedByCart[event.cartId] ?? 0) + event.amount;
      case UsageEventType.correction:
      case UsageEventType.auditReconciliation:
        otherByCart[event.cartId] =
            (otherByCart[event.cartId] ?? 0) + event.amount;
    }
  }

  String nameFor(String cartId) {
    for (final cart in carts) {
      if (cart.id == cartId) return cart.name;
    }
    return 'Carro removido';
  }

  final cartIds = {
    ...consumedByCart.keys,
    ...replenishedByCart.keys,
    ...otherByCart.keys,
  };
  final summaries = [
    for (final cartId in cartIds)
      CartUsageSummary(
        cartId: cartId,
        cartName: nameFor(cartId),
        consumed: consumedByCart[cartId] ?? 0,
        replenished: replenishedByCart[cartId] ?? 0,
        otherAdjustments: otherByCart[cartId] ?? 0,
      ),
  ];
  summaries.sort((a, b) => a.cartName.compareTo(b.cartName));
  return summaries;
}

/// Grouping granularity for [summarizeByPeriod].
enum SummaryPeriodUnit { day, week, month }

/// Per-period totals, bucketing events by the calendar day/week/month
/// [UsageEvent.serverTimestamp] falls in (a week starts on Monday) — spec
/// section 51's per-period aggregate. An event with no `serverTimestamp` yet
/// (an offline write still queued for sync) is skipped, matching how
/// `buildHistoryCsv` treats the same case.
class PeriodUsageSummary {
  const PeriodUsageSummary({
    required this.periodStart,
    required this.consumed,
    required this.replenished,
    required this.otherAdjustments,
  });

  /// Start (local midnight) of the day/week/month this bucket covers.
  final DateTime periodStart;
  final int consumed;
  final int replenished;
  final int otherAdjustments;
}

DateTime _periodStart(DateTime timestamp, SummaryPeriodUnit unit) {
  final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
  switch (unit) {
    case SummaryPeriodUnit.day:
      return day;
    case SummaryPeriodUnit.week:
      return day.subtract(Duration(days: day.weekday - DateTime.monday));
    case SummaryPeriodUnit.month:
      return DateTime(timestamp.year, timestamp.month);
  }
}

List<PeriodUsageSummary> summarizeByPeriod(
  List<UsageEvent> events,
  SummaryPeriodUnit unit,
) {
  final consumedByPeriod = <DateTime, int>{};
  final replenishedByPeriod = <DateTime, int>{};
  final otherByPeriod = <DateTime, int>{};

  for (final event in events) {
    final timestamp = event.serverTimestamp;
    if (timestamp == null) continue;
    final period = _periodStart(timestamp, unit);
    switch (event.type) {
      case UsageEventType.consumption:
        consumedByPeriod[period] =
            (consumedByPeriod[period] ?? 0) - event.amount;
      case UsageEventType.replenishment:
        replenishedByPeriod[period] =
            (replenishedByPeriod[period] ?? 0) + event.amount;
      case UsageEventType.correction:
      case UsageEventType.auditReconciliation:
        otherByPeriod[period] = (otherByPeriod[period] ?? 0) + event.amount;
    }
  }

  final periods = {
    ...consumedByPeriod.keys,
    ...replenishedByPeriod.keys,
    ...otherByPeriod.keys,
  };
  final summaries = [
    for (final period in periods)
      PeriodUsageSummary(
        periodStart: period,
        consumed: consumedByPeriod[period] ?? 0,
        replenished: replenishedByPeriod[period] ?? 0,
        otherAdjustments: otherByPeriod[period] ?? 0,
      ),
  ];
  summaries.sort((a, b) => a.periodStart.compareTo(b.periodStart));
  return summaries;
}
