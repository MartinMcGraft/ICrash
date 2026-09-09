import 'package:flutter/material.dart';
import 'package:icrash_app/home_menu.dart';

import '../../common/app_services.dart';
import '../../domain/entities/institution.dart';

/// Stands in for the real dashboard (spec section 49: assigned carts,
/// alerts, expiry/audit status) until workstreams B/C/E/F land. Keeps the
/// legacy screens reachable in the meantime, per the "preserve existing
/// functionality" rule, without wiring any new code to the obsolete
/// Django `RequestHandler`.
class DashboardPlaceholderScreen extends StatelessWidget {
  const DashboardPlaceholderScreen({super.key, required this.institution});

  final Institution institution;

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(institution.name),
        actions: [
          IconButton(
            tooltip: 'Terminar sessão',
            icon: const Icon(Icons.logout),
            onPressed: () => services.auth.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Os carros, gavetas e stock desta instituição ainda estão em construção nesta versão V2.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('Abrir aplicação anterior (referência)'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HomeMenu()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
