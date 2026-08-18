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

  Future<Database> get database async {
    if (_database != null) return _database!;
    _initFuture ??= _initDB('cently_bookkeeping.db');
    _database = await _initFuture;
    return _database!;
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
      version: 1,
      onConfigure: _configureDB,
      onCreate: _createDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    // Enable SQLite foreign key constraint support
    await db.execute('PRAGMA foreign_keys = ON;');
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
        createdAt INTEGER NOT NULL
      )
    ''');

    // 4. Create indices for high-frequency queries
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions(timestamp);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_categoryId ON transactions(categoryId);');
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

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionRecord>> getTransactionsByMonth(DateTime month) async {
    final db = await database;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);

    final result = await db.query(
      'transactions',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        startOfMonth.millisecondsSinceEpoch,
        endOfMonth.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC, createdAt DESC',
    );
    return result.map((map) => TransactionRecord.fromMap(map)).toList();
  }

  Future<List<TransactionRecord>> getAllTransactions() async {
    final db = await database;
    final result = await db.query('transactions', orderBy: 'timestamp DESC, createdAt DESC');
    return result.map((map) => TransactionRecord.fromMap(map)).toList();
  }

  Future<int> countTransactionsByCategory(String categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE categoryId = ?',
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
          if (item is Map<String, dynamic>) {
            final cat = Category.fromMap(item);
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
          if (item is Map<String, dynamic>) {
            final preset = PresetItem.fromMap(item);
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
          if (item is Map<String, dynamic>) {
            final tx = TransactionRecord.fromMap(item);
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

