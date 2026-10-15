import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/common/l10n/app_localizations.dart';
import 'package:icrash_app/src/common/locale_scope.dart';
import 'package:icrash_app/src/data/firebase/firebase_bootstrap.dart';
import 'package:icrash_app/src/ui/app/app_root.dart';
import 'package:icrash_app/src/ui/core/theme/app_theme.dart';
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
  // Design v2 rule: the App is landscape only (phone and tablet). Desktop
  // and web windows are left alone.
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }
  final firebase = await bootstrapFirebase();
  final services = AppServices(auth: firebase.auth, firestore: firebase.firestore);
  services.sync.attachConnectivity();
  runApp(MyApp(services: services));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.services, this.home});

  final AppServices services;

  /// Tests can replace the root.
  final Widget? home;

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
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: widget.home ?? const AppRoot(),
        ),
      ),
    );
  }
}
