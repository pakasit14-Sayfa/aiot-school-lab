-- =====================================================================
-- Signed gateway ingest. The gateway never sends its device token. It
-- uses SHA-256(device_token) as the HMAC key; that value is already
-- stored as devices.token_hash. Timestamp and per-device nonce prevent
-- replay. Pairs with supabase/functions/gateway-sensor-ingest.
-- =====================================================================

alter table devices
  add column if not exists token_issued_at timestamptz;

update devices
set token_issued_at = coalesce(token_issued_at, registered_at)
where token_hash is not null;

create table if not exists gateway_request_nonces (
  gateway_id uuid not null references devices(id),
  nonce varchar not null,
  used_at timestamptz not null default now(),
  primary key (gateway_id, nonce)
);

alter table gateway_request_nonces enable row level security;

create or replace function verify_gateway_request(
  p_gateway_id uuid,
  p_timestamp bigint,
  p_nonce text,
  p_signature text,
  p_method text,
  p_path text,
  p_body_hash text
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_device devices%rowtype;
  v_expected_signature text;
  v_signed_text text;
begin
  if abs(extract(epoch from now())::bigint - p_timestamp) > 300 then
    raise exception 'gateway_timestamp_out_of_range';
  end if;
  if p_nonce !~ '^[A-Za-z0-9_-]{16,128}$' then
    raise exception 'invalid_gateway_nonce';
  end if;
  if lower(p_body_hash) !~ '^[0-9a-f]{64}$'
     or lower(p_signature) !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid_gateway_signature';
  end if;

  select * into v_device
  from devices
  where id = p_gateway_id
    and token_hash is not null
    and status <> 'error';
  if not found then raise exception 'invalid_gateway'; end if;

  v_signed_text := upper(trim(p_method)) || E'\n'
    || trim(p_path) || E'\n'
    || p_timestamp::text || E'\n'
    || p_nonce || E'\n'
    || lower(p_body_hash);
  v_expected_signature := encode(
    hmac(v_signed_text, v_device.token_hash, 'sha256'),
    'hex'
  );

  if v_expected_signature <> lower(p_signature) then
    raise exception 'invalid_gateway_signature';
  end if;

  begin
    insert into gateway_request_nonces (gateway_id, nonce)
    values (p_gateway_id, p_nonce);
  exception when unique_violation then
    raise exception 'gateway_replay_detected';
  end;

  return true;
end;
$$;

create or replace function ingest_sensor_readings_verified(
  p_gateway_id uuid,
  p_readings jsonb
)
returns integer
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_reading jsonb;
  v_metric metric_type;
  v_value numeric;
  v_ts timestamptz;
  v_inserted integer := 0;
begin
  if not exists (
    select 1 from gateway_request_nonces
    where gateway_id = p_gateway_id
      and used_at >= now() - interval '5 minutes'
  ) then
    raise exception 'verified_gateway_request_required';
  end if;
  if p_readings is null or jsonb_typeof(p_readings) <> 'array' then
    raise exception 'readings_must_be_array';
  end if;
  if jsonb_array_length(p_readings) > 500 then
    raise exception 'batch_too_large';
  end if;

  for v_reading in select * from jsonb_array_elements(p_readings)
  loop
    begin
      v_metric := (v_reading->>'metric')::metric_type;
      v_value := (v_reading->>'value')::numeric;
      v_ts := coalesce((v_reading->>'ts')::timestamptz, now());
    exception when others then
      raise exception 'invalid_sensor_reading';
    end;
    if v_value is null then raise exception 'invalid_sensor_reading'; end if;

    insert into sensor_readings (device_id, metric, ts, value)
    values (p_gateway_id, v_metric, v_ts, v_value)
    on conflict (device_id, metric, ts) do nothing;
    if found then v_inserted := v_inserted + 1; end if;
  end loop;

  update devices set status = 'online' where id = p_gateway_id;
  insert into device_heartbeats (device_id, status, details)
  values (
    p_gateway_id,
    'online',
    jsonb_build_object('readings', jsonb_array_length(p_readings), 'auth', 'hmac')
  );
  return v_inserted;
end;
$$;

-- The legacy bearer-token ingest path is intentionally disabled.
revoke all on function sensor_ingest(text, jsonb)
  from public, anon, authenticated;
revoke all on function verify_gateway_request(uuid, bigint, text, text, text, text, text)
  from public, anon, authenticated;
revoke all on function ingest_sensor_readings_verified(uuid, jsonb)
  from public, anon, authenticated;
grant execute on function verify_gateway_request(uuid, bigint, text, text, text, text, text)
  to service_role;
grant execute on function ingest_sensor_readings_verified(uuid, jsonb)
  to service_role;

create index if not exists idx_gateway_request_nonces_used_at
  on gateway_request_nonces (used_at);

create or replace function set_device_token_issued_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if tg_op = 'INSERT' or new.token_hash is distinct from old.token_hash then
    new.token_issued_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_device_token_issued_at on devices;
create trigger trg_device_token_issued_at
before update of token_hash on devices
for each row execute function set_device_token_issued_at();

drop trigger if exists trg_device_token_issued_at_insert on devices;
create trigger trg_device_token_issued_at_insert
before insert on devices
for each row execute function set_device_token_issued_at();

revoke all on function set_device_token_issued_at() from public, anon, authenticated;
