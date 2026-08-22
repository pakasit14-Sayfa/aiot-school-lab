-- 20260823070000_seed_auth_users_for_local_dev.sql seeds auth.users with
-- password 'Password123!', but the live local DB's actual passwords had
-- already drifted to something else by the time this was checked (found via
-- real login testing: 'Password123!' returned invalid_credentials for all 8
-- seeded accounts, confirmed via `encrypted_password = crypt(...)` in SQL).
--
-- Standardize on 'Test1234!' — the same password already documented in
-- CLAUDE.md for my_first_app's own custom-session test accounts — so both
-- auth systems in this repo use one password to remember.

update auth.users
set encrypted_password = crypt('Test1234!', gen_salt('bf', 10)),
    updated_at = now()
where email in (
  select email from public.users
);
