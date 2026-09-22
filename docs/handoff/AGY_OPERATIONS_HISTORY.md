# ประวัติการเรียก Antigravity CLI (agy) และคู่มือส่งต่องานให้ Claude

บันทึกวันที่ 2026-09-22 โดย Codex ตามคำขอผู้ใช้ ครอบคลุมตั้งแต่เริ่มเรียกวันที่ 2026-09-21 จนถึงการสาธิต Windows-MCP ครั้งล่าสุด เวลาในเรื่องเป็นเวลาไทย เว้นแต่ระบุ UTC

เอกสารนี้เป็นประวัติการทดลอง ไม่ใช่การรับรองสถานะปัจจุบันของระบบ ก่อนทำงานให้รัน `./scripts/state.sh` และตรวจเครื่องมือ/ฐานข้อมูลจริงอีกครั้ง หลักฐานบางส่วนอยู่เฉพาะเครื่องผู้ใช้และไม่ได้ commit เพื่อไม่เผยข้อมูลจากหน้าจอหรือ session

## อ่านก่อนรับงานต่อ

- ผู้ใช้ต้องการให้ agy ทำงานบน Chrome ที่มองเห็นได้ โดย Codex/Claude กำหนดงานเป็นขั้น ตรวจผลจริง และค่อยเพิ่มขอบเขต ผู้ใช้เลือก `gemini-3.8-flash-high` สำหรับรอบถัดจากการทดลอง Pro
- สถานะ UI ที่เห็นครั้งล่าสุด: USER APP ที่ `http://127.0.0.1:8085/` เปิดฟอร์มสร้างโรงเรียนค้างไว้ ชื่อ `AGY live demo` **ยังไม่กดบันทึก** ตรวจหน้าจอใหม่ก่อนทำงานต่อ หากจะเริ่มงานอื่นให้ปิด/ยกเลิกฟอร์มทดลอง
- agy เป็นผู้กรอก demo ครั้งล่าสุดเอง Codex ตรวจภาพหน้าจอซ้ำ การกรอก demo ไม่ได้สร้างโรงเรียนเพิ่ม
- ตรวจ config ซ้ำตอนเขียนเอกสาร: MCP `windows-observe-test` ยังลงทะเบียนอยู่ และไม่เหลือ temporary allow rules ของ server นี้ หลังจบงานก่อนหน้าได้คืนรายการเครื่องมือเป็น Snapshot-only
- ไม่ได้ให้อำนาจ agy แก้ production หรือเขียนโค้ดแบบไม่จำกัด การอนุญาตงานหนึ่งไม่ใช่การอนุญาตงานอื่น

## 1. วันที่ 21 กันยายน: เริ่มเชื่อมต่อและทดสอบอ่านโค้ด

| เวลา | สิ่งที่สั่ง / ผลที่ตรวจได้ |
|---|---|
| 14:45:43 | เรียก agy ให้ตอบภาษาไทยว่ารับข้อความและพร้อมรับ bounded task ห้ามใช้ tools อ่านไฟล์ รันคำสั่ง delegate หรือแก้ไขสิ่งใด |
| 14:46:05 | ได้คำตอบและ exit code 0 ยืนยันเฉพาะการเรียก CLI/รับคำตอบ ยังไม่ได้ตรวจโปรเจกต์ โมเดลรอบแรกไม่ได้ระบุในหลักฐานส่วนนี้ |
| หลังทดสอบ | ผู้ใช้ tail log ไม่เจอในตอนแรก และเคยแยก `-Encoding UTF8 -Wait` เป็นอีกคำสั่ง ทำให้ PowerShell error; แก้เป็นคำสั่งบรรทัดเดียว ปัญหาภาษาไทยเพี้ยนแก้ที่การบันทึก UTF-8 แล้ว log ปัจจุบันอ่านคำตอบได้ |
| 16:11:19 | Level 1 read-only audit เรื่อง direct alerts reads/subscriptions เทียบ RPC ใน worktree แยก `agy-alerts-review` ที่ e822a0f; agy เรียก `git status` แต่ headless ไม่สามารถถาม command permission จึง auto-denied ถึงแม้ JSON จะขึ้น SUCCESS และ exit 0 |
| 16:12:27 | จำกัดให้ใช้เครื่องมือค้นหา/อ่าน ไม่ใช้ shell; agy รายงานข้อจำกัดเครื่องมือและหยุด ยังนับว่า audit ไม่สำเร็จ |
| 16:13:25 | ลดเป็น Level 0 ระบุเพียงสองไฟล์ เพื่อแยกปัญหาการค้นหาออกจากการอ่าน |
| 16:17:05 | ระบุ `gemini-3.1-pro-high` ชัดเจน ใช้ view_file เฉพาะสองไฟล์ที่อนุญาต Codex ตรวจ RPC, p_token, subscription กับโค้ดจริงแล้วตรง ไม่พบ diff/ไฟล์ใหม่/HEAD เปลี่ยน ผ่านเฉพาะอ่านและรายงาน |
| 16:19:50 | ทดลอง `gemini-3.8-flash-high` กับสองไฟล์เดียวกัน ผ่านการตรวจแบบเดียวกัน Flash 15.35 วินาที เทียบ Pro 23.86 วินาที เป็นงานเดียวครั้งเดียว **ไม่ใช่ benchmark ทั่วไป** |
| 16:23:59 | ขยายเป็น alerts audit หกไฟล์ ใช้ Flash High; มี provider 500 จึงไม่ยกระดับให้แก้ไข Codex ตรวจรายงานด้วยตนเอง |
| 16:38:00 | Codex เป็นผู้ดำเนินการ alerts security_invoker ใน production และตรวจ pgTAP 18/18, anonymous REST denied 401/42501 (96ecb24) ไม่ใช่ agy deploy |

การทดลองช่วงนี้มีขอบเขตห้ามอ่าน env/secrets/โครงการข้างเคียง ห้ามเขียนไฟล์ รัน build/test ติดตั้ง package เข้าฐานข้อมูล commit/push หรือเรียก subagent เพิ่ม ข้อจำกัดดังกล่าวเป็นขอบเขตของการทดลอง ไม่ใช่ข้อสรุปว่าเครื่องมือทำสิ่งเหล่านั้นไม่ได้

## 2. วันที่ 21 กันยายน: เปิด Chrome ให้ผู้ใช้ดู

browser subagent เริ่มต้นหา DevToolsActivePort ไม่พบ เพราะ Chrome เดิมไม่ได้เปิด remote debugging การเปิดหน้าต่างใหม่ด้วย profile เดิมไม่รับประกันว่าจะเปิดพอร์ตเพิ่มได้ จึงใช้ profile ทดลองแยก ไม่จำเป็นต้องปิด Chrome ทุก process

PowerShell ต้องวางคำสั่งนี้เป็น **หนึ่งบรรทัด**:

```powershell
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --user-data-dir="$env:LOCALAPPDATA\agy-browser-test" --no-first-run https://example.com
```

ผู้ใช้เคยแยก flags ไปอีกบรรทัด จึงเกิด Missing expression after unary operator '--' ต่อมาตรวจ `http://127.0.0.1:9222/json/version` ได้ Chrome 153 และ webSocketDebuggerUrl; agy พบแท็บ json/version และ Example Domain และผู้ใช้ยืนยันว่าเห็นการสาธิตแล้ว อย่าคัดลอก websocket UUID เก่ามาใช้ใหม่

การต่อพอร์ตสำเร็จพิสูจน์การเชื่อมต่อเท่านั้น ยังไม่รับรองความเสถียรของ browser subagent หรือความพร้อมทั้งแอป

## 3. วันที่ 22 กันยายน: browser subagent ตรวจงานและสร้างโรงเรียนจริง

### วิธีเรียกที่ใช้ได้ในรอบนี้

CLI อยู่ที่ `C:\Users\user\AppData\Local\agy\bin\agy.exe` พบการอัปเดตจาก 1.2.6 เป็น 1.2.7 ระหว่างการทดลอง ควรตรวจ version/help ใหม่เมื่อใช้งาน

การเริ่ม browser ผ่าน print mode ติดขัดหลายครั้ง จึงใช้ interactive session แล้วพิมพ์ `/browser` ใน prompt จริง การใส่ `/browser` เป็นข้อความเริ่มต้นของ `--prompt-interactive` ในรอบที่ลองไม่ได้ขยาย slash command ตามต้องการ และถูกหยุดเมื่อเริ่มอ่านเอกสาร/config นอกงานที่ต้องการ

- Parent conversation: `8061c1dc-9936-46d8-85d2-1d3791a3feab`
- Browser child: `56d122c2-1b9b-476b-9bbb-a5381e8efe4f`
- ใช้ child เดิมต่อเนื่อง หลีกเลี่ยงเปิด agy browser อีก process พร้อมกัน เพราะอาจกระทบ browser server
- PTY เคยทำอักขระ `@`/`:` หาย ต้องตรวจค่าที่แสดงใน UI และอ่านข้อมูล canonical กลับ ไม่เชื่อข้อความที่ตั้งใจพิมพ์อย่างเดียว

### งานที่ทำและผู้รับผิดชอบ

agy เปิดหน้า Supabase และ USER APP ให้ดู ส่วน Codex ตรวจฐานข้อมูล/ผลอีกชั้น ช่วงที่ตรวจพบ CPU ประมาณ 3–4%, RAM 55%, disk 19%, connections 15/60; sensor_latest ตรวจได้ 7.396 ms และ delta 38 calls เฉลี่ย 7.375 ms ไม่มี temp writes ค่านี้เป็นการวัดเฉพาะช่วง ไม่ใช่คำรับรองตลอดเวลา ส่วนภาพ CPU 95% → 18% เป็นหลักฐานจากวันที่ 21

งานแก้ performance อยู่ใน commit `7bdb439` (sensor_latest) และ `e822a0f` (polling lifecycle) ให้ดู git/เอกสารเดิม ไม่ควรสรุปว่า agy เป็นผู้แก้ทั้งหมด

ผู้ใช้อนุญาตสร้างโรงเรียนทดสอบ agy กรอก UI และกดสร้างหนึ่งครั้งวันที่ 22 ประมาณ 10:00:50 จากนั้น Codex อ่านฐานข้อมูลยืนยัน:

| ฟิลด์ | ค่าที่ตรวจได้ |
|---|---|
| ชื่อ | โรงเรียนดิลิออน ทดสอบ |
| รหัส | SCH-202609-9990 |
| ID | 39a4d974-d125-4eab-96c2-1a801126790c |
| จังหวัดทดลอง | ข้อมูลทดสอบ |
| Email ทดลอง | school-admin@dilion-test.invalid |
| แพ็กเกจ | Basic; max users 30; max devices 30 |
| created_at | 2026-09-22 03:00:50.383333+00 |
| ข้อจำกัด | พบ creation audit หนึ่งรายการ; users 0; **ยังไม่ได้สร้างบัญชีแอดมินโรงเรียน** |

สร้างผ่าน UI → RPC ไม่ใช่ SQL INSERT จาก Codex ข้อมูลติดต่อเป็นข้อมูลทดสอบ และไม่ได้ส่งคำเชิญ รหัสโรงเรียนสร้างโดย RPC แบบสุ่ม 1000–9999 ต่อเดือน มี unique index และ retry สูงสุดห้าครั้ง: ตัวสุ่มมีโอกาสชน แต่ฐานข้อมูลไม่ยอมเก็บรหัสซ้ำ รหัส 9990 ไม่ได้แปลว่ามีโรงเรียน 9,990 แห่ง

หลังบันทึกพบ Flutter red screen (`TextEditingController was used after being disposed` / `_dependents.isEmpty`) จึงหยุด ไม่กดสร้างซ้ำ อ่านฐานข้อมูลก่อน และ reload เห็นโรงเรียนที่สร้างแล้ว

Codex แก้ dialog lifecycle ใน `7c19399` ให้รอ route.completed ก่อน dispose controllers พร้อมทดสอบ regression จาก red เป็น green การให้ agy ตรวจหลังแก้ติด Chrome DevTools timeout สามครั้ง จึงหยุด browser child อย่างชัดเจน **ห้ามนับรอบนั้นว่าผ่าน** ต่อมา Codex ใช้ Computer Use ของตนเองคลิกกรอกแล้ว Cancel และ X ผ่านโดยไม่มี red screen; บันทึก `34f270a` เป็นการตรวจโดย Codex ไม่ใช่ agy

ดู [School dialog recovery](SCHOOL_DIALOG_RECOVERY_2026_09_22.md) และ [Alerts security](ALERTS_ACCESS_SECURITY_2026_09_21.md) สำหรับรายละเอียดงานที่เกี่ยวข้อง

## 4. วันที่ 22 กันยายน: ทดลอง Windows-MCP ให้ agy คลิกแบบมองเห็นได้

ไม่พบวิธีรองรับให้ agy ใช้ OpenAI Computer Use (`@oai/sky`) ตัวเดียวกับ Codex โดยตรง จึงทดลอง MCP แยกของ CursorTouch/Windows-MCP ไม่ใช่ปลั๊กอิน OpenAI

ติดตั้ง `windows-mcp==0.8.5` ในพื้นที่ทดลอง `%TEMP%\agy-windows-mcp-test` ใช้ managed Python 3.13.15 (bootstrap Python 3.11 + uv) และลงทะเบียนชื่อ `windows-observe-test` แบบ stdio ไม่ได้ตั้ง scheduled task หรือ startup service ตัว executable อยู่ใน Temp จึงอาจหายเมื่อระบบล้างไฟล์ชั่วคราว

### ลำดับผลการทดลอง

1. `344a4115-7521-48df-9a18-aa5b19cf138c`: headless เรียก Snapshot แต่ MCP permission ถูก auto-denied; JSON SUCCESS/exit 0 ไม่ใช่ผ่าน
2. `72637f66-fa8b-4b70-8857-9dc1d503654d`: อนุญาต Snapshot เฉพาะงานแล้ว แต่เจอ provider 503 Eligibility check unavailable; คืน permission ใน finally
3. Local MCP client ยืนยัน server ตอบ Snapshot ได้ พบว่า `use_ui_tree=false` ข้าม window enumeration ทำให้รายงานไม่พบ Chrome ไม่ได้แปลว่าเชื่อมต่อเสีย ต้องใช้ `use_ui_tree=true` เมื่อต้องการหา UI
4. `d5df803a-1fd6-4290-991e-a81e2d910b61`: agy เรียก Snapshot สำเร็จ ตรวจ tool result จริง แล้วถอน temporary permission
5. `121958ec-8088-48d9-899a-700d7fa82b00`: **ผ่าน demo click/type/cancel**; agy switch USER APP → Snapshot → คลิก Create New → Snapshot → กรอก `AGY Windows MCP Demo` → Snapshot ยืนยันค่า → Cancel → Snapshot ยืนยันปิดฟอร์ม Codex ตรวจหน้าจอซ้ำ รายงานรอบนี้ 81.901 วินาที ไม่ได้บันทึกโรงเรียนเพิ่ม
6. `b0247a8e-256c-4bc4-9b81-c559e18262bd`: ทดลองช้าลงให้ผู้ใช้ดู โดยใช้ Wait 5 วินาที; รอบแรกหมดเวลา และ resume เปิดฟอร์มได้แต่ยังไม่ได้พิมพ์ จึงส่ง STOP และได้รับคำตอบ `The demonstration is stopped.` ไม่ใช่ผ่านครบ flow
7. กลับไป conversation ที่เคยสำเร็จ `121958ec-8088-48d9-899a-700d7fa82b00` จำกัดเหลือ Snapshot/App/Type: agy ตรวจหน้าจอใหม่แล้วกรอก `AGY live demo` โดย `press_enter=false` → Snapshot ยืนยัน → หยุดและปล่อยฟอร์มเปิดให้ผู้ใช้ดู Codex เห็นข้อความจริงในช่อง นี่คือสถานะล่าสุดก่อนเขียนเอกสาร

รอบ demo แรก agy ยังอ่าน schema ของ tool และ output ที่ระบบสร้างด้วย view_file จึงไม่ควรอ้างว่าใช้ MCP อย่างเดียวทุก tool call รอบต่อไปต้องอนุญาตอ่าน schema/output ของงานตนเองให้ชัด แต่ไม่ขยายไปไฟล์ธุรกิจหรือ secrets

เวลา/usage ที่ CLI แสดงเมื่อ resume conversation อาจเป็นยอดสะสม เช่นรอบสุดท้ายแสดง 1142.225 วินาทีและ num_turns 2 ไม่ใช่เวลาพิมพ์ช่องเดียว ห้ามใช้เป็น benchmark

## 5. วิธีเรียกต่อและขอบเขตควบคุม

ตัวอย่างอ่านอย่างเดียว (ตรวจ `agy --help` ของรุ่นที่ติดตั้งก่อน):

```powershell
agy mcp list
agy --model gemini-3.8-flash-high --sandbox --print-timeout 90s --output-format json --print 'งานอ่านอย่างเดียวที่ระบุขอบเขตและหลักฐานที่ต้องส่งกลับ'
```

การ resume ใช้ `--conversation <UUID>` แต่ต้องอ่านสถานะเดิมก่อน ห้าม resume งานเขียนเก่าโดยไม่ตรวจว่าทำไปแล้วหรือยัง `--remote-control` ไม่ใช่หลักฐานว่าควบคุม Windows desktop ได้

ตำแหน่งตั้งค่าในเครื่องนี้:

- MCP: `C:\Users\user\.gemini\config\mcp_config.json`
- Permissions: `C:\Users\user\.gemini\antigravity-cli\settings.json`
- Server: `C:\Users\user\AppData\Local\Temp\agy-windows-mcp-test\server\Scripts\windows-mcp.exe`
- Args ปกติหลังจบ demo: `serve --transport stdio --tools Snapshot`
- Env ของ server: `ANONYMIZED_TELEMETRY=false`, `PYTHONIOENCODING=utf-8`, `WINDOWS_MCP_WATCHDOG=false`

Headless ถ้าต้องถามสิทธิ์จะ auto-deny ให้เปิดเพียง tool ที่งานต้องใช้ทั้งที่ server allowlist และ exact permission เช่น `mcp(windows-observe-test/Snapshot)` ไม่ใช้ skip-permissions ทั้งหมด การเพิ่ม permission ชั่วคราวต้องมี try/finally คืนค่า ลบเฉพาะกฎที่เราเพิ่ม รักษากฎเดิม/การแก้ของงานอื่น แล้วคืน server เป็น Snapshot-only

Automatic approval review เคยปฏิเสธการพิมพ์ snapshot เต็มเพราะอาจเปิดเผยหน้าต่างอื่น และปฏิเสธการเพิ่ม permission ที่ไม่มี cleanup แก้ด้วยการสรุปเฉพาะหน้าต่างเป้าหมายและ try/finally ไม่ได้ข้ามข้อจำกัด

### ระดับงานสำหรับ Claude ใช้ต่อ (แนวปฏิบัติ ไม่ใช่สิทธิ์ถาวร)

| ระดับ | ขอบเขต | เกณฑ์ก่อนขยายงาน |
|---|---|---|
| 0 | อ่านไฟล์ที่ระบุหรือ Snapshot เป้าหมาย | หลักฐานตรง ไม่มีการแก้ไข/ออกนอกขอบเขต |
| 1 | สำรวจเส้นทาง page/service/RPC แบบอ่านอย่างเดียว | ผู้ควบคุมอ่านโค้ดและตรวจ live contract เอง |
| 2 | UI เปิด/คลิก/กรอก/ยกเลิกใน flow ที่ระบุ | ภาพ/ค่า UI ยืนยันจริง ไม่ save โดยปริยาย |
| 3 | Mutation ที่ผู้ใช้อนุญาตเฉพาะรายการ | กดครั้งเดียว อ่าน canonical/audit กลับก่อนรายงานสำเร็จหรือ retry |

การสร้างโรงเรียนเป็น mutation ที่อนุญาตเฉพาะครั้ง ไม่ได้แปลว่าปลดล็อก Level 3 ทุกงาน ปัจจุบันเหมาะกับงานย่อยที่มีผู้ตรวจ ไม่ควรปล่อย migration/production write แบบกว้าง

ตัวอย่างใบสั่งงาน UI ต่อไป:

> ใช้ USER APP ที่ localhost:8085 เท่านั้น ตรวจหน้าจอใหม่ทุกขั้น เปิดฟอร์ม กรอกชื่อทดสอบที่กำหนดโดยไม่กด Enter ยืนยันค่าด้วย Snapshot แล้วหยุด ห้าม Save/Create/Delete ห้ามแก้ฐานข้อมูลหรืออ่าน env/secrets ถ้าหน้าจอไม่ตรงหรือ tool ล้มเหลวให้หยุดและรายงาน ส่งรายการ action ที่ทำจริงและหลักฐานโดยไม่แสดงข้อมูลหน้าต่างอื่น

ให้ทำงานทีละ flow อย่าให้สอง agent คลิกหน้าต่างเดียวกันพร้อมกัน ห้ามใช้พิกัดเก่าจากเอกสาร หลัง timeout ตรวจ transcript/หน้าจอและส่ง STOP หากจำเป็น ห้ามตีความ process exit หรือ JSON SUCCESS อย่างเดียว ต้องตรวจ denied_actions, stderr, tool results และผลจริงด้วย

## 6. หลักฐานและการดู log

ไฟล์ local ใน root workspace (ไม่ใช่ทุกไฟล์ถูก track ใน git):

- `agy-session.log`: เริ่มเชื่อมต่อ 21 ก.ย., audit, โมเดลและผลตรวจของ Codex
- `agy-browser-demo.log`: browser demo
- `agy-readiness-20260922.log`: งานตรวจรอบ 22 ก.ย.
- `%TEMP%\agy-windows-mcp-test\`: `agy-probe*.json`, `local-probe.log`, `agy-ui-demo.json`, `watch-stage1.json`, `watch-stage1-retry.json`, `watch-stop.json`, `watch-type-only.json`

```powershell
Get-Content 'C:\Users\user\projects\my_first_app\agy-session.log' -Encoding UTF8 -Wait
```

Transcript ของ agy อยู่ใต้ `C:\Users\user\.gemini\antigravity-cli\brain\<conversation UUID>\.system_generated\logs\transcript.jsonl`; ภาพอยู่ใต้ logs/media และบาง tool output อยู่ใต้ steps/<N>/output.txt

อ่านเฉพาะคำสั่ง/tool/result/รายงานที่เกี่ยวข้อง ไม่เผย internal reasoning หรือ secrets ระวัง output.txt เป็น JSON string บรรทัดเดียวที่บรรจุ snapshot ทั้ง desktop: ต้อง decode แล้วกรองเฉพาะเป้าหมายก่อนแสดง ห้าม Select-String แล้วพิมพ์ทั้งบรรทัดลง log/public repo

## 7. งานค้าง / สิ่งที่ยังไม่รับรอง

- ปิดฟอร์ม `AGY live demo` ที่ยังไม่บันทึกก่อนเริ่มงานใหม่ โดยตรวจหน้าจอปัจจุบันก่อน
- โรงเรียนทดสอบมีแล้ว แต่ยังไม่มีแอดมินโรงเรียนจริง ข้อมูลติดต่อยังเป็นข้อมูลทดลอง
- browser subagent ยังมีปัญหา timeout และ Windows-MCP headless บางรอบค้าง การสำเร็จบางรอบไม่ใช่ความเสถียรระยะยาว
- ไม่ได้ทดสอบ CRUD ทุกบทบาทหรือรับรองความพร้อมระบบเป็นเปอร์เซ็นต์
- ไม่มีการยกระดับ agy ให้แก้โค้ด/ฐานข้อมูลอัตโนมัติถาวร
- ก่อนงาน backend ต้องปฏิบัติตาม AGENTS.md: main app ใช้ custom sessions + p_token, direct table RLS deny-all, ตรวจ RPC กับ live DB และประสาน migration กับเลนอื่น

บันทึกนี้จงใจเก็บทั้งรอบสำเร็จ รอบติดข้อจำกัด และผู้ลงมือจริง เพื่อให้ Claude ตัดสินใจจากหลักฐาน ไม่ต้องเริ่มทดลองซ้ำจากศูนย์
