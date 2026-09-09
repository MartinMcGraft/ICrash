import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/cart_product_assignment.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/slot.dart';
import '../../domain/entities/usage_event.dart';
import 'assignment_status_label.dart';

enum _Mode { view, assign, consume, replenish, reconcile, correct }

/// One slot's product assignment: shows what is currently assigned (if
/// anything) and lets the user record daily consumption. Assigning a new
/// product or replenishing stock changes fields Rules reserve to manager+
/// (`earliestKnownExpiry`, `batches`), so those actions are hidden — never
/// disabled-but-visible — for anyone else; consumption only touches
/// `currentQuantity`, which any user with cart access may do (spec sections
/// 17, 22-24).
Future<void> showAssignmentDialog(
  BuildContext context, {
  required String institutionId,
  required String cartId,
  required Slot slot,
  required CartProductAssignment? assignment,
  required List<Product> products,
  required bool canManage,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AssignmentDialog(
      institutionId: institutionId,
      cartId: cartId,
      slot: slot,
      assignment: assignment,
      products: products,
      canManage: canManage,
    ),
  );
}

class _AssignmentDialog extends StatefulWidget {
  const _AssignmentDialog({
    required this.institutionId,
    required this.cartId,
    required this.slot,
    required this.assignment,
    required this.products,
    required this.canManage,
  });

  final String institutionId;
  final String cartId;
  final Slot slot;
  final CartProductAssignment? assignment;
  final List<Product> products;
  final bool canManage;

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  late _Mode _mode = widget.assignment == null ? _Mode.assign : _Mode.view;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  Product? _selectedProduct;
  final _targetController = TextEditingController(text: '1');
  final _initialController = TextEditingController(text: '0');
  final _amountController = TextEditingController();
  final _lotController = TextEditingController();
  DateTime? _expiryDate;

  List<Batch>? _batches;
  Set<String> _confirmedBatchIds = {};
  final _confirmedQuantityController = TextEditingController();

  List<UsageEvent>? _events;
  UsageEvent? _selectedEventToCorrect;
  final _correctionAmountController = TextEditingController();

  @override
  void dispose() {
    _targetController.dispose();
    _initialController.dispose();
    _amountController.dispose();
    _lotController.dispose();
    _confirmedQuantityController.dispose();
    _correctionAmountController.dispose();
    super.dispose();
  }

  Product? _productFor(String productId) {
    for (final product in widget.products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  Future<void> _submitAssign() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) return;
    setState(() => _saving = true);
    final services = AppServicesScope.of(context);
    try {
      await services.inventory.createAssignment(
        widget.institutionId,
        widget.cartId,
        CartProductAssignment(
          id: '',
          cartId: widget.cartId,
          slotId: widget.slot.id,
          productId: _selectedProduct!.id,
          currentQuantity: int.parse(_initialController.text),
          targetQuantity: int.parse(_targetController.text),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on RepositoryFailure catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atribuir o produto. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitConsumption() async {
    if (!_formKey.currentState!.validate()) return;
    final assignment = widget.assignment!;
    final amount = int.parse(_amountController.text);
    if (amount > assignment.currentQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não pode consumir mais do que a quantidade atual.')),
      );
      return;
    }
    setState(() => _saving = true);
    final services = AppServicesScope.of(context);
    try {
      await services.inventory.recordConsumption(
        institutionId: widget.institutionId,
        cartId: widget.cartId,
        assignmentId: assignment.id,
        amount: amount,
        actorUid: services.auth.currentUser!.uid,
      );
      if (mounted) Navigator.of(context).pop();
    } on RepositoryFailure catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível registar o consumo. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitReplenishment() async {
    if (!_formKey.currentState!.validate() || _expiryDate == null) {
      if (_expiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indique a validade do lote.')));
      }
      return;
    }
    final assignment = widget.assignment!;
    final amount = int.parse(_amountController.text);
    setState(() => _saving = true);
    final services = AppServicesScope.of(context);
    try {
      await services.inventory.recordReplenishment(
        institutionId: widget.institutionId,
        cartId: widget.cartId,
        assignmentId: assignment.id,
        amount: amount,
        batch: Batch(id: '', assignmentId: assignment.id, lotNumber: _lotController.text.trim(), expiryDate: _expiryDate!),
        actorUid: services.auth.currentUser!.uid,
      );
      if (mounted) Navigator.of(context).pop();
    } on RepositoryFailure catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível repor o stock. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _enterReconcileMode() async {
    final assignment = widget.assignment!;
    final services = AppServicesScope.of(context);
    final batches = await services.inventory.watchBatches(widget.institutionId, widget.cartId, assignment.id).first;
    if (!mounted) return;
    setState(() {
      _batches = batches;
      _confirmedBatchIds = batches.map((b) => b.id).toSet();
      _confirmedQuantityController.text = '${assignment.currentQuantity}';
      _mode = _Mode.reconcile;
    });
  }

  Future<void> _submitReconciliation() async {
    if (!_formKey.currentState!.validate()) return;
    final assignment = widget.assignment!;
    final confirmedQuantity = int.parse(_confirmedQuantityController.text);
    final confirmedBatches = _batches!.where((b) => _confirmedBatchIds.contains(b.id)).toList();
    setState(() => _saving = true);
    final services = AppServicesScope.of(context);
    try {
      await services.inventory.reconcileAfterAudit(
        institutionId: widget.institutionId,
        cartId: widget.cartId,
        assignmentId: assignment.id,
        confirmedQuantity: confirmedQuantity,
        confirmedBatches: confirmedBatches,
        actorUid: services.auth.currentUser!.uid,
      );
      if (mounted) Navigator.of(context).pop();
    } on RepositoryFailure catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível reconciliar. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _enterCorrectMode() async {
    final assignment = widget.assignment!;
    final services = AppServicesScope.of(context);
    final events = await services.usage.watchEventsForAssignment(widget.institutionId, assignment.id).first;
    if (!mounted) return;
    setState(() {
      _events = events;
      _selectedEventToCorrect = events.isEmpty ? null : events.first;
      _correctionAmountController.text = events.isEmpty ? '' : '${-events.first.amount}';
      _mode = _Mode.correct;
    });
  }

  Future<void> _submitCorrection() async {
    if (!_formKey.currentState!.validate() || _selectedEventToCorrect == null) return;
    final assignment = widget.assignment!;
    final amount = int.parse(_correctionAmountController.text);
    setState(() => _saving = true);
    final services = AppServicesScope.of(context);
    try {
      await services.inventory.recordCorrection(
        institutionId: widget.institutionId,
        cartId: widget.cartId,
        assignmentId: assignment.id,
        amount: amount,
        correctsEventId: _selectedEventToCorrect!.id,
        actorUid: services.auth.currentUser!.uid,
      );
      if (mounted) Navigator.of(context).pop();
    } on RepositoryFailure catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível corrigir. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    if (assignment == null && !widget.canManage) {
      return AlertDialog(
        title: const Text('Slot vazio'),
        content: const Text('Este slot ainda não tem produto atribuído.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
        ],
      );
    }

    switch (_mode) {
      case _Mode.assign:
        return AlertDialog(
          title: const Text('Atribuir produto'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.products.isEmpty)
                  const Text('Crie primeiro um produto no catálogo da instituição.')
                else
                  DropdownButtonFormField<Product>(
                    initialValue: _selectedProduct,
                    decoration: const InputDecoration(labelText: 'Produto'),
                    items: [
                      for (final product in widget.products) DropdownMenuItem(value: product, child: Text(product.name)),
                    ],
                    onChanged: (value) => setState(() => _selectedProduct = value),
                    validator: (value) => value == null ? 'Escolha um produto' : null,
                  ),
                TextFormField(
                  controller: _initialController,
                  decoration: const InputDecoration(labelText: 'Quantidade inicial'),
                  keyboardType: TextInputType.number,
                  validator: _validateNonNegativeInt,
                ),
                TextFormField(
                  controller: _targetController,
                  decoration: const InputDecoration(labelText: 'Quantidade alvo'),
                  keyboardType: TextInputType.number,
                  validator: _validateNonNegativeInt,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            FilledButton(
              onPressed: (_saving || widget.products.isEmpty) ? null : _submitAssign,
              child: const Text('Atribuir'),
            ),
          ],
        );

      case _Mode.consume:
        return AlertDialog(
          title: const Text('Registar consumo'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _amountController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Quantidade consumida'),
              keyboardType: TextInputType.number,
              validator: _validatePositiveInt,
            ),
          ),
          actions: [
            TextButton(onPressed: () => setState(() => _mode = _Mode.view), child: const Text('Voltar')),
            FilledButton(onPressed: _saving ? null : _submitConsumption, child: const Text('Confirmar')),
          ],
        );

      case _Mode.replenish:
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Repor stock'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _amountController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Quantidade recebida'),
                    keyboardType: TextInputType.number,
                    validator: _validatePositiveInt,
                  ),
                  TextFormField(
                    controller: _lotController,
                    decoration: const InputDecoration(labelText: 'Número de lote'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Indique o lote' : null,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_expiryDate == null ? 'Escolher validade' : 'Validade: ${_formatDate(_expiryDate!)}'),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) setDialogState(() => _expiryDate = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => setState(() => _mode = _Mode.view), child: const Text('Voltar')),
              FilledButton(onPressed: _saving ? null : _submitReplenishment, child: const Text('Confirmar')),
            ],
          ),
        );

      case _Mode.reconcile:
        final batches = _batches ?? const <Batch>[];
        return AlertDialog(
          title: const Text('Reconciliar (auditoria)'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _confirmedQuantityController,
                    decoration: const InputDecoration(labelText: 'Quantidade confirmada fisicamente'),
                    keyboardType: TextInputType.number,
                    validator: _validateNonNegativeInt,
                  ),
                  const SizedBox(height: 12),
                  if (batches.isEmpty)
                    const Text('Sem lotes registados; a reconciliação fica sem lotes confirmados.')
                  else ...[
                    const Text('Lotes confirmados como fisicamente presentes:'),
                    for (final batch in batches)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _confirmedBatchIds.contains(batch.id),
                        title: Text('Lote ${batch.lotNumber}'),
                        subtitle: Text('Validade: ${_formatDate(batch.expiryDate)}'),
                        onChanged: (checked) => setState(() {
                          if (checked ?? false) {
                            _confirmedBatchIds.add(batch.id);
                          } else {
                            _confirmedBatchIds.remove(batch.id);
                          }
                        }),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => setState(() => _mode = _Mode.view), child: const Text('Voltar')),
            FilledButton(onPressed: _saving ? null : _submitReconciliation, child: const Text('Confirmar')),
          ],
        );

      case _Mode.correct:
        final events = _events ?? const <UsageEvent>[];
        return AlertDialog(
          title: const Text('Corrigir evento'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (events.isEmpty)
                    const Text('Ainda não existem eventos para corrigir.')
                  else
                    DropdownButtonFormField<UsageEvent>(
                      initialValue: _selectedEventToCorrect,
                      decoration: const InputDecoration(labelText: 'Evento a corrigir'),
                      items: [
                        for (final event in events)
                          DropdownMenuItem(
                            value: event,
                            child: Text('${usageEventTypeLabel(event.type)}: ${event.amount > 0 ? '+' : ''}${event.amount}'),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _selectedEventToCorrect = value;
                        _correctionAmountController.text = value == null ? '' : '${-value.amount}';
                      }),
                      validator: (value) => value == null ? 'Escolha um evento' : null,
                    ),
                  TextFormField(
                    controller: _correctionAmountController,
                    decoration: const InputDecoration(labelText: 'Ajuste (positivo ou negativo)'),
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    validator: _validateNonZeroInt,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => setState(() => _mode = _Mode.view), child: const Text('Voltar')),
            FilledButton(
              onPressed: (_saving || events.isEmpty) ? null : _submitCorrection,
              child: const Text('Confirmar'),
            ),
          ],
        );

      case _Mode.view:
        final product = _productFor(assignment!.productId);
        return AlertDialog(
          title: Text(product?.name ?? 'Produto removido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Atual: ${assignment.currentQuantity}   Alvo: ${assignment.targetQuantity}'),
              const SizedBox(height: 8),
              Chip(label: Text(assignmentStatusLabel(assignment.status))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
            TextButton(onPressed: _enterCorrectMode, child: const Text('Corrigir')),
            if (widget.canManage) ...[
              TextButton(
                onPressed: () => setState(() => _mode = _Mode.replenish),
                child: const Text('Repor stock'),
              ),
              TextButton(onPressed: _enterReconcileMode, child: const Text('Reconciliar')),
            ],
            FilledButton(
              onPressed: () => setState(() => _mode = _Mode.consume),
              child: const Text('Registar consumo'),
            ),
          ],
        );
    }
  }
}

String? _validatePositiveInt(String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed <= 0) return 'Indique um número positivo';
  return null;
}

String? _validateNonNegativeInt(String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed < 0) return 'Indique um número válido';
  return null;
}

String? _validateNonZeroInt(String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed == 0) return 'Indique um ajuste diferente de zero';
  return null;
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
