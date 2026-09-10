import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/l10n/app_localizations.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_product_assignment.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/slot.dart';
import 'assignment_dialog.dart';

/// Finds a product already stocked in this cart by name (spec section 41:
/// daily management lets a professional identify what they used either by
/// navigating the virtual drawer, or — faster when they already know the
/// name — by searching for it directly). Because a product may only exist
/// once per cart, a match uniquely identifies its assignment, so a result
/// opens the same assignment dialog the drawer view would.
class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key, required this.cart, required this.canManage});

  final Cart cart;
  final bool canManage;

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  late final Future<List<Product>> _products =
      AppServicesScope.of(context).products.watchProducts(widget.cart.institutionId).first;

  // Cached once: the search field calls `setState` on every keystroke, and
  // a fresh `watchAssignments(...)` call would otherwise re-subscribe the
  // Firestore listener on every keystroke instead of just re-filtering
  // already-received assignments.
  late final Stream<List<CartProductAssignment>> _assignmentsStream =
      AppServicesScope.of(context).inventory.watchAssignments(widget.cart.institutionId, widget.cart.id);

  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Product? _productFor(List<Product> products, String productId) {
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: Theme.of(context).textTheme.titleMedium,
          decoration: InputDecoration(hintText: l10n.productSearchHint, border: InputBorder.none),
          onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
        ),
      ),
      body: StreamBuilder<List<CartProductAssignment>>(
        stream: _assignmentsStream,
        builder: (context, assignmentsSnapshot) {
          return FutureBuilder<List<Product>>(
            future: _products,
            builder: (context, productsSnapshot) {
              final products = productsSnapshot.data ?? const <Product>[];
              final assignments = assignmentsSnapshot.data ?? const <CartProductAssignment>[];
              final results = <(CartProductAssignment, Product)>[
                for (final assignment in assignments)
                  if (_productFor(products, assignment.productId) case final product?)
                    if (_query.isEmpty || product.name.toLowerCase().contains(_query)) (assignment, product),
              ];

              if (_query.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.productSearchPrompt, textAlign: TextAlign.center),
                  ),
                );
              }
              if (results.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.productSearchEmpty, textAlign: TextAlign.center),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final (assignment, product) = results[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.medication_outlined),
                      title: Text(product.name),
                      subtitle: Text('${assignment.currentQuantity}/${assignment.targetQuantity}'),
                      onTap: () => showAssignmentDialog(
                        context,
                        institutionId: widget.cart.institutionId,
                        cartId: widget.cart.id,
                        slot: Slot(id: assignment.slotId, drawerId: '', row: 0, column: 0),
                        assignment: assignment,
                        products: products,
                        canManage: widget.canManage,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
