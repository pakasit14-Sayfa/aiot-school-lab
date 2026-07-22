# Mission: ทดลองส่ง Email OTP อย่างปลอดภัย

## Why
ตั้งค่าการส่ง OTP ของ AIoT School Lab ให้ทดสอบได้จริง โดยไม่ต้องซื้อโดเมนและไม่ทำ API Key รั่วเข้า Git

## Success looks like
- สร้าง Resend API Key ที่มีสิทธิ์ส่งอีเมลเท่านั้น
- ตั้ง `RESEND_API_KEY` และ `RESEND_FROM_EMAIL` ให้ Supabase Edge Functions
- ส่ง OTP ทดลองถึงอีเมลที่ผูกกับบัญชี Resend ได้
- รู้ข้อจำกัดของ `onboarding@resend.dev` ก่อนนำไปใช้กับครูหลายคน

## Constraints
- ใช้แพ็กเกจฟรีระหว่างทดลอง
- ส่งได้เฉพาะอีเมลเจ้าของบัญชี Resend จนกว่าจะยืนยันโดเมนของตัวเอง
- ห้ามเก็บ API Key ในโค้ดหรือ Git

## Out of scope
- การยืนยันโดเมน Production
- การเปิดใช้ 2FA กับผู้ใช้จริงทุกบทบาท
