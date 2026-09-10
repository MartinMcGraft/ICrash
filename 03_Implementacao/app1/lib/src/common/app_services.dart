import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../data/firebase/firebase_auth_repository.dart';
import '../data/firebase/firestore_audit_repository.dart';
import '../data/firebase/firestore_cart_repository.dart';
import '../data/firebase/firestore_drawer_repository.dart';
import '../data/firebase/firestore_institution_repository.dart';
import '../data/firebase/firestore_inventory_repository.dart';
import '../data/firebase/firestore_product_repository.dart';
import '../data/firebase/firestore_usage_repository.dart';
import '../domain/repositories/audit_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/cart_repository.dart';
import '../domain/repositories/drawer_repository.dart';
import '../domain/repositories/institution_repository.dart';
import '../domain/repositories/inventory_repository.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/usage_repository.dart';
import '../services/gs1_camera_scanner_service.dart';
import '../services/scanner_service.dart';

/// Bundles every repository the V2 presentation layer needs, constructed
/// once at app startup. Deliberately a plain object handed down via
/// [AppServicesScope] rather than a DI package: the dependency count is
/// still small enough that adding a framework would be premature.
class AppServices {
  /// [auth]/[firestore] must come from [bootstrapFirebase]'s
  /// [FirebaseServices], not the bare `.instance` singletons: in emulator
  /// mode they are scoped to a separate named [FirebaseApp], not `[DEFAULT]`
  /// (see firebase_bootstrap.dart for why).
  AppServices({required FirebaseAuth auth, required FirebaseFirestore firestore})
      : this.withRepositories(
          auth: FirebaseAuthRepository(auth),
          institutions: FirestoreInstitutionRepository(firestore, auth),
          carts: FirestoreCartRepository(firestore, auth),
          drawers: FirestoreDrawerRepository(firestore),
          products: FirestoreProductRepository(firestore),
          inventory: FirestoreInventoryRepository(firestore),
          usage: FirestoreUsageRepository(firestore),
          audit: FirestoreAuditRepository(firestore),
          createGs1Scanner: MobileScannerGs1Service.new,
        );

  /// Lets widget tests supply fakes for every repository instead of the
  /// Firebase-backed ones, without touching `Firebase.initializeApp`.
  AppServices.withRepositories({
    required this.auth,
    required this.institutions,
    required this.carts,
    required this.drawers,
    required this.products,
    required this.inventory,
    required this.usage,
    required this.audit,
    required this.createGs1Scanner,
  });

  final AuthRepository auth;
  final InstitutionRepository institutions;
  final CartRepository carts;
  final DrawerRepository drawers;
  final ProductRepository products;
  final InventoryRepository inventory;
  final UsageRepository usage;
  final AuditRepository audit;

  /// Builds a fresh [Gs1DataMatrixScannerService] each time it's called
  /// (e.g. one per scan screen, disposed when that screen closes) rather
  /// than sharing one long-lived instance, since it owns a camera resource.
  final Gs1DataMatrixScannerService Function() createGs1Scanner;
}

class AppServicesScope extends InheritedWidget {
  const AppServicesScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppServicesScope>();
    assert(scope != null, 'AppServicesScope.of() called with no AppServicesScope ancestor');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppServicesScope oldWidget) => services != oldWidget.services;
}
