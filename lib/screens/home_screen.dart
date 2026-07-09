import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/local_service.dart';
import 'login_screen.dart';
import 'patient_list_screen.dart';
import 'dashboard_screen.dart';
import 'user_management_screen.dart';

const _th = {
  'appName': 'Careplan CG',
  'role_admin': 'ผู้ดูแลระบบ', 'role_staff': 'เจ้าหน้าที่',
  'role_cg': 'เจ้าหน้าที่ CG', 'role_cm': 'เจ้าหน้าที่ CM',
  'role_team': 'ทีมสหสาขาวิชาชีพ', 'role_register': 'ฝ่ายทะเบียน',
  'menu_file': 'แฟ้มข้อมูล', 'menu_file_sub': 'จัดการข้อมูลผู้สูงอายุ',
  'menu_report': 'รายงานสรุปผล', 'menu_report_sub': 'ดูสถิติและรายงาน',
  'menu_user': 'จัดการผู้ใช้งาน', 'menu_user_sub': 'เพิ่ม/แก้ไข/ลบ User',
  'language': 'ภาษา', 'about': 'เกี่ยวกับแอป', 'contact': 'ติดต่อผู้ดูแลระบบ',
  'logout': 'ออกจากระบบ', 'lang_title': 'เลือกภาษา',
  'lang_th': 'ภาษาไทย', 'lang_en': 'English',
  'about_desc': 'ระบบจัดการแผนการดูแลผู้สูงอายุ\nสำหรับเจ้าหน้าที่และฝ่ายทะเบียน',
  'version': 'เวอร์ชัน 1.0.0', 'close': 'ปิด',
  'contact_name': 'ผู้ดูแลระบบ Careplan CG',
  'contact_phone': '081-234-5678', 'contact_email': 'admin@careplan.com',
  'contact_hours': 'จ-ศ  08:00 - 17:00 น.',
  'admin': 'ผู้ดูแล', 'phone': 'โทรศัพท์', 'email': 'อีเมล',
  'hours': 'เวลาทำการ', 'greeting_morning': 'สวัสดีตอนเช้า',
  'greeting_afternoon': 'สวัสดีตอนบ่าย', 'greeting_evening': 'สวัสดีตอนเย็น',
};

const _en = {
  'appName': 'Careplan CG',
  'role_admin': 'Administrator', 'role_staff': 'Staff',
  'role_cg': 'CG Officer', 'role_cm': 'CM Officer',
  'role_team': 'Multi-disciplinary Team', 'role_register': 'Registration',
  'menu_file': 'Patient Files', 'menu_file_sub': 'Manage elderly patient data',
  'menu_report': 'Reports', 'menu_report_sub': 'View statistics & reports',
  'menu_user': 'User Management', 'menu_user_sub': 'Add / Edit / Delete Users',
  'language': 'Language', 'about': 'About App', 'contact': 'Contact Admin',
  'logout': 'Logout', 'lang_title': 'Select Language',
  'lang_th': 'ภาษาไทย', 'lang_en': 'English',
  'about_desc': 'Elderly care plan management system\nfor staff and registration officers.',
  'version': 'Version 1.0.0', 'close': 'Close',
  'contact_name': 'Careplan CG Admin',
  'contact_phone': '081-234-5678', 'contact_email': 'admin@careplan.com',
  'contact_hours': 'Mon-Fri  08:00 - 17:00',
  'admin': 'Admin', 'phone': 'Phone', 'email': 'Email',
  'hours': 'Office Hours', 'greeting_morning': 'Good morning',
  'greeting_afternoon': 'Good afternoon', 'greeting_evening': 'Good evening',
};

class HomeScreen extends StatelessWidget {
  final AppUser user;
  const HomeScreen({super.key, required this.user});

  Map<String, String> get _t =>
      languageNotifier.value.languageCode == 'th' ? _th : _en;

  String _greeting(Map<String, String> t) {
    final h = DateTime.now().hour;
    if (h < 12) return t['greeting_morning']!;
    if (h < 17) return t['greeting_afternoon']!;
    return t['greeting_evening']!;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, _, __) {
        final t = _t;
        return Scaffold(
          backgroundColor: const Color(0xFFF0F4F2),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, t)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ..._buildMenuCards(context, t),
                    const SizedBox(height: 28),
                    _buildVersionBadge(),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, String> t) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF071C18), Color(0xFF0D2B26), Color(0xFF1A4038)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.4, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative orbs
          Positioned(top: -80, right: -60,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF2DD4A0).withOpacity(0.07),
                  Colors.transparent,
                ]),
              ))),
          Positioned(bottom: -50, left: -30,
            child: Container(width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03)))),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: Column(children: [
                // Top bar
                Row(children: [
                  // Logo ring
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF2DD4A0).withOpacity(0.35),
                          width: 1),
                      color: Colors.white.withOpacity(0.07),
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(22, 22),
                        painter: _MiniShieldPainter(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Careplan CG',
                        style: GoogleFonts.playfairDisplay(
                          color: kWhite, fontSize: 18,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    Text(_roleLabel(user.role, t),
                        style: GoogleFonts.notoSansThai(
                          color: const Color(0xFF9FE1CB),
                          fontSize: 11, letterSpacing: 0.5)),
                  ]),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showProfile(context, t),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF2DD4A0).withOpacity(0.5),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2DD4A0).withOpacity(0.2),
                            blurRadius: 10, spreadRadius: 0),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF2DD4A0).withOpacity(0.2),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0] : '?',
                          style: GoogleFonts.playfairDisplay(
                            color: kWhite, fontSize: 16,
                            fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 28),

                // Greeting card — glassmorphism
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white.withOpacity(0.07),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(children: [
                    // Avatar
                    Container(
                      width: 58, height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2DD4A0), Color(0xFF1BB884)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                            color: const Color(0xFF2DD4A0).withOpacity(0.4),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2DD4A0).withOpacity(0.3),
                            blurRadius: 12, spreadRadius: 0),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0] : '?',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFF071C18), fontSize: 22,
                            fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(t),
                            style: GoogleFonts.notoSansThai(
                              color: const Color(0xFF9FE1CB),
                              fontSize: 12)),
                        const SizedBox(height: 3),
                        Text(user.name,
                            style: GoogleFonts.playfairDisplay(
                              color: kWhite, fontSize: 18,
                              fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        _RoleBadge(role: user.role, t: t),
                      ],
                    )),
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.08))),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFF9FE1CB), size: 20)),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuCards(BuildContext context, Map<String, String> t) {
    return [
      const SizedBox(height: 24),
      _PremiumMenuCard(
        icon: Icons.folder_shared_rounded,
        label: t['menu_file']!,
        subtitle: t['menu_file_sub']!,
        gradient: const [Color(0xFF1BB884), Color(0xFF0D8A60)],
        accentColor: const Color(0xFFE8F5F0),
        tagColor: const Color(0xFF1BB884),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PatientListScreen())),
      ),
      if (user.role == 'staff' || user.role == 'admin' ||
          user.role == 'cg'    || user.role == 'cm'    ||
          user.role == 'team') ...const [SizedBox(height: 14)],
      if (user.role == 'staff' || user.role == 'admin' ||
          user.role == 'cg'    || user.role == 'cm'    ||
          user.role == 'team')
        _PremiumMenuCard(
          icon: Icons.bar_chart_rounded,
          label: t['menu_report']!,
          subtitle: t['menu_report_sub']!,
          gradient: const [Color(0xFF3B8FD8), Color(0xFF1B6AB0)],
          accentColor: const Color(0xFFE5EEF7),
          tagColor: const Color(0xFF3B8FD8),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DashboardScreen())),
        ),
      if (user.role == 'admin') ...const [SizedBox(height: 14)],
      if (user.role == 'admin')
        _PremiumMenuCard(
          icon: Icons.manage_accounts_rounded,
          label: t['menu_user']!,
          subtitle: t['menu_user_sub']!,
          gradient: const [Color(0xFF7B6EA8), Color(0xFF5B4D88)],
          accentColor: const Color(0xFFEEEAF8),
          tagColor: const Color(0xFF7B6EA8),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const UserManagementScreen())),
        ),
    ];
  }

  Widget _buildVersionBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5EDEA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2DD4A0),
            ),
          ),
          const SizedBox(width: 9),
          Text('Careplan CG  •  v1.0.0',
              style: GoogleFonts.prompt(
                fontSize: 11, color: kTextMuted,
                fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  String _roleLabel(String role, Map<String, String> t) {
    switch (role) {
      case 'admin':    return t['role_admin']!;
      case 'staff':    return t['role_staff']!;
      case 'cg':       return t['role_cg'] ?? 'เจ้าหน้าที่ CG';
      case 'cm':       return t['role_cm'] ?? 'เจ้าหน้าที่ CM';
      case 'team':     return t['role_team'] ?? 'ทีมสหสาขาวิชาชีพ';
      case 'register': return t['role_register']!;
      default:         return role;
    }
  }

  void _showProfile(BuildContext context, Map<String, String> t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ValueListenableBuilder<Locale>(
        valueListenable: languageNotifier,
        builder: (ctx, locale, __) {
          final t2 = locale.languageCode == 'th' ? _th : _en;
          return Container(
            decoration: const BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Center(child: Container(
                width: 44, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE5E3),
                  borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              // Avatar
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2DD4A0), Color(0xFF1BB884)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(
                      color: const Color(0xFF2DD4A0).withOpacity(0.4),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2DD4A0).withOpacity(0.25),
                      blurRadius: 16, spreadRadius: 1),
                  ],
                ),
                child: Center(child: Text(
                  user.name.isNotEmpty ? user.name[0] : '?',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFF071C18), fontSize: 28,
                    fontWeight: FontWeight.w800))),
              ),
              const SizedBox(height: 12),
              Text(user.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: kTextHead)),
              const SizedBox(height: 4),
              Text(user.email,
                  style: GoogleFonts.notoSansThai(
                    color: kTextMuted, fontSize: 13)),
              const SizedBox(height: 10),
              _RoleBadge(role: user.role, t: t2, dark: true),
              const SizedBox(height: 22),
              const Divider(height: 1, color: Color(0xFFEAF0EE)),
              _profileTile(Icons.language_rounded, t2['language']!,
                  trailing: Text(
                    locale.languageCode == 'th' ? '🇹🇭 ไทย' : '🇬🇧 EN',
                    style: GoogleFonts.prompt(
                      fontSize: 13, color: kPrimary,
                      fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showLanguageDialog(context);
                  }),
              _profileTile(Icons.info_outline_rounded, t2['about']!,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAbout(context, t2);
                  }),
              _profileTile(Icons.support_agent_rounded, t2['contact']!,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showContact(context, t2);
                  }),
              const Divider(height: 1, color: Color(0xFFEAF0EE)),
              _profileTile(Icons.logout_rounded, t2['logout']!,
                  color: kBed, onTap: () {
                    LocalService().logout();
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()));
                  }),
            ]),
          );
        },
      ),
    );
  }

  Widget _profileTile(IconData icon, String label,
      {Color? color, Widget? trailing, VoidCallback? onTap}) {
    final c = color ?? kTextBody;
    return ListTile(
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, size: 18, color: c),
      ),
      title: Text(label,
          style: GoogleFonts.notoSansThai(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: color ?? kTextHead)),
      trailing: trailing ?? const Icon(Icons.chevron_right,
          size: 18, color: Color(0xFFBBCDCA)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ValueListenableBuilder<Locale>(
        valueListenable: languageNotifier,
        builder: (ctx, locale, __) {
          final t = locale.languageCode == 'th' ? _th : _en;
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.language_rounded,
                    color: kPrimary, size: 20)),
              const SizedBox(width: 10),
              Text(t['lang_title']!,
                  style: GoogleFonts.prompt(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: kTextHead)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Divider(),
              _langOption(ctx, '🇹🇭', t['lang_th']!,
                  const Locale('th', 'TH'), locale),
              const Divider(height: 1),
              _langOption(ctx, '🇬🇧', t['lang_en']!,
                  const Locale('en', 'US'), locale),
            ]),
          );
        },
      ),
    );
  }

  Widget _langOption(BuildContext ctx, String flag, String label,
      Locale locale, Locale current) {
    final sel = current.languageCode == locale.languageCode;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label,
          style: GoogleFonts.notoSansThai(
            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
            color: sel ? kPrimary : kTextHead)),
      trailing: Icon(sel ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: sel ? kPrimary : const Color(0xFFCCDBD8), size: 22),
      onTap: () {
        languageNotifier.value = locale;
        Navigator.pop(ctx);
      },
    );
  }

  void _showAbout(BuildContext context, Map<String, String> t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2DD4A0), Color(0xFF1BB884)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              border: Border.all(
                  color: const Color(0xFF2DD4A0).withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2DD4A0).withOpacity(0.2),
                  blurRadius: 16, spreadRadius: 0),
              ],
            ),
            child: Center(child: CustomPaint(
              size: const Size(42, 42),
              painter: _MiniShieldPainter(),
            )),
          ),
          const SizedBox(height: 14),
          Text('Careplan CG',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w700, color: kTextHead)),
          const SizedBox(height: 4),
          Text(t['version']!,
              style: GoogleFonts.notoSansThai(
                fontSize: 12, color: kTextMuted)),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Text(t['about_desc']!,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansThai(
                fontSize: 13, color: kTextMuted, height: 1.7)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t['close']!,
                style: GoogleFonts.prompt(
                  color: kPrimary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _showContact(BuildContext context, Map<String, String> t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.support_agent_rounded,
                color: kPrimary, size: 20)),
          const SizedBox(width: 10),
          Text(t['contact']!,
              style: GoogleFonts.prompt(
                fontSize: 16, fontWeight: FontWeight.w600, color: kTextHead)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Divider(),
          const SizedBox(height: 8),
          _contactRow(Icons.person_outline_rounded, t['admin']!, t['contact_name']!),
          const SizedBox(height: 10),
          _contactRow(Icons.phone_outlined, t['phone']!, t['contact_phone']!),
          const SizedBox(height: 10),
          _contactRow(Icons.email_outlined, t['email']!, t['contact_email']!),
          const SizedBox(height: 10),
          _contactRow(Icons.access_time_rounded, t['hours']!, t['contact_hours']!),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t['close']!,
                style: GoogleFonts.prompt(
                  color: kPrimary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  static Widget _contactRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: kPrimary),
      const SizedBox(width: 10),
      SizedBox(width: 80,
        child: Text(label,
            style: GoogleFonts.notoSansThai(fontSize: 13, color: kTextMuted))),
      Expanded(
        child: Text(value,
            style: GoogleFonts.notoSansThai(
              fontSize: 13, fontWeight: FontWeight.w600, color: kTextHead))),
    ]);
  }
}

// ── Role Badge ────────────────────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  final String role;
  final Map<String, String> t;
  final bool dark;
  const _RoleBadge({required this.role, required this.t, this.dark = false});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (role) {
      case 'admin':    c = const Color(0xFF4D6E8A); break;
      case 'staff':    c = kPrimary; break;
      case 'cg':       c = const Color(0xFF2DD4A0); break;
      case 'cm':       c = const Color(0xFF7B6EA8); break;
      case 'team':     c = const Color(0xFFB05E2E); break;
      default:         c = const Color(0xFF5B8A7A);
    }
    String label;
    switch (role) {
      case 'admin':    label = t['role_admin']!; break;
      case 'staff':    label = t['role_staff']!; break;
      case 'cg':       label = t['role_cg'] ?? 'CG'; break;
      case 'cm':       label = t['role_cm'] ?? 'CM'; break;
      case 'team':     label = t['role_team'] ?? 'Team'; break;
      case 'register': label = t['role_register']!; break;
      default:         label = role;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(dark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.25))),
      child: Text(label,
          style: GoogleFonts.notoSansThai(
            color: dark ? c : c,
            fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Premium Menu Card ─────────────────────────────────────────────
class _PremiumMenuCard extends StatefulWidget {
  final IconData icon;
  final String label, subtitle;
  final List<Color> gradient;
  final Color accentColor, tagColor;
  final VoidCallback onTap;
  const _PremiumMenuCard({
    required this.icon, required this.label, required this.subtitle,
    required this.gradient, required this.accentColor,
    required this.tagColor, required this.onTap,
  });
  @override
  State<_PremiumMenuCard> createState() => _PremiumMenuCardState();
}

class _PremiumMenuCardState extends State<_PremiumMenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _pressed
                  ? widget.tagColor.withOpacity(0.25)
                  : const Color(0xFFE5EDEA),
              width: _pressed ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradient[0].withOpacity(_pressed ? 0.05 : 0.12),
                blurRadius: _pressed ? 10 : 24,
                offset: Offset(0, _pressed ? 2 : 8)),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(children: [
            // Icon with gradient
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: widget.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient[0].withOpacity(0.35),
                    blurRadius: 12, offset: const Offset(0, 5)),
                ],
              ),
              child: Icon(widget.icon, color: kWhite, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label,
                    style: GoogleFonts.prompt(
                      fontSize: 17, fontWeight: FontWeight.w700,
                      color: kTextHead, letterSpacing: 0.1)),
                const SizedBox(height: 4),
                Text(widget.subtitle,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12, color: kTextMuted)),
              ],
            )),
            // Arrow button
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: widget.accentColor,
                borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: widget.tagColor, size: 14),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Mini Shield Painter ───────────────────────────────────────────
class _MiniShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final paint = Paint();

    final path = Path();
    path.moveTo(cx, 0);
    path.lineTo(size.width, size.height * 0.22);
    path.lineTo(size.width, size.height * 0.65);
    path.quadraticBezierTo(size.width, size.height * 0.88, cx, size.height);
    path.quadraticBezierTo(0, size.height * 0.88, 0, size.height * 0.65);
    path.lineTo(0, size.height * 0.22);
    path.close();

    paint
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.25);
    canvas.drawPath(path, paint);

    paint
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1;
    canvas.drawPath(path, paint);

    final hx = cx, hy = size.height * 0.56;
    final r = size.width * 0.2;
    final heartPath = Path();
    heartPath.moveTo(hx, hy + r * 0.8);
    heartPath.cubicTo(hx, hy + r * 0.8, hx - r * 1.8, hy + r * 0.2,
        hx - r * 1.8, hy - r * 0.3);
    heartPath.arcToPoint(Offset(hx, hy - r * 0.05),
        radius: Radius.circular(r * 0.95), clockwise: true);
    heartPath.arcToPoint(Offset(hx + r * 1.8, hy - r * 0.3),
        radius: Radius.circular(r * 0.95), clockwise: true);
    heartPath.cubicTo(hx + r * 1.8, hy + r * 0.2, hx, hy + r * 0.8,
        hx, hy + r * 0.8);
    heartPath.close();

    paint
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    canvas.drawPath(heartPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
