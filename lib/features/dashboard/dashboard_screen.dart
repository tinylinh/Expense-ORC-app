import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/receipt.dart';
import '../receipts/receipt_form_screen.dart';
import '../receipts/receipt_providers.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

String formatVnd(num amount) => NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
).format(amount);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime _month = DateTime.now();

  Future<void> _chooseMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select a date in the month to view',
    );
    if (selected != null) setState(() => _month = selected);
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _openHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiptsProvider);
    final theme = Theme.of(context);
    return SafeArea(
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _LoadError(
          error: error,
          onRetry: () => ref.read(receiptsProvider.notifier).refresh(),
        ),
        data: (receipts) {
          final monthReceipts = receipts
              .where(
                (receipt) =>
                    receipt.receiptDate.year == _month.year &&
                    receipt.receiptDate.month == _month.month,
              )
              .toList(growable: false);
          final total = monthReceipts.fold<int>(
            0,
            (sum, receipt) => sum + receipt.totalAmount,
          );
          return RefreshIndicator(
            onRefresh: () => ref.read(receiptsProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 21,
                            backgroundColor: theme.colorScheme.surface,
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _chooseMonth,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                            ),
                            label: Text(DateFormat('MMMM yyyy').format(_month)),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.onSurface,
                              backgroundColor: theme.colorScheme.surface,
                              shape: const StadiumBorder(),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _openSettings,
                            tooltip: 'Settings',
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _BalanceCard(
                        total: total,
                        receiptCount: monthReceipts.length,
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Text(
                            'Recent transactions',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _openHistory,
                            child: const Text('See all'),
                          ),
                        ],
                      ),
                      if (receipts.isEmpty)
                        const _EmptyReceipts()
                      else
                        ...receipts
                            .take(5)
                            .map(
                              (receipt) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ReceiptListTile(receipt: receipt),
                              ),
                            ),
                      if (receipts.isNotEmpty)
                        Align(
                          alignment: Alignment.center,
                          child: TextButton.icon(
                            onPressed: _openHistory,
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: const Text('Open receipt history'),
                          ),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.total, required this.receiptCount});

  final int total;
  final int receiptCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.brightness == Brightness.dark
              ? const [Color(0xFF24363D), Color(0xFF1A2529)]
              : const [Color(0xFFEAF9FE), Color(0xFFD8F2FB)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Text(
            'Total expenses',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatVnd(total),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.trending_down,
                  title: 'Expenses',
                  value: formatVnd(total),
                  color: AppTheme.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.receipt_long_outlined,
                  title: 'Receipts',
                  value: '$receiptCount this month',
                  color: AppTheme.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 6),
              Text(title, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReceipts extends StatelessWidget {
  const _EmptyReceipts();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 38,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          const Text('No receipts yet'),
          const SizedBox(height: 4),
          Text(
            'Tap + to scan or add your first expense.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiptListTile extends StatelessWidget {
  const ReceiptListTile({super.key, required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _categoryColor(receipt.category);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.13),
          foregroundColor: color,
          child: Icon(_categoryIcon(receipt.category), size: 20),
        ),
        title: Text(
          receipt.merchant,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if (receipt.productName.isNotEmpty) receipt.productName,
            receipt.category,
            DateFormat('MMM d').format(receipt.receiptDate),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            '-${formatVnd(receipt.totalAmount)}',
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReceiptDetailScreen(receipt: receipt),
          ),
        ),
      ),
    );
  }
}

Color _categoryColor(String category) => switch (category) {
  'Food' => const Color(0xFFE8483F),
  'Shopping' => const Color(0xFFE2AD00),
  'Transportation' => const Color(0xFF17617A),
  'Education' => const Color(0xFF079B61),
  'Bills' => const Color(0xFF7558C8),
  'Health' => const Color(0xFFCA4D8D),
  _ => const Color(0xFFB76B2B),
};

IconData _categoryIcon(String category) => switch (category) {
  'Food' => Icons.restaurant_outlined,
  'Shopping' => Icons.shopping_bag_outlined,
  'Transportation' => Icons.directions_bus_outlined,
  'Education' => Icons.school_outlined,
  'Bills' => Icons.receipt_long_outlined,
  'Health' => Icons.health_and_safety_outlined,
  _ => Icons.more_horiz,
};

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42),
          const SizedBox(height: 12),
          const Text('Could not load your receipts.'),
          const SizedBox(height: 4),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class ReceiptDetailScreen extends ConsumerWidget {
  const ReceiptDetailScreen({super.key, required this.receipt});

  final Receipt receipt;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final id = receipt.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete receipt?'),
        content: const Text(
          'This will permanently remove this receipt and image.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(receiptsProvider.notifier).delete(id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete receipt: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePath = receipt.imagePath;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt details'),
        actions: [
          IconButton(
            tooltip: 'Edit receipt',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReceiptFormScreen(receipt: receipt),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete receipt',
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          if (imagePath != null && File(imagePath).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(imagePath),
                height: 260,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 22),
          Text(
            receipt.merchant,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 7),
          Text(
            formatVnd(receipt.totalAmount),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 22),
          _DetailRow(
            label: 'Date',
            value: DateFormat('dd MMMM yyyy').format(receipt.receiptDate),
          ),
          if (receipt.productName.isNotEmpty)
            _DetailRow(label: 'Product', value: receipt.productName),
          _DetailRow(label: 'Category', value: receipt.category),
          if (receipt.rawOcrText.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Recognized text',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(receipt.rawOcrText),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
