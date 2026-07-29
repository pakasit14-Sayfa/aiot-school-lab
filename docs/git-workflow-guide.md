# คู่มือ Git — วิธีบันทึกงาน (commit) และวิธีอัปขึ้น (push)

> เอกสารนี้เขียนไว้สำหรับทีมงานโปรเจกต์ AIoT School Lab ให้ commit/push งานไปในทิศทางเดียวกัน

## ทำไมต้อง commit และ push

- **commit** คือการ "บันทึกจุดหนึ่งของงาน" ไว้ในประวัติของโปรเจกต์ ถ้าโค้ดพังทีหลังหรือแก้ผิดทาง จะย้อนกลับไปจุดที่ยังทำงานถูกได้เสมอ
- **push** คือการอัปสิ่งที่ commit ไว้ในเครื่องเรา ขึ้นไปเก็บที่ remote (GitHub/GitLab) เพื่อ
  1. **สำรองงาน** — ถ้าเครื่องพังหรือลบไฟล์พลาด งานไม่หาย
  2. **ให้คนอื่นทำงานต่อได้** — เพื่อน/Codex/Claude อีกเครื่องดึงโค้ดล่าสุดไปทำต่อได้
  3. **เห็นประวัติว่าใครแก้อะไรตอนไหน** — เวลาเกิดบั๊กจะย้อนดูได้ว่าเปลี่ยนอะไรไปก่อนหน้า
- โปรเจกต์นี้ push ขึ้น **2 ที่พร้อมกัน**: GitHub (`origin`) และ GitLab (`gitlab`) — เผื่อฝั่งหนึ่งมีปัญหา (เช่น GitLab CI) อีกฝั่งยังใช้งานได้

## ก่อน commit ทุกครั้ง

1. **ดูว่าเปลี่ยนอะไรไปบ้าง**
   ```bash
   git status
   ```
   จะเห็นไฟล์ที่แก้ (`modified`), ไฟล์ใหม่ (`untracked`), ไฟล์ที่ลบ (`deleted`)

2. **ดูเนื้อหาที่เปลี่ยนจริง ๆ ก่อนบันทึก** (กันแก้พลาด/หลุด secret)
   ```bash
   git diff                # ไฟล์ที่ยังไม่ได้ add
   git diff --cached       # ไฟล์ที่ add แล้ว รอ commit
   ```

## วิธี commit

### 1. เลือกไฟล์ที่จะบันทึก (add)

**สำคัญ: อย่าใช้ `git add -A` หรือ `git add .` พร่ำเพรื่อ** เพราะอาจดึงไฟล์ที่ไม่ตั้งใจ (เช่น `.env`, ไฟล์ทดลองส่วนตัว) เข้ามาด้วย ให้เลือกไฟล์ทีละตัวหรือทีละกลุ่มที่เกี่ยวข้องกัน:

```bash
git add packages/shared_core/lib/services/auth_service.dart
git add packages/shared_core/lib/services/consent_service.dart
```

### 2. บันทึก (commit) พร้อมข้อความอธิบาย

```bash
git commit -m "อธิบายว่าทำอะไรและทำไม"
```

**หลักการเขียนข้อความ commit ที่ใช้ในโปรเจกต์นี้:**
- สั้น กระชับ บอก "ทำอะไร" บรรทัดแรก แล้วเว้นบรรทัดอธิบาย "ทำไม" ต่อถ้าจำเป็น
- ใช้ prefix บอกประเภทงาน เช่น
  - `feat:` งานใหม่ (เพิ่มฟีเจอร์)
  - `fix:` แก้บั๊ก
  - `refactor:` จัดโครงสร้างใหม่ ไม่เปลี่ยนพฤติกรรม
  - `docs:` แก้เอกสาร
  - `chore:` งานเบ็ดเตล็ด (เช่น อัป dependency)
- ตัวอย่างจริงจากโปรเจกต์นี้:
  ```
  refactor(shared_core): split auth_service.dart by responsibility
  refactor(supabase): split pdpa_security_hardening migration by concern
  fix: patch auth_sign_in timing side-channel
  ```

### 3. แยก commit เป็นก้อนเล็ก ๆ ตามเรื่อง ("แยกเป็นอัน ๆ")

ถ้าทำหลายเรื่องในคราวเดียว **อย่ารวมเป็น commit เดียว** ให้แยกตามเนื้อหา เช่น ถ้าวันนี้ทั้งแก้ auth service และแก้ migration คนละเรื่องกัน ให้ทำ:

```bash
git add <ไฟล์กลุ่มที่ 1>
git commit -m "refactor: เรื่องที่ 1"

git add <ไฟล์กลุ่มที่ 2>
git commit -m "refactor: เรื่องที่ 2"
```

**ทำไมต้องแยก**: ถ้าทีหลังพบว่าเรื่องใดเรื่องหนึ่งมีปัญหา จะ revert เฉพาะ commit นั้นได้โดยไม่กระทบงานเรื่องอื่น และคนอ่านประวัติ (`git log`) จะเข้าใจง่ายกว่ารวมทุกอย่างเป็นก้อนเดียว

## วิธี push ขึ้น remote

### เช็กก่อนว่ามี remote อะไรบ้าง

```bash
git remote -v
```

ของโปรเจกต์นี้จะเห็น 2 อัน:
```
origin  git@github.com:pakasit14-Sayfa/aiot-school-lab.git   (GitHub)
gitlab  git@gitlab.com:diliondev/aiot-school-lab.git         (GitLab)
```

### push ขึ้นทั้งสองที่

```bash
git push origin main
git push gitlab main
```

- ใช้ SSH (ไม่ใช่ username/password) เชื่อมต่อ ต้องตั้ง SSH key ไว้กับทั้ง GitHub และ GitLab ล่วงหน้า (ทำครั้งเดียว)
- ถ้า push แล้วขึ้น error ว่า remote มีของใหม่กว่า (`rejected — non-fast-forward`) ให้ `git pull` ดึงของใหม่มารวมก่อน แล้วค่อย push ใหม่ — **ห้าม force push** (`push -f`) ทับโดยไม่เช็กก่อน เพราะจะลบงานของคนอื่นที่ push ไปก่อนหน้าทิ้งได้

## สรุปลำดับการทำงานทั้งหมด (ทำจริงบ่อยที่สุด)

```bash
git status                     # ดูว่าเปลี่ยนอะไรไปบ้าง
git add <ไฟล์ที่เกี่ยวข้องกัน>   # เลือกเฉพาะไฟล์ของเรื่องนี้
git commit -m "อธิบายสั้น ๆ"    # บันทึก
git push origin main           # อัปขึ้น GitHub
git push gitlab main           # อัปขึ้น GitLab
```

## ข้อควรระวัง

- **ห้าม commit ไฟล์ที่มี secret** เช่น `env.json`, API key, password จริง — เช็ก `git status`/`git diff` ก่อน add เสมอ
- **ไฟล์ที่ตั้งใจไม่ commit** (เช่น `docs/code-structure.html` ที่เก็บไว้ดูในเครื่องอย่างเดียว) ให้จำไว้ว่าอย่า `git add` ไฟล์นั้น หรือใส่ชื่อไว้ใน `.gitignore` ถ้าไม่อยากให้ `git status` ขึ้นเตือนซ้ำ ๆ
- ถ้าไม่แน่ใจว่า commit ไหนทำอะไร ใช้ `git log --oneline -10` ดูประวัติล่าสุดก่อนตัดสินใจ
