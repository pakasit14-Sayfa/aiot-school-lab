# สเปกสำหรับเฟิร์มแวร์: รับคำสั่งรีเลย์ และรายงานผลกลับ

> เขียน 2026-09-10 หลังตรวจฐานข้อมูล production จริง
> ส่งไฟล์นี้ให้คนที่ดูแลโค้ดบนบอร์ด (อยู่คนละ repo)

## สรุปสั้น: ขาดอะไร

บอร์ดทำ 2 ใน 3 อย่างได้แล้ว:

| สิ่งที่ต้องทำ | สภาพ |
|---|---|
| ส่งค่าเซนเซอร์ขึ้น | ✅ ทำได้ — 144,125 แถวใน `sensor_readings` |
| ดึงคำสั่งจากคิว (`poll_device_commands`) | ✅ ทำได้ — ดึงไปแล้ว 170 ครั้ง |
| **รายงานผลกลับ (`ack_device_command`)** | ❌ **ไม่เคยเรียกเลยสักครั้งใน 170 ครั้ง** |
| รายงานสถานะรีเลย์ตอนบูต (`report_relay_states`) | ❌ RPC เพิ่งมี 2026-09-14 |
| ส่ง firmware/IP ใน heartbeat | ❌ ส่งแค่ device id คอลัมน์ว่างมาตลอด |
| watchdog รีบูตเองเมื่อหลุด | ❌ บอร์ดเก่าเงียบไปเฉย ๆ ไม่ฟื้นเอง |

ผลที่เกิดขึ้นกับผู้ใช้: แอดมินกดเปิดวาล์วน้ำ → หน้าจอขึ้น "ส่งคำสั่งเข้าคิวแล้ว
รออุปกรณ์ยืนยัน" → รอไปเรื่อย ๆ → เปลี่ยนเป็น **"อุปกรณ์ยังไม่ยืนยัน —
ตรวจสอบหน้างาน"** สีส้ม **ต่อให้วาล์วเปิดจริงไปแล้วก็ตาม**

ตาราง `device_relay_states` ที่แอปใช้แสดงสถานะจริงจึงว่างเปล่ามาตลอด (0 แถว)

## สิ่งที่ต้องเพิ่ม

```
loop ทุก 2-5 วินาที:
    cmds = rpc('poll_device_commands', { p_device_token: <token ของบอร์ด> })

    for c in cmds:                    # เรียงตาม created_at ให้แล้ว ทำตามลำดับได้เลย
        relay = c.command['relay']    # 1-4
        state = c.command['state']    # "ON" | "OFF"
        try:
            ตั้งขา GPIO ตาม relay/state
            rpc('ack_device_command', {
                p_device_token: <token>,
                p_command_id:   c.id,
                p_status:       'ok',
                p_relay:        relay,
                p_state:        (state == 'ON'),
            })
        except e:
            rpc('ack_device_command', {
                p_device_token: <token>,
                p_command_id:   c.id,
                p_status:       'failed',
                p_detail:       {'error': str(e)},
            })
```

**บรรทัดที่ขาดอยู่คือ `ack_device_command` เท่านั้น** ส่วน `poll_device_commands`
บอร์ดเรียกเป็นอยู่แล้ว

## สเปก RPC

### `poll_device_commands(p_device_token text, p_limit int default 20)`

คืน `id uuid`, `command jsonb`, `created_at timestamptz`

- **เรียงตาม `created_at` จากเก่าไปใหม่** — ทำตามลำดับที่ได้มาได้เลย
- คืนไม่เกิน `p_limit` ต่อรอบ (ตั้งต้น 20, สูงสุด 100) — คิวยาวจะทยอยออก
  ไม่ถล่มบอร์ดรวดเดียว
- คำสั่งที่ค้างเกิน **10 นาที** จะถูกทำเครื่องหมายหมดอายุอัตโนมัติ ไม่ส่งมาให้
  (คนกดปิดไฟเมื่อ 22 ชม.ที่แล้ว ไม่ได้ตั้งใจให้ไฟติดตอนนี้)
- การเรียกนี้อัปเดต `last_seen_at` ของบอร์ดให้เอง
- `p_limit` มีค่าตั้งต้น → **เรียกแบบ 1 อาร์กิวเมนต์ได้เหมือนเดิม ไม่ต้องแก้โค้ดเดิม**

### `ack_device_command(...)`

```
p_device_token text     -- token ของบอร์ด (ตัวเดียวกับที่ใช้ poll)
p_command_id   uuid     -- c.id ที่ได้จาก poll
p_status       text     -- 'ok' หรือ 'failed' เท่านั้น (ค่าอื่น -> invalid_status)
p_relay        smallint -- ไม่บังคับ แต่ **ต้องส่ง** ถ้าอยากให้สถานะขึ้นบนแอป
p_state        boolean  -- ไม่บังคับ แต่ **ต้องส่ง** ถ้าอยากให้สถานะขึ้นบนแอป
p_detail       jsonb    -- ไม่บังคับ ใส่รายละเอียดตอน failed
```

**สำคัญ:** `device_relay_states` จะถูกเขียนก็ต่อเมื่อ
`p_status = 'ok'` **และ** `p_relay` **และ** `p_state` ไม่เป็น null ครบทั้งสาม
ถ้าส่งแค่ `p_status = 'ok'` เฉย ๆ แอปจะยังขึ้นว่า "ยังไม่ยืนยัน" อยู่ดี


### `report_relay_states(p_device_token text, p_states jsonb)` → int

**เรียกครั้งเดียวหลังต่อ WiFi สำเร็จ ก่อนเริ่ม loop** — บอกแอปว่ารีเลย์ทุกช่อง
อยู่สถานะไหนจริงตอนนี้ (หลังไฟดับ/รีสตาร์ท ทุกช่อง OFF แต่แอปยังจำสถานะเก่า)

```json
{ "p_device_token": "...",
  "p_states": [ {"relay":1,"state":false}, {"relay":2,"state":false},
                {"relay":3,"state":false}, {"relay":4,"state":false} ] }
```

- `relay` ต้องเป็นตัวเลข · `state` ต้องเป็น boolean (ไม่ใช่ string) ไม่งั้น `invalid_states`
- คืนจำนวนช่องที่บันทึก
- นับเป็นการรายงานตัวด้วย (อัปเดต `last_seen_at`)
- เพิ่มใน migration `20260914000000` — ต้อง push ขึ้น production ก่อนบอร์ดจะเรียกได้

### error ที่อาจเจอ

| ข้อความ | สาเหตุ |
|---|---|
| `invalid_device_token` | token ไม่ตรงกับ `devices.token_hash` |
| `invalid_status` | `p_status` ไม่ใช่ `'ok'`/`'failed'` |
| `command_not_found` | `p_command_id` ไม่ใช่คำสั่งของบอร์ดตัวนี้ |

## งานเพิ่มอีก 3 ข้อ (นอกจาก ack + report on boot)

### 3. ส่ง firmware version + IP ใน heartbeat

`record_device_heartbeat` **รับอยู่แล้ว** แต่โค้ดเดิมส่งแค่พารามิเตอร์แรก
คอลัมน์ `devices.firmware_version` / `ip_address` เลยว่างมาตลอด

```json
{ "p_device_id": "<uuid ของบอร์ด ตามที่โค้ดเดิมใช้>",
  "p_ip_address": "<IP จาก WiFi>",
  "p_firmware": "2.0.0-ack" }
```

ตั้งเวอร์ชันใหม่ให้ต่างจากเดิม — ฝั่งแอปจะได้รู้ทันทีว่าบอร์ดไหนอัปแล้ว
และพอบอร์ดเงียบ จะรู้ IP โดยไม่ต้องเดินไปดูหน้างาน

### 4. Watchdog

บอร์ดเก่าหยุด 2026-09-09 17:12:45 แบบ "เงียบไปเฉย ๆ" ไม่มีสัญญาณอะไรก่อน
และไม่ฟื้นเองจนพัง — ให้เพิ่ม:

- WiFi หลุดเกิน 60 วินาที → reconnect · ไม่สำเร็จ → `ESP.restart()`
- HTTP ล้มเหลวติดกัน 5 ครั้ง → `ESP.restart()`
- เปิด hardware watchdog timer ถ้าบอร์ดรองรับ

### 5. ต่อเซนเซอร์ให้ครบ 10 ค่า แล้วยืนยันว่ากลับมาครบ

| metric | หยุดส่งตั้งแต่ (บอร์ดเก่า) |
|---|---|
| `water_flow_lmin`, `water_volume_l` | 28 ส.ค. |
| `pm25` | 31 ส.ค. |
| `temperature`, `humidity`, `co2`, `tvoc`, `light_lux`, `aqi` | 2 ก.ย. 14:08 (6 ค่าพร้อมกันเป๊ะ) |
| `gas_mq2_percent` | 9 ก.ย. 17:12 (ตัวสุดท้าย) |

ตายทีละตัวก่อนบอร์ดจะดับทั้งตัว — เข้าเค้าว่า**พอร์ตบนบอร์ดเก่าทยอยเสีย**
ไม่ใช่เซนเซอร์เสีย ลงบอร์ดใหม่ให้ต่อครบทุกตัว แล้วดูใน `sensor_readings` ว่า
ทั้ง 10 metric กลับมาไหม ตัวไหนไม่กลับมาค่อยเปลี่ยนเซนเซอร์ตัวนั้น

### ลำดับตอนบูต (สรุป)

```
1. ต่อ WiFi
2. report_relay_states(สถานะ GPIO จริงทุกช่อง)      ← ครั้งเดียว
3. loop:
     ทุก ≤60 วิ  : record_device_heartbeat(id, ip, firmware)
     ทุก N วิ    : sensor_ingest(ค่าเซนเซอร์)
     ทุก 2-5 วิ  : poll_device_commands → สั่งรีเลย์ → ack_device_command
     watchdog   : นับ HTTP fail / WiFi หลุด → restart
```

## ห้ามทำ

- ห้าม hardcode `device_token` ในโค้ด / ห้าม commit ค่าลง git — ใส่ใน config
- ห้ามสั่งรีเลย์แล้วข้าม ack — ทุกคำสั่งต้องได้ ack ไม่ `ok` ก็ `failed`
- ห้ามเรียก `poll_device_commands` ด้วยชื่อพารามิเตอร์อื่น — `p_device_token` เท่านั้น

## รูปแบบคำสั่ง

```json
{"relay": 1, "state": "ON"}
{"relay": 2, "state": "OFF"}
```

`relay` = 1-4 ตรงกับคอลัมน์ `relay_no` ในตาราง `devices`
บน production ตอนนี้: **ช่อง 1 = วาล์วน้ำ** · ช่อง 2, 3, 4 = รีเลย์ทั่วไป

หมายเหตุ: คำสั่งถูกส่งไปที่ device id ของ **"เซนเซอร์ห้องทดลอง"** (บอร์ดตัวจริง)
ส่วน 4 แถว relay ในตาราง `devices` เป็นป้ายชื่อช่องสำหรับแสดงผลบนแอปเท่านั้น

## วิธีทดสอบว่าทำถูกแล้ว

หลังแก้เฟิร์มแวร์ ให้กดเปิดรีเลย์ 1 ครั้งจากแอป แล้วเช็ก:

```sql
select command::text, created_at, delivered_at, acked_at, ack_status
from device_commands order by created_at desc limit 1;

select * from device_relay_states;
```

**ผ่านเมื่อ:** หลังบูต `device_relay_states` มี 4 แถวทันที · แล้วกดสั่ง 1 ครั้ง →
`delivered_at` มีค่า · `acked_at` มีค่า · `ack_status = 'ok'` ·
และ `device_relay_states` มีแถวของ relay นั้นพร้อม `state` ที่ถูกต้อง

บนหน้าจอแอดมินจะเปลี่ยนจากส้ม "อุปกรณ์ยังไม่ยืนยัน" เป็นเขียว
**"อุปกรณ์ยืนยันว่าเปิดอยู่ · <เวลา>"**

## เรื่องที่ต้องรู้เพิ่ม

- **บอร์ดหยุดทำงานตั้งแต่ 2026-09-09 10:12:50** (heartbeat สุดท้าย 10:12:45,
  poll สุดท้าย 10:12:50) ต้องเปิดขึ้นมาก่อนถึงจะทดสอบได้
- เซนเซอร์หลายตัวหยุดส่งก่อนหน้านั้นอีก: น้ำ 28 ส.ค. · PM2.5 31 ส.ค. ·
  อุณหภูมิ/CO₂/แสง 2 ก.ย. — เหลือ `gas_mq2` ตัวเดียวที่ส่งถึง 9 ก.ย.
  ถ้าจะทดสอบวาล์วน้ำ ต้องเช็กก่อนว่ามิเตอร์น้ำยังต่ออยู่ ไม่งั้นเปิดวาล์วแล้ว
  ตัวเลขไม่ขยับ จะแยกไม่ออกว่า "วาล์วไม่ทำงาน" หรือ "เซนเซอร์ตาย"
- คิวคำสั่งค้าง 16 อันถูกล้างแล้วเมื่อ 2026-09-10 (ทำเครื่องหมาย `failed`)
