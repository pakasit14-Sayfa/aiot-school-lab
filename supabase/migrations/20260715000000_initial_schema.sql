-- =====================================================================
-- AIoT Safe & Green School Lab — Initial Schema (MVP v1)
-- Generated from AIoT-School-Lab-Vault/MVP-Planning/db-schema-mvp-v1.dbml
--
-- Open Issue: sensor_readings ใช้ Postgres table ธรรมดา (ไม่ใช่ TimescaleDB
-- hypertable) เพราะ Supabase Cloud ไม่รองรับ extension timescaledb
-- (เช็คแล้ว 2026-07-15 ผ่าน pg_available_extensions) — ดูรายละเอียดใน
-- vault: MVP-Planning/api-spec-mvp-v1.md หัวข้อ 16 Open Issues
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------- Enums ----------

create type user_status as enum ('active', 'suspended');

create type role_type as enum (
  'super_admin', 'school_admin', 'teacher', 'executive',
  'student', 'parent', 'facility_manager', 'technician'
);

create type otp_purpose as enum ('login_2fa', 'password_reset', 'parent_email_verify');

create type binding_status as enum ('pending', 'pending_second_review', 'approved', 'rejected', 'revoked');

create type binding_code_status as enum ('issued', 'redeemed', 'expired', 'revoked');

create type consent_status as enum ('granted', 'withdrawn');

create type consent_action as enum ('granted', 'withdrawn');

create type invitation_status as enum ('pending', 'accepted', 'expired', 'revoked');

create type course_status as enum ('active', 'closed');

create type lesson_status as enum ('draft', 'published', 'archived');

create type material_type as enum ('video', 'file', 'link', 'image');

create type assignment_type as enum ('worksheet', 'homework', 'project');

create type publish_status as enum ('draft', 'published');

create type submission_status as enum ('submitted', 'graded', 'returned');

create type attachment_type as enum ('file', 'sensor_dataset', 'chart');

create type chart_type as enum ('line', 'bar', 'compare_before_after');

create type quiz_type as enum ('pre_test', 'post_test', 'general');

create type question_type as enum ('multiple_choice', 'true_false', 'short_answer');

create type grade_source as enum ('submission', 'quiz_attempt');

create type grade_status as enum ('draft', 'confirmed');

create type coi_review_status as enum ('pending', 'reviewed');

create type device_type as enum (
  'mini_pc', 'aiot_gateway', 'pm25_sensor', 'air_quality_sensor',
  'light_sensor', 'energy_meter', 'camera', 'relay',
  'emergency_button', 'warning_light'
);

create type device_status as enum ('online', 'offline', 'error', 'maintenance');

create type metric_type as enum ('pm25', 'aqi', 'temperature', 'humidity', 'light_lux', 'energy_kwh', 'power_w');

create type alert_status as enum ('new', 'acknowledged', 'resolved');

create type emergency_status as enum ('new', 'acknowledged', 'closed');

create type security_event_status as enum ('pending_review', 'confirmed', 'rejected');

create type license_type as enum ('perpetual', 'subscription');

-- ---------- 1) School & Package ----------

create table packages (
  id uuid primary key default gen_random_uuid(),
  name varchar not null,
  license_type license_type not null default 'perpetual',
  enabled_modules jsonb,
  max_users int,
  created_at timestamptz default now()
);
comment on table packages is 'MVP: seed แถว default แถวเดียว — หน้าจอจัดการแพ็กเกจ/license เป็น Phase 3 (กลุ่ม COM)';

create table schools (
  id uuid primary key default gen_random_uuid(),
  package_id uuid not null,
  name varchar not null unique,
  school_code varchar not null unique,
  address text,
  contact_name varchar,
  contact_phone varchar,
  logo_url varchar,
  status user_status default 'active',
  created_at timestamptz default now()
);

create table academic_years (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  name varchar not null,
  start_date date,
  end_date date
);

create table terms (
  id uuid primary key default gen_random_uuid(),
  academic_year_id uuid not null,
  name varchar not null,
  start_date date,
  end_date date
);

create table school_settings (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null unique,
  electricity_rate_thb numeric,
  retention_policy jsonb,
  pdpa_camera_ready bool not null default false,
  pdpa_camera_approved_by uuid,
  pdpa_camera_approved_at timestamptz
);
comment on column school_settings.pdpa_camera_ready is 'deployment gate: ต้องเป็น true ก่อนเปิดใช้ endpoint กล้องที่แตะภาพ/คลิป';

-- ---------- 2) Identity & Auth ----------

create table users (
  id uuid primary key default gen_random_uuid(),
  school_id uuid,
  email varchar not null unique,
  student_code varchar,
  password_hash varchar not null,
  must_change_password bool not null default false,
  first_name varchar not null,
  last_name varchar not null,
  status user_status not null default 'active',
  created_by uuid,
  created_at timestamptz default now(),
  unique (school_id, student_code)
);
comment on table users is 'id = internal_user_id — PK ถาวรตาม decision ห้ามใช้ student_code/email เป็น FK';
comment on column users.created_by is 'ไม่มี self-signup — บังคับสำหรับทุกบัญชี ยกเว้น bootstrap super_admin คนแรกจาก migration';

create table student_profiles (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null,
  academic_year_id uuid not null,
  grade_level varchar not null,
  room varchar not null,
  created_by uuid not null,
  created_at timestamptz not null default now(),
  unique (student_id, academic_year_id)
);

create table user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  role role_type not null,
  school_id uuid,
  granted_by uuid not null,
  granted_at timestamptz default now(),
  unique (user_id, role, school_id)
);
comment on table user_roles is 'ผู้ใช้ 1 คนมีได้หลาย role — สิทธิ์ใช้งานจริงดูจาก sessions.active_role';

create table user_invitations (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  email varchar not null,
  initial_role role_type not null default 'teacher',
  scope jsonb not null,
  token_hash varchar not null unique,
  status invitation_status not null default 'pending',
  expires_at timestamptz not null,
  invited_by uuid not null,
  accepted_by uuid,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);
create index idx_user_invitations_school_email_status on user_invitations (school_id, email, status);

create table sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  active_role role_type not null,
  active_school_id uuid,
  token_hash varchar not null,
  device_info varchar,
  ip_address varchar,
  created_at timestamptz default now(),
  expires_at timestamptz not null,
  revoked_at timestamptz
);

create table trusted_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  device_fingerprint varchar not null,
  trusted_until timestamptz not null,
  created_at timestamptz default now()
);

create table parent_binding_codes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  student_id uuid not null,
  code_hash varchar not null unique,
  code_hint varchar,
  status binding_code_status not null default 'issued',
  expires_at timestamptz not null,
  issued_by uuid not null,
  issued_at timestamptz not null default now(),
  redeemed_by uuid,
  redeemed_at timestamptz,
  revoked_by uuid,
  revoked_at timestamptz,
  revoke_reason text
);
create index idx_parent_binding_codes_school_status on parent_binding_codes (school_id, status);
create index idx_parent_binding_codes_student_status on parent_binding_codes (student_id, status);

create table otp_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  parent_binding_code_id uuid,
  purpose otp_purpose not null,
  code_hash varchar not null,
  sent_to_email varchar not null,
  attempt_count int not null default 0,
  locked_until timestamptz,
  last_sent_at timestamptz not null default now(),
  expires_at timestamptz not null,
  used_at timestamptz
);
comment on table otp_codes is 'ต้องมี user_id หรือ parent_binding_code_id อย่างน้อยหนึ่งค่า';

create table audit_logs (
  id bigserial primary key,
  school_id uuid,
  user_id uuid,
  acted_role role_type,
  action varchar not null,
  entity_type varchar,
  entity_id varchar,
  details jsonb,
  ip_address varchar,
  created_at timestamptz default now()
);

-- ---------- 3) Parent & PDPA ----------

create table parent_links (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null,
  parent_id uuid not null,
  relationship varchar not null,
  binding_code_id uuid not null unique,
  status binding_status not null default 'pending',
  requested_at timestamptz default now(),
  first_reviewed_by uuid,
  first_reviewed_at timestamptz,
  approved_by uuid,
  approved_at timestamptz,
  rejected_by uuid,
  rejected_at timestamptz,
  rejection_reason text,
  coi_conflict bool not null default false,
  exception_reason text,
  second_approved_by uuid,
  second_approved_at timestamptz,
  unique (student_id, parent_id)
);
comment on table parent_links is 'CoI 2 แบบ: (1) grading ใช้ flag+audit ไม่ block (2) parent binding เก็บ first reviewer แล้ว block เป็น pending_second_review';

create table consent_policies (
  id uuid primary key default gen_random_uuid(),
  school_id uuid,
  consent_type varchar not null,
  version varchar not null,
  document_hash varchar not null,
  content_url varchar not null,
  effective_at timestamptz not null,
  retired_at timestamptz,
  created_by uuid not null,
  unique (school_id, consent_type, version)
);

create table consents (
  id uuid primary key default gen_random_uuid(),
  parent_link_id uuid not null,
  policy_id uuid not null,
  status consent_status not null default 'granted',
  granted_by uuid not null,
  granted_at timestamptz not null default now(),
  withdrawn_at timestamptz,
  evidence_hash varchar not null,
  details jsonb not null,
  unique (parent_link_id, policy_id)
);

create table consent_events (
  id bigserial primary key,
  consent_id uuid not null,
  policy_id uuid not null,
  actor_id uuid not null,
  action consent_action not null,
  evidence jsonb not null,
  occurred_at timestamptz not null default now()
);

-- ---------- 4) Classroom ----------

create table courses (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  term_id uuid not null,
  subject_name varchar not null,
  grade_level varchar,
  room varchar,
  description text,
  status course_status not null default 'active',
  closed_at timestamptz,
  created_by uuid not null,
  created_at timestamptz default now()
);

create table course_teachers (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null,
  teacher_id uuid not null,
  is_owner bool default true,
  unique (course_id, teacher_id)
);

create table course_students (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null,
  student_id uuid not null,
  enrolled_by uuid,
  enrolled_at timestamptz default now(),
  unique (course_id, student_id)
);

create table assignments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null,
  type assignment_type not null,
  title varchar not null,
  instructions text,
  due_at timestamptz,
  is_group bool default false,
  rubric_id uuid,
  status publish_status not null default 'draft',
  created_by uuid not null,
  created_at timestamptz default now()
);

create table student_groups (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null,
  assignment_id uuid,
  name varchar not null,
  created_by uuid not null,
  created_at timestamptz default now()
);
comment on column student_groups.assignment_id is 'CLS-5 BR1: นักเรียน 1 คนอยู่ได้ 1 กลุ่มต่อกิจกรรม';

create table group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null,
  student_id uuid not null,
  unique (group_id, student_id)
);

-- ---------- 5) Lesson ----------

create table devices (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  type device_type not null,
  name varchar not null,
  serial_no varchar unique,
  location varchar,
  kit_code varchar,
  status device_status not null default 'offline',
  registered_by uuid not null,
  registered_at timestamptz default now()
);

create table lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null,
  title varchar not null,
  content jsonb,
  status lesson_status not null default 'draft',
  published_at timestamptz,
  created_by uuid not null,
  updated_at timestamptz
);

create table lesson_materials (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null,
  type material_type not null,
  title varchar,
  url varchar not null,
  sort_order int default 0
);
comment on column lesson_materials.url is 'LRN-2: ไฟล์เก็บใน Supabase Storage';

create table lesson_sensor_links (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null,
  device_id uuid not null,
  metric metric_type not null,
  time_start timestamptz,
  time_end timestamptz,
  caption varchar
);
comment on table lesson_sensor_links is 'LRN-8: ฝังข้อมูล AIoT จริงในบทเรียน';

create table lesson_progress (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null,
  student_id uuid not null,
  progress_pct numeric default 0,
  completed bool default false,
  completed_at timestamptz,
  updated_at timestamptz,
  unique (lesson_id, student_id)
);

-- ---------- 6) Assignment & PBL ----------

create table assignment_sensor_datasets (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null,
  device_id uuid not null,
  metric metric_type not null,
  time_start timestamptz,
  time_end timestamptz,
  label varchar
);

create table submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid not null,
  student_id uuid,
  group_id uuid,
  status submission_status not null default 'submitted',
  current_version int not null default 1,
  submitted_at timestamptz default now(),
  unique (assignment_id, student_id),
  unique (assignment_id, group_id)
);
comment on column submissions.student_id is 'งานเดี่ยว';
comment on column submissions.group_id is 'งานกลุ่ม (PBL-10) — student_id หรือ group_id อย่างใดอย่างหนึ่ง';

create table submission_versions (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null,
  version int not null,
  content text,
  submitted_by uuid not null,
  submitted_at timestamptz default now(),
  unique (submission_id, version)
);
comment on table submission_versions is 'PBL-11 BR1: เก็บประวัติทุกเวอร์ชันการส่ง';

create table charts (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null,
  course_id uuid,
  chart_type chart_type not null,
  device_id uuid not null,
  metric metric_type not null,
  time_start timestamptz not null,
  time_end timestamptz not null,
  compare_time_start timestamptz,
  compare_time_end timestamptz,
  config jsonb,
  annotation text,
  created_at timestamptz default now()
);
comment on table charts is 'PBL-7 BR1: กราฟอ้างอิงข้อมูลจริงจาก sensor_readings เท่านั้น ห้ามพิมพ์ตัวเลขเอง — จึงเก็บเป็น query params ไม่เก็บตัวเลขดิบ';

create table submission_attachments (
  id uuid primary key default gen_random_uuid(),
  submission_version_id uuid not null,
  type attachment_type not null,
  file_url varchar,
  dataset_id uuid,
  chart_id uuid
);

create table feedbacks (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null,
  author_id uuid not null,
  body text not null,
  created_at timestamptz default now()
);

-- ---------- 7) Quiz & Rubric ----------

create table rubrics (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  title varchar not null,
  description text,
  created_by uuid not null
);

create table rubric_criteria (
  id uuid primary key default gen_random_uuid(),
  rubric_id uuid not null,
  name varchar not null,
  description text,
  max_score numeric not null,
  levels jsonb,
  sort_order int default 0
);

create table quizzes (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null,
  lesson_id uuid,
  type quiz_type not null,
  title varchar not null,
  time_limit_min int,
  status publish_status not null default 'draft',
  created_by uuid not null
);

create table quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null,
  type question_type not null,
  question text not null,
  points numeric not null default 1,
  sort_order int default 0
);

create table quiz_choices (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null,
  choice_text text not null,
  is_correct bool default false,
  sort_order int default 0
);

create table quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null,
  student_id uuid not null,
  started_at timestamptz default now(),
  submitted_at timestamptz,
  auto_score numeric
);
comment on column quiz_attempts.auto_score is 'ASM-4: คะแนนอัตโนมัติเฉพาะปรนัย — คะแนนจริงต้องผ่าน grades (ครูยืนยัน)';

create table quiz_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null,
  question_id uuid not null,
  answer jsonb,
  is_correct bool,
  score numeric
);

-- ---------- 8) Grade ----------

create table grades (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null,
  course_id uuid not null,
  source_type grade_source not null,
  submission_id uuid,
  quiz_attempt_id uuid,
  score numeric,
  max_score numeric,
  status grade_status not null default 'draft',
  graded_by uuid,
  graded_at timestamptz default now(),
  coi_flag bool not null default false,
  coi_detected_at timestamptz,
  coi_review_status coi_review_status,
  coi_reviewed_by uuid,
  coi_reviewed_at timestamptz,
  confirmed_by uuid,
  confirmed_at timestamptz
);
comment on table grades is 'หัวใจหลัก "ครูยืนยันเสมอ" — งานกลุ่ม: สร้าง grade แยกรายนักเรียนทุกคนในกลุ่ม · coi_flag ต้องตั้งโดยระบบผ่าน trigger/RPC เท่านั้น และเมื่อเป็น true แล้วห้ามย้อนเป็น false · courses.status ห้ามเป็น closed ถ้ายังมี grade ในวิชานั้นที่ coi_review_status = pending';
comment on column grades.status is 'นักเรียน/ผู้ปกครองเห็นเฉพาะ confirmed เท่านั้น (หลักการที่ไม่ต่อรอง)';

create table grade_criterion_scores (
  id uuid primary key default gen_random_uuid(),
  grade_id uuid not null,
  criterion_id uuid not null,
  score numeric not null,
  feedback text,
  unique (grade_id, criterion_id)
);

-- ---------- 9) AIoT Devices & Sensor Data ----------

create table device_heartbeats (
  id bigserial primary key,
  device_id uuid not null,
  ts timestamptz not null default now(),
  status device_status not null,
  details jsonb
);
create index idx_device_heartbeats_device_ts on device_heartbeats (device_id, ts);
comment on table device_heartbeats is 'DEV-3 ถึง DEV-9: สถานะอุปกรณ์ทุกชนิดรวมกล้อง (สถานะเท่านั้น ไม่เกี่ยวกับภาพ)';

-- Open Issue: TimescaleDB hypertable ใช้ไม่ได้บน Supabase Cloud (ไม่มี extension)
-- ใช้ Postgres table ธรรมดาไปก่อนสำหรับ MVP แล้วย้ายเป็น hypertable จริงตอน
-- self-host EdgeBox — ดู MVP-Planning/api-spec-mvp-v1.md หัวข้อ 16
create table sensor_readings (
  device_id uuid not null,
  metric metric_type not null,
  ts timestamptz not null,
  value numeric not null,
  primary key (device_id, metric, ts)
);
comment on table sensor_readings is 'AIO-12: จุดรับข้อมูลจาก AIoT Gateway ฐานของ dashboard ทุกตัว (AIO-1..8) และ export (AIO-10). Plain Postgres table ใน MVP (ไม่ใช่ TimescaleDB hypertable) — ดู Open Issue';

create table thresholds (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  device_id uuid,
  metric metric_type not null,
  min_value numeric,
  max_value numeric,
  is_active bool default true,
  created_by uuid not null
);
comment on table thresholds is 'AIO-9: เงื่อนไขแจ้งเตือนค่าผิดปกติแบบง่าย';

create table sensor_alerts (
  id uuid primary key default gen_random_uuid(),
  threshold_id uuid not null,
  device_id uuid not null,
  metric metric_type not null,
  value numeric not null,
  triggered_at timestamptz default now(),
  status alert_status not null default 'new',
  acknowledged_by uuid,
  acknowledged_at timestamptz
);

-- ---------- 10) Emergency ----------

create table emergency_events (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  source_device_id uuid,
  location varchar,
  triggered_at timestamptz default now(),
  status emergency_status not null default 'new',
  warning_light_on bool default false,
  acknowledged_by uuid,
  acknowledged_at timestamptz,
  closed_at timestamptz,
  review_note text
);
comment on column emergency_events.warning_light_on is 'EMG-3: ระบบสั่งเปิดไฟจนกว่าครูยืนยัน — override คำสั่งผู้ใช้ทั่วไป';

-- ---------- 11) Smart Security ----------

create table security_events (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  camera_device_id uuid not null,
  event_type varchar not null default 'motion',
  detected_at timestamptz not null,
  metadata jsonb,
  clip_object_key varchar,
  status security_event_status not null default 'pending_review',
  reviewed_by uuid,
  reviewed_at timestamptz,
  review_note text,
  retention_expires_at timestamptz not null,
  purged_at timestamptz
);
comment on table security_events is 'MVP: motion เท่านั้น — ชนิดอื่นเป็น Phase 3';
comment on column security_events.metadata is 'event metadata จาก Edge AI (YOLOv8) เท่านั้น — ห้ามมี field ระบุตัวตน/Face Recognition (decision)';
comment on column security_events.clip_object_key is 'private object key ใน security-clips bucket ห้ามเก็บ signed URL; URL 60 วินาทีสร้างเมื่อผ่าน grant + PDPA gate และ audit';
comment on column security_events.retention_expires_at is 'SEC-10: ครบกำหนดต้อง purge — ข้อมูลเด็กใช้ระยะเก็บสั้นพิเศษ';

create table camera_access_grants (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  user_id uuid not null,
  camera_device_id uuid,
  granted_by uuid not null,
  reason text not null,
  valid_from timestamptz not null default now(),
  valid_until timestamptz not null,
  granted_at timestamptz default now(),
  revoked_at timestamptz
);
comment on table camera_access_grants is 'SEC-9: facility_manager ห้ามมีสิทธิ์นี้เด็ดขาด (decision) · ทุกการเปิดดูภาพต้องลง audit_logs';

-- ---------- 12) Notification ----------

create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  type varchar not null,
  title varchar not null,
  body text,
  payload jsonb,
  created_at timestamptz default now(),
  read_at timestamptz
);

-- =====================================================================
-- Foreign Keys (เพิ่มทีหลังทั้งหมดเพื่อเลี่ยงปัญหา forward reference)
-- =====================================================================

alter table schools add constraint fk_schools_package foreign key (package_id) references packages(id);
alter table academic_years add constraint fk_academic_years_school foreign key (school_id) references schools(id);
alter table terms add constraint fk_terms_academic_year foreign key (academic_year_id) references academic_years(id);
alter table school_settings add constraint fk_school_settings_school foreign key (school_id) references schools(id);
alter table school_settings add constraint fk_school_settings_approved_by foreign key (pdpa_camera_approved_by) references users(id);

alter table users add constraint fk_users_school foreign key (school_id) references schools(id);
alter table users add constraint fk_users_created_by foreign key (created_by) references users(id);

alter table student_profiles add constraint fk_student_profiles_student foreign key (student_id) references users(id);
alter table student_profiles add constraint fk_student_profiles_academic_year foreign key (academic_year_id) references academic_years(id);
alter table student_profiles add constraint fk_student_profiles_created_by foreign key (created_by) references users(id);

alter table user_roles add constraint fk_user_roles_user foreign key (user_id) references users(id);
alter table user_roles add constraint fk_user_roles_school foreign key (school_id) references schools(id);
alter table user_roles add constraint fk_user_roles_granted_by foreign key (granted_by) references users(id);

alter table user_invitations add constraint fk_user_invitations_school foreign key (school_id) references schools(id);
alter table user_invitations add constraint fk_user_invitations_invited_by foreign key (invited_by) references users(id);
alter table user_invitations add constraint fk_user_invitations_accepted_by foreign key (accepted_by) references users(id);

alter table sessions add constraint fk_sessions_user foreign key (user_id) references users(id);
alter table sessions add constraint fk_sessions_active_school foreign key (active_school_id) references schools(id);

alter table trusted_devices add constraint fk_trusted_devices_user foreign key (user_id) references users(id);

alter table parent_binding_codes add constraint fk_parent_binding_codes_school foreign key (school_id) references schools(id);
alter table parent_binding_codes add constraint fk_parent_binding_codes_student foreign key (student_id) references users(id);
alter table parent_binding_codes add constraint fk_parent_binding_codes_issued_by foreign key (issued_by) references users(id);
alter table parent_binding_codes add constraint fk_parent_binding_codes_redeemed_by foreign key (redeemed_by) references users(id);
alter table parent_binding_codes add constraint fk_parent_binding_codes_revoked_by foreign key (revoked_by) references users(id);

alter table otp_codes add constraint fk_otp_codes_user foreign key (user_id) references users(id);
alter table otp_codes add constraint fk_otp_codes_parent_binding_code foreign key (parent_binding_code_id) references parent_binding_codes(id);

alter table audit_logs add constraint fk_audit_logs_school foreign key (school_id) references schools(id);
alter table audit_logs add constraint fk_audit_logs_user foreign key (user_id) references users(id);

alter table parent_links add constraint fk_parent_links_student foreign key (student_id) references users(id);
alter table parent_links add constraint fk_parent_links_parent foreign key (parent_id) references users(id);
alter table parent_links add constraint fk_parent_links_binding_code foreign key (binding_code_id) references parent_binding_codes(id);
alter table parent_links add constraint fk_parent_links_first_reviewed_by foreign key (first_reviewed_by) references users(id);
alter table parent_links add constraint fk_parent_links_approved_by foreign key (approved_by) references users(id);
alter table parent_links add constraint fk_parent_links_rejected_by foreign key (rejected_by) references users(id);
alter table parent_links add constraint fk_parent_links_second_approved_by foreign key (second_approved_by) references users(id);

alter table consent_policies add constraint fk_consent_policies_school foreign key (school_id) references schools(id);
alter table consent_policies add constraint fk_consent_policies_created_by foreign key (created_by) references users(id);

alter table consents add constraint fk_consents_parent_link foreign key (parent_link_id) references parent_links(id);
alter table consents add constraint fk_consents_policy foreign key (policy_id) references consent_policies(id);
alter table consents add constraint fk_consents_granted_by foreign key (granted_by) references users(id);

alter table consent_events add constraint fk_consent_events_consent foreign key (consent_id) references consents(id);
alter table consent_events add constraint fk_consent_events_policy foreign key (policy_id) references consent_policies(id);
alter table consent_events add constraint fk_consent_events_actor foreign key (actor_id) references users(id);

alter table courses add constraint fk_courses_school foreign key (school_id) references schools(id);
alter table courses add constraint fk_courses_term foreign key (term_id) references terms(id);
alter table courses add constraint fk_courses_created_by foreign key (created_by) references users(id);

alter table course_teachers add constraint fk_course_teachers_course foreign key (course_id) references courses(id);
alter table course_teachers add constraint fk_course_teachers_teacher foreign key (teacher_id) references users(id);

alter table course_students add constraint fk_course_students_course foreign key (course_id) references courses(id);
alter table course_students add constraint fk_course_students_student foreign key (student_id) references users(id);
alter table course_students add constraint fk_course_students_enrolled_by foreign key (enrolled_by) references users(id);

alter table assignments add constraint fk_assignments_course foreign key (course_id) references courses(id);
alter table assignments add constraint fk_assignments_rubric foreign key (rubric_id) references rubrics(id);
alter table assignments add constraint fk_assignments_created_by foreign key (created_by) references users(id);

alter table student_groups add constraint fk_student_groups_course foreign key (course_id) references courses(id);
alter table student_groups add constraint fk_student_groups_assignment foreign key (assignment_id) references assignments(id);
alter table student_groups add constraint fk_student_groups_created_by foreign key (created_by) references users(id);

alter table group_members add constraint fk_group_members_group foreign key (group_id) references student_groups(id);
alter table group_members add constraint fk_group_members_student foreign key (student_id) references users(id);

alter table devices add constraint fk_devices_school foreign key (school_id) references schools(id);
alter table devices add constraint fk_devices_registered_by foreign key (registered_by) references users(id);

alter table lessons add constraint fk_lessons_course foreign key (course_id) references courses(id);
alter table lessons add constraint fk_lessons_created_by foreign key (created_by) references users(id);

alter table lesson_materials add constraint fk_lesson_materials_lesson foreign key (lesson_id) references lessons(id);

alter table lesson_sensor_links add constraint fk_lesson_sensor_links_lesson foreign key (lesson_id) references lessons(id);
alter table lesson_sensor_links add constraint fk_lesson_sensor_links_device foreign key (device_id) references devices(id);

alter table lesson_progress add constraint fk_lesson_progress_lesson foreign key (lesson_id) references lessons(id);
alter table lesson_progress add constraint fk_lesson_progress_student foreign key (student_id) references users(id);

alter table assignment_sensor_datasets add constraint fk_assignment_sensor_datasets_assignment foreign key (assignment_id) references assignments(id);
alter table assignment_sensor_datasets add constraint fk_assignment_sensor_datasets_device foreign key (device_id) references devices(id);

alter table submissions add constraint fk_submissions_assignment foreign key (assignment_id) references assignments(id);
alter table submissions add constraint fk_submissions_student foreign key (student_id) references users(id);
alter table submissions add constraint fk_submissions_group foreign key (group_id) references student_groups(id);

alter table submission_versions add constraint fk_submission_versions_submission foreign key (submission_id) references submissions(id);
alter table submission_versions add constraint fk_submission_versions_submitted_by foreign key (submitted_by) references users(id);

alter table charts add constraint fk_charts_created_by foreign key (created_by) references users(id);
alter table charts add constraint fk_charts_course foreign key (course_id) references courses(id);
alter table charts add constraint fk_charts_device foreign key (device_id) references devices(id);

alter table submission_attachments add constraint fk_submission_attachments_submission_version foreign key (submission_version_id) references submission_versions(id);
alter table submission_attachments add constraint fk_submission_attachments_dataset foreign key (dataset_id) references assignment_sensor_datasets(id);
alter table submission_attachments add constraint fk_submission_attachments_chart foreign key (chart_id) references charts(id);

alter table feedbacks add constraint fk_feedbacks_submission foreign key (submission_id) references submissions(id);
alter table feedbacks add constraint fk_feedbacks_author foreign key (author_id) references users(id);

alter table rubrics add constraint fk_rubrics_school foreign key (school_id) references schools(id);
alter table rubrics add constraint fk_rubrics_created_by foreign key (created_by) references users(id);

alter table rubric_criteria add constraint fk_rubric_criteria_rubric foreign key (rubric_id) references rubrics(id);

alter table quizzes add constraint fk_quizzes_course foreign key (course_id) references courses(id);
alter table quizzes add constraint fk_quizzes_lesson foreign key (lesson_id) references lessons(id);
alter table quizzes add constraint fk_quizzes_created_by foreign key (created_by) references users(id);

alter table quiz_questions add constraint fk_quiz_questions_quiz foreign key (quiz_id) references quizzes(id);

alter table quiz_choices add constraint fk_quiz_choices_question foreign key (question_id) references quiz_questions(id);

alter table quiz_attempts add constraint fk_quiz_attempts_quiz foreign key (quiz_id) references quizzes(id);
alter table quiz_attempts add constraint fk_quiz_attempts_student foreign key (student_id) references users(id);

alter table quiz_answers add constraint fk_quiz_answers_attempt foreign key (attempt_id) references quiz_attempts(id);
alter table quiz_answers add constraint fk_quiz_answers_question foreign key (question_id) references quiz_questions(id);

alter table grades add constraint fk_grades_student foreign key (student_id) references users(id);
alter table grades add constraint fk_grades_course foreign key (course_id) references courses(id);
alter table grades add constraint fk_grades_submission foreign key (submission_id) references submissions(id);
alter table grades add constraint fk_grades_quiz_attempt foreign key (quiz_attempt_id) references quiz_attempts(id);
alter table grades add constraint fk_grades_graded_by foreign key (graded_by) references users(id);
alter table grades add constraint fk_grades_coi_reviewed_by foreign key (coi_reviewed_by) references users(id);
alter table grades add constraint fk_grades_confirmed_by foreign key (confirmed_by) references users(id);

alter table grade_criterion_scores add constraint fk_grade_criterion_scores_grade foreign key (grade_id) references grades(id);
alter table grade_criterion_scores add constraint fk_grade_criterion_scores_criterion foreign key (criterion_id) references rubric_criteria(id);

alter table device_heartbeats add constraint fk_device_heartbeats_device foreign key (device_id) references devices(id);

alter table sensor_readings add constraint fk_sensor_readings_device foreign key (device_id) references devices(id);

alter table thresholds add constraint fk_thresholds_school foreign key (school_id) references schools(id);
alter table thresholds add constraint fk_thresholds_device foreign key (device_id) references devices(id);
alter table thresholds add constraint fk_thresholds_created_by foreign key (created_by) references users(id);

alter table sensor_alerts add constraint fk_sensor_alerts_threshold foreign key (threshold_id) references thresholds(id);
alter table sensor_alerts add constraint fk_sensor_alerts_device foreign key (device_id) references devices(id);
alter table sensor_alerts add constraint fk_sensor_alerts_acknowledged_by foreign key (acknowledged_by) references users(id);

alter table emergency_events add constraint fk_emergency_events_school foreign key (school_id) references schools(id);
alter table emergency_events add constraint fk_emergency_events_device foreign key (source_device_id) references devices(id);
alter table emergency_events add constraint fk_emergency_events_acknowledged_by foreign key (acknowledged_by) references users(id);

alter table security_events add constraint fk_security_events_school foreign key (school_id) references schools(id);
alter table security_events add constraint fk_security_events_camera foreign key (camera_device_id) references devices(id);
alter table security_events add constraint fk_security_events_reviewed_by foreign key (reviewed_by) references users(id);

alter table camera_access_grants add constraint fk_camera_access_grants_school foreign key (school_id) references schools(id);
alter table camera_access_grants add constraint fk_camera_access_grants_user foreign key (user_id) references users(id);
alter table camera_access_grants add constraint fk_camera_access_grants_camera foreign key (camera_device_id) references devices(id);
alter table camera_access_grants add constraint fk_camera_access_grants_granted_by foreign key (granted_by) references users(id);

alter table notifications add constraint fk_notifications_user foreign key (user_id) references users(id);
