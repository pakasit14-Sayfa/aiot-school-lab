begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(12);

insert into packages (id,name,license_type) values
('71100000-0000-0000-0000-000000000001','Latest probe test','perpetual');
insert into schools (id,package_id,name,school_code) values
('71200000-0000-0000-0000-000000000001','71100000-0000-0000-0000-000000000001','Probe A','PROBE-A'),
('71200000-0000-0000-0000-000000000002','71100000-0000-0000-0000-000000000001','Probe B','PROBE-B');
insert into users (id,school_id,email,password_hash,first_name,last_name,created_by) values
('71500000-0000-0000-0000-000000000001','71200000-0000-0000-0000-000000000001','probe@pdpa.test',crypt('x',gen_salt('bf')),'Probe','Test','71500000-0000-0000-0000-000000000001');
insert into user_roles (user_id,role,school_id,granted_by)
select '71500000-0000-0000-0000-000000000001',r::role_type,
case when r='super_admin' then null::uuid else '71200000-0000-0000-0000-000000000001'::uuid end,
'71500000-0000-0000-0000-000000000001'
from unnest(array['super_admin','school_admin','teacher','executive','student','parent']) r;
insert into sessions (user_id,active_role,active_school_id,token_hash,expires_at)
select '71500000-0000-0000-0000-000000000001',role,school_id,
encode(digest('probe-'||role::text,'sha256'),'hex'),now()+interval '1 hour'
from user_roles where user_id='71500000-0000-0000-0000-000000000001';
insert into devices (id,school_id,type,name,registered_by) values
('71600000-0000-0000-0000-000000000001','71200000-0000-0000-0000-000000000001','air_quality_sensor','Probe A','71500000-0000-0000-0000-000000000001'),
('71600000-0000-0000-0000-000000000002','71200000-0000-0000-0000-000000000002','air_quality_sensor','Probe B','71500000-0000-0000-0000-000000000001'),
('71600000-0000-0000-0000-000000000003','71200000-0000-0000-0000-000000000001','air_quality_sensor','Empty','71500000-0000-0000-0000-000000000001');
insert into sensor_readings(device_id,metric,ts,value)
select d.id,m.metric,'2026-09-01+00'::timestamptz+g*interval '1 second',g::numeric
from devices d cross join unnest(enum_range(null::metric_type)) m(metric)
cross join generate_series(1,20) g
where d.id in ('71600000-0000-0000-0000-000000000001','71600000-0000-0000-0000-000000000002');

select throws_ok($$select * from sensor_latest('invalid-probe-token')$$,'P0001','invalid_session','invalid token rejected');
select results_eq(
  $$select * from sensor_latest('probe-super_admin')$$,
  $$select distinct on(d.id,r.metric) d.id,d.name,d.location,r.metric,r.ts,r.value from devices d join sensor_readings r on r.device_id=d.id order by d.id,r.metric,r.ts desc$$,
  'super admin result equals old query including all metrics and existing data');
select results_eq(
  $$select * from sensor_latest('probe-teacher')$$,
  $$select distinct on(d.id,r.metric) d.id,d.name,d.location,r.metric,r.ts,r.value from devices d join sensor_readings r on r.device_id=d.id where d.school_id='71200000-0000-0000-0000-000000000001' order by d.id,r.metric,r.ts desc$$,
  'school-scoped result equals old query');
select is((select count(*) from sensor_latest('probe-teacher','71600000-0000-0000-0000-000000000002')),0::bigint,'device filter cannot cross school boundary');
select is((select count(*) from sensor_latest('probe-teacher','71600000-0000-0000-0000-000000000003')),0::bigint,'device without readings stays absent');
select is((select count(*) from sensor_latest('probe-super_admin','71600000-0000-0000-0000-000000000002')),cardinality(enum_range(null::metric_type))::bigint,'super admin can select another school device');
select ok((select bool_and(value=20) from sensor_latest('probe-teacher')),'returns newest values, not first readings');
select is((select count(*) from sensor_latest('probe-school_admin')),cardinality(enum_range(null::metric_type))::bigint,'school admin scoped');
select is((select count(*) from sensor_latest('probe-executive')),cardinality(enum_range(null::metric_type))::bigint,'executive scoped');
select is((select count(*) from sensor_latest('probe-student')),cardinality(enum_range(null::metric_type))::bigint,'student scoped');
select is((select count(*) from sensor_latest('probe-parent')),cardinality(enum_range(null::metric_type))::bigint,'parent scoped');
update sessions set expires_at=now()-interval '1 second' where token_hash=encode(digest('probe-teacher','sha256'),'hex');
select throws_ok($$select * from sensor_latest('probe-teacher')$$,'P0001','invalid_session','expired session rejected');
select * from finish();
rollback;
