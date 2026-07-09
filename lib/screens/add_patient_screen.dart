import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../translations/app_translations.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});
  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey             = GlobalKey<FormState>();
  final nameCtrl             = TextEditingController();
  final ageCtrl              = TextEditingController();
  final houseCtrl            = TextEditingController();
  final idCardCtrl           = TextEditingController();
  final relativeCtrl         = TextEditingController();
  final relativeRelationCtrl = TextEditingController();
  final diseaseCtrl          = TextEditingController();
  String gender       = 'ชาย';
  String group        = '1.กลุ่มติดเตียง';
  bool isLoading      = false;
  bool _pdpaAccepted  = false;

  // ── PDPA Dialog ─────────────────────────────────────────────────
  Future<bool> _showPdpaDialog() async {
    bool accepted = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: kCard,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon header
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimary.withOpacity(0.1),
                  border: Border.all(color: kPrimary.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.privacy_tip_outlined,
                    color: kPrimary, size: 30),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'นโยบายคุ้มครองข้อมูลส่วนบุคคล',
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTextHead,
                ),
              ),
              Text(
                'Personal Data Protection Act (PDPA)',
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(
                  fontSize: 11,
                  color: kTextMuted,
                ),
              ),
              const SizedBox(height: 16),

              // Divider
              Container(height: 1, color: const Color(0xFFEAF0EE)),
              const SizedBox(height: 14),

              // Content
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD4EAE4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pdpaItem(
                      Icons.lock_outline_rounded,
                      'การเก็บรักษาข้อมูล',
                      'ข้อมูลส่วนบุคคลของผู้รับบริการจะถูกจัดเก็บอย่างปลอดภัย และเข้าถึงได้เฉพาะผู้มีสิทธิ์ที่กำหนดเท่านั้น',
                    ),
                    const SizedBox(height: 10),
                    _pdpaItem(
                      Icons.people_outline_rounded,
                      'วัตถุประสงค์การใช้ข้อมูล',
                      'ข้อมูลจะถูกนำไปใช้เพื่อการดูแลสุขภาพ วางแผนการรักษา และติดตามผลการดูแลผู้สูงอายุเท่านั้น',
                    ),
                    const SizedBox(height: 10),
                    _pdpaItem(
                      Icons.share_outlined,
                      'การเปิดเผยข้อมูล',
                      'ข้อมูลจะไม่ถูกเปิดเผยต่อบุคคลภายนอก หรือนำไปใช้เพื่อวัตถุประสงค์อื่นโดยไม่ได้รับความยินยอม',
                    ),
                    const SizedBox(height: 10),
                    _pdpaItem(
                      Icons.verified_user_outlined,
                      'สิทธิ์ของเจ้าของข้อมูล',
                      'เจ้าของข้อมูลมีสิทธิ์ขอตรวจสอบ แก้ไข หรือลบข้อมูลส่วนบุคคลของตนได้ตลอดเวลา',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Consent note
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kPrimary.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'การกดยืนยัน ถือว่าผู้บันทึกรับทราบและยอมรับนโยบายคุ้มครองข้อมูลส่วนบุคคลตาม พ.ร.บ. คุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 11,
                        color: kPrimaryDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      accepted = false;
                      Navigator.pop(ctx);
                    },
                    child: Text('ยกเลิก',
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          color: kTextMuted,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      accepted = true;
                      Navigator.pop(ctx);
                    },
                    child: Text('ยืนยัน',
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    return accepted;
  }

  Widget _pdpaItem(IconData icon, String title, String desc) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: kPrimary),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.prompt(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kTextHead,
              )),
          const SizedBox(height: 2),
          Text(desc,
              style: GoogleFonts.notoSansThai(
                fontSize: 11,
                color: kTextBody,
                height: 1.5,
              )),
        ]),
      ),
    ]);
  }

  // ── Save ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // ✅ แสดง PDPA ทันทีเมื่อเปิดหน้า
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final accepted = await _showPdpaDialog();
      if (!accepted && mounted) {
        Navigator.pop(context); // ถ้าไม่ยอมรับ ปิดหน้าเลย
      } else {
        setState(() => _pdpaAccepted = true);
      }
    });
  }

  void save(Map<String, String> t) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_pdpaAccepted) return;
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('patients').add({
        'name'            : nameCtrl.text.trim(),
        'age'             : ageCtrl.text.trim(),
        'disease'         : diseaseCtrl.text.trim(),
        'gender'          : gender,
        'house'           : houseCtrl.text.trim(),
        'idCard'          : idCardCtrl.text.trim(),
        'relative'        : relativeCtrl.text.trim(),
        'relativeRelation': relativeRelationCtrl.text.trim(),
        'group'           : group,
        'createdAt'       : FieldValue.serverTimestamp(),
        'pdpaAccepted'    : true, // ✅ บันทึกว่ายอมรับ PDPA แล้ว
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('เกิดข้อผิดพลาด: $e',
            style: GoogleFonts.notoSansThai(color: kWhite)),
        backgroundColor: kBed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          gender = genderOptions.first;
        }

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            title: Text(t['patient_list_add_btn']!),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.pop(context)),
            flexibleSpace: Container(decoration: kHeaderGradient),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(children: [
                // Header
                Container(
                  decoration: kHeaderGradient,
                  padding: const EdgeInsets.only(bottom: 24, top: 4),
                  child: Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kWhite.withOpacity(0.2),
                        border: Border.all(
                            color: kWhite.withOpacity(0.4), width: 2)),
                      child: const Icon(Icons.person_rounded,
                          size: 44, color: kWhite),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _sectionCard([
                      _requiredField(t['edit_name']!, nameCtrl),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _requiredField(
                            t['edit_age']!, ageCtrl,
                            keyboard: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _dropdown(
                            t['edit_gender']!, gender, genderOptions,
                            (v) => setState(() => gender = v!))),
                      ]),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard([
                      _optField(t['edit_house']!, houseCtrl),
                      const SizedBox(height: 12),
                      _optField(t['edit_idcard']!, idCardCtrl,
                          keyboard: TextInputType.number),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard([
                      _optField(t['edit_relative']!, relativeCtrl),
                      const SizedBox(height: 12),
                      _optField('ความสัมพันธ์กับผู้สูงอายุ',
                          relativeRelationCtrl),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard([
                      _dropdown(t['edit_group']!, group,
                          ['1.กลุ่มติดเตียง', '2.กลุ่มติดบ้าน', '3.กลุ่มติดสังคม'],
                          (v) => setState(() => group = v!)),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard([
                      _label(t['edit_disease']!),
                      const SizedBox(height: 8),
                      TextField(
                        controller: diseaseCtrl, maxLines: 3,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14, color: kTextHead),
                        decoration: InputDecoration(
                          hintText: t['edit_disease'],
                          filled: true,
                          fillColor: const Color(0xFFEAF5F1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFCCE4DE))),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFCCE4DE))),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: kPrimary, width: 2))),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: kPrimary))
                        : ElevatedButton(
                            onPressed: () => save(t),
                            child: Text(t['patient_list_add_btn']!)),
                    const SizedBox(height: 28),
                  ]),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5EDEA))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children),
  );

  Widget _label(String text) => Text(text,
      style: GoogleFonts.notoSansThai(
        fontSize: 13, fontWeight: FontWeight.w600, color: kTextBody));

  Widget _requiredField(String label, TextEditingController ctrl,
      {TextInputType? keyboard}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, keyboardType: keyboard,
        style: GoogleFonts.notoSansThai(fontSize: 14, color: kTextHead),
        validator: (v) =>
            (v == null || v.isEmpty) ? 'กรุณากรอก$label' : null,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.notoSansThai(
            fontSize: 13, color: kTextMuted)),
      ),
    ]);
  }

  Widget _optField(String label, TextEditingController ctrl,
      {TextInputType? keyboard}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, keyboardType: keyboard,
        style: GoogleFonts.notoSansThai(fontSize: 14, color: kTextHead),
        decoration: InputDecoration(hintText: label),
      ),
    ]);
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8E5E2))),
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
