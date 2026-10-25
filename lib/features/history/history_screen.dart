import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../dashboard/dashboard_screen.dart';
import '../receipts/receipt_form_screen.dart';
import '../receipts/receipt_providers.dart';

enum _ReceiptSort { newest, oldest, highestAmount }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  late String _category;
  _ReceiptSort _sort = _ReceiptSort.newest;
  DateTime? _monthFilter;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? 'All categories';
  }

  Future<void> _chooseMonth() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _monthFilter ?? today,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select a date in the month to filter',
    );
    if (selected != null) setState(() => _monthFilter = selected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(receiptsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt history')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load receipts: $error'),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.read(receiptsProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (receipts) {
          final filtered = receipts
              .where(
                (receipt) =>
                    (_category == 'All categories' ||
                        receipt.category == _category) &&
                    (_monthFilter == null ||
                        (receipt.receiptDate.year == _monthFilter!.year &&
                            receipt.receiptDate.month ==
                                _monthFilter!.month)) &&
                    ('${receipt.merchant} ${receipt.productName}')
                        .toLowerCase()
                        .contains(_searchController.text.trim().toLowerCase()),
              )
              .toList();
          switch (_sort) {
            case _ReceiptSort.newest:
              filtered.sort((a, b) => b.receiptDate.compareTo(a.receiptDate));
            case _ReceiptSort.oldest:
              filtered.sort((a, b) => a.receiptDate.compareTo(b.receiptDate));
            case _ReceiptSort.highestAmount:
              filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search merchant or product',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: ['All categories', ...receiptCategories]
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _category = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<_ReceiptSort>(
                            initialValue: _sort,
                            decoration: const InputDecoration(
                              labelText: 'Sort',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: _ReceiptSort.newest,
                                child: Text('Newest'),
                              ),
                              DropdownMenuItem(
                                value: _ReceiptSort.oldest,
                                child: Text('Oldest'),
                              ),
                              DropdownMenuItem(
                                value: _ReceiptSort.highestAmount,
                                child: Text('Amount'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _sort = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: _chooseMonth,
                            icon: const Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                            ),
                            label: Text(
                              _monthFilter == null
                                  ? 'Filter by month'
                                  : DateFormat(
                                      'MMMM yyyy',
                                    ).format(_monthFilter!),
                            ),
                          ),
                          if (_monthFilter != null)
                            IconButton(
                              tooltip: 'Clear date filter',
                              onPressed: () =>
                                  setState(() => _monthFilter = null),
                              icon: const Icon(Icons.close, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            receipts.isEmpty
                                ? 'No saved receipts yet. Scan a receipt to get started.'
                                : 'No receipts match your search.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(receiptsProvider.notifier).refresh(),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final receipt = filtered[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                leading: CircleAvatar(
                                  child: Text(
                                    receipt.merchant.isEmpty
                                        ? '?'
                                        : receipt.merchant[0].toUpperCase(),
                                  ),
                                ),
                                title: Text(
                                  receipt.merchant,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${receipt.category} · ${DateFormat('dd MMM yyyy').format(receipt.receiptDate)}',
                                ),
                                trailing: Text(
                                  formatVnd(receipt.totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReceiptDetailScreen(receipt: receipt),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
