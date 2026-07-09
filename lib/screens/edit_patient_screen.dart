import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/local_service.dart';
import '../translations/app_translations.dart';

class EditPatientScreen extends StatefulWidget {
  final Patient patient;
  const EditPatientScreen({super.key, required this.patient});
  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  late TextEditingController nameCtrl, ageCtrl, houseCtrl,
      idCardCtrl, relativeCtrl, relativeRelationCtrl, diseaseCtrl;
  late String gender, group;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    nameCtrl             = TextEditingController(text: p.name);
    ageCtrl              = TextEditingController(text: p.age);
    houseCtrl            = TextEditingController(text: p.house);
    idCardCtrl           = TextEditingController(text: p.idCard);
    relativeCtrl         = TextEditingController(text: p.relative);
    relativeRelationCtrl = TextEditingController(text: p.relativeRelation);
    diseaseCtrl          = TextEditingController(text: p.disease);
    gender = p.gender.isEmpty ? 'ชาย' : p.gender;
    group  = p.group.isEmpty  ? '1.กลุ่มติดเตียง' : p.group;
  }

  void save(Map<String, String> t) async {
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patient.id)
          .update({
        'name'            : nameCtrl.text.trim(),
        'age'             : ageCtrl.text.trim(),
        'disease'         : diseaseCtrl.text.trim(),
        'gender'          : gender,
        'house'           : houseCtrl.text.trim(),
        'idCard'          : idCardCtrl.text.trim(),
        'relative'        : relativeCtrl.text.trim(),
        'relativeRelation': relativeRelationCtrl.text.trim(),
        'group'           : group,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${t['edit_error']}: $e',
            style: GoogleFonts.notoSansThai(color: kWhite)),
        backgroundColor: kBed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final t = getTranslations(locale.languageCode);
        final genderOptions = [t['edit_gender_m']!, t['edit_gender_f']!];
        if (!genderOptions.contains(gender)) {
          gender = gender == 'หญิง'
              ? t['edit_gender_f']! : t['edit_gender_m']!;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF0F4F2),
          body: CustomScrollView(
            slivers: [
              // Premium header
              SliverAppBar(
                expandedHeight: 230,
                pinned: true,
                backgroundColor: const Color(0xFF071C18),
                title: Text(t['edit_title']!,
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
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF071C18), Color(0xFF0D2B26), Color(0xFF1A4038)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.0, 0.4, 1.0],
                      ),
                    ),
                    child: Stack(children: [
                      Positioned(top: -50, right: -40,
                        child: Container(width: 200, height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              const Color(0xFF2DD4A0).withOpacity(0.08),
                              Colors.transparent,
                            ]),
                          ))),
                      SafeArea(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 76, height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2DD4A0), Color(0xFF1BB884)]),
                                    border: Border.all(
                                        color: kWhite.withOpacity(0.3), width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2DD4A0).withOpacity(0.35),
                                        blurRadius: 20, spreadRadius: 0),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.patient.name.isNotEmpty
                                          ? widget.patient.name[0] : '?',
                                      style: GoogleFonts.playfairDisplay(
                                        color: const Color(0xFF071C18),
                                        fontSize: 30, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(widget.patient.name,
                                    style: GoogleFonts.prompt(
                                      color: kWhite, fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2DD4A0).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFF2DD4A0).withOpacity(0.3))),
                                  child: Text(t['edit_title']!,
                                      style: GoogleFonts.notoSansThai(
                                        color: const Color(0xFF9FE1CB),
                                        fontSize: 11, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

              // Form body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _sectionCard(
                      title: 'ข้อมูลพื้นฐาน',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _field(t['edit_name']!, nameCtrl),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: _field(t['edit_age']!, ageCtrl,
                              keyboard: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _dropdown(
                              t['edit_gender']!, gender, genderOptions,
                              (v) => setState(() => gender = v!))),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _sectionCard(
                      title: 'ที่อยู่และข้อมูลบัตร',
                      icon: Icons.home_outlined,
                      children: [
                        _field(t['edit_house']!, houseCtrl),
                        const SizedBox(height: 14),
                        _field(t['edit_idcard']!, idCardCtrl,
                            keyboard: TextInputType.number),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _sectionCard(
                      title: 'ผู้ดูแลและกลุ่มผู้ป่วย',
                      icon: Icons.people_outline_rounded,
                      children: [
                        _field(t['edit_relative']!, relativeCtrl),
                        const SizedBox(height: 14),
                        _field('ความสัมพันธ์', relativeRelationCtrl),
                        const SizedBox(height: 14),
                        _dropdown(t['edit_group']!, group,
                            ['1.กลุ่มติดเตียง', '2.กลุ่มติดบ้าน',
                             '3.กลุ่มติดสังคม'],
                            (v) => setState(() => group = v!)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _sectionCard(
                      title: 'โรคประจำตัว',
                      icon: Icons.medical_information_outlined,
                      children: [
                        TextField(
                          controller: diseaseCtrl, maxLines: 4,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 14, color: kTextHead),
                          decoration: InputDecoration(
                            hintText: 'ระบุโรคประจำตัว...',
                            hintStyle: GoogleFonts.notoSansThai(
                                fontSize: 13, color: kTextMuted),
                            filled: true,
                            fillColor: const Color(0xFFF4FAF8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFFCCE4DE))),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFFCCE4DE))),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: kPrimary, width: 2)),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Save button
                    isLoading
                        ? Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kGradStart, kGradEnd]),
                              borderRadius: BorderRadius.circular(18)),
                            child: const Center(
                              child: SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(
                                  color: kWhite, strokeWidth: 2.5))))
                        : _SaveButton(
                            label: t['edit_save']!,
                            onTap: () => save(t)),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EDEA)),
        boxShadow: kCardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.04),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22))),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
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

  Widget _label(String text) => Text(text,
      style: GoogleFonts.notoSansThai(
        fontSize: 12, fontWeight: FontWeight.w600, color: kTextBody));

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboard}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 7),
      TextField(
        controller: ctrl, keyboardType: keyboard,
        style: GoogleFonts.notoSansThai(fontSize: 14, color: kTextHead),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.notoSansThai(
              fontSize: 13, color: kTextMuted),
          filled: true,
          fillColor: const Color(0xFFF4FAF8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCCE4DE))),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCCE4DE))),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 7),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FAF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCCE4DE))),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true,
            items: items.map((g) => DropdownMenuItem(
              value: g,
              child: Text(g,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14, color: kTextHead)))).toList(),
            onChanged: onChanged,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: kPrimaryLight, size: 22),
          ),
        ),
      ),
    ]);
  }
}

// ── Save Button ───────────────────────────────────────────────────
class _SaveButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _SaveButton({required this.label, required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _pressed
                  ? [const Color(0xFF0F9E70), const Color(0xFF0D8A60)]
                  : [kGradStart, kGradEnd]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(_pressed ? 0.2 : 0.35),
                blurRadius: _pressed ? 8 : 20,
                offset: Offset(0, _pressed ? 2 : 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: kWhite.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check_rounded,
                    size: 16, color: kWhite),
              ),
              const SizedBox(width: 10),
              Text(widget.label,
                  style: GoogleFonts.prompt(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: kWhite, letterSpacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
