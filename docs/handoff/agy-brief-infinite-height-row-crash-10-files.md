# Brief for agy: `Row(crossAxisAlignment: stretch)` crashes 10 ported pages — confirmed on 1, same pattern in the other 9

## Confirmed bug

`parent_learning_page.dart` — the "การเรียน" tab renders **completely
blank** for a real parent login. `flutter analyze`/`flutter test` don't
catch this (release web build swallows the error silently — you have to
run `flutter run -d web-server` in **debug mode** to see it at all).

Root cause, line 244:

```dart
return const Row(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Expanded(flex: 4, child: _AttendanceLearningCard()),
    SizedBox(width: 14),
    Expanded(flex: 4, child: _AssignmentSummaryCard()),
    SizedBox(width: 14),
    Expanded(flex: 4, child: _OverallPerformanceCard()),
  ],
);
```

This `Row` sits inside `LayoutBuilder` → `Column` →
`SingleChildScrollView` — i.e. **unbounded vertical space** (that's what
makes it scrollable). `CrossAxisAlignment.stretch` on a `Row` tells its
children to stretch to fill the *cross* axis, which for a `Row` is
height. Stretching to fill "all available height" when available height
is literally infinite throws:

```
BoxConstraints forces an infinite height.
The offending constraints were:
  BoxConstraints(0.0<=w<=Infinity, h=Infinity)
```

...and the whole subtree fails to paint. Nothing shows, no error banner,
no crash dialog — just blank.

This is a bug from **the original UI port** (director_dashboard_flutter/
parent_portal_split → this repo), not from this session's backend-wiring
pass — it was just never actually clicked into and looked at in a real
browser until now.

## The other 9 files use the identical pattern — audit each one live

Grepped `CrossAxisAlignment.stretch` across every ported page. 18 more
occurrences, 9 files:

- `parent_dashboard_page.dart` — lines 220, 258
- `parent_attendance_page.dart` — lines 170, 208
- `parent_settings_page.dart` — line 104
- `parent_academic_calendar_page.dart` — lines 218, 251
- `director_overview_page.dart` — lines 125, 590, 885, 911, 937, 1102, 1274
- `director_meetings_page.dart` — line 231
- `director_settings_page.dart` — lines 110, 144
- `director_learning_page.dart` — lines 224, 744
- `director_environment_page.dart` — lines 248, 510

**Not all of these are necessarily broken.** `CrossAxisAlignment.stretch`
on a `Row` is completely fine when the `Row` itself sits inside a
height-bounded ancestor — e.g. `director_overview_page.dart` already has
at least one correct usage wrapped in `SizedBox(height: 370, child: Row(...))`
elsewhere in that same file. The only way to know which of these 18 are
actually broken is the same way this one was found: **load the real page
in a browser and look**, not read the code and guess — nested
`LayoutBuilder`/`Column`/scroll-view ancestry is easy to misjudge by eye,
and this exact bug proves that.

## How to check each one (same method used to find the first one)

`flutter analyze`/`flutter test` won't catch this — confirmed. Use:

```bash
flutter run -d web-server --web-port=8766 --dart-define-from-file=../../env.json
```

Debug mode prints the full "BoxConstraints forces an infinite height"
assertion with the exact file/line to the browser console
(`window.console` — or capture it however you're driving the browser).
A release `flutter build web` will NOT show this — it fails silently,
which is exactly why this stayed hidden through the earlier verification
pass.

Go through every tab of both `ParentNavigationShell` and
`DirectorNavigationShell` at a desktop width (≥1024px — several of these
`Row`s are inside a `LayoutBuilder` that only takes the `Row` branch
above some width breakpoint, so a narrow viewport won't trigger it even
where it's genuinely broken). For each blank/broken tab, find which of
the `CrossAxisAlignment.stretch` `Row`s in that file is the actual
offender via the console stack trace (same as the line 244 example
above) — don't just fix all 18 blind, some are fine and touching them
adds noise.

## Fix pattern

For ones that ARE broken (a `Row(crossAxisAlignment: stretch)` inside
unbounded vertical space), wrap it in `IntrinsicHeight`:

```dart
return IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [ ... ],
  ),
);
```

This makes the `Row` compute a bounded height from its children's
natural height instead of trying to fill infinite space — the stretch
behavior (all three cards same height) still works, just resolved
against a real number now. Simpler than picking an arbitrary
`SizedBox(height: ...)` like the working example elsewhere in
`director_overview_page.dart` does — that only works because someone
picked a magic number (370) that happens to fit; `IntrinsicHeight`
doesn't need one.

## Verify

Same rule as always — don't trust `flutter analyze`/`flutter test`,
they already proved blind to this exact bug once. For every tab in both
navigation shells: real login, real click into the tab, real screenshot,
confirm content actually renders (not blank) at both a narrow and a wide
viewport. This is the same headless-Chromium-with-console-capture
approach used to find the original bug — reuse it rather than eyeballing
code.
