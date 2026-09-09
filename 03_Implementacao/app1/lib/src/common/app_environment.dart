import 'package:flutter/foundation.dart';

/// Which Firestore/Auth backend the app talks to.
///
/// Defaults to the local emulator suite in debug builds so development never
/// writes to the cloud project (`i-crash-pt-2026`) by accident. A release
/// build defaults to cloud, since end-user devices have no emulator to reach.
/// Either default can be forced explicitly with
/// `--dart-define=ICRASH_BACKEND=emulator` or `--dart-define=ICRASH_BACKEND=cloud`.
enum FirebaseBackend { emulator, cloud }

class AppEnvironment {
  const AppEnvironment._();

  static const String _override = String.fromEnvironment('ICRASH_BACKEND');

  static FirebaseBackend get backend {
    switch (_override) {
      case 'cloud':
        return FirebaseBackend.cloud;
      case 'emulator':
        return FirebaseBackend.emulator;
      default:
        return kDebugMode ? FirebaseBackend.emulator : FirebaseBackend.cloud;
    }
  }

  static bool get isEmulator => backend == FirebaseBackend.emulator;

  /// Host that reaches `127.0.0.1` of the development machine from the
  /// platform actually running the app. The Android emulator maps its own
  /// loopback interface, so the host machine is reached via `10.0.2.2`
  /// instead; every other supported platform can use `127.0.0.1` directly.
  static String get emulatorHost {
    if (kIsWeb) return '127.0.0.1';
    if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
    return '127.0.0.1';
  }

  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8081;

  /// Must match `.firebaserc`'s `demo-icrash-v2` alias and `firebase.json`'s
  /// `singleProjectMode` emulator configuration.
  static const String emulatorProjectId = 'demo-icrash-v2';
}
