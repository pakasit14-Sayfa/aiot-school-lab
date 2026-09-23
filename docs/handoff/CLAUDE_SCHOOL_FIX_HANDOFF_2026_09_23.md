# ส่งต่อ Claude: งานฐานข้อมูล, agy และจอแดงจัดการโรงเรียน

เขียนโดย Codex วันที่ 2026-09-23 ตามคำขอผู้ใช้ อ่านคู่กับ AGENTS.md และ [ประวัติ agy](AGY_OPERATIONS_HISTORY.md)

## สถานะที่ตรวจวันนี้

- รัน scripts/state.sh แล้ว ได้สถานะ git; ส่วน build/test ยังไม่คืนผล จึงไม่อ้างว่า analyze/test วันนี้ผ่าน
- main ใน `.worktrees/assignment-save-confirmation` อยู่ที่ 15636f2 และ clean ก่อนงานเอกสารนี้
- งานแก้ล่าสุดของ agy อยู่ที่ `.worktrees/school-package-fix` branch `fix/super-admin-school-package-assertion` ฐาน 15636f2 **ยังไม่ commit/merge**
- มีสองไฟล์เปลี่ยนสาระ: `apps/user_app/lib/pages/super_admin/super_admin_schools_page.dart` (+91/-20), `apps/user_app/test/super_admin/super_admin_schools_page_connection_test.dart` (+265/-4)
- generated plugin registrants ของ Linux/macOS/Windows ขึ้น modified ด้วย ต้องตรวจ diff แยกก่อนจัดเข้า commit ห้ามรวมโดยไม่ตรวจ
- root `C:\Users\user\projects\my_first_app` ยังอยู่ branch เก่า `agent/android-round1` ที่ 6677ce5 พร้อมงานเดิม uncommitted ห้ามคัดลอกทั้งไฟล์จากตรงนั้นทับ main หรือ reset/clean งานผู้ใช้
- ผลทดสอบและ review ด้านล่างเป็นการตรวจวันที่ 22 ก.ย. ต้องรันใหม่หลังแก้เพิ่ม ไม่ใช่ผลตรวจเว็บ/ฐานข้อมูลสดวันที่ 23

## งานที่ทำไปแล้วและหลักฐานย้อนหลัง

| งาน | สิ่งที่ทำ / หลักฐาน |
|---|---|
| sensor_latest ใช้ทรัพยากรสูง | 7bdb439 ปรับ query; หลักฐานช่วงก่อนหน้า 1302.465 ms → 13.465 ms ในการวัดนั้น |
| polling lifecycle | e822a0f หยุดเมื่อไม่มี listener/หน้าซ่อน และจัดการ stale responses |
| alerts security | 96ecb24 ปรับ security_invoker; pgTAP 18/18 และ anonymous REST denied 401/42501 ณ เวลาตรวจ |
| จอแดงตอนปิดฟอร์ม | 7c19399 ใช้ DialogRoute และรอ route.completed ก่อน dispose controllers; 34f270a บันทึก Codex คลิก Cancel/X บน Chrome ผ่าน |
| โรงเรียนทดสอบ | agy สร้างผ่าน UI: โรงเรียนดิลิออน ทดสอบ, SCH-202609-9990, ID 39a4d974-d125-4eab-96c2-1a801126790c; Codex อ่าน canonical/audit ยืนยัน มี users 0 ตอนตรวจ ยังไม่ได้สร้างแอดมินโรงเรียน |
| agy CLI/browser/MCP | ทดลอง Pro High แล้วใช้ gemini-3.8-flash-high ตามผู้ใช้; มีทั้งรอบสำเร็จและ timeout อย่านับ JSON SUCCESS/exit 0 อย่างเดียว |
| บันทึก agy | ebdfa1a เพิ่มประวัติและลิงก์ใน CLAUDE.md ส่งขึ้น GitHub/GitLab แล้ว |

CPU ที่ผู้ใช้เห็น 95% → 18% และรอบตรวจถัดมาประมาณ 3–4% เป็นค่าตามช่วงเวลา ไม่ใช่การรับรอง performance ปัจจุบัน ไม่ได้ประเมินความพร้อมทั้งระบบเป็นเปอร์เซ็นต์

## ผล review งาน Dropdown ล่าสุดของ agy

บั๊กเป้าหมาย: เปิดแก้โรงเรียนที่ package เป็น `Pro Package` แล้ว Dropdown assertion เพราะไม่มี item ตรงค่าเดิมหนึ่งรายการ ภาพผู้ใช้ยืนยันอาการนี้ แต่ต้องอ่าน DB ใหม่หากจะยืนยันค่าปัจจุบันของ TEST01

สิ่งที่แก้แล้วใน worktree ล่าสุด:

- รวมฐาน main ที่มี route.completed แล้ว ไม่ทำตัวแก้ lifecycle หาย
- เพิ่ม raw package เดิมในตัวเลือก ทำให้ legacy/unknown/empty เปิดฟอร์มได้
- ค่าว่างแสดง “ไม่ระบุแพ็กเกจ” และไม่เปลี่ยนเป็น Basic; Basic ยังเป็น default ของการสร้างใหม่
- แก้ชื่ออย่างเดียวส่ง `Pro Package` เดิม ไม่ normalize ไปเป็น `Pro` เงียบ ๆ
- Filter สร้างจากข้อมูล และรีเซ็ต state เมื่อแพ็กเกจที่เลือกหายหลังโหลดใหม่
- เพิ่ม regression tests สำหรับเปิด legacy/unknown/empty, payload เมื่อแก้ชื่อ, Save/Cancel/X และ filter refresh

Codex รันอิสระใน worktree นี้วันที่ 22 ก.ย.:

```powershell
cd C:\Users\user\projects\my_first_app\.worktrees\school-package-fix\apps\user_app
& C:\src\flutter\bin\flutter.bat test test/super_admin/super_admin_schools_page_connection_test.dart --no-pub --reporter expanded
```

ผล **13/13 passed** เป็นเทสต์ไฟล์นี้เท่านั้น ไม่ใช่ regression ทั้งระบบหรือผล browser ล่าสุด

## ประเด็นที่ยังต้องแก้/ตรวจ

1. **บั๊กตัวกรองช่องว่าง (P2):** `_packageFilterOptions` ตัด `.trim()` แต่ `_filteredSchools` เทียบ raw `school.packageName == _packageFilter` ดังนั้นค่า `" Pro Package "` สร้างตัวเลือก `Pro Package` แต่เลือกแล้วโรงเรียนหาย แก้ key สำหรับเทียบให้สอดคล้องกันโดยยังเก็บ raw สำหรับ save และเพิ่ม regression
2. **ชื่อแพ็กเกจชนตัวเลือกทุกแพ็กเกจ:** ถ้า backend มีชื่อ `ทุกแพ็กเกจ` จะซ้ำกับ sentinel ที่เติมต้นรายการ อาจเกิด Dropdown assertion อีก ต้องแยก identity ของ All ออกจากชื่อข้อมูล และเพิ่มเทสต์ unknown ชื่อนี้
3. **การยืนยันหลังบันทึก:** เทสต์แก้ชื่อยืนยันเพียง arguments ที่ส่ง ตัว mock loader ยังคืน record เก่า จึงไม่พิสูจน์ persisted canonical state; save handler เดิม reload แล้วแจ้งสำเร็จโดยไม่เทียบค่าที่ได้ และ loader ดูด read errors ปัญหานี้เดิมมีอยู่ ไม่ใช่ agy เพิ่งสร้าง แต่ห้ามอ้างว่าเทสต์นี้ยืนยันบันทึกจริงครบตาม DoD
4. `didUpdateWidget` เพิ่ม reload เมื่อ callback เปลี่ยน แต่ไม่มี generation guard กันผลโหลดเก่าทับใหม่ เป็นข้อสังเกตลำดับรอง (production ปกติไม่ส่ง callback) พิจารณาหากจะคง seam นี้
5. ยังไม่ได้ยืนยันเว็บที่รัน **โค้ดล่าสุดนี้** ด้วยการคลิกจริง ผล browser จาก 34f270a เป็นงาน lifecycle ก่อนหน้า ใช้แทนหลักฐาน patch นี้ไม่ได้
6. ผล analyze ทั้งสามแพ็กเกจและ regression ทั้งชุดของ patch ล่าสุดยังไม่ได้ตรวจยืนยันอิสระ ห้ามเรียกว่า “ปลอดภัย 100%” จาก 13 เทสต์

## ลำดับรับงานต่อ

1. รัน state/fetch/status ตรวจ worktree และประสานว่า agy ยังทำงานอยู่หรือไม่ก่อนแก้ไฟล์เดียวกัน
2. เก็บสองกรณี filter ข้างต้น เพิ่มเทสต์ และตรวจ canonical-save contract ตามขอบเขตที่ผู้ใช้อนุญาต อย่าขยายไปเปลี่ยน production เอง
3. รัน focused tests, regression และ analyze ทั้ง shared_core/shared_ui/user_app เปรียบเทียบ baseline จริง
4. เปิดเว็บจาก worktree โค้ดใหม่ให้ผู้ใช้ดู ทดสอบเปิดแก้ TEST01 แล้ว Cancel/X ห้าม Save production เพื่อทดสอบโดยไม่ได้อนุญาตเฉพาะรายการ; Save ทดสอบผ่าน mock/local test DB ได้
5. ถ้ามี timeout หลัง mutation ต้องอ่านข้อมูลก่อน retry เพื่อไม่สร้างซ้ำ
6. ตรวจ diff ตัดไฟล์ generated ที่ไม่เกี่ยวข้องอย่างระมัดระวัง Commit เฉพาะ ticket รวมกลับ main และ push ทั้งสอง remote ตาม AGENTS.md ตรวจชื่อ remote จริง (ที่เคยพบ: github=GitHub, origin=GitLab)
7. ส่งผลพร้อม commit และหลักฐาน แยกผ่าน/ยังไม่ตรวจ/ติดขัดให้ชัด

ผู้ใช้ต้องการลดการถาม Yes ซ้ำ: ทำต่อได้ในขอบเขตที่อนุญาตแล้ว แต่ไม่ข้ามระบบอนุมัติ ไม่เปิด permission ทั้งหมดถาวร และไม่ตีความว่างานแก้ UI อนุญาตล้างฐานข้อมูล

สถานะ UI/MCP ใน AGY_OPERATIONS_HISTORY เป็นประวัติ: ครั้งล่าสุดเคยเปิดฟอร์ม `AGY live demo` ที่ยังไม่บันทึก และคืน MCP เป็น Snapshot-only ต้องตรวจปัจจุบันใหม่ก่อนใช้ ไม่ถือว่าเปิดค้างอยู่ตลอดไป
