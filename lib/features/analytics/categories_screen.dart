import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../receipts/receipt_form_screen.dart';
import '../receipts/receipt_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(receiptsProvider);
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Expense categories')),
      body: receipts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load categories: $error'),
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
        data: (items) {
          final monthly = items
              .where(
                (receipt) =>
                    receipt.receiptDate.year == now.year &&
                    receipt.receiptDate.month == now.month,
              )
              .toList(growable: false);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  'This month · ${monthly.length} receipts',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              ...receiptCategories.map((category) {
                final matching = monthly
                    .where((receipt) => receipt.category == category)
                    .toList(growable: false);
                final total = matching.fold<int>(
                  0,
                  (sum, receipt) => sum + receipt.totalAmount,
                );
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(_categoryIcon(category))),
                    title: Text(category),
                    subtitle: Text('${matching.length} receipts'),
                    trailing: Text(
                      formatVnd(total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            HistoryScreen(initialCategory: category),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

IconData _categoryIcon(String category) => switch (category) {
  'Food' => Icons.restaurant_outlined,
  'Shopping' => Icons.shopping_bag_outlined,
  'Transportation' => Icons.directions_bus_outlined,
  'Education' => Icons.school_outlined,
  'Bills' => Icons.receipt_long_outlined,
  'Health' => Icons.health_and_safety_outlined,
  _ => Icons.more_horiz,
};
