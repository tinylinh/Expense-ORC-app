import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/receipt.dart';
import '../../shared/charts/spending_charts.dart';
import '../dashboard/dashboard_screen.dart';
import '../receipts/receipt_providers.dart';

const _chartCategories = {
  'Food': Color(0xFFE8483F),
  'Shopping': Color(0xFFE2AD00),
  'Transportation': Color(0xFF17617A),
  'Education': Color(0xFF079B61),
  'Others': Color(0xFFB76B2B),
};

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(receiptsProvider);
    return SafeArea(
      child: receipts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load analytics: $error'),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => ref.read(receiptsProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => _AnalyticsContent(receipts: items),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.receipts});

  final List<Receipt> receipts;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthly = receipts
        .where((item) =>
            item.receiptDate.year == now.year &&
            item.receiptDate.month == now.month)
        .toList(growable: false);
    final totalsByCategory = {
      for (final category in _chartCategories.keys)
        category: monthly
            .where((item) => item.category == category)
            .fold<int>(0, (sum, item) => sum + item.totalAmount),
    };
    final total = monthly.fold<int>(0, (sum, item) => sum + item.totalAmount);
    final values = _chartCategories.keys
        .map((category) => (totalsByCategory[category] ?? 0).toDouble())
        .toList(growable: false);
    final weekly = _thisWeekValues(receipts);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        Text(
          'Analytics',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMMM yyyy').format(now),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        _ChartCard(
          title: 'Expenses by category',
          subtitle: 'Based on saved receipts this month',
          child: monthly.isEmpty
              ? const _ChartEmptyState(
                  message: 'Add a receipt to see category spending.',
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 205,
                      child: DonutChart(
                        values: values,
                        colors: _chartCategories.values.toList(growable: false),
                        centerText: 'Total',
                        totalText: formatVnd(total),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ..._chartCategories.entries.map((entry) {
                      final amount = totalsByCategory[entry.key] ?? 0;
                      final percent = total == 0 ? 0 : amount / total * 100;
                      return _LegendRow(
                        color: entry.value,
                        name: entry.key,
                        percent: '${percent.round()}%',
                        amount: formatVnd(amount),
                      );
                    }),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Daily expenses',
          subtitle: 'This week',
          child: weekly.any((item) => item > 0)
              ? SizedBox(
                  height: 210,
                  child: WeeklyBarChart(
                    values: weekly,
                    labels: _weekLabels(),
                    color: theme.brightness == Brightness.dark
                        ? AppTheme.accent
                        : Colors.black,
                  ),
                )
              : const _ChartEmptyState(
                  message: 'No receipts recorded this week.',
                  compact: true,
                ),
        ),
      ],
    );
  }
}

List<double> _thisWeekValues(List<Receipt> receipts) {
  final today = DateTime.now();
  final monday = DateTime(today.year, today.month, today.day)
      .subtract(Duration(days: today.weekday - 1));
  return List<double>.generate(7, (index) {
    final date = monday.add(Duration(days: index));
    return receipts
        .where((receipt) =>
            receipt.receiptDate.year == date.year &&
            receipt.receiptDate.month == date.month &&
            receipt.receiptDate.day == date.day)
        .fold<int>(0, (sum, item) => sum + item.totalAmount)
        .toDouble();
  }, growable: false);
}

List<String> _weekLabels() => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.name,
    required this.percent,
    required this.amount,
  });

  final Color color;
  final String name;
  final String percent;
  final String amount;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(name)),
            Text(
              percent,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 105,
              child: Text(
                amount,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({required this.message, this.compact = false});

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: compact ? 90 : 135,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
}
