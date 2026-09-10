import '../../common/app_services.dart';
import '../../domain/entities/cart.dart';

/// Increments a cart's `layoutVersion` after a structural change to its
/// drawers/slots (spec section 38: "Structure modifications must not destroy
/// historical understanding... use layout versioning or equivalent
/// snapshots"). This only tracks *that* a change happened and roughly when,
/// via the version number — it does not snapshot the actual historical
/// drawer/slot geometry, which nothing reads yet. Fetches the latest copy of
/// the cart first so two structural changes in a row do not stomp on each
/// other's bump.
Future<void> bumpCartLayoutVersion(AppServices services, Cart cart) async {
  final current = await services.carts.getCart(cart.institutionId, cart.id) ?? cart;
  await services.carts.updateCart(
    cart.institutionId,
    Cart(
      id: current.id,
      institutionId: current.institutionId,
      name: current.name,
      status: current.status,
      layoutVersion: current.layoutVersion + 1,
      templateId: current.templateId,
    ),
  );
}
