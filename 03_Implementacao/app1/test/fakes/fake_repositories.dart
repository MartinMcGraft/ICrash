import 'dart:async';

import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
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
  FakeInstitutionRepository({this.institutions = const [], this.myMembership});

  List<Institution> institutions;
  Membership? myMembership;

  @override
  Stream<List<Institution>> watchMyInstitutions() => Stream.value(institutions);

  @override
  Future<Membership?> getMyMembership(String institutionId) async => myMembership;
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

class FakeDrawerRepository extends UnimplementedFake implements DrawerRepository {}

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
