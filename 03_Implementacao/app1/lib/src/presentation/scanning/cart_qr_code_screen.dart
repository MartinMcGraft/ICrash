import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../common/l10n/app_localizations.dart';
import '../../domain/entities/cart.dart';
import '../../services/internal_qr_payload.dart';

/// Shows this cart's internal QR code (spec sections 29, 33): scanning it
/// elsewhere resolves straight to this cart, without granting any access by
/// itself — the scanning user's own permissions still decide whether they
/// can actually open it.
class CartQrCodeScreen extends StatelessWidget {
  const CartQrCodeScreen({super.key, required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final payload = encodeCartQrPayload(cart.institutionId, cart.id);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cartQrScreenTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cart.name, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Semantics(
                label: l10n.cartQrSemanticLabel(cart.name),
                image: true,
                child: QrImageView(data: payload, size: 240),
              ),
              const SizedBox(height: 24),
              Text(l10n.cartQrInstruction, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
