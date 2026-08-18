import 'package:intl/intl.dart';

class DateFormatHelper {
  static final DateFormat _monthFormat = DateFormat('yyyy年M月');
  static final DateFormat _yearFormat = DateFormat('yyyy年');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _fullDateTimeFormat = DateFormat('yyyy年M月d日 HH:mm');

  static const List<String> _weekdays = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  static String formatMonth(DateTime date) {
    return _monthFormat.format(date);
  }

  static String formatYear(DateTime date) {
    return _yearFormat.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  static String formatFullDateTime(DateTime date) {
    return _fullDateTimeFormat.format(date);
  }

  static String formatDayHeader(DateTime date, {bool? showYear}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDay = DateTime(date.year, date.month, date.day);

    final bool includeYear = showYear ?? (date.year != now.year);
    final String dayStr = includeYear
        ? '${date.year}年${date.month}月${date.day}日'
        : '${date.month}月${date.day}日';
    final String weekdayStr = _getWeekdayString(date.weekday);

    if (targetDay == today) {
      return '$dayStr 今天 · $weekdayStr';
    } else if (targetDay == yesterday) {
      return '$dayStr 昨天 · $weekdayStr';
    } else {
      return '$dayStr · $weekdayStr';
    }
  }

  /// Formats date-time into a concise relative text for chips and badges:
  /// e.g. "今天 14:30", "昨天 09:15", "8月16日 12:00", "2025年3月1日 10:00"
  static String formatRelativeDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(dt.year, dt.month, dt.day);
    final timeStr = _timeFormat.format(dt);

    if (target == today) {
      return '今天 $timeStr';
    } else if (target == yesterday) {
      return '昨天 $timeStr';
    } else if (dt.year == now.year) {
      return '${dt.month}月${dt.day}日 $timeStr';
    } else {
      return '${dt.year}年${dt.month}月${dt.day}日 $timeStr';
    }
  }

  static String _getWeekdayString(int weekday) {
    if (weekday >= 1 && weekday <= 7) {
      return _weekdays[weekday - 1];
    }
    return '';
  }
}
