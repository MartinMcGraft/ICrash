import '../entities/cart.dart';
import '../entities/cart_responsible_user.dart';

abstract class CartRepository {
  /// Carts within [institutionId] visible to the current user: every cart
  /// for managers/admins, only assigned carts for a normal user
  /// (spec section 17).
  Stream<List<Cart>> watchAccessibleCarts(String institutionId);

  Future<Cart?> getCart(String institutionId, String cartId);

  Future<Cart> createCart(String institutionId, Cart cart);

  Future<void> updateCart(String institutionId, Cart cart);

  Stream<List<CartResponsibleUser>> watchResponsibleUsers(String institutionId, String cartId);

  Future<void> assignResponsibleUser(String institutionId, String cartId, String uid);

  Future<void> removeResponsibleUser(String institutionId, String cartId, String uid);
}
