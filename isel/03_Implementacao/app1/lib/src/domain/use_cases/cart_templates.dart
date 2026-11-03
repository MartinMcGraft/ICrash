import '../entities/cart.dart';
import '../entities/cart_drawer.dart';
import '../entities/cart_product_assignment.dart';
import '../entities/cart_template.dart';
import '../entities/slot.dart';
import '../repositories/cart_repository.dart';
import '../repositories/drawer_repository.dart';
import '../repositories/inventory_repository.dart';

/// Use cases spanning carts, drawers, slots and assignments (MVVM "domain
/// layer": logic that would otherwise be duplicated in several ViewModels).
class CartTemplateUseCases {
  const CartTemplateUseCases({required this.carts, required this.drawers, required this.inventory});

  final CartRepository carts;
  final DrawerRepository drawers;
  final InventoryRepository inventory;

  /// Copies a cart's drawers, layout and target quantities into a template.
  /// Stock and history are never copied.
  Future<CartTemplate> templateFromCart({
    required String institutionId,
    required String cartId,
    required String name,
    required String updatedByName,
  }) async {
    final cartDrawers = await drawers.watchDrawers(institutionId, cartId).first;
    final assignments = await inventory.watchAssignments(institutionId, cartId).first;
    final bySlot = {for (final a in assignments) a.slotId: a};
    final result = <TemplateDrawer>[];
    for (final drawer in cartDrawers) {
      final slots = await drawers.watchSlots(institutionId, cartId, drawer.id).first;
      final ids = slots.isEmpty
          ? [for (var r = 0; r < drawer.rows; r++) for (var c = 0; c < drawer.columns; c++) 'r${r}c$c']
          : slots.map((s) => s.id).toList();
      result.add(TemplateDrawer(
        name: drawer.name,
        rows: drawer.rows,
        columns: drawer.columns,
        slots: slots,
        products: [
          for (final id in ids)
            if (bySlot[id] case final a?)
              TemplateSlotProduct(slotId: id, productId: a.productId, targetQuantity: a.targetQuantity, minimumQuantity: a.minimumQuantity),
        ],
      ));
    }
    return CartTemplate(
      id: '',
      institutionId: institutionId,
      name: name,
      drawers: result,
      updatedAt: DateTime.now(),
      updatedByName: updatedByName,
    );
  }

  /// Creates a cart with the template's drawers, positions and target
  /// quantities (current stock starts at 0).
  Future<Cart> createCartFromTemplate({
    required CartTemplate template,
    required String name,
    String? service,
    String? location,
  }) async {
    final institutionId = template.institutionId;
    final cart = await carts.createCart(
      institutionId,
      Cart(id: '', institutionId: institutionId, name: name, service: service, location: location, templateId: template.id),
    );
    for (final t in template.drawers) {
      final drawer = await drawers.createDrawer(
        institutionId,
        cart.id,
        CartDrawer(id: '', cartId: cart.id, name: t.name, rows: t.rows, columns: t.columns),
      );
      if (t.slots.isNotEmpty) {
        await drawers.replaceSlots(institutionId, cart.id, drawer.id, [
          for (final s in t.slots)
            Slot(id: s.id, drawerId: drawer.id, row: s.row, column: s.column, rowSpan: s.rowSpan, columnSpan: s.columnSpan, label: s.label),
        ]);
      }
    }
    // Products are assigned after every drawer exists. A product may sit in
    // only one slot per cart, so duplicates in a template are skipped.
    final placed = <String>{};
    for (final t in template.drawers) {
      for (final p in t.products) {
        if (!placed.add(p.productId)) continue;
        await inventory.createAssignment(
          institutionId,
          cart.id,
          CartProductAssignment(
            id: '',
            cartId: cart.id,
            slotId: p.slotId,
            productId: p.productId,
            currentQuantity: 0,
            targetQuantity: p.targetQuantity,
            minimumQuantity: p.minimumQuantity,
          ),
        );
      }
    }
    return cart;
  }
}
