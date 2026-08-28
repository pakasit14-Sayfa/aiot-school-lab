# Sensor Gateway Integration Guide — for the hardware/firmware team

**⚠️ NOT LIVE IN PRODUCTION YET (as of 2026-08-28).** Production
(`smqoknnftgjyhrnzugar`) still runs the older `sensor_ingest` path —
see `docs/sensor-api.md`, that one is the currently-correct guide for
real hardware today. This document describes the newer HMAC-signed
scheme that exists in this repo's migrations and works against the
**local dev stack**, intended to eventually replace `sensor_ingest`
once a coordinated cutover (new firmware + migration deploy + Edge
Function deploy, all at once) is planned with the hardware team. Don't
point real production hardware at the endpoint below until that
migration is actually deployed — it doesn't exist in production yet,
so requests to it will fail outright, not fall back to anything.

This is the guide for connecting a real physical device (ESP32, Pico,
gateway board, etc.) to push sensor readings into AIoT School Lab via
the **new** scheme, once it's rolled out. It covers the intended
long-term ingest path, verified locally as of 2026-08-28.

No real hardware has been tested against this path yet, but the full
recipe below (registration → signature → POST → DB row → device goes
`online`, plus replay rejection) was verified end-to-end against the
local dev stack on 2026-08-28 using a plain Python script simulating a
device — not just read from source. If your firmware's request is
rejected, the bug is almost certainly in the firmware's signature
computation (see the HMAC key note below — it's the one detail that's
easy to get backwards), not in this doc or the backend.

## 1. Get a device token (one-time, done by a human)

A `school_admin`/`super_admin` registers the device from inside the app
(or a script using their session), which calls:

```
register_device(p_token, p_type, p_name, p_serial_no, p_location, p_kit_code)
  → { device_id: uuid, device_token: "dev_<48 hex chars>" }
```

`device_token` is shown **exactly once** — the server only ever stores
`sha256(device_token)` (as `devices.token_hash`). If it's lost, someone
with admin access must call `issue_device_token(p_token, p_device_id)`
to rotate it (the old token stops working immediately).

**The firmware needs two things out of this step:**
- `device_id` (a UUID) — this is what the request headers call the
  "gateway ID." One device = one gateway; there's no separate gateway
  concept to register.
- `device_token` — keep this secret on the device (e.g. in NVS/flash).
  It is never sent over the network directly.

## 2. Endpoint

```
POST https://<project-ref>.supabase.co/functions/v1/gateway-sensor-ingest
```

For the local dev stack: `http://127.0.0.1:54321/functions/v1/gateway-sensor-ingest`

No `Authorization` header, no Supabase anon key needed — this endpoint
has `verify_jwt = false` and authenticates purely via the signature
scheme below.

## 3. Required headers

| Header | Value |
|---|---|
| `x-gateway-id` | the device's `device_id` (UUID) |
| `x-timestamp` | current Unix time in **seconds** (integer) |
| `x-nonce` | a random string, 16–128 chars, only `A-Za-z0-9_-` |
| `x-gateway-signature` | see step 4 |

- `x-timestamp` must be within **300 seconds** of the server's clock, or
  the request is rejected (`gateway_timestamp_out_of_range`). Keep the
  device's clock reasonably accurate (NTP).
- `x-nonce` must be **unique per device, forever** (it's stored and
  checked against — reusing one is rejected as `gateway_replay_detected`).
  A monotonically increasing counter, or a random 22+ char string, both
  work. A UUID also works (36 chars, within the 16–128 range).

## 4. Computing the signature

The HMAC key is **not** the raw device token — it's
`sha256_hex(device_token)` (the same value stored server-side as
`devices.token_hash`). Compute this once on first boot and cache it;
don't recompute per-request if that's expensive on your hardware.

The signed message is 5 fields joined by `\n` (literal newline, not
`\r\n`):

```
METHOD + "\n" + PATH + "\n" + TIMESTAMP + "\n" + NONCE + "\n" + SHA256_HEX(RAW_BODY)
```

Where:
- `METHOD` = `POST` (uppercase)
- `PATH` = `/functions/v1/gateway-sensor-ingest` (exactly this string,
  regardless of the full host/URL you're posting to)
- `TIMESTAMP` = the same integer string sent in `x-timestamp`
- `NONCE` = the same string sent in `x-nonce`
- `SHA256_HEX(RAW_BODY)` = lowercase-hex SHA-256 of the **exact raw JSON
  bytes** you're about to send as the request body (compute the hash
  before adding any headers, on the literal bytes that go over the wire)

Then:

```
x-gateway-signature = HMAC_SHA256_HEX(message, key = sha256_hex(device_token))
```

Send `x-gateway-signature` as lowercase hex (64 chars).

### Worked example (Python, for bench-testing before writing firmware)

```python
import hashlib, hmac, json, time, uuid, requests

device_id = "11111111-2222-3333-4444-555555555555"  # from register_device
device_token = "dev_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"  # from register_device, shown once

hmac_key = hashlib.sha256(device_token.encode()).hexdigest()

body = json.dumps({
    "readings": [
        {"metric": "pm25", "value": 12.3},
        {"metric": "temperature", "value": 29.1},
    ]
})  # this exact string is what gets hashed AND what gets sent — don't re-serialize after hashing

body_hash = hashlib.sha256(body.encode()).hexdigest()
timestamp = str(int(time.time()))
nonce = uuid.uuid4().hex  # 32 chars, fine

message = "\n".join(["POST", "/functions/v1/gateway-sensor-ingest", timestamp, nonce, body_hash])
# HMAC key is the UTF-8 bytes of the hex STRING hmac_key, not hex-decoded
# to raw bytes — see the note below this example, this is the easy part
# to get wrong.
signature = hmac.new(hmac_key.encode(), message.encode(), hashlib.sha256).hexdigest()

resp = requests.post(
    "http://127.0.0.1:54321/functions/v1/gateway-sensor-ingest",
    headers={
        "x-gateway-id": device_id,
        "x-timestamp": timestamp,
        "x-nonce": nonce,
        "x-gateway-signature": signature,
        "Content-Type": "application/json",
    },
    data=body,
)
print(resp.status_code, resp.json())
```

**Important on the HMAC key encoding**: the server computes
`hmac(message, v_device.token_hash, 'sha256')` in Postgres, where
`token_hash` is a hex-encoded text column — Postgres's `hmac()` treats
this as the raw text bytes of the hex string, **not** as hex-decoded
binary. So your HMAC key must be the ASCII/UTF-8 bytes of the 64-character
hex string itself (i.e. `hmac_key.encode()` in the Python example above,
not `bytes.fromhex(hmac_key)`). Get this wrong and every signature will
mismatch with no other symptom.

## 5. Request body

```json
{
  "readings": [
    { "metric": "pm25", "value": 12.3 },
    { "metric": "temperature", "value": 29.1, "ts": "2026-08-28T10:15:00Z" }
  ]
}
```

- `metric` — one of: `pm25`, `aqi`, `temperature`, `humidity`,
  `light_lux`, `energy_kwh`, `power_w`. Anything else is rejected
  (`invalid_sensor_reading`).
- `value` — numeric, required.
- `ts` — optional ISO-8601 timestamp. If omitted, the server uses "now."
  Include it if you're batching up readings taken over the last few
  minutes (e.g. after a brief network outage) — don't fabricate a
  timestamp you don't actually have.
- Up to 500 readings per request (`batch_too_large` above that).
- Duplicate `(device_id, metric, ts)` triples are silently ignored
  (safe to retry a request if you're not sure it landed).

## 6. Response

- `200 { "inserted": <count> }` — success. `inserted` may be less than
  the number of readings you sent if some were duplicates (see above).
- `401 { "error": "invalid_gateway_request" }` — auth failed: bad
  device_id, timestamp out of range, malformed nonce, or (most likely
  during bring-up) a signature mismatch.
- `400 { "error": "invalid_payload" }` — body isn't valid JSON, or
  `readings` isn't an array, or a reading has a bad `metric`/`value`.

The response body does not currently distinguish *which* auth check
failed (all collapse to `invalid_gateway_request`) — check the Edge
Function logs server-side (`npx supabase functions logs gateway-sensor-ingest`
locally) for the specific Postgres exception if a device can't connect.

## 7. Side effects on success

Every successful request also sets `devices.status = 'online'` and
writes a `device_heartbeats` row for that device — so a device that's
actively posting readings will show as online in the app without any
separate heartbeat mechanism. If a device goes quiet, it'll fall out of
"online" only when something else re-reads `devices.status` (there's no
automatic timeout that flips it back to `offline` on its own yet — a
device that posts once and then goes silent will show `online` with a
stale `last_seen_at`, which is what the "ต้องตรวจสาย USB" alert on the
teacher dashboard is actually watching for).

## 8. Local dev testing checklist

1. `npx supabase start` (local stack running).
2. As `school_admin`, call `register_device` (via the app, or curl with
   a real session token) to get a real `device_id`/`device_token`.
3. Use the Python snippet above (or equivalent) to POST one reading.
4. Confirm in the DB: `select * from sensor_readings where device_id = '<id>' order by ts desc limit 5;`
5. Confirm `devices.status` flipped to `online` and a `device_heartbeats`
   row appeared.
6. Try posting the exact same request again — `inserted` should be `0`
   (idempotent duplicate).
7. Try reusing the same `x-nonce` with a different body — should get
   `401` (`gateway_replay_detected`).
