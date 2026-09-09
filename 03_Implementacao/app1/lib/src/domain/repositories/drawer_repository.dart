import '../entities/cart_drawer.dart';
import '../entities/slot.dart';

abstract class DrawerRepository {
  Stream<List<CartDrawer>> watchDrawers(String institutionId, String cartId);

  Future<CartDrawer> createDrawer(String institutionId, String cartId, CartDrawer drawer);

  Future<void> updateDrawer(String institutionId, String cartId, CartDrawer drawer);

  Stream<List<Slot>> watchSlots(String institutionId, String cartId, String drawerId);

  /// Replaces the full slot layout for a drawer in one call, since merge/
  /// split editing (spec section 36) naturally produces a new complete set
  /// of non-overlapping slots rather than incremental edits.
  Future<void> replaceSlots(String institutionId, String cartId, String drawerId, List<Slot> slots);
}
