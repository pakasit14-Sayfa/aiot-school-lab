#!/usr/bin/env python3
"""
MQTT → AIoT School Lab (Supabase sensor_ingest)

Subscribe topic "aiot/lab01/sensors" จาก Mosquitto broker แล้วยิงค่าที่ได้
เข้า Supabase ผ่าน RPC sensor_ingest โดยตรง (ไม่ผ่าน Edge Function เพราะยัง
ไม่ได้ deploy บนโปรเจกต์นี้ — RPC ตัวนี้ grant ให้ anon เรียกตรงได้อยู่แล้ว)

วิธีใช้:
  1. ./.venv/bin/pip install paho-mqtt  (ทำไว้แล้วถ้าใช้ venv ในโฟลเดอร์นี้)
  2. แก้ค่าในส่วน CONFIG ด้านล่างถ้า broker/topic เปลี่ยน
  3. รัน: ./.venv/bin/python mqtt_to_database.py
"""

import json
import threading
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone

import paho.mqtt.client as mqtt

# ========================= CONFIG =========================

MQTT_BROKER_HOST = "192.168.1.118"  # broker รันอยู่บนเครื่องนี้เอง (เดิมตั้งไว้
                                     # เป็น 192.168.1.180 แต่เครื่องนั้นหายจาก
                                     # LAN — ต้องแก้ secrets.py บนบอร์ดให้ชี้มาที่นี่)
MQTT_BROKER_PORT = 1883
MQTT_TOPIC = "aiot/lab01/sensors"

SUPABASE_URL = "https://smqoknnftgjyhrnzugar.supabase.co"
API_KEY = "sb_publishable_IFaGjUFwiBeBH_M-GYrSZA_Fywg9Tk9"
DEVICE_TOKEN = "dev_11e199bc95427c21cf36a2d00e2d2cc68b9ebb4836520c4e"  # ออกใหม่
                                     # ให้ device be76fccb-...c963a ผ่าน
                                     # issue_device_token — token เดิม (ถ้ามี)
                                     # ใช้ไม่ได้แล้วเพราะออกใหม่ทับ

SEND_INTERVAL = 5          # ส่งขึ้น Supabase ทุกกี่วินาที (สะสมแล้วส่งเป็นชุด)
MAX_QUEUE = 5000

# แปลงชื่อ field จาก payload ของบอร์ด -> ชื่อ metric ที่ระบบรู้จัก
# รองรับตามที่ยืนยันจริงจาก sensor_latest: pm25, aqi, temperature, humidity,
# light_lux, water_flow_lmin, water_volume_l, gas_mq2_percent
# (ชื่อ field จริงจากบอร์ดยังไม่ยืนยัน 100% — ดู raw payload ที่ print ออกมา
#  แล้วเพิ่ม/แก้ในตารางนี้ได้เลยถ้าไม่ตรง)
METRIC_MAP = {
    "pm25": "pm25", "pm2_5": "pm25", "pm2.5": "pm25",
    "aqi": "aqi",
    "temp": "temperature", "temperature": "temperature",
    "hum": "humidity", "humidity": "humidity", "rh": "humidity",
    "lux": "light_lux", "light": "light_lux", "light_lux": "light_lux",
    "gas": "gas_mq2_percent", "gas_percent": "gas_mq2_percent",
    "mq2": "gas_mq2_percent", "gas_mq2_percent": "gas_mq2_percent",
    "flow": "water_flow_lmin", "flow_lmin": "water_flow_lmin",
    "water_flow": "water_flow_lmin", "water_flow_lmin": "water_flow_lmin",
    "volume": "water_volume_l", "volume_l": "water_volume_l",
    "water_volume": "water_volume_l", "water_volume_l": "water_volume_l",
}

# ============================================================

queue: list = []
queue_lock = threading.Lock()
warned_keys: set = set()


def log(msg: str) -> None:
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)


def to_readings(data: dict) -> list:
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


def on_connect(client, userdata, flags, reason_code, properties=None):
    if reason_code == 0:
        log(f"เชื่อม broker {MQTT_BROKER_HOST}:{MQTT_BROKER_PORT} สำเร็จ — subscribe {MQTT_TOPIC}")
        client.subscribe(MQTT_TOPIC)
    else:
        log(f"เชื่อม broker ไม่สำเร็จ: {reason_code}")


def on_message(client, userdata, msg):
    try:
        data = json.loads(msg.payload)
    except json.JSONDecodeError:
        log(f"รับ payload ที่ไม่ใช่ JSON จาก topic {msg.topic}: {msg.payload!r}")
        return
    readings = to_readings(data)
    with queue_lock:
        queue.extend(readings)
        del queue[:-MAX_QUEUE]
    log(f"รับจากบอร์ด ({msg.topic}): {data} -> เข้าคิว {len(readings)} ค่า (คิวรวม {len(queue)})")


def send_batch() -> None:
    with queue_lock:
        if not queue:
            return
        batch, remaining = queue[:500], queue[500:]
        queue[:] = remaining

    body = json.dumps(
        {"p_device_token": DEVICE_TOKEN, "p_readings": batch},
        ensure_ascii=False,
    ).encode("utf-8")
    req = urllib.request.Request(
        f"{SUPABASE_URL}/rest/v1/rpc/sensor_ingest",
        data=body,
        headers={"apikey": API_KEY, "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            inserted = resp.read().decode().strip()
            log(f"ส่งขึ้น Supabase สำเร็จ: {len(batch)} ค่า (บันทึกใหม่ {inserted})")
    except urllib.error.HTTPError as e:
        detail = e.read().decode()[:200]
        if e.code in (400, 404):
            log(f"เซิร์ฟเวอร์ปฏิเสธ ({e.code}): {detail} — ทิ้ง batch นี้ ตรวจ DEVICE_TOKEN/METRIC_MAP")
        else:
            with queue_lock:
                queue[:0] = batch
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
    threading.Thread(target=sender_loop, daemon=True).start()
    client = mqtt.Client(callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
    client.on_connect = on_connect
    client.on_message = on_message
    log(f"กำลังเชื่อม broker {MQTT_BROKER_HOST}:{MQTT_BROKER_PORT} ...")
    client.connect(MQTT_BROKER_HOST, MQTT_BROKER_PORT, keepalive=60)
    try:
        client.loop_forever()
    except KeyboardInterrupt:
        log("ปิดโปรแกรม — ส่งค่าที่ค้างในคิวก่อนจบ")
        send_batch()


if __name__ == "__main__":
    main()
