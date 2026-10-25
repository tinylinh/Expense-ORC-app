import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:expense_orc/data/database/app_database.dart';
import 'package:expense_orc/data/models/receipt.dart';
import 'package:expense_orc/data/repositories/receipt_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late ReceiptRepository repository;
  late String databasePath;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('expense_orc_test_');
    databasePath = '${directory.path}${Platform.pathSeparator}receipts.db';
    database = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    repository = ReceiptRepository(database);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('serializes a receipt without losing its fields', () {
    final receipt = Receipt(
      id: 7,
      merchant: 'Cửa hàng',
      totalAmount: 125000,
      receiptDate: DateTime(2026, 10, 24),
      category: 'Food',
      productName: 'Cà phê sữa',
      rawOcrText: 'TỔNG TIỀN: 125.000',
      createdAt: DateTime(2026, 10, 24, 8),
      updatedAt: DateTime(2026, 10, 24, 9),
    );

    final restored = Receipt.fromMap(receipt.toMap());

    expect(restored.id, 7);
    expect(restored.merchant, receipt.merchant);
    expect(restored.totalAmount, 125000);
    expect(restored.productName, 'Cà phê sữa');
    expect(restored.receiptDate, DateTime(2026, 10, 24));
    expect(restored.rawOcrText, receipt.rawOcrText);
  });

  test('creates, reads, updates, deletes and persists receipts', () async {
    final date = DateTime(2026, 10, 24);
    final id = await repository.save(
      Receipt(
        merchant: 'Cafe A',
        totalAmount: 100000,
        receiptDate: date,
        category: 'Food',
        productName: 'Coffee',
        rawOcrText: 'TOTAL: 100.000',
      ),
    );

    expect((await repository.getById(id))?.merchant, 'Cafe A');
    expect((await repository.getAll()).single.totalAmount, 100000);
    expect((await repository.getAll()).single.productName, 'Coffee');

    await repository.update(
      Receipt(
        id: id,
        merchant: 'Cafe B',
        totalAmount: 125000,
        receiptDate: date,
        category: 'Others',
        productName: 'Latte',
        rawOcrText: 'GRAND TOTAL: 125.000',
      ),
    );
    final updated = await repository.getById(id);
    expect(updated?.merchant, 'Cafe B');
    expect(updated?.totalAmount, 125000);
    expect(updated?.productName, 'Latte');

    await database.close();
    database = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    repository = ReceiptRepository(database);
    expect(
      (await repository.getAll()).single.rawOcrText,
      'GRAND TOTAL: 125.000',
    );

    await repository.delete(id);
    expect(await repository.getAll(), isEmpty);
    expect(await repository.getById(id), isNull);
  });

  test('adds the product field when migrating a version 2 database', () async {
    await database.close();
    final legacyDatabase = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE receipts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              merchant TEXT NOT NULL,
              total_amount INTEGER NOT NULL,
              receipt_date TEXT NOT NULL,
              category TEXT NOT NULL,
              image_path TEXT,
              raw_ocr_text TEXT NOT NULL DEFAULT '',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.insert('receipts', {
            'merchant': 'Legacy shop',
            'total_amount': 20000,
            'receipt_date': '2026-10-24',
            'category': 'Food',
            'raw_ocr_text': '',
            'created_at': '2026-10-24T08:00:00.000',
            'updated_at': '2026-10-24T08:00:00.000',
          });
        },
      ),
    );
    await legacyDatabase.close();

    database = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    repository = ReceiptRepository(database);
    final migrated = await repository.getById(1);

    expect(migrated?.merchant, 'Legacy shop');
    expect(migrated?.productName, isEmpty);
  });

  test(
    'copies images to persistent storage and retains shared files',
    () async {
      final source = File(
        '${directory.path}${Platform.pathSeparator}picked_receipt.png',
      );
      await source.writeAsBytes([1, 2, 3]);
      final storedDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}app_documents',
      );
      final imageRepository = ReceiptRepository(
        database,
        documentsDirectoryProvider: () async => storedDirectory,
      );
      final firstId = await imageRepository.save(
        Receipt(
          merchant: 'Cafe A',
          totalAmount: 100000,
          receiptDate: DateTime(2026, 10, 24),
          category: 'Food',
          imagePath: source.path,
        ),
      );
      final first = (await imageRepository.getById(firstId))!;
      expect(first.imagePath, isNot(source.path));
      expect(await File(first.imagePath!).exists(), isTrue);
      expect(await source.exists(), isTrue);

      final secondId = await imageRepository.save(
        Receipt(
          merchant: 'Cafe B',
          totalAmount: 200000,
          receiptDate: DateTime(2026, 10, 24),
          category: 'Food',
        ),
      );
      final db = await database.database;
      await db.update(
        'receipts',
        {'image_path': first.imagePath},
        where: 'id = ?',
        whereArgs: [secondId],
      );

      await imageRepository.delete(firstId);
      expect(await File(first.imagePath!).exists(), isTrue);
      await imageRepository.delete(secondId);
      expect(await File(first.imagePath!).exists(), isFalse);
    },
  );
}
