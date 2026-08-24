# Brief for agy: GitLab CI Pipeline Real Failure Cause & Verification Discipline

> **Document Purpose:** บันทึกการวิเคราะห์สาเหตุที่แท้จริงของการที่ GitLab CI/CD Pipeline ขึ้นสถานะล้มเหลว (Failed) ทั้ง 4 Jobs ตามภาพถ่ายหน้าจอ โดยอ้างอิงจากหลักฐานจริงระดับ GitLab API เพื่อเป็นแนวทางที่ถูกต้อง ชัดเจน และป้องกันการแก้โค้ดโดยไม่จำเป็น

---

## 🔎 1. หลักฐานจริงจาก GitLab API (Ground-Truth Evidence)

จากการตรวจสอบสถานะ Pipeline และ Job ผ่าน GitLab API โดยตรง พบข้อมูลทางเทคนิคดังนี้:

* **Pipeline Status:** `failed`
* **Failure Reason:** `ci_quota_exceeded` (โควต้าเวลา CI / Shared Runner Minutes หมด)
* **Job Traces (Logs):** **ว่างเปล่า (Empty Log) ทั้ง 4 Jobs** (`apps/admin_app`, `apps/user_app`, `packages/shared_core`, `packages/shared_ui`)
  * ไม่มี Log ของการรัน `flutter pub get`, `flutter analyze`, หรือ `flutter test` แม้แต่บรรทัดเดียว
  * แสดงว่าตัว Job ยังไม่ทันถูกส่ง (Dispatch) ไปยัง GitLab Runner ด้วยซ้ำ แต่ถูกระบบ GitLab ปฏิเสธการทำงานตั้งแต่ขั้นตอนจัดคิว (Pipeline Scheduling)

---

## 🛑 2. สาเหตุที่แท้จริง (Root Cause)

* **GitLab Trial Plan หมดอายุ + โควต้า CI Minutes หมด:**
  * บัญชี/กลุ่มบน GitLab อยู่ในสถานะหมด Free Trial หรือใช้ Compute Minutes โควต้าฟรีของ Shared Runners ประจำเดือนหมดแล้ว
  * เมื่อโควต้าหมด GitLab จะสั่งยกเลิก (Drop/Fail) ทุก Job ทันทีพร้อมติดแท็ก `ci_quota_exceeded`
* **สถานะโค้ดในโปรเจกต์:**
  * **ไม่ต้องแก้ไขโค้ดใดๆ ทั้งสิ้น (No Code Changes Needed)**
  * โค้ดไม่ได้มีบั๊กที่ทำให้ CI พัง และคำสั่งในโปรเจกต์สามารถรันผ่านได้ตามปกติ

---

## 💡 3. แนวทางการแก้ไขและลดการใช้โควต้า CI Minutes (Optimization & Action Plan)

### ก) การแก้ปัญหาโควต้าในระดับ Account / Infrastructure:
1. **ต่ออายุแพ็กเกจ หรือเพิ่มโควต้า CI Minutes** ใน GitLab Account / Group Settings
2. **ติดตั้ง Self-Hosted GitLab Runner:** ติดตั้ง Runner ในเครื่องของตนเอง (ไม่มีจำกัดนาที CI)

### ข) การลดการเผาโควต้าซ้ำซ้อนใน `.gitlab-ci.yml` (Prevent Duplicate Pipelines):
ปัจจุบันไฟล์ [`.gitlab-ci.yml`](file:///Users/sayfa/my_first_app/.gitlab-ci.yml) มีการกำหนดเงื่อนไข:
```yaml
rules:
  - if: '$CI_PIPELINE_SOURCE == "push" || $CI_PIPELINE_SOURCE == "merge_request_event"'
```
**ปัญหา:** เมื่อมีการ Push โค้ดขึ้นไปบน Branch ที่เปิด Merge Request (MR) ค้างอยู่ GitLab จะ Trigger รัน Pipeline พร้อมกัน **2 ครั้ง (Double Pipelines: Branch Pipeline + MR Pipeline)** ทำให้กินโควต้า CI Minutes เพิ่มขึ้นเป็น 2 เท่าโดยไม่จำเป็น

**แนวทางปรับปรุง:**
ใช้ Workflow Rules หรือกำหนดให้รันเฉพาะเมื่อเป็น Merge Request หรือ Push เข้า Main Branch:
```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
```

---

## 🧠 4. ข้อคิดและระเบียบวิธี Verify ก่อนเสนอ Fix (Discipline & Verification Lessons)

เหตุการณ์นี้เป็นกรณีศึกษาสำคัญด้าน **"การตรวจสอบข้อเท็จจริงก่อนตั้งสมมติฐาน" (Verify Before Hypothesizing)**:

1. **เช็ค Job Log จริงเป็นอันดับแรก (Check Actual Logs First):**
   * หาก Job ขึ้นสีแดง ให้เปิดดู Log ด้านในก่อนเสมอ
   * ถ้า **Log ว่างเปล่า** หรือมีข้อความแจ้งเตือนระดับระบบ (เช่น `ci_quota_exceeded`, `stuck runner`, `billing required`) แสดงว่าเป็นปัญหา **ระดับระบบ/โควต้า (Infrastructure/Account Level)** ไม่ใช่ปัญหาโค้ดในโปรเจกต์
2. **หลีกเลี่ยงการเดาสาเหตุจากความน่าจะเป็น (Avoid Guessing Based on Local Lints):**
   * การเห็นโค้ดมี Lint Warning หรือโฟลเดอร์ว่างใน Local แล้วด่วนสรุปว่าเป็นสาเหตุที่ทำให้ CI แดง โดยไม่ได้ดู Raw Error ของ CI จริง นำไปสู่การ "แก้ผิดจุด" (False Diagnosis)
3. **ยึดหลัก Ground-Truth First:**
   * รายงานผลตามข้อมูลดิบที่ได้จาก API หรือ Log เสมอ และหากยังไม่เห็น Log ให้ระบุสถานะว่า "รอตรวจสอบ Log จากเซิร์ฟเวอร์จริง" แทนการคาดเดา
