import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cently/data/database_helper.dart';
import 'package:cently/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('App settings key-value store', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 6,
        onCreate: (db, version) async {
          await DatabaseHelper.instance.createDBForTesting(db);
        },
      );
      DatabaseHelper.setDatabaseForTesting(db);
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.setDatabaseForTesting(null);
    });

    test('setSetting writes and getSetting reads the value back', () async {
      await DatabaseHelper.instance.setSetting('themeMode', 'dark');
      expect(await DatabaseHelper.instance.getSetting('themeMode'), 'dark');
    });

    test('setSetting overwrites an existing key (conflict replace)', () async {
      await DatabaseHelper.instance.setSetting('themeMode', 'dark');
      await DatabaseHelper.instance.setSetting('themeMode', 'light');
      expect(await DatabaseHelper.instance.getSetting('themeMode'), 'light');
    });

    test('getSetting returns null for unknown keys', () async {
      expect(await DatabaseHelper.instance.getSetting('nonexistent'), isNull);
    });

    test('settings table coexists with transactions tables', () async {
      await DatabaseHelper.instance.setSetting('themeMode', 'system');
      final tables = await db.query(
        'sqlite_master',
        where: "type = 'table' AND name IN ('app_settings', 'transactions', 'categories')",
      );
      expect(tables.length, 3);
    });
  });

  group('SettingsProvider theme mode', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 6,
        onCreate: (db, version) async {
          await DatabaseHelper.instance.createDBForTesting(db);
        },
      );
      DatabaseHelper.setDatabaseForTesting(db);
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.setDatabaseForTesting(null);
    });

    test('defaults to system mode before any load', () {
      expect(SettingsProvider().themeMode, ThemeMode.system);
    });

    test('setThemeMode updates state, notifies and persists', () async {
      final provider = SettingsProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
      expect(notifications, 1);
      expect(await DatabaseHelper.instance.getSetting('themeMode'), 'dark');

      await provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);
      expect(notifications, 2);
      expect(await DatabaseHelper.instance.getSetting('themeMode'), 'light');
    });

    test('setThemeMode with the same value is a no-op', () async {
      final provider = SettingsProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setThemeMode(ThemeMode.system);
      expect(notifications, 0);
      expect(await DatabaseHelper.instance.getSetting('themeMode'), isNull);
    });

    test('loadThemeMode restores persisted mode on a fresh instance', () async {
      await DatabaseHelper.instance.setSetting('themeMode', 'dark');

      final provider = SettingsProvider();
      await provider.loadThemeMode();
      expect(provider.themeMode, ThemeMode.dark);
    });

    test('loadThemeMode falls back to system on invalid persisted value', () async {
      await DatabaseHelper.instance.setSetting('themeMode', 'sepia');

      final provider = SettingsProvider();
      await provider.loadThemeMode();
      expect(provider.themeMode, ThemeMode.system);
    });
  });
}
