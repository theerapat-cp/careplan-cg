# Careplan CG 

ระบบจัดการแผนการดูแลผู้สูงอายุ สำหรับเจ้าหน้าที่สาธารณสุขและฝ่ายทะเบียน

## รายละเอียดโปรเจกต์

| รายการ    | รายละเอียด                               |
|----------|-----------------------------------------|
| ชื่อแอป    | Careplan CG                            |
| เวอร์ชัน    | 1.0.0+1                                |
| Framework | Flutter 3.x                           |
| Dart SDK  | ≥ 3.0.0 < 4.0.0                       |
| Database  | Firebase Firestore + SQLite (sqflite) |
| รองรับภาษา | ไทย 🇹🇭 / English 🇬🇧                   |

## 🚀 การติดตั้งและรัน

### 1. Clone โปรเจกต์

```bash
git clone <repository-url>
cd careplan_fixed
```
### 2. ติดตั้ง dependencies

```bash
flutter pub get
```
### 3. ตั้งค่า Firebase

- สร้างโปรเจกต์ใน [Firebase Console](https://console.firebase.google.com)
- เพิ่ม Android/iOS app
- ดาวน์โหลด `google-services.json` (Android) หรือ `GoogleService-Info.plist` (iOS)
- วางไฟล์ใน path ที่ถูกต้อง

### 4. รันแอป

```bash
flutter run
```

##  บัญชีผู้ใช้ (Default)

| Email                 | Password  | Role            |
|-----------------------|-----------|-----------------|
| admin@careplan.com    | 123456    | Admin           |
| staff@careplan.com    | 123456    | เจ้าหน้าที่         |
| register@careplan.com | 123456    | ฝ่ายทะเบียน       |
|team@careplan.com      | 123456    | ทีมสหสาขาวิชาชีพ  |
|staffCG@careplan.com   | 123456    | CG              |
|staffCM@careplan.com   | 123456    | CM              |

##  สิทธิ์การใช้งานตาม Role

| ฟีเจอร์              | Admin    | Staff / CG / CM / สหสาขา   | ฝ่ายทะเบียน   |
|---------          |-------    |--------------------------  |-------------|
| ดูรายชื่อผู้สูงอายุ      |    ✅    |             ✅             |     ✅     |
| เพิ่ม / แก้ไขผู้สูงอายุ  |    ✅    |             ❌             |     ✅     |
| ลบผู้สูงอายุ          |    ✅    |             ❌             |     ❌     |
| เพิ่ม / ดู Care Plan |    ✅    |             ✅             |     ❌     |
| ดูรายงานสรุปผล      |    ✅    |             ✅             |     ❌     |
| จัดการผู้ใช้งาน       |    ✅    |             ❌             |     ❌     |


##  โครงสร้างโปรเจกต์

lib/
├── main.dart                      # Entry point + Theme + Color constants
├── screens/
│   ├── launch_screen.dart         # Splash screen
│   ├── login_screen.dart          # หน้าเข้าสู่ระบบ
│   ├── home_screen.dart           # หน้าหลัก / เมนู
│   ├── patient_list_screen.dart   # รายชื่อผู้สูงอายุ (เรียงตามวันนัด)
│   ├── patient_detail_screen.dart # ข้อมูลรายละเอียดผู้สูงอายุ
│   ├── add_patient_screen.dart    # เพิ่มผู้สูงอายุใหม่
│   ├── edit_patient_screen.dart   # แก้ไขข้อมูลผู้สูงอายุ
│   ├── careplan_screen.dart       # เพิ่ม / ดู Care Plan
│   ├── dashboard_screen.dart      # Dashboard + ปฏิทิน
│   ├── report_screen.dart         # รายงาน (รายผู้ป่วย + ราย CG)
│   └── user_management_screen.dart # จัดการผู้ใช้งาน
├── services/
│   └── local_service.dart         # SQLite service (Users, Patients, CarePlans)
└── translations/
    └── app_translations.dart      # ข้อความ 2 ภาษา (TH/EN)

## ✨ ฟีเจอร์หลัก

### 📂 จัดการผู้สูงอายุ
- เพิ่ม / แก้ไข / ลบข้อมูลผู้สูงอายุ
- แบ่งกลุ่ม: ติดเตียง / ติดบ้าน / ติดสังคม
- ค้นหาและกรองตามกลุ่ม
- **เรียงลำดับตามวันนัดที่ใกล้ที่สุดก่อน** พร้อมแสดง "วันนี้" / "พรุ่งนี้" / "เลยกำหนด"

### 📋 Care Plan
- บันทึกการตรวจเยี่ยม พร้อมเป้าหมายระยะสั้น/ยาว
- **ความถี่คำนวณอัตโนมัติ** ตามจำนวนครั้งในเดือนเดียวกัน
- **เวลาเริ่ม/สิ้นสุด** เลือกเป็น TimePicker
- **ระยะเวลารวม** คำนวณอัตโนมัติจากเวลาเริ่ม/สิ้นสุด
- วันนัดครั้งต่อไป + เวลา
- **CG auto-fill** จาก user ที่ login อยู่ (Admin เลือก user จาก dropdown)

### 📊 รายงาน (2 โหมด)
- **รายผู้ป่วย** — ตารางสรุปจำนวนการเยี่ยม กรองตามกลุ่ม/ช่วงวันที่
- **ราย CG/User** — ดูว่าแต่ละคนเยี่ยมใครไปกี่ครั้ง กี่ชั่วโมง กดดูรายละเอียด visit แต่ละครั้ง
- Export PDF ได้ทั้ง 2 โหมด

### 👥 จัดการผู้ใช้งาน (Admin)
- เพิ่ม / แก้ไข / ลบ user
- 6 roles: Admin, เจ้าหน้าที่, CG, CM, ทีมสหสาขาวิชาชีพ, ฝ่ายทะเบียน

## 📦 Dependencies หลัก

| Package               | เวอร์ชัน   | การใช้งาน                       |
|-----------------------|----------|-------------------------------|
| firebase_core         | ^4.5.0   | Firebase initialization       |
| cloud_firestore       | ^6.1.3   | เก็บข้อมูล Patients & CarePlans  |
| sqflite               | ^2.3.3   | เก็บข้อมูล Users (local)         |
| google_fonts          | ^6.2.1   | Font: Prompt + Noto Sans Thai |
| pdf                   | ^3.10.8  | สร้าง PDF รายงาน                |
| printing              | ^5.12.0  | Print / Export PDF            |
| flutter_localizations | SDK      | รองรับ 2 ภาษา                  |

## 🎨 Design System

- **Primary color:** `#2A7C6F` (Deep Teal)
- **Font heading:** Prompt
- **Font body:** Noto Sans Thai
- **Theme:** Warm Sage + Deep Teal — อบอุ่น เหมาะกับระบบดูแลผู้สูงอายุ
- **Group colors:**
  - ติดเตียง: `#D95757` (Red)
  - ติดบ้าน: `#E8924A` (Amber)
  - ติดสังคม: `#4A90B8` (Blue)

