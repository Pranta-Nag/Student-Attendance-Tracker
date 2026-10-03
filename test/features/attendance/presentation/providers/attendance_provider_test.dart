import 'package:flutter_test/flutter_test.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/attendance_status.dart';
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
  });

  group('attendance', () {
    setUp(() {
      provider
        ..addStudent('Ada')
        ..addStudent('Grace');
    });

    test('toggle flips a student between present and absent', () {
      final id = provider.students.first.id;
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.toggleAttendance(id);
      expect(provider.studentById(id)!.isPresent, isTrue);

      provider.toggleAttendance(id);
      expect(provider.studentById(id)!.isPresent, isFalse);
      expect(notifications, 2);
    });

    test('setAttendance mirrors the checkbox value', () {
      final id = provider.students.first.id;

      provider.setAttendance(id, true);
      expect(provider.studentById(id)!.status, AttendanceStatus.present);

      provider.setAttendance(id, false);
      expect(provider.studentById(id)!.status, AttendanceStatus.absent);
    });

    test('unknown id is a no-op', () {
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider
        ..toggleAttendance('missing')
        ..setAttendance('missing', true);

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
  });

  group('removeStudent', () {
    setUp(() => provider.addStudent('Ada'));

    test('removes the student and reports it back', () {
      final removed = provider.removeStudent(provider.students.single.id);

      expect(removed?.name, 'Ada');
      expect(provider.students, isEmpty);
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

  test('seeding with initial students exposes them as absent', () {
    final seeded = AttendanceProvider(
      initialStudents: const [Student(id: 's1', name: 'Ada')],
    );

    expect(seeded.stats.total, 1);
    expect(seeded.stats.absent, 1);
  });
}
