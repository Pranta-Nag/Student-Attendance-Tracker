# Student Attendance Tracker

A single-screen Flutter app for marking and tracking student attendance, built
entirely on **Provider** (`ChangeNotifier`) for state management.

## Features

- **Student list** — name, live status badge (Present/Absent) and a checkbox.
- **Mark attendance** — checking the box marks a student *Present*, unchecking
  marks them *Absent*. The list and the statistics update instantly.
- **Add student** — a `FloatingActionButton` opens a dialog with a validated
  name field. New students are always added as *Absent*.
- **Delete student** — a delete icon per row removes the student, with an
  *Undo* action in a snack bar.
- **Statistics** — Total / Present / Absent counters plus an attendance-rate
  bar, all computed from the provider data on every read.
- **Empty state** — friendly guidance with a call to action when the roster is
  empty.
- **Mark all present** — bulk action in the app bar.

## Architecture

Layered clean architecture, one vertical feature slice:

```
lib/
├── main.dart                     # runApp entry point
├── app.dart                      # Composition root (ChangeNotifierProvider)
├── core/
│   └── theme/app_theme.dart      # Material 3 theme + status colors
└── features/attendance/
    ├── domain/models/            # Pure Dart, no Flutter/Provider imports
    │   ├── attendance_status.dart
    │   ├── student.dart
    │   └── attendance_stats.dart
    └── presentation/
        ├── providers/attendance_provider.dart   # ChangeNotifier state holder
        ├── screens/attendance_screen.dart        # The one and only screen
        ├── dialogs/add_student_dialog.dart
        └── widgets/                              # summary, row, empty state
```

### State management rules

| Concern | Owner |
| --- | --- |
| Roster, attendance, statistics | `AttendanceProvider extends ChangeNotifier` |
| UI subscription | `Consumer<AttendanceProvider>` / `context.select` |
| Actions | `context.read<AttendanceProvider>()…` |
| Publish changes | `notifyListeners()` |
| Form validation only | `StatefulWidget` in the dialog |

No widget uses `setState` for attendance or student state, and no other state
management package is used. `Student` is immutable, so the UI can never mutate
state behind the provider's back; `AttendanceStats` is derived from the roster
on every read, so the counters can never go stale.

## Running

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```

37 tests covering the domain models, the provider (including the "name cannot
be empty" invariant and notification behaviour) and the screen end to end
(add, mark present/absent, delete, undo, statistics and the empty state).
