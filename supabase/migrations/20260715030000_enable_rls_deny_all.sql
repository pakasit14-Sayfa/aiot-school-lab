-- =====================================================================
-- SECURITY FIX (ด่วน): เปิด RLS ทุกตารางแบบ deny-all
--
-- พบว่า Supabase ให้สิทธิ์ anon/authenticated อ่าน-เขียนตารางใน schema
-- public เป็นค่าเริ่มต้น ถ้าไม่เปิด RLS — ทดสอบแล้วพบว่า users.password_hash
-- และ sessions.token_hash หลุดออกมาผ่าน REST API ตรง ๆ ได้ ต้องปิดทันที
--
-- เปิด RLS แบบไม่มี policy ใด ๆ ก่อน = deny-all สำหรับ anon/authenticated
-- ทุกกรณี ส่วน RPC (auth_sign_in ฯลฯ) เป็น SECURITY DEFINER ที่ owner เป็น
-- เจ้าของตาราง (bypass RLS ตาม Postgres default) จึงยังทำงานได้ตามปกติ
--
-- Policy ที่ถูกต้องตาม permission-matrix-mvp-v1 ต้องออกแบบทีละตารางเป็น
-- งานถัดไป — deny-all นี้คือ "ปิดรูรั่ว" ชั่วคราวที่ปลอดภัยที่สุดตอนนี้
-- =====================================================================

alter table packages enable row level security;
alter table schools enable row level security;
alter table academic_years enable row level security;
alter table terms enable row level security;
alter table school_settings enable row level security;
alter table users enable row level security;
alter table student_profiles enable row level security;
alter table user_roles enable row level security;
alter table user_invitations enable row level security;
alter table sessions enable row level security;
alter table trusted_devices enable row level security;
alter table parent_binding_codes enable row level security;
alter table otp_codes enable row level security;
alter table audit_logs enable row level security;
alter table parent_links enable row level security;
alter table consent_policies enable row level security;
alter table consents enable row level security;
alter table consent_events enable row level security;
alter table courses enable row level security;
alter table course_teachers enable row level security;
alter table course_students enable row level security;
alter table assignments enable row level security;
alter table student_groups enable row level security;
alter table group_members enable row level security;
alter table devices enable row level security;
alter table lessons enable row level security;
alter table lesson_materials enable row level security;
alter table lesson_sensor_links enable row level security;
alter table lesson_progress enable row level security;
alter table assignment_sensor_datasets enable row level security;
alter table submissions enable row level security;
alter table submission_versions enable row level security;
alter table charts enable row level security;
alter table submission_attachments enable row level security;
alter table feedbacks enable row level security;
alter table rubrics enable row level security;
alter table rubric_criteria enable row level security;
alter table quizzes enable row level security;
alter table quiz_questions enable row level security;
alter table quiz_choices enable row level security;
alter table quiz_attempts enable row level security;
alter table quiz_answers enable row level security;
alter table grades enable row level security;
alter table grade_criterion_scores enable row level security;
alter table device_heartbeats enable row level security;
alter table sensor_readings enable row level security;
alter table thresholds enable row level security;
alter table sensor_alerts enable row level security;
alter table emergency_events enable row level security;
alter table security_events enable row level security;
alter table camera_access_grants enable row level security;
alter table notifications enable row level security;

-- ตารางที่ SECURITY DEFINER function เป็นเจ้าของ (owner) เดียวกับตาราง
-- (สร้างผ่าน migration ในนามเดียวกัน) จึง bypass RLS ได้ตาม Postgres
-- default โดยไม่ต้องตั้งค่าเพิ่ม — แต่กันไว้อีกชั้นด้วย FORCE ก็ไม่จำเป็น
-- เพราะเราต้องการให้ owner (function) ผ่านได้อยู่แล้ว
