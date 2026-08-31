class DateFormatHelper {
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
    return '${date.year}年${date.month}月';
  }

  static String formatYear(DateTime date) {
    return '${date.year}年';
  }

  static String formatTime(DateTime date) {
    final h = date.hour < 10 ? '0${date.hour}' : '${date.hour}';
    final m = date.minute < 10 ? '0${date.minute}' : '${date.minute}';
    return '$h:$m';
  }

  static String formatFullDateTime(DateTime date) {
    final timeStr = formatTime(date);
    return '${date.year}年${date.month}月${date.day}日 $timeStr';
  }

  static String formatDayHeader(DateTime date, {bool? showYear}) {
    final now = DateTime.now();
    final isSameYear = date.year == now.year;
    final isSameMonth = date.month == now.month;
    final isToday = isSameYear && isSameMonth && date.day == now.day;
    final isYesterday = !isToday &&
        DateTime(date.year, date.month, date.day) ==
            DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));

    final bool includeYear = showYear ?? (!isSameYear);
    final String dayStr = includeYear
        ? '${date.year}年${date.month}月${date.day}日'
        : '${date.month}月${date.day}日';
    final String weekdayStr = _getWeekdayString(date.weekday);

    if (isToday) {
      return '$dayStr 今天 · $weekdayStr';
    } else if (isYesterday) {
      return '$dayStr 昨天 · $weekdayStr';
    } else {
      return '$dayStr · $weekdayStr';
    }
  }

  /// Formats date-time into a concise relative text for chips and badges:
  /// e.g. "今天 14:30", "昨天 09:15", "8月16日 12:00", "2025年3月1日 10:00"
  static String formatRelativeDateTime(DateTime dt) {
    final now = DateTime.now();
    final isSameYear = dt.year == now.year;
    final isSameMonth = dt.month == now.month;
    final isToday = isSameYear && isSameMonth && dt.day == now.day;
    final isYesterday = !isToday &&
        DateTime(dt.year, dt.month, dt.day) ==
            DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final timeStr = formatTime(dt);

    if (isToday) {
      return '今天 $timeStr';
    } else if (isYesterday) {
      return '昨天 $timeStr';
    } else if (isSameYear) {
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
