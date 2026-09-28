# Comic Library — Supabase Edition (เวอร์ชันไม่มีระบบสมัครสมาชิก)

- `index.html` = หน้าเว็บทั้งหมด (ใส่ SUPABASE_URL / ANON KEY ไว้แล้ว)
- `supabase_setup.sql` = รันครั้งเดียวใน Supabase > SQL Editor (สร้างตาราง, policy, bucket)

## ผู้อ่าน
เปิดเว็บแล้วอ่านได้เลย ไม่ต้องสมัคร/ล็อกอิน

## สร้างบัญชีผู้ดูแล (ทำเองใน Supabase เพราะไม่มีหน้าสมัคร)
1. Supabase > Authentication > Users > Add user > Create new user (ใส่อีเมล+รหัสผ่าน, ติ๊ก Auto Confirm User)
2. คัดลอก User UID แล้วรันใน SQL Editor:
```sql
update public.profiles set role = 'admin' where id = 'UID-ของผู้ดูแล';
```
3. เปิดเว็บ กด "ผู้ดูแลเข้าสู่ระบบ" ที่มุมขวาบน

## สำคัญ
- ห้ามนำ Service Role Key มาใส่ใน index.html
- หน้าปกจำกัด 5 MB / ขนาด PDF ต่อไฟล์ถูกจำกัดโดยแผน Supabase (Free = 50MB)
