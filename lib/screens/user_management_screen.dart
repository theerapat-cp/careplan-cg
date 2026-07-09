import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/local_service.dart';
import '../main.dart';
import '../translations/app_translations.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<AppUser> users    = [];
  List<AppUser> filtered = [];
  String search     = '';
  String filterRole = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final list = await LocalService().getUsers();
    setState(() { users = list; _applyFilter(); });
  }

  void _applyFilter() {
    final t        = getTranslations(languageNotifier.value.languageCode);
    final allLabel = t['user_all'] ?? 'ทั้งหมด';
    if (filterRole.isEmpty) filterRole = allLabel;
    filtered = users.where((u) {
      final matchSearch = search.isEmpty ||
          u.email.toLowerCase().contains(search.toLowerCase()) ||
          u.name.toLowerCase().contains(search.toLowerCase());
      final matchRole = filterRole == allLabel || u.role == filterRole;
      return matchSearch && matchRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final t        = getTranslations(locale.languageCode);
        final allLabel = t['user_all'] ?? 'ทั้งหมด';
        if (filterRole.isEmpty) filterRole = allLabel;
        final roleItems = [allLabel, 'admin', 'staff', 'cg', 'cm', 'team', 'register'];

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            title: Text(t['user_title']!),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.pop(context)),
            flexibleSpace: Container(decoration: kHeaderGradient),
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.person_add_rounded),
            label: Text(t['user_add_btn']!,
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.w600, fontSize: 14)),
            onPressed: () async {
              await _showUserDialog(context, t);
              _load();
            },
          ),
          body: Column(children: [
            // ── Search + Filter ──────────────────────────────────────
            Container(
              decoration: kHeaderGradient,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 8)]),
                    child: TextField(
                      onChanged: (v) => setState(
                          () { search = v; _applyFilter(); }),
                      style: GoogleFonts.notoSansThai(
                        fontSize: 14, color: kTextHead),
                      decoration: InputDecoration(
                        hintText: t['user_search'],
                        hintStyle: GoogleFonts.notoSansThai(
                          fontSize: 13, color: kTextMuted),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: kPrimaryLight),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        filled: false),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8)]),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: roleItems.contains(filterRole)
                          ? filterRole : allLabel,
                      items: roleItems.map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(_roleLabel(g, t),
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12, color: kTextBody)))).toList(),
                      onChanged: (v) => setState(
                          () { filterRole = v!; _applyFilter(); }),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: kPrimaryLight, size: 20),
                    ),
                  ),
                ),
              ]),
            ),

            // ── Column header ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              color: const Color(0xFFEAF2EF),
              child: Row(children: [
                Expanded(
                  child: Text(t['user_col_name']!,
                      style: GoogleFonts.prompt(
                        fontWeight: FontWeight.w600,
                        fontSize: 12, color: kPrimary))),
              ]),
            ),
            const Divider(height: 1, color: Color(0xFFDEEBE7)),

            // ── List ──────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 64,
                            color: kTextMuted.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(t['user_not_found']!,
                            style: GoogleFonts.notoSansThai(
                              color: kTextMuted, fontSize: 15)),
                      ]))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: Color(0xFFF0F4F2)),
                      itemBuilder: (ctx, i) {
                        final u  = filtered[i];
                        final rc = _roleColor(u.role);
                        return InkWell(
                          onTap: () async {
                            await _showUserDialog(context, t, user: u);
                            _load();
                          },
                          child: Container(
                            color: kCard,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: rc.withOpacity(0.12),
                                child: Text(
                                  u.name.isNotEmpty ? u.name[0] : '?',
                                  style: GoogleFonts.prompt(
                                    color: rc,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                Text(
                                  u.name.isNotEmpty ? u.name : u.email,
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kTextHead)),
                                const SizedBox(height: 2),
                                Text(u.email,
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 11,
                                      color: kTextMuted)),
                                const SizedBox(height: 4),
                                // ✅ แสดงแค่ Role badge อย่างเดียว ไม่มี ward
                                _roleBadge(u.role, t),
                              ])),
                              GestureDetector(
                                onTap: () async {
                                  await _showUserDialog(context, t,
                                      user: u);
                                  _load();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF2EF),
                                    borderRadius:
                                        BorderRadius.circular(9)),
                                  child: const Icon(
                                      Icons.edit_outlined,
                                      color: kPrimary, size: 16),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Color(0xFFBBCDCA), size: 20),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          ]),
        );
      },
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':    return const Color(0xFF4D6E8A);
      case 'staff':    return kPrimary;
      case 'cg':       return const Color(0xFF2E8B6E);
      case 'cm':       return const Color(0xFF7B6EA8);
      case 'team':     return const Color(0xFFB05E2E);
      case 'register': return const Color(0xFF5B8A7A);
      default:         return kTextMuted;
    }
  }

  String _roleLabel(String role, Map<String, String> t) {
    switch (role) {
      case 'admin':    return 'Admin';
      case 'staff':    return t['role_staff']    ?? 'เจ้าหน้าที่';
      case 'cg':       return 'เจ้าหน้าที่ CG';
      case 'cm':       return 'เจ้าหน้าที่ CM';
      case 'team':     return 'ทีมสหสาขาวิชาชีพ';
      case 'register': return t['role_register'] ?? 'ฝ่ายทะเบียน';
      default:         return t['user_all']      ?? 'ทั้งหมด';
    }
  }

  Widget _roleBadge(String role, Map<String, String> t) {
    final c = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8)),
      child: Text(_roleLabel(role, t),
          style: GoogleFonts.notoSansThai(
            fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _showUserDialog(BuildContext context,
      Map<String, String> t, {AppUser? user}) async {
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passCtrl  = TextEditingController(text: user?.password ?? '');
    final nameCtrl  = TextEditingController(text: user?.name ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    String role     = user?.role ?? 'staff';
    bool showPass   = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE5E3),
                  borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(user == null
                  ? t['user_dialog_add']! : t['user_dialog_edit']!,
                  style: GoogleFonts.prompt(
                    fontSize: 18, fontWeight: FontWeight.w600,
                    color: kTextHead)),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [kPrimary, kPrimaryLight]),
                    shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      nameCtrl.text.isNotEmpty
                          ? nameCtrl.text[0] : '?',
                      style: GoogleFonts.prompt(
                        color: kWhite, fontSize: 24,
                        fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.notoSansThai(
                  fontSize: 14, color: kTextHead),
                decoration: InputDecoration(
                  labelText: t['user_label_email'],
                  prefixIcon: const Icon(Icons.email_outlined,
                      size: 20, color: kPrimaryLight))),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: !showPass,
                style: GoogleFonts.notoSansThai(
                  fontSize: 14, color: kTextHead),
                decoration: InputDecoration(
                  labelText: t['user_label_pass'],
                  prefixIcon: const Icon(Icons.lock_outline,
                      size: 20, color: kPrimaryLight),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20, color: kTextMuted),
                    onPressed: () =>
                        setS(() => showPass = !showPass)))),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.notoSansThai(
                  fontSize: 14, color: kTextHead),
                decoration: InputDecoration(
                  labelText: t['user_label_name'],
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      size: 20, color: kPrimaryLight))),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.notoSansThai(
                  fontSize: 14, color: kTextHead),
                decoration: InputDecoration(
                  labelText: 'เบอร์โทรศัพท์',
                  prefixIcon: const Icon(Icons.phone_outlined,
                      size: 20, color: kPrimaryLight))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(
                    labelText: t['user_label_role']),
                items: [
                  DropdownMenuItem(value: 'admin',
                    child: Text('Admin',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14, color: kTextHead))),
                  DropdownMenuItem(value: 'staff',
                    child: Text(t['role_staff'] ?? 'เจ้าหน้าที่',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14, color: kTextHead))),
                  DropdownMenuItem(value: 'cg',
                    child: Text('เจ้าหน้าที่ CG',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14, color: kTextHead))),
                  DropdownMenuItem(value: 'cm',
                    child: Text('เจ้าหน้าที่ CM',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14, color: kTextHead))),
                  DropdownMenuItem(value: 'team',
                    child: Text('ทีมสหสาขาวิชาชีพ',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14, color: kTextHead))),
                  DropdownMenuItem(value: 'register',
                    child: Text(t['role_register'] ?? 'ฝ่ายทะเบียน',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14, color: kTextHead))),
                ],
                onChanged: (v) => setS(() => role = v!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (user == null) {
                    await LocalService().addUser(
                        emailCtrl.text.trim(),
                        passCtrl.text,
                        nameCtrl.text.trim(),
                        role, '',
                        phone: phoneCtrl.text.trim());
                  } else {
                    await LocalService().updateUser(
                        user.id,
                        emailCtrl.text.trim(),
                        passCtrl.text,
                        nameCtrl.text.trim(),
                        role, '',
                        phone: phoneCtrl.text.trim());
                  }
                  Navigator.pop(ctx);
                },
                child: Text(user == null
                    ? t['user_save_add']! : t['user_save_edit']!),
              ),
              if (user != null) ...[
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kBed,
                      minimumSize: const Size(double.infinity, 52)),
                  onPressed: () async {
                    await LocalService().deleteUser(user.id);
                    Navigator.pop(ctx);
                  },
                  child: Text(t['user_delete']!),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
