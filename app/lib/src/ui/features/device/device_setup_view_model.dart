import '../../../common/app_services.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/institution.dart';
import '../../../domain/entities/registered_device.dart';
import '../../../domain/entities/role.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../core/mvvm/view_model.dart';

enum DeviceSetupStep { signIn, details }

/// A0 · Configurar dispositivo (D17, 30 Oct 2026): I-Crash delivers the
/// tablet with the app; an Admin signs in once with their e-mail and
/// password, names the tablet and picks the carts it serves (at least one).
/// The tablet then gets its own account and the Admin is signed out.
class DeviceSetupViewModel extends ViewModel {
  DeviceSetupViewModel(this.services, {required this.onRegistered});

  static const maxNameLength = 60;

  final AppServices services;

  /// The tablet's credentials were saved; the app root signs it in.
  final Future<void> Function(DeviceCredentials credentials) onRegistered;

  DeviceSetupStep step = DeviceSetupStep.signIn;
  Institution? institution;
  AuthUser? _admin;
  String? adminName;
  List<Cart> carts = const [];
  final Set<String> selected = {};
  String name = '';

  bool get canRegister => name.trim().isNotEmpty && selected.isNotEmpty && !busy;

  /// Step 1. Error codes: `notAdmin` (the account isn't an active Admin of
  /// an institution).
  Future<ActionResult<void>> signIn(String email, String password) => run(() async {
        final user = await services.auth.signInWithEmailPassword(email.trim(), password);
        final list = List.of(await services.institutions.watchMyInstitutions().first)
          ..sort((a, b) => a.name.compareTo(b.name));
        for (final candidate in list) {
          final membership = await services.institutions.getMyMembership(candidate.id);
          if (membership != null && membership.isActive && membership.role == Role.institutionAdmin) {
            institution = candidate;
            adminName = membership.label;
            break;
          }
        }
        final found = institution;
        if (found == null) {
          await services.auth.signOut();
          throw const ActionError('notAdmin');
        }
        _admin = user;
        carts = [
          for (final c in await services.carts.watchAccessibleCarts(found.id).first)
            if (!c.archived) c,
        ]..sort((a, b) => a.name.compareTo(b.name));
        step = DeviceSetupStep.details;
      });

  void setName(String value) {
    name = value;
    notify();
  }

  void toggleCart(String cartId) {
    if (!selected.remove(cartId)) selected.add(cartId);
    notify();
  }

  /// Step 2. Error codes: `nameRequired`, `noCarts`.
  Future<ActionResult<void>> register() => run(() async {
        final found = institution;
        final admin = _admin;
        if (found == null || admin == null) throw const ActionError('notAdmin');
        final trimmed = name.trim();
        if (trimmed.isEmpty || trimmed.length > maxNameLength) throw const ActionError('nameRequired');
        if (selected.isEmpty) throw const ActionError('noCarts');
        final credentials = await services.devices.registerDevice(
          found.id,
          institutionName: found.name,
          name: trimmed,
          cartIds: [for (final c in carts) if (selected.contains(c.id)) c.id],
          byUid: admin.uid,
          byName: adminName,
        );
        await services.deviceCredentials.save(credentials);
        await onRegistered(credentials);
      });
}
