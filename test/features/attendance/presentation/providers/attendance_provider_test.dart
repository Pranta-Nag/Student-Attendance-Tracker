import 'package:flutter_test/flutter_test.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/attendance_status.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/roster_filter.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/student.dart';
import 'package:studentattendancetracker/features/attendance/presentation/providers/attendance_provider.dart';

void main() {
  late AttendanceProvider provider;

  setUp(() => provider = AttendanceProvider());

  group('addStudent', () {
    test('adds a new student as absent and notifies listeners', () {
      var notifications = 0;
      provider.addListener(() => notifications++);

      final added = provider.addStudent('Ada Lovelace');

      expect(added, isTrue);
      expect(provider.students, hasLength(1));
      expect(provider.students.single.name, 'Ada Lovelace');
      expect(provider.students.single.status, AttendanceStatus.absent);
      expect(notifications, 1);
    });

    test('trims surrounding whitespace', () {
      provider.addStudent('  Grace Hopper  ');

      expect(provider.students.single.name, 'Grace Hopper');
    });

    test('rejects a blank name without notifying listeners', () {
      provider.addStudent('Ada');
      var notifications = 0;
      provider.addListener(() => notifications++);

      expect(provider.addStudent('   '), isFalse);
      expect(provider.students, hasLength(1));
      expect(notifications, 0);
    });

    test('generates unique ids', () {
      provider
        ..addStudent('Ada')
        ..addStudent('Grace');

      expect(provider.students[0].id, isNot(provider.students[1].id));
    });

    test('assigns the next free roll number of the section', () {
      provider
        ..addStudent('Ada', className: 'Grade 8 - A')
        ..addStudent('Grace', className: 'Grade 8 - A')
        ..addStudent('Chen', className: 'Grade 8 - B');

      expect(provider.students[0].rollNumber, 1);
      expect(provider.students[1].rollNumber, 2);
      expect(provider.students[2].rollNumber, 1);
    });

    test('falls back to the general class for a blank name', () {
      provider.addStudent('Ada', className: '   ');

      expect(provider.students.single.className, kDefaultClassName);
    });

    test('addStudents skips blank lines and counts the additions', () {
      final added = provider.addStudents(['Ada', ' ', 'Grace', '']);

      expect(added, 2);
      expect(provider.students.map((student) => student.name), ['Ada', 'Grace']);
    });
  });

  group('attendance', () {
    late String ada;
    late String grace;

    setUp(() {
      provider
        ..addStudent('Ada')
        ..addStudent('Grace');
      ada = provider.students[0].id;
      grace = provider.students[1].id;
    });

    test('toggle flips a student between present and absent', () {
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.toggleAttendance(ada);
      expect(provider.studentById(ada)!.isPresent, isTrue);

      provider.toggleAttendance(ada);
      expect(provider.studentById(ada)!.isPresent, isFalse);
      expect(notifications, 2);
    });

    test('a late student is toggled back to absent', () {
      provider.setStatus(ada, AttendanceStatus.late);

      provider.toggleAttendance(ada);
      expect(provider.studentById(ada)!.status, AttendanceStatus.absent);
    });

    test('setAttendance mirrors the checkbox value', () {
      provider.setAttendance(ada, true);
      expect(provider.studentById(ada)!.status, AttendanceStatus.present);

      provider.setAttendance(ada, false);
      expect(provider.studentById(ada)!.status, AttendanceStatus.absent);
    });

    test('setting the same status again does not notify', () {
      var notifications = 0;
      provider
        ..setStatus(ada, AttendanceStatus.excused)
        ..addListener(() => notifications++);
      provider.setStatus(ada, AttendanceStatus.excused);

      expect(notifications, 0);
    });

    test('unknown id is a no-op', () {
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider
        ..toggleAttendance('missing')
        ..setAttendance('missing', true)
        ..setStatus('missing', AttendanceStatus.late);

      expect(provider.stats.present, 0);
      expect(notifications, 0);
    });

    test('markAllPresent flags everyone and skips an empty roster', () {
      provider.markAllPresent();
      expect(provider.stats.present, 2);

      final empty = AttendanceProvider();
      var notifications = 0;
      empty.addListener(() => notifications++);
      empty.markAllPresent();
      expect(notifications, 0);
    });

    test('markAllPresentUnmarked only fills the gaps', () {
      provider.setStatus(ada, AttendanceStatus.late);

      expect(provider.markAllPresentUnmarked(), 1);
      expect(provider.studentById(ada)!.status, AttendanceStatus.late,
          reason: 'the deliberate mark must survive');
      expect(provider.studentById(grace)!.status, AttendanceStatus.present);

      expect(provider.markAllPresentUnmarked(), 0);
    });

    test('markAll replaces every mark of the day', () {
      provider
        ..setStatus(ada, AttendanceStatus.late)
        ..markAll(AttendanceStatus.absent);

      expect(provider.stats.absent, 2);
      expect(provider.stats.late, 0);
    });
  });

  group('lessons', () {
    final today = DateTime(2026, 3, 3);
    final yesterday = DateTime(2026, 3, 2);

    setUp(() {
      provider = AttendanceProvider(selectedDate: today)
        ..addStudent('Ada')
        ..addStudent('Grace');
    });

    test('marks are stored per day', () {
      final ada = provider.students.first.id;
      provider
        ..setStatus(ada, AttendanceStatus.present)
        ..selectDate(yesterday);

      expect(provider.stats.present, 0);

      provider.selectDate(today);

      expect(provider.stats.present, 1);
    });

    test('selectToday jumps back to the current day', () {
      provider.selectDate(DateTime(2020, 1, 1));

      provider.selectToday();

      expect(provider.isSelectedDayToday, isTrue);
    });

    test('going back and forth keeps the marks of each day', () {
      final ada = provider.students.first.id;
      provider
        ..selectDate(yesterday)
        ..setStatus(ada, AttendanceStatus.late)
        ..selectDate(today)
        ..setStatus(ada, AttendanceStatus.present);

      expect(provider.stats.present, 1);

      provider.selectDate(yesterday);
      expect(provider.studentById(ada)!.status, AttendanceStatus.late);
      expect(provider.isSelectedDayToday, isFalse);
    });

    test('shiftDate moves by whole days', () {
      provider.shiftDate(-1);
      expect(provider.selectedDate, yesterday);

      provider.shiftDate(1);
      expect(provider.selectedDate, today);
    });

    test('history is ordered newest first and skips empty days', () {
      final ada = provider.students.first.id;
      provider
        ..setStatus(ada, AttendanceStatus.present)
        ..selectDate(yesterday)
        ..setStatus(ada, AttendanceStatus.absent);

      expect(
        provider.history.map((day) => day.key),
        ['2026-03-03', '2026-03-02'],
      );
    });

    test('dayHasMarks and dayFor expose a single day', () {
      final ada = provider.students.first.id;

      expect(provider.dayHasMarks(today), isFalse);
      expect(provider.dayFor(today), isNull);

      provider.setStatus(ada, AttendanceStatus.present);

      expect(provider.dayHasMarks(today), isTrue);
      expect(provider.dayFor(today)!.markedCount, 1);
    });

    test('rollOverFromPreviousDay copies the closest earlier lesson', () {
      final ada = provider.students[0].id;
      final grace = provider.students[1].id;
      provider
        ..selectDate(DateTime(2026, 3, 1))
        ..setStatus(ada, AttendanceStatus.late)
        ..setStatus(grace, AttendanceStatus.absent)
        ..selectDate(today)
        ..setStatus(ada, AttendanceStatus.absent)
        ..setStatus(grace, AttendanceStatus.excused);

      expect(provider.rollOverFromPreviousDay(), 2);
      expect(provider.studentById(ada)!.status, AttendanceStatus.late);
      expect(provider.studentById(grace)!.status, AttendanceStatus.absent);
    });

    test('rollOverFromPreviousDay does nothing without earlier history', () {
      provider.markAllPresent();

      expect(provider.rollOverFromPreviousDay(), 0);
    });

    test('clearSelectedDay drops the marks but keeps the roster', () {
      provider.markAllPresent();

      provider.clearSelectedDay();

      expect(provider.markedCount, 0);
      expect(provider.stats.present, 0);
      expect(provider.students, hasLength(2));
    });

    test('markAllPresentUnmarked counts the unmarked students', () {
      expect(provider.markedCount, 0);
      expect(provider.unmarkedCount, 2);

      provider.setStatus(provider.students.first.id, AttendanceStatus.absent);

      expect(provider.markedCount, 1);
      expect(provider.unmarkedCount, 1);
    });

    test('recentDates ends today and is ordered', () {
      final dates = provider.recentDates(3, today: today);

      expect(dates, [
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 3),
      ]);
    });

    test('marksForStudent and daysForStudent walk the history', () {
      final ada = provider.students.first.id;
      provider
        ..setStatus(ada, AttendanceStatus.present)
        ..selectDate(yesterday)
        ..setStatus(ada, AttendanceStatus.absent);

      expect(provider.marksForStudent(ada), {
        '2026-03-02': AttendanceStatus.absent,
        '2026-03-03': AttendanceStatus.present,
      });
      expect(provider.daysForStudent(ada).map((day) => day.key), [
        '2026-03-03',
        '2026-03-02',
      ]);
      expect(provider.attendanceRateFor(ada), 0.5);
    });

    test('attendanceRateFor is zero without marks', () {
      expect(provider.attendanceRateFor(provider.students.first.id), 0);
    });
  });

  group('filters', () {
    setUp(() {
      provider
        ..addStudent('Ada Lovelace', className: 'Grade 8 - A')
        ..addStudent('Grace Hopper', className: 'Grade 8 - B');
    });

    test('a query narrows the visible roster', () {
      provider.setQuery('grace');

      expect(provider.visibleStudents.single.name, 'Grace Hopper');
      expect(provider.students, hasLength(2),
          reason: 'the roster itself is untouched');
    });

    test('the status filter only keeps the matching marks', () {
      provider
        ..setStatus(provider.students.first.id, AttendanceStatus.present)
        ..setStatusFilter(StatusFilter.present);

      expect(provider.visibleStudents.single.name, 'Ada Lovelace');
    });

    test('the class filter keeps one section', () {
      provider.setClassFilter('Grade 8 - B');

      expect(provider.visibleStudents.single.name, 'Grace Hopper');
      expect(provider.filter.hasClass, isTrue);
    });

    test('sorting by name and by roll number', () {
      provider.setSort(RosterSort.name);
      expect(provider.visibleStudents.first.name, 'Ada Lovelace');

      provider.setSort(RosterSort.rollNumber);
      expect(provider.visibleStudents.first.name, 'Ada Lovelace');
    });

    test('sorting by status pushes the missing students first', () {
      provider.setStatus(provider.students.first.id, AttendanceStatus.present);
      provider.setSort(RosterSort.status);

      expect(provider.visibleStudents.first.name, 'Grace Hopper');
    });

    test('clearFilters keeps the sorting', () {
      provider
        ..setQuery('ada')
        ..setStatusFilter(StatusFilter.absent)
        ..setSort(RosterSort.name)
        ..clearFilters();

      expect(provider.filter.isActive, isFalse);
      expect(provider.filter.sort, RosterSort.name);
    });

    test('classNames lists the sections alphabetically', () {
      provider.addStudent('Chen', className: 'Grade 7 - A');

      expect(provider.classNames, ['Grade 7 - A', 'Grade 8 - A', 'Grade 8 - B']);
    });
  });

  group('updateStudent', () {
    setUp(() => provider.addStudent('Ada'));

    test('renames and moves a student', () {
      final id = provider.students.single.id;

      provider.updateStudent(
        id,
        name: '  Ada Lovelace ',
        className: 'Grade 8 - A',
      );

      expect(provider.students.single.name, 'Ada Lovelace');
      expect(provider.students.single.className, 'Grade 8 - A');
    });

    test('keeps the marks when the roster changes', () {
      final id = provider.students.single.id;
      provider
        ..setStatus(id, AttendanceStatus.present)
        ..updateStudent(id, name: 'Ada Lovelace');

      expect(provider.studentById(id)!.status, AttendanceStatus.present);
    });

    test('an unknown id is a no-op', () {
      provider.updateStudent('missing', name: 'Nobody');

      expect(provider.students.single.name, 'Ada');
    });
  });

  group('removeStudent', () {
    setUp(() => provider.addStudent('Ada'));

    test('removes the student and reports it back', () {
      final removed = provider.removeStudent(provider.students.single.id);

      expect(removed?.name, 'Ada');
      expect(provider.students, isEmpty);
    });

    test('also drops the marks of every lesson', () {
      final id = provider.students.single.id;
      provider.setStatus(id, AttendanceStatus.present);

      provider.removeStudent(id);

      expect(provider.marksForStudent(id), isEmpty);
      expect(provider.markedCount, 0);
    });

    test('unknown id returns null', () {
      expect(provider.removeStudent('missing'), isNull);
    });

    test('restoreStudent puts the student back at its position', () {
      provider.addStudent('Grace');
      final index = provider.students.indexWhere(
        (student) => student.name == 'Ada',
      );
      final removed = provider.removeStudent(provider.students[index].id)!;

      provider.restoreStudent(removed, index: index);

      expect(
        provider.students.map((student) => student.name),
        ['Ada', 'Grace'],
      );
    });

    test('restoreStudent ignores a duplicate id', () {
      final removed = provider.removeStudent(provider.students.single.id)!;
      provider.restoreStudent(removed);

      provider.restoreStudent(removed);

      expect(provider.students, hasLength(1));
    });
  });

  group('stats', () {
    test('an empty roster reports zeroes', () {
      expect(provider.stats.total, 0);
      expect(provider.stats.present, 0);
      expect(provider.stats.absent, 0);
      expect(provider.stats.attendanceRate, 0);
    });

    test('counts are derived from the roster', () {
      provider
        ..addStudent('Ada')
        ..addStudent('Grace')
        ..addStudent('Alan');
      provider.setAttendance(provider.students[0].id, true);
      provider.setAttendance(provider.students[1].id, true);

      expect(provider.stats.total, 3);
      expect(provider.stats.present, 2);
      expect(provider.stats.absent, 1);
      expect(provider.stats.attendanceRate, closeTo(2 / 3, 0.0001));
    });

    test('the exposed list is unmodifiable', () {
      provider.addStudent('Ada');

      expect(
        () => provider.students.add(
          const Student(id: 'x', name: 'X'),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('data tools', () {
    test('seedSampleRoster adds a demo class', () {
      final added = provider.seedSampleRoster();

      expect(added, 8);
      expect(provider.classNames, ['Grade 8 - A', 'Grade 8 - B']);
    });

    test('clearHistory keeps the roster', () {
      provider
        ..addStudent('Ada')
        ..markAllPresent()
        ..clearHistory();

      expect(provider.history, isEmpty);
      expect(provider.students, hasLength(1));
    });

    test('resetAll empties roster, history and filters', () {
      provider
        ..addStudent('Ada')
        ..markAllPresent()
        ..setQuery('ada')
        ..selectDate(DateTime(2026, 1, 1))
        ..resetAll();

      expect(provider.students, isEmpty);
      expect(provider.history, isEmpty);
      expect(provider.filter.isActive, isFalse);
      expect(provider.isSelectedDayToday, isTrue);
    });
  });

  test('seeding with initial students exposes them as absent', () {
    final seeded = AttendanceProvider(
      initialStudents: const [Student(id: 's1', name: 'Ada')],
    );

    expect(seeded.stats.total, 1);
    expect(seeded.stats.absent, 1);
  });

  test('seeding with records restores a past lesson', () {
    final seeded = AttendanceProvider(
      selectedDate: DateTime(2026, 3, 3),
      initialStudents: const [Student(id: 's1', name: 'Ada')],
      initialRecords: const {
        '2026-03-02': {'s1': AttendanceStatus.late},
      },
    );

    expect(seeded.history.single.marks['s1'], AttendanceStatus.late);
    expect(seeded.attendanceRateFor('s1'), 1);
  });
}