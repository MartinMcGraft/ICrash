// STUB (local only) — storage for features that have no backend yet.
//
// Design v2 screens such as the monthly check, report signing, emergency
// mode, templates, shifts and per-type permissions have no Firestore model
// yet (product decisions D2–D8 are still open). Their repositories are
// implemented on top of this device-local JSON store so the screens work as
// a demo. Data stays on this device and is NOT shared between devices.
// Replace each `Local*Repository` with a Firestore implementation of the
// same domain interface when the decisions are made.

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStore {
  Future<Object?> read(String key);
  Future<void> write(String key, Object? value);
}

class SharedPreferencesLocalStore implements LocalStore {
  static const _prefix = 'icrash.local.';

  @override
  Future<Object?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    return raw == null ? null : jsonDecode(raw);
  }

  @override
  Future<void> write(String key, Object? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('$_prefix$key');
    } else {
      await prefs.setString('$_prefix$key', jsonEncode(value));
    }
  }
}

/// For tests, and as a safe default when nothing is injected.
class InMemoryLocalStore implements LocalStore {
  final Map<String, Object?> _values = {};

  @override
  Future<Object?> read(String key) async => _values[key] == null ? null : jsonDecode(jsonEncode(_values[key]));

  @override
  Future<void> write(String key, Object? value) async => _values[key] = value;
}

/// A JSON list persisted under one key, with a watchable stream.
class LocalJsonList<T> {
  LocalJsonList(this._store, this._key, this._fromJson, this._toJson);

  final LocalStore _store;
  final String _key;
  final T Function(Map<String, Object?> json) _fromJson;
  final Map<String, Object?> Function(T value) _toJson;
  final _controller = StreamController<List<T>>.broadcast();
  List<T>? _cache;

  Future<List<T>> load() async {
    if (_cache != null) return _cache!;
    final raw = await _store.read(_key);
    final items = <T>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map) {
          try {
            items.add(_fromJson(entry.cast<String, Object?>()));
          } catch (_) {
            // Skip entries written by an older/incompatible stub version.
          }
        }
      }
    }
    return _cache = items;
  }

  Stream<List<T>> watch() async* {
    yield List.unmodifiable(await load());
    yield* _controller.stream;
  }

  Future<void> save(List<T> items) async {
    _cache = List.of(items);
    await _store.write(_key, [for (final item in items) _toJson(item)]);
    _controller.add(List.unmodifiable(items));
  }

  Future<void> update(List<T> Function(List<T> current) change) async {
    final current = List.of(await load());
    await save(change(current));
  }
}
