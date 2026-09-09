import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../domain/entities/institution.dart';
import '../dashboard/dashboard_placeholder_screen.dart';

/// Spec section 49: after login, select an institution before anything else
/// is shown. Only institutions the signed-in user has an active membership
/// in are ever returned by [InstitutionRepository.watchMyInstitutions] —
/// this screen never needs to filter unauthorized institutions itself.
class InstitutionSelectionScreen extends StatelessWidget {
  const InstitutionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolher instituição'),
        actions: [
          IconButton(
            tooltip: 'Terminar sessão',
            icon: const Icon(Icons.logout),
            onPressed: () => services.auth.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Institution>>(
        stream: services.institutions.watchMyInstitutions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Não foi possível carregar as instituições: ${snapshot.error}'),
              ),
            );
          }
          final institutions = snapshot.data ?? const <Institution>[];
          if (institutions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ainda não tem acesso a nenhuma instituição.\nContacte o administrador da sua instituição.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: institutions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final institution = institutions[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_hospital_outlined),
                  title: Text(institution.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DashboardPlaceholderScreen(institution: institution)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
