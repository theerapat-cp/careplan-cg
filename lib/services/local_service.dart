import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  String id, email, password, name, role, ward, phone;
  AppUser({required this.id, required this.email, required this.password,
    required this.name, required this.role, required this.ward,
    this.phone = ''});
  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    id: m['id'].toString(), email: m['email'] ?? '', password: m['password'] ?? '',
    name: m['name'] ?? '',
    role: (m['role'] ?? 'staff').toString().toLowerCase(),
    ward: m['ward'] ?? 'ฝ่ายทะเบียน',
    phone: m['phone'] ?? '');
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id, email: m['email'] ?? '', password: m['password'] ?? '',
      name: m['name'] ?? '',
      role: (m['role'] ?? 'staff').toString().toLowerCase(),
      ward: m['ward'] ?? 'ฝ่ายทะเบียน',
      phone: m['phone'] ?? '');
  }
}

class Patient {
  String id, name, age, disease, gender, house, idCard, relative, relativeRelation, phone, group;
  Patient({required this.id, required this.name, required this.age, required this.disease,
    this.gender = 'ชาย', this.house = '', this.idCard = '', this.relative = '',
    this.relativeRelation = '', this.phone = '', this.group = '1.กลุ่มติดเตียง'});
  factory Patient.fromMap(Map<String, dynamic> m) => Patient(
    id: m['id'].toString(), name: m['name'] ?? '', age: m['age']?.toString() ?? '',
    disease: m['disease'] ?? '', gender: m['gender'] ?? 'ชาย', house: m['house'] ?? '',
    idCard: m['id_card'] ?? '', relative: m['relative'] ?? '',
    relativeRelation: m['relativeRelation'] ?? '', phone: m['phone'] ?? '',
    group: m['grp'] ?? '1.กลุ่มติดเตียง');
  Map<String, dynamic> toMap() => {
    'name': name, 'age': age, 'disease': disease, 'gender': gender,
    'house': house, 'id_card': idCard, 'relative': relative,
    'relativeRelation': relativeRelation, 'phone': phone, 'grp': group};
}

class CarePlan {
  String id, patientId, cgName, cgPhone, shortGoal, longGoal, medicine, note;
  int visitCount; String visitDate, nextDate;
  CarePlan({required this.id, required this.patientId, this.cgName = '', this.cgPhone = '',
    this.shortGoal = '', this.longGoal = '', this.medicine = '', this.note = '',
    this.visitCount = 1, this.visitDate = '', this.nextDate = ''});
  factory CarePlan.fromMap(Map<String, dynamic> m) => CarePlan(
    id: m['id'].toString(), patientId: m['patient_id'].toString(),
    cgName: m['cg_name'] ?? '', cgPhone: m['cg_phone'] ?? '',
    shortGoal: m['short_goal'] ?? '', longGoal: m['long_goal'] ?? '',
    medicine: m['medicine'] ?? '', note: m['note'] ?? '',
    visitCount: m['visit_count'] ?? 1, visitDate: m['visit_date'] ?? '', nextDate: m['next_date'] ?? '');
  Map<String, dynamic> toMap() => {
    'patient_id': patientId, 'cg_name': cgName, 'cg_phone': cgPhone,
    'short_goal': shortGoal, 'long_goal': longGoal, 'medicine': medicine,
    'note': note, 'visit_count': visitCount, 'visit_date': visitDate, 'next_date': nextDate};
}

class LocalService {
  static final LocalService _i = LocalService._();
  factory LocalService() => _i;
  LocalService._();

  static Database? _db;
  final _ctrl = StreamController<List<Patient>>.broadcast();
  AppUser? currentUser;

  final _fs = FirebaseFirestore.instance;

  // ── SharedPreferences keys ────────────────────────────────────
  static const _keyUid      = 'session_uid';
  static const _keyEmail    = 'session_email';
  static const _keyPassword = 'session_password';
  static const _keyName     = 'session_name';
  static const _keyRole     = 'session_role';
  static const _keyWard     = 'session_ward';
  static const _keyPhone    = 'session_phone';

  Future<Database> get db async { _db ??= await _init(); return _db!; }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'careplan_v3.db');
    return openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, age TEXT, disease TEXT, gender TEXT,
        house TEXT, id_card TEXT, relative TEXT, phone TEXT, grp TEXT)''');
      await db.execute('''CREATE TABLE careplans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER, cg_name TEXT, cg_phone TEXT,
        short_goal TEXT, long_goal TEXT, medicine TEXT,
        note TEXT, visit_count INTEGER, visit_date TEXT, next_date TEXT)''');
    });
  }

  // ─────────────────────────────────────────────
  // SESSION — บันทึก/ดึง/ล้าง login ค้างไว้
  // ─────────────────────────────────────────────

  /// เรียกตอนเปิดแอป — ถ้ามี session ค้างจะ return AppUser ทันที
  Future<AppUser?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_keyUid);
      if (uid == null || uid.isEmpty) return null;
      currentUser = AppUser(
        id       : uid,
        email    : prefs.getString(_keyEmail)    ?? '',
        password : prefs.getString(_keyPassword) ?? '',
        name     : prefs.getString(_keyName)     ?? '',
        role     : prefs.getString(_keyRole)     ?? 'staff',
        ward     : prefs.getString(_keyWard)     ?? '',
        phone    : prefs.getString(_keyPhone)    ?? '',
      );
      return currentUser;
    } catch (_) { return null; }
  }

  Future<void> _saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid,      user.id);
    await prefs.setString(_keyEmail,    user.email);
    await prefs.setString(_keyPassword, user.password);
    await prefs.setString(_keyName,     user.name);
    await prefs.setString(_keyRole,     user.role);
    await prefs.setString(_keyWard,     user.ward);
    await prefs.setString(_keyPhone,    user.phone);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyName);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyWard);
    await prefs.remove(_keyPhone);
  }

  // ─────────────────────────────────────────────
  // SEED — เพิ่ม default users ครั้งแรกอัตโนมัติ
  // ─────────────────────────────────────────────
  Future<void> seedDefaultUsers() async {
    try {
      final snap = await _fs.collection('users').limit(1).get();
      if (snap.docs.isNotEmpty) return;
      final defaults = [
        {'email': 'admin@careplan.com',    'password': '123456', 'name': 'ผู้ดูแลระบบ',            'role': 'admin',    'ward': 'ฝ่ายบริหาร'},
        {'email': 'staff@careplan.com',    'password': '123456', 'name': 'นาย สมชาย เจ้าหน้าที่', 'role': 'staff',    'ward': 'ฝ่ายเจ้าหน้าที่'},
        {'email': 'register@careplan.com', 'password': '123456', 'name': 'นาง สมหญิง ทะเบียน',    'role': 'register', 'ward': 'ฝ่ายทะเบียน'},
      ];
      final batch = _fs.batch();
      for (final u in defaults) { batch.set(_fs.collection('users').doc(), u); }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> forceCreateAdmin() async {
    try {
      final snap = await _fs.collection('users')
          .where('email', isEqualTo: 'admin@careplan.com').limit(1).get();
      if (snap.docs.isNotEmpty) {
        await _fs.collection('users').doc(snap.docs.first.id).update({'role': 'admin'});
      } else {
        await _fs.collection('users').add({
          'email': 'admin@careplan.com', 'password': '123456',
          'name': 'ผู้ดูแลระบบ', 'role': 'admin', 'ward': 'ฝ่ายบริหาร',
        });
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // USER — Firestore
  // ─────────────────────────────────────────────

  Future<AppUser?> login(String email, String password) async {
    final snap = await _fs.collection('users')
        .where('email', isEqualTo: email.trim())
        .where('password', isEqualTo: password)
        .limit(1).get();
    if (snap.docs.isEmpty) return null;
    currentUser = AppUser.fromFirestore(snap.docs.first);
    await _saveSession(currentUser!);   // ← บันทึก session ลงเครื่อง
    return currentUser;
  }

  Future<void> logout() async {
    currentUser = null;
    await _clearSession();              // ← ล้าง session ออกจากเครื่อง
  }

  Future<List<AppUser>> getUsers() async {
    final snap = await _fs.collection('users').get();
    return snap.docs.map(AppUser.fromFirestore).toList();
  }

  Future<void> addUser(String email, String password, String name, String role, String ward, {String phone = ''}) async {
    await _fs.collection('users').add({
      'email': email, 'password': password,
      'name': name, 'role': role.toLowerCase(),
      'ward': ward, 'phone': phone,
    });
  }

  Future<void> updateUser(String id, String email, String password, String name, String role, String ward, {String phone = ''}) async {
    await _fs.collection('users').doc(id).update({
      'email': email, 'password': password,
      'name': name, 'role': role.toLowerCase(),
      'ward': ward, 'phone': phone,
    });
  }

  Future<void> deleteUser(String id) async {
    await _fs.collection('users').doc(id).delete();
  }

  // ─────────────────────────────────────────────
  // PATIENT — SQLite
  // ─────────────────────────────────────────────

  Stream<List<Patient>> getPatients() { _refresh(); return _ctrl.stream; }

  Future<void> _refresh() async {
    final d = await db;
    final rows = await d.query('patients', orderBy: 'id DESC');
    _ctrl.add(rows.map(Patient.fromMap).toList());
  }

  Future<void> addPatient(String name, String age, String disease,
      {String gender = 'ชาย', String house = '', String idCard = '',
       String relative = '', String phone = '', String group = '1.กลุ่มติดเตียง'}) async {
    final d = await db;
    await d.insert('patients', {'name': name, 'age': age, 'disease': disease,
      'gender': gender, 'house': house, 'id_card': idCard,
      'relative': relative, 'phone': phone, 'grp': group});
    await _refresh();
  }

  Future<void> updatePatient(String id, String name, String age, String disease,
      {String gender = 'ชาย', String house = '', String idCard = '',
       String relative = '', String phone = '', String group = '1.กลุ่มติดเตียง'}) async {
    final d = await db;
    await d.update('patients',
      {'name': name, 'age': age, 'disease': disease, 'gender': gender,
       'house': house, 'id_card': idCard, 'relative': relative, 'phone': phone, 'grp': group},
      where: 'id = ?', whereArgs: [id]);
    await _refresh();
  }

  Future<void> deletePatient(String id) async {
    final d = await db;
    await d.delete('patients', where: 'id = ?', whereArgs: [id]);
    await d.delete('careplans', where: 'patient_id = ?', whereArgs: [id]);
    await _refresh();
  }

  // ─────────────────────────────────────────────
  // CAREPLAN — SQLite
  // ─────────────────────────────────────────────

  Future<List<CarePlan>> getCarePlans(String patientId) async {
    final d = await db;
    final rows = await d.query('careplans', where: 'patient_id = ?', whereArgs: [patientId], orderBy: 'id DESC');
    return rows.map(CarePlan.fromMap).toList();
  }

  Future<void> addCarePlan(String patientId, {String cgName = '', String cgPhone = '',
    String shortGoal = '', String longGoal = '', String medicine = '',
    String note = '', int visitCount = 1, String visitDate = '', String nextDate = ''}) async {
    final d = await db;
    await d.insert('careplans', {'patient_id': patientId, 'cg_name': cgName, 'cg_phone': cgPhone,
      'short_goal': shortGoal, 'long_goal': longGoal, 'medicine': medicine,
      'note': note, 'visit_count': visitCount, 'visit_date': visitDate, 'next_date': nextDate});
  }

  Future<void> updateCarePlan(String id, {String cgName = '', String cgPhone = '',
    String shortGoal = '', String longGoal = '', String medicine = '',
    String note = '', int visitCount = 1, String visitDate = '', String nextDate = ''}) async {
    final d = await db;
    await d.update('careplans',
      {'cg_name': cgName, 'cg_phone': cgPhone, 'short_goal': shortGoal, 'long_goal': longGoal,
       'medicine': medicine, 'note': note, 'visit_count': visitCount, 'visit_date': visitDate, 'next_date': nextDate},
      where: 'id = ?', whereArgs: [id]);
  }
}
