import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/registered_device.dart';
import '../../domain/repositories/device_repository.dart';
import 'local_store.dart';

const _key = 'icrash.local.device';
const _fallbackKey = 'device';

/// D17: a registered tablet keeps its own sign-in in the OS keychain /
/// keystore (Android, iOS). Other platforms aren't registered as tablets in
/// practice; there the [LocalStore] is used (no keychain entitlement needed
/// on macOS debug builds).
class SecureDeviceCredentialStore implements DeviceCredentialStore {
  SecureDeviceCredentialStore(this._fallback);

  final LocalStore _fallback;
  static const _secure = FlutterSecureStorage();

  bool get _useSecure =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<DeviceCredentials?> load() async {
    try {
      final Object? data;
      if (_useSecure) {
        final raw = await _secure.read(key: _key);
        data = raw == null ? null : jsonDecode(raw);
      } else {
        data = await _fallback.read(_fallbackKey);
      }
      return data is Map ? DeviceCredentials.fromJson(data.cast<String, Object?>()) : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(DeviceCredentials credentials) async {
    if (_useSecure) {
      await _secure.write(key: _key, value: jsonEncode(credentials.toJson()));
    } else {
      await _fallback.write(_fallbackKey, credentials.toJson());
    }
  }

  @override
  Future<void> clear() async {
    if (_useSecure) {
      await _secure.delete(key: _key);
    } else {
      await _fallback.write(_fallbackKey, null);
    }
  }
}

/// In memory, for tests.
class InMemoryDeviceCredentialStore implements DeviceCredentialStore {
  DeviceCredentials? value;

  @override
  Future<DeviceCredentials?> load() async => value;

  @override
  Future<void> save(DeviceCredentials credentials) async => value = credentials;

  @override
  Future<void> clear() async => value = null;
}
