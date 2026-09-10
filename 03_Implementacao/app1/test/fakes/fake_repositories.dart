import 'dart:async';

import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/common/repository_failure.dart';
import 'package:icrash_app/src/domain/entities/batch.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/cart_drawer.dart';
import 'package:icrash_app/src/domain/entities/cart_product_assignment.dart';
import 'package:icrash_app/src/domain/entities/cart_responsible_user.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/product.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/entities/slot.dart';
import 'package:icrash_app/src/domain/entities/usage_event.dart';
import 'package:icrash_app/src/domain/repositories/audit_repository.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/domain/repositories/cart_repository.dart';
import 'package:icrash_app/src/domain/repositories/drawer_repository.dart';
import 'package:icrash_app/src/domain/repositories/institution_repository.dart';
import 'package:icrash_app/src/domain/repositories/inventory_repository.dart';
import 'package:icrash_app/src/domain/repositories/product_repository.dart';
import 'package:icrash_app/src/domain/repositories/usage_repository.dart';
import 'package:icrash_app/src/services/scanner_service.dart';

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

  @override
  Future<Cart?> getCart(String institutionId, String cartId) async {
    for (final cart in carts) {
      if (cart.id == cartId) return cart;
    }
    return null;
  }

  @override
  Future<void> updateCart(String institutionId, Cart cart) async {
    final index = carts.indexWhere((c) => c.id == cart.id);
    if (index == -1) {
      carts.add(cart);
    } else {
      carts[index] = cart;
    }
    _emit();
  }

  final List<CartResponsibleUser> responsibleUsers = [];
  final _responsibleUsersController = StreamController<List<CartResponsibleUser>>.broadcast();

  void _emitResponsibleUsers() => _responsibleUsersController.add(List.unmodifiable(responsibleUsers));

  @override
  Stream<List<CartResponsibleUser>> watchResponsibleUsers(String institutionId, String cartId) {
    scheduleMicrotask(_emitResponsibleUsers);
    return _responsibleUsersController.stream;
  }

  @override
  Future<void> assignResponsibleUser(String institutionId, String cartId, String uid) async {
    if (!responsibleUsers.any((r) => r.uid == uid && r.cartId == cartId)) {
      responsibleUsers.add(CartResponsibleUser(uid: uid, cartId: cartId));
    }
    _emitResponsibleUsers();
  }

  @override
  Future<void> removeResponsibleUser(String institutionId, String cartId, String uid) async {
    responsibleUsers.removeWhere((r) => r.uid == uid && r.cartId == cartId);
    _emitResponsibleUsers();
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

class FakeProductRepository extends UnimplementedFake implements ProductRepository {
  FakeProductRepository({List<Product>? products}) : products = products ?? [];

  final List<Product> products;
  Product? lastCreated;
  int _nextId = 1;
  final _controller = StreamController<List<Product>>.broadcast();

  void _emit() => _controller.add(List.unmodifiable(products));

  @override
  Stream<List<Product>> watchProducts(String institutionId) {
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  @override
  Future<Product?> findByGtin(String institutionId, String gtin) async {
    for (final product in products) {
      if (product.gtin == gtin) return product;
    }
    return null;
  }

  @override
  Future<Product> createProduct(String institutionId, Product product) async {
    final created = Product(
      id: 'product-${_nextId++}',
      institutionId: institutionId,
      name: product.name,
      description: product.description,
      unitDescription: product.unitDescription,
      gtin: product.gtin,
    );
    lastCreated = created;
    products.add(created);
    _emit();
    return created;
  }

  @override
  Future<void> updateProduct(String institutionId, Product product) async {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) products[index] = product;
    _emit();
  }
}

class FakeInventoryRepository extends UnimplementedFake implements InventoryRepository {
  FakeInventoryRepository({List<CartProductAssignment>? assignments}) : assignments = assignments ?? [];

  final List<CartProductAssignment> assignments;
  final Map<String, List<Batch>> batchesByAssignment = {};
  CartProductAssignment? lastCreated;
  String? lastCorrectedEventId;
  int _nextId = 1;
  int _nextBatchId = 1;
  final _controller = StreamController<List<CartProductAssignment>>.broadcast();

  void _emit() => _controller.add(List.unmodifiable(assignments));

  @override
  Stream<List<CartProductAssignment>> watchAssignments(String institutionId, String cartId) {
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  @override
  Stream<List<CartProductAssignment>> watchAllAssignments(String institutionId) {
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  @override
  Future<CartProductAssignment?> getAssignment(String institutionId, String cartId, String assignmentId) async {
    for (final assignment in assignments) {
      if (assignment.id == assignmentId) return assignment;
    }
    return null;
  }

  @override
  Future<CartProductAssignment> createAssignment(String institutionId, String cartId, CartProductAssignment assignment) async {
    if (assignments.any((a) => a.productId == assignment.productId)) {
      throw const RepositoryFailure(RepositoryFailureReason.conflict);
    }
    final created = CartProductAssignment(
      id: 'assignment-${_nextId++}',
      cartId: cartId,
      slotId: assignment.slotId,
      productId: assignment.productId,
      currentQuantity: assignment.currentQuantity,
      targetQuantity: assignment.targetQuantity,
    );
    lastCreated = created;
    assignments.add(created);
    _emit();
    return created;
  }

  @override
  Future<void> reassignSlot({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required String newSlotId,
    required String actorUid,
  }) async {
    final index = assignments.indexWhere((a) => a.id == assignmentId);
    if (index == -1) return;
    final current = assignments[index];
    assignments[index] = CartProductAssignment(
      id: current.id,
      cartId: current.cartId,
      slotId: newSlotId,
      productId: current.productId,
      currentQuantity: current.currentQuantity,
      targetQuantity: current.targetQuantity,
      minimumQuantity: current.minimumQuantity,
      earliestKnownExpiry: current.earliestKnownExpiry,
      status: current.status,
    );
    _emit();
  }

  @override
  Future<void> deleteAssignment({
    required String institutionId,
    required String cartId,
    required String assignmentId,
  }) async {
    assignments.removeWhere((a) => a.id == assignmentId);
    batchesByAssignment.remove(assignmentId);
    _emit();
  }

  @override
  Stream<List<Batch>> watchBatches(String institutionId, String cartId, String assignmentId) {
    return Stream.value(List.unmodifiable(batchesByAssignment[assignmentId] ?? const []));
  }

  @override
  Future<void> recordConsumption({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required String actorUid,
  }) async {
    final index = assignments.indexWhere((a) => a.id == assignmentId);
    if (index == -1) return;
    final current = assignments[index];
    assignments[index] = CartProductAssignment(
      id: current.id,
      cartId: current.cartId,
      slotId: current.slotId,
      productId: current.productId,
      currentQuantity: current.currentQuantity - amount,
      targetQuantity: current.targetQuantity,
      minimumQuantity: current.minimumQuantity,
      earliestKnownExpiry: current.earliestKnownExpiry,
      status: current.status,
    );
    _emit();
  }

  @override
  Future<void> recordReplenishment({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required Batch batch,
    required String actorUid,
  }) async {
    final index = assignments.indexWhere((a) => a.id == assignmentId);
    if (index == -1) return;
    final current = assignments[index];
    assignments[index] = CartProductAssignment(
      id: current.id,
      cartId: current.cartId,
      slotId: current.slotId,
      productId: current.productId,
      currentQuantity: current.currentQuantity + amount,
      targetQuantity: current.targetQuantity,
      minimumQuantity: current.minimumQuantity,
      earliestKnownExpiry: current.earliestKnownExpiry,
      status: current.status,
    );
    final storedBatch = Batch(
      id: 'batch-${_nextBatchId++}',
      assignmentId: batch.assignmentId,
      lotNumber: batch.lotNumber,
      expiryDate: batch.expiryDate,
      quantity: batch.quantity,
      gtin: batch.gtin,
      source: batch.source,
    );
    (batchesByAssignment[assignmentId] ??= []).add(storedBatch);
    _emit();
  }

  @override
  Future<void> reconcileAfterAudit({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int confirmedQuantity,
    required List<Batch> confirmedBatches,
    required String actorUid,
  }) async {
    final index = assignments.indexWhere((a) => a.id == assignmentId);
    if (index == -1) return;
    final current = assignments[index];
    assignments[index] = CartProductAssignment(
      id: current.id,
      cartId: current.cartId,
      slotId: current.slotId,
      productId: current.productId,
      currentQuantity: confirmedQuantity,
      targetQuantity: current.targetQuantity,
      minimumQuantity: current.minimumQuantity,
      earliestKnownExpiry: current.earliestKnownExpiry,
      status: current.status,
    );
    batchesByAssignment[assignmentId] = List.of(confirmedBatches);
    _emit();
  }

  @override
  Future<void> recordCorrection({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required String correctsEventId,
    required String actorUid,
  }) async {
    final index = assignments.indexWhere((a) => a.id == assignmentId);
    if (index == -1) return;
    final current = assignments[index];
    assignments[index] = CartProductAssignment(
      id: current.id,
      cartId: current.cartId,
      slotId: current.slotId,
      productId: current.productId,
      currentQuantity: current.currentQuantity + amount,
      targetQuantity: current.targetQuantity,
      minimumQuantity: current.minimumQuantity,
      earliestKnownExpiry: current.earliestKnownExpiry,
      status: current.status,
    );
    lastCorrectedEventId = correctsEventId;
    _emit();
  }
}

class FakeUsageRepository extends UnimplementedFake implements UsageRepository {
  FakeUsageRepository({List<UsageEvent>? events}) : events = events ?? [];

  final List<UsageEvent> events;

  @override
  Stream<List<UsageEvent>> watchRecentEvents(String institutionId, {int limit = 50}) => Stream.value(List.unmodifiable(events));

  @override
  Stream<List<UsageEvent>> watchEventsForAssignment(String institutionId, String assignmentId) =>
      Stream.value(List.unmodifiable(events.where((e) => e.assignmentId == assignmentId).toList()));
}

class FakeAuditRepository extends UnimplementedFake implements AuditRepository {}

/// Lets a widget test drive the scan flow without a camera: push a raw GS1
/// payload string through [emit] and it reaches whatever is listening to
/// [scanRawPayloads], exactly like a real decoded barcode would.
class FakeGs1DataMatrixScannerService implements Gs1DataMatrixScannerService {
  final _controller = StreamController<String>.broadcast();
  bool disposed = false;

  void emit(String rawPayload) => _controller.add(rawPayload);

  @override
  Stream<String> scanRawPayloads() => _controller.stream;

  @override
  void dispose() {
    disposed = true;
    _controller.close();
  }
}

/// Lets a widget test drive the internal-QR scan flow without a camera: push
/// a raw payload string through [emit], mirroring
/// [FakeGs1DataMatrixScannerService] for the other scanning domain.
class FakeInternalQrScannerService implements InternalQrScannerService {
  final _controller = StreamController<String>.broadcast();
  bool disposed = false;

  void emit(String rawPayload) => _controller.add(rawPayload);

  @override
  Stream<String> scanPayloads() => _controller.stream;

  @override
  void dispose() {
    disposed = true;
    _controller.close();
  }
}

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
  Gs1DataMatrixScannerService Function()? createGs1Scanner,
  InternalQrScannerService Function()? createInternalQrScanner,
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
    createGs1Scanner: createGs1Scanner ?? FakeGs1DataMatrixScannerService.new,
    createInternalQrScanner: createInternalQrScanner ?? FakeInternalQrScannerService.new,
  );
}
