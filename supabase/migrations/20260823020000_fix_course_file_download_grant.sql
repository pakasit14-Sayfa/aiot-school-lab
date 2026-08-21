-- course-file-download (Edge Function) calls get_course_file_for_download
-- with the service-role client, same as lesson-material-download does for
-- get_lesson_material_for_download. That function's grant only covered
-- anon/authenticated, so service_role has no EXECUTE privilege and every
-- call fails with a permission error, surfaced by the Edge Function as a
-- generic "forbidden". Found while verifying the lesson-materials feature
-- (which had the identical bug, fixed in 20260823010000_lesson_material_upload.sql)
-- and confirmed course_files has the same gap by inspection.

grant execute on function get_course_file_for_download(text, uuid) to service_role;
