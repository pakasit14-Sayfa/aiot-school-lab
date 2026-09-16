-- device_effective_status อ่าน platform_settings.offline_minutes จริง (20260916020000)
begin;

create extension if not exists pgtap with schema extensions;
select plan(5);

update platform_settings set offline_minutes = 5 where id = 1;

select is(device_effective_status('online', now() - interval '3 minutes'), 'online'::device_status,
  'เห็นล่าสุด 3 นาที · เกณฑ์ 5 นาที → ยัง online');
select is(device_effective_status('online', now() - interval '8 minutes'), 'offline'::device_status,
  'เห็นล่าสุด 8 นาที · เกณฑ์ 5 นาที → offline');

update platform_settings set offline_minutes = 15 where id = 1;
select is(device_effective_status('online', now() - interval '8 minutes'), 'online'::device_status,
  'ขยายเกณฑ์เป็น 15 นาที → 8 นาทีกลับเป็น online (ค่าที่ตั้งมีผลจริง)');

select is(device_effective_status('online', null), 'offline'::device_status,
  'ไม่เคยรายงานตัว → offline เสมอ');
select is(device_effective_status('maintenance', now()), 'maintenance'::device_status,
  'maintenance/error ไม่ถูกเกณฑ์เวลาแตะ');

select * from finish();
rollback;
