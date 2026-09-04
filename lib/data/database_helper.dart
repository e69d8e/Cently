import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/category.dart';
import '../models/preset_item.dart';
import '../models/transaction_record.dart';
import 'default_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Future<Database>? _initFuture;

  DatabaseHelper._init();

  @visibleForTesting
  static void setDatabaseForTesting(Database? db) {
    _database = db;
    _initFuture = db != null ? Future.value(db) : null;
  }

  @visibleForTesting
  Future<void> createDBForTesting(Database db) async {
    await _createDB(db, 4);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _initFuture ??= _initDB('cently_bookkeeping.db');
      _database = await _initFuture;
      return _database!;
    } catch (e) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      path = filePath;
    } else {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      final dbFolder = await getApplicationDocumentsDirectory();
      path = join(dbFolder.path, filePath);
    }

    return await openDatabase(
      path,
      version: 5,
      onConfigure: _configureDB,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    // Enable SQLite foreign key constraint support and high-performance caching pragmas
    await db.execute('PRAGMA foreign_keys = ON;');
    await db.execute('PRAGMA synchronous = NORMAL;');
    await db.execute('PRAGMA temp_store = MEMORY;');
    await db.execute('PRAGMA cache_size = -2000;');
  }

  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN deletedAt INTEGER;');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_deletedAt ON transactions(deletedAt);');
    }
    if (oldVersion < 3) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_deleted_timestamp ON transactions(deletedAt, timestamp);');
    }
    if (oldVersion < 4) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_cat_deleted ON transactions(categoryId, deletedAt);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_type_deleted ON transactions(type, deletedAt);');
    }
    if (oldVersion < 5) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_active_order ON transactions(deletedAt, timestamp DESC, createdAt DESC);');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        iconKey TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        sortOrder INTEGER NOT NULL,
        isDefault INTEGER NOT NULL
      )
    ''');

    // 2. Preset items table
    await db.execute('''
      CREATE TABLE preset_items (
        id TEXT PRIMARY KEY,
        categoryId TEXT NOT NULL,
        name TEXT NOT NULL,
        sortOrder INTEGER NOT NULL,
        isDefault INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // 3. Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        categoryName TEXT NOT NULL,
        name TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        remark TEXT,
        createdAt INTEGER NOT NULL,
        deletedAt INTEGER
      )
    ''');

    // 4. Create indices for high-frequency queries
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions(timestamp);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_categoryId ON transactions(categoryId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_deletedAt ON transactions(deletedAt);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_deleted_timestamp ON transactions(deletedAt, timestamp);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_cat_deleted ON transactions(categoryId, deletedAt);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_type_deleted ON transactions(type, deletedAt);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_active_order ON transactions(deletedAt, timestamp DESC, createdAt DESC);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_preset_items_categoryId ON preset_items(categoryId);');

    // Seed default data
    await _seedDefaultData(db);
  }

  Future<void> _seedDefaultData(Database db) async {
    final batch = db.batch();
    for (final cat in DefaultData.getDefaultCategories()) {
      batch.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final item in DefaultData.getDefaultPresetItems()) {
      batch.insert('preset_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // =================== CATEGORIES ===================

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'sortOrder ASC');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(String categoryId) async {
    final db = await database;
    // Delete associated presets
    await db.delete('preset_items', where: 'categoryId = ?', whereArgs: [categoryId]);
    return await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
  }

  // =================== PRESET ITEMS ===================

  Future<List<PresetItem>> getAllPresetItems() async {
    final db = await database;
    final result = await db.query('preset_items', orderBy: 'sortOrder ASC');
    return result.map((map) => PresetItem.fromMap(map)).toList();
  }

  Future<List<PresetItem>> getPresetItemsByCategory(String categoryId) async {
    final db = await database;
    final result = await db.query(
      'preset_items',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'sortOrder ASC',
    );
    return result.map((map) => PresetItem.fromMap(map)).toList();
  }

  Future<int> insertPresetItem(PresetItem item) async {
    final db = await database;
    return await db.insert(
      'preset_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertPresetItemsBatch(List<PresetItem> items) async {
    if (items.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'preset_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> updatePresetItem(PresetItem item) async {
    final db = await database;
    return await db.update(
      'preset_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deletePresetItem(String id) async {
    final db = await database;
    return await db.delete('preset_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePresetItemsOrder(List<PresetItem> items) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < items.length; i++) {
      final updated = items[i].copyWith(sortOrder: i);
      batch.update(
        'preset_items',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [updated.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateCategoriesOrder(List<Category> categories) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < categories.length; i++) {
      final updated = categories[i].copyWith(sortOrder: i);
      batch.update(
        'categories',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [updated.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> resetCategoriesAndPresetsToDefault() async {
    final db = await database;
    await db.delete('preset_items');
    await db.delete('categories');
    await _seedDefaultData(db);
  }

  // =================== TRANSACTIONS ===================

  Future<int> insertTransaction(TransactionRecord record) async {
    final db = await database;
    return await db.insert(
      'transactions',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTransaction(TransactionRecord record) async {
    final db = await database;
    return await db.update(
      'transactions',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// Soft deletes a transaction and records deletion timestamp for 30-day retention
  Future<int> softDeleteTransaction(String id, {DateTime? deletedAt}) async {
    final db = await database;
    final deleteTime = (deletedAt ?? DateTime.now()).millisecondsSinceEpoch;
    return await db.update(
      'transactions',
      {'deletedAt': deleteTime},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Alias for softDeleteTransaction to ensure safety
  Future<int> deleteTransaction(String id) async {
    return await softDeleteTransaction(id);
  }

  /// Restores a soft-deleted transaction from recycle bin
  Future<int> restoreTransaction(String id) async {
    final db = await database;
    return await db.update(
      'transactions',
      {'deletedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Restores all deleted transactions from recycle bin
  Future<int> restoreAllTransactions() async {
    final db = await database;
    return await db.update(
      'transactions',
      {'deletedAt': null},
      where: 'deletedAt IS NOT NULL',
    );
  }

  /// Permanently deletes a transaction from SQLite
  Future<int> permanentlyDeleteTransaction(String id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Clears all transactions in recycle bin permanently
  Future<int> clearRecycleBin() async {
    final db = await database;
    return await db.delete('transactions', where: 'deletedAt IS NOT NULL');
  }

  /// Automatically cleans up transactions deleted more than [retentionDays] (default: 30) days ago
  Future<int> cleanupExpiredDeletedTransactions({int retentionDays = 30}) async {
    final db = await database;
    final threshold = DateTime.now().subtract(Duration(days: retentionDays)).millisecondsSinceEpoch;
    return await db.delete(
      'transactions',
      where: 'deletedAt IS NOT NULL AND deletedAt < ?',
      whereArgs: [threshold],
    );
  }

  /// Retrieves all deleted transactions sorted by deletion time (latest first)
  Future<List<TransactionRecord>> getDeletedTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'deletedAt IS NOT NULL',
      orderBy: 'deletedAt DESC, timestamp DESC',
    );
    return result.map((map) => TransactionRecord.fromMap(map)).toList();
  }

  /// Retrieves the total count of deleted transactions currently in recycle bin
  Future<int> getDeletedTransactionsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE deletedAt IS NOT NULL',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<TransactionRecord>> getTransactionsByMonth(DateTime month) async {
    final db = await database;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final startOfNextMonth = DateTime(month.year, month.month + 1, 1);

    final result = await db.query(
      'transactions',
      where: 'deletedAt IS NULL AND timestamp >= ? AND timestamp < ?',
      whereArgs: [
        startOfMonth.millisecondsSinceEpoch,
        startOfNextMonth.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC, createdAt DESC',
    );
    return result.map((map) => TransactionRecord.fromMap(map)).toList();
  }

  Future<List<TransactionRecord>> getAllTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'deletedAt IS NULL',
      orderBy: 'timestamp DESC, createdAt DESC',
    );
    return result.map((map) => TransactionRecord.fromMap(map)).toList();
  }

  Future<int> countTransactionsByCategory(String categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE deletedAt IS NULL AND categoryId = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<ImportSummary> importBackupData(Map<String, dynamic> data, {bool overwrite = false}) async {
    final db = await database;
    try {
      final batch = db.batch();

      if (overwrite) {
        batch.delete('transactions');
        batch.delete('preset_items');
        batch.delete('categories');
      }

      int catCount = 0;
      if (data.containsKey('categories') && data['categories'] is List) {
        final catList = data['categories'] as List;
        for (final item in catList) {
          if (item is Map) {
            final cat = Category.fromMap(Map<String, dynamic>.from(item));
            batch.insert(
              'categories',
              cat.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            catCount++;
          }
        }
      }

      int presetCount = 0;
      if (data.containsKey('presetItems') && data['presetItems'] is List) {
        final presetList = data['presetItems'] as List;
        for (final item in presetList) {
          if (item is Map) {
            final preset = PresetItem.fromMap(Map<String, dynamic>.from(item));
            batch.insert(
              'preset_items',
              preset.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            presetCount++;
          }
        }
      }

      int txCount = 0;
      if (data.containsKey('transactions') && data['transactions'] is List) {
        final txList = data['transactions'] as List;
        for (final item in txList) {
          if (item is Map) {
            final tx = TransactionRecord.fromMap(Map<String, dynamic>.from(item));
            batch.insert(
              'transactions',
              tx.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            txCount++;
          }
        }
      }

      await batch.commit(noResult: true);

      return ImportSummary(
        categoriesCount: catCount,
        presetsCount: presetCount,
        transactionsCount: txCount,
        isSuccess: true,
      );
    } catch (e) {
      return ImportSummary(
        categoriesCount: 0,
        presetsCount: 0,
        transactionsCount: 0,
        isSuccess: false,
        message: e.toString(),
      );
    }
  }

  Future<void> clearAllTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

class ImportSummary {
  final int categoriesCount;
  final int presetsCount;
  final int transactionsCount;
  final bool isSuccess;
  final String? message;

  ImportSummary({
    required this.categoriesCount,
    required this.presetsCount,
    required this.transactionsCount,
    required this.isSuccess,
    this.message,
  });
}

