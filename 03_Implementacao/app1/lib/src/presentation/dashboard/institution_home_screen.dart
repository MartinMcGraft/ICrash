import 'package:flutter/material.dart';
import 'package:icrash_app/home_menu.dart';

import '../../common/app_services.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_status.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/role.dart';
import '../../domain/entities/usage_event.dart';
import '../cart/assignment_status_label.dart';
import '../cart/cart_detail_screen.dart';
import '../cart/cart_status_label.dart';
import '../cart/create_cart_dialog.dart';
import '../members/members_screen.dart';
import '../products/products_screen.dart';
import '../reports/history_screen.dart';

/// Per-institution home (spec section 49): a small dashboard — cart-status
/// counts and recent activity — above the accessible-cart list, with a
/// name filter for fast access when there are many carts. Per-slot
/// alerts (expiring/expired products across every cart) would need an
/// institution-wide `assignments` collectionGroup query and a matching
/// Rules change, deliberately deferred — see docs/AI_HANDOFF.md. Keeps the
/// legacy `HomeMenu` reachable via a button, per the "preserve existing
/// functionality" rule, without wiring any new code to the obsolete Django
/// `RequestHandler`.
class InstitutionHomeScreen extends StatefulWidget {
  const InstitutionHomeScreen({super.key, required this.institution});

  final Institution institution;

  @override
  State<InstitutionHomeScreen> createState() => _InstitutionHomeScreenState();
}

class _InstitutionHomeScreenState extends State<InstitutionHomeScreen> {
  late final Future<Membership?> _myMembership = AppServicesScope.of(context)
      .institutions
      .getMyMembership(widget.institution.id);
  late final Future<List<Product>> _products =
      AppServicesScope.of(context).products.watchProducts(widget.institution.id).first;

  String _searchQuery = '';

  bool _canManageCarts(Membership? membership) {
    if (membership == null || !membership.isActive) return false;
    return membership.role == Role.institutionAdmin ||
        membership.role == Role.manager ||
        membership.role == Role.platformSuperAdmin;
  }

  bool _isInstitutionAdmin(Membership? membership) {
    if (membership == null || !membership.isActive) return false;
    return membership.role == Role.institutionAdmin || membership.role == Role.platformSuperAdmin;
  }

  Future<void> _createCart(BuildContext context) async {
    final name = await showCreateCartDialog(context);
    if (name == null || !context.mounted) return;
    final services = AppServicesScope.of(context);
    try {
      await services.carts.createCart(widget.institution.id, Cart(id: '', institutionId: widget.institution.id, name: name));
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível criar o carro. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.institution.name),
        actions: [
          IconButton(
            tooltip: 'Histórico',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HistoryScreen(institutionId: widget.institution.id)),
            ),
          ),
          FutureBuilder<Membership?>(
            future: _myMembership,
            builder: (context, snapshot) {
              if (!_canManageCarts(snapshot.data)) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Produtos',
                icon: const Icon(Icons.medication_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductsScreen(institutionId: widget.institution.id, canManage: true),
                  ),
                ),
              );
            },
          ),
          FutureBuilder<Membership?>(
            future: _myMembership,
            builder: (context, snapshot) {
              if (!_isInstitutionAdmin(snapshot.data)) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Membros',
                icon: const Icon(Icons.group_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MembersScreen(institution: widget.institution)),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Aplicação anterior (referência)',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HomeMenu()),
            ),
          ),
          IconButton(
            tooltip: 'Terminar sessão',
            icon: const Icon(Icons.logout),
            onPressed: () => services.auth.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Cart>>(
        stream: services.carts.watchAccessibleCarts(widget.institution.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Não foi possível carregar os carros: ${snapshot.error}'),
              ),
            );
          }
          final carts = snapshot.data ?? const <Cart>[];
          if (carts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ainda não existem carros de emergência nesta instituição.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final query = _searchQuery.trim().toLowerCase();
          final filtered = query.isEmpty ? carts : carts.where((c) => c.name.toLowerCase().contains(query)).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _CartStatusSummary(carts: carts),
              ),
              _RecentActivity(institutionId: widget.institution.id, products: _products),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Pesquisar carro',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Nenhum carro corresponde à pesquisa.', textAlign: TextAlign.center),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final cart = filtered[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.medical_services_outlined),
                              title: Text(cart.name),
                              subtitle: Text(cartStatusLabel(cart.status)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => CartDetailScreen(cart: cart)),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<Membership?>(
        future: _myMembership,
        builder: (context, snapshot) {
          if (!_canManageCarts(snapshot.data)) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _createCart(context),
            icon: const Icon(Icons.add),
            label: const Text('Novo carro'),
          );
        },
      ),
    );
  }
}

/// Cart-status counts (spec section 49: "carts operational", "replenishment
/// required", "audit overdue" are all derived from [Cart.status], already
/// available from the same stream the list below uses — no extra query).
class _CartStatusSummary extends StatelessWidget {
  const _CartStatusSummary({required this.carts});

  final List<Cart> carts;

  @override
  Widget build(BuildContext context) {
    final counts = <CartStatus, int>{for (final status in CartStatus.values) status: 0};
    for (final cart in carts) {
      counts[cart.status] = (counts[cart.status] ?? 0) + 1;
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final status in CartStatus.values)
          if (counts[status]! > 0) Chip(label: Text('${cartStatusLabel(status)}: ${counts[status]}')),
      ],
    );
  }
}

/// Institution-wide recent stock activity (spec section 49's "recent
/// relevant activity"), one of the few dashboard signals that does not need
/// a per-cart or cross-cart query: [UsageRepository.watchRecentEvents] is
/// already scoped to the whole institution.
class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.institutionId, required this.products});

  final String institutionId;
  final Future<List<Product>> products;

  String _productName(List<Product> products, String productId) {
    for (final product in products) {
      if (product.id == productId) return product.name;
    }
    return 'Produto removido';
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return StreamBuilder<List<UsageEvent>>(
      stream: services.usage.watchRecentEvents(institutionId, limit: 5),
      builder: (context, eventsSnapshot) {
        final events = eventsSnapshot.data ?? const <UsageEvent>[];
        if (events.isEmpty) return const SizedBox.shrink();
        return FutureBuilder<List<Product>>(
          future: products,
          builder: (context, productsSnapshot) {
            final productList = productsSnapshot.data ?? const <Product>[];
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Atividade recente', style: Theme.of(context).textTheme.labelLarge),
                  for (final event in events)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${usageEventTypeLabel(event.type)} · ${_productName(productList, event.productId)} '
                        '(${event.amount > 0 ? '+' : ''}${event.amount})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
