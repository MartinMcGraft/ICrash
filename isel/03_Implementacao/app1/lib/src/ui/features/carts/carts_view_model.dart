import '../../../common/app_services.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_product_assignment.dart';
import '../../../domain/entities/cart_report.dart';
import '../../../domain/entities/cart_status.dart';
import '../../../domain/entities/shift.dart';
import '../../../domain/inventory_health.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

enum CartsFilter { all, attention, mine }

/// Monthly checks older than this are overdue (B3 rule text: "Verificação
/// mensal com mais de 31 dias → Verificação em atraso").
const monthlyCheckMaxAgeDays = 31;

/// Everything one cart card shows (A4, B2, B1 tables).
class CartSummary {
  const CartSummary({
    required this.cart,
    required this.counts,
    required this.lastCheck,
    required this.checkOverdueDays,
    required this.emergencyActive,
    required this.mine,
  });

  final Cart cart;
  final HealthCounts counts;

  /// Last signed-or-not monthly check report, if any.
  final CartReport? lastCheck;

  /// Days past the 31-day limit, or null when not overdue.
  final int? checkOverdueDays;
  final bool emergencyActive;

  /// On shift for this cart now (or a normal user's own cart).
  final bool mine;

  bool get needsAttention =>
      emergencyActive || cart.status != CartStatus.operational || !counts.allOk || checkOverdueDays != null;
}

/// Builds [CartSummary]s from the live repositories. Shared by A4 (App) and
/// B1/B2 (Dashboard) so both show the same numbers.
class CartSummaries {
  static List<CartSummary> build({
    required List<Cart> carts,
    required List<CartProductAssignment> assignments,
    required List<CartReport> reports,
    required List<ShiftAssignment> shifts,
    required SessionController session,
    required DateTime now,
  }) {
    final byCart = <String, List<CartProductAssignment>>{};
    for (final a in assignments) {
      byCart.putIfAbsent(a.cartId, () => []).add(a);
    }
    final lastCheck = <String, CartReport>{};
    for (final r in reports) {
      if (r.kind != ReportKind.monthlyCheck) continue;
      final current = lastCheck[r.cartId];
      if (current == null || r.createdAt.isAfter(current.createdAt)) lastCheck[r.cartId] = r;
    }
    final period = ShiftPeriodHours.at(now);
    final today = DateTime(now.year, now.month, now.day);
    final myCarts = {
      for (final s in shifts)
        if (s.uid == session.user.uid && s.period == period && DateTime(s.day.year, s.day.month, s.day.day) == today) s.cartId,
    };
    final warningDays = session.institution.expiryWarningDays;
    CartSummary summarize(Cart cart) {
      final check = lastCheck[cart.id];
      final reference = check?.createdAt ?? cart.createdAt;
      final age = reference == null ? null : now.difference(reference).inDays;
      return CartSummary(
        cart: cart,
        counts: InventoryHealth.count(byCart[cart.id] ?? const [], expiryWarningDays: warningDays, now: now),
        lastCheck: check,
        checkOverdueDays: age != null && age > monthlyCheckMaxAgeDays ? age - monthlyCheckMaxAgeDays : null,
        emergencyActive: session.isEmergencyActive(cart.id),
        mine: myCarts.contains(cart.id) || !session.isManager,
      );
    }

    return [
      for (final cart in carts)
        if (!cart.archived) summarize(cart),
    ];
  }
}

/// A4 · Carrinhos (and A12, the same screen offline).
class CartsViewModel extends ViewModel {
  CartsViewModel(this.services, this.session) {
    final id = session.institution.id;
    listen(services.carts.watchAccessibleCarts(id), (carts) {
      _carts = carts;
      state = LoadState.ready;
      _rebuild();
    }, onError: (_) {
      state = LoadState.error;
      notify();
    });
    listen(services.inventory.watchAllAssignments(id), (assignments) {
      _assignments = assignments;
      _rebuild();
    }, onError: (_) {
      // Cross-cart reads may be denied for some roles: cards still show
      // their state, just without stock alerts.
      alertsUnavailable = true;
      notify();
    });
    listen(services.reports.watchReports(id), (reports) {
      _reports = reports;
      _rebuild();
    });
    listen(services.shifts.watchShifts(id), (shifts) {
      _shifts = shifts;
      _rebuild();
    });
    session.addListener(_rebuild);
  }

  final AppServices services;
  final SessionController session;

  LoadState state = LoadState.loading;
  bool alertsUnavailable = false;
  CartsFilter filter = CartsFilter.all;
  String query = '';

  List<Cart> _carts = const [];
  List<CartProductAssignment> _assignments = const [];
  List<CartReport> _reports = const [];
  List<ShiftAssignment> _shifts = const [];
  List<CartSummary> _all = const [];

  int get total => _all.length;
  int get attentionCount => _all.where((s) => s.needsAttention).length;
  int get mineCount => _all.where((s) => s.mine).length;

  List<CartSummary> get visible {
    final q = query.trim().toLowerCase();
    final list = _all.where((s) {
      final matchesFilter = switch (filter) {
        CartsFilter.all => true,
        CartsFilter.attention => s.needsAttention,
        CartsFilter.mine => s.mine,
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return '${s.cart.name} ${s.cart.service ?? ''} ${s.cart.location ?? ''}'.toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) {
      if (a.needsAttention != b.needsAttention) return a.needsAttention ? -1 : 1;
      return a.cart.name.compareTo(b.cart.name);
    });
    return list;
  }

  void setFilter(CartsFilter value) {
    filter = value;
    notify();
  }

  void setQuery(String value) {
    query = value;
    notify();
  }

  void _rebuild() {
    _all = CartSummaries.build(
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
