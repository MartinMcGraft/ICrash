import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/common/l10n/app_localizations.dart';
import 'package:icrash_app/src/common/locale_scope.dart';
import 'package:icrash_app/src/data/firebase/firebase_bootstrap.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/presentation/auth/login_screen.dart';
import 'package:icrash_app/src/presentation/common/connectivity_banner.dart';
import 'package:icrash_app/src/presentation/institution/institution_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localePrefsKey = 'locale';

/// Defaults to PT-PT regardless of the device's own system locale — this
/// app is deployed in Portugal first — rather than following
/// `MaterialApp`'s usual system-locale resolution; a user can still switch
/// to English from `LocaleScope`, and that choice is what [_loadSavedLocale]
/// persists (spec section 13).
const _defaultLocale = Locale('pt', 'PT');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebase = await bootstrapFirebase();
  runApp(
    MyApp(
      services: AppServices(auth: firebase.auth, firestore: firebase.firestore),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.services});

  final AppServices services;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = _defaultLocale;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedLocale());
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefsKey);
    if (code == null || !mounted) return;
    setState(() => _locale = Locale(code));
  }

  Future<void> _setLocale(Locale locale) async {
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefsKey, locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return AppServicesScope(
      services: widget.services,
      child: LocaleScope(
        locale: _locale,
        setLocale: (locale) => unawaited(_setLocale(locale)),
        child: MaterialApp(
          title: 'I-Crash',
          theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          // `builder`, not `home`, so the banner persists across every pushed
          // route (Navigator.push replaces `home`'s content entirely, but
          // `builder` wraps the whole navigator).
          builder: (context, child) => ConnectivityBanner(child: child!),
          home: const _AuthGate(),
        ),
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        return user == null
            ? const LoginScreen()
            : const InstitutionSelectionScreen();
      },
    );
  }
}
