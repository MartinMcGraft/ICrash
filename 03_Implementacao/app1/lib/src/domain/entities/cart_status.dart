/// Spec section 40. Derived automatically where practical rather than set
/// arbitrarily, so it never contradicts the actual inventory state.
enum CartStatus { operational, replenishmentRequired, auditRequired, outOfService }

extension CartStatusCodec on CartStatus {
  String get id => name;

  static CartStatus fromId(String id) => CartStatus.values.firstWhere(
        (status) => status.name == id,
        orElse: () => CartStatus.operational,
      );
}
