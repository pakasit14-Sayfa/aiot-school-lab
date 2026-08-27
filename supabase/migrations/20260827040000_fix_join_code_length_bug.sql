-- =====================================================================
-- Fix generate_course_join_code(): `(random() * n)::int` was relied on
-- to truncate into [0, n-1], but Postgres's float8->int4 cast ROUNDS
-- (not truncates) — when random()*32 lands close to 32 (e.g. 31.6), the
-- cast rounds up to 32, giving substr() an out-of-range starting
-- position (33) which silently returns '' instead of erroring, so
-- string_agg quietly drops that character. Confirmed live: the very
-- first real join code generated via the UI came out 7 chars instead
-- of 8 ("9QLJYHM"). floor() forces truncation before the cast, so the
-- result is always in [0, n-1].
-- =====================================================================

create or replace function generate_course_join_code()
returns varchar
language plpgsql
as $$
declare
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- no 0/O/1/I ambiguity
  v_code varchar;
begin
  loop
    v_code := (
      select string_agg(substr(v_alphabet, floor(random() * length(v_alphabet))::int + 1, 1), '')
      from generate_series(1, 8)
    );
    exit when not exists (select 1 from courses where join_code = v_code);
  end loop;
  return v_code;
end;
$$;
