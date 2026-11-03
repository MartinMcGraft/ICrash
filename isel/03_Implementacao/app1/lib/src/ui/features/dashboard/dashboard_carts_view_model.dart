import 'dart:async';

import '../../../common/app_services.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_drawer.dart';
import '../../../domain/entities/cart_product_assignment.dart';
import '../../../domain/entities/cart_report.dart';
import '../../../domain/entities/cart_status.dart';
import '../../../domain/entities/cart_template.dart';
import '../../../domain/entities/shift.dart';
import '../../../domain/use_cases/cart_templates.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../carts/carts_view_model.dart';

enum DashboardCartsFilter { all, attention, outOfService }

/// B2 · Carrinhos (table).
class DashboardCartsViewModel extends ViewModel {
  DashboardCartsViewModel(this.services, this.session) {
    final id = session.institution.id;
    listen(services.carts.watchAccessibleCarts(id), (v) {
      _carts = v;
      state = LoadState.ready;
      _syncDrawerSubscriptions();
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
    listen(services.templates.watchTemplates(id), (v) {
      templates = v;
      notify();
    });
  }

  final AppServices services;
  final SessionController session;

  LoadState state = LoadState.loading;
  DashboardCartsFilter filter = DashboardCartsFilter.all;
  String query = '';
  List<CartTemplate> templates = const [];

  List<Cart> _carts = const [];
  List<CartProductAssignment> _assignments = const [];
  List<CartReport> _reports = const [];
  List<ShiftAssignment> _shifts = const [];
  List<CartSummary> _all = const [];
  final Map<String, List<CartDrawer>> _drawers = {};
  final Map<String, StreamSubscription<List<CartDrawer>>> _drawerSubs = {};

  int get total => _all.length;
  int get attentionCount => _all.where((s) => s.needsAttention).length;
  int get outOfServiceCount => _all.where((s) => s.cart.status == CartStatus.outOfService).length;
  int get serviceCount => _all.map((s) => s.cart.service).whereType<String>().toSet().length;

  int? drawerCount(String cartId) => _drawers[cartId]?.length;

  String? responsibleNow(String cartId) {
    final now = DateTime.now();
    final period = ShiftPeriodHours.at(now);
    final shift = _shifts
        .where((s) => s.cartId == cartId && s.period == period && s.day.year == now.year && s.day.month == now.month && s.day.day == now.day)
        .firstOrNull;
    return shift == null ? null : session.nameOf(shift.uid);
  }

  List<CartSummary> get visible {
    final q = query.trim().toLowerCase();
    return _all.where((s) {
      final ok = switch (filter) {
        DashboardCartsFilter.all => true,
        DashboardCartsFilter.attention => s.needsAttention,
        DashboardCartsFilter.outOfService => s.cart.status == CartStatus.outOfService,
      };
      return ok && (q.isEmpty || '${s.cart.name} ${s.cart.service ?? ''} ${s.cart.location ?? ''}'.toLowerCase().contains(q));
    }).toList()
      ..sort((a, b) => a.cart.name.compareTo(b.cart.name));
  }

  void setFilter(DashboardCartsFilter value) {
    filter = value;
    notify();
  }

  void setQuery(String value) {
    query = value;
    notify();
  }

  Future<ActionResult<Cart>> createCart({required String name, String? service, String? location}) => run(() => services.carts.createCart(
        session.institution.id,
        Cart(id: '', institutionId: session.institution.id, name: name, service: service, location: location),
      ));

  Future<ActionResult<Cart>> createFromTemplate(CartTemplate template, {required String name, String? service, String? location}) =>
      run(() => CartTemplateUseCases(carts: services.carts, drawers: services.drawers, inventory: services.inventory)
          .createCartFromTemplate(template: template, name: name, service: service, location: location));

  void _syncDrawerSubscriptions() {
    final ids = _carts.map((c) => c.id).toSet();
    for (final gone in _drawerSubs.keys.where((id) => !ids.contains(id)).toList()) {
      unawaited(_drawerSubs.remove(gone)!.cancel());
    }
    for (final cart in _carts) {
      _drawerSubs.putIfAbsent(
        cart.id,
        () => services.drawers.watchDrawers(session.institution.id, cart.id).listen((d) {
          _drawers[cart.id] = d;
          notify();
        }, onError: (_) {}),
      );
    }
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
    for (final s in _drawerSubs.values) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
