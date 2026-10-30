import '../entities/cart.dart';
import '../entities/cart_status.dart';
import '../entities/cart_responsible_user.dart';

abstract class CartRepository {
  /// Carts within [institutionId] visible to the current user: every cart
  /// for managers/admins, only assigned carts for a normal user
  /// (spec section 17).
  Stream<List<Cart>> watchAccessibleCarts(String institutionId);

  Future<Cart?> getCart(String institutionId, String cartId);

  Future<Cart> createCart(String institutionId, Cart cart);

  Future<void> updateCart(String institutionId, Cart cart);

  /// Changes only the cart's state (A5 "Alterar estado", D7 auto-state, the
  /// end of an emergency). D16: a Manager registered to the cart may do this
  /// and nothing else on the cart document.
  Future<void> updateCartStatus(String institutionId, String cartId, CartStatus status);

  Stream<List<CartResponsibleUser>> watchResponsibleUsers(String institutionId, String cartId);

  Future<void> assignResponsibleUser(String institutionId, String cartId, String uid);

  Future<void> removeResponsibleUser(String institutionId, String cartId, String uid);
}
