/// Per-cart settings that have no Firestore field yet (design v2 B3:
/// "Atualizar o estado automaticamente", proposal D7).
abstract class CartSettingsRepository {
  Stream<Set<String>> watchAutoStatusCarts(String institutionId);
  Future<void> setAutoStatus(String institutionId, String cartId, bool enabled);
}
