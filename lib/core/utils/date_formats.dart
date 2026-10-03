/// Small, dependency free date helpers.
///
/// The project intentionally avoids `intl`, so the handful of formats the UI
/// needs are implemented here.
const List<String> _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _monthShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> weekdayShort = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Strips the time component, keeping only the calendar day.
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

/// Stable `yyyy-MM-dd` identifier used to index attendance records.
String dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}

/// Inverse of [dateKey].
DateTime dateFromKey(String key) => startOfDay(DateTime.parse(key));

/// `Fri, 3 Oct 2026`
String formatFullDate(DateTime date) =>
    '${weekdayShort[date.weekday - 1]}, ${date.day} ${_monthShort[date.month - 1]} ${date.year}';

/// `3 Oct`
String formatDayMonth(DateTime date) =>
    '${date.day} ${_monthShort[date.month - 1]}';

/// `October 2026`
String formatMonthYear(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.year}';

/// `Today` / `Yesterday` / `Tomorrow` / `3 Oct`.
String formatRelativeDay(DateTime date, DateTime today) {
  final diff = startOfDay(date).difference(startOfDay(today)).inDays;
  return switch (diff) {
    0 => 'Today',
    -1 => 'Yesterday',
    1 => 'Tomorrow',
    _ => formatDayMonth(date),
  };
}

/// `1,234`
String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}