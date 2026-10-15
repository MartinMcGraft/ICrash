import '../../../common/repository_failure.dart';
import '../../../services/code_scanner_service.dart';
import '../../../services/internal_qr_payload.dart';
import '../../core/mvvm/view_model.dart';

enum CartLoginError { notACartCode, cartNotFound, noAccess, noSavedSession, generic }

/// A3 · Entrar no carro (proposal D3: scanning the cart's QR opens a session
/// limited to that cart).
class CartLoginViewModel extends ViewModel {
  CartLoginViewModel({required this.scanner, required this.enterCart}) {
    listen(scanner.scans(), (code) => submitCode(code.raw));
  }

  final CodeScannerService scanner;

  /// Provided by the app root (opens the cart-scoped session).
  final Future<ActionResult<void>> Function(CartQrTarget target) enterCart;

  CartLoginError? error;
  bool torchOn = false;
  bool _submitting = false;

  /// Accepts the full QR payload or the readable "institution/cart" code
  /// printed under the QR.
  Future<void> submitCode(String raw) async {
    if (_submitting) return;
    final text = raw.trim();
    final target = decodeCartQrPayload(text) ?? _decodeManual(text);
    if (target == null) {
      error = CartLoginError.notACartCode;
      notify();
      return;
    }
    _submitting = true;
    error = null;
    notify();
    final result = await enterCart(target);
    _submitting = false;
    if (!result.isOk) {
      error = switch ((result.failure, result.code)) {
        (_, 'noSavedSession') => CartLoginError.noSavedSession,
        (RepositoryFailureReason.notFound, _) => CartLoginError.cartNotFound,
        (RepositoryFailureReason.permissionDenied, _) => CartLoginError.noAccess,
        _ => CartLoginError.generic,
      };
      notify();
    }
  }

  static CartQrTarget? _decodeManual(String text) {
    final parts = text.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length != 2) return null;
    return CartQrTarget(institutionId: parts[0], cartId: parts[1]);
  }

  Future<void> toggleTorch() async {
    await scanner.toggleTorch();
    torchOn = !torchOn;
    notify();
  }

  @override
  void dispose() {
    super.dispose();
    scanner.dispose();
  }
}
