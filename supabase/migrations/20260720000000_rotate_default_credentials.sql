-- =====================================================================
-- Rotate known default credentials.
--
-- 20260715010000_auth_rpc.sql bootstraps a super_admin with the password
-- 'ChangeMe123!' and seed.sql creates test accounts with 'Test1234!'.
-- Any account still using one of those passwords when this migration
-- runs gets its password replaced with a random value and all of its
-- sessions revoked.
--
-- To give the bootstrap admin a real password in the same run, set it
-- before pushing migrations:
--   alter database postgres set app.bootstrap_admin_password = '<strong password>';
-- (then reset it afterwards: alter database postgres reset app.bootstrap_admin_password;)
--
-- Otherwise, set a new password manually via the SQL editor:
--   update users set password_hash = crypt('<strong password>', gen_salt('bf'))
--     where email = 'admin@aiot-school-lab.local';
--
-- Local dev is unaffected: `supabase db reset` applies seed.sql after
-- migrations, which resets the dev accounts' passwords to 'Test1234!'.
-- =====================================================================

set search_path = public, extensions;

do $$
declare
  r record;
  v_admin_password text;
begin
  v_admin_password := current_setting('app.bootstrap_admin_password', true);

  for r in
    select id, email, password_hash from users
    where password_hash = crypt('ChangeMe123!', password_hash)
       or password_hash = crypt('Test1234!', password_hash)
  loop
    if r.email = 'admin@aiot-school-lab.local'
       and v_admin_password is not null and v_admin_password <> '' then
      update users
        set password_hash = crypt(v_admin_password, gen_salt('bf'))
        where id = r.id;
      raise notice 'bootstrap admin %: password set from app.bootstrap_admin_password', r.email;
    else
      update users
        set password_hash = crypt(gen_random_uuid()::text || clock_timestamp()::text, gen_salt('bf'))
        where id = r.id;
      raise notice 'account % still had a default password — rotated to a random value (see migration header for how to set a new one)', r.email;
    end if;

    update sessions set revoked_at = now()
      where user_id = r.id and revoked_at is null;
  end loop;
end $$;
