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

  group('SettingsProvider auto check update', () {
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

    test('defaults to off and never auto-checks before enabling', () {
      final provider = SettingsProvider();
      expect(provider.autoCheckUpdate, false);
      expect(provider.shouldAutoCheckToday, false);
    });

    test('setAutoCheckUpdate persists and notifies', () async {
      final provider = SettingsProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setAutoCheckUpdate(true);
      expect(provider.autoCheckUpdate, true);
      expect(notifications, 1);
      expect(await DatabaseHelper.instance.getSetting('autoCheckUpdate'), 'true');

      await provider.setAutoCheckUpdate(false);
      expect(provider.autoCheckUpdate, false);
      expect(notifications, 2);
      expect(await DatabaseHelper.instance.getSetting('autoCheckUpdate'), 'false');
    });

    test('setAutoCheckUpdate with the same value is a no-op', () async {
      final provider = SettingsProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setAutoCheckUpdate(false);
      expect(notifications, 0);
      expect(await DatabaseHelper.instance.getSetting('autoCheckUpdate'), isNull);
    });

    test('loadAutoCheckUpdate restores persisted switch', () async {
      await DatabaseHelper.instance.setSetting('autoCheckUpdate', 'true');

      final provider = SettingsProvider();
      await provider.loadAutoCheckUpdate();
      expect(provider.autoCheckUpdate, true);
    });

    test('loadAutoCheckUpdate treats unknown values as off', () async {
      await DatabaseHelper.instance.setSetting('autoCheckUpdate', 'yes');

      final provider = SettingsProvider();
      await provider.loadAutoCheckUpdate();
      expect(provider.autoCheckUpdate, false);
    });

    test('shouldAutoCheckToday is true after enabling until checked today', () async {
      final provider = SettingsProvider();
      await provider.setAutoCheckUpdate(true);
      expect(provider.shouldAutoCheckToday, true);

      await provider.markUpdateChecked();
      expect(provider.shouldAutoCheckToday, false);
    });

    test('markUpdateChecked persists the date and survives a reload', () async {
      final provider = SettingsProvider();
      await provider.setAutoCheckUpdate(true);
      await provider.markUpdateChecked();

      final reloaded = SettingsProvider();
      await reloaded.loadAutoCheckUpdate();
      expect(reloaded.autoCheckUpdate, true);
      expect(reloaded.shouldAutoCheckToday, false);
    });
  });
}
