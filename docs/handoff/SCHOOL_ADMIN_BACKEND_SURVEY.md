# School Admin — สำรวจ backend + แผนต่อสายรายหน้า

**คู่กับ `EXECUTIVE_BACKEND_SURVEY.md` (ticket 3.0) — ฉบับนี้คือฝั่ง School Admin
ครอบ Phase 2 ทั้งหมดของ `MASTER_PLAN_2026-09-06.md`**
วันที่: 2026-09-06 · วิเคราะห์อย่างเดียว ไม่ได้แก้โค้ดหน้าไหน

เป้าหมายที่เอกสารนี้รองรับ: **ทุกหน้าต้องใช้งานได้จริง** ไม่ใช่ 80%
ดังนั้นขอบเขตคือ **15 หน้าที่เหลือ** (ทั้งหมด 20 − ผ่าน DoD แล้ว 5)

## ✅ ผลตรวจ 5 หน้าที่เอกสารเดิมบอกว่า "ผ่าน DoD แล้ว" — 2026-09-06

ไล่อ่านเต็มทั้ง 5 หน้า + controller เพราะเซสชันนี้พิสูจน์แล้วว่า "มี test แล้วดูเหมือนต่อ"
ไม่ได้แปลว่าใช้ได้จริง (หน้า energy มี service call จริง 6 จุด แต่มี fallback ปลอม 10 ตัว)

**ผลรวม: 4 ใน 5 หน้าเสร็จจริงตามที่อ้าง · 1 หน้ามีปัญหาที่ต้องแก้**

สิ่งที่ทั้ง 5 หน้าทำถูกและควรใช้เป็นแบบสำหรับหน้าที่เหลือ:

| เกณฑ์ | ผล |
|---|---|
| error message เป็นข้อความคงที่ ไม่มี `$e` หลุดขึ้นจอ | ✅ ครบทั้ง 5 |
| ไม่มี `catch (_) {}` | ✅ ครบทั้ง 5 |
| ข้อความ "สำเร็จ" อยู่หลัง `if (succeeded)` เสมอ | ✅ ครบทั้ง 5 |
| **mutation เขียน → อ่าน canonical กลับ → ตรวจว่าเจอจริง → ค่อยบอกสำเร็จ** | ✅ ครบทั้ง 5 — controller โยน `backend_*_not_confirmed` ถ้า backend ไม่ยืนยัน (เข้มกว่าที่ DoD กำหนดด้วยซ้ำ) |
| แยก loading / data / empty / error ด้วย sealed state + `previousData` | ✅ ครบทั้ง 5 |
| ไม่มีตารางข้อมูล hardcode | ✅ ครบทั้ง 5 (`_colorChoices` ใน learning_tracks เป็นจานสี = UI config) |

### ⚠️ `school_alerts_page` — เจอ 2 ปัญหา (แก้แล้ว 2026-09-06)

**1. Filter 4 ตัวเป็นรายการเขียนตายตัวที่กรองอะไรไม่ได้เลย**

`list_school_alerts` คืน sensor alert ของอุปกรณ์ หน้าจึง map ทุกแถวเป็น
`category: 'อุปกรณ์'` และ `severity/building/room: '--'` แต่ dropdown เสนอ:

| filter | ตัวเลือกที่เสนอ | ความจริง |
|---|---|---|
| ประเภท | ไฟฟ้า · น้ำ · คุณภาพอากาศ · ความปลอดภัย · นักเรียน · ระบบ | ทุกแถวเป็น "อุปกรณ์" → เลือกอันอื่นได้ 0 แถวเสมอ |
| ระดับ | เร่งด่วน · เฝ้าระวัง · แจ้งเตือน | ไม่มี severity ใน `sensor_alerts` เลย |
| สถานะ | กำลังตรวจสอบ · ส่งต่อแล้ว | backend เขียนได้แค่ `acknowledged` / `resolved` |
| อาคาร | อาคารเรียน A · อาคารเรียน B · อาคารปฏิบัติการ · อาคารอำนวยการ · ระบบกลาง | **ชื่ออาคารที่แต่งขึ้น** — ชุดเดียวกับที่ลบออกจากหน้า energy |

อันตรายเพราะเลือกแล้วตารางว่าง ผู้ใช้อ่านว่า *"อาคารนี้ไม่มีแจ้งเตือน"* ไม่ใช่
*"ตัวกรองนี้ใช้ไม่ได้"* → **แก้เป็นสร้างตัวเลือกจากข้อมูลที่โหลดมาจริง** ฟิลด์ที่
backend ไม่เคยใส่ค่าให้ (ระดับ, อาคาร) จะไม่แสดง dropdown เลย

**2. ปุ่ม 3 ตัวที่กดได้แต่ตอบว่า "ยังไม่เชื่อมต่อระบบหลังบ้าน"**

ส่งออกรายงาน · รับทราบทั้งหมด · ตรวจสอบ — ซื่อสัตย์กว่า fake success มาก แต่ผิด DoD
ข้อ "ปุ่มที่ไม่มี backend = disable" → disable + tooltip บอกเหตุผล
(ปุ่ม "ตรวจสอบ" ไม่ใช่แค่ยังไม่ต่อ แต่ **เป็นไปไม่ได้** — `sensor_alerts.status`
ไม่มีสถานะนี้ และไม่มี RPC ตัวไหนเขียนได้)

> การ์ดสรุป "เร่งด่วน" และ "กำลังตรวจสอบ" ที่โชว์ `--` พร้อมเหตุผล **เก็บไว้** —
> นั่นคือรูปแบบที่ถูกอยู่แล้ว

test เพิ่ม 2 ชุดใน `school_alerts_page_connection_test.dart`

---

## เกณฑ์ตัดสิน

| รหัส | ความหมาย | ใครทำ |
|---|---|---|
| **A** | RPC มีอยู่แล้ว รับ `p_token` และเปิดให้ `school_admin` → ต่อสายอย่างเดียว | Flutter |
| **B** | RPC มีอยู่ แต่ role gate ไม่รับ `school_admin` → migration บรรทัดเดียว | migration + Flutter |
| **C** | ข้อมูลอยู่ในตารางจริง แต่ไม่มี RPC เปิดให้ → เขียน SECURITY DEFINER ใหม่ | migration + service + Flutter |
| **D** | **ไม่มีอะไรในสคีมารองรับ** ไม่ใช่งานเขียนโค้ด แต่เป็นการตัดสินใจเชิงผลิตภัณฑ์ | เจ้าของโปรเจกต์ |

---

## 🔴 ข้อค้นพบที่กระทบแผนมากที่สุด — RPC 3 ตัวเรียกจากแอปนี้ไม่ได้

`archive_school_device` · `archive_school_user` · `admin_update_user_profile`
**ไม่มีพารามิเตอร์ `p_token`** และข้างในใช้ `is_super_admin()` / `has_role()` /
`current_user_school_id()` ซึ่งเป็น helper ที่อิง `auth.uid()`

ตาม hard rule 1 ของ `CLAUDE.md` แอปนี้ **ไม่ได้ใช้ Supabase Auth** — RPC ทั้งสามนี้
เขียนไว้ให้ `aiot_dev_dashboard` (แอดมินแอปอีกตัวที่ใช้ Auth จริง) เรียกจาก
`my_first_app` แล้ว actor จะเป็น null เสมอ

**ผลกระทบ:** ใครที่ไล่ชื่อ RPC แล้วเห็น `archive_school_device` จะนึกว่าปุ่ม
"ปิดใช้งานอุปกรณ์" ต่อได้เลย — ต่อไม่ได้ ต้องเขียนตัวใหม่ที่รับ `p_token`
ตรวจ `p_token` ในลายเซ็นก่อนเสมอ อย่าดูแค่ชื่อ

---

## ตารางรายหน้า (15 หน้า)

### 1. `school_admin_dashboard_page` (2,796) — หน้าแรกของ school_admin

ต่อจริงแล้วเยอะ: `fetchDashboardSummary` `fetchBuildings` `fetchRooms`
`fetchAuditLogs` `listSchoolAlerts` `getAllUsers`

| สิ่งที่ยังปลอม | verdict | ทางแก้ |
|---|---|---|
| `_ResourceData`(2183) — "การใช้ไฟวันนี้ 428 kWh / ลดลง 3.2% จากเมื่อวาน" | **A** | `UtilityService.getEnergyUsageSummary` / `getWaterUsageSummary` เปิดให้ school_admin อยู่แล้ว |
| ขาด `ยังไม่มีข้อมูล` ทั้งหน้า | — | เพิ่มตาม DoD |

**คลาส: ต่อสายอย่างเดียว** · เป็นหน้าที่ผู้ใช้เห็นก่อนใคร ควรทำก่อน

### 2. `school_permissions_page` (3,331) — ticket 2.1 (ทำค้างไว้ครึ่งทาง)

ต่อจริง: `getAllUsers` `updateRole` `deleteUser`(=suspend) `reactivateUser` `fetchAuditLogs`

| สิ่งที่ยังปลอม | verdict | ทางแก้ |
|---|---|---|
| ปุ่มเชิญบุคลากรใหม่ | **A** | `InvitationService` ห่อ `create_staff_invitation`/`list_school_invitations`/`revoke_staff_invitation` ครบแล้ว (รวมของซ้ำเสร็จ 2026-09-06) |
| `_RoleData roles`(1138) + `_MatrixRowData rows`(1199) — เมทริกซ์ "บทบาทไหนเห็นอะไรได้" | **D → ลบทิ้ง** | ไม่มีตารางไหนนิยามเมทริกซ์นี้ มันคือคำอธิบายที่เขียนมือ **ไม่ผูกกับ role gate จริงใน RPC เลย** และยังโชว์บทบาท `ครูประจำอาคาร` ซึ่งคือซาก `facility_manager` ที่ถูกยุบไปแล้วตั้งแต่ 2026-08-25 |
| ขาด `ยังไม่มีข้อมูล` | — | |

**สถานะงานค้าง:** `school_admin_permissions_controller.dart` (345 บรรทัด) เขียนเสร็จแล้ว
คุณภาพดี (นับ role จาก `all_roles` ไม่ใช่ `active_role`, กัน `forbidden_role_grant`,
โชว์ token คำเชิญทันทีเพราะ backend เก็บแค่ sha256) **แต่ยังไม่มีหน้าไหน import และยังไม่มี test**

### 3. `school_resources_page` (2,439)

ต่อจริง: `getSchoolUtilityRates` เท่านั้น (และ master plan ระบุว่าดึงมาแล้ว**ทิ้ง**)

| สิ่งที่ยังปลอม | verdict | ทางแก้ |
|---|---|---|
| `_BuildingResourceRecord buildings`(1253) — "อาคารเรียน A · 96.2 kWh · เกรด A" | **C** | ต่อรายอาคารไม่มี RPC รวมยอด — ช่องว่างเดียวกับ `director_environment` ฝั่ง Executive → เขียน `get_utility_usage_by_building(p_token, p_metric, p_days)` **ใช้ร่วมกันได้ทั้งสองสิทธิ์** |
| กราฟ/KPI รวม | **A** | `getEnergyUsageSummary/Trend` `getWaterUsageSummary/Trend` `getEnergyEfficiencyScore` `getWaterEfficiencyScore` |
| "บันทึกเกณฑ์การแจ้งเตือนทรัพยากรเรียบร้อยแล้ว" | **A** | `set_threshold` / `list_thresholds` gate `('teacher','school_admin','super_admin')` |
| "ส่งออกรายงาน (PDF/Excel) สำเร็จ" | **D → disable** | ไม่มี export pipeline |
| "แจ้งเตือนฝ่ายอาคารสถานที่เรียบร้อยแล้ว" | **D → ลบ** | ไม่มีฝ่าย ไม่มีช่องทางแจ้ง |
| `IoT Live Sync` เป็น true ตลอด | — | ผูกกับ `metricUpdatedAt` จริง |

### 4. `school_admin_energy_page` (985) — ✅ **เสร็จแล้ว 2026-09-06**

> ⚠️ **ประเมินไว้ต่ำเกินจริง** ตอนสำรวจเขียนว่า "ต่อจริงครบ 6 จุด เหลือแค่งาน DoD"
> พออ่านเต็มทั้งไฟล์พบว่ามีของปลอมมากกว่านั้นมาก — เป็นหลักฐานว่า `grep`
> บอกได้แค่ "ไม่ต่อแน่ ๆ" ไม่เคยพิสูจน์ว่า "ต่อครบ"

| ที่พบจริง | แก้เป็น |
|---|---|
| fallback ปลอม 10 ตัว (`?? 4.5` `?? 18.0` `?? 88.5` `?? 'ดีเยี่ยม'` `?? 4520.5` `?? 5160.0` `?? 79.0` `?? 'ดี'` `?? 340.2` `?? 357.0`) — **ลอกมาจาก `school_admin_screenshot_test.dart`** | `ยังไม่มีข้อมูล` / `โหลดไม่สำเร็จ` แยกกัน |
| บล็อกรายอาคาร hardcode 4 แท่ง | empty state + บอกว่าต้องระบุอาคารให้มิเตอร์ก่อน |
| "Smart Energy Insights" อ้าง *"ตรวจพบเครื่องปรับอากาศ…เกิน 8 ชม."* `"ไม่มีสัญญาณท่อรั่วซึม"` `"ประหยัด ฿2,860"` | คำนวณจาก `current`/`previous` จริงเท่านั้น |
| `catch (_) {}` | error banner + ปุ่มลองใหม่ |
| ปุ่มส่งออก fake success | disable + tooltip |
| **backend ส่ง `disclaimer` / `isRateDefault` / `deviceCount` มาให้ แต่หน้าใช้ 0 ครั้ง** | แสดงทั้งสามอย่าง |

**เจอเพิ่มตอนเปิดเบราว์เซอร์จริง (ไม่เห็นจาก unit test):** RPC รวมยอดด้วย
`coalesce(sum(...), 0)` โรงเรียนที่**ไม่มีมิเตอร์เลย**จึงได้แถวสมบูรณ์ที่อ่านว่า
`0.0 kWh` — หน้าเลยประกาศว่า "ใช้ไฟศูนย์หน่วย" ทั้งที่ไม่มีอะไรวัด
ใช้ `deviceCount` เป็นตัวแยก "วัดแล้วได้ศูนย์" ออกจาก "ไม่มีอะไรวัด"

test: `test/school_admin/school_admin_energy_page_connection_test.dart` (9 ชุด)

### 5. `school_admin_esg_page` (767) — ✅ **เสร็จแล้ว 2026-09-06**

> 🔴 **บั๊กร้ายแรงที่สุดที่เจอในเซสชันนี้ ไม่ใช่ตัวเลขปลอม แต่เป็น *คำตัดสิน* ปลอม**
> คะแนนสองด้านอ่าน `?? 0.0` ทั้งคู่ โรงเรียนที่ไม่มีมิเตอร์เลย (และโรงเรียนที่โหลดพัง)
> จึงได้ **0/100 พร้อมป้ายแดง "ต้องปรับปรุง"** บนหน้าที่ผู้อำนวยการอาจส่งต่อขึ้นไป
> — เป็นการตัดเกรดโรงเรียนจากข้อมูลที่ไม่เคยเก็บ

| ที่พบจริง | แก้เป็น |
|---|---|
| คะแนนรวม `?? 0.0` → 0/100 "ต้องปรับปรุง" | เฉลี่ยเฉพาะด้านที่มีคะแนนจริง · ไม่มีเลย = วงกลมเทา `—` "ยังไม่มีคะแนน" |
| ป้าย `ลดคาร์บอน ~X kg CO₂e` | **ติดป้ายกลับด้าน** — สูตรคำนวณคาร์บอนที่ *ปล่อยจาก* ไฟที่ใช้ ยิ่งใช้ไฟมากตัวเลข "ลด" ยิ่งเยอะ → เปลี่ยนเป็น `คาร์บอนจากไฟฟ้า` + ตั้งชื่อค่าคงที่ `kGridEmissionFactorKgCo2ePerKwh` พร้อมอ้างที่มา (TGO) |
| มาตรการ 3 ข้อพร้อมป้ายสถานะ | เหลือข้อเดียวที่ระบบสังเกตได้จริง — ผูกกับ `device_schedules` (`enabled` + `lastTriggeredAt`) · ลบ "ตรวจจับน้ำรั่วไหล — พร้อมทำงาน" และ "เป้าหมายลดคาร์บอน 5% — ตามแผนงาน" ที่ไม่มีตารางรองรับ |
| ปุ่มส่งออก fake success | disable + tooltip · header เปลี่ยน `Row`→`Wrap` กัน overflow |
| การ์ด "ขอบเขตและที่มาของข้อมูล" | **เก็บไว้** — เป็นส่วนที่ซื่อสัตย์อยู่แล้ว บอกตรง ๆ ว่า Waste/Social/Governance ยังไม่มีข้อมูลจึงไม่แสดงตัวเลข |

test: `test/school_admin/school_admin_esg_page_connection_test.dart` (12 ชุด)

**ยืนยันในเบราว์เซอร์จริงแล้วทั้งสองหน้า** (login school_admin → เปิดหน้าจริง)
regression: `+239 -17` — 17 ตัวที่ fail เป็นของเดิมทั้งหมด ไม่มีใน School Admin

### 6. `school_admin_device_control_page` (783) — ✅ **เสร็จแล้ว 2026-09-06**

> **หน้าที่โกหกผู้ใช้ชัดที่สุดในกลุ่ม** — ผู้ดูแลกดปิดไฟ ระบบขึ้นว่า "สำเร็จ"
> สวิตช์เลื่อนไปตำแหน่งปิด แต่ที่เกิดขึ้นจริงคือ **เขียนแถวลงคิวคำสั่งเท่านั้น**
> ถ้าอุปกรณ์ออฟไลน์ ไฟยังเปิดค้างอยู่ แต่จอบอกว่าดับแล้ว

⚠️ **แก้ที่ผมเขียนไว้ตอนสำรวจ:** เดิมเขียนว่าใช้ `ack_device_command` +
`poll_device_commands` ได้ — **ผิด** ตรวจลายเซ็นจริงแล้วทั้งคู่รับ `p_device_token`
ไม่ใช่ `p_token` คือเป็น RPC ที่**ตัวอุปกรณ์เรียกเอง** แอดมินเรียกไม่ได้
ตัวที่ใช้ได้จริงคือ **`list_device_relay_states(p_token, p_device_id)`**

| ปัญหา | แก้เป็น |
|---|---|
| บอก "สำเร็จ" ตอนแค่เข้าคิว | "ส่งคำสั่ง…เข้าคิวแล้ว รออุปกรณ์ยืนยัน" แล้ว poll `list_device_relay_states` จนอุปกรณ์รายงานสถานะที่ขอมาจริง จึงเปลี่ยนเป็น "อุปกรณ์ยืนยันว่าเปิด/ปิดอยู่ · <เวลา>" · ถ้าไม่ยืนยันภายในกำหนด → "อุปกรณ์ยังไม่ยืนยัน — ตรวจสอบหน้างาน" |
| สวิตช์เริ่มที่ OFF เสมอ (อ่านจาก `_optimisticState` ที่เริ่มจาก map ว่าง) | อ่านสถานะจริงจาก `device_relay_states` · **อุปกรณ์ที่ไม่มีแถว = "ยังไม่ทราบสถานะ" ไม่ใช่ "ปิด"** |
| KPI "สั่งเปิดไว้ (เครื่องนี้)" นับเฉพาะที่กดในแท็บนี้ (เป็น 0 เสมอตอนโหลด) | "เปิดอยู่ (ยืนยันแล้ว)" นับจากที่อุปกรณ์รายงาน + เพิ่ม KPI "ยังไม่ทราบสถานะ" |
| คำอธิบายอ้างว่าสถานะ "สะท้อนตามคำสั่งล่าสุดที่สั่งงานจากระบบ" | อธิบายวงจรจริง + บอกเวลาที่ยืนยันล่าสุด |
| `'โหลด...ไม่สำเร็จ: $e'` / `'สั่งงานไม่สำเร็จ: $e'` โชว์ exception ดิบ | ข้อความสำหรับผู้ใช้ ไม่มี raw backend text |

**เพิ่มใน `shared_core`:** `DeviceRelayState` model + `RealtimeService.listDeviceRelayStates()`
(RPC มีอยู่แล้วแต่ไม่เคยมีใครห่อ) · `queueDeviceCommand` คืน command id แทนที่จะทิ้ง

**บทเรียนจากการเขียน test:** ตัวจับ timeout เดิมใช้ `DateTime.now()` ซึ่ง
`tester.pump(Duration)` เลื่อนไม่ได้ ทำให้เส้นทาง "อุปกรณ์ไม่ยืนยัน" ทดสอบไม่ได้เลย
— เปลี่ยนเป็นนับจำนวนรอบ poll แทน

test: `test/school_admin/school_admin_device_control_connection_test.dart` (9 ชุด)

**ยืนยันในเบราว์เซอร์จริง** — กดสวิตช์ → เห็น "เข้าคิวแล้ว" → ใส่ ack ใน DB จำลอง
อุปกรณ์ตอบกลับ → รีเฟรช → KPI ขยับจาก 1/6 เป็น 2/6 และ "ยังไม่ทราบสถานะ" ลดจาก 4 เหลือ 3

<details><summary>SQL ที่ใช้จำลองอุปกรณ์ตอบรับ (สำหรับตรวจซ้ำ)</summary>

```sql
-- ให้อุปกรณ์รายงานสถานะ (สิ่งที่ ack_device_command ทำจริง)
insert into device_relay_states (device_id, relay_no, state, updated_at)
values ('<device_id>', 1, true, now())
on conflict (device_id, relay_no) do update
  set state = excluded.state, updated_at = excluded.updated_at;
```
ลบทิ้งเมื่อตรวจเสร็จ — อย่าปล่อยค้างไว้เป็น fixture ที่ไม่มีใครรู้ที่มา
</details>

### 7. `school_devices_page` (3,114)

ต่อจริง: `listSchoolDevices` `fetchAuditLogs`

| ปุ่ม/ข้อมูลปลอม | verdict | ทางแก้ |
|---|---|---|
| "ลงทะเบียนอุปกรณ์ใหม่เรียบร้อยแล้ว" | **A** | `register_device` มี `p_token` จริง |
| "แก้ไขข้อมูล X สำเร็จ" | **C** | ไม่มี `update_device` ที่รับ `p_token` (`archive_school_device` ใช้ไม่ได้ — ดูหัวข้อ 🔴) |
| "เปิดใช้งาน X เรียบร้อยแล้ว" | **C** | เหตุผลเดียวกัน |
| "พิมพ์ QR Code สำเร็จ" | **D → disable** | |
| "เตรียมข้อมูลส่งออก Excel/CSV เรียบร้อย" | **D → disable** | |
| `_DeviceHealthData`(1283) | ตรวจว่ามาจาก `status`/`last_seen_at` จริงหรือแต่ง | |

### 8. `school_students_page` (2,942)

ต่อจริง: `getAllUsers` เท่านั้น

| ปุ่ม/ข้อมูลปลอม | verdict | ทางแก้ |
|---|---|---|
| "บันทึกข้อมูลนักเรียนเรียบร้อยแล้ว" (แก้ชื่อ) | **A** | `update_user_profile(p_token, p_target_user_id, p_first_name, p_last_name)` — school_admin แก้คนในโรงเรียนตัวเองได้ (ตรวจแล้วที่ `20260716000000:68`) **แต่ได้แค่ชื่อ-นามสกุล** ฟิลด์อื่นที่ฟอร์มเก็บต้องตัดออก |
| "เพิ่มนักเรียนเรียบร้อยแล้ว" | **C** | **ไม่มี RPC สร้างผู้ใช้เดี่ยว** มีแต่ `import_school_users_batch_for_school_admin` → เลือกทาง: เรียก batch ด้วยแถวเดียว หรือเขียน `create_school_user(p_token, …)` |
| "ส่งออกข้อมูลนักเรียน … สำเร็จแล้ว" | **D → disable** | |
| นักเรียนปลอมโผล่ตอนผลลัพธ์ว่าง | — | ลบ fallback ใช้ empty state |

⚠️ ถ้าเลือกทาง batch ต้องแก้ blocker รหัสผ่านของหน้า import ก่อน (ข้อ 14)

### 9. `school_teachers_page` (3,691)

ต่อจริง: `getAllUsers` `listHomeroomAssignments` `setHomeroomTeacher` `removeHomeroomTeacher`

| ปุ่ม/ข้อมูลปลอม | verdict | ทางแก้ |
|---|---|---|
| `_divisions`(17) + `_academicSubjects`(26) — ฝ่าย/กลุ่มสาระ | **D → ลบ** | **ไม่มีตาราง `departments` หรือ `subject_groups` และ `users` ไม่มีคอลัมน์ `position`/`department`/`phone`** — ช่องว่างเดียวกับ `director_teachers` ฝั่ง Executive |
| "บันทึกข้อมูลครูเรียบร้อยแล้ว" | **A (บางส่วน)** | `update_user_profile` ได้แค่ชื่อ-นามสกุล |
| "เพิ่มครูและบุคลากรเรียบร้อยแล้ว" | **A** | ควรเป็น **คำเชิญ** ไม่ใช่สร้างบัญชีตรง → `InvitationService.createInvitation` |
| "$title: บันทึกตัวอย่างเรียบร้อย" | **D → ลบ** | ข้อความบอกตัวเองว่าเป็นตัวอย่าง |
| homeroom write ไม่ atomic | **C** | รวมการแทนที่เป็น RPC เดียว |

### 10. `school_buildings_page` (4,697) — ไฟล์ใหญ่สุดของกลุ่ม

ต่อจริง: `fetchBuildings` `fetchRooms` `fetchAuditLogs` (อ่านอย่างเดียว)

| ปัญหา | verdict | ทางแก้ |
|---|---|---|
| CRUD อาคาร/ห้องทั้งหมด | **C** | มีแต่ `import_school_buildings_batch` / `import_school_rooms_batch` — **ไม่มี create/update/delete รายตัวที่รับ `p_token`** ต้องเขียนใหม่ 4–6 ตัว |

**คลาส: แพงสุดในกลุ่ม** (ไฟล์ใหญ่ + RPC ใหม่หลายตัว)

### 11. `school_settings_page` (1,702)

ต่อจริง: `fetchAuditLogs` เท่านั้น

| ปัญหา | verdict | ทางแก้ |
|---|---|---|
| การตั้งค่าโรงเรียน | **C** | ตาราง `school_settings` **มีจริง** (`electricity_rate_thb`, `retention_policy`, `pdpa_camera_ready/approved_by/approved_at`) แต่ **ไม่มี RPC อ่าน/เขียนที่รับ `p_token`** — มีแค่ `set_school_utility_rates` (แตะ rate อย่างเดียว) และ `update_school_for_super_admin` (คนละสิทธิ์) |
| toggle นอกเหนือคอลัมน์ที่มีจริง | **D → ลบ/disable** | ให้แก้ได้เฉพาะฟิลด์ที่มีในตาราง |
| backup / reset | **D → disable** | ปุ่มอันตรายที่ไม่มี backend |

### 12. `school_admin_profile_page` (1,401)

ต่อจริง: `fetchAuditLogs`

| ปัญหา | verdict | ทางแก้ |
|---|---|---|
| แก้ชื่อตัวเอง | **A** | `update_user_profile` (สาขา self-edit) |
| เปลี่ยนรหัสผ่าน | **A** | `request_password_reset_otp` + `confirm_password_reset` — **ไม่มี** RPC เปลี่ยนรหัสในเซสชัน ห้ามรายงานว่าเปลี่ยนสำเร็จถ้าไม่ได้เรียกอะไร |
| ออกจากระบบทุกอุปกรณ์ | **A** | `auth_sign_out_all` |
| เบอร์โทร / รูปโปรไฟล์ / การแจ้งเตือนรายคน | **D → ลบ** | `users` ไม่มีคอลัมน์เหล่านี้ ไม่มีตาราง preference |

### 13. `school_reports_page` (1,147) — ทำค้างไว้

loading/data/empty/error แยกเสร็จแล้ว + มี `school_reports_page_connection_test.dart`

| ที่เหลือ | verdict |
|---|---|
| filter / กราฟ / insight | สร้างจาก `fetchDashboardSummary` + `fetchAuditLogs` จริงเท่านั้น |
| export | **D → disable** |

### 14. `school_import_page` (1,963)

ต่อจริง 5 ชนิด (users/buildings/rooms/devices + google sheet)

| ปัญหา | verdict |
|---|---|
| 🔐 **สร้างผู้ใช้ด้วยรหัส `Test1234!` และไม่บังคับเปลี่ยน** | **blocker** — `users.must_change_password` มีอยู่แล้ว ต้องบังคับใช้ |
| ประวัติ import อยู่ในหน่วยความจำ (`_logs` เริ่มจาก `[]`) | **A** — ใช้ `fetchAuditLogs` จริง |

### 15. `school_scan_page` (850) — ❌ ไม่ import `shared_core` เลย

| สิ่งที่หน้านี้อ้างว่าทำได้ | verdict | ทางแก้ |
|---|---|---|
| สแกนโค้ดอุปกรณ์ → แสดงข้อมูลจริง | **A** | `list_school_devices` มี `kit_code`/`device_code` → resolve ได้ (หรือ **C** ถ้าอยากได้ `get_device_by_code` ที่เร็วกว่า) |
| ประวัติการสแกน | **D** | ไม่มีตารางเก็บ scan event และไม่มีอะไรเขียนลง |
| นำทางไปยังตำแหน่ง | **D → ลบ** | |

---

## สรุป RPC ที่ต้องเขียนใหม่ (verdict C)

เรียงตามจำนวนหน้าที่ปลดล็อกได้

| # | RPC ที่เสนอ | ปลดล็อก | หมายเหตุ |
|---|---|---|---|
| 1 | `get_utility_usage_by_building(p_token, p_metric, p_days)` | `school_resources` **+ `director_environment` (Executive)** | ใช้ร่วม 2 สิทธิ์ — คุ้มที่สุด |
| 2 | `create_school_user(p_token, …)` + บังคับ `must_change_password` | `school_students` `school_teachers` `school_import` | แก้ blocker ความปลอดภัยไปพร้อมกัน |
| 3 | `update_school_device(p_token, …)` | `school_devices` | แทน `archive_school_device` ที่ใช้ไม่ได้ |
| 4 | `get_school_settings` / `update_school_settings(p_token, …)` | `school_settings` | จำกัดเฉพาะคอลัมน์ที่มีจริงใน `school_settings` |
| 5 | CRUD อาคาร/ห้องรายตัว (4–6 ตัว) | `school_buildings` | แพงสุด |
| 6 | `set_homeroom_teacher` แบบ atomic | `school_teachers` | รวม remove+set เป็นทรานแซกชันเดียว |

**ทุกตัวต้อง `revoke ... from service_role` ด้วย** (โปรเจกต์นี้เจอ leak แบบนี้มาแล้ว 3 ครั้ง)

## สิ่งที่ไม่มีสคีมารองรับ (verdict D — ต้องตัดสินใจ ไม่ใช่เขียนโค้ด)

1. **เมทริกซ์สิทธิ์รายบทบาท** — ไม่มีตารางนิยาม และตารางที่โชว์อยู่ยังอ้างบทบาทที่ถูกยุบไปแล้ว
2. **ฝ่าย (departments) / กลุ่มสาระ (subject_groups)** — ไม่มีตาราง `users` ไม่มี `position`/`department`/`phone` · กระทบทั้ง `school_teachers` และ `director_teachers`
3. **Export เป็นไฟล์ (PDF/Excel/CSV)** — ไม่มี pipeline ที่ไหนเลย โผล่เป็นปุ่มปลอมใน 5 หน้า
4. **ประวัติการสแกน** — ไม่มีตาราง ไม่มีตัวเขียน
5. **การแจ้งเตือนรายบุคคล / preference** — ไม่มีตาราง
6. **พิมพ์ QR ประจำอุปกรณ์** — ไม่มี

> ข้อ 2 กับ 3 ซ้ำกับฝั่ง Executive — ตัดสินใจครั้งเดียวใช้ได้ทั้งสองสาย

---

## ลำดับที่แนะนำ

จัดโดยดู **ต่อสายได้เลย → ราคาถูก → ปลดล็อกหลายหน้า → แพง**

| ลำดับ | หน้า | คลาส | เหตุผล | เซสชัน |
|---:|---|---|---|---:|
| ~~1~~ | ~~`energy` + `esg`~~ | A | ✅ **เสร็จ 2026-09-06** — ดูรายละเอียดที่หัวข้อ 4 และ 5 | 1 |
| ~~2~~ | ~~`device_control`~~ | A | ✅ **เสร็จ 2026-09-06** — ดูหัวข้อ 6 | 1 |
| 3 | `dashboard` | A | หน้าแรกที่ทุกคนเห็น ตัวเลขไฟ/น้ำปลอมแทนที่ด้วย UtilityService ได้เลย | 1 |
| 4 | **`permissions`** | A + ลบ D | งานค้างครึ่งทางอยู่แล้ว · `InvitationService` พร้อมแล้ว · ลบเมทริกซ์ปลอม | 1 |
| 5 | `reports` | A | ทำค้างไว้ เหลือ filter/กราฟ + disable export | 0.5 |
| 6 | `profile` | A | เล็ก ต่อได้ด้วย RPC ที่มีอยู่ทั้งหมด | 0.5 |
| 7 | `scan` | A | ต่อจากศูนย์ แต่ scope เล็กลงมากถ้าตัด D ออก | 1 |
| 8 | 🔐 `import` + `create_school_user` | C | **แก้ blocker รหัสผ่าน** และปลดล็อกข้อ 9–10 | 2 |
| 9 | `students` | A + C#2 | ต้องรอ RPC สร้างผู้ใช้จากข้อ 8 | 1.5 |
| 10 | `teachers` | A + C#2 + C#6 | เหมือนข้อ 9 + homeroom atomic + ลบฝ่าย/กลุ่มสาระ | 2 |
| 11 | `resources` + RPC C#1 | C | RPC ใหม่ที่ Executive ใช้ต่อได้ด้วย | 2 |
| 12 | `devices` + RPC C#3 | C | | 1.5 |
| 13 | `settings` + RPC C#4 | C | | 1.5 |
| 14 | `buildings` + RPC C#5 | C | ไฟล์ 4,697 บรรทัด + RPC ใหม่ 4–6 ตัว | 2.5 |

**รวม ~19 เซสชัน** (master plan เดิมประเมิน 16–18 สำหรับ 15 หน้าเท่ากัน — ใกล้เคียง)

### จุดที่ทำขนานกับสาย Executive ได้/ไม่ได้

- ลำดับ 1–7 **ขนานได้เต็มที่** — แตะแค่ `pages/school_admin/` ไม่ชน
- ลำดับ 8–14 **มี migration** — ต้องคุยเรื่องเลข timestamp กับสาย Executive
  ไม่งั้นชนกัน (สอง agent สร้าง migration พร้อมกันได้เลขซ้ำ)
- RPC C#1 (`get_utility_usage_by_building`) ใช้ร่วมสองสาย → **ให้สายเดียวเขียน อีกสายรอ**

### ก่อนเริ่มต้องตัดสินใจ 3 เรื่อง

| # | เรื่อง | บล็อก | ตัวเลือก |
|---|---|---|---|
| S1 | เมทริกซ์สิทธิ์ (`permissions`) | ลำดับ 4 | ลบทิ้ง (แนะนำ) / สร้างตารางนิยามสิทธิ์จริง |
| S2 | ฝ่าย + กลุ่มสาระ | ลำดับ 10 · Executive 3.2 | ลบทิ้ง / เพิ่มคอลัมน์+ตาราง (เป็นฟีเจอร์ ไม่ใช่การต่อสาย) |
| S3 | ปุ่ม Export ใน 5 หน้า | ลำดับ 3,5,7,9,12 | disable พร้อมเหตุผล (แนะนำ) / สร้าง export pipeline จริง |
