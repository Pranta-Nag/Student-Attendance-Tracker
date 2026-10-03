# School Attendance

A Flutter register for teachers: mark a class present, keep a history per
lesson, and export the register. Built entirely on **Provider**
(`ChangeNotifier`) for state management and with **no other runtime
dependency**, so the app stays offline-first and data never leaves the device.

## Interface

Two complete visual languages, switchable at runtime in **Settings →
Appearance** (or straight from the app bar icon for light / dark):

- **Classic** (default) — the classic Material look: solid app bar, square
  cards, filled bottom navigation bar, outlined inputs.
- **Modern** — Material 3: tonal surfaces, rounded cards, pill bottom bar.

Attendance colours ship as a `ThemeExtension` (`StatusColors`), so every status
keeps its contrast in both brightnesses.

## Features

### Register (daily lesson)

- **Lesson picker** — arrows, a calendar dialog and a strip of the last 14 days
  with a dot on every day that already carries marks.
- **Marks per lesson** — marks are stored per calendar day, so any past lesson
  can be revisited without losing data.
- **Four statuses** — Present, Late, Excused, Absent. Late counts as attended,
  excused absences are excluded from the rate.
- **Counters** — Total / Present / Late / Absent plus an attendance-rate meter
  and a “marked x of y” progress badge.
- **Bulk actions** — mark everyone present (only the students still unmarked
  once the lesson has started), mark all absent, copy the previous lesson, or
  clear the lesson.
- **Search and filters** — free-text search over names and sections, status
  filter, section filter and sorting by roll number, name or status.
- **Student sheet** — tap a name for the status picker, the totals over the
  recorded lessons and the recent history; edit or remove from there.
- **Add students** — single dialog (name + section, roll number assigned
  automatically) or paste a whole class at once, one name per line.
- **Remove with undo** — deleting a student also drops their marks from every
  lesson; the snack bar brings them back at their original position.

### Reports

- Counters for the selected lesson and the number of recorded lessons.
- Trend bars for the last recorded lessons (dependency-free chart).
- Per-section split and per-student totals, weakest attendance first.
- **CSV export** to the clipboard, ready to paste into a spreadsheet.

### Settings

- School profile: school name, class/section, teacher, period, academic year —
  shown in the register header and in the CSV export.
- Appearance: interface style and light / dark / system theme.
- Attendance rules at a glance, plus data tools: load a sample class, clear the
  recorded lessons, reset everything.

## Architecture

Layered clean architecture, one vertical feature slice:

```
lib/
├── main.dart                     # runApp entry point
├── app.dart                      # Composition root (MultiProvider + themes)
├── core/
│   ├── theme/app_theme.dart      # classic + modern themes, StatusColors
│   ├── theme/app_style.dart      # AppStyle enum
│   └── utils/                    # date formatting, snack bar helpers
└── features/attendance/
    ├── domain/models/            # Pure Dart, no Flutter/Provider imports
    │   ├── attendance_status.dart
    │   ├── student.dart
    │   ├── attendance_stats.dart
    │   ├── attendance_day.dart
    │   ├── roster_filter.dart
    │   └── school_profile.dart
    ├── domain/reports/attendance_report.dart   # aggregation + CSV
    └── presentation/
        ├── providers/attendance_provider.dart   # ChangeNotifier state holder
        ├── providers/settings_provider.dart     # school + appearance prefs
        ├── actions/                             # shared dialog flows
        ├── screens/                             # home shell, register, reports, settings
        ├── dialogs/                             # add, bulk add, filters, profile, detail sheet
        └── widgets/                             # summary, row, date strip, meter, ...
```

### State management rules

| Concern | Owner |
| --- | --- |
| Roster, marks per lesson, filters, statistics | `AttendanceProvider extends ChangeNotifier` |
| School details, interface style, theme mode | `SettingsProvider extends ChangeNotifier` |
| UI subscription | `context.watch` / `Consumer` |
| Actions | `context.read<AttendanceProvider>()…` through the `actions/` flows |
| Publish changes | `notifyListeners()` |
| Form validation only | `StatefulWidget` in the dialogs |

No widget uses `setState` for attendance, student or settings state, and no
other state management package is used. `Student` is immutable, so the UI can
never mutate state behind the provider's back; `AttendanceStats`,
`AttendanceDay` and `AttendanceReport` are derived on every read, so counters and
reports can never go stale. Mutations that change nothing are short-circuited
before `notifyListeners()`, which keeps listener counts honest.

## Running

```bash
flutter pub get
flutter run
```

## Tests

```bash
flutter test
```

128 tests: domain models (statuses, stats, days, filters, profile), the
providers (notification behaviour, per-lesson marks, roll-over, filters, data
tools), the report aggregation and CSV export, the settings provider, the date
helpers, the register screen end to end (add, mark, delete, undo, filters,
lesson navigation, tabs) and phone-sized layout smoke tests for both interface
styles in light and dark mode.