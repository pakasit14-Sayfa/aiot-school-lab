-- เพิ่มชนิด metric สำหรับเซนเซอร์วัดน้ำ (flow rate + ปริมาณสะสม)
-- บอร์ดเพื่อนวัดค่านี้ได้อยู่แล้ว (flow_rate_l_min, total_volume_l) แต่
-- gateway ข้ามทิ้งเพราะ metric_type เดิมไม่มีช่องรองรับ

alter type metric_type add value if not exists 'water_flow_lmin';
alter type metric_type add value if not exists 'water_volume_l';
