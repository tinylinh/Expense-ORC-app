import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/receipt.dart';

class ReceiptRepository {
  ReceiptRepository(this._database);

  final AppDatabase _database;

  Future<List<Receipt>> getAll() async {
    final db = await _database.database;
    final rows = await db.query(
      'receipts',
      orderBy: 'receipt_date DESC, id DESC',
    );
    return rows.map(Receipt.fromMap).toList(growable: false);
  }

  Future<int> save(Receipt receipt) async {
    final db = await _database.database;
    final now = DateTime.now();
    final stableImagePath = receipt.imagePath == null
        ? null
        : await _copyImageToAppStorage(receipt.imagePath!);
    final savedReceipt = receipt.copyWith(
      imagePath: stableImagePath,
      createdAt: receipt.createdAt ?? now,
      updatedAt: now,
    );
    final id = await db.insert(
      'receipts',
      savedReceipt.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return id;
  }

  Future<void> update(Receipt receipt) async {
    final id = receipt.id;
    if (id == null) throw ArgumentError('A saved receipt must have an id.');
    final db = await _database.database;
    final previousRows = await db.query(
      'receipts',
      columns: ['image_path'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (previousRows.isEmpty) {
      throw StateError('Receipt $id no longer exists.');
    }
    final oldImagePath = previousRows.first['image_path'] as String?;
    final newImagePath = receipt.imagePath == oldImagePath
        ? oldImagePath
        : receipt.imagePath == null
            ? null
            : await _copyImageToAppStorage(receipt.imagePath!);
    await db.update(
      'receipts',
      receipt
          .copyWith(imagePath: newImagePath, updatedAt: DateTime.now())
          .toMap()
        ..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
    if (oldImagePath != null && oldImagePath != newImagePath) {
      await _deleteStoredImage(oldImagePath);
    }
  }

  Future<void> delete(int id) async {
    final db = await _database.database;
    final rows = await db.query(
      'receipts',
      columns: ['image_path'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Receipt $id no longer exists.');
    await db.delete('receipts', where: 'id = ?', whereArgs: [id]);
    final imagePath = rows.first['image_path'] as String?;
    if (imagePath != null) await _deleteStoredImage(imagePath);
  }

  Future<String> _copyImageToAppStorage(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Receipt image was not found', sourcePath);
    }
    final directory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory(path.join(directory.path, 'receipts'));
    await imageDirectory.create(recursive: true);
    final extension = path.extension(sourcePath);
    final destination = path.join(
      imageDirectory.path,
      'receipt_${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    return (await source.copy(destination)).path;
  }

  Future<void> _deleteStoredImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) await file.delete();
  }
}
