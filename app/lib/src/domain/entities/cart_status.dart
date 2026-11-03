/// Spec section 40. Derived automatically where practical rather than set
/// arbitrarily, so it never contradicts the actual inventory state.
///
/// [checkInProgress] ("Gestão mensal em curso", 2 Nov 2026): set when a
/// monthly check starts and replaced when its report is created. Not a
/// manual choice ([manualCartStatuses]).
enum CartStatus { operational, replenishmentRequired, auditRequired, outOfService, checkInProgress }

/// The states someone may pick in "Alterar estado".
const manualCartStatuses = [
  CartStatus.operational,
  CartStatus.replenishmentRequired,
  CartStatus.auditRequired,
  CartStatus.outOfService,
];

extension CartStatusCodec on CartStatus {
  String get id => name;

  static CartStatus fromId(String id) => CartStatus.values.firstWhere(
        (status) => status.name == id,
        orElse: () => CartStatus.operational,
      );
}
