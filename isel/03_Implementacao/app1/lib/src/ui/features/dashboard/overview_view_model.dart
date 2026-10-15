import '../../../common/app_services.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_product_assignment.dart';
import '../../../domain/entities/cart_report.dart';
import '../../../domain/entities/cart_status.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/shift.dart';
import '../../../domain/entities/usage_event.dart';
import '../../../domain/inventory_health.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../carts/carts_view_model.dart';

/// One line of "Atividade recente": a stock event or a report.
class ActivityItem {
  const ActivityItem({required this.at, this.event, this.report});
  final DateTime at;
  final UsageEvent? event;
  final CartReport? report;
}

/// B1 · Visão geral.
class OverviewViewModel extends ViewModel {
  OverviewViewModel(this.services, this.session) {
    final id = session.institution.id;
    listen(services.carts.watchAccessibleCarts(id), (v) {
      _carts = v;
      state = LoadState.ready;
      _rebuild();
    }, onError: (_) {
      state = LoadState.error;
      notify();
    });
    listen(services.inventory.watchAllAssignments(id), (v) {
      _assignments = v;
      _rebuild();
    }, onError: (_) {});
    listen(services.reports.watchReports(id), (v) {
      _reports = v;
      _rebuild();
    });
    listen(services.shifts.watchShifts(id), (v) {
      _shifts = v;
      _rebuild();
    });
    listen(services.usage.watchRecentEvents(id, limit: 20), (v) {
      _events = v;
      notify();
    }, onError: (_) {});
    listen(services.products.watchProducts(id), (v) {
      products = {for (final p in v) p.id: p};
      notify();
    }, onError: (_) {});
    session.addListener(_rebuild);
  }

  final AppServices services;
  final SessionController session;

  LoadState state = LoadState.loading;
  List<Cart> _carts = const [];
  List<CartProductAssignment> _assignments = const [];
  List<CartReport> _reports = const [];
  List<ShiftAssignment> _shifts = const [];
  List<UsageEvent> _events = const [];
  Map<String, Product> products = const {};
  List<CartSummary> summaries = const [];

  Map<String, Cart> get cartsById => {for (final c in _carts) c.id: c};

  int get operational => summaries.where((s) => s.cart.status == CartStatus.operational).length;
  int get needReplenishment => summaries.where((s) => s.cart.status == CartStatus.replenishmentRequired).length;

  /// Expiring within 30 days, and in how many carts.
  (int count, int carts) get expiringSoon {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 30));
    final hits = _assignments.where((a) {
      final e = a.earliestKnownExpiry;
      return e != null && e.isAfter(now) && !e.isAfter(limit);
    }).toList();
    return (hits.length, hits.map((a) => a.cartId).toSet().length);
  }

  List<CartSummary> get overdueChecks => summaries.where((s) => s.checkOverdueDays != null).toList();

  /// Emergency summaries this month and the units they recorded.
  (int count, int units) get emergenciesThisMonth {
    final now = DateTime.now();
    final month = _reports.where((r) =>
        r.kind == ReportKind.emergencySummary && r.createdAt.year == now.year && r.createdAt.month == now.month);
    return (month.length, month.fold(0, (sum, r) => sum + r.lines.fold(0, (s, l) => s + l.amount)));
  }

  List<CartSummary> get needingAttention => summaries.where((s) => s.needsAttention).toList();

  List<ActivityItem> get activity {
    final items = [
      for (final e in _events)
        if (e.serverTimestamp != null) ActivityItem(at: e.serverTimestamp!, event: e),
      for (final r in _reports) ActivityItem(at: r.signedAt ?? r.createdAt, report: r),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return items.take(8).toList();
  }

  String positionOf(UsageEvent e) {
    final slotId = _assignments.where((a) => a.id == e.assignmentId).firstOrNull?.slotId;
    return slotId == null ? '' : (positionFromSlotId(slotId) ?? '');
  }

  void _rebuild() {
    summaries = CartSummaries.build(
      carts: _carts,
      assignments: _assignments,
      reports: _reports,
      shifts: _shifts,
      session: session,
      now: DateTime.now(),
    );
    notify();
  }

  @override
  void dispose() {
    session.removeListener(_rebuild);
    super.dispose();
  }
}
