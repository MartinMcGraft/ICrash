import '../../domain/entities/cart_status.dart';

/// PT-PT display label for [CartStatus] (spec section 40). Centralized here
/// so every screen that lists carts describes status the same way.
String cartStatusLabel(CartStatus status) {
  switch (status) {
    case CartStatus.operational:
      return 'Operacional';
    case CartStatus.replenishmentRequired:
      return 'Reposição necessária';
    case CartStatus.auditRequired:
      return 'Auditoria necessária';
    case CartStatus.outOfService:
      return 'Fora de serviço';
  }
}
