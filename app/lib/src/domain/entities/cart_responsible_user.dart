/// Explicit assignment of a member as responsible for one [Cart]
/// (spec section 17). Institution membership alone does not grant cart
/// access. Document id is the user's uid.
/// Path: `institutions/{institutionId}/carts/{cartId}/responsibleUsers/{uid}`.
///
/// Modelled as one document per uid (rather than a single array field) so a
/// future move to multiple simultaneous responsible users per cart needs no
/// schema change, only relaxing who may create additional documents.
class CartResponsibleUser {
  const CartResponsibleUser({
    required this.uid,
    required this.cartId,
    this.assignedAt,
    this.assignedBy,
  });

  final String uid;
  final String cartId;
  final DateTime? assignedAt;
  final String? assignedBy;

  factory CartResponsibleUser.fromMap(String uid, String cartId, Map<String, Object?> map) {
    return CartResponsibleUser(
      uid: uid,
      cartId: cartId,
      assignedBy: map['assignedBy'] as String?,
    );
  }

  Map<String, Object?> toMap() => {
        'uid': uid,
        if (assignedBy != null) 'assignedBy': assignedBy,
      };
}
