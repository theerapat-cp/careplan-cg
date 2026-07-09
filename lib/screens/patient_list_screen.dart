import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/local_service.dart';
import '../translations/app_translations.dart';
import 'add_patient_screen.dart';
import 'patient_detail_screen.dart';
import 'edit_patient_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});
  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  String search      = '';
  String filterGroup = '';
  String get _role   => LocalService().currentUser?.role ?? 'staff';

  final Map<String, String> _nextDateCache = {};
  bool _datesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNextDates();
  }

  Future<void> _loadNextDates() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('careplans').get();
      final todayI = _todayInt;
      final futureMap = <String, String>{};
      final pastMap   = <String, String>{};

      for (final doc in snap.docs) {
        final pid = doc['patientId']?.toString() ?? '';
        final nd  = doc['nextDate']?.toString() ?? '';
        if (pid.isEmpty || nd.isEmpty) continue;
        final nInt = _dateToSortInt(nd);
        if (nInt >= todayI) {
          if (!futureMap.containsKey(pid) ||
              nInt < _dateToSortInt(futureMap[pid]!)) futureMap[pid] = nd;
        } else {
          if (!pastMap.containsKey(pid) ||
              nInt > _dateToSortInt(pastMap[pid]!)) pastMap[pid] = nd;
        }
      }
      final map = <String, String>{};
      final allPids = {...futureMap.keys, ...pastMap.keys};
      for (final pid in allPids) {
        map[pid] = futureMap.containsKey(pid) ? futureMap[pid]! : pastMap[pid]!;
      }
      if (mounted) setState(() {
        _nextDateCache..clear()..addAll(map);
        _datesLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _datesLoaded = true);
    }
  }

  int _dateToSortInt(String d) {
    if (d.isEmpty) return 999999999;
    try {
      final p = d.split('/');
      if (p.length < 3) return 999999999;
      int year = int.parse(p[2]);
      if (year > 2400) year -= 543;
      return year * 10000 + int.parse(p[1]) * 100 + int.parse(p[0]);
    } catch (_) { return 999999999; }
  }

  int get _todayInt {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  String _formatNext(String? nd, String langCode) {
    if (nd == null || nd.isEmpty) return '';
    final nInt   = _dateToSortInt(nd);
    final todayI = _todayInt;
    if (nInt < todayI)      return '⚠️ เลย $nd';
    if (nInt == todayI)     return '🔴 วันนี้';
    if (nInt == todayI + 1) return '🟠 พรุ่งนี้';
    if (nInt <= todayI + 3) return '🟡 $nd';
    return nd;
  }

  Color _nextDateColor(String? nd) {
    if (nd == null || nd.isEmpty) return kTextMuted;
    final nInt   = _dateToSortInt(nd);
    final todayI = _todayInt;
    if (nInt < todayI)      return kBed;
    if (nInt <= todayI + 1) return kBed;
    if (nInt <= todayI + 3) return kHome;
    return kPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final t        = getTranslations(locale.languageCode);
        final lang     = locale.languageCode;
        final groupAll = t['patient_list_group']!;
        if (filterGroup.isEmpty) filterGroup = groupAll;
        final groups = [
          groupAll,
          t['patient_list_group_bed']!,
          t['patient_list_group_home']!,
          t['patient_list_group_social']!,
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF0F4F2),
          body: CustomScrollView(
            slivers: [
              // Premium SliverAppBar
              SliverAppBar(
                pinned: true,
                expandedHeight: 170,
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
                      // Title shown only when expanded
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(t['patient_list_title']!,
                                style: GoogleFonts.playfairDisplay(
                                  color: kWhite, fontSize: 26,
                                  fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kWhite.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        color: kWhite, size: 16)),
                  onPressed: () => Navigator.pop(context)),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F4F2),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28))),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(children: [
                      // Search field
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: kCardShadow,
                            border: Border.all(
                                color: const Color(0xFFECF2F0))),
                          child: TextField(
                            onChanged: (v) =>
                                setState(() => search = v),
                            style: GoogleFonts.notoSansThai(
                              fontSize: 14, color: kTextHead),
                            decoration: InputDecoration(
                              hintText: t['patient_list_search'],
                              hintStyle: GoogleFonts.notoSansThai(
                                fontSize: 13, color: kTextMuted),
                              prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: 20, color: kPrimary.withOpacity(0.5)),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              filled: false),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Filter dropdown
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: kCardShadow,
                          border: Border.all(
                              color: const Color(0xFFECF2F0))),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: groups.contains(filterGroup)
                                ? filterGroup : groupAll,
                            items: groups.map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g, style: GoogleFonts.notoSansThai(
                                  fontSize: 12, color: kTextBody)))).toList(),
                            onChanged: (v) =>
                                setState(() => filterGroup = v!),
                            icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: kPrimary.withOpacity(0.6), size: 20),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

              // Column header
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: kPrimary.withOpacity(0.12))),
                  child: Row(children: [
                    SizedBox(
                      width: 38,
                      child: Text('#',
                          style: GoogleFonts.prompt(
                            fontWeight: FontWeight.w700,
                            fontSize: 12, color: kPrimary))),
                    Expanded(child: Text(t['patient_list_col_name']!,
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.w700,
                          fontSize: 12, color: kPrimary))),
                    Text('วันนัด',
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.w700,
                          fontSize: 12, color: kPrimary)),
                  ]),
                ),
              ),

              // Patient list
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('patients').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SliverToBoxAdapter(
                      child: SizedBox(height: 200,
                        child: Center(child: CircularProgressIndicator(
                            color: kPrimary))));
                  }

                  var docs = snapshot.data!.docs.where((doc) {
                    final name = doc['name'].toString().toLowerCase();
                    final matchSearch = name.contains(search.toLowerCase());
                    final isAll = filterGroup == groupAll;
                    final gv   = (doc['group'] ?? '').toString();
                    final matchGroup = isAll ||
                        (filterGroup == t['patient_list_group_bed']    && gv.contains('ติดเตียง')) ||
                        (filterGroup == t['patient_list_group_home']   && gv.contains('ติดบ้าน'))  ||
                        (filterGroup == t['patient_list_group_social'] && gv.contains('ติดสังคม'));
                    return matchSearch && matchGroup;
                  }).toList();

                  docs.sort((a, b) {
                    final da = _dateToSortInt(_nextDateCache[a.id] ?? '');
                    final db = _dateToSortInt(_nextDateCache[b.id] ?? '');
                    return da.compareTo(db);
                  });

                  if (docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: SizedBox(height: 300,
                        child: Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.06),
                                shape: BoxShape.circle),
                              child: Icon(Icons.people_outline_rounded,
                                  size: 40,
                                  color: kPrimary.withOpacity(0.3))),
                            const SizedBox(height: 16),
                            Text(t['not_found']!,
                                style: GoogleFonts.notoSansThai(
                                  color: kTextMuted, fontSize: 15)),
                          ],
                        ))));
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final doc     = docs[i];
                          final data    = doc.data() as Map<String, dynamic>;
                          final patient = Patient(
                            id              : doc.id,
                            name            : data['name']    ?? '',
                            age             : data['age']?.toString() ?? '',
                            disease         : data['disease'] ?? '',
                            gender          : data['gender']  ?? 'ชาย',
                            house           : data['house']   ?? '',
                            idCard          : data['idCard']  ?? '',
                            relative        : data['relative'] ?? '',
                            relativeRelation: data['relativeRelation'] ?? '',
                            phone           : data['phone']   ?? '',
                            group           : data['group']   ?? '1.กลุ่มติดเตียง',
                          );
                          final nextRaw     = _nextDateCache[doc.id];
                          final nextDisplay = _formatNext(nextRaw, lang);
                          final nextColor   = _nextDateColor(nextRaw);
                          final gc          = groupColor(patient.group);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PatientCard(
                              index: i + 1,
                              patient: patient,
                              nextDisplay: nextDisplay,
                              nextColor: nextColor,
                              groupColor: gc,
                              role: _role,
                              onTap: () async {
                                await Navigator.push(ctx,
                                    MaterialPageRoute(builder: (_) =>
                                        PatientDetailScreen(patient: patient)));
                                await _loadNextDates();
                              },
                              onEdit: (_role == 'register' || _role == 'admin')
                                  ? () => Navigator.push(ctx,
                                        MaterialPageRoute(builder: (_) =>
                                            EditPatientScreen(patient: patient)))
                                  : null,
                            ),
                          );
                        },
                        childCount: docs.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: (_role == 'register' || _role == 'admin')
              ? _AddPatientFAB(
                  label: t['patient_list_add_btn']!,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AddPatientScreen())),
                )
              : null,
        );
      },
    );
  }
}

// ── Premium FAB ───────────────────────────────────────────────────
class _AddPatientFAB extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _AddPatientFAB({required this.label, required this.onTap});
  @override
  State<_AddPatientFAB> createState() => _AddPatientFABState();
}

class _AddPatientFABState extends State<_AddPatientFAB> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2DD4A0), Color(0xFF1BB884)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.4),
                blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_add_rounded, color: kWhite, size: 20),
            const SizedBox(width: 8),
            Text(widget.label,
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.w700, fontSize: 14,
                  color: kWhite)),
          ]),
        ),
      ),
    );
  }
}

// ── Patient Card ──────────────────────────────────────────────────
class _PatientCard extends StatefulWidget {
  final int index;
  final Patient patient;
  final String nextDisplay;
  final Color nextColor, groupColor;
  final String role;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _PatientCard({
    required this.index, required this.patient,
    required this.nextDisplay, required this.nextColor,
    required this.groupColor, required this.role,
    required this.onTap, this.onEdit,
  });

  @override
  State<_PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<_PatientCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final gc = widget.groupColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pressed
                  ? gc.withOpacity(0.3)
                  : const Color(0xFFECF2F0)),
            boxShadow: [
              BoxShadow(
                color: _pressed
                    ? gc.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _pressed ? 12 : 8,
                offset: Offset(0, _pressed ? 3 : 2)),
            ],
          ),
          child: Row(children: [
            // Left accent strip + number
            Container(
              width: 56,
              decoration: BoxDecoration(
                color: gc.withOpacity(0.08),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20))),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${widget.index}',
                        style: GoogleFonts.playfairDisplay(
                          color: gc, fontSize: 16,
                          fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: gc.withOpacity(0.15),
                        shape: BoxShape.circle),
                      child: Icon(groupIcon(p.group),
                          size: 14, color: gc)),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: GoogleFonts.prompt(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: kTextHead)),
                    const SizedBox(height: 7),
                    Row(children: [
                      _pill('อายุ ${p.age} ปี', kPrimary,
                          const Color(0xFFE8F5F0)),
                      const SizedBox(width: 6),
                      _groupPill(p.group),
                    ]),
                    if (widget.nextDisplay.isNotEmpty) ...const [SizedBox(height: 8)],
                    if (widget.nextDisplay.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.nextColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 10, color: widget.nextColor),
                          const SizedBox(width: 4),
                          Text(widget.nextDisplay,
                              style: GoogleFonts.notoSansThai(
                                fontSize: 11,
                                color: widget.nextColor,
                                fontWeight: FontWeight.w600)),
                        ]),
                      ),
                  ],
                ),
              ),
            ),

            // Right actions
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.onEdit != null)
                  GestureDetector(
                    onTap: widget.onEdit,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.edit_outlined,
                          color: kPrimary, size: 16))),
                const SizedBox(width: 6),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F3),
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.chevron_right_rounded,
                      color: kTextMuted.withOpacity(0.6), size: 18)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Text(text,
          style: GoogleFonts.notoSansThai(
            fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _groupPill(String group) {
    final c = groupColor(group);
    String label;
    if (group.contains('ติดเตียง'))      label = 'ติดเตียง';
    else if (group.contains('ติดบ้าน')) label = 'ติดบ้าน';
    else                                  label = 'ติดสังคม';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.2))),
      child: Text(label,
          style: GoogleFonts.notoSansThai(
            fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }
}
