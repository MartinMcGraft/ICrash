/// Encodes/decodes the internal I-Crash QR payload (spec section 33): an
/// opaque, versioned URI identifying a cart — `icrash://v1/cart/<institutionId>/<cartId>`.
/// Deliberately independent of any camera/scanner code, mirroring
/// `gs1_data_matrix_parser.dart`'s separation of decoding from parsing.
///
/// Scanning only resolves an id; it never grants access by itself (spec
/// section 33) — whoever reads the resolved cart still goes through
/// `CartRepository.getCart`, which Firestore Rules gate exactly as they
/// gate every other cart read.
class CartQrTarget {
  const CartQrTarget({required this.institutionId, required this.cartId});

  final String institutionId;
  final String cartId;
}

String encodeCartQrPayload(String institutionId, String cartId) => 'icrash://v1/cart/$institutionId/$cartId';

CartQrTarget? decodeCartQrPayload(String payload) {
  final uri = Uri.tryParse(payload);
  if (uri == null || uri.scheme != 'icrash' || uri.host != 'v1') return null;
  final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
  if (segments.length != 3 || segments[0] != 'cart') return null;
  return CartQrTarget(institutionId: segments[1], cartId: segments[2]);
}
