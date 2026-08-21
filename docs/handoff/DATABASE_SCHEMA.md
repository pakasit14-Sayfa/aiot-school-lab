# Database Schema (live dump from local Supabase, regenerated 2026-08-21)

Total tables: 66

All tables have Row-Level Security enabled with **zero policies** — nothing is reachable directly via PostgREST. Every read/write goes through a `SECURITY DEFINER` RPC function (see RPC list below) or an Edge Function. Clients call `supabase.rpc('fn_name', {...})`, never `.from('table').select()` directly.


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

Foreign keys:
- `created_by` → `users.id`
- `school_id` → `schools.id`
- `term_id` → `terms.id`

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
- `school_id` → `schools.id`
- `source_device_id` → `devices.id`

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

Foreign keys:
- `coi_reviewed_by` → `users.id`
- `confirmed_by` → `users.id`
- `course_id` → `courses.id`
- `graded_by` → `users.id`
- `quiz_attempt_id` → `quiz_attempts.id`
- `student_id` → `users.id`
- `submission_id` → `submissions.id`

## group_members

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| group_id | uuid | NO |  |
| student_id | uuid | NO |  |

Foreign keys:
- `group_id` → `student_groups.id`
- `student_id` → `users.id`

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

## submission_attachments

| column | type | nullable | default |
|---|---|---|---|
| id | uuid | NO | gen_random_uuid() |
| submission_version_id | uuid | NO |  |
| type | USER-DEFINED | NO |  |
| file_url | character varying | YES |  |
| dataset_id | uuid | YES |  |
| chart_id | uuid | YES |  |

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
| initial_role | USER-DEFINED | NO | 'teacher'::role_type |
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

# RPC Functions (public schema, callable via supabase.rpc)

Total: 148

Almost every one takes `p_token text` as its first arg — the custom session token (see auth pattern in main handoff doc), validated internally via `get_session_actor(p_token)`. This is NOT Supabase Auth; there is no `auth.uid()`.

| function | args | returns |
|---|---|---|
| `accept_staff_invitation` | p_token text, p_first_name text, p_last_name text, p_password text | TABLE(auth_state text, session_token text, user_id uuid, email character vary... |
| `acknowledge_emergency_event` | p_token text, p_event_id uuid | void |
| `acknowledge_incident_report` | p_token text, p_id uuid | void |
| `add_group_member` | p_token text, p_group_id uuid, p_student_id uuid | void |
| `add_incident_action` | p_token text, p_id uuid, p_note text | void |
| `add_lesson_material` | p_token text, p_lesson_id uuid, p_type material_type, p_title text, p_url text, p_sort_order inte... | TABLE(material_id uuid) |
| `add_quiz_question` | p_token text, p_quiz_id uuid, p_type question_type, p_question text, p_points numeric, p_choices ... | TABLE(question_id uuid) |
| `add_rubric_criterion` | p_token text, p_rubric_id uuid, p_name text, p_description text, p_max_score numeric, p_levels js... | TABLE(criterion_id uuid) |
| `approve_parent_link` | p_token text, p_parent_link_id uuid | void |
| `assert_course_upload_access` | p_token text, p_course_id uuid | void |
| `assert_lesson_upload_access` | p_token text, p_lesson_id uuid | void |
| `assign_incident_report` | p_token text, p_id uuid, p_assignee_id uuid | void |
| `auth_sign_in` | p_email text, p_password text, p_device_info text, p_ip_address text | TABLE(auth_state text, session_token text, user_id uuid, email character vary... |
| `auth_sign_out` | p_token text | void |
| `auth_sign_out_all` | p_token text | integer |
| `auth_validate_session` | p_token text | TABLE(user_id uuid, email character varying, first_name character varying, la... |
| `auth_verify_login_otp` | p_otp_token text, p_otp_code text | TABLE(session_token text, user_id uuid, email character varying, first_name c... |
| `close_emergency_event` | p_token text, p_event_id uuid, p_review_note text | void |
| `close_incident_report` | p_token text, p_id uuid, p_resolution_type incident_resolution_type, p_resolution_note text | void |
| `confirm_g_score` | p_token text, p_entry_id uuid | void |
| `confirm_grade` | p_token text, p_grade_id uuid | void |
| `confirm_parent_binding` | p_verification_token text, p_otp_code text, p_relationship text, p_first_name text, p_last_name t... | TABLE(parent_link_id uuid, status binding_status) |
| `confirm_password_reset` | p_email text, p_otp_code text, p_new_password text | void |
| `count_school_users_by_role` | p_token text | TABLE(active_role text, user_count bigint) |
| `create_assignment` | p_token text, p_course_id uuid, p_type assignment_type, p_title text, p_instructions text, p_due_... | TABLE(assignment_id uuid) |
| `create_course` | p_token text, p_term_id uuid, p_subject_name text, p_grade_level text, p_room text, p_description... | TABLE(course_id uuid) |
| `create_grade` | p_token text, p_student_id uuid, p_course_id uuid, p_score numeric, p_max_score numeric | TABLE(grade_id uuid) |
| `create_incident_report` | p_token text, p_category incident_category, p_room text, p_reason text, p_severity text | TABLE(incident_id uuid) |
| `create_lesson` | p_token text, p_course_id uuid, p_title text, p_content jsonb | TABLE(lesson_id uuid) |
| `create_parent_binding_code` | p_token text, p_student_code text | TABLE(binding_code text, expires_at timestamp with time zone, student_first_n... |
| `create_personal_task` | p_token text, p_title text, p_note text, p_due_at timestamp with time zone | TABLE(task_id uuid) |
| `create_post` | p_token text, p_course_id uuid, p_body text | TABLE(post_id uuid) |
| `create_quiz` | p_token text, p_course_id uuid, p_type quiz_type, p_title text, p_lesson_id uuid, p_time_limit_mi... | TABLE(quiz_id uuid) |
| `create_reply` | p_token text, p_post_id uuid, p_body text | TABLE(reply_id uuid) |
| `create_rubric` | p_token text, p_title text, p_description text, p_criteria jsonb | TABLE(rubric_id uuid) |
| `create_staff_invitation` | p_token text, p_email text, p_role role_type, p_school_id uuid | TABLE(invitation_token text, expires_at timestamp with time zone) |
| `create_student_group` | p_token text, p_course_id uuid, p_name text | uuid |
| `delete_personal_task` | p_token text, p_task_id uuid | void |
| `delete_student_group` | p_token text, p_group_id uuid | void |
| `enroll_student` | p_token text, p_course_id uuid, p_student_id uuid | void |
| `escalate_incident_report` | p_token text, p_id uuid | void |
| `find_student_by_email` | p_token text, p_email text | TABLE(student_id uuid, first_name character varying, last_name character vary... |
| `get_assignment` | p_token text, p_assignment_id uuid | TABLE(assignment_id uuid, course_id uuid, type assignment_type, title charact... |
| `get_course` | p_token text, p_course_id uuid | TABLE(course_id uuid, subject_name character varying, grade_level character v... |
| `get_course_file_for_download` | p_token text, p_file_id uuid | TABLE(storage_path text, file_name character varying) |
| `get_energy_usage_summary` | p_token text, p_period text | TABLE(device_count integer, total_kwh numeric, electricity_rate_thb numeric, ... |
| `get_incident_report` | p_token text, p_id uuid | TABLE(id uuid, category incident_category, room character varying, status inc... |
| `get_incident_summary` | p_token text | TABLE(category incident_category, total_count integer, avg_response_seconds n... |
| `get_lesson` | p_token text, p_lesson_id uuid | TABLE(lesson_id uuid, course_id uuid, title character varying, content jsonb,... |
| `get_lesson_material_for_download` | p_token text, p_material_id uuid | TABLE(storage_path text, file_name character varying) |
| `get_my_latest_quiz_attempt` | p_token text, p_quiz_id uuid | TABLE(attempt_id uuid, started_at timestamp with time zone, submitted_at time... |
| `get_my_student_room` | p_token text | TABLE(room character varying, grade_level character varying) |
| `get_quiz_for_student` | p_token text, p_quiz_id uuid | TABLE(quiz_id uuid, title character varying, type quiz_type, time_limit_min i... |
| `get_rubric` | p_token text, p_rubric_id uuid | TABLE(rubric_id uuid, title character varying, description text, criteria jso... |
| `get_school_utility_rates` | p_token text | TABLE(electricity_rate_thb numeric, is_electricity_default boolean, water_rat... |
| `get_session_actor` | p_token text | TABLE(user_id uuid, role role_type, school_id uuid) |
| `get_water_usage_summary` | p_token text, p_period text | TABLE(device_count integer, total_m3 numeric, water_rate_thb numeric, is_rate... |
| `give_feedback` | p_token text, p_submission_id uuid, p_body text | TABLE(feedback_id uuid) |
| `grant_parent_consent` | p_token text, p_parent_link_id uuid, p_policy_id uuid, p_evidence jsonb | uuid |
| `ingest_sensor_readings_verified` | p_gateway_id uuid, p_readings jsonb | integer |
| `issue_device_token` | p_token text, p_device_id uuid | text |
| `link_assignment_sensor_dataset` | p_token text, p_assignment_id uuid, p_device_id uuid, p_metric metric_type, p_time_start timestam... | TABLE(dataset_id uuid) |
| `link_lesson_sensor` | p_token text, p_lesson_id uuid, p_device_id uuid, p_metric metric_type, p_time_start timestamp wi... | TABLE(link_id uuid) |
| `list_active_consent_policies` | p_token text | TABLE(policy_id uuid, consent_type character varying, version character varyi... |
| `list_assignments` | p_token text, p_course_id uuid | TABLE(assignment_id uuid, type assignment_type, title character varying, due_... |
| `list_binding_codes` | p_token text, p_school_id uuid | TABLE(id uuid, student_id uuid, student_first_name character varying, student... |
| `list_consent_policies_admin` | p_token text, p_school_id uuid | TABLE(policy_id uuid, school_id uuid, consent_type character varying, version... |
| `list_course_files` | p_token text, p_course_id uuid | TABLE(file_id uuid, storage_path text, file_name character varying, size_byte... |
| `list_course_grades` | p_token text, p_course_id uuid | TABLE(grade_id uuid, student_id uuid, student_first_name character varying, s... |
| `list_course_quizzes` | p_token text, p_course_id uuid | TABLE(quiz_id uuid, type quiz_type, title character varying, time_limit_min i... |
| `list_course_students` | p_token text, p_course_id uuid | TABLE(student_id uuid, first_name character varying, last_name character vary... |
| `list_devices_in_my_building` | p_token text | TABLE(device_id uuid, name character varying, type device_type, location char... |
| `list_emergency_events` | p_token text, p_status emergency_status | TABLE(id uuid, school_id uuid, source_device_id uuid, device_name character v... |
| `list_feedback` | p_token text, p_submission_id uuid | TABLE(feedback_id uuid, author_first_name character varying, author_last_name... |
| `list_incident_reports` | p_token text, p_status incident_status | TABLE(id uuid, category incident_category, room character varying, status inc... |
| `list_lessons` | p_token text, p_course_id uuid | TABLE(lesson_id uuid, title character varying, status lesson_status, publishe... |
| `list_my_consents` | p_token text, p_parent_link_id uuid | TABLE(consent_id uuid, policy_id uuid, consent_type character varying, versio... |
| `list_my_courses` | p_token text | TABLE(course_id uuid, subject_name character varying, grade_level character v... |
| `list_my_g_score` | p_token text | TABLE(entry_id uuid, course_id uuid, subject_name character varying, source g... |
| `list_my_grades` | p_token text | TABLE(grade_id uuid, course_id uuid, subject_name character varying, score nu... |
| `list_my_incident_reports` | p_token text | TABLE(id uuid, category incident_category, room character varying, status inc... |
| `list_my_notifications` | p_token text | TABLE(id uuid, type character varying, title character varying, body text, pa... |
| `list_my_parent_links` | p_token text | TABLE(parent_link_id uuid, student_id uuid, student_first_name character vary... |
| `list_my_personal_tasks` | p_token text | TABLE(task_id uuid, title character varying, note text, due_at timestamp with... |
| `list_my_rubrics` | p_token text | TABLE(rubric_id uuid, title character varying, description text, created_by u... |
| `list_my_schedule` | p_token text | TABLE(schedule_id uuid, course_id uuid, subject_name character varying, day_o... |
| `list_my_submission_versions` | p_token text, p_assignment_id uuid | TABLE(version integer, content text, submitted_at timestamp with time zone) |
| `list_parent_links` | p_token text, p_status binding_status, p_school_id uuid | TABLE(id uuid, student_id uuid, student_first_name character varying, student... |
| `list_pending_coi_grades` | p_token text | TABLE(grade_id uuid, student_id uuid, student_first_name character varying, s... |
| `list_pending_g_score` | p_token text | TABLE(entry_id uuid, student_id uuid, student_first_name character varying, s... |
| `list_posts` | p_token text, p_course_id uuid | TABLE(post_id uuid, author_id uuid, author_first_name character varying, auth... |
| `list_school_devices` | p_token text | TABLE(device_id uuid, name character varying, type device_type, location char... |
| `list_school_invitations` | p_token text, p_school_id uuid | TABLE(id uuid, email character varying, initial_role role_type, status invita... |
| `list_school_users` | p_token text | TABLE(user_id uuid, first_name character varying, last_name character varying... |
| `list_student_groups` | p_token text, p_course_id uuid | TABLE(id uuid, course_id uuid, name character varying, created_at timestamp w... |
| `list_submissions` | p_token text, p_assignment_id uuid | TABLE(submission_id uuid, student_id uuid, student_first_name character varyi... |
| `list_teaching_kit_command_history` | p_token text, p_limit integer | TABLE(command_id uuid, device_id uuid, device_name character varying, command... |
| `list_teaching_kit_devices` | p_token text | TABLE(device_id uuid, name character varying, type device_type, location char... |
| `list_terms` | p_token text | TABLE(term_id uuid, term_name character varying, academic_year_name character... |
| `mark_lesson_complete` | p_token text, p_lesson_id uuid | void |
| `mark_notification_read` | p_token text, p_notification_id uuid | void |
| `poll_device_commands` | p_device_token text | TABLE(command_id uuid, command jsonb, created_at timestamp with time zone) |
| `publish_assignment` | p_token text, p_assignment_id uuid | void |
| `publish_consent_policy` | p_token text, p_consent_type text, p_version text, p_document_hash text, p_content_url text, p_is... | uuid |
| `publish_lesson` | p_token text, p_lesson_id uuid | void |
| `publish_quiz` | p_token text, p_quiz_id uuid | void |
| `queue_device_command` | p_token text, p_device_id uuid, p_command jsonb | uuid |
| `queue_teaching_kit_command` | p_token text, p_device_id uuid, p_command jsonb | uuid |
| `record_operational_alert` | p_category text, p_severity text, p_details jsonb | bigint |
| `redeem_parent_binding_code` | p_code text, p_relationship text, p_email text, p_first_name text, p_last_name text, p_password t... | TABLE(session_token text, user_id uuid, email character varying, first_name c... |
| `register_course_file` | p_token text, p_course_id uuid, p_storage_path text, p_file_name text, p_size_bytes bigint | TABLE(file_id uuid) |
| `register_device` | p_token text, p_type device_type, p_name text, p_serial_no text, p_location text, p_kit_code text | TABLE(device_id uuid, device_token text) |
| `reject_parent_link` | p_token text, p_parent_link_id uuid, p_reason text | void |
| `remove_class_schedule` | p_token text, p_schedule_id uuid | void |
| `remove_group_member` | p_token text, p_group_id uuid, p_student_id uuid | void |
| `remove_student_from_course` | p_token text, p_course_id uuid, p_student_id uuid | void |
| `rename_student_group` | p_token text, p_group_id uuid, p_name text | void |
| `request_parent_binding_otp` | p_code text, p_email text | TABLE(otp_code text, verification_token text) |
| `request_parent_link_second_review` | p_token text, p_parent_link_id uuid, p_exception_reason text | void |
| `request_password_reset_otp` | p_email text | TABLE(otp_code text, user_id uuid, first_name character varying) |
| `retire_consent_policy` | p_token text, p_policy_id uuid | void |
| `review_coi_grade` | p_token text, p_grade_id uuid | void |
| `revoke_binding_code` | p_token text, p_code_id uuid | void |
| `revoke_staff_invitation` | p_token text, p_invitation_id uuid | void |
| `save_quiz_answer` | p_token text, p_attempt_id uuid, p_question_id uuid, p_answer jsonb | void |
| `search_school_students` | p_token text, p_query text | TABLE(student_id uuid, first_name character varying, last_name character vary... |
| `second_approve_parent_link` | p_token text, p_parent_link_id uuid | void |
| `sensor_history` | p_token text, p_device_id uuid, p_metric metric_type, p_from timestamp with time zone, p_to times... | TABLE(ts timestamp with time zone, value numeric) |
| `sensor_ingest` | p_device_token text, p_readings jsonb | integer |
| `sensor_latest` | p_token text, p_device_id uuid | TABLE(device_id uuid, device_name character varying, location character varyi... |
| `set_class_schedule` | p_token text, p_course_id uuid, p_day_of_week smallint, p_start_time time without time zone, p_en... | TABLE(schedule_id uuid) |
| `set_device_token_issued_at` |  | trigger |
| `set_facility_manager_building` | p_token text, p_target_user_id uuid, p_building text | void |
| `set_school_utility_rates` | p_token text, p_electricity_rate_thb numeric, p_water_rate_thb numeric | void |
| `start_quiz_attempt` | p_token text, p_quiz_id uuid | TABLE(attempt_id uuid, started_at timestamp with time zone) |
| `submit_assignment` | p_token text, p_assignment_id uuid, p_content text | TABLE(submission_id uuid, version integer) |
| `submit_quiz_attempt` | p_token text, p_attempt_id uuid | TABLE(auto_score numeric) |
| `suspend_user` | p_token text, p_target_user_id uuid | void |
| `toggle_personal_task` | p_token text, p_task_id uuid, p_done boolean | void |
| `update_assignment` | p_token text, p_assignment_id uuid, p_title text, p_instructions text, p_due_at timestamp with ti... | void |
| `update_course` | p_token text, p_course_id uuid, p_subject_name text, p_grade_level text, p_room text, p_descripti... | void |
| `update_grade` | p_token text, p_grade_id uuid, p_score numeric, p_max_score numeric | void |
| `update_lesson` | p_token text, p_lesson_id uuid, p_title text, p_content jsonb | void |
| `update_lesson_progress` | p_token text, p_lesson_id uuid, p_progress_pct numeric | void |
| `update_user_profile` | p_token text, p_target_user_id uuid, p_first_name text, p_last_name text | void |
| `update_user_role` | p_token text, p_target_user_id uuid, p_new_role role_type | void |
| `verify_gateway_request` | p_gateway_id uuid, p_timestamp bigint, p_nonce text, p_signature text, p_method text, p_path text... | boolean |
| `withdraw_parent_consent` | p_token text, p_consent_id uuid, p_reason text | void |