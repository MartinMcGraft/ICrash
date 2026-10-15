import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../firebase_options.dart';
import '../../common/app_environment.dart';

/// A `demo-` prefixed project needs no real credentials and is exactly what
/// `.firebaserc`'s local alias (`demo-icrash-v2`) and `firebase.json`'s
/// `singleProjectMode` emulator config expect to see.
///
/// CRITICAL: pointing the *cloud* project's `FirebaseOptions`
/// (`DefaultFirebaseOptions.currentPlatform`, projectId `i-crash-pt-2026`) at
/// the emulator host/port is NOT enough on its own. `useAuthEmulator`/
/// `useFirestoreEmulator` only redirect the network connection; the SDK still
/// tags every request with the app's configured project id. Confirmed
/// empirically: Firestore's emulator then reports "No matching allow
/// statements" for a `collectionGroup` query even though the exact same
/// rules and data succeed under the matching demo project id —
/// `singleProjectMode`'s cross-project-id tolerance does not reliably extend
/// to rules evaluation. So emulator mode uses its own `FirebaseOptions` with
/// the demo project id instead.
const _demoFirebaseOptions = FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:000000000000:web:0000000000000000000000',
  messagingSenderId: '000000000000',
  projectId: AppEnvironment.emulatorProjectId,
);

/// Name of the secondary [FirebaseApp] used in emulator mode. It cannot
/// reuse `[DEFAULT]`: on Android/iOS/macOS, the native Firebase SDK
/// auto-initializes the default app from `google-services.json`/
/// `GoogleService-Info.plist` (the real `i-crash-pt-2026` project) before
/// any Dart code runs, so calling `Firebase.initializeApp()` again for
/// `[DEFAULT]` with different (demo) options throws `[core/duplicate-app]`.
/// A separate named app sidesteps that entirely.
const _emulatorAppName = 'icrash-emulator';

/// The [FirebaseAuth]/[FirebaseFirestore] instances the rest of the app
/// should use — [AppServices] wires repositories to these rather than the
/// bare `.instance` singletons, since emulator mode resolves to a different
/// (named, demo-project) [FirebaseApp] than the default one.
class FirebaseServices {
  const FirebaseServices({required this.auth, required this.firestore});

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
}

/// A throwaway [FirebaseAuth] instance, on its own uniquely-named
/// [FirebaseApp], for creating another user's Auth account (e.g. an
/// institution admin adding a new member) without disturbing the current
/// user's session: `createUserWithEmailAndPassword` signs in as the newly
/// created user on whichever [FirebaseAuth] instance it is called on, and
/// there is no Cloud Function yet (spec Phase 1 has none) to do this
/// server-side instead. Callers must `await result.app.delete()` once done
/// with it. Uses the same emulator-vs-cloud choice as [bootstrapFirebase].
Future<FirebaseAuth> createIsolatedAccountCreationAuth() async {
  final isEmulator = AppEnvironment.isEmulator;
  final app = await Firebase.initializeApp(
    name: 'icrash-account-creation-${DateTime.now().microsecondsSinceEpoch}',
    options: isEmulator ? _demoFirebaseOptions : DefaultFirebaseOptions.currentPlatform,
  );
  final isolatedAuth = FirebaseAuth.instanceFor(app: app);
  if (isEmulator) {
    await isolatedAuth.useAuthEmulator(AppEnvironment.emulatorHost, AppEnvironment.authEmulatorPort);
  }
  return isolatedAuth;
}

/// Initializes Firebase and, in development, points Auth/Firestore at the
/// local emulator suite instead of the cloud project `i-crash-pt-2026`
/// (see [AppEnvironment]). Call once before `runApp`.
Future<FirebaseServices> bootstrapFirebase() async {
  // Always initialize the default app: on native platforms it typically
  // already exists (auto-initialized from the platform config file) and
  // this call is a no-op attach; on web it is the only initialization.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!AppEnvironment.isEmulator) {
    return FirebaseServices(auth: FirebaseAuth.instance, firestore: FirebaseFirestore.instance);
  }

  final emulatorApp = await Firebase.initializeApp(name: _emulatorAppName, options: _demoFirebaseOptions);
  final auth = FirebaseAuth.instanceFor(app: emulatorApp);
  final firestore = FirebaseFirestore.instanceFor(app: emulatorApp);

  final host = AppEnvironment.emulatorHost;
  await auth.useAuthEmulator(host, AppEnvironment.authEmulatorPort);
  firestore.useFirestoreEmulator(host, AppEnvironment.firestoreEmulatorPort);

  if (kDebugMode) {
    debugPrint(
      'I-Crash: using Firebase emulators at $host '
      '(auth:${AppEnvironment.authEmulatorPort}, firestore:${AppEnvironment.firestoreEmulatorPort}, '
      'project:${AppEnvironment.emulatorProjectId})',
    );
  }

  return FirebaseServices(auth: auth, firestore: firestore);
}
