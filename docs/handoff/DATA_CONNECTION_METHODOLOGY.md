# Methodology: auditing and wiring real backend data in this app

Written for agy (or any future session working on this codebase),
distilled from a long real audit-and-fix session on 2026-08-31. This is
*how to think*, not a one-off task — read this before doing "connect X
to the database" or "audit page Y for fake data" work. Pairs with the
hard rules already in `CLAUDE.md` (custom session auth, RLS deny-all,
SECURITY DEFINER RPCs) — this file is about *process*, that one is
about *architecture*.

## 1. Know what "real" looks like here before judging anything

Every genuinely-connected page follows the same shape:

```
Page (StatefulWidget)
  → calls a method on a class in packages/shared_core/lib/services/*.dart
    → that method calls supabase.rpc('some_function', params: {'p_token': token, ...})
      → the RPC is a real function in supabase/migrations/*.sql
        → SECURITY DEFINER, starts with `select * into v_actor from get_session_actor(p_token)`
        → checks v_actor.role against an allowlist
        → reads/writes real tables, scoped by v_actor.school_id / v_actor.user_id
```

If any link in that chain is missing, the page is not really connected,
no matter how real the UI looks. A page calling a service method that's
just `return const [...]` (hardcoded), or a page never calling any
service at all, is 100% fake regardless of polish.

## 2. Auditing a page for fake vs. real — the actual search

- `grep -n "Service\.\|\.rpc(\|await \|StreamBuilder\|FutureBuilder\|supabase\." <file>`
  — **zero matches across the whole build method tree = 100% fake**,
  no exceptions. This is the fastest first signal.
- Read the **whole file**, not an excerpt. A 2,000+ line page can be
  wired for real in one section and 100% hardcoded in the very next
  widget — excerpts miss this (found repeatedly this session:
  `director_learning_page.dart` was 100% fake end to end;
  `director_overview_page.dart` was real in most places but had one
  hardcoded fallback list buried deep in an unrelated card).
- Look specifically for these fake-data smells:
  - `const someList = [ {...}, {...} ]` sitting directly in a `build()`
    or a `Widget _xxx()` method — a real list comes from a service call
    in `initState`/a `StreamBuilder`, never a `const` literal of
    business data.
  - `realValue ?? 'plausible-looking fake default'` or
    `hasRealData ? realValue : 'fake fallback'` — check whether the
    fake branch is honestly disclosed (see §5) or silently
    indistinguishable from real.
  - A button `onPressed` that only does `setState(...)` +
    `ScaffoldMessenger.showSnackBar(...)` with **no `await SomeService.x()`
    before it** — a fake-success action.
  - A field on a model defaulting an *absent* value to `0`/`''` instead
    of `null` — indistinguishable from a real zero/empty reading unless
    the caller separately checks presence (this project's `SensorModel`
    has exactly this shape: check `metricUpdatedAt.containsKey(metric)`
    before trusting `sensor.pm25` etc., never trust the number alone).

## 3. Wiring something new — trace the real path end to end before writing UI code

1. Does the RPC already exist? Grep
   `supabase/migrations/*.sql` for the function name. If multiple
   migrations `create or replace` the same function, **the latest file
   (by filename timestamp) is live** — read that one, not an earlier
   version, and check no later migration redefines it again.
2. If it doesn't exist, write it following the exact shape in §1:
   `get_session_actor(p_token)`, role check, table access scoped by
   actor's school/user id, `insert into audit_logs (...)` for anything
   that mutates state (every existing write RPC in this codebase does
   this — match the pattern).
3. Add a method to the matching `packages/shared_core/lib/services/*.dart`
   class. Never call `supabase.rpc(...)` directly from a page widget.
4. Wire the page: real loading state, real empty state, real error
   state (`catchError` returning an empty/null value + `debugPrint`,
   matching the pattern already used everywhere in this codebase — see
   `director_emergency_page.dart`'s `_loadRealData()` for a clean
   example). No fake fallback numbers standing in for "loading" or
   "error."

## 4. Never trust a "done"/"fixed"/"connected" claim without re-checking it yourself

This includes claims from a previous turn of your own conversation,
from a commit message, from another agent's summary, or from
`WORK_LOG.md` before it's been independently spot-checked. Concrete
proof this matters, same session: agy reported a badge-mislabeling bug
already fixed — it hadn't been (`grep` for the specific variable name
still showed the old, wrong condition; `flutter analyze` still flagged
the helper meant to fix it as `unused_element`). The claim was phrased
confidently and specifically, and was still wrong.

**How to actually verify:**
- Re-read the specific lines the claim is about — don't skim, grep the
  exact variable/function name mentioned and read what it's doing now.
- `git log --oneline -1 <commit hash>` + `git show --stat <hash>` if a
  commit is cited — confirm it exists and touches the files claimed.
- For backend logic specifically: don't just read the SQL and assume
  it's correct. **PL/pgSQL does not validate a function body at
  `CREATE OR REPLACE FUNCTION` time** — a function can sit broken in
  production for weeks if the exact code path inside it was never
  actually executed (found this session: `create_parent_binding_code`
  had a genuine "column reference is ambiguous" error that had
  apparently never been hit before, because nobody had ever really
  exercised that RPC). The only way to know a function truly works is
  to actually call it.

## 5. Live-verify backend changes against production directly

This project has no separate staging database — verification happens
against the real linked Supabase project
(`npx supabase db query --linked --project-ref smqoknnftgjyhrnzugar --file <path>`).
That's normal and expected here, but it means discipline matters:

- **Prefer routing test data through the real RPCs/flows**, not
  hand-crafted `INSERT`s — this exercises the actual code path (catches
  bugs like the ambiguous-column one above) and respects every real
  constraint/trigger you might not know about. To get a session token
  for a role that requires 2FA (`school_admin`/`super_admin`/
  `executive`/`teacher` all do — see `auth_sign_in`'s `mfa_required`
  path), call `auth_sign_in(...)` to get `otp_token`/`otp_code` back
  directly in the response row (no real email is sent in this setup),
  then `auth_verify_login_otp(otp_token, otp_code, false)` for a real
  `session_token`. Chain further RPC calls with that token exactly like
  the app would.
- **Always clean up test data you created** — `delete from <table>
  where <the specific test marker you used>` — right after confirming
  the result, in the same sitting. Don't leave test rows for someone
  else to trip over later (this session repeatedly used a distinctive
  `reason = 'migration verification test...'` marker specifically so
  cleanup could target only what was just created).
- **Every schema migration gets recorded** after applying:
  `insert into supabase_migrations.schema_migrations (version, name)
  values ('<timestamp>', '<name>') on conflict (version) do nothing;`
  — matching the migration file's own name. Skipping this desyncs the
  migration history from what's actually live.

## 6. `flutter analyze` / `flutter build web` are necessary, not sufficient

Confirmed multiple times this session that both can report **completely
clean** while a file has:
- A broken import inside `packages/shared_core` (only `flutter build
  web` catches this reliably, not `analyze`).
- A duplicated closing brace that silently orphans every method after
  it in a class (neither `analyze` nor `build web` caught this once —
  only `flutter run`'s dev-server compile did).
- Stale/inconsistent results across repeated `analyze` runs on the same
  unchanged file — don't trust a single "no issues found," especially
  after several edits to a large file; re-run once more, and run it
  project-wide (not just the one file) before calling something done.
- **Runtime-only bugs are invisible to both tools entirely** — layout
  exceptions (see §7) and logic bugs (a badge showing the wrong
  real/demo state, a stream silently reconnecting every 5 seconds) only
  show up by actually reading the logic carefully or by a live
  click-through. Don't report something as "verified" off `flutter
  analyze` alone if the bug class is a runtime one.

For anything nontrivial (large file, edited blind, first time touching
a pre-existing file this session), also do a manual brace-balance sanity
check — a small Python script that walks the file character-by-character
tracking `{`/`}` depth while skipping string literals and comments — as
a cheap extra safety net independent of the Dart toolchain's own cache
behavior.

## 7. Known Flutter layout crash patterns specific to this app — check before adding new UI

Both confirmed live this session, both invisible to `flutter analyze`:

- **`ElevatedButton`/`ElevatedButton.icon` without
  `minimumSize: Size.zero`** — the app's global theme sets
  `minimumSize: Size(double.infinity, ...)`. Any such button placed
  where its parent doesn't give it a bounded width (`Row`/`Wrap`
  without `Expanded`, or `Align`) crashes with
  `BoxConstraints(unconstrained)`/"Cannot hit test a render box with no
  size." Grep `ElevatedButton(` **and** `ElevatedButton.icon(` in a file
  and diff the count against `minimumSize: Size.zero` — they should
  match exactly. Add it defensively every time, even if the button
  looks safely placed today.
- **`Row(crossAxisAlignment: CrossAxisAlignment.stretch)` without an
  `IntrinsicHeight` wrapper** — crashes with "BoxConstraints forces an
  infinite height" the moment that Row ends up somewhere with unbounded
  incoming height (e.g. a card widget that's sometimes invoked with no
  explicit `height:` argument, inside a scrollable ancestor). Wrap it in
  `IntrinsicHeight(child: Row(...))` any time `.stretch` is used this
  way — this project already has an established, working example of
  this exact fix with a comment explaining why, worth grepping for and
  matching the pattern rather than re-deriving it.
- **`RealtimeService.sensorStream(...)` / `.rawReadingsStream()` called
  inline as a `StreamBuilder`'s `stream:` argument**, especially nested
  inside another polling `StreamBuilder` — creates a brand-new
  underlying stream object on every rebuild, so the inner
  `StreamBuilder` never settles long enough to show real data. Always
  cache these in `late final` fields assigned once in `initState()`.

## 8. Honest labeling discipline — the "real vs. demo" badge rule

Multiple pages in this app show a small "ฐานข้อมูลจริง" (real data) or
"ข้อมูลจำลอง" (simulated data) badge next to content that toggles
between real and a hardcoded fallback. **The badge's condition and the
content's condition must be the literal same boolean/variable** — not
two different flags that merely happen to agree most of the time.
Confirmed twice this session that they silently diverge: a broad
"does any real data exist anywhere" flag (true forever once any real
row has ever existed) paired with narrow "is there something active
*right now*" content logic will eventually show fake content proudly
labeled as real, the moment the real thing resolves/closes/expires.
When adding a real/demo toggle anywhere, write the condition once as a
named local, and reuse that exact same name for both the badge and the
content — never restate an equivalent-looking condition in two places.

## 9. When you're done

Per `CLAUDE.md`'s "Keeping this current" section (not optional): update
`WORK_LOG.md` (move the brief from "In progress" to "Done" with the
closing commit hash) and `HANDOFF.md` if what's true about the project
materially changed. A fix that isn't reflected in these docs might as
well not have happened, from the next session's point of view.
