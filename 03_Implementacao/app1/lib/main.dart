import 'package:flutter/material.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/data/firebase/firebase_bootstrap.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/presentation/auth/login_screen.dart';
import 'package:icrash_app/src/presentation/institution/institution_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebase = await bootstrapFirebase();
  runApp(MyApp(services: AppServices(auth: firebase.auth, firestore: firebase.firestore)));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppServicesScope(
      services: services,
      child: MaterialApp(
        title: 'I-Crash',
        theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Routes between the V2 login screen and institution selection based on
/// Firebase Auth state. There is no signed-out-only legacy flow anymore:
/// the legacy screens are still reachable, but only from the dashboard
/// placeholder shown after login (see `DashboardPlaceholderScreen`).
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = AppServicesScope.of(context).auth;
    return StreamBuilder<AuthUser?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        return user == null ? const LoginScreen() : const InstitutionSelectionScreen();
      },
    );
  }
}
