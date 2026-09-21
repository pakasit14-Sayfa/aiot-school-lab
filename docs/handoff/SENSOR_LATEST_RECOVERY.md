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

## Remaining scope

Client polling cleanup is a separate change. Browser click verification is
unavailable in this Codex session (no connected browser). School creation is
pending normal Super Admin MFA: the test admin login returns `mfa_required` and
does not expose a development OTP. Never obtain OTPs or sessions from database
tables to bypass that boundary.
