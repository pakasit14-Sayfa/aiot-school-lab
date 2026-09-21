begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(18);

insert into packages(id,name,license_type) values
('72100000-0000-0000-0000-000000000001','Alerts security test','perpetual');
insert into schools(id,package_id,name,school_code) values
('72200000-0000-0000-0000-000000000001','72100000-0000-0000-0000-000000000001','Alerts A','ALERTS-SEC-A'),
('72200000-0000-0000-0000-000000000002','72100000-0000-0000-0000-000000000001','Alerts B','ALERTS-SEC-B');
insert into users(id,school_id,email,password_hash,first_name,last_name,created_by) values
('72500000-0000-0000-0000-000000000001','72200000-0000-0000-0000-000000000001','alerts-a@pdpa.test',crypt('test',gen_salt('bf')),'Alert','A','72500000-0000-0000-0000-000000000001'),
('72500000-0000-0000-0000-000000000002','72200000-0000-0000-0000-000000000002','alerts-b@pdpa.test',crypt('test',gen_salt('bf')),'Alert','B','72500000-0000-0000-0000-000000000002'),
('72500000-0000-0000-0000-000000000003',null,'alerts-super@pdpa.test',crypt('test',gen_salt('bf')),'Alert','Super','72500000-0000-0000-0000-000000000003');
insert into user_roles(user_id,role,school_id,granted_by) values
('72500000-0000-0000-0000-000000000001','teacher','72200000-0000-0000-0000-000000000001','72500000-0000-0000-0000-000000000001'),
('72500000-0000-0000-0000-000000000002','teacher','72200000-0000-0000-0000-000000000002','72500000-0000-0000-0000-000000000002'),
('72500000-0000-0000-0000-000000000003','super_admin',null,'72500000-0000-0000-0000-000000000003');
insert into sessions(user_id,active_role,active_school_id,token_hash,expires_at)
select user_id,role,school_id,encode(digest('alerts-test-'||user_id::text,'sha256'),'hex'),now()+interval '1 hour'
from user_roles where user_id in ('72500000-0000-0000-0000-000000000001','72500000-0000-0000-0000-000000000002','72500000-0000-0000-0000-000000000003');
insert into devices(id,school_id,type,name,registered_by) values
('72600000-0000-0000-0000-000000000001','72200000-0000-0000-0000-000000000001','pm25_sensor','Alert A','72500000-0000-0000-0000-000000000001'),
('72600000-0000-0000-0000-000000000002','72200000-0000-0000-0000-000000000002','pm25_sensor','Alert B','72500000-0000-0000-0000-000000000002');
insert into thresholds(id,school_id,metric,max_value,created_by) values
('72700000-0000-0000-0000-000000000001','72200000-0000-0000-0000-000000000001','pm25',50,'72500000-0000-0000-0000-000000000001'),
('72700000-0000-0000-0000-000000000002','72200000-0000-0000-0000-000000000002','pm25',50,'72500000-0000-0000-0000-000000000002');
insert into sensor_alerts(id,threshold_id,device_id,metric,value,status) values
('72800000-0000-0000-0000-000000000001','72700000-0000-0000-0000-000000000001','72600000-0000-0000-0000-000000000001','pm25',80,'new'),
('72800000-0000-0000-0000-000000000002','72700000-0000-0000-0000-000000000002','72600000-0000-0000-0000-000000000002','pm25',90,'new');

select ok(coalesce((select 'security_invoker=true'=any(reloptions) from pg_class where oid='public.alerts'::regclass),false),'alerts uses invoker security');
select ok(not has_table_privilege('anon','public.alerts','SELECT'),'anonymous direct SELECT remains revoked');
select ok(has_table_privilege('authenticated','public.alerts','SELECT'),'authenticated compatibility access retained');

-- Emulate Supabase Auth claims only within this rolled-back test transaction.
set local role authenticated;
set local request.jwt.claims='{"sub":"72500000-0000-0000-0000-000000000001","role":"authenticated"}';
select results_eq($$select id,school_id,status from public.alerts order by id$$,$$values ('72800000-0000-0000-0000-000000000001'::uuid,'72200000-0000-0000-0000-000000000001'::uuid,'new'::text)$$,'school A sees only its own alert through view');
select is((select count(*) from public.alerts where school_id='72200000-0000-0000-0000-000000000002'),0::bigint,'explicit school B filter cannot bypass RLS');
set local request.jwt.claims='{"sub":"72500000-0000-0000-0000-000000000002","role":"authenticated"}';
select is((select count(*) from public.alerts),1::bigint,'school B sees its own alert');
select is((select count(*) from public.alerts where school_id='72200000-0000-0000-0000-000000000001'),0::bigint,'school B cannot see school A');
set local request.jwt.claims='{"sub":"72500000-0000-0000-0000-000000000099","role":"authenticated"}';
select is((select count(*) from public.alerts),0::bigint,'unmapped authenticated identity sees nothing');
set local request.jwt.claims='{}';
select is((select count(*) from public.alerts),0::bigint,'missing identity sees nothing');
set local request.jwt.claims='{"sub":"72500000-0000-0000-0000-000000000003","role":"authenticated"}';
select is((select count(*) from public.alerts where school_id in ('72200000-0000-0000-0000-000000000001','72200000-0000-0000-0000-000000000002')),2::bigint,'Supabase Auth super admin retains cross-school visibility');

set local role anon;
set local request.jwt.claims='{}';
select throws_ok($$select * from public.alerts$$,'42501',null,'anonymous direct view read is denied');
select is((select count(*) from list_school_alerts('alerts-test-72500000-0000-0000-0000-000000000001')),1::bigint,'opaque-session main-app teacher read still works');
select is((select count(*) from list_school_alerts('alerts-test-72500000-0000-0000-0000-000000000001') where school_id='72200000-0000-0000-0000-000000000002'),0::bigint,'main-app RPC still excludes other schools');
select throws_ok($$select * from list_school_alerts('invalid-alerts-token')$$,'P0001','invalid_session','invalid opaque session still rejected');
select lives_ok($$select acknowledge_sensor_alert_for_school_admin('alerts-test-72500000-0000-0000-0000-000000000001','72800000-0000-0000-0000-000000000001')$$,'main-app acknowledgement still works');
select is((select status from list_school_alerts('alerts-test-72500000-0000-0000-0000-000000000001') where id='72800000-0000-0000-0000-000000000001'),'acknowledged'::text,'acknowledgement confirmed by canonical RPC read');
select is((select count(*) from list_school_alerts('alerts-test-72500000-0000-0000-0000-000000000003') where school_id in ('72200000-0000-0000-0000-000000000001','72200000-0000-0000-0000-000000000002')),2::bigint,'opaque-session super admin retains both schools');
reset role;
select is((select count(*) from sensor_alerts where id in ('72800000-0000-0000-0000-000000000001','72800000-0000-0000-0000-000000000002')),2::bigint,'underlying alerts are preserved');
select * from finish();
rollback;
