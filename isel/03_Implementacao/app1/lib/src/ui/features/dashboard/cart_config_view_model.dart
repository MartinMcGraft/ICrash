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
        for (final (i, d) in data.drawers.indexed)
          (i + 1, d, data.healthOf(d, expiryWarningDays: session.institution.expiryWarningDays)),
      ];

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

  Future<ActionResult<void>> addDrawer({required String name, required int rows, required int columns}) {
    final current = cart;
    return run(() async {
      if (current == null) return;
      await services.drawers.createDrawer(
        session.institution.id,
        cartId,
        CartDrawer(id: '', cartId: cartId, name: name, rows: rows, columns: columns),
      );
      await services.carts.updateCart(session.institution.id, current.copyWith(layoutVersion: current.layoutVersion + 1));
    });
  }

  @override
  void dispose() {
    data.dispose();
    super.dispose();
  }
}
