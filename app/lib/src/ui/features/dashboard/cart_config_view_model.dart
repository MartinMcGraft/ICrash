import '../../../common/app_services.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_drawer.dart';
import '../../../domain/entities/cart_status.dart';
import '../../../domain/entities/cart_template.dart';
import '../../../domain/inventory_health.dart';
import '../../core/cart_live_data.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

/// B3 · Carrinho — configuração.
class CartConfigViewModel extends ViewModel {
  CartConfigViewModel(this.services, this.session, this.cartId) {
    data = CartLiveData(services: services, institutionId: session.institution.id, cartId: cartId, onChanged: notify);
    listen(services.cartSettings.watchAutoStatusCarts(session.institution.id), (ids) {
      autoStatus = ids.contains(cartId);
      notify();
    });
    listen(services.templates.watchTemplates(session.institution.id), (t) {
      _templates = t;
      notify();
    });
  }

  final AppServices services;
  final SessionController session;
  final String cartId;
  late final CartLiveData data;

  bool autoStatus = false;
  List<CartTemplate> _templates = const [];

  Cart? get cart => data.cart;
  bool get ready => data.ready;
  String? get templateName => _templates.where((t) => t.id == cart?.templateId).firstOrNull?.name;

  List<(int number, CartDrawer drawer, DrawerHealth health)> get drawers => [
        for (final d in data.drawers)
          (data.numberOf(d), d, data.healthOf(d, expiryWarningDays: session.institution.expiryWarningDays)),
      ];

  /// Default number for "Adicionar gaveta": the lowest one not in use.
  int get nextDrawerNumber => data.nextFreeNumber;

  /// Whether a manager may change this drawer's number (Q8, 29 Oct): only a
  /// drawer created before numbers were stored, or one never used. "Used"
  /// (`usedAt`) arrives with the structure lock (P1/P2).
  bool canEditNumber(CartDrawer drawer) => true;

  Future<ActionResult<void>> save({required String name, String? service, String? location}) {
    final current = cart;
    return run(() async {
      if (current == null) return;
      await services.sync.track(services.carts.updateCart(
        session.institution.id,
        Cart(
          id: current.id,
          institutionId: current.institutionId,
          name: name,
          status: current.status,
          layoutVersion: current.layoutVersion,
          templateId: current.templateId,
          service: service,
          location: location,
          archived: current.archived,
        ),
      ));
    });
  }

  Future<ActionResult<void>> setStatus(CartStatus status) {
    final current = cart;
    return run(() async {
      if (current == null) return;
      await services.sync.track(services.carts.updateCart(session.institution.id, current.copyWith(status: status)));
    });
  }

  Future<ActionResult<void>> setAutoStatus(bool enabled) =>
      run(() => services.cartSettings.setAutoStatus(session.institution.id, cartId, enabled));

  /// D15: archive instead of delete (Rules forbid deleting carts).
  Future<ActionResult<void>> archive() {
    final current = cart;
    return run(() async {
      if (current == null) return;
      await services.carts.updateCart(session.institution.id, current.copyWith(archived: true));
    });
  }

  /// "Adicionar gaveta". The drawer gets its slots (one per cell) in the same
  /// write. Error code `drawerNumberTaken` (P17: number unique in the cart).
  Future<ActionResult<void>> addDrawer({required int number, required int rows, required int columns}) {
    final current = cart;
    return run(() async {
      if (current == null) return;
      if (number < 1) throw const ActionError('drawerNumberInvalid');
      if (data.usedNumbers.contains(number)) throw const ActionError('drawerNumberTaken');
      await services.drawers.createDrawer(
        session.institution.id,
        cartId,
        CartDrawer(id: '', cartId: cartId, number: number, rows: rows, columns: columns),
      );
      await services.carts.updateCart(session.institution.id, current.copyWith(layoutVersion: current.layoutVersion + 1));
    });
  }

  /// "Alterar número" on a drawer row (Q8). Error codes `drawerNumberTaken`,
  /// `drawerInUse`.
  Future<ActionResult<void>> setDrawerNumber(CartDrawer drawer, int number) => run(() async {
        if (!canEditNumber(drawer)) throw const ActionError('drawerInUse');
        if (number < 1) throw const ActionError('drawerNumberInvalid');
        if (number == data.numberOf(drawer) && drawer.number != null) return;
        if (data.drawers.any((d) => d.id != drawer.id && data.numberOf(d) == number)) {
          throw const ActionError('drawerNumberTaken');
        }
        await services.drawers.updateDrawer(session.institution.id, cartId, drawer.copyWith(number: number));
      });

  @override
  void dispose() {
    data.dispose();
    super.dispose();
  }
}
