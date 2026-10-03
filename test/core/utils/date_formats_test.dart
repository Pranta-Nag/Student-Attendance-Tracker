import 'package:flutter_test/flutter_test.dart';
import 'package:studentattendancetracker/core/utils/date_formats.dart';

void main() {
  group('dateKey', () {
    test('pads the month and the day', () {
      expect(dateKey(DateTime(2026, 3, 2)), '2026-03-02');
      expect(dateKey(DateTime(2026, 11, 30)), '2026-11-30');
    });

    test('ignores the time component', () {
      expect(dateKey(DateTime(2026, 3, 2, 23, 59)), '2026-03-02');
    });

    test('round trips with dateFromKey', () {
      final date = DateTime(2026, 3, 2, 15, 30);

      expect(dateFromKey(dateKey(date)), DateTime(2026, 3, 2));
    });
  });

  group('formatting', () {
    test('formats the long date with the weekday', () {
      expect(formatFullDate(DateTime(2026, 10, 3)), 'Sat, 3 Oct 2026');
    });

    test('formats the short date and the month', () {
      expect(formatDayMonth(DateTime(2026, 1, 5)), '5 Jan');
      expect(formatMonthYear(DateTime(2026, 1, 5)), 'January 2026');
    });

    test('labels today, yesterday and tomorrow', () {
      final today = DateTime(2026, 10, 3);

      expect(formatRelativeDay(today, today), 'Today');
      expect(
        formatRelativeDay(today.subtract(const Duration(days: 1)), today),
        'Yesterday',
      );
      expect(
        formatRelativeDay(today.add(const Duration(days: 1)), today),
        'Tomorrow',
      );
      expect(
        formatRelativeDay(today.subtract(const Duration(days: 5)), today),
        '28 Sep',
      );
    });

    test('groups thousands in counts', () {
      expect(formatCount(1234), '1,234');
      expect(formatCount(0), '0');
      expect(formatCount(-1500), '-1,500');
    });
  });

  test('startOfDay strips the time', () {
    expect(startOfDay(DateTime(2026, 3, 2, 23, 59)), DateTime(2026, 3, 2));
  });
}