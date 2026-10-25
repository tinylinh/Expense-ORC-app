import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/receipt.dart';

class ReceiptRepository {
  ReceiptRepository(
    this._database, {
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final AppDatabase _database;
  final Future<Directory> Function() _documentsDirectoryProvider;

  Future<List<Receipt>> getAll() async {
    final db = await _database.database;
    final rows = await db.query(
      'receipts',
      orderBy: 'receipt_date DESC, id DESC',
    );
    return rows.map(Receipt.fromMap).toList(growable: false);
  }

  Future<Receipt?> getById(int id) async {
    final db = await _database.database;
    final rows = await db.query(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Receipt.fromMap(rows.first);
  }

  Future<int> save(Receipt receipt) async {
    final db = await _database.database;
    final now = DateTime.now();
    final stableImagePath = receipt.imagePath == null
        ? null
        : await _copyImageToAppStorage(receipt.imagePath!);
    try {
      final savedReceipt = receipt.copyWith(
        imagePath: stableImagePath,
        createdAt: receipt.createdAt ?? now,
        updatedAt: now,
      );
      return await db.insert(
        'receipts',
        savedReceipt.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (_) {
      if (stableImagePath != null) {
        await _deleteStoredImage(stableImagePath);
      }
      rethrow;
    }
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
    if (previousRows.isEmpty) throw StateError('Receipt $id no longer exists.');
    final oldImagePath = previousRows.first['image_path'] as String?;
    final newImagePath = receipt.imagePath == oldImagePath
        ? oldImagePath
        : receipt.imagePath == null
        ? null
        : await _copyImageToAppStorage(receipt.imagePath!);
    try {
      final updatedRows = await db.update(
        'receipts',
        receipt
            .copyWith(imagePath: newImagePath, updatedAt: DateTime.now())
            .toMap()
          ..remove('id'),
        where: 'id = ?',
        whereArgs: [id],
      );
      if (updatedRows != 1) throw StateError('Receipt $id no longer exists.');
    } catch (_) {
      if (newImagePath != null && newImagePath != oldImagePath) {
        await _deleteStoredImage(newImagePath);
      }
      rethrow;
    }
    if (oldImagePath != null && oldImagePath != newImagePath) {
      await _deleteImageIfUnreferenced(db, oldImagePath);
    }
  }

  Future<void> delete(int id) async {
    final db = await _database.database;
    final imagePath = await db.transaction((transaction) async {
      final rows = await transaction.query(
        'receipts',
        columns: ['image_path'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Receipt $id no longer exists.');
      await transaction.delete('receipts', where: 'id = ?', whereArgs: [id]);
      return rows.first['image_path'] as String?;
    });
    if (imagePath != null) await _deleteImageIfUnreferenced(db, imagePath);
  }

  Future<void> _deleteImageIfUnreferenced(
    DatabaseExecutor db,
    String imagePath,
  ) async {
    final references = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM receipts WHERE image_path = ?',
      [imagePath],
    );
    if ((references.first['count'] as int) == 0) {
      await _deleteStoredImage(imagePath);
    }
  }

  Future<String> _copyImageToAppStorage(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Receipt image was not found', sourcePath);
    }
    final directory = await _documentsDirectoryProvider();
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
