/// An active emergency-mode session on one cart (design v2 A10,
/// proposal §9: consumptions only; tap = −1 unit; ending it sets the cart to
/// "Reposição necessária" and generates a summary report).
///
/// The session itself is device-local (stub); every consumption inside it is
/// a real `InventoryRepository.recordConsumption` call.
class EmergencySession {
  const EmergencySession({
    required this.institutionId,
    required this.cartId,
    required this.cartName,
    required this.startedAt,
    required this.startedByUid,
    required this.startedByName,
    this.consumptions = const [],
  });

  final String institutionId;
  final String cartId;
  final String cartName;
  final DateTime startedAt;
  final String startedByUid;
  final String startedByName;
  final List<EmergencyConsumption> consumptions;

  EmergencySession withConsumptions(List<EmergencyConsumption> next) => EmergencySession(
        institutionId: institutionId,
        cartId: cartId,
        cartName: cartName,
        startedAt: startedAt,
        startedByUid: startedByUid,
        startedByName: startedByName,
        consumptions: next,
      );

  /// Totals per product, in first-recorded order.
  List<(String productId, String productName, int amount)> totalsByProduct() {
    final order = <String>[];
    final names = <String, String>{};
    final totals = <String, int>{};
    for (final c in consumptions) {
      if (!totals.containsKey(c.productId)) order.add(c.productId);
      names[c.productId] = c.productName;
      totals[c.productId] = (totals[c.productId] ?? 0) + c.amount;
    }
    return [for (final id in order) (id, names[id]!, totals[id]!)];
  }

  Map<String, Object?> toJson() => {
        'institutionId': institutionId,
        'cartId': cartId,
        'cartName': cartName,
        'startedAt': startedAt.toIso8601String(),
        'startedByUid': startedByUid,
        'startedByName': startedByName,
        'consumptions': [for (final c in consumptions) c.toJson()],
      };

  factory EmergencySession.fromJson(Map<String, Object?> json) => EmergencySession(
        institutionId: json['institutionId'] as String,
        cartId: json['cartId'] as String,
        cartName: json['cartName'] as String? ?? '',
        startedAt: DateTime.parse(json['startedAt'] as String),
        startedByUid: json['startedByUid'] as String? ?? '',
        startedByName: json['startedByName'] as String? ?? '',
        consumptions: [
          for (final c in (json['consumptions'] as List? ?? const []))
            EmergencyConsumption.fromJson((c as Map).cast<String, Object?>()),
        ],
      );
}

class EmergencyConsumption {
  const EmergencyConsumption({
    required this.assignmentId,
    required this.productId,
    required this.productName,
    required this.amount,
    required this.at,
  });

  final String assignmentId;
  final String productId;
  final String productName;
  final int amount;
  final DateTime at;

  Map<String, Object?> toJson() => {
        'assignmentId': assignmentId,
        'productId': productId,
        'productName': productName,
        'amount': amount,
        'at': at.toIso8601String(),
      };

  factory EmergencyConsumption.fromJson(Map<String, Object?> json) => EmergencyConsumption(
        assignmentId: json['assignmentId'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String? ?? '',
        amount: (json['amount'] as num).toInt(),
        at: DateTime.parse(json['at'] as String),
      );
}
