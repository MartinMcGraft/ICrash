import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../firebase_options.dart';
import '../../common/app_environment.dart';

/// Initializes Firebase and, in development, points Auth/Firestore at the
/// local emulator suite instead of the cloud project `i-crash-pt-2026`
/// (see [AppEnvironment]). Call once before `runApp`.
Future<void> bootstrapFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!AppEnvironment.isEmulator) {
    return;
  }

  final host = AppEnvironment.emulatorHost;
  await FirebaseAuth.instance.useAuthEmulator(host, AppEnvironment.authEmulatorPort);
  FirebaseFirestore.instance.useFirestoreEmulator(host, AppEnvironment.firestoreEmulatorPort);

  if (kDebugMode) {
    debugPrint(
      'I-Crash: using Firebase emulators at $host '
      '(auth:${AppEnvironment.authEmulatorPort}, firestore:${AppEnvironment.firestoreEmulatorPort})',
    );
  }
}
