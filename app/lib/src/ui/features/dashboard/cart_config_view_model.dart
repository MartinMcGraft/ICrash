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
  /// drawer never used, or one created before numbers were stored.
  bool canEditNumber(CartDrawer drawer) => drawer.number == null || !data.drawerInUse(drawer);

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
      await services.sync.track(services.carts.updateCartStatus(session.institution.id, current.id, status));
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
  Future<ActionResult<void>> addDrawer({required int number, String? name, required int rows, required int columns}) {
    final current = cart;
    final cleanName = CartDrawer.cleanName(name);
    return run(() async {
      if (current == null) return;
      if (number < 1) throw const ActionError('drawerNumberInvalid');
      if (cleanName != null && cleanName.length > CartDrawer.maxNameLength) throw const ActionError('drawerNameTooLong');
      if (data.usedNumbers.contains(number)) throw const ActionError('drawerNumberTaken');
      await services.drawers.createDrawer(
        session.institution.id,
        cartId,
        CartDrawer(id: '', cartId: cartId, number: number, name: cleanName, rows: rows, columns: columns),
      );
      await services.carts.updateCart(session.institution.id, current.copyWith(layoutVersion: current.layoutVersion + 1));
    });
  }

  /// "Alterar número" on a drawer row (Q8). Error codes `drawerNumberTaken`,
  /// `drawerInUse`.
  Future<ActionResult<void>> setDrawerNumber(CartDrawer drawer, int number) =>
      editDrawer(drawer, number: number, name: drawer.name);

  /// "Editar gaveta" on a drawer row: its number (Q8: only while unused, or
  /// if it never had one) and its optional name (D20: always, even when used;
  /// empty removes it). Error codes `drawerNumberTaken`, `drawerInUse`,
  /// `drawerNameTooLong`.
  Future<ActionResult<void>> editDrawer(CartDrawer drawer, {required int number, String? name}) => run(() async {
        final cleanName = CartDrawer.cleanName(name);
        if (cleanName != null && cleanName.length > CartDrawer.maxNameLength) throw const ActionError('drawerNameTooLong');
        final numberChanged = drawer.number == null || number != data.numberOf(drawer);
        if (numberChanged) {
          if (!canEditNumber(drawer)) throw const ActionError('drawerInUse');
          if (number < 1) throw const ActionError('drawerNumberInvalid');
          if (data.drawers.any((d) => d.id != drawer.id && data.numberOf(d) == number)) {
            throw const ActionError('drawerNumberTaken');
          }
        }
        if (!numberChanged && cleanName == drawer.name) return;
        await services.drawers.updateDrawer(
          session.institution.id,
          cartId,
          drawer.copyWith(number: number, name: cleanName, clearName: cleanName == null),
        );
      });

  @override
  void dispose() {
    data.dispose();
    super.dispose();
  }
}
