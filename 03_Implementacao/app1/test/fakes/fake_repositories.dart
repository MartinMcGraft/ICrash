import 'dart:async';

import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/cart_drawer.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/entities/slot.dart';
import 'package:icrash_app/src/domain/repositories/audit_repository.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/domain/repositories/cart_repository.dart';
import 'package:icrash_app/src/domain/repositories/drawer_repository.dart';
import 'package:icrash_app/src/domain/repositories/institution_repository.dart';
import 'package:icrash_app/src/domain/repositories/inventory_repository.dart';
import 'package:icrash_app/src/domain/repositories/product_repository.dart';
import 'package:icrash_app/src/domain/repositories/usage_repository.dart';

/// Throws on any call that isn't explicitly overridden by a subclass.
/// Lets each fake below implement only the handful of methods a given
/// widget test actually exercises, instead of every method on its interface.
class UnimplementedFake {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call in test fake: ${invocation.memberName}');
}

class FakeAuthRepository extends UnimplementedFake implements AuthRepository {
  FakeAuthRepository({this.signedInUser, this.signInResult, this.signInError});

  AuthUser? signedInUser;
  AuthUser? signInResult;
  Object? signInError;
  String? lastEmail;
  String? lastPassword;
  int signOutCallCount = 0;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(signedInUser);

  @override
  AuthUser? get currentUser => signedInUser;

  @override
  Future<AuthUser> signInWithEmailPassword(String email, String password) async {
    lastEmail = email;
    lastPassword = password;
    if (signInError != null) throw signInError!;
    return signInResult ?? const AuthUser(uid: 'test-uid');
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    signedInUser = null;
  }
}

class FakeInstitutionRepository extends UnimplementedFake implements InstitutionRepository {
  FakeInstitutionRepository({this.institutions = const [], this.myMembership, List<Membership>? members})
      : members = members ?? [];

  List<Institution> institutions;
  Membership? myMembership;
  final List<Membership> members;
  Object? createMemberError;
  int _nextUid = 1;
  final _membersController = StreamController<List<Membership>>.broadcast();

  void _emitMembers() => _membersController.add(List.unmodifiable(members));

  @override
  Stream<List<Institution>> watchMyInstitutions() => Stream.value(institutions);

  @override
  Future<Membership?> getMyMembership(String institutionId) async => myMembership;

  @override
  Stream<List<Membership>> watchMembers(String institutionId) {
    scheduleMicrotask(_emitMembers);
    return _membersController.stream;
  }

  @override
  Future<void> createMember(
    String institutionId, {
    required String email,
    required String password,
    required Role role,
  }) async {
    if (createMemberError != null) throw createMemberError!;
    members.add(Membership(
      uid: 'member-${_nextUid++}',
      institutionId: institutionId,
      role: role,
      status: MembershipStatus.active,
    ));
    _emitMembers();
  }

  @override
  Future<void> updateMemberRole(String institutionId, String uid, Role role) async {
    final index = members.indexWhere((m) => m.uid == uid);
    if (index == -1) return;
    final current = members[index];
    members[index] = Membership(uid: current.uid, institutionId: institutionId, role: role, status: current.status);
    _emitMembers();
  }

  @override
  Future<void> setMembershipStatus(String institutionId, String uid, MembershipStatus status) async {
    final index = members.indexWhere((m) => m.uid == uid);
    if (index == -1) return;
    final current = members[index];
    members[index] = Membership(uid: current.uid, institutionId: institutionId, role: current.role, status: status);
    _emitMembers();
  }
}

class FakeCartRepository extends UnimplementedFake implements CartRepository {
  FakeCartRepository({List<Cart>? carts}) : carts = carts ?? [];

  final List<Cart> carts;
  Cart? lastCreated;
  Object? createError;
  int _nextId = 1;
  final _controller = StreamController<List<Cart>>.broadcast();

  void _emit() => _controller.add(List.unmodifiable(carts));

  @override
  Stream<List<Cart>> watchAccessibleCarts(String institutionId) {
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  @override
  Future<Cart> createCart(String institutionId, Cart cart) async {
    if (createError != null) throw createError!;
    final created = Cart(id: 'cart-${_nextId++}', institutionId: institutionId, name: cart.name, status: cart.status);
    lastCreated = created;
    carts.add(created);
    _emit();
    return created;
  }
}

class FakeDrawerRepository extends UnimplementedFake implements DrawerRepository {
  FakeDrawerRepository({List<CartDrawer>? drawers}) : drawers = drawers ?? [];

  final List<CartDrawer> drawers;
  final Map<String, List<Slot>> slotsByDrawer = {};
  CartDrawer? lastCreatedDrawer;
  List<Slot>? lastSavedSlots;
  int _nextId = 1;
  final _drawersController = StreamController<List<CartDrawer>>.broadcast();
  final Map<String, StreamController<List<Slot>>> _slotsControllers = {};

  void _emitDrawers() => _drawersController.add(List.unmodifiable(drawers));

  StreamController<List<Slot>> _slotsController(String drawerId) =>
      _slotsControllers.putIfAbsent(drawerId, () => StreamController<List<Slot>>.broadcast());

  void _emitSlots(String drawerId) => _slotsController(drawerId).add(List.unmodifiable(slotsByDrawer[drawerId] ?? const []));

  @override
  Stream<List<CartDrawer>> watchDrawers(String institutionId, String cartId) {
    scheduleMicrotask(_emitDrawers);
    return _drawersController.stream;
  }

  @override
  Future<CartDrawer> createDrawer(String institutionId, String cartId, CartDrawer drawer) async {
    final created =
        CartDrawer(id: 'drawer-${_nextId++}', cartId: cartId, name: drawer.name, rows: drawer.rows, columns: drawer.columns);
    lastCreatedDrawer = created;
    drawers.add(created);
    _emitDrawers();
    return created;
  }

  @override
  Future<void> updateDrawer(String institutionId, String cartId, CartDrawer drawer) async {
    final index = drawers.indexWhere((d) => d.id == drawer.id);
    if (index != -1) drawers[index] = drawer;
    _emitDrawers();
  }

  @override
  Stream<List<Slot>> watchSlots(String institutionId, String cartId, String drawerId) {
    final controller = _slotsController(drawerId);
    scheduleMicrotask(() => _emitSlots(drawerId));
    return controller.stream;
  }

  @override
  Future<void> replaceSlots(String institutionId, String cartId, String drawerId, List<Slot> slots) async {
    slotsByDrawer[drawerId] = List.of(slots);
    lastSavedSlots = List.of(slots);
    _emitSlots(drawerId);
  }
}

class FakeProductRepository extends UnimplementedFake implements ProductRepository {}

class FakeInventoryRepository extends UnimplementedFake implements InventoryRepository {}

class FakeUsageRepository extends UnimplementedFake implements UsageRepository {}

class FakeAuditRepository extends UnimplementedFake implements AuditRepository {}

/// Builds an [AppServices] for widget tests: pass fakes for whatever the
/// screen under test actually uses, everything else defaults to a filler
/// fake that throws if it is ever called.
AppServices buildTestServices({
  AuthRepository? auth,
  InstitutionRepository? institutions,
  CartRepository? carts,
  DrawerRepository? drawers,
  ProductRepository? products,
  InventoryRepository? inventory,
  UsageRepository? usage,
  AuditRepository? audit,
}) {
  return AppServices.withRepositories(
    auth: auth ?? FakeAuthRepository(),
    institutions: institutions ?? FakeInstitutionRepository(),
    carts: carts ?? FakeCartRepository(),
    drawers: drawers ?? FakeDrawerRepository(),
    products: products ?? FakeProductRepository(),
    inventory: inventory ?? FakeInventoryRepository(),
    usage: usage ?? FakeUsageRepository(),
    audit: audit ?? FakeAuditRepository(),
  );
}
