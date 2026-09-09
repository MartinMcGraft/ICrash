import 'package:flutter/material.dart';
import 'package:icrash_app/home_menu.dart';

import '../../common/app_services.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/role.dart';
import '../cart/cart_detail_screen.dart';
import '../cart/cart_status_label.dart';
import '../cart/create_cart_dialog.dart';
import '../members/members_screen.dart';

/// Per-institution home: the real cart list (spec section 49's dashboard is
/// still future work — no alerts/expiry summary yet), reachable after
/// picking an institution. Keeps the legacy `HomeMenu` reachable via a
/// button, per the "preserve existing functionality" rule, without wiring
/// any new code to the obsolete Django `RequestHandler`.
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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Cart>>(
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
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: carts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cart = carts[index];
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
                );
              },
            ),
          ),
        ],
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
