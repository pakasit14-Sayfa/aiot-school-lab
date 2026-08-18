# Teacher Redesign Prototype

สถานะ: PROTOTYPE SANDBOX — ใช้ทดลอง UI/UX ฝั่งครูก่อนรวมระบบจริง

คำถามที่ prototype นี้ตอบ:

> หน้าแรกครูควรวางข้อมูลแบบไหนให้ครูเห็น “งานที่ต้องทำวันนี้” ได้เร็วที่สุด

ขอบเขต:

- ทำเฉพาะ UI/UX
- ไม่เชื่อมข้อมูลจริง
- ไม่แตะ backend / Supabase / auth / database
- แยกจาก `student_redesign_prototype` เพื่อให้ Claude แก้ UI นักเรียนต่อได้โดยไม่ชนกัน

ตำแหน่ง:

- `lib/pages/teacher_redesign_prototype/teacher_redesign_prototype_page.dart`

Route:

- `/prototype/teacher-redesign`

Variant:

- A — Dashboard ครูแบบ schedule + right insight panel
- B — Focus ตารางสอนวันนี้
- C — Operations queue สำหรับงานรอตรวจและนักเรียนที่ต้องติดตาม

ธีม:

- School AIoT
- Glass / soft dashboard
- ใช้สีได้ยืดหยุ่น แต่ยังให้มีฐานเขียว `#165042`
- เน้นอ่านเร็ว ใช้งานจริงสำหรับครู มากกว่าความน่ารักแบบนักเรียน

## แผนงานหน้าครูที่จะทำต่อ

เป้าหมายหลัก:

- ทำหน้า prototype ฝั่งครูให้เป็น “โต๊ะทำงานครู” ที่เห็นงานสำคัญของวันนี้เร็ว
- ยังเป็น UI mock/sandbox ก่อน ไม่เชื่อมระบบจริง
- งานนี้แยกจากหน้านักเรียน เพื่อให้ Claude แก้ UI นักเรียนต่อได้พร้อมกัน

ลำดับงาน:

1. QA โครงสร้างหลักของหน้าครู
   - ตรวจ Variant A/B/C ว่าสลับได้จริง
   - เอาแถบ floating switcher ออกให้หมด
   - ใช้ Sidebar/เมนูครูเป็นจุดควบคุมหลัก
   - เช็คว่าไม่มี overflow ใน desktop/tablet/mobile

2. ปรับ Sidebar ครู
   - ทำให้ Sidebar เป็น glass / soft panel
   - รองรับแบบเต็มและแบบย่อ
   - เมนูหลักควรมี: Dashboard, รายวิชา, นักเรียน, ตรวจงาน, คะแนน, AIoT
   - แสดงห้องประจำชั้นหรือ context ปัจจุบันโดยไม่รก

3. ปรับ Variant A — Dashboard
   - ให้เป็นหน้าหลักที่ครูเปิดแล้วเห็นภาพรวมทันที
   - ต้องมี:
     - สรุปคาบสอนวันนี้
     - งานรอตรวจ
     - นักเรียนที่ต้องติดตาม
     - รายวิชา/ห้องเรียนที่รับผิดชอบ
     - สถานะ AIoT Classroom
   - จัด layout ให้สมดุลกับ sidebar และ right panel

4. ปรับ Variant B — Schedule Focus
   - เน้นตารางสอนและคาบถัดไป
   - ใช้สำหรับครูที่ต้องเตรียมสอนตามเวลา
   - ต้องเห็น:
     - timeline คาบเรียน
     - ห้อง/รายวิชา
     - สถานะก่อนเข้าเรียน
     - งานที่เกี่ยวกับคาบนั้น

5. ปรับ Variant C — Review Ops
   - เน้นงานรอตรวจและงานที่ต้องจัดการ
   - ต้องเห็น:
     - งานที่รอตรวจ
     - งานด่วน
     - นักเรียนที่ต้องติดตาม
     - สถานะส่งงานของห้อง

6. ตรวจ MVP ฝั่งครูจากมุม UI
   - ไม่สนข้อมูลจริงในขั้นนี้
   - เช็คเฉพาะว่า UI มีปุ่ม/การ์ด/ทางเข้าหน้าที่ต้องใช้ครบหรือยัง
   - ถ้าขาด ให้เพิ่มเป็น mock ก่อน

7. บันทึกสถานะหลังทำ
   - เขียนว่าแต่ละ Variant เสร็จกี่ %
   - ระบุสิ่งที่ยังค้าง
   - ระบุว่าไฟล์ไหนเป็น sandbox และไฟล์ไหนห้ามเอาไปรวมระบบจริงทันที

กติกาการทำงาน:

- ทำใน `teacher_redesign_prototype` เท่านั้น
- ห้ามแก้ `student_redesign_prototype` ระหว่างงานครู
- ห้ามเชื่อม backend หรือข้อมูลจริงในรอบ UI นี้
- ถ้าจะรวมระบบจริงภายหลัง ให้ Claude เป็นคนเชื่อมระบบ ส่วน Codex ตรวจโครงสร้าง/คุณภาพ UI และความเสี่ยง

## ⚠️ ก่อนขึ้นระบบจริง (บันทึกไว้ 2026-08-13)

จากการตรวจสอบ (13 ส.ค. 69) พบว่าหน้าครูและหน้านักเรียนไม่เชื่อมกันเลย
(ไม่มีการ import ข้ามโฟลเดอร์กัน ไม่มี Supabase call จริงในทั้งสองโฟลเดอร์)
ปลอดภัยดี แต่ยังไม่พร้อม "แยกโค้ด" เข้าระบบจริง เพราะยังไม่เริ่ม rewrite
เข้าหน้า production เลยสักหน้า

จุดที่ต้องแก้แน่นอนก่อนปล่อยผู้ใช้จริง (ครู/นักเรียน/ผู้ปกครองตัวจริง):

- `lib/main.dart:26` — `const isPrototypeRoute = true;` ต้องเปลี่ยนเป็น
  `false` (หรือทำเป็น build flag/env var แยก dev กับ production) ไม่งั้น
  ผู้ใช้จริงจะข้ามหน้า login ไปเข้าโหมด prototype เสมอ

## เพิ่มเมื่อ 2026-08-16: ASM-7 + กลุ่ม AI-assisted Evaluation (AI-1..AI-10)

หลังตรวจสอบหน้าครู/นักเรียนเทียบ UC ในวอลต์แบบละเอียด พบว่า ASM-7 (ตรวจงาน
ตาม Rubric) ไม่มีหน้าจริงเลย และทั้งกลุ่ม AI-1..AI-10 ไม่มี UI เลยสักตัว —
สร้างเพิ่ม 2 ไฟล์ใหม่:

- `teacher_submission_review_page.dart` — ASM-7 + AI-1/AI-2/AI-3/AI-9/AI-10
  รวมอยู่ในหน้าเดียวกันโดยตั้งใจ (ไม่ใช่ความบังเอิญ) เพราะ ASM-7 "ครูตรวจงาน
  ตาม Rubric" กับ AI-3 "ครูยืนยันคะแนนที่ AI เสนอ" เป็น flow เดียวกันจริงๆ ใน
  ทางปฏิบัติ — เปิดจาก `teacher_grading_page.dart` ปุ่ม "ตรวจงาน"/"ดูผล"
  (เดิมเป็นแค่ `showTeacherMockAction` ลอยๆ) มี: AI แนะนำคะแนนต่อเกณฑ์ +
  ร่างข้อเสนอแนะ (AI-1/AI-2, ไม่มีผลจนกว่าครูยืนยัน), ปุ่ม "ใช้ตามที่ AI
  แนะนำทั้งหมด" vs ให้คะแนนเองทีละเกณฑ์, ธงเตือนคะแนนผิดปกติแบบไม่บล็อก
  (AI-9), ช่องเหตุผลเมื่อครูแก้คะแนนจาก AI (AI-10), checkbox CoI (AI-3
  Exception 1), และเคสที่ AI วิเคราะห์ไม่ได้เลย (ไฟล์วิดีโอ) ให้ครูให้คะแนน
  เองทั้งหมด (AI-1 Exception 1)
- `teacher_student_support_page.dart` — AI-4/AI-5/AI-6/AI-7/AI-8: รายการ
  นักเรียนที่ระบบวิเคราะห์แล้วพบความเสี่ยง (ส่งงานช้า/ไม่ดูบทเรียน/คะแนน
  ตก — จากพฤติกรรมการเรียนเท่านั้น ไม่ตัดสินนิสัยส่วนบุคคล ตาม AI-4 BR1)
  พร้อมเหตุผล+ข้อมูลประกอบ, กิจกรรมเสริมที่ AI แนะนำแต่ต้องครูกดมอบหมายเอง
  ทีละรายการ (ไม่ auto-assign ตาม AI-7 BR1), บันทึกสถานะ/บันทึกการติดตาม
  (AI-6), และปุ่มสร้างสรุปผลการเรียนที่ AI ร่างให้ครูตรวจก่อนใช้จริง (AI-8)
  — เปิดผ่าน `/prototype/teacher-student-support` (ยังไม่ผูกเข้า sidebar/
  เมนูจริง เหมือน teacher-gscore-confirm)

ทั้งสองหน้ายังเป็น mock data ล้วนๆ ไม่มี backend ตามธรรมชาติของ prototype
folder นี้

## เพิ่มเมื่อ 2026-08-17: เชื่อมต่อ Backend จริงระบบรับแจ้งเหตุฉุกเฉิน SOS (`teacher_incident_inbox_page.dart`)

- เชื่อมต่อ `IncidentService.listTeacherIncidentReports()`, `acknowledgeIncidentReport()`, `addIncidentAction()`, `escalateIncidentReport()`, `closeIncidentReport()` เข้ากับ UI `teacher_incident_inbox_page.dart`
- ครูเห็นเฉพาะรายการแจ้งเหตุจากห้องเรียนในวิชาที่ตนสอนตามสิทธิ์ `SECURITY DEFINER` RLS
- แสดงผลสถานะจริง (`new`, `acknowledged`, `in_progress`, `escalated`, `resolved`, `cancelled`) พร้อมปุ่มดำเนินการครบถ้วน


## เพิ่มเมื่อ 2026-08-18: เชื่อมต่อ Backend จริงฝั่งครู Tier 1 (Teacher Redesign Full Parity)

- **`teacher_lesson_editor_page.dart`**: เชื่อมต่อ `LessonService.listLessons()`, `createLesson()`, `updateLesson()`, `publishLesson()`, `addLessonMaterial()`, `linkLessonSensor()` ข้อมูลและเนื้อหาบทเรียนบันทึกลง Supabase จริง
- **`teacher_assignment_editor_page.dart`**: เชื่อมต่อ `AssignmentService.listAssignments()`, `createAssignment()`, `updateAssignment()`, `publishAssignment()` สร้างและจัดการใบงานจริง
- **`teacher_pbl_activity_editor_page.dart`**: เชื่อมต่อ `AssignmentService.createAssignment(type: 'project')` และ `publishAssignment()` สำหรับสร้างและเผยแพร่โครงงาน PBL จริง
- **`teacher_notifications_page.dart`**: เชื่อมต่อ `NotificationService.listMyNotifications()` และ `markNotificationRead()`
- **`teacher_gscore_confirm_page.dart`**: ตรวจสอบและแสดงป้ายแจ้งเตือนระบุชัดเจนตามข้อกำหนดว่า "ฟีเจอร์แต้มสะสม G-Score (Gamification) ยังไม่มีระบบ Backend รองรับในฐานข้อมูล" (ไม่ใส่ข้อมูล fake/mock แทนของจริง)
- **ตรวจสอบความสมบูรณ์ 5 หน้า**: (`teacher_courses_page.dart`, `teacher_students_page.dart`, `teacher_parent_binding_approval_page.dart`, `teacher_aiot_dashboard_page.dart`, `teacher_profile_page.dart`) เชื่อมต่อ `CourseService`, `ParentBindingService`, `LessonService.listSchoolDevices()`, `currentUserModel` และ `AuthService` ข้อมูลจริงครบถ้วน
- **품질 ยืนยัน**:
  - `dart format` + `flutter analyze`: PASS (0 errors)
  - `flutter build web --dart-define-from-file=../../env.json`: PASS 100% (ผ่านการคอมไพล์จริง)
  - `npx supabase test db`: PASS 19/19 test files (198 assertions)

