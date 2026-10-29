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
    final cartDrawers = List.of(await drawers.watchDrawers(institutionId, cartId).first)
      ..sort((a, b) => (a.number ?? 1 << 20).compareTo(b.number ?? 1 << 20));
    final assignments = await inventory.watchAssignments(institutionId, cartId).first;
    final placed = <String>{};
    final result = <TemplateDrawer>[];
    for (final (index, drawer) in cartDrawers.indexed) {
      final slots = await drawers.watchSlots(institutionId, cartId, drawer.id).first;
      final ids = slots.isEmpty
          ? [for (var r = 0; r < drawer.rows; r++) for (var c = 0; c < drawer.columns; c++) 'r${r}c$c']
          : slots.map((s) => s.id).toList();
      // A placement belongs to its `drawerId`; an old one without it to the
      // first drawer that has its slot id (as CartLiveData.drawerOf does).
      final bySlot = <String, CartProductAssignment>{
        for (final a in assignments)
          if (!placed.contains(a.id) && (a.drawerId == drawer.id || (a.drawerId == null && ids.contains(a.slotId)))) a.slotId: a,
      };
      placed.addAll(bySlot.values.map((a) => a.id));
      result.add(TemplateDrawer(
        number: drawer.number ?? index + 1,
        rows: drawer.rows,
        columns: drawer.columns,
        slots: slots,
        products: [
          for (final id in ids)
            if (bySlot[id] case final a?)
              TemplateSlotProduct(slotId: id, productId: a.productId, targetQuantity: a.targetQuantity),
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
    final created = <(TemplateDrawer, CartDrawer)>[];
    for (final t in template.drawers) {
      // The drawer and its layout are written together (no slot is ever
      // deleted and rewritten); an empty template layout = one slot per cell.
      final drawer = await drawers.createDrawer(
        institutionId,
        cart.id,
        CartDrawer(id: '', cartId: cart.id, number: t.number, rows: t.rows, columns: t.columns),
        slots: t.slots.isEmpty
            ? null
            : [
                for (final s in t.slots)
                  Slot(id: s.id, drawerId: '', row: s.row, column: s.column, rowSpan: s.rowSpan, columnSpan: s.columnSpan, label: s.label),
              ],
      );
      created.add((t, drawer));
    }
    // Products are assigned after every drawer exists. A product may sit in
    // only one slot per cart, so duplicates in a template are skipped.
    final placed = <String>{};
    for (final (t, drawer) in created) {
      for (final p in t.products) {
        if (!placed.add(p.productId)) continue;
        await inventory.createAssignment(
          institutionId,
          cart.id,
          CartProductAssignment(
            id: '',
            cartId: cart.id,
            drawerId: drawer.id,
            slotId: p.slotId,
            productId: p.productId,
            currentQuantity: 0,
            targetQuantity: p.targetQuantity,
          ),
        );
      }
    }
    return cart;
  }
}
