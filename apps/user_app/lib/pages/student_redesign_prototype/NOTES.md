# Student Redesign Prototype

สถานะ: throwaway UX/UI sandbox สำหรับหน้า student เท่านั้น

เปิดดู:

- `/prototype/student-redesign?variant=A`
- `/prototype/student-redesign?variant=B`
- `/prototype/student-redesign?variant=C`
- `/prototype/student-redesign?variant=D`

คำถามที่ prototype นี้ตอบ:

"หน้าตาระบบนักเรียนควรวาง information architecture แบบไหนก่อนรวมกลับเข้าระบบจริง?"

Variant:

- A: School Academy Home - หน้าแรกนักเรียนแบบโรงเรียนตาม reference ล่าสุด มี hero ใหญ่, mascot, quick actions, learning progress, AIoT sensor, tasks และประกาศโรงเรียน
- B: Daily Learning Path - timeline ตามกิจกรรมของวัน
- C: Focus Workspace - workspace เน้นวิชาปัจจุบันและ panel สรุปด้านข้าง
- D: Learning Command Center - dashboard รวมงาน วิชา คะแนน และ AIoT

อัปเดตล่าสุด (August 1, 2026):

- หน้าแรกนักเรียนของ Variant A ทำเสร็จแล้วในระดับ UX/UI prototype
- โครงหน้าแรกหลักครบ: hero, summary bar, sensor card, learning progress card, G-Score card, quick actions, continue learning, tasks due และ announcements
- interaction หลักของหน้าแรกถูกเชื่อมเข้าหน้าจริงในแอปแล้วในระดับ prototype flow
- สถานะปัจจุบัน: หน้าแรกนักเรียนพร้อมใช้เป็นต้นแบบอ้างอิงสำหรับพัฒนาหน้าจริงต่อ

กติกาการใช้งานที่พักงาน:

- โฟลเดอร์ `student_redesign_prototype/` คือที่พักงานสำหรับทดลอง UX/UI ก่อนลงระบบจริง
- งานในที่พักงานถือเป็น prototype ไม่ใช่ production page
- ให้พัฒนาหน้าตา, layout, flow, information architecture และ interaction ในที่พักงานก่อน
- ถ้างานยังไม่นิ่ง ห้ามย้ายเข้า `pages/student/...` หรือหน้าจริงของระบบ
- ถ้าหน้าใดผ่านแล้ว ให้ใช้เป็น reference แล้วค่อย rewrite เป็นงานจริงในหน้าจริงแยกอีกครั้ง
- ห้ามกองงานใหม่กลับเข้าไฟล์ใหญ่เดิม ถ้าแยกไฟล์ย่อยได้ให้แยกไฟล์ย่อยเสมอ
- source of truth ของงานทดลองแต่ละหน้าควรอยู่ในไฟล์แยกที่อ่านง่ายและดูแลง่าย
- เมื่อหน้าจริงทำเสร็จแล้ว ค่อยกลับมาลบ prototype ที่ไม่จำเป็นออก

กระบวนการทำงาน:

1. สร้าง prototype ของหน้าที่ต้องการก่อนในโซน `student_redesign_prototype/`
2. แยก component และไฟล์ย่อยให้ชัดเจน อย่ากองทุกอย่างในไฟล์เดียว
3. ตรวจหน้าตา, spacing, hierarchy, responsive และ flow ให้ผ่านในระดับ prototype
4. เชื่อม interaction เบื้องต้นให้กดไปหน้าที่เกี่ยวข้องได้ แม้ยังไม่ผูกข้อมูลจริงทั้งหมด
5. เมื่อแนวทางนิ่งแล้ว ค่อยนำดีไซน์ที่ผ่านไป rewrite ในหน้าจริงของระบบ
6. ค่อยผูกข้อมูลจริง, state จริง, service จริง และ navigation จริงให้ครบในหน้าจริง
7. หลังหน้าจริงเสร็จ ให้กลับมาเก็บ/ลบ prototype ที่ไม่จำเป็น เพื่อไม่ให้ codebase ซ้ำซ้อน

กติกา:

- ห้ามถือว่าไฟล์นี้เป็น production UI
- ห้ามผูก mutation จริง
- เมื่อเลือกแนวทางแล้วให้ rewrite เข้าหน้า student จริง แล้วลบ prototype นี้

## แนวทาง AIoT Lab / ชุดฝึก สำหรับแอปนักเรียน

สถานะ: แนวทางออกแบบสำหรับ MVP และการนำแอปไปใช้ซ้ำในโครงการอื่น

สรุปการตัดสินใจ:

- ไม่แยกเป็นแอปใหม่ในตอนนี้
- ให้ทำ `AIoT Lab / ชุดฝึก AIoT` เป็นโมดูลเสริมภายในแอปนักเรียนเดิม
- โมดูลนี้ต้องเปิด/ปิดได้ตาม config หรือ package ของแต่ละโครงการ
- ถ้าโครงการอื่นไม่ใช้ AIoT Lab ต้องซ่อนเมนู หน้า และข้อความที่เกี่ยวข้องทั้งหมดได้

เหตุผล:

- นักเรียนควรเรียน ทำ Lab ส่งใบงาน และดูคะแนนในแอปเดียว
- ลดงานซ้ำ เช่น login, profile, navigation, notification และ theme
- เหมาะกับ MVP มากกว่า เพราะทำเป็น module ก่อน แล้วค่อยแยกออกภายหลังได้ถ้าจำเป็น
- ป้องกันไม่ให้ฟีเจอร์ AIoT ติดไปกับโครงการอื่นที่ไม่เกี่ยวข้อง

ขอบเขตของโมดูล AIoT Lab:

- หน้า “กิจกรรม Lab” หรือ “ชุดฝึก AIoT”
- ขั้นตอนการทดลอง เช่น Step 1, Step 2, Step 3
- ใบงานที่ผูกกับค่าจากเซนเซอร์
- สถานะบอร์ดของนักเรียน เช่น ออนไลน์ / ออฟไลน์ / ยังไม่เชื่อมต่อ
- ปุ่มส่งผลการทดลอง
- หน้าดูผลลัพธ์จากชุดคิทของตัวเอง
- ข้อความเตือนว่าเป็น Lab Mode ไม่ใช่อุปกรณ์อาคารจริง

กติกาการออกแบบ:

- ห้ามฝังคำว่า AIoT ลงในหน้าทั่วไปถ้าไม่จำเป็น เช่น profile, score, worksheet generic
- ให้แยกโค้ดของ AIoT Lab ออกจาก student UI หลักให้ชัดเจน
- เมนู AIoT Lab ต้องแสดงเมื่อเปิด module เท่านั้น
- mock data ของ Lab, sensor, board status และ relay state ต้องแยกจาก mock data ทั่วไป
- ห้ามให้นักเรียนควบคุมอาคารจริงหรืออุปกรณ์รวมของโรงเรียน

แนวทางโครงสร้างที่แนะนำ:

- `modules/aiot_lab/`
- `modules/aiot_lab/pages/`
- `modules/aiot_lab/widgets/`
- `modules/aiot_lab/mock/`

ตัวอย่าง config:

- `aiot_lab_enabled = true`
- `generic_learning_only = false`
- `enabled_modules = ["learning", "worksheet", "score", "profile", "aiot_lab"]`

ถ้านำแอปไปใช้อีกโครงการ:

- ปิด `aiot_lab_enabled`
- ซ่อนเมนู “ชุดฝึก AIoT”
- ซ่อนหน้า Lab ทั้งหมด
- เหลือเฉพาะระบบเรียนทั่วไป เช่น หน้าแรก บทเรียน ใบงาน คะแนน และโปรไฟล์

## แนวทางโมดูลความปลอดภัยห้องเรียน (Classroom Safety Page)

สถานะ: แนวทางออกแบบต้นแบบ (UI Prototype) สำหรับโมดูลแจ้งเหตุ/ขอความช่วยเหลือ

สรุปข้อกำหนดและการตัดสินใจที่สำคัญ:
- **ป้ายเตือนระบบจำลอง (Critical Warning)**: ต้องแสดงแถบเตือนสีส้ม/แดง **"โหมดทดลอง UI — ยังไม่เชื่อมระบบแจ้งเหตุจริง"** ค้างไว้ด้านบนสุดของหน้าจอเสมอ เพื่อไม่ให้นักเรียนสับสนว่าเป็นการแจ้งเหตุจริงในช่วงทดสอบ
- **ทางเข้าใช้งาน**:
  - เมนูด่วน (Quick Action) บนหน้าแรกนักเรียน
  - ปุ่มเมนูความปลอดภัยเพิ่มเติม
- **ขอบเขตการเข้าถึง (Student Sandbox)**:
  - เห็นเฉพาะเหตุการณ์ที่ตนเองแจ้งเท่านั้น (ห้ามเห็นของนักเรียนคนอื่น)
  - ห้ามแสดงปุ่มปิดหรือแก้ไขเหตุของผู้อื่น
  - ไม่มีสิทธิ์เข้าถึงภาพกล้องวงจรปิด (CCTV) หรือรายชื่อผู้แจ้งเหตุ
- **การตรวจสอบความเข้ากันได้**:
  - ดำเนินการตรวจสอบ responsive และ overflow บนหน้าจอขนาดต่างๆ (Mobile/Tablet/Desktop) เพื่อความยืดหยุ่นในการใช้งานจริง

**[แก้ไข 2026-08-16] ตัดปุ่ม self-close ออกจากฝั่งนักเรียน**: `student_safety_page.dart`
(`_showSOSStatusActivatedSheet`) เดิมมีปุ่ม "สถานการณ์ปกติแล้ว" ให้นักเรียนปิดเหตุฉุกเฉิน
ของตัวเองได้ทันทีโดยไม่ผ่านครู ซึ่งขัด EMG-5 BR1 ("ปิดเหตุได้เฉพาะครูหลังบันทึกผลตรวจสอบ")
และขัดกติกาที่บันทึกไว้เองข้างบน ("ห้ามแสดงปุ่มปิดหรือแก้ไขเหตุของผู้อื่น" — รวมถึงกรณีปิด
เหตุของตัวเองโดยไม่ผ่านครูด้วย) แก้โดยตัดปุ่มนั้นออก เหลือปุ่มเดียวที่แค่ปิดหน้าต่าง แล้วขยาย
การจำลอง `Future.delayed` ที่มีอยู่แล้วให้ไหลต่อจนถึงสถานะ "ปิดเหตุแล้ว" (จำลองว่าครูเวร
ตรวจสอบและปิดเองหลังผ่านไปประมาณ 35 วินาที) เพื่อให้ `classroomSafetyStatus` รีเซ็ตกลับ
ปกติได้โดยไม่ต้องพึ่งการกดของนักเรียนเลย — ถ้าจะ rewrite เข้าหน้าจริง จุดปิดเหตุต้องมาจาก
ฝั่งครู (endpoint/สิทธิ์เฉพาะครู) เท่านั้น ห้ามมี mutation ปิดเหตุจากฝั่งนักเรียนอีก

**[แก้ไข 2026-08-16] เมนู "ความเป็นส่วนตัวและ PDPA" ในโปรไฟล์ยังเป็น placeholder**:
`widgets/student_profile_page.dart` (`_MenuTile`) ทุกเมนูในหน้าโปรไฟล์ใช้ tap handler
เดียวกันที่โชว์แค่ snackbar ทั่วไป ("กำลังเปิด: ...") ไม่มี flow จริงสักเมนู — เพิ่มคอมเมนต์
กำกับไว้เฉพาะจุดเมนู PDPA (มี 2 จุด สำหรับ layout มือถือ/desktop) เพราะพาดพิงสิทธิ์ข้อมูล
ของผู้เยาว์โดยตรง (CON-3/4/5) ต่างจากเมนูอื่นที่เป็นแค่ help/settings ทั่วไป กันทีมที่ rewrite
เข้าหน้าจริงเข้าใจผิดว่า flow ยินยอม/ดูประวัติ PDPA ผ่านแล้ว — ยังไม่ได้แก้ tap behavior เอง
เพราะเป็น infra ร่วมกับเมนูอื่นที่ยังเป็น mock ทั้งหมดเหมือนกัน

**[แก้ไข 2026-08-16] G-Score เปลี่ยนจากให้อัตโนมัติ เป็นรอครูยืนยัน (LRN-11/LRN-12)**:
G-Score เดิมไม่มี UC รองรับในวอลต์เลย — คุยกับเจ้าของโปรเจกต์แล้วเสนอเป็น UC ใหม่
(`LRN-11` ระบบสะสมยอดรอยืนยัน, `LRN-12` ครูยืนยันก่อนแสดงผลจริง — สอดคล้องหลักการ
"ครูยืนยันขั้นสุดท้ายเสมอ") แก้โค้ดให้ตรง:
- `widgets/student_dashboard_models.dart`: เพิ่ม `gscorePendingValue` แยกจาก
  `gscoreValue` ที่ยืนยันแล้ว
- `widgets/student_score_page.dart`: แสดง "รอครูยืนยันอีก N คะแนน" ต่อท้าย subtitle
  ของการ์ด G-Score เมื่อมียอดค้าง
- `widgets/student_assignments_page.dart`: ข้อความหลังส่งงานเปลี่ยนจาก "รับ N G-Score"
  (สื่อว่าได้แล้ว) เป็น "ได้ N G-Score เข้าคิวรอครูยืนยัน"
- ฝั่งครู: หน้าใหม่ `teacher_redesign_prototype/teacher_gscore_confirm_page.dart`
  (เปิดผ่าน `/prototype/teacher-gscore-confirm` เหมือนหน้าครูใหม่อื่นๆ — ยังไม่ได้
  เชื่อมเข้า sidebar/เมนูจริง รอ agy wire เข้า navigation ตอนทำหน้าครูให้เสร็จ)
  มีรายการรอยืนยันต่อคน/ต่อกิจกรรม กดยืนยันทีละรายการหรือทั้งหมดได้ กรองเห็นเฉพาะ
  รายวิชาที่ตนสอน (ตาม LRN-12 BR4)
- `student_lessons_page.dart` ไม่ต้องแก้ เพราะชิป "+N G-Score" ในนั้นเป็นแค่ป้าย
  บอกมูลค่าบทเรียนก่อนเรียน (ไม่ใช่ข้อความ "ได้รับแล้ว") อยู่แล้ว

## ⚠️ ก่อนขึ้นระบบจริง (บันทึกไว้ 2026-08-13)

จากการตรวจสอบ (13 ส.ค. 69) พบว่าหน้าครูและหน้านักเรียนไม่เชื่อมกันเลย
(ไม่มีการ import ข้ามโฟลเดอร์กัน) ปลอดภัยดี แต่ยังไม่พร้อม "แยกโค้ด" เข้า
ระบบจริง เพราะยังไม่เริ่ม rewrite เข้าหน้า production เลยสักหน้า (ฝั่ง
นักเรียนมีจุดต่อออกไปหน้าจริงที่ผูก Supabase จริงอยู่แล้ว 2 จุด คือ AIoT
Dashboard และ Notifications — ฝั่งครูยังไม่มีจุดต่อแบบนี้เลย)

จุดที่ต้องแก้แน่นอนก่อนปล่อยผู้ใช้จริง (ครู/นักเรียน/ผู้ปกครองตัวจริง):

- `lib/main.dart:26` — `const isPrototypeRoute = true;` ต้องเปลี่ยนเป็น
  `false` (หรือทำเป็น build flag/env var แยก dev กับ production) ไม่งั้น
  ผู้ใช้จริงจะข้ามหน้า login ไปเข้าโหมด prototype เสมอ

จุดเล็กๆ เสริม (ไม่รีบ): import ที่ไม่ได้ใช้งานจริง 2 จุดใน
`student_variant_school_home.dart` (`course_card.dart`) และ
`academy_continue_learning_card.dart` (`course_list_page.dart`)

## ✅ เชื่อมข้อมูลจริงเข้าหน้าแรกนักเรียน — Variant A (2026-08-17)

พบว่า `pages/student_home_page/student_home_page_widget.dart` มีคอมเมนต์ระบุไว้
ตั้งแต่แรกว่าเป็น "Official Production Page" เลือก Variant A เป็นตัวจริง แต่ไม่เคย
ถูกเชื่อมเข้า `role_router.dart` เลย (`RoleRouter` เดิมส่งนักเรียนไป
`StudentMainNav` ครอบ Variant D แทน ทำให้แถบล่างซ้อนกัน 2 อัน) — แก้ให้
`role_router.dart` ส่งนักเรียนไป `StudentHomePageWidget()` ตรงๆ แล้วเชื่อมข้อมูล
จริงเข้า `StudentVariantSchoolHome` ครบทุกส่วนของหน้าแรก:

**ต่อจริงแล้ว**: กระดิ่งแจ้งเตือน+การ์ดประกาศ (`NotificationService`), วงคืบหน้า+
เมนูด่วน+การ์ด "เรียนต่อ"+การ์ด "งานใกล้ครบกำหนด" (`CourseService`/
`LessonService`/`AssignmentService`), การ์ดคะแนน (`GradeService`), การ์ดเซนเซอร์
AIoT (`RealtimeService` — fallback ทั้งโรงเรียนเมื่อไม่มี room match ตรงกับ
สถานการณ์ชุดฝึกจริงพอดี ตามที่เจ้าของโปรเจกต์ยืนยัน)

**ตัดออกเพราะไม่มี backend รองรับเลย**: banner "PROTOTYPE SANDBOX" (ขัดกับ
banner จริงของ `StudentHomePageWidget`), การ์ดแจ้งเตือนความปลอดภัย
(`_activeSafetyAlerts` mock + ปุ่ม "รับทราบ" ที่ setState local อย่างเดียว —
เหมือน STK-12 ที่ไม่มี backend ทุก role ที่ตรวจมาในเซสชันนี้), การ์ด "การใช้
น้ำ-ไฟห้องเรียนฉัน" (`StudentHomeroomUtilityCard`, ผู้เขียนเดิมคอมเมนต์ไว้เองว่า
"ข้อมูลเป็น mock"), ตัวเลข G-Score/GPA/แบดจ์ (ไม่มี `GScoreService`/RPC ใดๆ
เลยทั้งฝั่งครูและนักเรียน — แทนที่การ์ดนี้ด้วยคะแนนเฉลี่ยจริงจาก `GradeService`
แทน), แถบ "เข้าเรียน" badge (ไม่มี attendance service ในระบบเลย), 2 สไลด์ปลอม
ใน `SchoolEncouragementCard` (ตัวเลข "ประหยัดไฟ 14.8% ลด 3.2kg CO₂" กับ
"25°C ประหยัดไฟสูงสุด" — เก็บไว้แค่สไลด์คติพจน์ทั่วไปที่ไม่ได้อ้างเป็นข้อมูลจริง)

**ยังไม่ได้ทำ (out of scope รอบนี้)**: 7 หน้าปลายทางที่เมนูด่วนพาไป
(`StudentLessonsPage`/`StudentAssignmentsPage`/`StudentScorePage`/
`StudentPretestPosttestPage`/`StudentCourseFilesPage`/`StudentCalendarPage`/
`StudentSafetyPage`) ยังเป็น mock 100% เหมือนเดิม — เป็นงานแยกต่างหาก
เทียบเท่ากับเมนู mock ที่เหลือของครู (คลังข้อสอบ/คลังความรู้/G-Score confirm ฯลฯ)

**เก็บกวาดพ่วง**: ลบโค้ดตาย `_Academy*`/`_ModeChip`/`_LabPatternPainter`
(~1,600 บรรทัด ไม่เคยถูกเรียกใช้จริง) ออกจาก
`student_redesign_prototype_page.dart`, ลบ import ที่ไม่ได้ใช้ทั้ง 2 จุดที่
ระบุไว้ข้างบนแล้ว

Variant B/C/D ยังอยู่ครบ เข้าดูเปรียบเทียบได้ผ่าน
`/prototype/student-redesign?variant=X` เหมือนเดิม (ไม่ใช่ตัวจริงอีกต่อไป)

## ✅ เชื่อมข้อมูลจริงเข้า 4 หน้าปลายทางจากเมนูด่วน — กลุ่ม A (2026-08-17)

ต่อจากรอบก่อนหน้า (เชื่อมหน้าแรก) — ทำต่อ 4 ใน 7 หน้าปลายทางที่มี backend
รองรับอยู่แล้วจริง ส่วนอีก 3 หน้า (สอบก่อน-หลังเรียน/ปฏิทิน/แจ้งเหตุ SOS)
ยังไม่มี backend เลย คงเป็น mock ต่อไปจนกว่าจะออกแบบระบบหลังบ้านใหม่

**`student_lessons_page.dart`**: เขียนใหม่ทั้งไฟล์ — ดึง `LessonService.listLessons`
ทุกวิชาที่ลงทะเบียนจริง (`CourseService.listMyCourses`) แต่ละบทเรียนกดแล้วพา
ไปหน้า `LessonViewPage` จริง (ของเดิม `pages/student/lesson_view_page.dart`)
แทนที่จะเปิด `StudentLessonContentPage` (mock, ลบทิ้งพร้อม
`StudentLessonQuizPage` ที่ใช้ร่วมกัน — ไม่มีที่ไหนเรียกใช้แล้วหลังแก้จุดนี้)
ตัดแท็บ "วิดีโอ"/เนื้อหาแบ่งประเภทออก (ไม่มีฟิลด์ content-type จริงในสคีมา)
และตัดชิป "มีใบงาน" ออก (lesson กับ assignment ไม่มีความสัมพันธ์ผูกกันตรงๆ
ในสคีมา)

**`student_assignments_page.dart`**: เขียนใหม่ทั้งไฟล์ — ดึง
`AssignmentService.listAssignments` ทุกวิชา เช็คสถานะส่งจริงผ่าน
`listMySubmissionVersions` ต่อชิ้นงาน ฟอร์มส่งงานเปลี่ยนจาก UI อัปโหลดไฟล์
พร้อม progress bar ปลอม (ไม่มี backend รองรับไฟล์แนบเลย — `submit_assignment`
รับแค่ text `content`) เป็นฟอร์มข้อความจริงเรียก `AssignmentService.submitAssignment`
ตรงๆ ตัดสถานะ "ตรวจแล้ว A+"/คะแนนต่อชิ้นงานออก (ไม่มีระบบให้คะแนนต่อ
assignment ในสคีมา คะแนนมีแค่ระดับวิชารวมผ่าน `GradeService` เท่านั้น)

**`student_score_page.dart`**: เขียนใหม่ทั้งไฟล์ — ตัด G-Score/GPA/แนวโน้ม
รายเดือน/แบดจ์ทั้งหมดออก (ไม่มี backend รองรับเลยสักอย่าง) เหลือแค่คะแนน
รายวิชาจริงจาก `GradeService.listMyGrades()` พร้อมแยกโซน "รอครูยืนยัน"
ออกจากคะแนนที่ยืนยันแล้ว (`confirmedAt == null` = รอยืนยัน)

**`student_course_files_page.dart`**: เขียนใหม่ทั้งไฟล์ — ดึงไฟล์จริงต่อวิชา
ผ่าน `CourseFileService.listFiles`, ดาวน์โหลดจริงผ่าน signed URL
(`getDownloadUrl` + `url_launcher`) ตัดการจัดกลุ่มตาม "บทเรียน" ออก (ไฟล์จริง
ไม่มีความสัมพันธ์กับบทเรียนในสคีมา ผูกกับวิชาเท่านั้น) แท็บกรองประเภทไฟล์
เปลี่ยนจาก field ปลอมเป็นนามสกุลไฟล์จริงแทน

**ยังไม่ได้ทำ (คงเป็น mock ต่อไป)**: `StudentPretestPosttestPage`,
`StudentCalendarPage`, `StudentSafetyPage` (SOS) — ทั้ง 3 หน้าไม่มี backend
รองรับเลย ต้องออกแบบระบบใหม่ทั้งหมดก่อนเชื่อมได้ (โดยเฉพาะ SOS ที่เป็นเรื่อง
ความปลอดภัยเด็ก ต้องคิดดีไซน์รอบคอบ ไม่ใช่แค่ต่อ RPC ธรรมดา)

