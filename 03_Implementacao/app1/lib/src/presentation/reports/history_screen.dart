import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../common/app_services.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/usage_event.dart';
import '../cart/assignment_status_label.dart';
import 'history_csv_export.dart';
import 'history_pdf_export.dart';
import 'history_summary.dart';

/// Institution-wide activity/audit history (spec section 51): a filterable
/// list of usage events with product names resolved, read-only, aggregate
/// summaries grouped by product, cart, or day/week/month, and CSV/PDF
/// exports — all of exactly what's currently shown (respects the type
/// filter).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.institutionId});

  final String institutionId;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Future<List<Product>> _products = AppServicesScope.of(context)
      .products
      .watchProducts(widget.institutionId)
      .first;
  late final Future<List<Cart>> _carts = AppServicesScope.of(context).carts
      .watchAccessibleCarts(widget.institutionId)
      .first;

  // Cached once: the type-filter chips call `setState` on every tap, and a
  // fresh `watchRecentEvents(...)` call would otherwise re-subscribe the
  // Firestore listener on every filter change instead of just re-filtering
  // already-received events.
  late final Stream<List<UsageEvent>> _eventsStream = AppServicesScope.of(
    context,
  ).usage.watchRecentEvents(widget.institutionId, limit: 100);

  UsageEventType? _typeFilter;

  String _productName(List<Product> products, String productId) {
    for (final product in products) {
      if (product.id == productId) return product.name;
    }
    return 'Produto removido';
  }

  /// Copies to the clipboard rather than writing a file, to avoid adding a
  /// file-system dependency for a prototype-phase export (spec section 51).
  void _exportCsv(
    BuildContext context,
    List<UsageEvent> events,
    List<Product> products,
  ) {
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('CSV copiado.')));
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  /// Hands the generated PDF bytes to the platform's own print/share sheet
  /// via `printing` — this app never writes the file itself or requests
  /// filesystem access directly.
  Future<void> _exportPdf(
    BuildContext context,
    List<UsageEvent> events,
    List<Product> products,
  ) async {
    await Printing.layoutPdf(
      onLayout: (_) =>
          buildHistoryPdf(events, products, title: 'Histórico de atividade'),
    );
  }

  void _showSummary(
    BuildContext context,
    List<UsageEvent> events,
    List<Product> products,
    List<Cart> carts,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) =>
          _SummaryDialog(events: events, products: products, carts: carts),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              stream: _eventsStream,
              builder: (context, eventsSnapshot) {
                if (eventsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (eventsSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Não foi possível carregar o histórico: ${eventsSnapshot.error}',
                      ),
                    ),
                  );
                }
                final events = (eventsSnapshot.data ?? const <UsageEvent>[])
                    .where(
                      (event) =>
                          _typeFilter == null || event.type == _typeFilter,
                    )
                    .toList();
                if (events.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Sem eventos para mostrar.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return FutureBuilder<List<Product>>(
                  future: _products,
                  builder: (context, productsSnapshot) {
                    final products = productsSnapshot.data ?? const <Product>[];
                    return FutureBuilder<List<Cart>>(
                      future: _carts,
                      builder: (context, cartsSnapshot) {
                        final carts = cartsSnapshot.data ?? const <Cart>[];
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showSummary(
                                      context,
                                      events,
                                      products,
                                      carts,
                                    ),
                                    icon: const Icon(Icons.summarize_outlined),
                                    label: const Text('Ver resumo'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _exportCsv(context, events, products),
                                    icon: const Icon(
                                      Icons.file_download_outlined,
                                    ),
                                    label: const Text('Exportar CSV'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _exportPdf(context, events, products),
                                    icon: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                    ),
                                    label: const Text('Exportar PDF'),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: events.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final event = events[index];
                                  return Card(
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.history_outlined,
                                      ),
                                      title: Text(
                                        _productName(products, event.productId),
                                      ),
                                      subtitle: Text(
                                        usageEventTypeLabel(event.type),
                                      ),
                                      trailing: Text(
                                        '${event.amount > 0 ? '+' : ''}${event.amount}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _SummaryGrouping { product, cart, period }

String _periodLabel(SummaryPeriodUnit unit) {
  switch (unit) {
    case SummaryPeriodUnit.day:
      return 'Dia';
    case SummaryPeriodUnit.week:
      return 'Semana';
    case SummaryPeriodUnit.month:
      return 'Mês';
  }
}

String _formatPeriodStart(DateTime start, SummaryPeriodUnit unit) {
  String two(int n) => n.toString().padLeft(2, '0');
  switch (unit) {
    case SummaryPeriodUnit.day:
    case SummaryPeriodUnit.week:
      return '${two(start.day)}/${two(start.month)}/${start.year}';
    case SummaryPeriodUnit.month:
      return '${two(start.month)}/${start.year}';
  }
}

/// Lets the user switch the history summary between the three grouping
/// dimensions spec section 51 asks for — product, cart, and period — rather
/// than showing three separate entry points for what is otherwise the same
/// dialog.
class _SummaryDialog extends StatefulWidget {
  const _SummaryDialog({
    required this.events,
    required this.products,
    required this.carts,
  });

  final List<UsageEvent> events;
  final List<Product> products;
  final List<Cart> carts;

  @override
  State<_SummaryDialog> createState() => _SummaryDialogState();
}

class _SummaryDialogState extends State<_SummaryDialog> {
  _SummaryGrouping _grouping = _SummaryGrouping.product;
  SummaryPeriodUnit _periodUnit = SummaryPeriodUnit.day;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resumo'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<_SummaryGrouping>(
              segments: const [
                ButtonSegment(
                  value: _SummaryGrouping.product,
                  label: Text('Produto'),
                ),
                ButtonSegment(
                  value: _SummaryGrouping.cart,
                  label: Text('Carro'),
                ),
                ButtonSegment(
                  value: _SummaryGrouping.period,
                  label: Text('Período'),
                ),
              ],
              selected: {_grouping},
              onSelectionChanged: (selection) =>
                  setState(() => _grouping = selection.single),
            ),
            if (_grouping == _SummaryGrouping.period) ...[
              const SizedBox(height: 8),
              SegmentedButton<SummaryPeriodUnit>(
                segments: [
                  for (final unit in SummaryPeriodUnit.values)
                    ButtonSegment(value: unit, label: Text(_periodLabel(unit))),
                ],
                selected: {_periodUnit},
                onSelectionChanged: (selection) =>
                    setState(() => _periodUnit = selection.single),
              ),
            ],
            const SizedBox(height: 12),
            Flexible(child: SingleChildScrollView(child: _buildContent())),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_grouping) {
      case _SummaryGrouping.product:
        final summaries = summarizeByProduct(widget.events, widget.products);
        if (summaries.isEmpty) return const Text('Sem dados para resumir.');
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final summary in summaries)
              _SummaryRow(
                label: summary.productName,
                consumed: summary.consumed,
                replenished: summary.replenished,
                otherAdjustments: summary.otherAdjustments,
              ),
          ],
        );
      case _SummaryGrouping.cart:
        final summaries = summarizeByCart(widget.events, widget.carts);
        if (summaries.isEmpty) return const Text('Sem dados para resumir.');
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final summary in summaries)
              _SummaryRow(
                label: summary.cartName,
                consumed: summary.consumed,
                replenished: summary.replenished,
                otherAdjustments: summary.otherAdjustments,
              ),
          ],
        );
      case _SummaryGrouping.period:
        final summaries = summarizeByPeriod(widget.events, _periodUnit);
        if (summaries.isEmpty) return const Text('Sem dados para resumir.');
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final summary in summaries)
              _SummaryRow(
                label: _formatPeriodStart(summary.periodStart, _periodUnit),
                consumed: summary.consumed,
                replenished: summary.replenished,
                otherAdjustments: summary.otherAdjustments,
              ),
          ],
        );
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.consumed,
    required this.replenished,
    required this.otherAdjustments,
  });

  final String label;
  final int consumed;
  final int replenished;
  final int otherAdjustments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          Text(
            'Consumido: $consumed   Reposto: $replenished'
            '${otherAdjustments == 0 ? '' : '   Outros ajustes: ${otherAdjustments > 0 ? '+' : ''}$otherAdjustments'}',
          ),
        ],
      ),
    );
  }
}
