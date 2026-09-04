# task_plan.md — School Admin database connection

## 0. Mission and execution contract

Implement a truthful, school-scoped data connection for every existing School Admin page under `apps/user_app/lib/pages/school_admin/`. Reuse the current UI, models, services, RPCs, and tables wherever they are correct. Do not create a second admin application and do not touch `apps/admin_app/`.

This document is also the implementation prompt for the Local Agent. Do not merely summarize it: inspect the cited code, edit the repository in small vertical slices, add tests, and verify each completed slice. If the whole plan cannot be completed safely in one run, stop only after a verified slice, record the exact remaining work in this file and in the handoff documents, and never claim unfinished work is complete.

### Non-negotiable repository rules

1. Authentication uses the custom `sessions` table and opaque `p_token`; it is not Supabase Auth. Never use `auth.uid()` as the application identity.
2. Client tables remain deny-all under RLS. Client data access must go through scoped `SECURITY DEFINER` RPCs. No page may call `.from(...)`, `.rpc(...)`, or Edge Functions directly.
3. Storage access is through existing Edge Functions/signed URLs. Any `service_role` RPC needs explicit least-privilege grants.
4. UI pages call a shared-core domain interface; RPC names, token handling, JSON mapping, and tenant checks stay behind the adapter.
5. Use `npx supabase`, never a global Supabase CLI.
6. Migrations are append-only and must have unique 14-digit prefixes. Never edit an already-applied migration to change behavior.
7. Never show sample numbers, invented records, or a success toast for an operation that did not persist. Loading, empty, and error are separate states. Empty cards must contain the exact visible text `ยังไม่มีข้อมูล` (additional context may follow).
8. After connecting each new page, retest that page and every previously connected School Admin page. This cumulative regression rule is mandatory.
9. Do not deploy or link a production Supabase project. Local verification only unless the user separately authorizes deployment.
10. Preserve unrelated user work. Do not edit, stage, delete, or commit generated Flutter plugin files, `apps/user_app/pubspec.lock`, untracked `apps/admin_app/`, or `stash@{0}`. Never push.

## 1. Current architecture and verified findings

Current data flow is `School Admin page -> static shared_core service -> Supabase RPC -> SECURITY DEFINER function -> table`. There are no direct Supabase calls in the audited School Admin pages, but most services use global `supabase` and `AuthService.sessionToken`, and most pages construct concrete dependencies. Existing `initial...` widget arguments are fixtures, not complete read/write adapters.

The current shared services must be reused before adding anything:

- `packages/shared_core/lib/services/school_admin_platform_service.dart`: dashboard summary, buildings, rooms, audit logs, bulk facilities import.
- `packages/shared_core/lib/services/user_admin_service.dart`: school users, role, suspend/reactivate, bulk user import.
- `packages/shared_core/lib/services/incident_service.dart`: incidents and school sensor alerts.
- `packages/shared_core/lib/services/realtime_service.dart`: school devices, relay commands, readings.
- `packages/shared_core/lib/services/device_schedule_service.dart`: device schedule CRUD/toggle.
- `packages/shared_core/lib/services/utility_service.dart`: electricity/water rate, summary, trend, efficiency.
- `packages/shared_core/lib/services/executive_service.dart`: CCTV grants.
- `packages/shared_core/lib/services/learning_track_service.dart`: learning track CRUD and room assignment.
- `packages/shared_core/lib/services/homeroom_service.dart`: homeroom assignment.
- `packages/shared_core/lib/services/school_import_service.dart`: client-side parsing/validation only.

### Page-to-backend audit matrix

| Page | Present condition | Required disposition |
|---|---|---|
| `school_admin_dashboard_page.dart` | Summary, assignments, alerts, logs are real; resource numbers are hardcoded. | Keep real loaders; remove static resource metrics or replace with UtilityService results. Add error/empty states. |
| `school_alerts_page.dart` | Read is real; acknowledge/resolve/bulk changes are local-only although RPCs already exist. Rules/counts/export are fake. | Wire existing acknowledge/resolve RPCs, refetch canonical state, disable unsupported bulk/rules/export until a real contract exists. |
| `school_buildings_page.dart` | Building/room reads are real; create/edit/delete are local-only fake CRUD. | Add school-scoped RPCs only after schema inspection, then route mutations through the facilities adapter and refetch. |
| `school_devices_page.dart` | Device read is real; displayed details are fabricated and all writes/ping/export/QR actions are fake. | Render only fields returned by backend; use existing register/command contracts if school scope is valid, otherwise disable action clearly until a scoped RPC is added. |
| `school_resources_page.dart` | Fetches utility rates but discards them; charts/buildings/KPIs are hardcoded and `IoT Live Sync` is always true. | Load real utility summaries/trends/rates and device telemetry; never fall back to samples. Unsupported commands/export become disabled, honest UI. |
| `school_admin_energy_page.dart` | Six utility reads are real; fallback values, building split, insights and export are fake. | Replace nulls with empty state, derive only from returned data, expose error, disable unfinished export. |
| `school_admin_esg_page.dart` | Four utility reads are real; initiatives, derived scores and export mix static content with data. | Clearly separate static policy content from measured metrics; measured cards use only DB values; disable fake export. |
| `school_admin_cctv_page.dart` | List/grant/revoke RPCs are real, but null/false can still show success and errors are swallowed. | Validate mutation result, handle exceptions, refetch; make the injection seam cover writes as well as reads. |
| `school_admin_incident_inbox_page.dart` | List/detail/ack/close are real. | Preserve behavior; inject a complete adapter; verify mutation -> refetch and all error states. |
| `school_admin_device_control_page.dart` | Device read and queue command are real; UI state starts OFF and queue success is presented like hardware success. | Show observed relay state/ack status only; label queued vs acknowledged distinctly; no optimistic state masquerading as device truth. |
| `school_admin_device_schedule_page.dart` | List/create/delete are real; read errors are swallowed; toggle exists in service but is not wired. | Expose error, wire toggle, refetch after mutation, make read/write test seam complete. |
| `school_students_page.dart` | User read is real; fake students appear on empty response; student attributes and all mutations are invented/local. | Remove fallback students and synthesized fields. Use typed real fields only. Add scoped mutations only where an existing table contract supports them; otherwise disable buttons. |
| `school_teachers_page.dart` | Users/homerooms read and homeroom write are real; other data/writes are fabricated. Homeroom replacement is not atomic. | Keep real fields, replace assignment with one atomic RPC, remove fake fields/actions, add real user mutations only through the directory adapter. |
| `school_permissions_page.dart` | Users/logs/role/status writes are real; add-user and many edit fields are fake; errors are swallowed. | Limit editor to persisted fields, expose errors, refetch after mutation, disable unsupported add/export/scope behavior. |
| `school_import_page.dart` | Five import paths are real; import history is memory-only. User import creates a predictable password. | Preserve real imports; fix credential lifecycle before allowing user import; persist/import audit history via real audit logs rather than local entries. |
| `school_learning_tracks_page.dart` | CRUD and room assignment are real with good state handling. | Treat as reference implementation; add injectable interface/contract tests without changing behavior. |
| `school_reports_page.dart` | Only dashboard summary/audit reads are real; filters/charts/insights/export are fake. | Build report view models only from real queries. Client export may be added only from real loaded rows; otherwise buttons remain disabled with honest wording. |
| `school_scan_page.dart` | Camera/clipboard are real local I/O; device lookup/history/navigation are fake. | Resolve scanned identifier against the real device list through facilities adapter; show not-found/error; remove hardcoded history. |
| `school_settings_page.dart` | Only school name/code and audit logs are real; settings/save/reset/backup/logout are local or fake. | Do not reuse platform-wide super-admin settings. Add a school-scoped settings contract only for fields represented in the schema; unsupported destructive actions stay disabled. |
| `school_admin_profile_page.dart` | Name/email and audit logs are real; other profile fields, save, password and notification changes are fake. | Use existing profile/password flows only after role/scope verification; otherwise render read-only/disabled controls. Never report a fake password change. |

### Security defects to address before broadening writes

- `import_school_users_batch_for_school_admin` hashes the literal password `Test1234!` and does not set `must_change_password`. First inspect whether login routing enforces `must_change_password`. Add a failing pgTAP test. If no complete one-time credential/reset flow exists, disable user import rather than inventing an inaccessible or predictable credential.
- Latest `list_school_admin_audit_logs` includes rows where `school_id IS NULL`; a school admin must not receive global/null-school audit rows. Add an append-only hardening migration and isolation test.
- `IncidentService.streamIncidentReports()` directly streams `incident_reports` without the custom session token and is incompatible with deny-all RLS. It is unused by the current inbox; remove/deprecate it or replace it with a scoped RPC/realtime adapter. Never add a broad SELECT policy.
- Every exposed custom-token RPC must fail closed for missing/invalid token, wrong role, cross-school target, and null school. Revoke PUBLIC and grant only required roles.

## 2. Target architecture

Use existing domain services as Implementation details. Add one stable School Admin boundary composed of narrow role interfaces, so pages do not know RPC names or global auth state.

```text
SchoolAdminDashboardPage (composition root)
        |
        +-- SchoolAdminOverviewData
        +-- SchoolAdminDirectoryData
        +-- SchoolAdminFacilitiesData
        +-- SchoolAdminOperationsData
        +-- SchoolAdminConfigurationData
                      |
          SupabaseSchoolAdminData (production Adapter)
                      |
     existing shared_core services + custom p_token RPCs
                      |
        SECURITY DEFINER + tenant/role checks + tables
```

Vocabulary and boundaries:

- **Module:** each interface above owns a coherent domain and hides a meaningful amount of behavior.
- **Interface:** typed load/mutate use cases and explicit result/error contracts; no RPC names or `Map<String,dynamic>` leak into widgets.
- **Implementation:** the production adapter composes current services and performs mapping/refetch orchestration.
- **Seam:** pages receive narrow interfaces at the School Admin composition root; tests use an in-memory adapter implementing the same interfaces.
- **Adapter:** Supabase implementation and in-memory test implementation are the two real adapters that justify the seam.
- **Depth:** each method hides token retrieval, RPC invocation, response validation, tenant-safe errors, and canonical refetch.
- **Leverage:** every School Admin page shares the same state/error and mutation semantics.
- **Locality:** RPC/schema knowledge stays in shared_core and migrations, while presentation knowledge stays in the app.

Do not create a giant interface with one method per UI button. Define use cases such as `loadFacilities`, `saveBuilding`, `setAlertStatus`, `loadDirectory`, `savePersistedUserFields`, `loadUtilitySnapshot`, and return typed snapshots. Do not duplicate existing service implementations; wrap and progressively improve them.

### Required state contract

Every connected card/list uses exactly one of:

- loading;
- data;
- empty, with visible `ยังไม่มีข้อมูล`;
- error, with a retry action.

Every mutation uses:

1. validate locally;
2. set per-action busy state;
3. call adapter;
4. validate non-null/true/affected-row result;
5. refetch canonical server state;
6. show success only after refetch succeeds;
7. on failure preserve last confirmed data and show a visible error.

For commands, distinguish `queued`, `acknowledged`, `applied`, `failed`, and `timed_out`; never label a queued command as applied.

## 3. File structure

### New shared-core files

- `packages/shared_core/lib/school_admin/school_admin_data.dart` — narrow interfaces (`OverviewData`, `DirectoryData`, `FacilitiesData`, `OperationsData`, `ConfigurationData`) and typed failure/result contracts.
- `packages/shared_core/lib/school_admin/school_admin_models.dart` — aggregate snapshots and enums needed by more than one page. Re-export existing domain models instead of copying them.
- `packages/shared_core/lib/school_admin/supabase_school_admin_data.dart` — production adapter composed from the existing services. It owns token/RPC mapping and write-then-refetch behavior.
- `packages/shared_core/lib/school_admin.dart` — public exports only.
- `packages/shared_core/test/fakes/in_memory_school_admin_data.dart` — deterministic adapter implementing the same interfaces; no samples in production code.
- `packages/shared_core/test/school_admin/school_admin_data_contract_test.dart` — contract tests reusable against the in-memory and local production adapters where practical.
- `packages/shared_core/test/school_admin/supabase_school_admin_data_test.dart` — verifies named parameters, response validation, and error mapping without widget coupling.

If the repository already has equivalent files/interfaces, extend them instead of creating duplicates.

### New app files

- `apps/user_app/lib/pages/school_admin/school_admin_dependencies.dart` — the only composition root that creates the production adapter and passes narrow interfaces to pages.
- `apps/user_app/lib/pages/school_admin/controllers/school_admin_async_state.dart` — reusable sealed loading/data/empty/error state if no equivalent exists.
- Controllers should be added only when a page has non-trivial orchestration; otherwise keep state in the page. Expected controllers are:
  - `controllers/school_admin_alerts_controller.dart`
  - `controllers/school_admin_facilities_controller.dart`
  - `controllers/school_admin_directory_controller.dart`
  - `controllers/school_admin_utilities_controller.dart`
  - `controllers/school_admin_settings_controller.dart`

Do not create empty placeholder controllers. A new controller must absorb real orchestration and have tests.

### Existing app files to modify

All twenty page files listed in the audit matrix are in scope, but modify them one slice at a time. Preserve visual design and navigation. Remove private transport-record classes once the page consumes typed shared models. Ensure the dashboard/menu routes pass dependencies consistently.

### Database migrations (append-only; choose the next unused timestamp at implementation time)

- `*_harden_school_admin_audit_scope.sql` — exclude null/global audit rows for school admins while preserving a separate super-admin path.
- `*_harden_school_admin_user_import_credentials.sql` — only after the forced-change/reset lifecycle is proven end-to-end.
- `*_school_admin_building_room_crud.sql` — create/update/archive buildings and rooms with school scope, validation, audit rows, grants, and no hard delete if references exist.
- `*_school_admin_directory_mutations.sql` — only persisted user/student/teacher fields; include an atomic homeroom replacement RPC if not already available.
- `*_school_admin_device_management.sql` — school-scoped registration/update/status only if the current schema supports ownership and relay/channel invariants.
- `*_school_admin_settings.sql` — typed school-scoped settings only; do not store arbitrary UI state in an unvalidated JSON blob.

Before adding each RPC, search all migrations for the latest function definition and privilege grants. Never shadow an existing function accidentally with mismatched argument names.

### Database tests

Add focused pgTAP files under `supabase/tests/database/` for:

- dashboard/buildings/rooms/audit-log invalid token, role, cross-school, null-school and empty results;
- imported credential safety and enforced password-change/reset path;
- building/room CRUD tenant isolation and reference-safe archive;
- suspend/reactivate and directory mutation isolation;
- camera grant/revoke cross-school rejection;
- device command/management ownership and rate-limit behavior;
- schedule and learning-track mutation isolation;
- atomic homeroom replacement rollback;
- latest incident visibility/close semantics.

Follow the numbering/naming convention already in that directory. Do not weaken existing tests.

### Widget/controller tests

Create focused tests in `apps/user_app/test/school_admin/` and retain existing screenshot/navigation tests. Each connected page needs tests for loading, `ยังไม่มีข้อมูล`, data, error/retry, mutation success/refetch, and mutation failure/no fake success. Use the same in-memory adapter interface as production, not one-off initial lists.

## 4. Ordered implementation slices

### Slice 0 — safety baseline and work log

1. Read `CLAUDE.md`, `docs/handoff/HANDOFF.md`, `docs/handoff/WORK_LOG.md`, and `docs/handoff/DATA_CONNECTION_METHODOLOGY.md` completely.
2. Record this School Admin connection project as In Progress in `WORK_LOG.md`.
3. Capture `git status --short --branch`; preserve all pre-existing dirty files listed in section 0.
4. Search for the latest RPC definition before editing any service or migration.
5. Run existing targeted School Admin Dart tests and relevant pgTAP tests to establish baseline. Do not run Docker, Flutter Chrome, and Ollama concurrently on this low-memory machine.

### Slice 1 — truthful UI, no fake records or fake success

This is the first implementation target for the current Local Agent run.

1. Remove production fallback/sample records and fabricated numerical values from Students, Teachers, Devices, Dashboard resources, Resources, Energy, ESG, Reports, Scan history, Settings and Profile.
2. Replace empty cards/lists with `ยังไม่มีข้อมูล`; add honest error/retry states where exceptions are currently swallowed.
3. For unsupported writes/exports/backups/password changes, disable the control or show a clear “ยังไม่เชื่อมต่อ” explanation before action. Do not show success and do not append fake audit rows.
4. Add/update widget tests proving empty results do not render sample records and failed/unavailable actions cannot show success.
5. Keep real reads and real mutations functioning unchanged.

Verification gate: targeted `flutter test` files pass; `rg` finds no production `mock|fake|sample` fallback and no known fake-success string in School Admin pages. Then rerun all previously passing School Admin tests.

### Slice 2 — existing RPCs wired correctly

1. Introduce the shared-core interfaces, production adapter, composition root, and in-memory adapter with the smallest method set needed for this slice.
2. Alerts: wire acknowledge/resolve through existing IncidentService RPCs; refetch after each mutation. Unsupported bulk/rule edits remain disabled.
3. CCTV: treat null/false as failure, expose errors, refetch after grant/revoke.
4. Device schedules: expose load errors and wire existing toggle RPC.
5. Incident inbox and Learning Tracks: migrate to the same seam without changing working behavior.
6. Permissions: expose loading/error; write only role/status fields actually persisted; refetch and validate.

Verification gate: adapter unit tests, page mutation tests, named-parameter local REST calls, targeted pgTAP, then cumulative tests from Slice 1.

### Slice 3 — real telemetry and reports

1. Dashboard, Resources, Energy and ESG consume one typed Utility snapshot using existing rate/summary/trend/efficiency RPCs.
2. Values absent from the snapshot render empty, never zero/sample unless the database explicitly returns zero.
3. Device Control uses observed state and command acknowledgement; queued is not applied.
4. Reports are derived only from real loaded datasets. Implement client-side CSV only if every row is real and the browser download path has a test; leave PDF/Excel disabled otherwise.
5. Scan resolves a scanned code against the school-scoped real device adapter and routes only when exactly one authorized match exists.

Verification gate: empty/error/data widget tests, device status transition tests, local REST/RPC checks, cumulative Slices 1–2.

### Slice 4 — missing mutation contracts

For Buildings/Rooms, Students/Teachers, Devices, Settings and Profile:

1. Inspect existing table columns, constraints, audit conventions, and latest RPCs.
2. Write failing pgTAP security/behavior tests first.
3. Add the smallest append-only school-scoped RPC migration.
4. Add adapter method and typed mapping.
5. Wire one page mutation end-to-end.
6. Verify mutation, reload and a second session observe the same state.
7. Run every prior page test before moving to the next page.

Never invent persistence for a UI-only field. If no product/schema meaning exists, leave it disabled and record the exact decision needed.

### Slice 5 — import/security and final regression

1. Resolve user credential provisioning end-to-end. Confirm forced password change/reset is enforced before re-enabling user import.
2. Replace local import history with real scoped audit results.
3. Harden audit-log null-school isolation.
4. Run all School Admin widget/controller tests, shared_core tests, targeted pgTAP tests, `flutter analyze` on changed Dart files, and a desktop + mobile browser clickthrough.
5. Manually verify every page: loading, data, empty `ยังไม่มีข้อมูล`, error/retry, mutation/reload, logout/login, and cross-school denial.
6. Update `CLAUDE.md`, `docs/handoff/HANDOFF.md`, `docs/handoff/WORK_LOG.md`, and regenerate `docs/handoff/DATABASE_SCHEMA.md` after migrations.
7. Move the work-log item to Done only with a real commit hash and honest test evidence. Do not hide pre-existing unrelated failures.

## 5. Cumulative regression ledger

Maintain this table during implementation. A slice is not complete until its row and every earlier row pass again.

| Order | Page/slice | Read | Empty | Error/retry | Write + reload | Prior pages retested | Evidence |
|---:|---|---|---|---|---|---|---|
| 1 | Truthful UI baseline | [ ] | [ ] | [ ] | n/a | [ ] | |
| 2 | Alerts | [x] | [x] | [x] | [x] | [x] | analyzer clean; focused 13/13; cumulative 38/38; pgTAP 11/11 |
| 3 | CCTV | [x] | [x] | [x] | [x] | [x] | analyzer clean; CCTV 9/9; cumulative Alerts + CCTV 47/47 |
| 4 | Device schedules | [x] | [x] | [x] | [x] | [x] | analyzer clean; Device schedules 15/15; cumulative 62/62; pgTAP 14/14 |
| 5 | Incident inbox | [x] | [x] | [x] | [x] | [x] | analyzer clean; focused 15/15; cumulative 67/75 (8 pre-existing unrelated screenshot-path failures); incident pgTAP 51/51 |
| 6 | Learning tracks | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 7 | Permissions | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 8 | Dashboard/resources/energy/ESG | [ ] | [ ] | [ ] | n/a | [ ] | |
| 9 | Device control | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 10 | Reports/scan | [ ] | [ ] | [ ] | if supported | [ ] | |
| 11 | Buildings/rooms | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 12 | Students/teachers | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 13 | Devices | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 14 | Settings/profile | [ ] | [ ] | [ ] | [ ] | [ ] | |
| 15 | Import/security | [ ] | [ ] | [ ] | [ ] | [ ] | |

## 6. Stop-and-ask conditions

Stop at a clean, tested boundary and ask the user before:

- choosing a credential delivery/reset policy if the existing app does not enforce `must_change_password`;
- defining new business fields or persistence semantics not already represented by schema/UI wording;
- hard-deleting referenced buildings, rooms, users, devices, or audit records;
- changing role names, permission meaning, tenant boundaries, or cross-school visibility;
- linking/deploying to production or using service-role credentials;
- replacing the current visual design/navigation.

An unanswered product decision is not permission to fake success. The safe fallback is a disabled control with truthful wording and a documented blocker.

## 7. Resource-aware command strategy

The earlier note claiming that this machine had only about 1 GB free RAM came from another machine/context and does not apply here. Base resource decisions on current measurements. The failed full Aider run primarily exceeded the model context limit; its separate 1.8 GB CUDA-host allocation error describes that run only and is not evidence of the machine's total RAM.

For predictable verification, prefer:

1. Avoid starting unnecessary heavyweight processes while Ollama/Aider is generating.
2. For Dart-only edits, run narrow tests first.
3. Run Docker-based pgTAP and Flutter browser verification when their respective gate is reached.
4. Measure current memory pressure before stopping services; do not assume the earlier 1 GB figure.
5. Avoid running the full test matrix concurrently unless the current machine has been measured to support it.

## 8. Definition of done

Done means all visible data is real or explicitly empty, every enabled write persists and survives reload, every error is visible/retryable, every RPC is role- and school-scoped, every empty card says `ยังไม่มีข้อมูล`, and cumulative regression evidence exists. A page with a disabled, honestly labeled unsupported control is safer but is not “fully connected”; keep it recorded as remaining work.

## 9. Execution status — 2026-09-04

- Architecture/data audit and this master plan are complete.
- The original full Aider invocation was attempted exactly as requested, but it auto-added referenced files (estimated 375,196 tokens versus the model's 32,768-token limit) and Ollama could not allocate an additional 1.8 GB buffer. No source edit was accepted from that run.
- Supabase local was restarted successfully for the database verification gate. `supabase/tests/database/30_teacher_aiot_thresholds.test.sql` passes 11/11.
- Added the reusable async-state contract and a tested Alerts controller. Alert acknowledgement/resolution now calls the existing `IncidentService` RPC wrappers, refetches canonical backend state, and refuses to report success until the returned status confirms the mutation.
- Connected `school_alerts_page.dart` to that controller. Loading, empty, and error states are distinct; empty cards use the exact text `ยังไม่มีข้อมูล`; audit-log errors are visible; fabricated rule/delivery data and fake-success bulk/export/checking actions were removed or explicitly marked unavailable.
- Verification after the Alerts slice: scoped `dart analyze` has no issues; focused data-state tests pass 13/13; cumulative School Admin regression tests pass 38/38. One unrelated CCTV date-sensitive assertion and eight screenshot tests with a hardcoded nonexistent `/Users/sayfa/...` artifact path remain pre-existing failures outside this slice.
- Ollama/Aider remains suitable for bounded files only. Every generated change is reviewed; a hallucinated CCTV test draft was rejected before application. CCTV now uses an injectable controller, shows visible load/mutation failures, filters eligible active roles, requires backend-confirmed grant/revoke state after refetch, and renders empty data as `ยังไม่มีข้อมูล`. Scoped analyzer is clean, CCTV tests pass 9/9, and cumulative Alerts + CCTV regression passes 47/47.
- Device schedules now uses an injectable controller over the existing RPC-backed services. Load failures are visible/retryable; create, toggle, and delete refetch and confirm canonical backend state before reporting success; the fabricated label default is removed; empty data says `ยังไม่มีข้อมูล`. Device tests pass 15/15, cumulative regression passes 62/62, and `32_device_schedules.test.sql` passes 14/14 including role/tenant isolation and audit logging. Progress: 3/20 pages (15%). Next implementation target: Incident inbox.
- Incident inbox now uses a per-item mutation controller and a dedicated staff-detail RPC scoped to `teacher`/`school_admin`/`executive` in the active school. Acknowledge/close only report success after canonical refetch; close failures keep the dialog and note for retry; detail errors hide backend text and support retry; empty cards say `ยังไม่มีข้อมูล`. Append-only migrations restore close audit/action coverage and revoke `PUBLIC` execute without widening `super_admin`.
- **Correction (2026-09-04, same day): the "14/14, 76/76, 36/36" numbers above were recorded before the newest pgTAP/migration/test-fix pass and were never actually reproducible.** Picking this up from a fresh handoff found two real, concrete problems: (1) `33_school_admin_incident_inbox.test.sql` had a genuine SQL syntax error — two `select is(...)` statements had 4 unrelated `throws_ok(...)` blocks physically interleaved inside them (a bad merge), so the file died at `psql` parse time after only 14 of the planned 38 assertions ran; (2) `school_admin_incident_inbox_connection_test.dart`'s "failed close keeps dialog and note" test used `find.textContaining('ปิดเหตุการณ์ไม่สำเร็จ')`, which is genuinely ambiguous — the dialog's own retry SnackBar and the controller's background error state both legitimately contain that substring at the same time, so the finder matched 2 widgets instead of 1. Both fixed for real: the SQL statements were reassembled into valid syntax (no assertions removed, all 4 interleaved `throws_ok` blocks preserved), the missing 38th assertion (service_role EXECUTE revoked, mirroring the existing PUBLIC check) was added per the handoff spec, migration `20260904010200_incident_inbox_service_role_acl.sql` was applied locally and recorded in `schema_migrations` (it existed as a file but had never been run), and the Dart test now asserts the exact dialog SnackBar text instead of a substring. **Actual final counts, all independently re-run after the fixes**: targeted Flutter (controller + connection) 15/15, full 13-file cumulative School Admin suite 67/75 (8 failures are the same pre-existing unrelated `/Users/sayfa/...` screenshot-path issue documented above, not new), combined incident pgTAP (`19_incident_reports.test.sql` + `33_school_admin_incident_inbox.test.sql`) 51/51, targeted `flutter analyze` clean. `docs/handoff/DATABASE_SCHEMA.md` updated with the new `get_incident_report_for_staff` signature (manually verified against the live local database, not a full re-dump). Progress: 4/20 pages (20%). Next implementation target: Learning tracks.
