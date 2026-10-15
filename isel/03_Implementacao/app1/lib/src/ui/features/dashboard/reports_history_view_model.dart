import '../../../common/app_services.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_product_assignment.dart';
import '../../../domain/entities/cart_report.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/usage_event.dart';
import '../../../domain/inventory_health.dart';
import '../../../domain/reports/history_csv_export.dart';
import '../../../domain/reports/history_summary.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

enum ReportsHistoryTab { reports, events, statistics }

/// B9 · Relatórios e histórico.
class ReportsHistoryViewModel extends ViewModel {
  ReportsHistoryViewModel(this.services, this.session, {required this.tab, DateTime? now})
      : month = DateTime((now ?? DateTime.now()).year, (now ?? DateTime.now()).month) {
    final id = session.institution.id;
    listen(services.reports.watchReports(id), (v) {
      _reports = v;
      state = LoadState.ready;
      notify();
    }, onError: (_) {
      state = LoadState.error;
      notify();
    });
    listen(services.usage.watchRecentEvents(id, limit: eventLimit), (v) {
      _events = v;
      notify();
    }, onError: (_) {});
    listen(services.carts.watchAccessibleCarts(id), (v) {
      carts = List.of(v)..sort((a, b) => a.name.compareTo(b.name));
      notify();
    }, onError: (_) {});
    listen(services.products.watchProducts(id), (v) {
      _products = v;
      notify();
    }, onError: (_) {});
    listen(services.inventory.watchAllAssignments(id), (v) {
      _assignments = {for (final a in v) a.id: a};
      notify();
    }, onError: (_) {});
  }

  /// Events are read from the most recent N (Firestore query cap). The
  /// screen says so when the cap is reached (audit U9).
  static const eventLimit = 500;

  final AppServices services;
  final SessionController session;

  LoadState state = LoadState.loading;
  ReportsHistoryTab tab;

  /// `null` = every cart.
  String? cartId;

  /// First day of the selected month.
  DateTime month;

  List<Cart> carts = const [];
  List<CartReport> _reports = const [];
  List<UsageEvent> _events = const [];
  List<Product> _products = const [];
  Map<String, CartProductAssignment> _assignments = const {};

  bool get eventsCapped => _events.length >= eventLimit;

  void setTab(ReportsHistoryTab value) {
    tab = value;
    notify();
  }

  void setCart(String? value) {
    cartId = value;
    notify();
  }

  void setMonth(DateTime value) {
    month = DateTime(value.year, value.month);
    notify();
  }

  /// The last 12 months, newest first (period menu).
  List<DateTime> get recentMonths {
    final now = DateTime.now();
    return [for (var i = 0; i < 12; i++) DateTime(now.year, now.month - i)];
  }

  bool _inScope(String eventCartId, DateTime? at) {
    if (cartId != null && eventCartId != cartId) return false;
    if (at == null) return false;
    return at.year == month.year && at.month == month.month;
  }

  String? get cartName => carts.where((c) => c.id == cartId).firstOrNull?.name;

  List<CartReport> get reports => _reports.where((r) => _inScope(r.cartId, r.createdAt)).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<UsageEvent> get events => _events.where((e) => _inScope(e.cartId, e.serverTimestamp)).toList()
    ..sort((a, b) => b.serverTimestamp!.compareTo(a.serverTimestamp!));

  Map<String, Cart> get cartsById => {for (final c in carts) c.id: c};
  Map<String, Product> get productsById => {for (final p in _products) p.id: p};

  String positionOf(UsageEvent e) {
    final slotId = _assignments[e.assignmentId]?.slotId;
    return slotId == null ? '' : (positionFromSlotId(slotId) ?? '');
  }

  // --- Estatísticas
  int get consumedUnits => events.where((e) => e.type == UsageEventType.consumption).fold(0, (s, e) => s - e.amount);
  int get replenishedUnits => events.where((e) => e.type == UsageEventType.replenishment).fold(0, (s, e) => s + e.amount);
  int get checksDone => reports.where((r) => r.kind == ReportKind.monthlyCheck).length;
  int get emergencies => reports.where((r) => r.kind == ReportKind.emergencySummary).length;
  int get pendingSignatures => reports.where((r) => !r.isSigned).length;

  /// Most consumed products first.
  List<ProductUsageSummary> productSummary({required String removedLabel}) =>
      summarizeByProduct(events, _products, removedLabel: removedLabel)..sort((a, b) => b.consumed.compareTo(a.consumed));

  List<CartUsageSummary> cartSummary({required String removedLabel}) =>
      summarizeByCart(events, carts, removedLabel: removedLabel)..sort((a, b) => b.consumed.compareTo(a.consumed));

  /// "Exportar CSV": the events in scope (when, where, what, who).
  String exportCsv({required String removedProduct, required String removedCart}) {
    final products = productsById;
    final byId = cartsById;
    return buildEventsCsv([
      for (final e in events)
        EventCsvRow(
          when: e.serverTimestamp,
          cart: byId[e.cartId]?.name ?? removedCart,
          place: positionOf(e),
          product: products[e.productId]?.name ?? removedProduct,
          type: e.type,
          amount: e.amount,
          user: session.nameOf(e.actorUid),
        ),
    ]);
  }
}
