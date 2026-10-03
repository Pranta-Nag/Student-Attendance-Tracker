import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/date_formats.dart';
import '../../domain/models/attendance_day.dart';
import '../../domain/models/attendance_stats.dart';
import '../../domain/models/attendance_status.dart';
import '../../domain/models/roster_filter.dart';
import '../../domain/models/student.dart';

/// Single source of truth for the register.
///
/// It owns the roster, the marks recorded per calendar day, and the active
/// filters. Every mutation funnels through this class which then publishes the
/// change with [notifyListeners]; widgets read it with `context.watch` /
/// `Consumer` and trigger actions with `context.read`, so no widget ever holds
/// a copy of the data or needs `setState`.
class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider({
    List<Student> initialStudents = const <Student>[],
    Map<String, Map<String, AttendanceStatus>> initialRecords =
        const <String, Map<String, AttendanceStatus>>{},
    DateTime? selectedDate,
  })  : _students = List<Student>.of(initialStudents),
        _records = <String, Map<String, AttendanceStatus>>{
          for (final entry in initialRecords.entries)
            entry.key: Map<String, AttendanceStatus>.of(entry.value),
        },
        _selectedDate = startOfDay(selectedDate ?? DateTime.now()),
        _nextId = initialStudents.length;

  final List<Student> _students;

  /// `yyyy-MM-dd` → (`studentId` → status) marks.
  final Map<String, Map<String, AttendanceStatus>> _records;

  DateTime _selectedDate;
  int _nextId;
  RosterFilter _filter = const RosterFilter();

  // ---------------------------------------------------------------- reading

  /// Read-only roster with the marks of [selectedDate] resolved onto it.
  List<Student> get students => UnmodifiableListView<Student>(
        _students.map(_withMark).toList(growable: false),
      );

  /// The roster after search, status filter, class filter and sorting.
  List<Student> get visibleStudents {
    final visible = _students
        .map(_withMark)
        .where((student) => _filter.matches(
              student.status,
              student.name,
              student.className,
            ))
        .toList();

    visible.sort(_compare);
    return UnmodifiableListView<Student>(visible);
  }

  /// Counters for the selected day, never stale because they are derived.
  AttendanceStats get stats => AttendanceStats.fromStudents(
        _students.map(_withMark),
      );

  DateTime get selectedDate => _selectedDate;

  String get selectedDateKey => dateKey(_selectedDate);

  bool get isSelectedDayToday =>
      selectedDateKey == dateKey(DateTime.now());

  /// The selected day resolved against the current roster.
  AttendanceDay get selectedDay => _resolve(_selectedDate);

  /// Recorded days, newest first.
  List<AttendanceDay> get history => _records.keys
      .map(dateFromKey)
      .toList()
      .map(_resolve)
      .toList(growable: false)
        ..sort(compareDaysDescending);

  /// The last [count] calendar days ending today, oldest first; used by the
  /// date strip so future days can be pre-marked but history is one tap away.
  List<DateTime> recentDates(int count, {DateTime? today}) {
    final end = startOfDay(today ?? DateTime.now());
    return List<DateTime>.generate(
      count,
      (index) => end.subtract(Duration(days: count - 1 - index)),
    );
  }

  RosterFilter get filter => _filter;

  /// Sections currently present in the roster, alphabetically.
  List<String> get classNames {
    final names = _students.map((student) => student.className).toSet().toList()
      ..sort();
    return List<String>.unmodifiable(names);
  }

  int get totalStudents => _students.length;

  bool get hasStudents => _students.isNotEmpty;

  /// How many students are marked on the selected day.
  int get markedCount => _records[selectedDateKey]?.length ?? 0;

  /// How many students still have no mark on the selected day.
  int get unmarkedCount => totalStudents - markedCount;

  Student? studentById(String id) {
    for (final student in _students) {
      if (student.id == id) return _withMark(student);
    }
    return null;
  }

  /// Marks of one student across every recorded day, keyed by [dateKey].
  Map<String, AttendanceStatus> marksForStudent(String studentId) {
    final marks = <String, AttendanceStatus>{};
    for (final entry in _records.entries) {
      final status = entry.value[studentId];
      if (status != null) marks[entry.key] = status;
    }
    return Map<String, AttendanceStatus>.unmodifiable(marks);
  }

  /// Attendance rate of one student over the recorded days; `0` when the
  /// student has no marks yet.
  double attendanceRateFor(String studentId) {
    final marks = marksForStudent(studentId).values;
    if (marks.isEmpty) return 0;
    final attended = marks.where((status) => status.isPresent).length;
    return attended / marks.length;
  }

  /// Days on which [studentId] carries a mark, newest first.
  List<AttendanceDay> daysForStudent(String studentId) => _records.keys
      .where((key) => _records[key]!.containsKey(studentId))
      .map(dateFromKey)
      .map(_resolve)
      .toList(growable: false)
        ..sort(compareDaysDescending);

  /// Attendance of one day, or `null` when nothing was recorded.
  AttendanceDay? dayFor(DateTime date) {
    final key = dateKey(date);
    if (!_records.containsKey(key)) return null;
    return _resolve(date);
  }

  bool dayHasMarks(DateTime date) =>
      (_records[dateKey(date)]?.isNotEmpty) ?? false;

  // --------------------------------------------------------------- filtering

  void setQuery(String query) {
    if (query == _filter.query) return;
    _filter = _filter.copyWith(query: query);
    notifyListeners();
  }

  void setStatusFilter(StatusFilter status) {
    if (status == _filter.status) return;
    _filter = _filter.copyWith(status: status);
    notifyListeners();
  }

  void setClassFilter(String? className) {
    if (className == _filter.className) return;
    _filter = className == null
        ? _filter.copyWith(clearClass: true)
        : _filter.copyWith(className: className);
    notifyListeners();
  }

  void setSort(RosterSort sort) {
    if (sort == _filter.sort) return;
    _filter = _filter.copyWith(sort: sort);
    notifyListeners();
  }

  /// Drops search, status and class restrictions, keeping the sorting.
  void clearFilters() {
    if (!_filter.isActive) return;
    _filter = RosterFilter(sort: _filter.sort);
    notifyListeners();
  }

  // ------------------------------------------------------------------- dates

  /// Switches the register to another day. Marks are kept per day, so the
  /// teacher can revisit any past date without losing data.
  void selectDate(DateTime date) {
    final target = startOfDay(date);
    if (target == _selectedDate) return;
    _selectedDate = target;
    notifyListeners();
  }

  /// Moves the register by [delta] days.
  void shiftDate(int delta) => selectDate(_selectedDate.add(
        Duration(days: delta),
      ));

  void selectToday() => selectDate(DateTime.now());

  // ------------------------------------------------------------------ roster

  /// Registers a new student, initially absent on the selected day.
  ///
  /// Returns `false` and leaves the roster untouched when [name] is blank,
  /// keeping the "name cannot be empty" rule enforced at the data layer too.
  bool addStudent(String name, {String? className, int? rollNumber}) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) return false;

    _students.add(
      Student(
        id: 'student_${_nextId++}',
        name: normalizedName,
        className: _normalizeClass(className),
        rollNumber: rollNumber ?? _nextRollFor(_normalizeClass(className)),
      ),
    );
    notifyListeners();
    return true;
  }

  /// Adds several students at once, skipping blank lines.
  ///
  /// Useful for pasting a list copied from a register; returns how many were
  /// added.
  int addStudents(Iterable<String> names, {String? className}) {
    var added = 0;
    for (final name in names) {
      if (addStudent(name, className: className)) added++;
    }
    return added;
  }

  /// Updates the editable fields of a student. Blank names are ignored.
  void updateStudent(
    String studentId, {
    String? name,
    String? className,
    int? rollNumber,
  }) {
    final index = _indexOf(studentId);
    if (index == -1) return;

    final trimmed = name?.trim();
    if (name != null && trimmed == null) return;

    _students[index] = _students[index].copyWith(
      name: trimmed,
      className: className == null ? null : _normalizeClass(className),
      rollNumber: rollNumber,
    );
    notifyListeners();
  }

  /// Flips the attendance of [studentId] between present and absent.
  void toggleAttendance(String studentId) {
    final student = studentById(studentId);
    if (student == null) return;
    setStatus(
      studentId,
      student.isPresent ? AttendanceStatus.absent : AttendanceStatus.present,
    );
  }

  /// Forces the attendance of [studentId] to match a checkbox value.
  void setAttendance(String studentId, bool isPresent) =>
      setStatus(studentId, AttendanceStatus.fromCheckbox(isPresent));

  /// Records [status] for [studentId] on the selected day.
  ///
  /// No-op when the id is unknown or the status is unchanged, which keeps the
  /// notification count honest for listeners.
  void setStatus(String studentId, AttendanceStatus status) {
    if (_indexOf(studentId) == -1) return;
    final key = selectedDateKey;
    final day = Map<String, AttendanceStatus>.of(_records[key] ?? const {});
    if (day[studentId] == status) return;

    day[studentId] = status;
    _records[key] = day;
    notifyListeners();
  }

  /// Applies [status] to the whole roster of the selected day.
  void markAll(AttendanceStatus status) {
    if (_students.isEmpty) return;

    final day = <String, AttendanceStatus>{
      for (final student in _students) student.id: status,
    };
    _records[selectedDateKey] = day;
    notifyListeners();
  }

  /// Convenience wrapper used by the "mark all present" action.
  void markAllPresent() => markAll(AttendanceStatus.present);

  /// Marks only the students that are still unmarked on the selected day.
  int markAllPresentUnmarked() {
    if (_students.isEmpty) return 0;

    final day = Map<String, AttendanceStatus>.of(
      _records[selectedDateKey] ?? const {},
    );
    var touched = 0;
    for (final student in _students) {
      if (day.containsKey(student.id)) continue;
      day[student.id] = AttendanceStatus.present;
      touched++;
    }
    if (touched == 0) return 0;

    _records[selectedDateKey] = day;
    notifyListeners();
    return touched;
  }

  /// Copies the marks of the closest earlier recorded day onto the selected
  /// day; returns how many students were copied, or `0` when nothing to copy.
  int rollOverFromPreviousDay() {
    final source = history.firstWhere(
      (day) => day.date.isBefore(_selectedDate) && day.hasMarks,
      orElse: _noDay,
    );
    if (!source.hasMarks) return 0;

    var copied = 0;
    final day = <String, AttendanceStatus>{};
    for (final student in _students) {
      final status = source.marks[student.id];
      if (status == null) continue;
      day[student.id] = status;
      copied++;
    }
    if (copied == 0) return 0;

    _records[selectedDateKey] = day;
    notifyListeners();
    return copied;
  }

  /// Drops every mark of the selected day while keeping the roster.
  void clearSelectedDay() {
    if (_records.remove(selectedDateKey) == null) return;
    notifyListeners();
  }

  /// Removes [studentId] and returns the removed student, or `null` when the id
  /// is unknown. Returning it enables an undo affordance in the UI.
  Student? removeStudent(String studentId) {
    final index = _indexOf(studentId);
    if (index == -1) return null;

    final removed = _students.removeAt(index);
    _records.removeWhere(
      (_, marks) => marks.remove(studentId) != null,
    );
    notifyListeners();
    return removed;
  }

  /// Puts a previously removed [student] back at its original position.
  void restoreStudent(Student student, {int? index}) {
    if (studentById(student.id) != null) return;

    final target = (index ?? _students.length).clamp(0, _students.length);
    _students.insert(target, student);
    notifyListeners();
  }

  // -------------------------------------------------------------------- data

  /// Adds a small demo class, handy for a first run or a demo.
  int seedSampleRoster({String className = 'Grade 8 - A'}) {
    const samples = <(String, String)>[
      ('Aarav Sharma', 'Grade 8 - A'),
      ('Bella Nguyen', 'Grade 8 - A'),
      ('Chen Wei', 'Grade 8 - A'),
      ('Dalia Haddad', 'Grade 8 - A'),
      ('Elias Novak', 'Grade 8 - A'),
      ('Fatima Zahra', 'Grade 8 - A'),
      ('Gabriel Santos', 'Grade 8 - B'),
      ('Hana Kobayashi', 'Grade 8 - B'),
    ];

    var added = 0;
    for (final (name, section) in samples) {
      if (addStudent(name, className: section)) added++;
    }
    if (_filter.hasClass && !classNames.contains(_filter.className)) {
      _filter = _filter.copyWith(clearClass: true);
    }
    return added;
  }

  /// Removes every recorded day but keeps the roster.
  void clearHistory() {
    if (_records.isEmpty) return;
    _records.clear();
    notifyListeners();
  }

  /// Empties the roster, the history and the filters.
  void resetAll() {
    _students.clear();
    _records.clear();
    _filter = const RosterFilter();
    _selectedDate = startOfDay(DateTime.now());
    notifyListeners();
  }

  // ---------------------------------------------------------------- internals

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

  /// Placeholder returned by [rollOverFromPreviousDay] when nothing is recorded
  /// before the selected day.
  static AttendanceDay _noDay() => AttendanceDay(
        date: _epoch,
        marks: const <String, AttendanceStatus>{},
        stats: AttendanceStats.empty,
      );

  Student _withMark(Student student) => student.copyWith(
        status: _records[selectedDateKey]?[student.id] ??
            AttendanceStatus.absent,
      );

  AttendanceDay _resolve(DateTime date) => AttendanceDay.resolve(
        date: date,
        marks: _records[dateKey(date)] ?? const {},
        students: _students,
      );

  int _indexOf(String studentId) {
    for (var i = 0; i < _students.length; i++) {
      if (_students[i].id == studentId) return i;
    }
    return -1;
  }

  String _normalizeClass(String? className) {
    final trimmed = className?.trim() ?? '';
    return trimmed.isEmpty ? kDefaultClassName : trimmed;
  }

  int _nextRollFor(String className) {
    var highest = 0;
    for (final student in _students) {
      if (student.className != className) continue;
      if (student.rollNumber > highest) highest = student.rollNumber;
    }
    return highest + 1;
  }

  int _compare(Student a, Student b) {
    switch (_filter.sort) {
      case RosterSort.name:
        final byName =
            a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return byName != 0 ? byName : a.rollNumber - b.rollNumber;
      case RosterSort.status:
        final byStatus = _statusOrder(a.status).compareTo(
          _statusOrder(b.status),
        );
        if (byStatus != 0) return byStatus;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case RosterSort.rollNumber:
        final byClass = a.className.compareTo(b.className);
        if (byClass != 0) return byClass;
        final byRoll = _rollOrder(a.rollNumber).compareTo(
          _rollOrder(b.rollNumber),
        );
        if (byRoll != 0) return byRoll;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
  }

  /// Students without a roll number always sink to the bottom.
  static int _rollOrder(int rollNumber) => rollNumber > 0 ? rollNumber : 1 << 20;

  static int _statusOrder(AttendanceStatus status) => switch (status) {
        AttendanceStatus.absent => 0,
        AttendanceStatus.excused => 1,
        AttendanceStatus.late => 2,
        AttendanceStatus.present => 3,
      };
}