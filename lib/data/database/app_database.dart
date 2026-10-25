import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._({DatabaseFactory? factory, String? databasePath})
    : _factory = factory ?? databaseFactory,
      _databasePath = databasePath;

  static final AppDatabase instance = AppDatabase._();
  static AppDatabase forTesting({
    required DatabaseFactory factory,
    required String databasePath,
  }) => AppDatabase._(factory: factory, databasePath: databasePath);

  final DatabaseFactory _factory;
  final String? _databasePath;
  Database? _database;
  Future<Database>? _opening;

  Future<Database> get database async {
    if (_database != null) return _database!;
    return _opening ??= _open().whenComplete(() => _opening = null);
  }

  Future<Database> _open() async {
    final databasePath =
        _databasePath ??
        path.join(
          (await getApplicationDocumentsDirectory()).path,
          'expense_orc.db',
        );
    final database = await _factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await _createReceiptTable(db);
          await _createCategoryIndex(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) await _createCategoryIndex(db);
          if (oldVersion < 3) {
            await db.execute(
              "ALTER TABLE receipts ADD COLUMN product_name TEXT NOT NULL DEFAULT ''",
            );
          }
        },
      ),
    );
    _database = database;
    return database;
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    if (database != null) await database.close();
  }

  Future<void> _createReceiptTable(DatabaseExecutor db) async {
    await db.execute('''
          CREATE TABLE receipts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT NOT NULL,
            total_amount INTEGER NOT NULL,
            receipt_date TEXT NOT NULL,
            category TEXT NOT NULL,
            product_name TEXT NOT NULL DEFAULT '',
            image_path TEXT,
            raw_ocr_text TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
    await db.execute(
      'CREATE INDEX receipts_date_idx ON receipts(receipt_date)',
    );
  }

  Future<void> _createCategoryIndex(DatabaseExecutor db) => db.execute(
    'CREATE INDEX receipts_category_date_idx '
    'ON receipts(category, receipt_date)',
  );
}
