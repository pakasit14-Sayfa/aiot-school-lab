# Sensor Ingest API — คู่มือสำหรับฝั่งอุปกรณ์/Gateway

เอกสารนี้สำหรับคนทำฝั่งเซนเซอร์/gateway ที่ต้องการส่งค่าเข้าระบบ AIoT School Lab

## สิ่งที่ต้องมี (ขอจากแอดมินระบบ)

1. **`SUPABASE_URL`** — เช่น `https://<project-ref>.supabase.co`
2. **`API_KEY`** — publishable key ของโปรเจกต์ (ใช้ใน header `apikey`)
3. **`DEVICE_TOKEN`** — token ประจำอุปกรณ์ ขึ้นต้นด้วย `dev_...`
   ได้จากแอดมิน/ช่างเทคนิคที่ลงทะเบียนอุปกรณ์ผ่าน RPC `register_device`
   (token แสดงครั้งเดียวตอนลงทะเบียน — เก็บให้ดี ถ้าหายต้องขอออกใหม่)

## ส่งค่าเซนเซอร์

`POST {SUPABASE_URL}/rest/v1/rpc/sensor_ingest`

Headers:

```
apikey: {API_KEY}
Content-Type: application/json
```

Body:

```json
{
  "p_device_token": "dev_xxxxxxxxxxxxxxxx",
  "p_readings": [
    { "metric": "temperature", "value": 28.4, "ts": "2026-07-20T09:00:00Z" },
    { "metric": "humidity",    "value": 61.2, "ts": "2026-07-20T09:00:00Z" },
    { "metric": "pm25",        "value": 12.0 }
  ]
}
```

- `metric` ต้องเป็นค่าใดค่าหนึ่งของ:
  `pm25`, `aqi`, `temperature`, `humidity`, `light_lux`, `energy_kwh`, `power_w`
- `value` เป็นตัวเลข (จำเป็น)
- `ts` เป็น ISO 8601 UTC (ไม่ส่ง = ใช้เวลาที่เซิร์ฟเวอร์รับ)
- ส่งได้สูงสุด **500 ค่าต่อครั้ง** — แนะนำ batch สะสมแล้วส่งทุก 10–60 วินาที
- **retry ได้ปลอดภัย**: ค่า (metric, ts) ที่ซ้ำจะถูกข้าม ไม่เกิดข้อมูลซ้ำ

ผลลัพธ์: ตัวเลขจำนวน reading ที่ถูกบันทึกจริง เช่น `3`

ตัวอย่าง curl:

```bash
curl -X POST "$SUPABASE_URL/rest/v1/rpc/sensor_ingest" \
  -H "apikey: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "p_device_token": "'$DEVICE_TOKEN'",
    "p_readings": [
      {"metric": "temperature", "value": 28.4},
      {"metric": "humidity", "value": 61.2}
    ]
  }'
```

## Error ที่อาจเจอ

| ข้อความ | สาเหตุ |
|---|---|
| `invalid_device_token` | token ผิดหรือถูก rotate ไปแล้ว — ขอ token ใหม่จากแอดมิน |
| `unknown_metric: ...` | ชื่อ metric ไม่อยู่ในรายการที่รองรับ |
| `missing_value_for_metric: ...` | reading ไม่มี `value` |
| `batch_too_large` | ส่งเกิน 500 ค่าในครั้งเดียว |
| `readings_must_be_array` | `p_readings` ไม่ใช่ JSON array |

หมายเหตุ: ถ้า reading ใดใน batch ผิด ทั้ง batch จะถูก reject (transaction เดียว) —
ตรวจ payload ให้เรียบร้อยก่อนส่ง

## ฝั่งแอป (สำหรับทีม Flutter)

- `register_device(p_token, p_type, p_name, ...)` → ลงทะเบียนอุปกรณ์ + รับ device token (ครั้งเดียว) — role: school_admin / technician / super_admin
- `issue_device_token(p_token, p_device_id)` → rotate token
- `sensor_latest(p_token, [p_device_id])` → ค่าล่าสุดทุก metric ของทุกอุปกรณ์ในโรงเรียน
- `sensor_history(p_token, p_device_id, p_metric, p_from, [p_to])` → ข้อมูลย้อนหลังสำหรับกราฟ (สูงสุด 10,000 จุด)
