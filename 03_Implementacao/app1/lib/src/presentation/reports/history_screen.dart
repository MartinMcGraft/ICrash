import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/app_services.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/usage_event.dart';
import '../cart/assignment_status_label.dart';
import 'history_csv_export.dart';
import 'history_summary.dart';

/// Institution-wide activity/audit history (spec section 51). Scoped
/// deliberately for this prototype: a filterable list of usage events with
/// product names resolved, read-only, a per-product summary, and a CSV
/// export — all of exactly what's currently shown (respects the type
/// filter). Per-cart/per-period aggregates are still explicitly deferred —
/// see docs/AI_HANDOFF.md.
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

  /// Copies to the clipboard rather than writing a file, to avoid adding a
  /// file-system dependency for a prototype-phase export (spec section 51).
  void _exportCsv(BuildContext context, List<UsageEvent> events, List<Product> products) {
    final csv = buildHistoryCsv(events, products);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar CSV'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(csv)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV copiado.')),
              );
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  void _showSummary(BuildContext context, List<UsageEvent> events, List<Product> products) {
    final summaries = summarizeByProduct(events, products);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumo por produto'),
        content: SizedBox(
          width: double.maxFinite,
          child: summaries.isEmpty
              ? const Text('Sem dados para resumir.')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final summary in summaries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(summary.productName, style: Theme.of(context).textTheme.titleSmall),
                              Text(
                                'Consumido: ${summary.consumed}   Reposto: ${summary.replenished}'
                                '${summary.otherAdjustments == 0 ? '' : '   Outros ajustes: ${summary.otherAdjustments > 0 ? '+' : ''}${summary.otherAdjustments}'}',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
        ],
      ),
    );
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
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showSummary(context, events, products),
                                icon: const Icon(Icons.summarize_outlined),
                                label: const Text('Ver resumo'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _exportCsv(context, events, products),
                                icon: const Icon(Icons.file_download_outlined),
                                label: const Text('Exportar CSV'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
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
                          ),
                        ),
                      ],
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
