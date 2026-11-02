import '../../../common/app_services.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_drawer.dart';
import '../../../domain/entities/cart_report.dart';
import '../../../domain/entities/cart_status.dart';
import '../../../domain/entities/emergency_session.dart';
import '../../../domain/entities/shift.dart';
import '../../../domain/inventory_health.dart';
import '../../core/cart_live_data.dart';
import '../../core/feature_flags.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../carts/carts_view_model.dart' show monthlyCheckMaxAgeDays;

class DrawerRowModel {
  const DrawerRowModel({required this.number, required this.drawer, required this.health});
  final int number;
  final CartDrawer drawer;
  final DrawerHealth health;
}

/// A5 · Carrinho — drawers with a state each, plus the cart menu.
class CartViewModel extends ViewModel {
  CartViewModel(this.services, this.session, this.cartId) {
    data = CartLiveData(services: services, institutionId: session.institution.id, cartId: cartId, onChanged: _onData);
    listen(services.shifts.watchShifts(session.institution.id), (shifts) {
      _shifts = shifts;
      notify();
    });
    listen(services.reports.watchReports(session.institution.id), (reports) {
      pendingSignatures = reports.where((r) => r.cartId == cartId && !r.isSigned && r.createdByUid == session.user.uid).length;
      _lastCheck = reports
          .where((r) => r.cartId == cartId && r.kind == ReportKind.monthlyCheck)
          .fold<CartReport?>(null, (best, r) => best == null || r.createdAt.isAfter(best.createdAt) ? r : best);
      _onData();
    });
    listen(services.cartSettings.watchAutoStatusCarts(session.institution.id), (ids) {
      _autoStatus = ids.contains(cartId);
      _onData();
    });
    session.addListener(notify);
    refreshCheckDraft();
  }

  /// Reports of this cart I made and still have to sign (RV-20 badge).
  int pendingSignatures = 0;

  /// A monthly check was left half-way on this device: "Retomar verificação".
  bool hasCheckDraft = false;

  /// Re-reads the draft, e.g. after coming back from A8.
  Future<void> refreshCheckDraft() async {
    final draft = await services.reports.loadCheckDraft(session.institution.id, cartId);
    if (isDisposed) return;
    hasCheckDraft = draft != null && draft['version'] == 2;
    notify();
  }

  final AppServices services;
  final SessionController session;
  final String cartId;
  late final CartLiveData data;

  List<ShiftAssignment> _shifts = const [];
  CartReport? _lastCheck;
  bool _autoStatus = false;
  bool _applyingAutoStatus = false;

  Cart? get cart => data.cart;
  bool get notFound => data.cartMissing;
  bool get ready => data.ready;
  bool get emergencyActive => session.isEmergencyActive(cartId);
  int get _warningDays => session.institution.expiryWarningDays;

  List<DrawerRowModel> get drawers => [
        for (final drawer in data.drawers)
          DrawerRowModel(number: data.numberOf(drawer), drawer: drawer, health: data.healthOf(drawer, expiryWarningDays: _warningDays)),
      ];

  /// "Responsável no turno: Ana Silva" (proposal D8), or null.
  String? get responsibleOnShift {
    if (!kShiftsEnabled) return null;
    final now = DateTime.now();
    final period = ShiftPeriodHours.at(now);
    final shift = _shifts
        .where((s) =>
            s.cartId == cartId &&
            s.period == period &&
            s.day.year == now.year &&
            s.day.month == now.month &&
            s.day.day == now.day)
        .firstOrNull;
    return shift == null ? null : session.nameOf(shift.uid);
  }

  bool get _checkOverdue {
    final reference = _lastCheck?.createdAt ?? cart?.createdAt;
    return reference != null && DateTime.now().difference(reference).inDays > monthlyCheckMaxAgeDays;
  }

  void _onData() {
    notify();
    _maybeApplyAutoStatus();
  }

  /// D7: when the cart has automatic state on, a manager's client keeps the
  /// stored status in line with the rule.
  Future<void> _maybeApplyAutoStatus() async {
    final current = cart;
    if (!_autoStatus || !session.canChangeCartState || current == null || !data.ready || _applyingAutoStatus) return;
    final next = suggestedCartStatus(
      current: current.status,
      counts: data.cartCounts(expiryWarningDays: _warningDays),
      checkOverdue: _checkOverdue,
    );
    if (next == current.status) return;
    _applyingAutoStatus = true;
    await run(() => services.sync.track(services.carts.updateCartStatus(session.institution.id, current.id, next)));
    _applyingAutoStatus = false;
  }

  Future<ActionResult<void>> changeStatus(CartStatus status) {
    final current = cart;
    if (current == null) return Future.value(const ActionResult.ok(null));
    return run(() => services.sync.track(services.carts.updateCartStatus(session.institution.id, current.id, status)));
  }

  /// Opens (or reuses) the emergency session for this cart.
  Future<ActionResult<void>> startEmergency() {
    final current = cart;
    return run(() async {
      if (current == null) return;
      await services.emergency.start(EmergencySession(
        institutionId: session.institution.id,
        cartId: cartId,
        cartName: current.name,
        startedAt: DateTime.now(),
        startedByUid: session.user.uid,
        startedByName: session.myName,
      ));
    });
  }

  @override
  void dispose() {
    session.removeListener(notify);
    data.dispose();
    super.dispose();
  }
}
