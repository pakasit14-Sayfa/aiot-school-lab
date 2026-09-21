# Sensor latest recovery — 2026-09-21

Live investigation found `sensor_latest` was the largest cumulative execution-time
consumer: 137,200 calls averaging 562.8 ms since August 27. This is historical
elapsed time, not a CPU profile or proof of the sole cause of the outage. Recent
cron runs took 5–36 ms; no blocked query was present in the inspected snapshot.
The database had restarted at 08:15:59 UTC; API recovery preceded our deployment.

## Database change

Migration `20260921090000` keeps the RPC signature, role checks, school boundary,
ordering and missing-reading behavior. It probes the existing primary key
`(device_id, metric, ts)` backwards for each device/enum metric with `LIMIT 1`.
No indexes, RLS policies, grants or business rows are changed.

Read-only measurements on the same live dataset (5 devices, 150,465 readings):

| Query | Execution time | Result rows | Temporary blocks written |
| --- | ---: | ---: | ---: |
| Old DISTINCT ON scan/sort | 1,302.465 ms | 10 | 1,468 |
| Indexed latest-row probes | 13.465 ms | 10 | 0 |

These are individual EXPLAIN ANALYZE samples, not a sustained load benchmark.
Tests 57, 69 and new 71 passed all 31 pgTAP assertions with candidate DDL and
fixtures rolled back. New tests compare exact results against the old query and
cover all six allowed roles, device filters, empty devices, cross-school access,
invalid sessions and expiration.

The targeted migration was applied to the linked database in one transaction
with its migration ledger entry, a 5-second lock timeout, a 15-second statement
timeout and an old-definition hash guard. No unrelated migrations were pushed.
Five authenticated student `sensor_latest` HTTP requests afterwards returned
10 rows each in 150–182 ms including network time; login/session validation and
sign-out also succeeded. This does not establish long-term system stability.

## Client polling cleanup

Previously each raw/model stream started its own infinite async generator;
`asBroadcastStream()` left the source running after the last listener departed.
The replacement shares one broadcast poller, waits for each fetch to finish,
and cancels its timer after the last listener or on app backgrounding. Pending
responses from a previous listener generation or auth token are discarded.
One-shot AIoT reads share an in-flight request for the same session token.

Sensor stream builders detach on covered routes and disabled TickerMode scopes.
Both student navigation IndexedStacks now disable TickerMode for hidden tabs.
Single-subscription injected streams use a paused/resumed adapter and are
cancelled on disposal; production broadcast streams detach completely.

The client change must be included in a newly built/reloaded app to take effect;
old running clients still use their original polling implementation. This change
does not interrupt an HTTP request already executing when the app is hidden.

Validation on the isolated branch based on `bfce8da`:

- shared_core: 70 passed (baseline 66), analyzer clean.
- shared_ui: 16 passed / 1 failed, same existing ListTile assertion as baseline;
  analyzer retains its 4 existing infos.
- user_app: 921 passed / 8 failed (baseline 919 / 8). The same eight screenshot
  tests depend on a missing macOS absolute output directory on Windows. Analyzer
  has 188 existing warnings/infos and zero errors.
- Four new polling tests and two visibility widget tests pass; existing executive
  dialog/re-entry tests also pass after adapting one-shot injected streams.
- Release web build passed. Browser interaction could not be verified.
- A later authenticated sensor API check still returned 10 rows in 166 ms.

## Remaining scope

Browser click verification is unavailable in this Codex session (no connected
browser). Sustained monitoring is still needed. School creation is
pending normal Super Admin MFA: the test admin login returns `mfa_required` and
does not expose a development OTP. Never obtain OTPs or sessions from database
tables to bypass that boundary.
