# Brief for agy: 4 dead drawer buttons in `school_admin_dashboard.dart`

Small, narrowly-scoped UI fix — not a design decision, just wiring
something up correctly.

## The bug

`apps/user_app/lib/pages/dashboard/school_admin_dashboard.dart` — the
side drawer has 6 items, but 4 of them do literally nothing when tapped:

```dart
DrawerItem(icon: Icons.dashboard, title: 'Dashboard โรงเรียน', onTap: (_) {}),   // line 18-23
DrawerItem(icon: Icons.videocam, title: 'กล้อง CCTV', onTap: (_) {}),            // line 39-44
DrawerItem(icon: Icons.schedule, title: 'ตั้งเวลาอุปกรณ์', onTap: (_) {}),        // line 45-50
DrawerItem(icon: Icons.bar_chart, title: 'รายงาน ESG', onTap: (_) {}),           // line 51-56
```

Only `จัดการผู้ใช้` and `Consent Policy` navigate anywhere. Note this is
different from the body of the same page, which already handles 3 of
these 4 honestly with `ComingSoonCard(phase: 'Phase 3'/'Phase 4'/'Phase 5'/'Phase 6')`
— the body tells the admin these aren't built yet; the drawer just
silently does nothing, which reads as broken rather than "not built yet."

## Fix

Don't build the 4 missing features — that's real, separate work (energy
dashboard, CCTV+AI, device auto-scheduling, ESG report) each with its own
backend to design later. For this pass, just make the drawer consistent
with what the body already honestly says:

- `Dashboard โรงเรียน` — this drawer item is redundant (we're already on
  the dashboard). Either remove it from the drawer entirely, or have it
  just close the drawer (`Navigator.pop(ctx)`) if removing breaks some
  test/expectation elsewhere — check if anything references it first.
- `กล้อง CCTV`, `ตั้งเวลาอุปกรณ์`, `รายงาน ESG` — these each already have
  a matching `ComingSoonCard` in the body with a phase label. Reuse the
  same "coming soon" messaging instead of a silent no-op: either
  `Navigator.pop(ctx)` + a `SnackBar` saying something like
  "ฟีเจอร์นี้อยู่ระหว่างพัฒนา (Phase X)" with the matching phase number
  from the body card, or scroll/navigate to the matching `ComingSoonCard`
  in the body if that's easy given the existing `SingleChildScrollView`.
  Snackbar is the simpler, lower-risk option — pick that unless
  scroll-to-card is trivial.

## Verify

Real click-through in the running app (or the same headless-Chromium
approach used for the parent/executive verification this session — serve
`build/web`, log in as `school_admin`, open the drawer, click each of the
4 items, confirm something visibly happens instead of nothing). Don't
just `flutter analyze` this — a no-op `onTap` and a working one both
analyze clean.
