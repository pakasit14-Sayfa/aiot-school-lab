# Database Schema (live dump from local Supabase, regenerated 2026-08-25;
# RPC list manually updated 2026-08-26 for the 3 new school_admin bulk-import
# functions plus one pre-existing gap, and manually updated three more times
# on 2026-08-27 — once for the new quiz_question_attachments table + its 3
# RPCs, once for courses.join_code + its 2 RPCs / a renamed function / the
# new _check_threshold_violations pg_cron job, once for submission_
# attachments finally getting an RPC layer (file_name column + 3 RPCs) —
# a full re-dump wasn't re-run for any of these since they were small,
# additive changes)

Total tables: 83 (+ 2 views: alerts, profiles)

Most tables (`my_first_app`'s own domain) have Row-Level Security enabled with **zero policies** — nothing is reachable directly via PostgREST except through explicit grants. Every read/write goes through a `SECURITY DEFINER` RPC function (see RPC list below) or an Edge Function. Clients call `supabase.rpc('fn_name', {...})`, never `.from('table').select()` directly.

**Exception**: `devices`, `schools`, `thresholds`, `school_settings`, `device_commands`, `device_logs`, `control_approval_requests`, `sensor_readings`, `users`, `user_roles` also carry real `authenticated`-role RLS policies for `aiot_dev_dashboard` (a second app, real Supabase Auth, outside this repo) — each has a school-membership check (`school_id = get_auth_school_id()`) *and*, for writes, a role check (`has_role('school_admin')`/`'technician'`/etc). Both checks matter: a policy with only the school check was a real, fixed vulnerability (any authenticated school member had school_admin-level write access) — see HANDOFF.md's 2026-08-24 section before adding a new policy on any of these tables.

`profiles` and `alerts` are **views** added for `aiot_dev_dashboard` compatibility (over `users`/`sensor_alerts`) — views run with the view owner's privileges by default and bypass the underlying tables' RLS, so their own grants matter independently (currently `authenticated` only, `anon` was revoked after a leak was found and fixed).


## academic_years

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| name | character varying | NO |  |
| start_date | date | YES |  |
| end_date | date | YES |  |

Foreign keys:
- `school_id` → `schools.id`

## alerts (view)

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | YES |  |
| school_id | uuid | YES |  |
| device_id | uuid | YES |  |
| alert_type | text | YES |  |
| title | text | YES |  |
| message | text | YES |  |
| severity | text | YES |  |
| status | text | YES |  |
| created_at | timestamp with time zone | YES |  |

## assignment_sensor_datasets

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| assignment_id | uuid | NO |  |
| device_id | uuid | NO |  |
| metric | USER-DEFINED | NO |  |
| time_start | timestamp with time zone | YES |  |
| time_end | timestamp with time zone | YES |  |
| label | character varying | YES |  |

Foreign keys:
- `assignment_id` → `assignments.id`
- `device_id` → `devices.id`

## assignments

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| course_id | uuid | NO |  |
| type | USER-DEFINED | NO |  |
| title | character varying | NO |  |
| instructions | text | YES |  |
| due_at | timestamp with time zone | YES |  |
| is_group | boolean | YES | false |
| rubric_id | uuid | YES |  |
| status | USER-DEFINED | NO | 'draft'::publish_status |
| created_by | uuid | NO |  |
| created_at | timestamp with time zone | YES | now() |

Foreign keys:
- `course_id` → `courses.id`
- `created_by` → `users.id`
- `rubric_id` → `rubrics.id`

## attendance_records

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| course_id | uuid | NO |  |
| student_id | uuid | NO |  |
| class_date | date | NO |  |
| status | text | NO |  |
| marked_by | uuid | NO |  |
| marked_at | timestamp with time zone | NO | now() |
| note | text | YES |  |

Foreign keys:
- `course_id` → `courses.id`
- `marked_by` → `users.id`
- `student_id` → `users.id`

## audit_logs

| column | type | nullable | default |
|---|---|---|---|
| id | bigint | NO | nextval('audit_logs_id_seq'::regclass) |
| school_id | uuid | YES |  |
| user_id | uuid | YES |  |
| acted_role | USER-DEFINED | YES |  |
| action | character varying | NO |  |
| entity_type | character varying | YES |  |
| entity_id | character varying | YES |  |
| details | jsonb | YES |  |
| ip_address | character varying | YES |  |
| created_at | timestamp with time zone | YES | now() |

Foreign keys:
- `school_id` → `schools.id`
- `user_id` → `users.id`

## auth_login_ip_rate_limits

| column | type | nullable | default |
|---|---|---|---|
| ip_hash | text | NO |  |
| window_started_at | timestamp with time zone | NO | now() |
| attempt_count | integer | NO | 0 |
| blocked_until | timestamp with time zone | YES |  |
| last_attempt_at | timestamp with time zone | NO | now() |

## auth_login_rate_limits

| column | type | nullable | default |
|---|---|---|---|
| email_hash | text | NO |  |
| window_started_at | timestamp with time zone | NO | now() |
| attempt_count | integer | NO | 0 |
| blocked_until | timestamp with time zone | YES |  |
| last_attempt_at | timestamp with time zone | NO | now() |

## auth_security_constants

| column | type | nullable | default |
|---|---|---|---|
| singleton | boolean | NO | true |
| dummy_password_hash | text | NO |  |

## buildings

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| name | text | NO |  |
| code | text | YES |  |
| floors | integer | YES | 1 |
| manager_name | text | YES |  |
| note | text | YES |  |
| status | text | YES | 'active'::text |
| created_at | timestamp with time zone | YES | now() |
| updated_at | timestamp with time zone | YES | now() |

Foreign keys:
- `school_id` → `schools.id`

## camera_access_grants

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| user_id | uuid | NO |  |
| camera_device_id | uuid | YES |  |
| granted_by | uuid | NO |  |
| reason | text | NO |  |
| valid_from | timestamp with time zone | NO | now() |
| valid_until | timestamp with time zone | NO |  |
| granted_at | timestamp with time zone | YES | now() |
| revoked_at | timestamp with time zone | YES |  |

Foreign keys:
- `camera_device_id` → `devices.id`
- `granted_by` → `users.id`
- `school_id` → `schools.id`
- `user_id` → `users.id`

## charts

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| created_by | uuid | NO |  |
| course_id | uuid | YES |  |
| chart_type | USER-DEFINED | NO |  |
| device_id | uuid | NO |  |
| metric | USER-DEFINED | NO |  |
| time_start | timestamp with time zone | NO |  |
| time_end | timestamp with time zone | NO |  |
| compare_time_start | timestamp with time zone | YES |  |
| compare_time_end | timestamp with time zone | YES |  |
| config | jsonb | YES |  |
| annotation | text | YES |  |
| created_at | timestamp with time zone | YES | now() |

Foreign keys:
- `course_id` → `courses.id`
- `created_by` → `users.id`
- `device_id` → `devices.id`

## class_schedules

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| course_id | uuid | NO |  |
| day_of_week | smallint | NO |  |
| start_time | time without time zone | NO |  |
| end_time | time without time zone | NO |  |
| room | character varying | YES |  |
| created_by | uuid | NO |  |
| created_at | timestamp with time zone | NO | now() |

Foreign keys:
- `course_id` → `courses.id`
- `created_by` → `users.id`

## consent_events

| column | type | nullable | default |
|---|---|---|---|
| id | bigint | NO | nextval('consent_events_id_seq'::regclass) |
| consent_id | uuid | NO |  |
| policy_id | uuid | NO |  |
| actor_id | uuid | NO |  |
| action | USER-DEFINED | NO |  |
| evidence | jsonb | NO |  |
| occurred_at | timestamp with time zone | NO | now() |

Foreign keys:
- `actor_id` → `users.id`
- `consent_id` → `consents.id`
- `policy_id` → `consent_policies.id`

## consent_policies

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | YES |  |
| consent_type | character varying | NO |  |
| version | character varying | NO |  |
| document_hash | character varying | NO |  |
| content_url | character varying | NO |  |
| effective_at | timestamp with time zone | NO |  |
| retired_at | timestamp with time zone | YES |  |
| created_by | uuid | NO |  |
| is_required | boolean | NO | false |

Foreign keys:
- `created_by` → `users.id`
- `school_id` → `schools.id`

## consents

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| parent_link_id | uuid | NO |  |
| policy_id | uuid | NO |  |
| status | USER-DEFINED | NO | 'granted'::consent_status |
| granted_by | uuid | NO |  |
| granted_at | timestamp with time zone | NO | now() |
| withdrawn_at | timestamp with time zone | YES |  |
| evidence_hash | character varying | NO |  |
| details | jsonb | NO |  |

Foreign keys:
- `granted_by` → `users.id`
- `parent_link_id` → `parent_links.id`
- `policy_id` → `consent_policies.id`

## control_approval_requests

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | YES |  |
| device_id | uuid | YES |  |
| command | text | NO |  |
| requested_by | uuid | YES |  |
| status | text | NO | 'pending'::text |
| reviewed_by | uuid | YES |  |
| reviewed_at | timestamp with time zone | YES |  |
| notes | text | YES |  |
| created_at | timestamp with time zone | YES | now() |

Foreign keys:
- `device_id` → `devices.id`
- `requested_by` → `users.id`
- `reviewed_by` → `users.id`
- `school_id` → `schools.id`

## course_files

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| course_id | uuid | NO |  |
| uploaded_by | uuid | NO |  |
| storage_path | text | NO |  |
| file_name | character varying | NO |  |
| size_bytes | bigint | NO |  |
| created_at | timestamp with time zone | NO | now() |

Foreign keys:
- `course_id` → `courses.id`
- `uploaded_by` → `users.id`

## course_post_replies

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| post_id | uuid | NO |  |
| author_id | uuid | NO |  |
| body | text | NO |  |
| created_at | timestamp with time zone | NO | now() |

Foreign keys:
- `author_id` → `users.id`
- `post_id` → `course_posts.id`

## course_posts

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| course_id | uuid | NO |  |
| author_id | uuid | NO |  |
| body | text | NO |  |
| is_pinned | boolean | NO | false |
| created_at | timestamp with time zone | NO | now() |

Foreign keys:
- `author_id` → `users.id`
- `course_id` → `courses.id`

## course_students

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| course_id | uuid | NO |  |
| student_id | uuid | NO |  |
| enrolled_by | uuid | YES |  |
| enrolled_at | timestamp with time zone | YES | now() |

Foreign keys:
- `course_id` → `courses.id`
- `enrolled_by` → `users.id`
- `student_id` → `users.id`

## course_teachers

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| course_id | uuid | NO |  |
| teacher_id | uuid | NO |  |
| is_owner | boolean | YES | true |

Foreign keys:
- `course_id` → `courses.id`
- `teacher_id` → `users.id`

## courses

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| term_id | uuid | NO |  |
| subject_name | character varying | NO |  |
| grade_level | character varying | YES |  |
| room | character varying | YES |  |
| description | text | YES |  |
| status | USER-DEFINED | NO | 'active'::course_status |
| closed_at | timestamp with time zone | YES |  |
| created_by | uuid | NO |  |
| created_at | timestamp with time zone | YES | now() |
| join_code | character varying | YES |  (unique) |

`join_code` added 2026-08-27 (`20260827010000_course_join_code.sql`) —
real, randomly-generated, unique per course; set on first call to
`get_or_create_course_join_code`, replaced by `regenerate_course_join_code`.
Was previously a client-computed, guessable, non-persisted string.

Foreign keys:
- `created_by` → `users.id`
- `school_id` → `schools.id`
- `term_id` → `terms.id`

## device_categories

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| name | text | NO |  |
| code | text | YES |  |
| description | text | YES |  |
| icon | text | YES |  |
| created_at | timestamp with time zone | YES | now() |

## device_command_rate_limits

| column | type | nullable | default |
|---|---|---|---|
| device_id | uuid | NO |  |
| window_started_at | timestamp with time zone | NO | now() |
| attempt_count | integer | NO | 1 |
| blocked_until | timestamp with time zone | YES |  |

Foreign keys:
- `device_id` → `devices.id`

## device_commands

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| device_id | uuid | NO |  |
| command | jsonb | NO |  |
| created_by | uuid | NO |  |
| created_at | timestamp with time zone | YES | now() |
| delivered_at | timestamp with time zone | YES |  |

Foreign keys:
- `device_id` → `devices.id`

## device_heartbeats

| column | type | nullable | default |
|---|---|---|---|
| id | bigint | NO | nextval('device_heartbeats_id_seq'::regclass) |
| device_id | uuid | NO |  |
| ts | timestamp with time zone | NO | now() |
| status | USER-DEFINED | NO |  |
| details | jsonb | YES |  |

Foreign keys:
- `device_id` → `devices.id`

## device_logs

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| device_id | uuid | YES |  |
| school_id | uuid | YES |  |
| event_type | text | NO |  |
| message | text | YES |  |
| metadata | jsonb | YES | '{}'::jsonb |
| created_at | timestamp with time zone | YES | now() |

Foreign keys:
- `device_id` → `devices.id`
- `school_id` → `schools.id`

## device_schedules

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| device_id | uuid | NO |  |
| school_id | uuid | NO |  |
| label | text | YES |  |
| command | jsonb | NO |  |
| days_of_week | ARRAY | NO |  |
| time_of_day | time without time zone | NO |  |
| enabled | boolean | NO | true |
| created_by | uuid | NO |  |
| created_at | timestamp with time zone | NO | now() |
| last_triggered_at | timestamp with time zone | YES |  |

Foreign keys:
- `created_by` → `users.id`
- `device_id` → `devices.id`
- `school_id` → `schools.id`

## devices

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| type | USER-DEFINED | NO |  |
| name | character varying | NO |  |
| serial_no | character varying | YES |  |
| location | character varying | YES |  |
| kit_code | character varying | YES |  |
| status | USER-DEFINED | NO | 'offline'::device_status |
| registered_by | uuid | NO |  |
| registered_at | timestamp with time zone | YES | now() |
| token_hash | character varying | YES |  |
| token_issued_at | timestamp with time zone | YES |  |
| course_id | uuid | YES |  |
| category_code | text | YES |  |
| device_code | text | YES |  |
| building | text | YES |  |
| room | text | YES |  |
| metadata | jsonb | YES | '{}'::jsonb |
| updated_at | timestamp with time zone | YES | now() |
| last_seen_at | timestamp with time zone | YES | now() |
| ip_address | text | YES | '192.168.1.100'::text |
| firmware_version | text | YES | 'v1.2.0-prod'::text |

Foreign keys:
- `course_id` → `courses.id`
- `registered_by` → `users.id`
- `school_id` → `schools.id`

## emergency_events

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| source_device_id | uuid | YES |  |
| location | character varying | YES |  |
| triggered_at | timestamp with time zone | YES | now() |
| status | USER-DEFINED | NO | 'new'::emergency_status |
| warning_light_on | boolean | YES | false |
| acknowledged_by | uuid | YES |  |
| acknowledged_at | timestamp with time zone | YES |  |
| closed_at | timestamp with time zone | YES |  |
| review_note | text | YES |  |

Foreign keys:
- `acknowledged_by` → `users.id`
- `source_device_id` → `devices.id`
- `school_id` → `schools.id`

## feedbacks

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| submission_id | uuid | NO |  |
| author_id | uuid | NO |  |
| body | text | NO |  |
| created_at | timestamp with time zone | YES | now() |

Foreign keys:
- `author_id` → `users.id`
- `submission_id` → `submissions.id`

## g_score_entries

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| student_id | uuid | NO |  |
| course_id | uuid | NO |  |
| source | USER-DEFINED | NO |  |
| source_id | uuid | NO |  |
| points | numeric | NO |  |
| status | USER-DEFINED | NO | 'pending'::g_score_status |
| created_at | timestamp with time zone | NO | now() |
| confirmed_by | uuid | YES |  |
| confirmed_at | timestamp with time zone | YES |  |

Foreign keys:
- `confirmed_by` → `users.id`
- `course_id` → `courses.id`
- `student_id` → `users.id`

## gateway_request_nonces

| column | type | nullable | default |
|---|---|---|---|
| gateway_id | uuid | NO |  |
| nonce | character varying | NO |  |
| used_at | timestamp with time zone | NO | now() |

Foreign keys:
- `gateway_id` → `devices.id`

## grade_criterion_scores

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| grade_id | uuid | NO |  |
| criterion_id | uuid | NO |  |
| score | numeric | NO |  |
| feedback | text | YES |  |

Foreign keys:
- `criterion_id` → `rubric_criteria.id`
- `grade_id` → `grades.id`

## grades

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| student_id | uuid | NO |  |
| course_id | uuid | NO |  |
| source_type | USER-DEFINED | NO |  |
| submission_id | uuid | YES |  |
| quiz_attempt_id | uuid | YES |  |
| score | numeric | YES |  |
| max_score | numeric | YES |  |
| status | USER-DEFINED | NO | 'draft'::grade_status |
| graded_by | uuid | YES |  |
| graded_at | timestamp with time zone | YES | now() |
| coi_flag | boolean | NO | false |
| coi_detected_at | timestamp with time zone | YES |  |
| coi_review_status | USER-DEFINED | YES |  |
| coi_reviewed_by | uuid | YES |  |
| coi_reviewed_at | timestamp with time zone | YES |  |
| confirmed_by | uuid | YES |  |
| confirmed_at | timestamp with time zone | YES |  |
| assignment_id | uuid | YES |  |

Foreign keys:
- `coi_reviewed_by` → `users.id`
- `confirmed_by` → `users.id`
- `course_id` → `courses.id`
- `graded_by` → `users.id`
- `quiz_attempt_id` → `quiz_attempts.id`
- `student_id` → `users.id`
- `submission_id` → `submissions.id`
- `assignment_id` → `assignments.id`

## group_members

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| group_id | uuid | NO |  |
| student_id | uuid | NO |  |

Foreign keys:
- `group_id` → `student_groups.id`
- `student_id` → `users.id`

## homeroom_assignments

Added 2026-08-27 (`20260827060000_homeroom_attendance_system.sql`) — which
teacher is the homeroom/advisory teacher (ครูประจำชั้น) of a given
grade_level+room for a given academic year. Previously this had no real
backend at all (`school_admin`'s "ครูประจำชั้น" field was a fake local-only
value).

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| academic_year_id | uuid | NO |  |
| grade_level | varchar | NO |  |
| room | varchar | NO |  |
| teacher_id | uuid | NO |  |
| created_by | uuid | NO |  |
| created_at | timestamptz | NO | now() |

Unique: `(academic_year_id, grade_level, room, teacher_id)` — allows more
than one co-homeroom-teacher per room, but not a duplicate row for the same
teacher+room.

Foreign keys:
- `school_id` → `schools.id`
- `academic_year_id` → `academic_years.id`
- `teacher_id` → `users.id`
- `created_by` → `users.id`

## homeroom_attendance_records

Added 2026-08-27 (`20260827060000_homeroom_attendance_system.sql`) —
per-room (not per-course) daily attendance, alongside the pre-existing
`attendance_records` (course-scoped). Same status vocabulary.

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| student_id | uuid | NO |  |
| academic_year_id | uuid | NO |  |
| grade_level | varchar | NO |  |
| room | varchar | NO |  |
| class_date | date | NO |  |
| status | text | NO | (check: present/late/absent/excused) |
| marked_by | uuid | NO |  |
| marked_at | timestamptz | NO | now() |
| note | text | YES |  |

Unique: `(student_id, class_date)` — one homeroom attendance record per
student per day.

Foreign keys:
- `student_id` → `users.id`
- `academic_year_id` → `academic_years.id`
- `marked_by` → `users.id`

## incident_actions

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| incident_report_id | uuid | NO |  |
| actor_id | uuid | NO |  |
| action_type | character varying | NO |  |
| note | text | YES |  |
| created_at | timestamp with time zone | NO | now() |

Foreign keys:
- `actor_id` → `users.id`
- `incident_report_id` → `incident_reports.id`

## incident_reports

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| reporter_student_id | uuid | NO |  |
| category | USER-DEFINED | NO |  |
| room | character varying | YES |  |
| status | USER-DEFINED | NO | 'new'::incident_status |
| acknowledged_by | uuid | YES |  |
| acknowledged_at | timestamp with time zone | YES |  |
| assigned_to | uuid | YES |  |
| escalated_to_emergency_event_id | uuid | YES |  |
| resolution_type | USER-DEFINED | YES |  |
| resolution_note | text | YES |  |
| closed_by | uuid | YES |  |
| closed_at | timestamp with time zone | YES |  |
| created_at | timestamp with time zone | NO | now() |
| reason | text | YES |  |
| severity | text | YES |  |

Foreign keys:
- `acknowledged_by` → `users.id`
- `assigned_to` → `users.id`
- `closed_by` → `users.id`
- `escalated_to_emergency_event_id` → `emergency_events.id`
- `reporter_student_id` → `users.id`
- `school_id` → `schools.id`

## learning_items

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| training_set | text | NO |  |
| type | text | NO |  |
| title | text | NO |  |
| description | text | YES |  |
| difficulty | text | YES |  |
| duration_minutes | integer | YES |  |
| points | integer | YES | 0 |
| link | text | YES |  |
| published | boolean | NO | false |
| publish_to_all_schools | boolean | NO | true |
| published_school_ids | ARRAY | YES | '{}'::uuid[] |
| created_by | uuid | YES |  |
| created_at | timestamp with time zone | YES | now() |
| updated_at | timestamp with time zone | YES | now() |

Foreign keys:
- `created_by` → `users.id`

## learning_simulators

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| training_set | text | NO |  |
| name | text | NO |  |
| url | text | NO |  |
| description | text | YES |  |
| auto_check | boolean | NO | false |
| created_by | uuid | YES |  |
| created_at | timestamp with time zone | YES | now() |
| updated_at | timestamp with time zone | YES | now() |

Foreign keys:
- `created_by` → `users.id`

## lesson_materials

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| lesson_id | uuid | NO |  |
| type | USER-DEFINED | NO |  |
| title | character varying | YES |  |
| url | character varying | NO |  |
| sort_order | integer | YES | 0 |

Foreign keys:
- `lesson_id` → `lessons.id`

## lesson_progress

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| lesson_id | uuid | NO |  |
| student_id | uuid | NO |  |
| progress_pct | numeric | YES | 0 |
| completed | boolean | YES | false |
| completed_at | timestamp with time zone | YES |  |
| updated_at | timestamp with time zone | YES |  |

Foreign keys:
- `lesson_id` → `lessons.id`
- `student_id` → `users.id`

## lesson_sensor_links

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| lesson_id | uuid | NO |  |
| device_id | uuid | NO |  |
| metric | USER-DEFINED | NO |  |
| time_start | timestamp with time zone | YES |  |
| time_end | timestamp with time zone | YES |  |
| caption | character varying | YES |  |

Foreign keys:
- `device_id` → `devices.id`
- `lesson_id` → `lessons.id`

## lessons

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| course_id | uuid | NO |  |
| title | character varying | NO |  |
| content | jsonb | YES |  |
| status | USER-DEFINED | NO | 'draft'::lesson_status |
| published_at | timestamp with time zone | YES |  |
| created_by | uuid | NO |  |
| updated_at | timestamp with time zone | YES |  |

Foreign keys:
- `course_id` → `courses.id`
- `created_by` → `users.id`

## notifications

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| user_id | uuid | NO |  |
| type | character varying | NO |  |
| title | character varying | NO |  |
| body | text | YES |  |
| payload | jsonb | YES |  |
| created_at | timestamp with time zone | YES | now() |
| read_at | timestamp with time zone | YES |  |

Foreign keys:
- `user_id` → `users.id`

## operational_alerts

| column | type | nullable | default |
|---|---|---|---|
| id | bigint | NO | nextval('operational_alerts_id_seq'::regclass) |
| category | character varying | NO |  |
| severity | character varying | NO |  |
| details | jsonb | NO | '{}'::jsonb |
| created_at | timestamp with time zone | NO | now() |
| resolved_at | timestamp with time zone | YES |  |

## otp_codes

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| user_id | uuid | YES |  |
| parent_binding_code_id | uuid | YES |  |
| purpose | USER-DEFINED | NO |  |
| code_hash | character varying | NO |  |
| sent_to_email | character varying | NO |  |
| attempt_count | integer | NO | 0 |
| locked_until | timestamp with time zone | YES |  |
| last_sent_at | timestamp with time zone | NO | now() |
| expires_at | timestamp with time zone | NO |  |
| used_at | timestamp with time zone | YES |  |
| verification_token_hash | character varying | YES |  |
| login_role | USER-DEFINED | YES |  |
| login_school_id | uuid | YES |  |
| login_device_info | character varying | YES |  |
| login_ip_address | character varying | YES |  |

Foreign keys:
- `login_school_id` → `schools.id`
- `parent_binding_code_id` → `parent_binding_codes.id`
- `user_id` → `users.id`

## packages

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| name | character varying | NO |  |
| license_type | USER-DEFINED | NO | 'perpetual'::license_type |
| enabled_modules | jsonb | YES |  |
| max_users | integer | YES |  |
| created_at | timestamp with time zone | YES | now() |

## parent_binding_codes

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| student_id | uuid | NO |  |
| code_hash | character varying | NO |  |
| code_hint | character varying | YES |  |
| status | USER-DEFINED | NO | 'issued'::binding_code_status |
| expires_at | timestamp with time zone | NO |  |
| issued_by | uuid | NO |  |
| issued_at | timestamp with time zone | NO | now() |
| redeemed_by | uuid | YES |  |
| redeemed_at | timestamp with time zone | YES |  |
| revoked_by | uuid | YES |  |
| revoked_at | timestamp with time zone | YES |  |
| revoke_reason | text | YES |  |

Foreign keys:
- `issued_by` → `users.id`
- `redeemed_by` → `users.id`
- `revoked_by` → `users.id`
- `school_id` → `schools.id`
- `student_id` → `users.id`

## parent_links

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| student_id | uuid | NO |  |
| parent_id | uuid | NO |  |
| relationship | character varying | NO |  |
| binding_code_id | uuid | NO |  |
| status | USER-DEFINED | NO | 'pending'::binding_status |
| requested_at | timestamp with time zone | YES | now() |
| first_reviewed_by | uuid | YES |  |
| first_reviewed_at | timestamp with time zone | YES |  |
| approved_by | uuid | YES |  |
| approved_at | timestamp with time zone | YES |  |
| rejected_by | uuid | YES |  |
| rejected_at | timestamp with time zone | YES |  |
| rejection_reason | text | YES |  |
| coi_conflict | boolean | NO | false |
| exception_reason | text | YES |  |
| second_approved_by | uuid | YES |  |
| second_approved_at | timestamp with time zone | YES |  |

Foreign keys:
- `approved_by` → `users.id`
- `binding_code_id` → `parent_binding_codes.id`
- `first_reviewed_by` → `users.id`
- `parent_id` → `users.id`
- `rejected_by` → `users.id`
- `second_approved_by` → `users.id`
- `student_id` → `users.id`

## profiles (view)

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | YES |  |
| email | character varying | YES |  |
| full_name | text | YES |  |
| role | text | YES |  |
| is_active | boolean | YES |  |
| school_id | uuid | YES |  |
| created_at | timestamp with time zone | YES |  |
| updated_at | timestamp with time zone | YES |  |

## quiz_answers

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| attempt_id | uuid | NO |  |
| question_id | uuid | NO |  |
| answer | jsonb | YES |  |
| is_correct | boolean | YES |  |
| score | numeric | YES |  |

Foreign keys:
- `attempt_id` → `quiz_attempts.id`
- `question_id` → `quiz_questions.id`

## quiz_attempts

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| quiz_id | uuid | NO |  |
| student_id | uuid | NO |  |
| started_at | timestamp with time zone | YES | now() |
| submitted_at | timestamp with time zone | YES |  |
| auto_score | numeric | YES |  |

Foreign keys:
- `quiz_id` → `quizzes.id`
- `student_id` → `users.id`

## quiz_choices

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| question_id | uuid | NO |  |
| choice_text | text | NO |  |
| is_correct | boolean | YES | false |
| sort_order | integer | YES | 0 |

Foreign keys:
- `question_id` → `quiz_questions.id`

## quiz_questions

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| quiz_id | uuid | NO |  |
| type | USER-DEFINED | NO |  |
| question | text | NO |  |
| points | numeric | NO | 1 |
| sort_order | integer | YES | 0 |

Foreign keys:
- `quiz_id` → `quizzes.id`

## quiz_question_attachments

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| question_id | uuid | NO |  |
| type | USER-DEFINED | NO |  |
| storage_path | character varying | NO |  |
| file_name | character varying | YES |  |
| sort_order | integer | NO | 0 |
| created_at | timestamp with time zone | NO | now() |

Foreign keys:
- `question_id` → `quiz_questions.id` (on delete cascade)

`type` is the `quiz_attachment_type` enum (`image`, `video`). `storage_path`
resolves to a private-bucket (`quiz-attachments`) object via
`get_quiz_attachment_for_download` / the `quiz-attachment-download` Edge
Function — same signed-URL pattern as `lesson_materials`, added
2026-08-27.

## quizzes

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| course_id | uuid | NO |  |
| lesson_id | uuid | YES |  |
| type | USER-DEFINED | NO |  |
| title | character varying | NO |  |
| time_limit_min | integer | YES |  |
| status | USER-DEFINED | NO | 'draft'::publish_status |
| created_by | uuid | NO |  |

Foreign keys:
- `course_id` → `courses.id`
- `created_by` → `users.id`
- `lesson_id` → `lessons.id`

## role_selection_challenges

| column | type | nullable | default |
|---|---|---|---|
| token_hash | text | NO |  |
| user_id | uuid | NO |  |
| expires_at | timestamp with time zone | NO | (now() + '00:05:00'::interval) |
| used_at | timestamp with time zone | YES |  |
| created_at | timestamp with time zone | NO | now() |

Foreign keys:
- `user_id` → `users.id`

## rooms

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| building_id | uuid | YES |  |
| name | text | NO |  |
| code | text | YES |  |
| floor | text | YES |  |
| room_type | text | YES | 'classroom'::text |
| capacity | integer | YES | 30 |
| teacher_name | text | YES |  |
| status | text | YES | 'active'::text |
| created_at | timestamp with time zone | YES | now() |
| updated_at | timestamp with time zone | YES | now() |

Foreign keys:
- `building_id` → `buildings.id`
- `school_id` → `schools.id`

## rubric_criteria

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| rubric_id | uuid | NO |  |
| name | character varying | NO |  |
| description | text | YES |  |
| max_score | numeric | NO |  |
| levels | jsonb | YES |  |
| sort_order | integer | YES | 0 |

Foreign keys:
- `rubric_id` → `rubrics.id`

## rubrics

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| title | character varying | NO |  |
| description | text | YES |  |
| created_by | uuid | NO |  |

Foreign keys:
- `created_by` → `users.id`
- `school_id` → `schools.id`

## school_settings

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| electricity_rate_thb | numeric | YES |  |
| retention_policy | jsonb | YES |  |
| pdpa_camera_ready | boolean | NO | false |
| pdpa_camera_approved_by | uuid | YES |  |
| pdpa_camera_approved_at | timestamp with time zone | YES |  |
| water_rate_thb | numeric | YES |  |

Foreign keys:
- `pdpa_camera_approved_by` → `users.id`
- `school_id` → `schools.id`

## schools

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| package_id | uuid | NO |  |
| name | character varying | NO |  |
| school_code | character varying | NO |  |
| address | text | YES |  |
| contact_name | character varying | YES |  |
| contact_phone | character varying | YES |  |
| logo_url | character varying | YES |  |
| status | USER-DEFINED | YES | 'active'::user_status |
| created_at | timestamp with time zone | YES | now() |
| province | text | YES | 'กรุงเทพมหานคร'::text |
| admin_email | text | YES | 'schooladmin@aiot-school-lab.local'::text |
| package_name | text | YES | 'Pro Package'::text |
| license_expires_at | timestamp with time zone | YES | (now() + '365 days'::interval) |
| max_users | integer | YES | 500 |
| max_devices | integer | YES | 100 |
| updated_at | timestamp with time zone | YES | now() |

Foreign keys:
- `package_id` → `packages.id`

## security_events

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| camera_device_id | uuid | NO |  |
| event_type | character varying | NO | 'motion'::character varying |
| detected_at | timestamp with time zone | NO |  |
| metadata | jsonb | YES |  |
| clip_object_key | character varying | YES |  |
| status | USER-DEFINED | NO | 'pending_review'::security_event_status |
| reviewed_by | uuid | YES |  |
| reviewed_at | timestamp with time zone | YES |  |
| review_note | text | YES |  |
| retention_expires_at | timestamp with time zone | NO |  |
| purged_at | timestamp with time zone | YES |  |

Foreign keys:
- `camera_device_id` → `devices.id`
- `reviewed_by` → `users.id`
- `school_id` → `schools.id`

## sensor_alerts

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| threshold_id | uuid | NO |  |
| device_id | uuid | NO |  |
| metric | USER-DEFINED | NO |  |
| value | numeric | NO |  |
| triggered_at | timestamp with time zone | YES | now() |
| status | USER-DEFINED | NO | 'new'::alert_status |
| acknowledged_by | uuid | YES |  |
| acknowledged_at | timestamp with time zone | YES |  |

Foreign keys:
- `acknowledged_by` → `users.id`
- `device_id` → `devices.id`
- `threshold_id` → `thresholds.id`

## sensor_readings

| column | type | nullable | default |
|---|---|---|---|
| device_id | uuid | NO |  |
| metric | USER-DEFINED | NO |  |
| ts | timestamp with time zone | NO |  |
| value | numeric | NO |  |

Foreign keys:
- `device_id` → `devices.id`

## sessions

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| user_id | uuid | NO |  |
| active_role | USER-DEFINED | NO |  |
| active_school_id | uuid | YES |  |
| token_hash | character varying | NO |  |
| device_info | character varying | YES |  |
| ip_address | character varying | YES |  |
| created_at | timestamp with time zone | YES | now() |
| expires_at | timestamp with time zone | NO |  |
| revoked_at | timestamp with time zone | YES |  |

Foreign keys:
- `active_school_id` → `schools.id`
- `user_id` → `users.id`

## student_groups

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| course_id | uuid | NO |  |
| assignment_id | uuid | YES |  |
| name | character varying | NO |  |
| created_by | uuid | NO |  |
| created_at | timestamp with time zone | YES | now() |

Foreign keys:
- `assignment_id` → `assignments.id`
- `course_id` → `courses.id`
- `created_by` → `users.id`

## student_personal_tasks

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| student_id | uuid | NO |  |
| title | character varying | NO |  |
| note | text | YES |  |
| due_at | timestamp with time zone | YES |  |
| done | boolean | NO | false |
| created_at | timestamp with time zone | NO | now() |
| updated_at | timestamp with time zone | NO | now() |

Foreign keys:
- `student_id` → `users.id`

## student_profiles

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| student_id | uuid | NO |  |
| academic_year_id | uuid | NO |  |
| grade_level | character varying | NO |  |
| room | character varying | NO |  |
| created_by | uuid | NO |  |
| created_at | timestamp with time zone | NO | now() |

Foreign keys:
- `academic_year_id` → `academic_years.id`
- `created_by` → `users.id`
- `student_id` → `users.id`

## student_support_cases

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| student_id | uuid | NO |  |
| course_id | uuid | YES |  |
| category | text | NO | 'academic'::text |
| risk_level | text | NO | 'medium'::text |
| status | text | NO | 'open'::text |
| title | text | NO |  |
| notes | text | YES |  |
| created_by | uuid | NO |  |
| created_at | timestamp with time zone | NO | now() |
| updated_at | timestamp with time zone | NO | now() |

Foreign keys:
- `course_id` → `courses.id`
- `created_by` → `users.id`
- `school_id` → `schools.id`
- `student_id` → `users.id`

## student_support_interventions

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| case_id | uuid | NO |  |
| action_type | text | NO |  |
| notes | text | NO |  |
| recorded_by | uuid | NO |  |
| created_at | timestamp with time zone | NO | now() |

Foreign keys:
- `case_id` → `student_support_cases.id`
- `recorded_by` → `users.id`

## submission_attachments

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| submission_version_id | uuid | NO |  |
| type | USER-DEFINED | NO |  |
| file_url | character varying | YES |  |
| dataset_id | uuid | YES |  |
| chart_id | uuid | YES |  |
| file_name | character varying | YES |  |

`file_name` added 2026-08-27 (`20260827050000_submission_file_attachments.sql`)
alongside the RPC layer this table never had before that date. `type='file'`
rows store a real Storage path in `file_url` (resolved via
`get_submission_attachment_for_download` / the `submission-attachment-download`
Edge Function — same signed-URL pattern as `lesson_materials`/
`quiz_question_attachments`). The `sensor_dataset`/`chart` `type` values
remain unwired (a separate, never-built AIoT dataset/chart submission
mode) — only `file` has any RPC touching it.

Foreign keys:
- `chart_id` → `charts.id`
- `dataset_id` → `assignment_sensor_datasets.id`
- `submission_version_id` → `submission_versions.id`

## submission_versions

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| submission_id | uuid | NO |  |
| version | integer | NO |  |
| content | text | YES |  |
| submitted_by | uuid | NO |  |
| submitted_at | timestamp with time zone | YES | now() |

Foreign keys:
- `submission_id` → `submissions.id`
- `submitted_by` → `users.id`

## submissions

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| assignment_id | uuid | NO |  |
| student_id | uuid | YES |  |
| group_id | uuid | YES |  |
| status | USER-DEFINED | NO | 'submitted'::submission_status |
| current_version | integer | NO | 1 |
| submitted_at | timestamp with time zone | YES | now() |

Foreign keys:
- `assignment_id` → `assignments.id`
- `group_id` → `student_groups.id`
- `student_id` → `users.id`

## terminal_pairing_sessions

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| pairing_code | text | NO |  |
| terminal_name | text | YES |  |
| status | text | NO | 'pending'::text |
| session_token | text | YES |  |
| claimed_by_user_id | uuid | YES |  |
| created_at | timestamp with time zone | NO | now() |
| expires_at | timestamp with time zone | NO |  |

Foreign keys:
- `claimed_by_user_id` → `users.id`

## terms

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| academic_year_id | uuid | NO |  |
| name | character varying | NO |  |
| start_date | date | YES |  |
| end_date | date | YES |  |

Foreign keys:
- `academic_year_id` → `academic_years.id`

## thresholds

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| device_id | uuid | YES |  |
| metric | USER-DEFINED | NO |  |
| min_value | numeric | YES |  |
| max_value | numeric | YES |  |
| is_active | boolean | YES | true |
| created_by | uuid | NO |  |

Foreign keys:
- `created_by` → `users.id`
- `device_id` → `devices.id`
- `school_id` → `schools.id`

## trusted_devices

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| user_id | uuid | NO |  |
| device_fingerprint | character varying | NO |  |
| trusted_until | timestamp with time zone | NO |  |
| created_at | timestamp with time zone | YES | now() |

Foreign keys:
- `user_id` → `users.id`

## user_invitations

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | NO |  |
| email | character varying | NO |  |
| initial_role | USER-DEFINED | NO | 'student'::role_type |
| scope | jsonb | NO |  |
| token_hash | character varying | NO |  |
| status | USER-DEFINED | NO | 'pending'::invitation_status |
| expires_at | timestamp with time zone | NO |  |
| invited_by | uuid | NO |  |
| accepted_by | uuid | YES |  |
| accepted_at | timestamp with time zone | YES |  |
| revoked_at | timestamp with time zone | YES |  |
| created_at | timestamp with time zone | NO | now() |

Foreign keys:
- `accepted_by` → `users.id`
- `invited_by` → `users.id`
- `school_id` → `schools.id`

## user_roles

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| user_id | uuid | NO |  |
| role | USER-DEFINED | NO |  |
| school_id | uuid | YES |  |
| granted_by | uuid | NO |  |
| granted_at | timestamp with time zone | YES | now() |

Foreign keys:
- `granted_by` → `users.id`
- `school_id` → `schools.id`
- `user_id` → `users.id`

## users

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| school_id | uuid | YES |  |
| email | character varying | NO |  |
| student_code | character varying | YES |  |
| password_hash | character varying | NO |  |
| must_change_password | boolean | NO | false |
| first_name | character varying | NO |  |
| last_name | character varying | NO |  |
| status | USER-DEFINED | NO | 'active'::user_status |
| created_by | uuid | YES |  |
| created_at | timestamp with time zone | YES | now() |
| building | character varying | YES |  |

Foreign keys:
- `created_by` → `users.id`
- `school_id` → `schools.id`


## RPC Functions (public schema, live signatures)

### `_run_due_device_schedules()` → `void` (SECURITY DEFINER)

### `_check_threshold_violations()` → `void` (SECURITY DEFINER) — added 2026-08-27, `pg_cron` job `threshold-violation-check` (every minute, same pattern as `device-schedules-tick`); `postgres` role only, no client grants; inserts a real `sensor_alerts` row per active threshold a device's latest reading crosses, de-duplicated against any still-open (`new`/`acknowledged`) alert for that device+threshold

### `accept_staff_invitation(p_token text, p_first_name text, p_last_name text, p_password text)` → `TABLE(auth_state text, session_token text, user_id uuid, email character varying, first_name character varying, last_name character varying, active_role role_type, active_school_id uuid, otp_token text, otp_code text, otp_expires_at timestamp with time zone)` (SECURITY DEFINER)

### `acknowledge_emergency_event(p_token text, p_event_id uuid)` → `void` (SECURITY DEFINER)

### `acknowledge_incident_report(p_token text, p_id uuid)` → `void` (SECURITY DEFINER)

### `acknowledge_sensor_alert(p_alert_id uuid)` → `jsonb` (SECURITY DEFINER)

### `add_group_member(p_token text, p_group_id uuid, p_student_id uuid)` → `void` (SECURITY DEFINER)

### `add_incident_action(p_token text, p_id uuid, p_note text)` → `void` (SECURITY DEFINER)

### `add_lesson_material(p_token text, p_lesson_id uuid, p_type material_type, p_title text, p_url text, p_sort_order integer)` → `TABLE(material_id uuid)` (SECURITY DEFINER)

### `add_quiz_question(p_token text, p_quiz_id uuid, p_type question_type, p_question text, p_points numeric, p_choices jsonb)` → `TABLE(question_id uuid)` (SECURITY DEFINER)

### `add_rubric_criterion(p_token text, p_rubric_id uuid, p_name text, p_description text, p_max_score numeric, p_levels jsonb)` → `TABLE(criterion_id uuid)` (SECURITY DEFINER)

### `add_secondary_role(p_token text, p_target_user_id uuid, p_role role_type, p_school_id uuid)` → `void` (SECURITY DEFINER)

### `add_student_support_intervention(p_token text, p_case_id uuid, p_action_type text, p_notes text)` → `TABLE(intervention_id uuid)` (SECURITY DEFINER)

### `admin_update_user_profile(p_user_id uuid, p_first_name text, p_last_name text, p_role text, p_school_id uuid, p_student_code text, p_email text, p_status text, p_building text)` → `jsonb` (SECURITY DEFINER)

### `approve_parent_link(p_token text, p_parent_link_id uuid)` → `void` (SECURITY DEFINER)

### `archive_school_device(p_device_id uuid)` → `jsonb` (SECURITY DEFINER)

### `archive_school_user(p_user_id uuid)` → `jsonb` (SECURITY DEFINER)

### `assert_course_upload_access(p_token text, p_course_id uuid)` → `void` (SECURITY DEFINER)

### `assert_lesson_upload_access(p_token text, p_lesson_id uuid)` → `void` (SECURITY DEFINER)

### `assign_incident_report(p_token text, p_id uuid, p_assignee_id uuid)` → `void` (SECURITY DEFINER)

### `auth_select_role(p_role_selection_token text, p_role role_type, p_school_id uuid, p_device_info text, p_ip_address text)` → `TABLE(auth_state text, session_token text, user_id uuid, email character varying, first_name character varying, last_name character varying, must_change_password boolean, active_role role_type, active_school_id uuid, otp_token text, otp_code text, otp_expires_at timestamp with time zone, building character varying)` (SECURITY DEFINER)

### `auth_sign_in(p_email text, p_password text, p_device_info text, p_ip_address text)` → `TABLE(auth_state text, session_token text, user_id uuid, email character varying, first_name character varying, last_name character varying, must_change_password boolean, active_role role_type, active_school_id uuid, otp_token text, otp_code text, otp_expires_at timestamp with time zone, building character varying)` (SECURITY DEFINER)

### `auth_sign_out(p_token text)` → `void` (SECURITY DEFINER)

### `auth_sign_out_all(p_token text)` → `integer` (SECURITY DEFINER)

### `auth_validate_session(p_token text)` → `TABLE(user_id uuid, email character varying, first_name character varying, last_name character varying, must_change_password boolean, active_role role_type, active_school_id uuid, building character varying)` (SECURITY DEFINER)

### `auth_verify_login_otp(p_otp_token text, p_otp_code text)` → `TABLE(session_token text, user_id uuid, email character varying, first_name character varying, last_name character varying, must_change_password boolean, active_role role_type, active_school_id uuid, building character varying)` (SECURITY DEFINER)

### `check_terminal_pairing_status(p_pairing_code text)` → `TABLE(status text, session_token text, student_name text)` (SECURITY DEFINER)

### `claim_terminal_pairing_session(p_token text, p_pairing_code text)` → `TABLE(success boolean, student_name text, message text)` (SECURITY DEFINER)

### `close_emergency_event(p_token text, p_event_id uuid, p_review_note text)` → `void` (SECURITY DEFINER)

### `close_incident_report(p_token text, p_id uuid, p_resolution_type incident_resolution_type, p_resolution_note text)` → `void` (SECURITY DEFINER)

### `confirm_g_score(p_token text, p_entry_id uuid)` → `void` (SECURITY DEFINER)

### `confirm_grade(p_token text, p_grade_id uuid)` → `void` (SECURITY DEFINER)

### `confirm_parent_binding(p_verification_token text, p_otp_code text, p_relationship text, p_first_name text, p_last_name text, p_password text)` → `TABLE(parent_link_id uuid, status binding_status)` (SECURITY DEFINER)

### `confirm_password_reset(p_email text, p_otp_code text, p_new_password text)` → `void` (SECURITY DEFINER)

### `count_school_users_by_role(p_token text)` → `TABLE(active_role text, user_count bigint)` (SECURITY DEFINER)

### `create_assignment(p_token text, p_course_id uuid, p_type assignment_type, p_title text, p_instructions text, p_due_at timestamp with time zone, p_rubric_id uuid)` → `TABLE(assignment_id uuid)` (SECURITY DEFINER)

### `create_control_approval_request(p_token text, p_device_id uuid, p_command text, p_reason text)` → `jsonb` (SECURITY DEFINER)

### `create_course(p_token text, p_term_id uuid, p_subject_name text, p_grade_level text, p_room text, p_description text, p_teacher_id uuid)` → `TABLE(course_id uuid)` (SECURITY DEFINER)

### `create_device_schedule(p_token text, p_device_id uuid, p_label text, p_command jsonb, p_days_of_week smallint[], p_time_of_day time without time zone)` → `uuid` (SECURITY DEFINER)

### `create_grade(p_token text, p_student_id uuid, p_course_id uuid, p_score numeric, p_max_score numeric, p_assignment_id uuid)` → `TABLE(grade_id uuid)` (SECURITY DEFINER)

### `create_incident_report(p_token text, p_category incident_category, p_room text, p_reason text, p_severity text)` → `TABLE(incident_id uuid)` (SECURITY DEFINER)

### `create_lesson(p_token text, p_course_id uuid, p_title text, p_content jsonb)` → `TABLE(lesson_id uuid)` (SECURITY DEFINER)

### `create_parent_binding_code(p_token text, p_student_code text)` → `TABLE(binding_code text, expires_at timestamp with time zone, student_first_name character varying, student_last_name character varying)` (SECURITY DEFINER)

### `create_personal_task(p_token text, p_title text, p_note text, p_due_at timestamp with time zone)` → `TABLE(task_id uuid)` (SECURITY DEFINER)

### `create_post(p_token text, p_course_id uuid, p_body text)` → `TABLE(post_id uuid)` (SECURITY DEFINER)

### `create_quiz(p_token text, p_course_id uuid, p_type quiz_type, p_title text, p_lesson_id uuid, p_time_limit_min integer)` → `TABLE(quiz_id uuid)` (SECURITY DEFINER)

### `create_reply(p_token text, p_post_id uuid, p_body text)` → `TABLE(reply_id uuid)` (SECURITY DEFINER)

### `create_rubric(p_token text, p_title text, p_description text, p_criteria jsonb)` → `TABLE(rubric_id uuid)` (SECURITY DEFINER)

### `create_school_for_super_admin(p_token text, p_name text, p_province text, p_admin_email text, p_package_name text, p_max_users integer, p_max_devices integer, p_license_expires_at timestamp with time zone)` → `jsonb` (SECURITY DEFINER)

### `create_staff_invitation(p_token text, p_email text, p_role role_type, p_school_id uuid)` → `TABLE(invitation_token text, expires_at timestamp with time zone)` (SECURITY DEFINER)

### `create_student_group(p_token text, p_course_id uuid, p_name text)` → `uuid` (SECURITY DEFINER)

### `create_student_support_case(p_token text, p_student_id uuid, p_course_id uuid, p_category text, p_risk_level text, p_title text, p_notes text)` → `TABLE(case_id uuid)` (SECURITY DEFINER)

### `create_terminal_pairing_session(p_terminal_name text)` → `TABLE(pairing_code text, expires_at timestamp with time zone)` (SECURITY DEFINER)

### `current_user_school_id()` → `uuid` (SECURITY DEFINER)

### `decide_control_approval_request(p_token text, p_request_id uuid, p_approved boolean, p_reason text)` → `jsonb` (SECURITY DEFINER)

### `delete_device_schedule(p_token text, p_schedule_id uuid)` → `void` (SECURITY DEFINER)

### `delete_personal_task(p_token text, p_task_id uuid)` → `void` (SECURITY DEFINER)

### `delete_student_group(p_token text, p_group_id uuid)` → `void` (SECURITY DEFINER)

### `enroll_student(p_token text, p_course_id uuid, p_student_id uuid)` → `void` (SECURITY DEFINER)

### `escalate_incident_report(p_token text, p_id uuid)` → `void` (SECURITY DEFINER)

### `find_student_by_email(p_token text, p_email text)` → `TABLE(student_id uuid, first_name character varying, last_name character varying, email character varying)` (SECURITY DEFINER)

### `get_assignment(p_token text, p_assignment_id uuid)` → `TABLE(assignment_id uuid, course_id uuid, type assignment_type, title character varying, instructions text, due_at timestamp with time zone, status publish_status, sensor_datasets jsonb)` (SECURITY DEFINER)

### `get_auth_school_id(p_uid uuid)` → `uuid` (SECURITY DEFINER)

### `get_classrooms_overview(p_token text)` → `TABLE(room_count bigint, course_count bigint, active_student_count bigint, assignments_due_this_week bigint)` (SECURITY DEFINER)

### `get_course(p_token text, p_course_id uuid)` → `TABLE(course_id uuid, subject_name character varying, grade_level character varying, room character varying, description text, status course_status, term_id uuid, teacher_names text)` (SECURITY DEFINER)

### `get_or_create_course_join_code(p_token text, p_course_id uuid)` → `varchar` (SECURITY DEFINER) — added 2026-08-27, teacher-of-course only

### `regenerate_course_join_code(p_token text, p_course_id uuid)` → `varchar` (SECURITY DEFINER) — added 2026-08-27, teacher-of-course only

### `generate_course_join_code()` → `varchar` — added 2026-08-27, internal helper (not SECURITY DEFINER, no grants — only callable from the two RPCs above); uses `floor(random() * n)::int` — do **not** drop the `floor()` when touching this, Postgres's float→int cast rounds rather than truncates and will intermittently produce a too-short code otherwise (see WORK_LOG.md 2026-08-27)

### `get_course_file_for_download(p_token text, p_file_id uuid)` → `TABLE(storage_path text, file_name character varying)` (SECURITY DEFINER)

### `get_energy_efficiency_score(p_token text)` → `TABLE(score numeric, label text, current_kwh numeric, previous_kwh numeric)` (SECURITY DEFINER)

### `get_energy_usage_summary(p_token text, p_period text)` → `TABLE(device_count integer, total_kwh numeric, electricity_rate_thb numeric, is_rate_default boolean, estimated_cost_thb numeric, disclaimer text)` (SECURITY DEFINER)

### `get_energy_usage_trend(p_token text, p_days integer)` → `TABLE(day date, total_kwh numeric)` (SECURITY DEFINER)

### `get_incident_report(p_token text, p_id uuid)` → `TABLE(id uuid, category incident_category, room character varying, status incident_status, resolution_type incident_resolution_type, resolution_note text, created_at timestamp with time zone, acknowledged_at timestamp with time zone, closed_at timestamp with time zone, reason text, severity text)` (SECURITY DEFINER)

### `get_incident_summary(p_token text)` → `TABLE(category incident_category, total_count integer, avg_response_seconds numeric)` (SECURITY DEFINER)

### `get_lesson(p_token text, p_lesson_id uuid)` → `TABLE(lesson_id uuid, course_id uuid, title character varying, content jsonb, status lesson_status, published_at timestamp with time zone, materials jsonb, sensor_links jsonb, progress_pct numeric, completed boolean)` (SECURITY DEFINER)

### `get_lesson_material_for_download(p_token text, p_material_id uuid)` → `TABLE(storage_path text, file_name character varying)` (SECURITY DEFINER)

### `get_my_latest_quiz_attempt(p_token text, p_quiz_id uuid)` → `TABLE(attempt_id uuid, started_at timestamp with time zone, submitted_at timestamp with time zone, auto_score numeric)` (SECURITY DEFINER)

### `get_my_student_room(p_token text)` → `TABLE(room character varying, grade_level character varying)` (SECURITY DEFINER)

### `get_quiz_for_student(p_token text, p_quiz_id uuid)` → `TABLE(quiz_id uuid, title character varying, type quiz_type, time_limit_min integer, question_id uuid, question_type question_type, question text, points numeric, sort_order integer, choices jsonb, attachments jsonb)` (SECURITY DEFINER) — `attachments` added 2026-08-27, one jsonb array per question of `{id, type, file_name}` stubs (never `storage_path`)

### `assert_quiz_question_upload_access(p_token text, p_question_id uuid)` → `void` (SECURITY DEFINER) — added 2026-08-27, service_role only (called from the `quiz-attachment-upload` Edge Function)

### `add_quiz_question_attachment(p_token text, p_question_id uuid, p_type quiz_attachment_type, p_storage_path character varying, p_file_name character varying)` → `TABLE(attachment_id uuid)` (SECURITY DEFINER) — added 2026-08-27, called directly by the client like `add_quiz_question`

### `get_quiz_attachment_for_download(p_token text, p_attachment_id uuid)` → `TABLE(storage_path text, file_name character varying)` (SECURITY DEFINER) — added 2026-08-27, called from the `quiz-attachment-download` Edge Function

### `get_rubric(p_token text, p_rubric_id uuid)` → `TABLE(rubric_id uuid, title character varying, description text, criteria jsonb)` (SECURITY DEFINER)

### `get_school_utility_rates(p_token text)` → `TABLE(electricity_rate_thb numeric, is_electricity_default boolean, water_rate_thb numeric, is_water_default boolean)` (SECURITY DEFINER)

### `get_session_actor(p_token text)` → `TABLE(user_id uuid, role role_type, school_id uuid)` (SECURITY DEFINER)

### `get_water_efficiency_score(p_token text)` → `TABLE(score numeric, label text, current_m3 numeric, previous_m3 numeric)` (SECURITY DEFINER)

### `get_water_usage_summary(p_token text, p_period text)` → `TABLE(device_count integer, total_m3 numeric, water_rate_thb numeric, is_rate_default boolean, estimated_cost_thb numeric, disclaimer text)` (SECURITY DEFINER)

### `get_water_usage_trend(p_token text, p_days integer)` → `TABLE(day date, total_m3 numeric)` (SECURITY DEFINER)

### `give_feedback(p_token text, p_submission_id uuid, p_body text)` → `TABLE(feedback_id uuid)` (SECURITY DEFINER)

### `grant_camera_access(p_token text, p_user_id uuid, p_camera_device_id uuid, p_reason text, p_valid_until timestamp with time zone)` → `uuid` (SECURITY DEFINER)

### `grant_parent_consent(p_token text, p_parent_link_id uuid, p_policy_id uuid, p_evidence jsonb)` → `uuid` (SECURITY DEFINER)

### `has_role(p_role text)` → `boolean` (SECURITY DEFINER)

### `import_school_buildings_batch(p_token text, p_buildings jsonb)` → `jsonb` (SECURITY DEFINER)

### `import_school_devices_batch(p_token text, p_devices jsonb)` → `jsonb` (SECURITY DEFINER)

### `import_school_rooms_batch(p_token text, p_rooms jsonb)` → `jsonb` (SECURITY DEFINER)

### `import_school_users_batch(p_school_id uuid, p_role text, p_users jsonb)` → `jsonb` (SECURITY DEFINER)

### `import_school_users_batch_for_school_admin(p_token text, p_role text, p_users jsonb)` → `jsonb` (SECURITY DEFINER)

### `ingest_sensor_readings_verified(p_gateway_id uuid, p_readings jsonb)` → `integer` (SECURITY DEFINER)

### `is_super_admin(p_uid uuid)` → `boolean` (SECURITY DEFINER)

### `issue_device_token(p_token text, p_device_id uuid)` → `text` (SECURITY DEFINER)

### `link_assignment_sensor_dataset(p_token text, p_assignment_id uuid, p_device_id uuid, p_metric metric_type, p_time_start timestamp with time zone, p_time_end timestamp with time zone, p_label text)` → `TABLE(dataset_id uuid)` (SECURITY DEFINER)

### `link_lesson_sensor(p_token text, p_lesson_id uuid, p_device_id uuid, p_metric metric_type, p_time_start timestamp with time zone, p_time_end timestamp with time zone, p_caption text)` → `TABLE(link_id uuid)` (SECURITY DEFINER)

### `list_active_consent_policies(p_token text)` → `TABLE(policy_id uuid, consent_type character varying, version character varying, document_hash character varying, content_url character varying, effective_at timestamp with time zone)` (SECURITY DEFINER)

### `list_all_school_schedules(p_token text)` → `TABLE(schedule_id uuid, course_id uuid, subject_name character varying, day_of_week smallint, start_time time without time zone, end_time time without time zone, room character varying)` (SECURITY DEFINER)

### `list_assignments(p_token text, p_course_id uuid)` → `TABLE(assignment_id uuid, type assignment_type, title character varying, due_at timestamp with time zone, status publish_status)` (SECURITY DEFINER)

### `list_binding_codes(p_token text, p_school_id uuid)` → `TABLE(id uuid, student_id uuid, student_first_name character varying, student_last_name character varying, code_hint character varying, status binding_code_status, expires_at timestamp with time zone, issued_at timestamp with time zone)` (SECURITY DEFINER)

### `list_camera_access_grants(p_token text)` → `TABLE(grant_id uuid, camera_device_id uuid, camera_name text, location text, building text, room text, user_id uuid, user_name text, user_email text, user_role text, reason text, valid_from timestamp with time zone, valid_until timestamp with time zone, granted_at timestamp with time zone, granted_by_name text, is_active boolean)` (SECURITY DEFINER)

### `list_consent_policies_admin(p_token text, p_school_id uuid)` → `TABLE(policy_id uuid, school_id uuid, consent_type character varying, version character varying, document_hash character varying, content_url character varying, is_required boolean, effective_at timestamp with time zone, retired_at timestamp with time zone)` (SECURITY DEFINER)

### `list_course_attendance(p_token text, p_course_id uuid, p_class_date date)` → `TABLE(student_id uuid, student_name text, student_code text, status text, note text, marked_at timestamp with time zone)` (SECURITY DEFINER)

### `list_homeroom_assignments(p_token text)` → `TABLE(assignment_id uuid, grade_level text, room text, teacher_id uuid, teacher_name text, student_count bigint)` (SECURITY DEFINER) — school_admin/super_admin/executive; added 2026-08-27.

### `list_my_homeroom_classes(p_token text)` → `TABLE(assignment_id uuid, grade_level text, room text, student_count bigint)` (SECURITY DEFINER) — teacher-only; added 2026-08-27.

### `list_homeroom_roster(p_token text, p_grade_level text, p_room text)` → `TABLE(student_id uuid, student_name text, student_code text)` (SECURITY DEFINER) — added 2026-08-27.

### `list_homeroom_attendance(p_token text, p_grade_level text, p_room text, p_class_date date)` → `TABLE(student_id uuid, student_name text, student_code text, status text, note text, marked_at timestamp with time zone)` (SECURITY DEFINER) — added 2026-08-27.

### `mark_homeroom_attendance(p_token text, p_grade_level text, p_room text, p_class_date date, p_records jsonb)` → `integer` (SECURITY DEFINER) — added 2026-08-27.

### `set_homeroom_teacher(p_token text, p_grade_level text, p_room text, p_teacher_id uuid)` → `uuid` (SECURITY DEFINER) — school_admin/super_admin only; added 2026-08-27.

### `remove_homeroom_teacher(p_token text, p_assignment_id uuid)` → `boolean` (SECURITY DEFINER) — school_admin/super_admin only; added 2026-08-27.

### `list_course_files(p_token text, p_course_id uuid)` → `TABLE(file_id uuid, storage_path text, file_name character varying, size_bytes bigint, uploaded_by uuid, uploader_first_name character varying, uploader_last_name character varying, created_at timestamp with time zone)` (SECURITY DEFINER)

### `list_course_grades(p_token text, p_course_id uuid)` → `TABLE(grade_id uuid, student_id uuid, student_first_name character varying, student_last_name character varying, score numeric, max_score numeric, status grade_status, coi_flag boolean, coi_review_status coi_review_status, confirmed_at timestamp with time zone)` (SECURITY DEFINER)

### `list_course_quizzes(p_token text, p_course_id uuid)` → `TABLE(quiz_id uuid, type quiz_type, title character varying, time_limit_min integer, status publish_status, lesson_id uuid)` (SECURITY DEFINER)

### `list_course_students(p_token text, p_course_id uuid)` → `TABLE(student_id uuid, first_name character varying, last_name character varying, email character varying, enrolled_at timestamp with time zone)` (SECURITY DEFINER)

### `list_device_control_data_for_super_admin(p_token text)` → `jsonb` (SECURITY DEFINER)

### `list_device_schedules(p_token text, p_device_id uuid)` → `TABLE(id uuid, device_id uuid, device_name character varying, device_location character varying, school_id uuid, label text, command jsonb, days_of_week smallint[], time_of_day time without time zone, enabled boolean, created_by uuid, created_at timestamp with time zone, last_triggered_at timestamp with time zone)` (SECURITY DEFINER)

### `list_emergency_events(p_token text, p_status emergency_status)` → `TABLE(id uuid, school_id uuid, source_device_id uuid, device_name character varying, location character varying, triggered_at timestamp with time zone, status emergency_status, warning_light_on boolean, acknowledged_by uuid, acknowledged_by_name text, acknowledged_at timestamp with time zone, closed_at timestamp with time zone, review_note text)` (SECURITY DEFINER)

### `list_feedback(p_token text, p_submission_id uuid)` → `TABLE(feedback_id uuid, author_first_name character varying, author_last_name character varying, body text, created_at timestamp with time zone)` (SECURITY DEFINER)

### `list_incident_reports(p_token text, p_status incident_status)` → `TABLE(id uuid, category incident_category, room character varying, status incident_status, reporter_name character varying, created_at timestamp with time zone, acknowledged_at timestamp with time zone, reason text, severity text)` (SECURITY DEFINER)

### `list_lessons(p_token text, p_course_id uuid)` → `TABLE(lesson_id uuid, title character varying, status lesson_status, published_at timestamp with time zone, updated_at timestamp with time zone)` (SECURITY DEFINER)

### `list_my_consents(p_token text, p_parent_link_id uuid)` → `TABLE(consent_id uuid, policy_id uuid, consent_type character varying, version character varying, document_hash character varying, content_url character varying, is_required boolean, status consent_status, granted_at timestamp with time zone, withdrawn_at timestamp with time zone)` (SECURITY DEFINER)

### `list_my_courses(p_token text)` → `TABLE(course_id uuid, subject_name character varying, grade_level character varying, room character varying, status course_status, term_id uuid)` (SECURITY DEFINER)

### `list_my_g_score(p_token text)` → `TABLE(entry_id uuid, course_id uuid, subject_name character varying, source g_score_source, points numeric, confirmed_at timestamp with time zone)` (SECURITY DEFINER)

### `list_my_grades(p_token text)` → `TABLE(grade_id uuid, course_id uuid, subject_name character varying, score numeric, max_score numeric, confirmed_at timestamp with time zone)` (SECURITY DEFINER)

### `list_my_incident_reports(p_token text)` → `TABLE(id uuid, category incident_category, room character varying, status incident_status, created_at timestamp with time zone, reason text, severity text)` (SECURITY DEFINER)

### `list_my_linked_students(p_token text)` → `TABLE(student_id uuid, first_name character varying, last_name character varying, school_id uuid, relationship character varying, linked_at timestamp with time zone)` (SECURITY DEFINER)

### `list_my_notifications(p_token text)` → `TABLE(id uuid, type character varying, title character varying, body text, payload jsonb, created_at timestamp with time zone, read_at timestamp with time zone)` (SECURITY DEFINER)

### `list_my_parent_links(p_token text)` → `TABLE(parent_link_id uuid, student_id uuid, student_first_name character varying, student_last_name character varying, relationship character varying, status binding_status)` (SECURITY DEFINER)

### `list_my_personal_tasks(p_token text)` → `TABLE(task_id uuid, title character varying, note text, due_at timestamp with time zone, done boolean, created_at timestamp with time zone)` (SECURITY DEFINER)

### `list_my_rubrics(p_token text)` → `TABLE(rubric_id uuid, title character varying, description text, created_by uuid, criteria_count bigint, used_count bigint)` (SECURITY DEFINER)

### `list_my_schedule(p_token text)` → `TABLE(schedule_id uuid, course_id uuid, subject_name character varying, day_of_week smallint, start_time time without time zone, end_time time without time zone, room character varying)` (SECURITY DEFINER)

### `list_my_student_attendance(p_token text, p_student_id uuid, p_date_from date, p_date_to date)` → `TABLE(record_id uuid, course_id uuid, course_name text, course_code text, class_date date, status text, note text, marked_at timestamp with time zone)` (SECURITY DEFINER)

### `list_my_student_grades(p_token text, p_student_id uuid)` → `TABLE(grade_id uuid, course_id uuid, subject_name character varying, score numeric, max_score numeric, confirmed_at timestamp with time zone)` (SECURITY DEFINER)

### `list_my_student_schedule(p_token text, p_student_id uuid)` → `TABLE(schedule_id uuid, course_id uuid, subject_name character varying, day_of_week smallint, start_time time without time zone, end_time time without time zone, room character varying)` (SECURITY DEFINER)

### `list_my_submission_versions(p_token text, p_assignment_id uuid)` → `TABLE(version integer, content text, submitted_at timestamp with time zone, submission_version_id uuid, attachments jsonb)` (SECURITY DEFINER) — `submission_version_id`/`attachments` added 2026-08-27

### `list_parent_links(p_token text, p_status binding_status, p_school_id uuid)` → `TABLE(id uuid, student_id uuid, student_first_name character varying, student_last_name character varying, parent_id uuid, parent_first_name character varying, parent_last_name character varying, parent_email character varying, relationship character varying, status binding_status, requested_at timestamp with time zone)` (SECURITY DEFINER)

### `list_pending_coi_grades(p_token text)` → `TABLE(grade_id uuid, student_id uuid, student_first_name character varying, student_last_name character varying, course_id uuid, subject_name character varying, graded_by uuid, score numeric, max_score numeric, status grade_status)` (SECURITY DEFINER)

### `list_pending_g_score(p_token text)` → `TABLE(entry_id uuid, student_id uuid, student_first_name character varying, student_last_name character varying, course_id uuid, subject_name character varying, source g_score_source, points numeric, created_at timestamp with time zone)` (SECURITY DEFINER)

### `list_posts(p_token text, p_course_id uuid)` → `TABLE(post_id uuid, author_id uuid, author_first_name character varying, author_last_name character varying, body text, is_pinned boolean, created_at timestamp with time zone, replies jsonb)` (SECURITY DEFINER)

### `list_school_devices(p_token text)` → `TABLE(device_id uuid, name character varying, type device_type, location character varying, status device_status)` (SECURITY DEFINER)

### `list_school_invitations(p_token text, p_school_id uuid)` → `TABLE(id uuid, email character varying, initial_role role_type, status invitation_status, expires_at timestamp with time zone, created_at timestamp with time zone)` (SECURITY DEFINER)

### `list_school_users(p_token text)` → `TABLE(user_id uuid, first_name character varying, last_name character varying, email character varying, active_role text, active_school_id uuid, status text)` (SECURITY DEFINER)

### `list_schools_for_super_admin(p_token text)` → `TABLE(id uuid, school_code text, name text, province text, admin_email text, package_name text, status text, license_expires_at timestamp with time zone, max_users integer, max_devices integer, created_at timestamp with time zone, updated_at timestamp with time zone, users_count integer, devices_total integer, devices_online integer, buildings_count integer, rooms_count integer, alerts_count integer, last_sync_at timestamp with time zone)` (SECURITY DEFINER)

### `list_student_groups(p_token text, p_course_id uuid)` → `TABLE(id uuid, course_id uuid, name character varying, created_at timestamp with time zone, members jsonb)` (SECURITY DEFINER)

### `list_student_support_cases(p_token text, p_course_id uuid, p_status text)` → `TABLE(case_id uuid, student_id uuid, student_name text, student_email text, course_id uuid, course_name text, category text, risk_level text, status text, title text, notes text, created_by_name text, intervention_count bigint, created_at timestamp with time zone, updated_at timestamp with time zone)` (SECURITY DEFINER)

### `list_students_needing_attention(p_token text)` → `TABLE(student_id uuid, student_name text, reason text, detail text, action_label text, severity text)` (SECURITY DEFINER) — teacher-only; added 2026-08-28. Auto-computed (≥2 overdue assignments / avg confirmed grade < 50% / ≥2 absences in 30 days), distinct from the manual `student_support_cases` above.

### `list_student_support_interventions(p_token text, p_case_id uuid)` → `TABLE(intervention_id uuid, case_id uuid, action_type text, notes text, recorded_by_name text, created_at timestamp with time zone)` (SECURITY DEFINER)

### `list_submissions(p_token text, p_assignment_id uuid)` → `TABLE(submission_id uuid, student_id uuid, student_first_name character varying, student_last_name character varying, status submission_status, current_version integer, latest_content text, submitted_at timestamp with time zone, latest_attachments jsonb)` (SECURITY DEFINER) — `latest_attachments` added 2026-08-27

### `assert_submission_upload_access(p_token text, p_submission_version_id uuid)` → `void` (SECURITY DEFINER) — added 2026-08-27, service_role only

### `add_submission_attachment(p_token text, p_submission_version_id uuid, p_storage_path character varying, p_file_name character varying)` → `TABLE(attachment_id uuid)` (SECURITY DEFINER) — added 2026-08-27, called directly by the client

### `get_submission_attachment_for_download(p_token text, p_attachment_id uuid)` → `TABLE(storage_path text, file_name character varying)` (SECURITY DEFINER) — added 2026-08-27

### `list_teacher_schedules(p_token text, p_course_id uuid)` → `TABLE(schedule_id uuid, course_id uuid, subject_name character varying, day_of_week smallint, start_time time without time zone, end_time time without time zone, room character varying)` (SECURITY DEFINER)

### `list_teaching_kit_command_history(p_token text, p_limit integer)` → `TABLE(command_id uuid, device_id uuid, device_name character varying, command jsonb, created_by_name text, created_at timestamp with time zone, delivered_at timestamp with time zone)` (SECURITY DEFINER)

### `list_teaching_kit_devices(p_token text)` → `TABLE(device_id uuid, name character varying, type device_type, location character varying, status device_status, course_id uuid, course_name character varying)` (SECURITY DEFINER)

### `list_terms(p_token text)` → `TABLE(term_id uuid, term_name character varying, academic_year_name character varying, start_date date, end_date date)` (SECURITY DEFINER)

### `mark_attendance(p_token text, p_course_id uuid, p_class_date date, p_records jsonb)` → `integer` (SECURITY DEFINER)

### `mark_lesson_complete(p_token text, p_lesson_id uuid)` → `void` (SECURITY DEFINER)

### `mark_notification_read(p_token text, p_notification_id uuid)` → `void` (SECURITY DEFINER)

### `peek_terminal_pairing_session(p_pairing_code text)` → `TABLE(is_valid boolean, terminal_name text, created_at timestamp with time zone, expires_at timestamp with time zone)` (SECURITY DEFINER)

### `poll_device_commands(p_device_token text)` → `TABLE(command_id uuid, command jsonb, created_at timestamp with time zone)` (SECURITY DEFINER)

### `publish_assignment(p_token text, p_assignment_id uuid)` → `void` (SECURITY DEFINER)

### `publish_consent_policy(p_token text, p_consent_type text, p_version text, p_document_hash text, p_content_url text, p_is_required boolean, p_effective_at timestamp with time zone, p_school_id uuid)` → `uuid` (SECURITY DEFINER)

### `publish_lesson(p_token text, p_lesson_id uuid)` → `void` (SECURITY DEFINER)

### `publish_quiz(p_token text, p_quiz_id uuid)` → `void` (SECURITY DEFINER)

### `queue_device_command(p_token text, p_device_id uuid, p_command jsonb)` → `uuid` (SECURITY DEFINER)

### `queue_teaching_kit_command(p_token text, p_device_id uuid, p_command jsonb)` → `uuid` (SECURITY DEFINER)

### `reactivate_user(p_token text, p_target_user_id uuid)` → `void` (SECURITY DEFINER)

### `record_device_heartbeat(p_device_id uuid, p_ip_address text, p_firmware text)` → `jsonb` (SECURITY DEFINER)

### `record_operational_alert(p_category text, p_severity text, p_details jsonb)` → `bigint` (SECURITY DEFINER)

### `redeem_parent_binding_code(p_code text, p_relationship text, p_email text, p_first_name text, p_last_name text, p_password text)` → `TABLE(session_token text, user_id uuid, email character varying, first_name character varying, last_name character varying, active_role role_type, active_school_id uuid)` (SECURITY DEFINER)

### `register_course_file(p_token text, p_course_id uuid, p_storage_path text, p_file_name text, p_size_bytes bigint)` → `TABLE(file_id uuid)` (SECURITY DEFINER)

### `register_device(p_token text, p_type device_type, p_name text, p_serial_no text, p_location text, p_kit_code text)` → `TABLE(device_id uuid, device_token text)` (SECURITY DEFINER)

### `reject_parent_link(p_token text, p_parent_link_id uuid, p_reason text)` → `void` (SECURITY DEFINER)

### `remove_class_schedule(p_token text, p_schedule_id uuid)` → `void` (SECURITY DEFINER)

### `remove_group_member(p_token text, p_group_id uuid, p_student_id uuid)` → `void` (SECURITY DEFINER)

### `remove_student_from_course(p_token text, p_course_id uuid, p_student_id uuid)` → `void` (SECURITY DEFINER)

### `rename_student_group(p_token text, p_group_id uuid, p_name text)` → `void` (SECURITY DEFINER)

### `request_parent_binding_otp(p_code text, p_email text)` → `TABLE(otp_code text, verification_token text)` (SECURITY DEFINER)

### `request_parent_link_second_review(p_token text, p_parent_link_id uuid, p_exception_reason text)` → `void` (SECURITY DEFINER)

### `request_password_reset_otp(p_email text)` → `TABLE(otp_code text, user_id uuid, first_name character varying)` (SECURITY DEFINER)

### `resolve_sensor_alert(p_alert_id uuid, p_note text)` → `jsonb` (SECURITY DEFINER)

### `retire_consent_policy(p_token text, p_policy_id uuid)` → `void` (SECURITY DEFINER)

### `review_coi_grade(p_token text, p_grade_id uuid)` → `void` (SECURITY DEFINER)

### `revoke_binding_code(p_token text, p_code_id uuid)` → `void` (SECURITY DEFINER)

### `revoke_camera_access(p_token text, p_grant_id uuid)` → `boolean` (SECURITY DEFINER)

### `revoke_staff_invitation(p_token text, p_invitation_id uuid)` → `void` (SECURITY DEFINER)

### `save_quiz_answer(p_token text, p_attempt_id uuid, p_question_id uuid, p_answer jsonb)` → `void` (SECURITY DEFINER)

### `search_school_students(p_token text, p_query text)` → `TABLE(student_id uuid, first_name character varying, last_name character varying, email character varying)` (SECURITY DEFINER)

### `second_approve_parent_link(p_token text, p_parent_link_id uuid)` → `void` (SECURITY DEFINER)

### `sensor_history(p_token text, p_device_id uuid, p_metric metric_type, p_from timestamp with time zone, p_to timestamp with time zone)` → `TABLE(ts timestamp with time zone, value numeric)` (SECURITY DEFINER)

### `sensor_ingest(p_device_token text, p_readings jsonb)` → `integer` (SECURITY DEFINER)

### `sensor_latest(p_token text, p_device_id uuid)` → `TABLE(device_id uuid, device_name character varying, location character varying, metric metric_type, ts timestamp with time zone, value numeric)` (SECURITY DEFINER)

### `set_class_schedule(p_token text, p_course_id uuid, p_day_of_week smallint, p_start_time time without time zone, p_end_time time without time zone, p_room text)` → `TABLE(schedule_id uuid)` (SECURITY DEFINER)

### `set_device_token_issued_at()` → `trigger`

### `set_school_admin_building(p_token text, p_target_user_id uuid, p_building text)` → `void` (SECURITY DEFINER) — renamed 2026-08-27 from `set_facility_manager_building`, a pre-role-merge leftover name; logic unchanged (already checked school_admin/super_admin)

### `set_school_status_for_super_admin(p_token text, p_school_id uuid, p_status text)` → `boolean` (SECURITY DEFINER)

### `set_school_utility_rates(p_token text, p_electricity_rate_thb numeric, p_water_rate_thb numeric)` → `void` (SECURITY DEFINER)

### `start_quiz_attempt(p_token text, p_quiz_id uuid)` → `TABLE(attempt_id uuid, started_at timestamp with time zone)` (SECURITY DEFINER)

### `submit_assignment(p_token text, p_assignment_id uuid, p_content text)` → `TABLE(submission_id uuid, version integer, submission_version_id uuid)` (SECURITY DEFINER) — `submission_version_id` added 2026-08-27 so the client can attach files to the version it just created

### `submit_quiz_attempt(p_token text, p_attempt_id uuid)` → `TABLE(auto_score numeric)` (SECURITY DEFINER)

### `suspend_user(p_token text, p_target_user_id uuid)` → `void` (SECURITY DEFINER)

### `toggle_device_schedule(p_token text, p_schedule_id uuid, p_enabled boolean)` → `void` (SECURITY DEFINER)

### `toggle_personal_task(p_token text, p_task_id uuid, p_done boolean)` → `void` (SECURITY DEFINER)

### `update_assignment(p_token text, p_assignment_id uuid, p_title text, p_instructions text, p_due_at timestamp with time zone, p_rubric_id uuid)` → `void` (SECURITY DEFINER)

### `update_course(p_token text, p_course_id uuid, p_subject_name text, p_grade_level text, p_room text, p_description text)` → `void` (SECURITY DEFINER)

### `update_grade(p_token text, p_grade_id uuid, p_score numeric, p_max_score numeric)` → `void` (SECURITY DEFINER)

### `update_lesson(p_token text, p_lesson_id uuid, p_title text, p_content jsonb)` → `void` (SECURITY DEFINER)

### `update_lesson_progress(p_token text, p_lesson_id uuid, p_progress_pct numeric)` → `void` (SECURITY DEFINER)

### `update_school_for_super_admin(p_token text, p_school_id uuid, p_name text, p_province text, p_admin_email text, p_package_name text, p_max_users integer, p_max_devices integer, p_license_expires_at timestamp with time zone)` → `boolean` (SECURITY DEFINER)

### `update_student_support_case_status(p_token text, p_case_id uuid, p_status text, p_note text)` → `void` (SECURITY DEFINER)

### `update_user_profile(p_token text, p_target_user_id uuid, p_first_name text, p_last_name text)` → `void` (SECURITY DEFINER)

### `update_user_role(p_token text, p_target_user_id uuid, p_new_role role_type)` → `void` (SECURITY DEFINER)

### `verify_gateway_request(p_gateway_id uuid, p_timestamp bigint, p_nonce text, p_signature text, p_method text, p_path text, p_body_hash text)` → `boolean` (SECURITY DEFINER)

### `withdraw_parent_consent(p_token text, p_consent_id uuid, p_reason text)` → `void` (SECURITY DEFINER)
