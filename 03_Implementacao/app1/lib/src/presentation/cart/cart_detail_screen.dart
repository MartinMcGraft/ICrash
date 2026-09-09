import 'package:flutter/material.dart';

import '../../domain/entities/cart.dart';
import 'cart_status_label.dart';

/// Placeholder for the real cart detail (drawers/slots/stock — workstreams
/// B/C/E/F). Shows what already exists (name, status) so the cart list is
/// still useful before those land.
class CartDetailScreen extends StatelessWidget {
  const CartDetailScreen({super.key, required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(cart.name)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chip(label: Text(cartStatusLabel(cart.status))),
              const SizedBox(height: 16),
              const Icon(Icons.construction_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'As gavetas, slots e stock deste carro ainda estão em construção nesta versão V2.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
