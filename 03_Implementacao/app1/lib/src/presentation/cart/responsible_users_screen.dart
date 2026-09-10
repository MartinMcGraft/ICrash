import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/l10n/app_localizations.dart';
import '../../domain/entities/cart_responsible_user.dart';
import '../../domain/entities/membership.dart';
import '../members/membership_labels.dart';

/// Grants a normal user access to one specific cart without making them a
/// manager (spec section 17): institution membership alone does not grant
/// cart access — a manager/admin sees every cart already, but a plain user
/// only sees carts they were explicitly made responsible for here.
/// Manager+ only; `firestore.rules` (`isManagerOrAbove` on
/// `responsibleUsers` writes) is the real boundary.
class ResponsibleUsersScreen extends StatelessWidget {
  const ResponsibleUsersScreen({
    super.key,
    required this.institutionId,
    required this.cartId,
  });

  final String institutionId;
  final String cartId;

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.responsibleUsersTitle)),
      body: StreamBuilder<List<Membership>>(
        stream: services.institutions.watchMembers(institutionId),
        builder: (context, membersSnapshot) {
          if (membersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (membersSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.membersLoadError(membersSnapshot.error!)),
              ),
            );
          }
          final members = membersSnapshot.data ?? const <Membership>[];
          if (members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.membersEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          return StreamBuilder<List<CartResponsibleUser>>(
            stream: services.carts.watchResponsibleUsers(institutionId, cartId),
            builder: (context, responsibleSnapshot) {
              final responsibleIds = {
                for (final r
                    in responsibleSnapshot.data ??
                        const <CartResponsibleUser>[])
                  r.uid,
              };
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: members.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isResponsible = responsibleIds.contains(member.uid);
                  return Card(
                    child: CheckboxListTile(
                      value: isResponsible,
                      title: Text(member.uid, overflow: TextOverflow.ellipsis),
                      subtitle: Text(roleLabel(context, member.role)),
                      onChanged: member.isActive
                          ? (checked) async {
                              if (checked ?? false) {
                                await services.carts.assignResponsibleUser(
                                  institutionId,
                                  cartId,
                                  member.uid,
                                );
                              } else {
                                await services.carts.removeResponsibleUser(
                                  institutionId,
                                  cartId,
                                  member.uid,
                                );
                              }
                            }
                          : null,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
