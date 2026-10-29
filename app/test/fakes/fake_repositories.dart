import 'dart:async';

import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/common/repository_failure.dart';
import 'package:icrash_app/src/data/local/local_store.dart';
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
import 'package:icrash_app/src/domain/gtin.dart';
import 'package:icrash_app/src/domain/inventory_rules.dart';
import 'package:icrash_app/src/domain/repositories/audit_repository.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/domain/repositories/cart_repository.dart';
import 'package:icrash_app/src/domain/repositories/credential_repository.dart';
import 'package:icrash_app/src/domain/repositories/drawer_repository.dart';
import 'package:icrash_app/src/domain/repositories/institution_repository.dart';
import 'package:icrash_app/src/domain/repositories/inventory_repository.dart';
import 'package:icrash_app/src/domain/repositories/product_repository.dart';
import 'package:icrash_app/src/domain/repositories/usage_repository.dart';
import 'package:icrash_app/src/services/pin_hasher.dart';
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

  /// What [createMember] received, by the new member's uid.
  final Map<String, String> passwords = {};
  final Map<String, String> pinHashes = {};
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
    required String pinHash,
    required Role role,
    String? displayName,
  }) async {
    if (createMemberError != null) throw createMemberError!;
    final uid = 'member-${_nextUid++}';
    passwords[uid] = password;
    pinHashes[uid] = pinHash;
    members.add(Membership(
      uid: uid,
      institutionId: institutionId,
      role: role,
      status: MembershipStatus.active,
      email: email,
      displayName: displayName,
    ));
    _emitMembers();
  }

  @override
  Future<void> updateMemberRole(String institutionId, String uid, Role role) async {
    final index = members.indexWhere((m) => m.uid == uid);
    if (index == -1) return;
    final current = members[index];
    members[index] = Membership(
      uid: current.uid,
      institutionId: institutionId,
      role: role,
      status: current.status,
      email: current.email,
      displayName: current.displayName,
    );
    _emitMembers();
  }

  @override
  Future<void> setMembershipStatus(String institutionId, String uid, MembershipStatus status) async {
    final index = members.indexWhere((m) => m.uid == uid);
    if (index == -1) return;
    final current = members[index];
    members[index] = Membership(
      uid: current.uid,
      institutionId: institutionId,
      role: current.role,
      status: status,
      email: current.email,
      displayName: current.displayName,
    );
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
    final created = Cart(
      id: 'cart-${_nextId++}',
      institutionId: institutionId,
      name: cart.name,
      status: cart.status,
      templateId: cart.templateId,
      service: cart.service,
      location: cart.location,
    );
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
  Future<CartDrawer> createDrawer(String institutionId, String cartId, CartDrawer drawer, {List<Slot>? slots}) async {
    final id = 'drawer-${_nextId++}';
    final created = CartDrawer(id: id, cartId: cartId, number: drawer.number, rows: drawer.rows, columns: drawer.columns);
    lastCreatedDrawer = created;
    drawers.add(created);
    slotsByDrawer[id] = [
      for (final s in slots ?? Slot.unitGrid(id, drawer.rows, drawer.columns))
        Slot(id: s.id, drawerId: id, row: s.row, column: s.column, rowSpan: s.rowSpan, columnSpan: s.columnSpan, label: s.label),
    ];
    _emitDrawers();
    _emitSlots(id);
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
    final forms = gtinLookupForms(gtin);
    for (final product in products) {
      if (forms.contains(product.gtin)) return product;
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
      category: product.category,
      expiryWarningDays: product.expiryWarningDays,
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
  String? lastCorrectionReason;
  String? lastConsumptionEventId;
  int _nextId = 1;
  int _nextBatchId = 1;
  int _nextEventId = 1;
  final _controller = StreamController<List<CartProductAssignment>>.broadcast();

  void _emit() => _controller.add(List.unmodifiable(assignments));

  /// Applies [change] to the assignment, mirroring the real repository's
  /// business-rule failures (a [StockRuleViolation] becomes a coded
  /// [RepositoryFailure]).
  void _update(String assignmentId, CartProductAssignment Function(CartProductAssignment current) change) {
    final index = assignments.indexWhere((a) => a.id == assignmentId);
    if (index == -1) return;
    try {
      assignments[index] = change(assignments[index]);
    } on StockRuleViolation catch (v) {
      throw RepositoryFailure(RepositoryFailureReason.invalidInput, cause: v, code: v.code);
    }
    _emit();
  }

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
    if (assignment.drawerId != null &&
        assignments.any((a) => a.drawerId == assignment.drawerId && a.slotId == assignment.slotId)) {
      throw const RepositoryFailure(RepositoryFailureReason.conflict, code: 'slotTaken');
    }
    try {
      InventoryRules.checkStock(assignment.currentQuantity, assignment.targetQuantity);
    } on StockRuleViolation catch (v) {
      throw RepositoryFailure(RepositoryFailureReason.invalidInput, cause: v, code: v.code);
    }
    final created = CartProductAssignment(
      id: 'assignment-${_nextId++}',
      cartId: cartId,
      drawerId: assignment.drawerId,
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
    required String newDrawerId,
    required String newSlotId,
    required String actorUid,
  }) async =>
      _update(assignmentId, (a) => a.copyWith(drawerId: newDrawerId, slotId: newSlotId));

  @override
  Future<void> deleteAssignment({
    required String institutionId,
    required String cartId,
    required String assignmentId,
  }) async {
    assignments.removeWhere((a) => a.id == assignmentId);
    // DB1: batches are marked removed, never deleted.
    final now = DateTime.now();
    batchesByAssignment[assignmentId] = [
      for (final b in batchesByAssignment[assignmentId] ?? const <Batch>[]) b.isActive ? b.removed(now) : b,
    ];
    _emit();
  }

  @override
  Future<void> updateAssignmentSettings({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int targetQuantity,
  }) async =>
      _update(assignmentId, (a) {
        InventoryRules.checkNewTarget(current: a.currentQuantity, newTarget: targetQuantity);
        return a.copyWith(targetQuantity: targetQuantity);
      });

  @override
  Stream<List<Batch>> watchBatches(String institutionId, String cartId, String assignmentId) {
    return Stream.value(List.unmodifiable((batchesByAssignment[assignmentId] ?? const <Batch>[]).where((b) => b.isActive)));
  }

  @override
  String newUsageEventId(String institutionId) => 'event-${_nextEventId++}';

  @override
  Future<String> recordConsumption({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required String actorUid,
    String? eventId,
  }) async {
    _update(assignmentId, (a) => a.copyWith(currentQuantity: InventoryRules.applyConsumption(a.currentQuantity, amount)));
    return lastConsumptionEventId = eventId ?? newUsageEventId(institutionId);
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
    _update(
      assignmentId,
      (a) => a.copyWith(currentQuantity: InventoryRules.applyReplenishment(a.currentQuantity, amount, target: a.targetQuantity)),
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
    _update(assignmentId, (a) {
      InventoryRules.checkStock(confirmedQuantity, a.targetQuantity);
      return a.copyWith(currentQuantity: confirmedQuantity);
    });
    // DB1: batches the audit didn't confirm are marked removed, never deleted.
    final confirmed = {for (final b in confirmedBatches) b.id};
    final now = DateTime.now();
    batchesByAssignment[assignmentId] = [
      for (final b in batchesByAssignment[assignmentId] ?? const <Batch>[])
        b.isActive && !confirmed.contains(b.id) ? b.removed(now) : b,
    ];
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
    String? reason,
  }) async {
    lastCorrectionReason = reason;
    _update(
      assignmentId,
      (a) => a.copyWith(currentQuantity: InventoryRules.applyCorrection(a.currentQuantity, amount, target: a.targetQuantity)),
    );
    lastCorrectedEventId = correctsEventId;
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

  @override
  Stream<Set<String>> watchUsedAssignmentIds(String institutionId, String cartId) =>
      Stream.value({for (final e in events) if (e.cartId == cartId) e.assignmentId});
}

class FakeAuditRepository extends UnimplementedFake implements AuditRepository {}

/// PIN hashes by `institutionId/uid` (DB3).
class FakeCredentialRepository extends UnimplementedFake implements CredentialRepository {
  FakeCredentialRepository({Map<String, String>? pinHashes}) : pinHashes = pinHashes ?? {};

  final Map<String, String> pinHashes;
  Object? fetchError;

  @override
  Future<String?> fetchPinHash(String institutionId, String uid) async {
    if (fetchError != null) throw fetchError!;
    return pinHashes['$institutionId/$uid'];
  }

  @override
  Future<void> setPinHash(String institutionId, String uid, String pinHash) async =>
      pinHashes['$institutionId/$uid'] = pinHash;
}

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
  CredentialRepository? credentials,
  PinHasher? pinHasher,
  Gs1DataMatrixScannerService Function()? createGs1Scanner,
  InternalQrScannerService Function()? createInternalQrScanner,
  LocalStore? localStore,
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
    credentials: credentials ?? FakeCredentialRepository(),
    // Few PBKDF2 iterations keep tests fast; the count travels with each hash.
    pinHasher: pinHasher ?? PinHasher(iterations: 1000),
    createGs1Scanner: createGs1Scanner ?? FakeGs1DataMatrixScannerService.new,
    createInternalQrScanner: createInternalQrScanner ?? FakeInternalQrScannerService.new,
    // A fresh store per test, so local stubs (templates, shifts, PIN…) never
    // leak between tests.
    localStore: localStore ?? InMemoryLocalStore(),
  );
}
