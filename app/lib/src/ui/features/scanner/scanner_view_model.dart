import '../../../common/app_services.dart';
import '../../../common/repository_failure.dart';
import '../../../domain/entities/product.dart';
import '../../../services/code_scanner_service.dart';
import '../../../services/gs1_data_matrix_parser.dart';
import '../../../services/internal_qr_payload.dart';
import '../../../services/scanned_product_code.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

enum ScanMode { product, cart }

enum ScanError { unreadable, unknownProduct, notACart, otherInstitution, notInAnyCart }

/// Where a product sits, so "Repor este produto" can open the right drawer.
class ProductLocation {
  const ProductLocation({required this.cartId, required this.drawerId, required this.slotId});
  final String cartId;
  final String drawerId;
  final String slotId;
}

/// A11 · Ler código — QR (carts), GS1 Data Matrix and barcodes (products),
/// camera or USB reader, with manual entry.
class ScannerViewModel extends ViewModel {
  ScannerViewModel(this.services, this.session, {required this.onCart}) : scanner = services.createCodeScanner() {
    listen(scanner.scans(), (code) => handle(code));
  }

  final AppServices services;
  final SessionController session;
  final CodeScannerService scanner;

  /// Opens a cart (shell navigation), called for a valid cart QR.
  final void Function(String cartId) onCart;

  ScanMode mode = ScanMode.product;
  Product? lastProduct;
  Gs1ParsedData? lastData;
  ScanError? error;
  bool torchOn = false;

  void setMode(ScanMode value) {
    mode = value;
    error = null;
    notify();
  }

  Future<void> toggleTorch() async {
    await scanner.toggleTorch();
    torchOn = !torchOn;
    notify();
  }

  /// Manual entry: a GTIN, a GS1 string or a cart code.
  Future<void> submitManual(String text) {
    final raw = text.trim();
    final format = raw.startsWith('icrash://') || (mode == ScanMode.cart && raw.contains('/'))
        ? CodeFormat.qr
        : RegExp(r'^\d{8,14}$').hasMatch(raw)
            ? CodeFormat.barcode
            : CodeFormat.dataMatrix;
    return handle(ScannedCode(raw, format));
  }

  Future<void> handle(ScannedCode code) async {
    error = null;
    if (code.format == CodeFormat.qr || mode == ScanMode.cart) {
      final target = decodeCartQrPayload(code.raw) ?? _manualCart(code.raw);
      if (target == null) {
        error = mode == ScanMode.cart ? ScanError.notACart : ScanError.unreadable;
      } else if (target.institutionId != session.institution.id) {
        error = ScanError.otherInstitution;
      } else {
        notify();
        onCart(target.cartId);
        return;
      }
      notify();
      return;
    }
    final data = productDataFromScan(code);
    if (data == null) {
      error = ScanError.unreadable;
      notify();
      return;
    }
    lastData = data;
    lastProduct = null;
    if (data.gtin != null) {
      try {
        lastProduct = await services.products.findByGtin(session.institution.id, data.gtin!);
      } on RepositoryFailure {
        lastProduct = null;
      }
    }
    if (lastProduct == null) error = ScanError.unknownProduct;
    notify();
  }

  static CartQrTarget? _manualCart(String raw) {
    final parts = raw.trim().split('/').where((p) => p.isNotEmpty).toList();
    return parts.length == 2 ? CartQrTarget(institutionId: parts[0], cartId: parts[1]) : null;
  }

  /// Finds the drawer/slot holding [lastProduct] (preferring a single cart
  /// scope when the session is limited to one cart).
  Future<ActionResult<ProductLocation>> locateLastProduct() => run(() async {
        final product = lastProduct;
        if (product == null) throw const ActionError('notInAnyCart');
        final institutionId = session.institution.id;
        final assignments = (await services.inventory.watchAllAssignments(institutionId).first)
            .where((a) => a.productId == product.id && (session.scopedCartId == null || a.cartId == session.scopedCartId))
            .toList();
        for (final a in assignments) {
          final drawers = await services.drawers.watchDrawers(institutionId, a.cartId).first;
          for (final drawer in drawers) {
            final slots = await services.drawers.watchSlots(institutionId, a.cartId, drawer.id).first;
            final ids = slots.isEmpty
                ? {for (var r = 0; r < drawer.rows; r++) for (var c = 0; c < drawer.columns; c++) 'r${r}c$c'}
                : slots.map((s) => s.id).toSet();
            if (ids.contains(a.slotId)) return ProductLocation(cartId: a.cartId, drawerId: drawer.id, slotId: a.slotId);
          }
        }
        throw const ActionError('notInAnyCart');
      });

  @override
  void dispose() {
    super.dispose();
    scanner.dispose();
  }
}
