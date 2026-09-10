import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/l10n/app_localizations.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/cart_product_assignment.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/slot.dart';
import '../../domain/entities/usage_event.dart';
import '../scanning/gs1_scan_screen.dart';
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
  String? _scannedGtin;

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
    } on RepositoryFailure catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = error.reason == RepositoryFailureReason.conflict
          ? l10n.assignConflictError
          : l10n.assignGenericError;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
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
        SnackBar(
          content: Text(AppLocalizations.of(context).consumeExceedsError),
        ),
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
        SnackBar(
          content: Text(AppLocalizations.of(context).consumeGenericError),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitReplenishment() async {
    if (!_formKey.currentState!.validate() || _expiryDate == null) {
      if (_expiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).replenishMissingExpiry),
          ),
        );
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
        batch: Batch(
          id: '',
          assignmentId: assignment.id,
          lotNumber: _lotController.text.trim(),
          expiryDate: _expiryDate!,
          gtin: _scannedGtin,
          source: _scannedGtin == null
              ? BatchSource.manual
              : BatchSource.gs1DataMatrix,
        ),
        actorUid: services.auth.currentUser!.uid,
      );
      if (mounted) Navigator.of(context).pop();
    } on RepositoryFailure catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).replenishGenericError),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Spec section 30's replenishment flow: scan is optional and retryable
  /// (the scan screen itself keeps listening until it parses something or
  /// the user cancels), pre-fills lot/expiry but never replaces manual entry
  /// as the fallback, and an unknown GTIN is never silently attached to the
  /// slot's product (spec section 30) — it only prefills the batch's own
  /// `gtin`/`source` fields.
  Future<void> _startGs1Scan(
    void Function(void Function()) setDialogState,
  ) async {
    final services = AppServicesScope.of(context);
    final result = await showGs1ScanScreen(
      context,
      createScanner: services.createGs1Scanner,
    );
    if (result == null || !mounted) return;

    if (result.gtin != null) {
      final match = await services.products.findByGtin(
        widget.institutionId,
        result.gtin!,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      if (match == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.gs1UnknownGtin)));
      } else if (match.id != widget.assignment!.productId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.gs1WrongProductWarning(match.name))),
        );
      }
    }

    setDialogState(() {
      _scannedGtin = result.gtin;
      if (result.lotNumber != null) _lotController.text = result.lotNumber!;
      if (result.expiryDate != null) _expiryDate = result.expiryDate;
    });
  }

  Future<void> _enterReconcileMode() async {
    final assignment = widget.assignment!;
    final services = AppServicesScope.of(context);
    final batches = await services.inventory
        .watchBatches(widget.institutionId, widget.cartId, assignment.id)
        .first;
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
    final confirmedBatches = _batches!
        .where((b) => _confirmedBatchIds.contains(b.id))
        .toList();
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
        SnackBar(
          content: Text(AppLocalizations.of(context).reconcileGenericError),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _enterCorrectMode() async {
    final assignment = widget.assignment!;
    final services = AppServicesScope.of(context);
    final events = await services.usage
        .watchEventsForAssignment(widget.institutionId, assignment.id)
        .first;
    if (!mounted) return;
    setState(() {
      _events = events;
      _selectedEventToCorrect = events.isEmpty ? null : events.first;
      _correctionAmountController.text = events.isEmpty
          ? ''
          : '${-events.first.amount}';
      _mode = _Mode.correct;
    });
  }

  Future<void> _submitCorrection() async {
    if (!_formKey.currentState!.validate() || _selectedEventToCorrect == null) {
      return;
    }
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
        SnackBar(
          content: Text(AppLocalizations.of(context).correctGenericError),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final assignment = widget.assignment;
    if (assignment == null && !widget.canManage) {
      return AlertDialog(
        title: Text(l10n.emptySlotTitle),
        content: Text(l10n.emptySlotMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionClose),
          ),
        ],
      );
    }

    switch (_mode) {
      case _Mode.assign:
        return AlertDialog(
          title: Text(l10n.assignDialogTitle),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.products.isEmpty)
                  Text(l10n.noProductsMessage)
                else
                  DropdownButtonFormField<Product>(
                    initialValue: _selectedProduct,
                    decoration: InputDecoration(labelText: l10n.productLabel),
                    items: [
                      for (final product in widget.products)
                        DropdownMenuItem(
                          value: product,
                          child: Text(product.name),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedProduct = value),
                    validator: (value) =>
                        value == null ? l10n.chooseProductValidation : null,
                  ),
                TextFormField(
                  controller: _initialController,
                  decoration: InputDecoration(
                    labelText: l10n.initialQuantityLabel,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => _validateNonNegativeInt(l10n, value),
                ),
                TextFormField(
                  controller: _targetController,
                  decoration: InputDecoration(
                    labelText: l10n.targetQuantityLabel,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => _validateNonNegativeInt(l10n, value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: (_saving || widget.products.isEmpty)
                  ? null
                  : _submitAssign,
              child: Text(l10n.actionAssign),
            ),
          ],
        );

      case _Mode.consume:
        return AlertDialog(
          title: Text(l10n.recordConsumptionTitle),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _amountController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.consumedQuantityLabel,
              ),
              keyboardType: TextInputType.number,
              validator: (value) => _validatePositiveInt(l10n, value),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => setState(() => _mode = _Mode.view),
              child: Text(l10n.actionBack),
            ),
            FilledButton(
              onPressed: _saving ? null : _submitConsumption,
              child: Text(l10n.actionConfirm),
            ),
          ],
        );

      case _Mode.replenish:
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(l10n.replenishStockTitle),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _amountController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.receivedQuantityLabel,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => _validatePositiveInt(l10n, value),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _startGs1Scan(setDialogState),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(l10n.gs1ScanTitle),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _lotController,
                    decoration: InputDecoration(labelText: l10n.lotNumberLabel),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? l10n.lotRequiredValidation
                        : null,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _expiryDate == null
                          ? l10n.chooseExpiryLabel
                          : l10n.expiryDateLabel(_formatDate(_expiryDate!)),
                    ),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() => _expiryDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => setState(() => _mode = _Mode.view),
                child: Text(l10n.actionBack),
              ),
              FilledButton(
                onPressed: _saving ? null : _submitReplenishment,
                child: Text(l10n.actionConfirm),
              ),
            ],
          ),
        );

      case _Mode.reconcile:
        final batches = _batches ?? const <Batch>[];
        return AlertDialog(
          title: Text(l10n.reconcileDialogTitle),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _confirmedQuantityController,
                    decoration: InputDecoration(
                      labelText: l10n.confirmedQuantityLabel,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateNonNegativeInt(l10n, value),
                  ),
                  const SizedBox(height: 12),
                  if (batches.isEmpty)
                    Text(l10n.noBatchesMessage)
                  else ...[
                    Text(l10n.confirmedBatchesLabel),
                    for (final batch in batches)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _confirmedBatchIds.contains(batch.id),
                        title: Text(l10n.batchLotLabel(batch.lotNumber)),
                        subtitle: Text(
                          l10n.expiryDateLabel(_formatDate(batch.expiryDate)),
                        ),
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
            TextButton(
              onPressed: () => setState(() => _mode = _Mode.view),
              child: Text(l10n.actionBack),
            ),
            FilledButton(
              onPressed: _saving ? null : _submitReconciliation,
              child: Text(l10n.actionConfirm),
            ),
          ],
        );

      case _Mode.correct:
        final events = _events ?? const <UsageEvent>[];
        return AlertDialog(
          title: Text(l10n.correctEventDialogTitle),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (events.isEmpty)
                    Text(l10n.noEventsToCorrect)
                  else
                    DropdownButtonFormField<UsageEvent>(
                      initialValue: _selectedEventToCorrect,
                      decoration: InputDecoration(
                        labelText: l10n.eventToCorrectLabel,
                      ),
                      items: [
                        for (final event in events)
                          DropdownMenuItem(
                            value: event,
                            child: Text(
                              '${usageEventTypeLabel(context, event.type)}: ${event.amount > 0 ? '+' : ''}${event.amount}',
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _selectedEventToCorrect = value;
                        _correctionAmountController.text = value == null
                            ? ''
                            : '${-value.amount}';
                      }),
                      validator: (value) =>
                          value == null ? l10n.chooseEventValidation : null,
                    ),
                  TextFormField(
                    controller: _correctionAmountController,
                    decoration: InputDecoration(
                      labelText: l10n.adjustmentLabel,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    validator: (value) => _validateNonZeroInt(l10n, value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => setState(() => _mode = _Mode.view),
              child: Text(l10n.actionBack),
            ),
            FilledButton(
              onPressed: (_saving || events.isEmpty) ? null : _submitCorrection,
              child: Text(l10n.actionConfirm),
            ),
          ],
        );

      case _Mode.view:
        final product = _productFor(assignment!.productId);
        return AlertDialog(
          title: Text(product?.name ?? l10n.productRemoved),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.currentTargetLabel(
                  assignment.currentQuantity,
                  assignment.targetQuantity,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(assignmentStatusLabel(context, assignment.status)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionClose),
            ),
            TextButton(
              onPressed: _enterCorrectMode,
              child: Text(l10n.actionCorrect),
            ),
            if (widget.canManage) ...[
              TextButton(
                onPressed: () => setState(() => _mode = _Mode.replenish),
                child: Text(l10n.replenishStockTitle),
              ),
              TextButton(
                onPressed: _enterReconcileMode,
                child: Text(l10n.actionReconcile),
              ),
            ],
            FilledButton(
              onPressed: () => setState(() => _mode = _Mode.consume),
              child: Text(l10n.recordConsumptionTitle),
            ),
          ],
        );
    }
  }
}

String? _validatePositiveInt(AppLocalizations l10n, String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed <= 0) return l10n.validatePositiveInt;
  return null;
}

String? _validateNonNegativeInt(AppLocalizations l10n, String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed < 0) return l10n.validateNonNegativeInt;
  return null;
}

String? _validateNonZeroInt(AppLocalizations l10n, String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed == 0) {
    return l10n.validateNonZeroInt;
  }
  return null;
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
