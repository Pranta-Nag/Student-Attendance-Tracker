import 'package:flutter_test/flutter_test.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/attendance_status.dart';
import 'package:studentattendancetracker/features/attendance/domain/models/attendance_stats.dart';
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

    test('exposes human readable labels', () {
      expect(AttendanceStatus.present.label, 'Present');
      expect(AttendanceStatus.absent.label, 'Absent');
    });
  });

  group('Student', () {
    test('defaults to absent', () {
      expect(ada.isPresent, isFalse);
      expect(ada.status, AttendanceStatus.absent);
    });

    test('copyWith keeps the id and replaces only the given fields', () {
      final present = ada.copyWith(status: AttendanceStatus.present);

      expect(present.id, ada.id);
      expect(present.status, AttendanceStatus.present);
      expect(ada.status, AttendanceStatus.absent,
          reason: 'must stay immutable');
    });

    test('supports value equality', () {
      expect(ada, const Student(id: '1', name: 'Ada'));
      expect(ada.hashCode, const Student(id: '1', name: 'Ada').hashCode);
      expect(ada, isNot(grace));
    });
  });

  group('AttendanceStats', () {
    test('is derived from the given students', () {
      final stats = AttendanceStats.fromStudents(const [ada, grace]);

      expect(stats.total, 2);
      expect(stats.present, 1);
      expect(stats.absent, 1);
      expect(stats.attendanceRate, 0.5);
    });

    test('an empty roster has a zero rate', () {
      final stats = AttendanceStats.fromStudents(const <Student>[]);

      expect(stats, AttendanceStats.empty);
      expect(stats.attendanceRate, 0);
    });

    test('a fully present roster has a rate of one', () {
      final stats = AttendanceStats.fromStudents(const [grace, grace]);

      expect(stats.attendanceRate, 1);
    });

    test('supports value equality', () {
      expect(
        AttendanceStats.fromStudents(const [ada]),
        const AttendanceStats(total: 1, present: 0, absent: 1),
      );
    });
  });
}
