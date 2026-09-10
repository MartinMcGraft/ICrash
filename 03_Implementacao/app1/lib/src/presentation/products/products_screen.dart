import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/l10n/app_localizations.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/product.dart';
import 'create_product_dialog.dart';

/// Institution-wide product catalogue (spec section 21). Manager+ only for
/// creation; `firestore.rules` is the real boundary (`isManagerOrAbove` on
/// `products` writes) — the FAB gating here only avoids showing a control
/// that would fail.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.institutionId, required this.canManage});

  final String institutionId;
  final bool canManage;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  Future<void> _createProduct(BuildContext context) async {
    final services = AppServicesScope.of(context);
    final input = await showCreateProductDialog(context);
    if (input == null || !context.mounted) return;
    try {
      await services.products.createProduct(
        widget.institutionId,
        Product(id: '', institutionId: widget.institutionId, name: input.name, unitDescription: input.unitDescription, gtin: input.gtin),
      );
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).productsCreateError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.productsScreenTitle)),
      body: StreamBuilder<List<Product>>(
        stream: services.products.watchProducts(widget.institutionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.productsLoadError(snapshot.error!)),
              ),
            );
          }
          final products = snapshot.data ?? const <Product>[];
          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.productsEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.medication_outlined),
                  title: Text(product.name),
                  subtitle: product.unitDescription != null ? Text(product.unitDescription!) : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: () => _createProduct(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.createProductTitle),
            )
          : null,
    );
  }
}
