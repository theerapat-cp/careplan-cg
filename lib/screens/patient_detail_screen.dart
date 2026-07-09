import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/local_service.dart';
import '../main.dart';
import '../translations/app_translations.dart';
import 'edit_patient_screen.dart';
import 'careplan_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;
  const PatientDetailScreen({super.key, required this.patient});
  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> plans = [];
  late Patient p;
  late TabController _tab;
  String get _role => LocalService().currentUser?.role ?? 'staff';
  bool get _isStaffLike =>
      _role == 'staff' || _role == 'cg' ||
      _role == 'cm'    || _role == 'team';

  @override
  void initState() {
    super.initState();
    p = widget.patient;
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final snap = await FirebaseFirestore.instance
        .collection('careplans')
        .where('patientId', isEqualTo: p.id)
        .get();
    setState(() =>
        plans = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final t  = getTranslations(locale.languageCode);
        final gc = groupColor(p.group);

        return Scaffold(
          backgroundColor: const Color(0xFFF0F4F2),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF071C18),
                title: Text(t['profile_title']!,
                    style: GoogleFonts.playfairDisplay(
                      color: kWhite, fontSize: 18,
                      fontWeight: FontWeight.w700)),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kWhite.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        color: kWhite, size: 16)),
                  onPressed: () => Navigator.pop(context)),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Stack(children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF071C18), Color(0xFF0D2B26), Color(0xFF1A4038)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                    Positioned(top: -60, right: -40,
                      child: Container(width: 240, height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            const Color(0xFF2DD4A0).withOpacity(0.08),
                            Colors.transparent,
                          ]),
                        ))),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 44, bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                            Container(
                              width: 88, height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [gc.withOpacity(0.4), gc.withOpacity(0.15)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                                border: Border.all(
                                    color: kWhite.withOpacity(0.35), width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: gc.withOpacity(0.35),
                                    blurRadius: 22, offset: const Offset(0, 6))
                                ],
                              ),
                              child: Center(child: Text(
                                p.name.isNotEmpty ? p.name[0] : '?',
                                style: GoogleFonts.playfairDisplay(
                                  color: kWhite, fontSize: 34,
                                  fontWeight: FontWeight.w800))),
                            ),
                            const SizedBox(height: 12),
                            Text(p.name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                    color: kWhite, fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: gc.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: gc.withOpacity(0.3))),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(groupIcon(p.group), size: 13, color: kWhite),
                                const SizedBox(width: 5),
                                Text(p.group,
                                    style: GoogleFonts.notoSansThai(
                                      color: kWhite, fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                bottom: TabBar(
                  controller: _tab,
                  indicatorColor: const Color(0xFF2DD4A0),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: kWhite,
                  unselectedLabelColor: kWhite.withOpacity(0.45),
                  labelStyle: GoogleFonts.prompt(
                    fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'ข้อมูลส่วนตัว'),
                    Tab(text: 'การดูแล'),
                  ],
                ),
              ),

              SliverFillRemaining(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    // Tab 1 — Info
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _infoCard(t),
                        const SizedBox(height: 32),
                      ]),
                    ),
                    // Tab 2 — Care actions
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        _actionButtons(context, t),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoCard(Map<String, String> t) {
    final genderLabel = p.gender == 'ชาย'
        ? t['detail_gender_m']! : t['detail_gender_f']!;
    return Column(children: [
      _infoSection('ข้อมูลทั่วไป', Icons.person_outline_rounded, [
        _infoItem(t['detail_age']!,
            '${p.age} ${t['patient_age_suffix']}  •  $genderLabel',
            Icons.cake_outlined),
        _infoItem(t['detail_house']!, p.house, Icons.home_outlined),
        _infoItem(t['detail_idcard']!, p.idCard,
            Icons.credit_card_outlined),
      ]),
      const SizedBox(height: 12),
      _infoSection('ผู้ดูแล / ญาติ', Icons.people_outline_rounded, [
        _infoItem(t['detail_relative']!, p.relative,
            Icons.people_outline_rounded),
        _infoItem('ความสัมพันธ์',
            p.relativeRelation.isNotEmpty ? p.relativeRelation : '-',
            Icons.favorite_border_rounded),
      ]),
      const SizedBox(height: 12),
      _infoSection('โรคประจำตัว', Icons.medical_information_outlined, [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kPrimary.withOpacity(0.1))),
          child: Text(p.disease.isEmpty ? '-' : p.disease,
              style: GoogleFonts.notoSansThai(
                fontSize: 14, color: kTextBody, height: 1.7)),
        ),
      ]),
    ]);
  }

  Widget _infoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: kCardShadow,
        border: Border.all(color: const Color(0xFFECF2F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.04),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22))),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 14, color: kPrimary)),
            const SizedBox(width: 10),
            Text(title, style: GoogleFonts.prompt(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: kPrimary)),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFECF2F0)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: children)),
      ]),
    );
  }

  Widget _infoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 16, color: kPrimaryLight),
        const SizedBox(width: 10),
        SizedBox(width: 110,
          child: Text(label, style: GoogleFonts.notoSansThai(
            fontSize: 12, color: kTextMuted))),
        Expanded(child: Text(value,
            style: GoogleFonts.notoSansThai(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: kTextHead))),
      ]),
    );
  }

  Widget _actionButtons(BuildContext context, Map<String, String> t) {
    return Column(children: [
      if (_isStaffLike || _role == 'admin') ...const [SizedBox()],
      if (_isStaffLike || _role == 'admin')
        _ActionCard(
          icon: Icons.add_circle_outline_rounded,
          title: t['btn_add_visit']!,
          subtitle: 'บันทึกการเยี่ยมใหม่',
          color: kPrimary,
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => CarePlanScreen(patient: p)));
            _load();
          },
        ),
      if ((_isStaffLike || _role == 'admin') && plans.isNotEmpty) ...const [SizedBox(height: 12)],
      if ((_isStaffLike || _role == 'admin') && plans.isNotEmpty)
        _ActionCard(
          icon: Icons.assignment_outlined,
          title: t['btn_view_visit']!,
          subtitle: 'ดูบันทึกการดูแล ${plans.length} ครั้ง',
          color: const Color(0xFF2DD4A0),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => CarePlanScreen(
                    patient: p,
                    carePlanId: plans.first['id'],
                    carePlanData: plans.first)));
            _load();
          },
        ),
      if (_role == 'register' || _role == 'admin') ...const [SizedBox(height: 12)],
      if (_role == 'register' || _role == 'admin')
        _ActionCard(
          icon: Icons.edit_outlined,
          title: t['btn_edit_info']!,
          subtitle: 'แก้ไขข้อมูลผู้สูงอายุ',
          color: const Color(0xFF4D6E8A),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => EditPatientScreen(patient: p)));
            setState(() {});
          },
        ),
      if (_role == 'admin') ...const [SizedBox(height: 12)],
      if (_role == 'admin')
        _ActionCard(
          icon: Icons.delete_outline_rounded,
          title: t['btn_delete_file']!,
          subtitle: 'ลบข้อมูลออกจากระบบ',
          color: kBed,
          onTap: () async {
            final ok = await _confirmDelete(context, t);
            if (ok == true) {
              await FirebaseFirestore.instance
                  .collection('patients').doc(p.id).delete();
              if (mounted) Navigator.pop(context);
            }
          },
        ),
    ]);
  }

  Future<bool?> _confirmDelete(
      BuildContext context, Map<String, String> t) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.warning_rounded, color: kBed, size: 20)),
          const SizedBox(width: 10),
          Text(t['dialog_delete_title']!,
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.w700, color: kTextHead)),
        ]),
        content: Text('${t['dialog_delete_confirm']} ${p.name}?',
            style: GoogleFonts.notoSansThai(
              fontSize: 14, color: kTextBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t['cancel']!,
                style: GoogleFonts.prompt(color: kTextMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kBed,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t['delete']!,
                style: GoogleFonts.prompt(
                    fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

// ── Action Card ───────────────────────────────────────────────────
class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon, required this.title,
    required this.subtitle, required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pressed
                  ? widget.color.withOpacity(0.25)
                  : widget.color.withOpacity(0.1)),
            boxShadow: kCardShadow,
          ),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: widget.color.withOpacity(0.15))),
              child: Icon(widget.icon, color: widget.color, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: GoogleFonts.prompt(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: kTextHead)),
                Text(widget.subtitle, style: GoogleFonts.notoSansThai(
                  fontSize: 12, color: kTextMuted)),
              ],
            )),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: widget.color.withOpacity(0.7))),
          ]),
        ),
      ),
    );
  }
}
