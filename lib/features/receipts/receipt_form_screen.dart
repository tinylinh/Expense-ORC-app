import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/receipt.dart';
import '../scanner/receipt_parser.dart';
import 'receipt_providers.dart';

const receiptCategories = [
  'Food',
  'Shopping',
  'Transportation',
  'Education',
  'Others',
];

class ReceiptFormScreen extends ConsumerStatefulWidget {
  const ReceiptFormScreen({
    super.key,
    this.imagePath,
    this.parsed,
    this.rawOcrText = '',
    this.ocrLines = const [],
    this.receipt,
  });

  final String? imagePath;
  final ParsedReceipt? parsed;
  final String rawOcrText;
  final List<String> ocrLines;
  final Receipt? receipt;

  @override
  ConsumerState<ReceiptFormScreen> createState() => _ReceiptFormScreenState();
}

class _ReceiptFormScreenState extends ConsumerState<ReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late DateTime? _date;
  late String _category;
  late final String _ocrText;
  bool _saving = false;

  bool get _isEditing => widget.receipt != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.receipt;
    _merchantController = TextEditingController(
      text: existing?.merchant ?? widget.parsed?.merchant ?? '',
    );
    _amountController = TextEditingController(
      text:
          (existing?.totalAmount ?? widget.parsed?.totalAmount)?.toString() ??
          '',
    );
    _ocrText = widget.rawOcrText.isNotEmpty
        ? widget.rawOcrText
        : existing?.rawOcrText ?? '';
    _date = existing?.receiptDate ?? widget.parsed?.receiptDate;
    _category = existing?.category ?? receiptCategories.first;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the receipt date.')),
      );
      return;
    }
    setState(() => _saving = true);
    final existing = widget.receipt;
    final receipt = Receipt(
      id: existing?.id,
      merchant: _merchantController.text.trim(),
      totalAmount: _parseAmountInput(_amountController.text)!,
      receiptDate: _date!,
      category: _category,
      imagePath: widget.imagePath ?? existing?.imagePath,
      rawOcrText: _ocrText,
      createdAt: existing?.createdAt,
    );
    try {
      if (_isEditing) {
        await ref.read(receiptsProvider.notifier).update(receipt);
      } else {
        await ref.read(receiptsProvider.notifier).save(receipt);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Receipt updated successfully.'
                : 'Receipt saved successfully.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save receipt: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = widget.imagePath ?? widget.receipt?.imagePath;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit receipt' : 'Review receipt'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              if (imagePath != null && File(imagePath).existsSync()) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(imagePath),
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                          height: 120,
                          child: Center(
                            child: Icon(Icons.receipt_long_outlined),
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 22),
              ],
              Text(
                'Check the details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'OCR can be imperfect. Correct anything before saving.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _merchantController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Merchant',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a merchant'
                    : null,
              ),
              if (widget.parsed?.merchant == null && !_isEditing)
                const _MissingValueHint(field: 'Merchant'),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                  signed: false,
                ),
                decoration: const InputDecoration(
                  labelText: 'Total amount (VND)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final amount = _parseAmountInput(value ?? '');
                  return amount == null || amount <= 0
                      ? 'Enter a valid whole VND amount'
                      : null;
                },
              ),
              if (widget.parsed?.totalAmount == null && !_isEditing)
                const _MissingValueHint(field: 'Total amount'),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _date == null
                        ? 'Select receipt date'
                        : DateFormat('dd MMM yyyy').format(_date!),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 17,
                  ),
                ),
              ),
              if (_date == null && !_isEditing)
                const _MissingValueHint(field: 'Receipt date'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: receiptCategories
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              if (_ocrText.isNotEmpty) ...[
                const SizedBox(height: 14),
                Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.text_snippet_outlined),
                    title: const Text('Recognized text'),
                    subtitle: Text(
                      widget.ocrLines.isEmpty
                          ? 'Tap to inspect the original OCR result'
                          : '${widget.ocrLines.length} recognized lines',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(_ocrText),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 26),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.brightness == Brightness.dark
                      ? AppTheme.accent
                      : Colors.black,
                  foregroundColor: theme.brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Update receipt' : 'Save receipt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingValueHint extends StatelessWidget {
  const _MissingValueHint({required this.field});

  final String field;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 12, top: 5),
    child: Text(
      '$field was not detected. Please enter it manually.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    ),
  );
}

int? _parseAmountInput(String value) {
  final normalized = value.trim();
  if (!RegExp(r'^(?:\d+|\d{1,3}(?:[.,\s]\d{3})+)$').hasMatch(normalized)) {
    return null;
  }
  return int.tryParse(normalized.replaceAll(RegExp(r'[.,\s]'), ''));
}
