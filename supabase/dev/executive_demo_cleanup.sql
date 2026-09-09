-- Remove only the local EXECUTIVE_DEMO_V1 dataset.
begin;

delete from public.student_support_interventions where id::text like 'dc000000-0000-4000-8000-%';
delete from public.student_support_cases where id::text like 'db000000-0000-4000-8000-%';
delete from public.grades where id::text like 'd8000000-0000-4000-8000-%';
delete from public.submissions where id::text like 'd7000000-0000-4000-8000-%';
delete from public.assignments where id::text like 'd6000000-0000-4000-8000-%';
delete from public.course_students where id::text like 'd5000000-0000-4000-8000-%';
delete from public.courses where id::text like 'd4000000-0000-4000-8000-%';
delete from public.learning_track_room_assignments where id::text like 'da000000-0000-4000-8000-%';
delete from public.learning_tracks where id::text like 'd9000000-0000-4000-8000-%';
delete from public.homeroom_attendance_records where id::text like 'd2100000-0000-4000-8000-%';
delete from public.student_profiles where id::text like 'd2000000-0000-4000-8000-%';
delete from public.user_roles where id::text like 'd1000000-0000-4000-8000-%';
delete from public.users where id::text like 'd0000000-0000-4000-8000-%';
delete from public.rooms where id::text like 'd3000000-0000-4000-8000-%';

commit;
