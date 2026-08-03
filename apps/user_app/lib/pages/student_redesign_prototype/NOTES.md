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
