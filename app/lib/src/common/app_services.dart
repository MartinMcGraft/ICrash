import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../data/firebase/firebase_auth_repository.dart';
import '../data/firebase/firestore_audit_repository.dart';
import '../data/firebase/firestore_cart_repository.dart';
import '../data/firebase/firestore_credential_repository.dart';
import '../data/firebase/firestore_device_repository.dart';
import '../data/firebase/firestore_drawer_repository.dart';
import '../data/firebase/firestore_institution_repository.dart';
import '../data/firebase/firestore_inventory_repository.dart';
import '../data/firebase/firestore_product_repository.dart';
import '../data/firebase/firestore_support_repository.dart';
import '../data/firebase/firestore_usage_repository.dart';
import '../domain/repositories/audit_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/cart_repository.dart';
import '../domain/repositories/credential_repository.dart';
import '../domain/repositories/device_repository.dart';
import '../domain/repositories/drawer_repository.dart';
import '../domain/repositories/institution_repository.dart';
import '../domain/repositories/inventory_repository.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/support_repository.dart';
import '../domain/repositories/usage_repository.dart';
import '../data/local/device_credential_store.dart';
import '../data/local/local_repositories.dart';
import '../data/local/local_store.dart';
import '../domain/repositories/cart_settings_repository.dart';
import '../domain/repositories/device_session_repository.dart';
import '../domain/repositories/emergency_repository.dart';
import '../domain/repositories/permission_repository.dart';
import '../domain/repositories/report_repository.dart';
import '../domain/repositories/shift_repository.dart';
import '../domain/repositories/template_repository.dart';
import '../services/code_scanner_service.dart';
import '../services/sync_status.dart';
import '../services/gs1_camera_scanner_service.dart';
import '../services/gs1_hid_scanner_service.dart';
import '../services/internal_qr_camera_scanner_service.dart';
import '../services/pin_hasher.dart';
import '../services/scanner_platform_support.dart';
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
          inventory: FirestoreInventoryRepository(firestore, auth),
          usage: FirestoreUsageRepository(firestore),
          audit: FirestoreAuditRepository(firestore),
          credentials: FirestoreCredentialRepository(firestore, auth),
          support: FirestoreSupportRepository(firestore, auth),
          devices: FirestoreDeviceRepository(firestore),
          deviceCredentials: SecureDeviceCredentialStore(SharedPreferencesLocalStore()),
          createGs1Scanner: isCameraScanningSupported ? MobileScannerGs1Service.new : HidGs1ScannerService.new,
          createInternalQrScanner: MobileScannerInternalQrService.new,
          localStore: SharedPreferencesLocalStore(),
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
    required this.credentials,
    required this.createGs1Scanner,
    required this.createInternalQrScanner,
    PinHasher? pinHasher,
    SupportRepository? support,
    DeviceRepository? devices,
    DeviceCredentialStore? deviceCredentials,
    LocalStore? localStore,
    DeviceSessionRepository? deviceSession,
    ReportRepository? reports,
    EmergencyRepository? emergency,
    TemplateRepository? templates,
    ShiftRepository? shifts,
    PermissionRepository? permissions,
    CartSettingsRepository? cartSettings,
    SyncStatus? sync,
    CodeScannerService Function()? createCodeScanner,
  })  : createCodeScanner = createCodeScanner ??
            (isCameraScanningSupported ? CameraCodeScannerService.new : KeyboardCodeScannerService.new),
        pinHasher = pinHasher ?? PinHasher(),
        support = support ?? const NoSupportRepository(),
        devices = devices ?? const NoDeviceRepository(),
        deviceCredentials = deviceCredentials ?? InMemoryDeviceCredentialStore(),
        deviceSession = deviceSession ?? LocalDeviceSessionRepository(localStore ?? _testStore, hasher: pinHasher),
        reports = reports ?? LocalReportRepository(localStore ?? _testStore),
        emergency = emergency ?? LocalEmergencyRepository(localStore ?? _testStore),
        templates = templates ?? LocalTemplateRepository(localStore ?? _testStore),
        shifts = shifts ?? LocalShiftRepository(localStore ?? _testStore),
        permissions = permissions ?? LocalPermissionRepository(localStore ?? _testStore),
        cartSettings = cartSettings ?? LocalCartSettingsRepository(localStore ?? _testStore),
        sync = sync ?? SyncStatus();

  /// Tests that don't pass a store share one in-memory store per isolate.
  static final LocalStore _testStore = InMemoryLocalStore();

  final AuthRepository auth;
  final InstitutionRepository institutions;
  final CartRepository carts;
  final DrawerRepository drawers;
  final ProductRepository products;
  final InventoryRepository inventory;
  final UsageRepository usage;
  final AuditRepository audit;

  /// Administrator-set PIN hashes (DB3; interim, under Firebase).
  final CredentialRepository credentials;

  /// D18: Super's support access windows.
  final SupportRepository support;

  /// D17: registered tablets (Dashboard) and this tablet's own sign-in.
  final DeviceRepository devices;
  final DeviceCredentialStore deviceCredentials;

  /// Salted, slow PIN hashing (PBKDF2), shared by B7 and the device check.
  final PinHasher pinHasher;

  // STUB (local only) repositories — design v2 features with no Firestore
  // model yet. See data/local/local_store.dart.
  final DeviceSessionRepository deviceSession;
  final ReportRepository reports;
  final EmergencyRepository emergency;
  final TemplateRepository templates;
  final ShiftRepository shifts;
  final PermissionRepository permissions;
  final CartSettingsRepository cartSettings;

  /// Online/pending-writes state for the sync indicator.
  final SyncStatus sync;

  /// Builds a fresh [Gs1DataMatrixScannerService] each time it's called
  /// (e.g. one per scan screen, disposed when that screen closes) rather
  /// than sharing one long-lived instance, since it owns a camera resource.
  final Gs1DataMatrixScannerService Function() createGs1Scanner;

  /// Same per-call-fresh-instance rationale as [createGs1Scanner], for the
  /// other scanning domain (internal cart/drawer QR — spec section 29).
  final InternalQrScannerService Function() createInternalQrScanner;

  /// Unified QR / Data Matrix / barcode scanner (design v2 A3, A11).
  final CodeScannerService Function() createCodeScanner;
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
