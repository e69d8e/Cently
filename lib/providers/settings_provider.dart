import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database_helper.dart';

/// 应用偏好设置状态：承载主题模式（跟随系统 / 浅色 / 深色）与
/// 自动检查更新开关，持久化于本地 SQLite 的 app_settings 键值表，
/// 重启后自动恢复。
class SettingsProvider extends ChangeNotifier {
  static const String _keyThemeMode = 'themeMode';
  static const String _keyAutoCheckUpdate = 'autoCheckUpdate';
  static const String _keyLastUpdateCheckDate = 'lastUpdateCheckDate';

  ThemeMode _themeMode = ThemeMode.system;
  bool _autoCheckUpdate = false;
  String? _lastUpdateCheckDate;

  ThemeMode get themeMode => _themeMode;

  /// 是否开启启动时自动检查更新；默认关闭，需用户显式开启。
  bool get autoCheckUpdate => _autoCheckUpdate;

  /// 今天是否应执行自动检查（已开启且今天尚未检查过）。
  bool get shouldAutoCheckToday =>
      _autoCheckUpdate && _lastUpdateCheckDate != _todayKey();

  /// 应用启动时恢复持久化的主题模式；读取失败时保持默认跟随系统
  Future<void> loadThemeMode() async {
    try {
      final raw = await DatabaseHelper.instance.getSetting(_keyThemeMode);
      final mode = _parseThemeMode(raw);
      if (mode != null && mode != _themeMode) {
        _themeMode = mode;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }

  /// 应用启动时恢复自动检查更新开关与上次检查日期；失败时保持默认关闭
  Future<void> loadAutoCheckUpdate() async {
    try {
      final db = DatabaseHelper.instance;
      final rawSwitch = await db.getSetting(_keyAutoCheckUpdate);
      final rawDate = await db.getSetting(_keyLastUpdateCheckDate);
      bool changed = false;
      final enabled = rawSwitch == 'true';
      if (enabled != _autoCheckUpdate) {
        _autoCheckUpdate = enabled;
        changed = true;
      }
      final date = (rawDate == null || rawDate.isEmpty) ? null : rawDate;
      if (date != _lastUpdateCheckDate) {
        _lastUpdateCheckDate = date;
        changed = true;
      }
      if (changed) notifyListeners();
    } catch (e) {
      debugPrint('Error loading auto check update setting: $e');
    }
  }

  /// 切换自动检查更新开关并持久化；持久化失败不影响当前会话内的即时生效
  Future<void> setAutoCheckUpdate(bool value) async {
    if (value == _autoCheckUpdate) return;
    _autoCheckUpdate = value;
    notifyListeners();
    try {
      await DatabaseHelper.instance.setSetting(
        _keyAutoCheckUpdate,
        value ? 'true' : 'false',
      );
    } catch (e) {
      debugPrint('Error persisting auto check update: $e');
    }
  }

  /// 记录"今天已成功检查过更新"，用于每日一次的节流。
  Future<void> markUpdateChecked() async {
    final today = _todayKey();
    if (_lastUpdateCheckDate == today) return;
    _lastUpdateCheckDate = today;
    try {
      await DatabaseHelper.instance.setSetting(_keyLastUpdateCheckDate, today);
    } catch (e) {
      debugPrint('Error persisting last update check date: $e');
    }
  }

  /// 切换主题模式并持久化；持久化失败不影响当前会话内的即时生效
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      await DatabaseHelper.instance.setSetting(_keyThemeMode, mode.name);
    } catch (e) {
      debugPrint('Error persisting theme mode: $e');
    }
  }

  /// 当天日期键，格式 yyyy-MM-dd，用于按日历日节流。
  static String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  ThemeMode? _parseThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }
}
