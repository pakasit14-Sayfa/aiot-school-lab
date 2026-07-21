#!/usr/bin/env python3
"""
WiFi Gateway — รับ JSON จากบอร์ดเซนเซอร์ใน WiFi วงเดียวกัน
แล้วส่งต่อเข้า AIoT School Lab (Supabase sensor_ingest)

วิธีใช้ (บนคอมที่อยู่ WiFi วงเดียวกับบอร์ด):
  1. แก้ค่าในส่วน CONFIG ด้านล่าง (API_KEY, DEVICE_TOKEN)
  2. รัน:  python3 wifi_gateway.py
  3. ให้บอร์ดยิง  POST http://<ip คอมเครื่องนี้>:8000/  เป็น JSON เช่น
       {"temp": 28.4, "hum": 61.2, "pm25": 12.0}
     (ดู ip คอมด้วย  ifconfig / ipconfig)

สคริปต์จะสะสมค่าแล้วส่งขึ้นเซิร์ฟเวอร์ทุก SEND_INTERVAL วินาที
ถ้าเน็ตหลุดจะเก็บค่าไว้แล้ว retry ให้เอง (ส่งซ้ำได้ ปลายทางกันข้อมูลซ้ำ)

ต้องใช้ Python 3.8+ เท่านั้น ไม่ต้องติดตั้งไลบรารีเพิ่ม
"""

import json
import threading
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# ========================= CONFIG — แก้ตรงนี้ =========================

SUPABASE_URL = "https://smqoknnftgjyhrnzugar.supabase.co"
API_KEY = "ใส่ publishable key ที่นี่"
DEVICE_TOKEN = "ใส่ device token (dev_...) ที่นี่"

LISTEN_PORT = 8000        # พอร์ตที่บอร์ดยิงเข้ามา
SEND_INTERVAL = 15        # ส่งขึ้นเซิร์ฟเวอร์ทุกกี่วินาที
MAX_QUEUE = 5000          # กันเมมโมรีบวมถ้าเน็ตหลุดนาน (เกินนี้ทิ้งค่าเก่าสุด)

# แปลงชื่อ field จากบอร์ด -> ชื่อ metric ของระบบ
# ระบบรองรับเฉพาะ: pm25, aqi, temperature, humidity, light_lux,
#                  energy_kwh, power_w
# ถ้าบอร์ดใช้ชื่ออื่น เพิ่ม/แก้บรรทัดในตารางนี้ได้เลย
METRIC_MAP = {
    "temp": "temperature",
    "temperature": "temperature",
    "hum": "humidity",
    "humidity": "humidity",
    "pm25": "pm25",
    "pm2_5": "pm25",
    "pm": "pm25",
    "aqi": "aqi",
    "lux": "light_lux",
    "light": "light_lux",
    "light_lux": "light_lux",
    "energy": "energy_kwh",
    "energy_kwh": "energy_kwh",
    "power": "power_w",
    "power_w": "power_w",
}

# =====================================================================

queue: list = []
queue_lock = threading.Lock()
warned_keys: set = set()


def log(msg: str) -> None:
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)


def to_readings(data: dict) -> list:
    """แปลง JSON จากบอร์ดเป็นรายการ reading ตาม format ของ sensor_ingest"""
    ts = datetime.now(timezone.utc).isoformat()
    readings = []
    for key, value in data.items():
        metric = METRIC_MAP.get(str(key).lower())
        if metric is None:
            if key not in warned_keys:
                warned_keys.add(key)
                log(f"เตือน: ไม่รู้จัก field '{key}' — ข้าม (เพิ่มใน METRIC_MAP ได้)")
            continue
        try:
            readings.append({"metric": metric, "value": float(value), "ts": ts})
        except (TypeError, ValueError):
            log(f"เตือน: ค่าของ '{key}' ไม่ใช่ตัวเลข ({value!r}) — ข้าม")
    return readings


class BoardHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        try:
            length = int(self.headers.get("Content-Length", 0))
            data = json.loads(self.rfile.read(length))
            readings = to_readings(data)
        except (json.JSONDecodeError, ValueError):
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b"invalid json")
            return

        with queue_lock:
            queue.extend(readings)
            del queue[:-MAX_QUEUE]  # เกินเพดานให้ทิ้งค่าเก่าสุด
        log(f"รับจากบอร์ด: {data} -> เข้าคิว {len(readings)} ค่า (คิวรวม {len(queue)})")

        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, *args):  # ปิด log ดีฟอลต์ของ http.server
        pass


def send_batch() -> None:
    with queue_lock:
        if not queue:
            return
        batch, remaining = queue[:500], queue[500:]  # เพดานฝั่งเซิร์ฟเวอร์ 500/ครั้ง
        queue[:] = remaining

    body = json.dumps({"p_device_token": DEVICE_TOKEN, "p_readings": batch})
    req = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/rpc/sensor_ingest",
        data=body.encode(),
        headers={"apikey": API_KEY, "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            inserted = resp.read().decode().strip()
            log(f"ส่งขึ้นเซิร์ฟเวอร์สำเร็จ: {len(batch)} ค่า (บันทึกใหม่ {inserted})")
    except urllib.error.HTTPError as e:
        detail = e.read().decode()[:200]
        if e.code in (400, 404):
            # payload/config ผิด — retry ไปก็ผิดเหมือนเดิม ทิ้ง batch แล้วแจ้งให้แก้
            log(f"เซิร์ฟเวอร์ปฏิเสธ ({e.code}): {detail} — ทิ้ง batch นี้ ตรวจ CONFIG/METRIC_MAP")
        else:
            with queue_lock:
                queue[:0] = batch  # เก็บกลับเข้าคิว รอส่งรอบหน้า
            log(f"ส่งไม่สำเร็จ ({e.code}): {detail} — จะลองใหม่")
    except OSError as e:
        with queue_lock:
            queue[:0] = batch
        log(f"เน็ตมีปัญหา ({e}) — เก็บไว้ส่งรอบหน้า (ค้าง {len(queue)} ค่า)")


def sender_loop() -> None:
    while True:
        time.sleep(SEND_INTERVAL)
        send_batch()


def main() -> None:
    if "ใส่" in API_KEY or "ใส่" in DEVICE_TOKEN:
        log("ยังไม่ได้ตั้งค่า API_KEY / DEVICE_TOKEN — แก้ในส่วน CONFIG ก่อนรัน")
        return
    threading.Thread(target=sender_loop, daemon=True).start()
    server = ThreadingHTTPServer(("0.0.0.0", LISTEN_PORT), BoardHandler)
    log(f"Gateway พร้อม — รอรับ JSON จากบอร์ดที่พอร์ต {LISTEN_PORT}")
    log(f"ทดสอบ: curl -X POST http://localhost:{LISTEN_PORT}/ "
        "-H 'Content-Type: application/json' -d '{\"temp\": 28.4, \"hum\": 61.2}'")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log("ปิด gateway — ส่งค่าที่ค้างในคิวก่อนจบ")
        send_batch()


if __name__ == "__main__":
    main()
