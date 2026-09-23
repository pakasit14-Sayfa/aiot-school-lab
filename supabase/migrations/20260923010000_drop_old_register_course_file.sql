-- 20260923010000_drop_old_register_course_file.sql
--
-- 20260923000000 เพิ่ม p_category เป็นพารามิเตอร์ที่ 6 ของ register_course_file
-- โดยคิดว่า `create or replace` จะทับของเดิม — ไม่ทับ เพราะจำนวนพารามิเตอร์
-- ต่างกัน Postgres จึงถือเป็นคนละฟังก์ชัน ผลคือมี 2 ตัวซ้อนกัน (เห็นตอนรัน
-- verify บน prod 2026-09-23)
--
-- ตัวเก่าไม่รู้จัก category และไม่เซ็ต kind — ถ้าตัวเรียกไหนส่งแค่ 5
-- พารามิเตอร์ หมวดที่ครูกรอกจะหายเงียบอีกรอบ ซึ่งเป็นบั๊กเดิมที่เพิ่งปิดไป
-- ทิ้งไว้ไม่ได้

drop function if exists public.register_course_file(text, uuid, text, text, bigint);
