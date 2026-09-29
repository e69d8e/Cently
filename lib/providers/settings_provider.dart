import 'package:flutter/material.dart';

import '../data/database_helper.dart';

/// 应用偏好设置状态：当前仅承载主题模式（跟随系统 / 浅色 / 深色），
/// 持久化于本地 SQLite 的 app_settings 键值表，重启后自动恢复。
class SettingsProvider extends ChangeNotifier {
  static const String _keyThemeMode = 'themeMode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

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
