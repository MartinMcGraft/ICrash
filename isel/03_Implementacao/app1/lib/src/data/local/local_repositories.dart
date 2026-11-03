// STUB (local only) — see local_store.dart for why these exist.
//
// Every class here implements a domain repository interface with
// device-local storage. Swap them for Firestore implementations in
// `AppServices` once the matching product decision is made:
//   LocalDeviceSessionRepository  — D3 (PIN; device-local by design)
//   LocalReportRepository         — D4/D6 (monthly check + signing)
//   LocalEmergencyRepository      — §9 (emergency mode)
//   LocalTemplateRepository       — B6 templates
//   LocalShiftRepository          — D8 shifts
//   LocalPermissionRepository     — D2 permissions
//   LocalCartSettingsRepository   — D7 automatic state rule

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../common/repository_failure.dart';
import '../../domain/entities/app_permission.dart';
import '../../domain/entities/cart_report.dart';
import '../../domain/entities/cart_template.dart';
import '../../domain/entities/emergency_session.dart';
import '../../domain/entities/role.dart';
import '../../domain/entities/shift.dart';
import '../../domain/repositories/cart_settings_repository.dart';
import '../../domain/repositories/device_session_repository.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../../domain/repositories/permission_repository.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/repositories/shift_repository.dart';
import '../../domain/repositories/template_repository.dart';
import 'local_store.dart';

String _newId() {
  final random = Random.secure();
  return List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
}

// ---------------------------------------------------------------------------
// Device session + PIN (D3)
// ---------------------------------------------------------------------------

class LocalDeviceSessionRepository implements DeviceSessionRepository {
  LocalDeviceSessionRepository(this._store);
  final LocalStore _store;

  static const _userKey = 'device.user';
  String _pinKey(String uid) => 'device.pin.$uid';

  @override
  Future<RememberedUser?> rememberedUser() async {
    final raw = await _store.read(_userKey);
    if (raw is! Map) return null;
    return RememberedUser.fromJson(raw.cast<String, Object?>());
  }

  @override
  Future<void> remember(RememberedUser user) => _store.write(_userKey, user.toJson());

  @override
  Future<void> forget() => _store.write(_userKey, null);

  @override
  Future<bool> hasPin(String uid) async => await _store.read(_pinKey(uid)) is Map;

  @override
  Future<void> setPin(String uid, String pin) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const RepositoryFailure(RepositoryFailureReason.invalidInput);
    }
    final salt = _newId();
    await _store.write(_pinKey(uid), {'salt': salt, 'hash': _hash(salt, pin)});
  }

  @override
  Future<bool> verifyPin(String uid, String pin) async {
    final raw = await _store.read(_pinKey(uid));
    if (raw is! Map) return false;
    return raw['hash'] == _hash(raw['salt'] as String, pin);
  }

  static String _hash(String salt, String pin) => sha256.convert(utf8.encode('$salt:$pin')).toString();
}

// ---------------------------------------------------------------------------
// Reports (D4/D6)
// ---------------------------------------------------------------------------

class LocalReportRepository implements ReportRepository {
  LocalReportRepository(this._store);
  final LocalStore _store;
  final Map<String, LocalJsonList<CartReport>> _lists = {};

  LocalJsonList<CartReport> _list(String institutionId) => _lists.putIfAbsent(
        institutionId,
        () => LocalJsonList(_store, 'reports.$institutionId', CartReport.fromJson, (r) => r.toJson()),
      );

  @override
  Stream<List<CartReport>> watchReports(String institutionId) => _list(institutionId).watch().map(
        (reports) => List.of(reports)..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  @override
  Future<CartReport> createReport(CartReport report) async {
    final created = CartReport.fromJson({...report.toJson(), 'id': report.id.isEmpty ? _newId() : report.id});
    await _list(report.institutionId).update((current) => [...current, created]);
    return created;
  }

  @override
  Future<void> signReport(String institutionId, String reportId, {required String uid, required String name}) async {
    await _list(institutionId).update((current) => [
          for (final report in current)
            if (report.id == reportId)
              (report.isSigned
                  ? throw const RepositoryFailure(RepositoryFailureReason.conflict)
                  : report.signed(uid: uid, name: name, at: DateTime.now()))
            else
              report,
        ]);
  }

  String _draftKey(String institutionId, String cartId) => 'checkDraft.$institutionId.$cartId';

  @override
  Future<Map<String, Object?>?> loadCheckDraft(String institutionId, String cartId) async {
    final raw = await _store.read(_draftKey(institutionId, cartId));
    return raw is Map ? raw.cast<String, Object?>() : null;
  }

  @override
  Future<void> saveCheckDraft(String institutionId, String cartId, Map<String, Object?> draft) =>
      _store.write(_draftKey(institutionId, cartId), draft);

  @override
  Future<void> clearCheckDraft(String institutionId, String cartId) => _store.write(_draftKey(institutionId, cartId), null);
}

// ---------------------------------------------------------------------------
// Emergency mode (§9)
// ---------------------------------------------------------------------------

class LocalEmergencyRepository implements EmergencyRepository {
  LocalEmergencyRepository(this._store);
  final LocalStore _store;
  final Map<String, LocalJsonList<EmergencySession>> _lists = {};

  LocalJsonList<EmergencySession> _list(String institutionId) => _lists.putIfAbsent(
        institutionId,
        () => LocalJsonList(_store, 'emergency.$institutionId', EmergencySession.fromJson, (s) => s.toJson()),
      );

  @override
  Stream<List<EmergencySession>> watchActive(String institutionId) => _list(institutionId).watch();

  @override
  Future<EmergencySession> start(EmergencySession session) async {
    final list = _list(session.institutionId);
    final existing = (await list.load()).where((s) => s.cartId == session.cartId).firstOrNull;
    if (existing != null) return existing;
    await list.update((current) => [...current, session]);
    return session;
  }

  @override
  Future<EmergencySession> addConsumption(String institutionId, String cartId, EmergencyConsumption consumption) async {
    final list = _list(institutionId);
    final current = List.of(await list.load());
    final index = current.indexWhere((s) => s.cartId == cartId);
    if (index < 0) throw const RepositoryFailure(RepositoryFailureReason.notFound);
    final updated = current[index].withConsumptions([...current[index].consumptions, consumption]);
    current[index] = updated;
    await list.save(current);
    return updated;
  }

  @override
  Future<EmergencyConsumption?> removeLast(String institutionId, String cartId) async {
    final list = _list(institutionId);
    final current = List.of(await list.load());
    final index = current.indexWhere((s) => s.cartId == cartId);
    if (index < 0 || current[index].consumptions.isEmpty) return null;
    final session = current[index];
    final removed = session.consumptions.last;
    current[index] = session.withConsumptions(session.consumptions.sublist(0, session.consumptions.length - 1));
    await list.save(current);
    return removed;
  }

  @override
  Future<EmergencySession?> end(String institutionId, String cartId) async {
    EmergencySession? ended;
    await _list(institutionId).update((current) {
      ended = current.where((s) => s.cartId == cartId).firstOrNull;
      return [for (final s in current) if (s.cartId != cartId) s];
    });
    return ended;
  }
}

// ---------------------------------------------------------------------------
// Templates (B6)
// ---------------------------------------------------------------------------

class LocalTemplateRepository implements TemplateRepository {
  LocalTemplateRepository(this._store);
  final LocalStore _store;
  final Map<String, LocalJsonList<CartTemplate>> _lists = {};

  LocalJsonList<CartTemplate> _list(String institutionId) => _lists.putIfAbsent(
        institutionId,
        () => LocalJsonList(_store, 'templates.$institutionId', CartTemplate.fromJson, (t) => t.toJson()),
      );

  @override
  Stream<List<CartTemplate>> watchTemplates(String institutionId) =>
      _list(institutionId).watch().map((items) => List.of(items)..sort((a, b) => a.name.compareTo(b.name)));

  @override
  Future<CartTemplate> saveTemplate(CartTemplate template) async {
    final saved = template.id.isEmpty ? template.copyWith(id: _newId()) : template;
    await _list(template.institutionId).update((current) => [
          for (final t in current)
            if (t.id != saved.id) t,
          saved,
        ]);
    return saved;
  }

  @override
  Future<void> deleteTemplate(String institutionId, String templateId) =>
      _list(institutionId).update((current) => [for (final t in current) if (t.id != templateId) t]);
}

// ---------------------------------------------------------------------------
// Shifts (D8)
// ---------------------------------------------------------------------------

class LocalShiftRepository implements ShiftRepository {
  LocalShiftRepository(this._store);
  final LocalStore _store;
  final Map<String, LocalJsonList<ShiftAssignment>> _lists = {};

  LocalJsonList<ShiftAssignment> _list(String institutionId) => _lists.putIfAbsent(
        institutionId,
        () => LocalJsonList(_store, 'shifts.$institutionId', ShiftAssignment.fromJson, (s) => s.toJson()),
      );

  @override
  Stream<List<ShiftAssignment>> watchShifts(String institutionId) => _list(institutionId).watch();

  @override
  Future<void> setShift(String institutionId, ShiftAssignment shift) =>
      _list(institutionId).update((current) => [for (final s in current) if (s.key != shift.key) s, shift]);

  @override
  Future<void> clearShift(String institutionId, ShiftAssignment shift) =>
      _list(institutionId).update((current) => [for (final s in current) if (s.key != shift.key) s]);
}

// ---------------------------------------------------------------------------
// Permissions (D2)
// ---------------------------------------------------------------------------

class LocalPermissionRepository implements PermissionRepository {
  LocalPermissionRepository(this._store);
  final LocalStore _store;
  final Map<String, StreamController<Map<Role, Set<AppPermission>>>> _controllers = {};

  String _key(String institutionId) => 'permissions.$institutionId';

  Future<Map<Role, Set<AppPermission>>> _load(String institutionId) async {
    final raw = await _store.read(_key(institutionId));
    final result = {for (final role in Role.values) role: defaultPermissionsFor(role)};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final role = Role.values.where((r) => r.name == entry.key).firstOrNull;
        if (role == null || entry.value is! List) continue;
        result[role] = {
          for (final name in entry.value as List)
            ?AppPermission.values.where((p) => p.name == name).firstOrNull,
        };
      }
    }
    return result;
  }

  @override
  Stream<Map<Role, Set<AppPermission>>> watchPermissions(String institutionId) async* {
    final controller = _controllers.putIfAbsent(institutionId, () => StreamController.broadcast());
    yield await _load(institutionId);
    yield* controller.stream;
  }

  @override
  Future<void> setPermission(String institutionId, Role role, AppPermission permission, bool granted) async {
    final current = await _load(institutionId);
    final set = {...current[role]!};
    granted ? set.add(permission) : set.remove(permission);
    current[role] = set;
    await _store.write(_key(institutionId), {
      for (final entry in current.entries) entry.key.name: [for (final p in entry.value) p.name],
    });
    _controllers.putIfAbsent(institutionId, () => StreamController.broadcast()).add(current);
  }
}

// ---------------------------------------------------------------------------
// Automatic cart state (D7)
// ---------------------------------------------------------------------------

class LocalCartSettingsRepository implements CartSettingsRepository {
  LocalCartSettingsRepository(this._store);
  final LocalStore _store;
  final Map<String, StreamController<Set<String>>> _controllers = {};

  String _key(String institutionId) => 'autoStatus.$institutionId';

  Future<Set<String>> _load(String institutionId) async {
    final raw = await _store.read(_key(institutionId));
    return raw is List ? raw.whereType<String>().toSet() : <String>{};
  }

  @override
  Stream<Set<String>> watchAutoStatusCarts(String institutionId) async* {
    final controller = _controllers.putIfAbsent(institutionId, () => StreamController.broadcast());
    yield await _load(institutionId);
    yield* controller.stream;
  }

  @override
  Future<void> setAutoStatus(String institutionId, String cartId, bool enabled) async {
    final set = await _load(institutionId);
    enabled ? set.add(cartId) : set.remove(cartId);
    await _store.write(_key(institutionId), set.toList());
    _controllers.putIfAbsent(institutionId, () => StreamController.broadcast()).add(set);
  }
}
