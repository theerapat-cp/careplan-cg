# CarePlan App — วิธีรัน

## 🚀 รันทันที (Demo Mode - ไม่ต้องมี Firebase)

โปรเจกต์นี้ถูกแก้ให้รันได้ **โดยไม่ต้องต่อ Firebase** ข้อมูลจะอยู่ใน memory (หาย เมื่อปิดแอป)

```bash
cd careplan_new
flutter pub get
flutter run
```

**Demo login:** `admin@careplan.com` / `123456`

---

## 🔥 ต่อ Firebase จริง (Production)

### 1. สร้าง Firebase Project
1. ไปที่ https://console.firebase.google.com
2. สร้าง project ใหม่
3. เปิดใช้ **Authentication** → Email/Password
4. เปิดใช้ **Firestore Database**

### 2. ติดตั้ง FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 3. Configure Firebase
```bash
cd careplan_new
flutterfire configure
```
จะสร้างไฟล์ `lib/firebase_options.dart` ให้อัตโนมัติ

### 4. แก้ pubspec.yaml เพิ่ม Firebase packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.32.0
  firebase_auth: ^4.20.0
  cloud_firestore: ^4.17.5
```

### 5. แก้ main.dart กลับมาใช้ Firebase
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CarePlanApp());
}
```

### 6. คืน services กลับ
- แก้ `lib/services/auth_service.dart` ให้ใช้ `FirebaseAuth`
- แก้ `lib/services/firestore_service.dart` ให้ใช้ `FirebaseFirestore`
- แก้ screens ให้ import จาก service เดิม แทน `LocalService`

---

## โครงสร้าง Firestore

```
patients/
  {id}/
    name: string
    age: string
    disease: string
    created_at: timestamp

careplans/
  {id}/
    patient_id: string
    medicine: string
    instruction: string
    note: string
    created_at: timestamp
```
