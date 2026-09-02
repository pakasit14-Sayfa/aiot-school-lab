# Brief for agy: SOS hero card must also cover real panic-button events, not just app SOS

**Applies to both `director_emergency_page.dart` AND
`teacher_incident_inbox_page.dart`** — user asked directly ("ของครูด้วยไหม")
whether this gap exists on the teacher side too after the restyle
(`agy-brief-teacher-emergency-visual-parity.md`, commit `405621e`).
Checked: same root gap exists there, but the teacher file's actual state
is messier — see the dedicated "Teacher-side specifics" section near the
bottom before starting on that file, it's not just "copy the director
fix."

User audit (2026-08-31), re-verified live against production data: the
big red hero card at the top of `director_emergency_page.dart`
(`_sosActiveCard()` + its detail dialog) only reflects a real active
**student-app** SOS (`_activeSosIncident` getter, line ~31 — filters
`_realIncidents` from `IncidentService.listTeacherIncidentReports()` by
`category == IncidentCategory.sos && status not in (resolved, cancelled)`).

It does **not** look at `_realEmergencyEvents`
(`EmergencyService.listEmergencyEvents()`) — the real physical
panic-button signal table (`emergency_events`, `status`
new/acknowledged/closed). Confirmed live: right now there's a genuinely
real, unaddressed `emergency_events` row (`status = 'new'`, triggered
16:47 today) sitting in the app, but the hero card shows the **fake
demo fallback content** ("นักเรียนหญิงหมดสติ...") because
`_activeSosIncident` is null (both real SOS-category incidents in
`incident_reports` are already resolved). The real panic-button event
only shows up as a small list item further down the page
("เหตุฉุกเฉินที่กำลังติดตาม" section), not in the urgent hero
treatment it should probably get.

**This is a design gap, not a mislabeling bug** — the "ข้อมูลจำลอง" badge
on the hero card is currently *technically correct* (there's no active
item in the specific data source it checks), just misleading in
practice because a real active emergency exists elsewhere on the same
page. See [[aiot-school-lab-badge-mislabel-bug]] for the actual
mislabeling bug fixed earlier the same day — don't reintroduce that
pattern while doing this fix (keep whatever content-vs-badge condition
this ends up using perfectly matched).

## What to do

Expand `_sosActiveCard()` (and its matching detail dialog, same file,
the `pageBuilder:` around line ~2914) to treat **either** an active
`_activeSosIncident` (existing) **or** an active real emergency event
(`_realEmergencyEvents.where((e) => e.status == 'new' || e.status ==
'acknowledged').firstOrNull` — new getter, same pattern as
`_activeSosIncident`) as "there's a real active emergency to show."

Open questions to resolve while implementing (not decided by the user
yet, use judgment or ask):
- If both an active SOS incident and an active emergency event exist
  simultaneously, which wins the hero card slot? (Suggest: SOS from a
  student always takes priority — it has a known human reporter — but
  confirm this is a reasonable default, don't just guess silently if it
  materially changes what's shown.)
- The accept/resolve buttons in the hero card and dialog currently call
  `IncidentService.acknowledgeIncidentReport(inc.id)` /
  `IncidentService.closeIncidentReport(inc.id, resolutionType:
  ..., resolutionNote: ...)` (lines ~3439, ~3490). When the active item
  is an `emergency_events` row instead, these need to branch to
  `EmergencyService.acknowledgeEmergencyEvent(eventId)` /
  `EmergencyService.closeEmergencyEvent(eventId: ..., reviewNote: ...)`
  instead (`packages/shared_core/lib/services/emergency_service.dart`,
  already exists, already used elsewhere in this same page for the
  lower list — reuse it, don't reinvent).
- `EmergencyEventItem` (`packages/shared_core/lib/models/emergency_event_model.dart`)
  has `location`, `deviceName`, `triggeredAt`, `warningLightOn` —
  different field names from `TeacherIncidentReport` (`room`,
  `reporterName`, `createdAt`, `reason`) — the hero card's title/
  location/reporter/time/narrative fields (lines ~1151–1192) will need
  a second real-content branch for this case (an emergency event has no
  human "reporter," it's device-triggered — word it honestly, don't
  invent a fake reporter name for a device trigger).

## Verification bar

Same as every other closed brief in `WORK_LOG.md`: `flutter analyze`
clean, then live-verify against the actual currently-open
`emergency_events` row mentioned above (or a fresh test one) — confirm
the hero card shows it as real (correct badge), and that
acknowledge/close on it actually updates the real `emergency_events` row
in the database, not a no-op. Clean up any test data created during
verification.

## Teacher-side specifics (`teacher_incident_inbox_page.dart`)

Unlike the director page, this file already has an
`_activeRealEmergencyEvent` getter (line ~131, same pattern as
`_activeSosIncident`) — but it's wired inconsistently, not simply
missing:

- **Hero card content** (`hasActiveReal = activeIncident != null` around
  line 785, `activeIncident = _activeSosIncident`) — same gap as
  director: never checks `_activeRealEmergencyEvent`, so a real active
  hardware SOS never gets the hero treatment, same fix needed.
- **`_acceptSos()`** (line ~311, the accept button's handler) — only
  handles `_activeSosIncident`. If it's null (meaning the only real
  active thing is a hardware event), it silently does `setState(() =>
  sosAccepted = true)` and shows a **fake success snackbar**
  ("🚨 รับแจ้งเหตุและกำลังดำเนินการ") **without calling any real backend
  acknowledge for the emergency event** — no
  `EmergencyService.acknowledgeEmergencyEvent(...)` call exists
  anywhere in this file at all. This is worse than doing nothing: it
  tells the teacher they've acknowledged a real emergency when they
  haven't touched the database.
- **Close button** (line ~1186–1212, inside the hero/detail area) — by
  contrast, this one is already correctly wired: branches on
  `_activeSosIncident` vs `_activeRealEmergencyEvent` and calls
  `IncidentService.closeIncidentReport` or
  `EmergencyService.closeEmergencyEvent` appropriately. Reuse this exact
  branching pattern for the accept button and for the hero card's
  content logic — don't reinvent it, just extend the same idea to the
  two places that are missing it.
- **Lower list tap-through** (`_openDetail`, line ~290) — tapping a
  hardware-event list item (one with no `originalIncident`) just shows
  `'เป็นเหตุจาก Hardware SOS กรุณาใช้อุปกรณ์จัดการ'` ("this is a Hardware
  SOS, please use the device to manage it") and does nothing else — a
  dead end that tells the teacher to go physically find the device
  instead of letting them acknowledge/close it from the app, even
  though the close button elsewhere in this same file proves that's
  possible. Decide whether this dead-end message should become a real
  action too (probably yes, for consistency — a teacher shouldn't need
  to physically locate a panic-button device just to acknowledge it),
  or leave it and make sure the messaging isn't reachable via a path
  that already has a working alternative once the other fixes land.

## Update on completion

Move this brief from "In progress" to "Done" in `WORK_LOG.md` with the
closing commit hash, per `CLAUDE.md`'s "Keeping this current" rule.
