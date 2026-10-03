import 'package:flutter_test/flutter_test.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/attendance_day.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/attendance_stats.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/attendance_status.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/roster_filter.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/school_profile.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/student.dart';

void main() {
  const ada = Student(id: '1', name: 'Ada');
  const grace =
      Student(id: '2', name: 'Grace', status: AttendanceStatus.present);

  group('AttendanceStatus', () {
    test('maps to and from the checkbox value', () {
      expect(AttendanceStatus.present.isPresent, isTrue);
      expect(AttendanceStatus.absent.isPresent, isFalse);
      expect(AttendanceStatus.fromCheckbox(true), AttendanceStatus.present);
      expect(AttendanceStatus.fromCheckbox(false), AttendanceStatus.absent);
    });

    test('counts late arrivals as attended', () {
      expect(AttendanceStatus.late.isPresent, isTrue);
      expect(AttendanceStatus.late.label, 'Late');
      expect(AttendanceStatus.late.checkboxValue, isTrue);
    });

    test('an excused absence still needs a decision', () {
      expect(AttendanceStatus.excused.isPresent, isFalse);
      expect(AttendanceStatus.excused.needsAttention, isTrue);
      expect(AttendanceStatus.late.needsAttention, isFalse);
    });

    test('exposes human readable labels', () {
      expect(AttendanceStatus.present.label, 'Present');
      expect(AttendanceStatus.absent.label, 'Absent');
    });
  });

  group('Student', () {
    test('defaults to absent in the general class', () {
      expect(ada.isPresent, isFalse);
      expect(ada.status, AttendanceStatus.absent);
      expect(ada.className, kDefaultClassName);
      expect(ada.rollNumber, 0);
      expect(ada.rollLabel, 'Unassigned');
    });

    test('copyWith keeps the id and replaces only the given fields', () {
      final present = ada.copyWith(status: AttendanceStatus.present);

      expect(present.id, ada.id);
      expect(present.status, AttendanceStatus.present);
      expect(ada.status, AttendanceStatus.absent,
          reason: 'must stay immutable');
    });

    test('copyWith updates the section and the roll number', () {
      const moved = Student(
        id: '3',
        name: 'Chen',
        className: 'Grade 9 - A',
        rollNumber: 12,
      );
      final result = moved.copyWith(className: 'Grade 9 - B');

      expect(result.className, 'Grade 9 - B');
      expect(result.rollNumber, 12);
      expect(result.rollLabel, 'No. 12');
    });

    test('supports value equality', () {
      expect(ada, const Student(id: '1', name: 'Ada'));
      expect(ada.hashCode, const Student(id: '1', name: 'Ada').hashCode);
      expect(ada, isNot(grace));
      expect(
        const Student(id: '1', name: 'Ada', className: 'B'),
        isNot(ada),
        reason: 'the section is part of the identity',
      );
    });
  });

  group('AttendanceStats', () {
    test('is derived from the given students', () {
      final stats = AttendanceStats.fromStudents(const [ada, grace]);

      expect(stats.total, 2);
      expect(stats.present, 1);
      expect(stats.absent, 1);
      expect(stats.attendanceRate, 0.5);
      expect(stats.summaryLine, '50% attendance recorded');
    });

    test('an empty roster has a zero rate', () {
      final stats = AttendanceStats.fromStudents(const <Student>[]);

      expect(stats, AttendanceStats.empty);
      expect(stats.attendanceRate, 0);
      expect(stats.summaryLine, 'No students enrolled yet');
    });

    test('a fully present roster has a rate of one', () {
      final stats = AttendanceStats.fromStudents(const [grace, grace]);

      expect(stats.attendanceRate, 1);
      expect(stats.attendancePercent, 100);
    });

    test('late students count as attended, excused ones as missing', () {
      const late = Student(id: '3', name: 'Late', status: AttendanceStatus.late);
      const excused = Student(
        id: '4',
        name: 'Excused',
        status: AttendanceStatus.excused,
      );
      final stats = AttendanceStats.fromStudents(const [late, excused]);

      expect(stats.late, 1);
      expect(stats.excused, 1);
      expect(stats.absent, 0);
      expect(stats.attended, 1);
      expect(stats.missing, 1);
      expect(stats.attendanceRate, 0.5);
    });

    test('supports value equality', () {
      expect(
        AttendanceStats.fromStudents(const [ada]),
        const AttendanceStats(total: 1, present: 0, absent: 1),
      );
    });
  });

  group('AttendanceDay', () {
    const roster = [
      Student(id: '1', name: 'Ada'),
      Student(id: '2', name: 'Grace'),
    ];

    test('resolves the marks against the roster', () {
      final day = AttendanceDay.resolve(
        date: DateTime(2026, 3, 2, 15, 30),
        marks: const {'2': AttendanceStatus.present},
        students: roster,
      );

      expect(day.date, DateTime(2026, 3, 2));
      expect(day.key, '2026-03-02');
      expect(day.markedCount, 1);
      expect(day.unmarkedCount, 1);
      expect(day.stats.present, 1);
      expect(day.stats.absent, 1);
      expect(day.isMarked('2'), isTrue);
      expect(day.isMarked('1'), isFalse);
    });

    test('a day without marks has no history', () {
      final day = AttendanceDay.resolve(
        date: DateTime(2026, 3, 2),
        marks: const {},
        students: roster,
      );

      expect(day.hasMarks, isFalse);
    });

    test('sorts newest first', () {
      final monday = AttendanceDay.resolve(
        date: DateTime(2026, 3, 2),
        marks: const {'1': AttendanceStatus.present},
        students: roster,
      );
      final tuesday = AttendanceDay.resolve(
        date: DateTime(2026, 3, 3),
        marks: const {'1': AttendanceStatus.absent},
        students: roster,
      );

      expect(
        [monday, tuesday]..sort(compareDaysDescending),
        [tuesday, monday],
      );
    });
  });

  group('RosterFilter', () {
    test('is inactive by default', () {
      const filter = RosterFilter();

      expect(filter.isActive, isFalse);
      expect(filter.activeCount, 0);
      expect(filter.matches(AttendanceStatus.absent, 'Ada', 'General'), isTrue);
    });

    test('counts the active restrictions', () {
      const filter = RosterFilter(
        query: 'ada',
        status: StatusFilter.present,
        className: 'A',
      );

      expect(filter.activeCount, 3);
    });

    test('matches on name, class and status', () {
      const filter = RosterFilter(
        query: 'ada',
        status: StatusFilter.present,
        className: 'Grade 8',
      );

      expect(
        filter.matches(AttendanceStatus.present, 'Ada Lovelace', 'Grade 8'),
        isTrue,
      );
      expect(
        filter.matches(AttendanceStatus.absent, 'Ada Lovelace', 'Grade 8'),
        isFalse,
      );
      expect(
        filter.matches(AttendanceStatus.present, 'Grace', 'Grade 8'),
        isFalse,
      );
      expect(
        filter.matches(AttendanceStatus.present, 'Ada', 'Grade 9'),
        isFalse,
      );
    });

    test('a query also matches the class name', () {
      const filter = RosterFilter(query: 'grade 8');

      expect(filter.matches(AttendanceStatus.absent, 'Ada', 'Grade 8'), isTrue);
    });

    test('copyWith can clear the class only', () {
      const filter = RosterFilter(className: 'A', sort: RosterSort.name);

      expect(filter.copyWith(clearClass: true).className, isNull);
      expect(filter.copyWith(clearClass: true).sort, RosterSort.name);
    });

    test('enum lookups fall back to the defaults', () {
      expect(StatusFilter.fromName('late'), StatusFilter.late);
      expect(StatusFilter.fromName('nope'), StatusFilter.all);
      expect(RosterSort.fromName('name'), RosterSort.name);
      expect(RosterSort.fromName(null), RosterSort.rollNumber);
    });
  });

  group('SchoolProfile', () {
    const profile = SchoolProfile(
      schoolName: 'Riverside High',
      section: 'Grade 8 - B',
      teacher: 'Ms. Okafor',
      academicYear: '2026 / 2027',
    );

    test('joins the details into one line', () {
      expect(profile.detailsLine, 'Grade 8 - B • 2026 / 2027');
      expect(profile.caption, 'Riverside High • Grade 8 - B • 2026 / 2027');
    });

    test('falls back gracefully when details are missing', () {
      const empty = SchoolProfile(schoolName: 'Riverside High');

      expect(empty.detailsLine, '');
      expect(empty.caption, 'Riverside High');
      expect(empty.subtitle, 'School register');
    });

    test('supports value equality and copyWith', () {
      expect(profile, profile.copyWith());
      expect(profile.copyWith(section: 'A'), isNot(profile));
    });
  });
}