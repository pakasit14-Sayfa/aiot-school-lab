# Brief for agy: match teacher's emergency/incident UI tone to the director's

User asked (2026-08-31) to bring the director's emergency page's visual
tone over to the teacher side. Not a data-wiring task — both sides
already call real, role-checked backend (see
[[aiot-school-lab-sos-broadcast-fix]] context: `list_incident_reports`,
`acknowledge_incident_report`, `assign_incident_report`,
`add_incident_action`, `escalate_incident_report`,
`close_incident_report`, `EmergencyService.listEmergencyEvents()`,
`IncidentService.getIncidentSummary()`,
`IncidentService.listTeacherIncidentReports()` are all already callable
by `teacher` — that part is done, migration
`20260831010000_sos_broadcast_to_all_staff.sql` also newly widened
`teacher`/`school_admin`/`executive` visibility for SOS-category
incidents specifically). This brief is pure UI/visual-design parity.

## Source of truth

`apps/user_app/lib/pages/executive_redesign_prototype/pages/director_emergency_page.dart`
(4,197 lines). Study its visual language:
- Urgency-based color coding (SOS vs regular incident, pending vs
  resolved) — see `AppPalette.danger`/`AppPalette.warning` usage plus
  the custom red/amber/green accent blocks around lines 78–344.
- Summary/stat header cards (pending SOS count badge, resolved count,
  refresh affordance) around lines 420–520.
- The card-based incident list with severity badges, acknowledge/close
  action buttons, status pills.

## Target files (teacher side, currently two separate pages)

- `apps/user_app/lib/pages/teacher_redesign_prototype/teacher_incident_inbox_page.dart`
  (1,289 lines)
- `apps/user_app/lib/pages/teacher_redesign_prototype/teacher_emergency_events_page.dart`
  (641 lines)

Both already use real data and `TeacherPalette` (not `AppPalette`) — keep
it that way. **Do not copy `AppPalette`'s literal hex values into the
teacher pages** — see [[aiot-school-lab-design-system-unification-plan]]:
role palettes are deliberately kept separate and not mixed. "Same tone"
here means matching the director page's *layout language* — card shapes,
spacing rhythm, urgency-color-coding pattern (map director's
danger/warning/success semantics onto `TeacherPalette`'s equivalent
danger/warning/muted tokens), summary-stat header treatment, badge/pill
styling, icon choices — not literally reusing `AppPalette` constants.

## Open questions to resolve before/while implementing (not decided by user yet)

- Whether to merge `teacher_incident_inbox_page.dart` +
  `teacher_emergency_events_page.dart` into one page (matching the
  director's single-page structure) or keep them as two pages just
  restyled — user did not specify, was leaning toward "keep teacher's
  existing pages, just restyle" in the conversation that led to this
  brief but didn't explicitly rule out a merge. Check with the user if
  genuinely ambiguous once you see how much restyling-in-place vs.
  merging actually simplifies the code.
- Confirm `flutter analyze` clean + a live click-through as
  `teacher@aiot-school-lab.local` (or an account with a real `teacher`
  `user_roles` row) before marking this done, same verification bar as
  every other closed brief in `WORK_LOG.md`.

## Update on completion

Move this brief from "In progress" to "Done" in `WORK_LOG.md` with the
closing commit hash, per `CLAUDE.md`'s "Keeping this current" rule.
