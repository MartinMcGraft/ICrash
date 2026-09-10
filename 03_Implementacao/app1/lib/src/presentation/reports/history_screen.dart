import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/usage_event.dart';
import '../cart/assignment_status_label.dart';

/// Institution-wide activity/audit history (spec section 51). Scoped
/// deliberately for this prototype: a filterable list of usage events with
/// product names resolved, read-only. Per-product/per-cart/per-period
/// aggregate reports and PDF/CSV export are explicitly deferred — see
/// docs/AI_HANDOFF.md — this is the "detailed view" half of section 51, not
/// the export half.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.institutionId});

  final String institutionId;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Future<List<Product>> _products =
      AppServicesScope.of(context).products.watchProducts(widget.institutionId).first;

  UsageEventType? _typeFilter;

  String _productName(List<Product> products, String productId) {
    for (final product in products) {
      if (product.id == productId) return product.name;
    }
    return 'Produto removido';
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _typeFilter == null,
                  onSelected: (_) => setState(() => _typeFilter = null),
                ),
                for (final type in UsageEventType.values)
                  ChoiceChip(
                    label: Text(usageEventTypeLabel(type)),
                    selected: _typeFilter == type,
                    onSelected: (_) => setState(() => _typeFilter = type),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UsageEvent>>(
              stream: services.usage.watchRecentEvents(widget.institutionId, limit: 100),
              builder: (context, eventsSnapshot) {
                if (eventsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (eventsSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Não foi possível carregar o histórico: ${eventsSnapshot.error}'),
                    ),
                  );
                }
                final events = (eventsSnapshot.data ?? const <UsageEvent>[])
                    .where((event) => _typeFilter == null || event.type == _typeFilter)
                    .toList();
                if (events.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Sem eventos para mostrar.', textAlign: TextAlign.center),
                    ),
                  );
                }
                return FutureBuilder<List<Product>>(
                  future: _products,
                  builder: (context, productsSnapshot) {
                    final products = productsSnapshot.data ?? const <Product>[];
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.history_outlined),
                            title: Text(_productName(products, event.productId)),
                            subtitle: Text(usageEventTypeLabel(event.type)),
                            trailing: Text(
                              '${event.amount > 0 ? '+' : ''}${event.amount}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
