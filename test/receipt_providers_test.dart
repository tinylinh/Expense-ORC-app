import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_orc/data/database/app_database.dart';
import 'package:expense_orc/data/models/receipt.dart';
import 'package:expense_orc/data/repositories/receipt_repository.dart';
import 'package:expense_orc/features/receipts/receipt_providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late ProviderContainer container;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'expense_orc_state_test_',
    );
    database = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      databasePath: '${directory.path}${Platform.pathSeparator}receipts.db',
    );
    container = ProviderContainer(
      overrides: [
        receiptRepositoryProvider.overrideWithValue(
          ReceiptRepository(database),
        ),
      ],
    );
    await container.read(receiptsProvider.notifier).refresh();
  });

  tearDown(() async {
    container.dispose();
    await database.close();
    await directory.delete(recursive: true);
  });

  test('refreshes receipt state after create, update, and delete', () async {
    final notifier = container.read(receiptsProvider.notifier);
    await notifier.save(
      Receipt(
        merchant: 'Cafe A',
        totalAmount: 100000,
        receiptDate: DateTime(2026, 10, 24),
        category: 'Food',
      ),
    );
    var receipts = container.read(receiptsProvider).requireValue;
    expect(receipts, hasLength(1));
    final saved = receipts.single;

    await notifier.update(
      saved.copyWith(merchant: 'Cafe B', totalAmount: 125000),
    );
    receipts = container.read(receiptsProvider).requireValue;
    expect(receipts.single.merchant, 'Cafe B');
    expect(receipts.single.totalAmount, 125000);

    await notifier.delete(saved.id!);
    expect(container.read(receiptsProvider).requireValue, isEmpty);
  });
}
