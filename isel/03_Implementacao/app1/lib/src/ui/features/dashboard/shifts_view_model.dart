import '../../../common/app_services.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/role.dart';
import '../../../domain/entities/shift.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

enum ShiftsView { byCart, byPerson }

/// B8 · Turnos (proposal D8: one health professional responsible per cart
/// per shift).
class ShiftsViewModel extends ViewModel {
  ShiftsViewModel(this.services, this.session, {DateTime? today}) : weekStart = mondayOf(today ?? DateTime.now()) {
    final id = session.institution.id;
    listen(services.shifts.watchShifts(id), (v) {
      _shifts = v;
      state = LoadState.ready;
      notify();
    }, onError: (_) {
      state = LoadState.error;
      notify();
    });
    listen(services.carts.watchAccessibleCarts(id), (v) {
      carts = v.where((c) => !c.archived).toList()..sort((a, b) => a.name.compareTo(b.name));
      notify();
    }, onError: (_) {});
    listen(services.institutions.watchMembers(id), (v) {
      members = v.where((m) => m.status != MembershipStatus.disabled).toList()
        ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      notify();
    }, onError: (_) {});
  }

  final AppServices services;
  final SessionController session;

  LoadState state = LoadState.loading;
  ShiftsView view = ShiftsView.byCart;
  DateTime weekStart;
  List<Cart> carts = const [];
  List<Membership> members = const [];
  List<ShiftAssignment> _shifts = const [];

  static DateTime mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  List<DateTime> get days => [for (var i = 0; i < 7; i++) DateTime(weekStart.year, weekStart.month, weekStart.day + i)];
  DateTime get weekEnd => days.last;

  bool get canEdit => session.isManager && session.can(AppPermission.manageUsersAndShifts);

  void previousWeek() {
    weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day - 7);
    notify();
  }

  void nextWeek() {
    weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
    notify();
  }

  void setView(ShiftsView value) {
    view = value;
    notify();
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  ShiftAssignment? shiftAt(String cartId, DateTime day, ShiftPeriod period) =>
      _shifts.where((s) => s.cartId == cartId && s.period == period && _sameDay(s.day, day)).firstOrNull;

  List<ShiftAssignment> shiftsOfPerson(String uid, DateTime day) =>
      _shifts.where((s) => s.uid == uid && _sameDay(s.day, day)).toList()..sort((a, b) => a.period.index.compareTo(b.period.index));

  /// People with at least one shift this week (the "Por pessoa" rows).
  List<Membership> get peopleThisWeek {
    final start = weekStart;
    final end = DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
    final uids = {
      for (final s in _shifts)
        if (!s.day.isBefore(start) && s.day.isBefore(end)) s.uid,
    };
    return members.where((m) => uids.contains(m.uid)).toList();
  }

  /// "Ana Silva" → "Ana S.".
  String shortName(String uid) {
    final parts = session.nameOf(uid).trim().split(RegExp(r'\s+'));
    if (parts.length < 2 || parts.first.contains('@')) return parts.first;
    return '${parts.first} ${parts.last[0]}.';
  }

  String cartName(String cartId) => carts.where((c) => c.id == cartId).firstOrNull?.name ?? '—';

  /// Sets (or, with `uid == null`, clears) who is responsible for a shift.
  Future<ActionResult<void>> assign({required String cartId, required DateTime day, required ShiftPeriod period, String? uid}) =>
      run(() async {
        final id = session.institution.id;
        final existing = shiftAt(cartId, day, period);
        if (uid == null) {
          if (existing != null) await services.shifts.clearShift(id, existing);
          return;
        }
        await services.shifts.setShift(id, ShiftAssignment(cartId: cartId, day: DateTime(day.year, day.month, day.day), period: period, uid: uid));
      });

  /// Copies the previous week's shifts into the current week (only empty slots).
  Future<ActionResult<int>> copyPreviousWeek() => run(() async {
        final id = session.institution.id;
        var copied = 0;
        for (final day in days) {
          final previous = DateTime(day.year, day.month, day.day - 7);
          for (final s in _shifts.where((s) => _sameDay(s.day, previous)).toList()) {
            if (shiftAt(s.cartId, day, s.period) != null) continue;
            await services.shifts.setShift(id, ShiftAssignment(cartId: s.cartId, day: day, period: s.period, uid: s.uid));
            copied++;
          }
        }
        return copied;
      });
}
