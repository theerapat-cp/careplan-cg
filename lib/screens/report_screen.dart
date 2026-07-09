import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/local_service.dart';
import '../translations/app_translations.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final t = getTranslations(locale.languageCode);
        return Scaffold(
          backgroundColor: kBg,
          body: Column(children: [
            // ── Header ─────────────────────────────────────────────
            Container(
              decoration: kHeaderGradient,
              child: SafeArea(
                bottom: false,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                    child: Row(children: [
                      IconButton(
                        icon: const Icon(
                            Icons.arrow_back_ios_rounded, color: kWhite),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          t['report_title'] ?? 'รายงานผล',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: GoogleFonts.prompt(
                            color: kWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  // Tab bar
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicator: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: kPrimary,
                      unselectedLabelColor: kWhite.withOpacity(0.8),
                      labelStyle: GoogleFonts.prompt(
                        fontSize: 13, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: GoogleFonts.prompt(
                        fontSize: 13, fontWeight: FontWeight.w500),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: '📋  รายชื่อผู้สูงอายุทั้งหมด'),
                        Tab(text: '👤  รายชื่อตามตำเเหน่งทั้งหมด'),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _PatientReportTab(),
                  _CgReportTab(),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TAB 1 — รายผู้ป่วย
// ══════════════════════════════════════════════════════════════════
class _PatientReportTab extends StatefulWidget {
  const _PatientReportTab();
  @override
  State<_PatientReportTab> createState() => _PatientReportTabState();
}

class _PatientReportTabState extends State<_PatientReportTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String search = '';
  String group  = '';
  bool isLoading = true;
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filtered = [];
  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int? _dateStrToInt(dynamic vd) {
    if (vd == null) return null;
    final s = vd.toString().trim();
    if (s.isEmpty || !s.contains('/')) return null;
    try {
      final p = s.split('/');
      if (p.length == 3) {
        int y = int.parse(p[2]);
        if (y < 2400) y += 543;
        return int.parse(p[0]) + int.parse(p[1]) * 100 + y * 10000;
      }
    } catch (_) {}
    return null;
  }

  int _dtToInt(DateTime dt) =>
      dt.day + dt.month * 100 + (dt.year + 543) * 10000;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year + 543}';
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final snap   = await FirebaseFirestore.instance
          .collection('patients').get();
      final cpSnap = await FirebaseFirestore.instance
          .collection('careplans').get();

      // ── ดึง users เพื่อแยก role cm / team ──
      final users     = await LocalService().getUsers();
      final cmNames   = users
          .where((u) => u.role == 'cm')
          .map((u) => u.name)
          .toSet();
      final teamNames = users
          .where((u) => u.role == 'team')
          .map((u) => u.name)
          .toSet();

      final fromInt = fromDate != null ? _dtToInt(fromDate!) : null;
      final toInt   = toDate   != null ? _dtToInt(toDate!)   : null;

      final result = snap.docs.map((d) {
        final cps = cpSnap.docs.where((cp) {
          if (cp['patientId'] != d.id) return false;
          if (fromInt == null && toInt == null) return true;
          final di = _dateStrToInt(cp['visitDate']);
          if (di == null) return false;
          if (fromInt != null && di < fromInt) return false;
          if (toInt   != null && di > toInt)   return false;
          return true;
        }).toList();

        // นับแยกตาม role ของ cgName
        final cgCount = cps.where((cp) {
          final n = (cp['cgName'] ?? '').toString();
          return !cmNames.contains(n) && !teamNames.contains(n);
        }).length;

        final cmCount = cps.where((cp) =>
            cmNames.contains((cp['cgName'] ?? '').toString())).length;

        final teamCount = cps.where((cp) =>
            teamNames.contains((cp['cgName'] ?? '').toString())).length;

        final total = cgCount + cmCount + teamCount;

        return {
          'id': d.id,
          ...d.data(),
          'cgCount':   cgCount,
          'cmCount':   cmCount,
          'teamCount': teamCount,
          'total':     total,
          'hasData': (fromInt == null && toInt == null) ? true : cps.isNotEmpty,
        };
      }).toList();

      if (mounted) {
        setState(() {
          patients = fromDate != null
              ? result.where((p) => p['hasData'] == true).toList()
              : result;
          filtered  = List.from(patients);
          isLoading = false;
        });
        _filter();
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filter() {
    final t        = getTranslations(languageNotifier.value.languageCode);
    final groupAll = t['report_group'] ?? 'กลุ่มผู้สูงอายุ';
    setState(() {
      filtered = patients.where((p) {
        final name       = (p['name'] ?? '').toString().toLowerCase();
        final matchSearch= search.isEmpty ||
            name.contains(search.toLowerCase());
        final isAll      = group.isEmpty || group == groupAll;
        final gv         = (p['group'] ?? '').toString();
        final matchGroup = isAll
            || (group == (t['report_group_bed']   ?? '') && gv.contains('ติดเตียง'))
            || (group == (t['report_group_home']  ?? '') && gv.contains('ติดบ้าน'))
            || (group == (t['report_group_social']?? '') && gv.contains('ติดสังคม'));
        return matchSearch && matchGroup;
      }).toList();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: fromDate != null && toDate != null
          ? DateTimeRange(start: fromDate!, end: toDate!)
          : null,
      locale: const Locale('th'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimary, onPrimary: kWhite),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      fromDate = picked.start;
      toDate   = picked.end;
      await _load();
    }
  }

  Future<void> _downloadPDF() async {
    final font     = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();
    final s  = pw.TextStyle(font: font,     fontSize: 9);
    final sb = pw.TextStyle(font: fontBold, fontSize: 9);
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Center(child: pw.Column(children: [
          pw.Text(
            'รายงานผลการให้บริการดูแลระยะยาวด้านสาธารณสุขสำหรับผู้สูงอายุ',
            style: pw.TextStyle(font: fontBold, fontSize: 13),
            textAlign: pw.TextAlign.center,
          ),
          if (fromDate != null && toDate != null)
            pw.Text(
              'ช่วงวันที่: ${_formatDate(fromDate)} - ${_formatDate(toDate)}',
              style: pw.TextStyle(font: font, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          pw.SizedBox(height: 16),
        ])),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(24),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FixedColumnWidth(38),
            3: const pw.FixedColumnWidth(32),
            4: const pw.FixedColumnWidth(32),
            5: const pw.FixedColumnWidth(46),
            6: const pw.FixedColumnWidth(36),
          },
          children: [
            pw.TableRow(
              decoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                'ลำดับ', 'ชื่อ-สกุล', 'บ้านเลขที่',
                'CG\n(ครั้ง)', 'CM\n(ครั้ง)',
                'ทีมสหสาขา\n(ครั้ง)', 'รวม\n(ครั้ง)',
              ].map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(h,
                    textAlign: pw.TextAlign.center, style: sb),
              )).toList(),
            ),
            ...filtered.asMap().entries.map((e) {
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: e.key.isEven
                      ? PdfColors.white
                      : PdfColors.grey50,
                ),
                children: [
                  _pdfCell('${e.key + 1}', s),
                  _pdfCell(e.value['name'] ?? '',  s,
                      align: pw.TextAlign.left),
                  _pdfCell(e.value['house'] ?? '', s),
                  _pdfCell('${e.value['cgCount']   ?? 0}', s),
                  _pdfCell('${e.value['cmCount']   ?? 0}', s),
                  _pdfCell('${e.value['teamCount'] ?? 0}', s), // ← แก้แล้ว
                  _pdfCell('${e.value['total']     ?? 0}', s),
                ],
              );
            }),
            pw.TableRow(
              decoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _pdfCell('', sb),
                _pdfCell('รวมทั้งหมด ${filtered.length} คน', sb,
                    align: pw.TextAlign.left),
                _pdfCell('', sb), _pdfCell('', sb),
                _pdfCell('', sb), _pdfCell('', sb), _pdfCell('', sb),
              ],
            ),
          ],
        ),
      ],
    ));
    await Printing.layoutPdf(
      onLayout: (fmt) async => pdf.save(),
      name: 'รายงานสรุปผล_careplan.pdf',
    );
  }

  pw.Widget _pdfCell(String text, pw.TextStyle style,
      {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, textAlign: align, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (ctx, locale, _) {
        final t        = getTranslations(locale.languageCode);
        final groupAll = t['report_group'] ?? 'กลุ่มผู้สูงอายุ';
        if (group.isEmpty) group = groupAll;
        final groups = [
          groupAll,
          t['report_group_bed']    ?? 'ติดเตียง',
          t['report_group_home']   ?? 'ติดบ้าน',
          t['report_group_social'] ?? 'ติดสังคม',
        ];

        return Column(children: [
          // Filter bar
          Container(
            color: kBg,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(children: [
              Row(children: [
                Expanded(child: _SearchBox(
                  hint: t['report_search'] ?? 'ค้นหา',
                  onChanged: (v) { search = v; _filter(); },
                )),
                const SizedBox(width: 8),
                _GroupDropdown(
                  groups: groups,
                  current: groups.contains(group) ? group : groupAll,
                  onChanged: (v) { group = v!; _filter(); },
                ),
              ]),
              const SizedBox(height: 8),
              _DateRangeBar(
                fromDate: fromDate,
                toDate:   toDate,
                onTap: _pickDateRange,
                onClear: () async {
                  fromDate = toDate = null;
                  await _load();
                },
              ),
              const SizedBox(height: 6),
            ]),
          ),

          // Table header
          Container(
            color: const Color(0xFFDDEDE8),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(34),
                1: FlexColumnWidth(3),
                2: FixedColumnWidth(42),
                3: FixedColumnWidth(30),
                4: FixedColumnWidth(30),
                5: FixedColumnWidth(46),
                6: FixedColumnWidth(36),
              },
              children: [
                TableRow(children: [
                  t['report_col_no']!,
                  t['report_col_name']!,
                  t['report_col_house']!,
                  t['report_col_cg']!,
                  t['report_col_cm']!,
                  t['report_col_team']!,
                  t['report_col_total']!,
                ].map((h) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 2),
                  child: Text(h,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.prompt(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      )),
                )).toList()),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimary))
                : filtered.isEmpty
                    ? _EmptyState(
                        msg: t['report_no_data'] ?? 'ไม่พบข้อมูล')
                    : ListView.builder(
                        itemCount: filtered.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == filtered.length) {
                            return _SummaryRow(
                              label:
                                  '${t['report_total']} ${filtered.length} ${t['report_total_suffix']}',
                            );
                          }
                          final p = filtered[i];
                          return Container(
                            color: i.isEven ? kCard : kBg,
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(34),
                                1: FlexColumnWidth(3),
                                2: FixedColumnWidth(42),
                                3: FixedColumnWidth(30),
                                4: FixedColumnWidth(30),
                                5: FixedColumnWidth(46),
                                6: FixedColumnWidth(36),
                              },
                              children: [
                                TableRow(children: [
                                  _TableCell(text: '${i + 1}'),
                                  _TableCell(
                                      text: p['name'] ?? '',
                                      align: TextAlign.left),
                                  _TableCell(text: p['house'] ?? ''),
                                  _TableCell(
                                      text: '${p['cgCount']   ?? 0}'),
                                  _TableCell(
                                      text: '${p['cmCount']   ?? 0}'),
                                  _TableCell(
                                      text: '${p['teamCount'] ?? 0}'), // ← แก้แล้ว
                                  _TableCell(
                                      text: '${p['total']     ?? 0}'),
                                ]),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Download button
          _DownloadBar(
            label: t['report_download'] ?? 'DOWNLOAD',
            onTap: _downloadPDF,
          ),
        ]);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TAB 2 — ราย CG / User
// ══════════════════════════════════════════════════════════════════
class _CgReportTab extends StatefulWidget {
  const _CgReportTab();
  @override
  State<_CgReportTab> createState() => _CgReportTabState();
}

class _CgReportTabState extends State<_CgReportTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool isLoading = true;

  List<AppUser>              allUsers     = [];
  List<Map<String, dynamic>> allCareplans = [];
  List<Map<String, dynamic>> allPatients  = [];

  AppUser?  selectedUser;
  DateTime? fromDate;
  DateTime? toDate;
  String    searchText = '';

  List<_CgRow>       cgRows     = [];
  List<_CgDetailRow> detailRows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year + 543}';
  }

  int? _dateStrToInt(dynamic vd) {
    if (vd == null) return null;
    final s = vd.toString().trim();
    if (!s.contains('/')) return null;
    try {
      final p = s.split('/');
      if (p.length == 3) {
        int y = int.parse(p[2]);
        if (y < 2400) y += 543;
        return int.parse(p[0]) + int.parse(p[1]) * 100 + y * 10000;
      }
    } catch (_) {}
    return null;
  }

  int _dtToInt(DateTime dt) =>
      dt.day + dt.month * 100 + (dt.year + 543) * 10000;

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      allUsers = await LocalService().getUsers();
      final ps = await FirebaseFirestore.instance
          .collection('patients').get();
      final cs = await FirebaseFirestore.instance
          .collection('careplans').get();
      allPatients  = ps.docs
          .map((d) => {'id': d.id, ...d.data()}).toList();
      allCareplans = cs.docs
          .map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {}
    if (mounted) {
      setState(() => isLoading = false);
      _compute();
    }
  }

  void _compute() {
    final fromInt =
        fromDate != null ? _dtToInt(fromDate!) : null;
    final toInt =
        toDate   != null ? _dtToInt(toDate!)   : null;

    final filteredCp = allCareplans.where((cp) {
      if (fromInt == null && toInt == null) return true;
      final di = _dateStrToInt(cp['visitDate']);
      if (di == null) return false;
      if (fromInt != null && di < fromInt) return false;
      if (toInt   != null && di > toInt)   return false;
      return true;
    }).toList();

    if (selectedUser == null) {
      cgRows = allUsers.map((u) {
        final myCp = filteredCp
            .where((cp) => (cp['cgName'] ?? '') == u.name)
            .toList();
        final patCount = myCp
            .map((cp) => cp['patientId']?.toString() ?? '')
            .toSet()
            .length;
        final visits = myCp.length;
        final hours  = myCp.fold<double>(0, (s, cp) =>
            s + (double.tryParse(
                    cp['totalHours']?.toString() ?? '') ?? 0));
        return _CgRow(
          user: u,
          visitCount:   visits,
          patientCount: patCount,
          totalHours:   hours,
        );
      }).where((r) {
        if (searchText.isEmpty) return true;
        final q = searchText.toLowerCase();
        return r.user.name.toLowerCase().contains(q) ||
            r.user.email.toLowerCase().contains(q);
      }).toList()
        ..sort((a, b) => b.visitCount.compareTo(a.visitCount));
    } else {
      final myCp = filteredCp
          .where((cp) =>
              (cp['cgName'] ?? '') == selectedUser!.name)
          .toList();

      final patMap =
          <String, List<Map<String, dynamic>>>{};
      for (final cp in myCp) {
        final pid = cp['patientId']?.toString() ?? '';
        patMap.putIfAbsent(pid, () => []).add(cp);
      }

      detailRows = patMap.entries.map((e) {
        final info = allPatients.firstWhere(
          (p) => p['id'] == e.key,
          orElse: () =>
              {'name': e.key, 'group': '', 'house': ''},
        );
        final visits = e.value.length;
        final hours  = e.value.fold<double>(0, (s, cp) =>
            s + (double.tryParse(
                    cp['totalHours']?.toString() ?? '') ?? 0));
        final lastInt = e.value.isNotEmpty
            ? e.value
                .map((cp) =>
                    _dateStrToInt(cp['visitDate']) ?? 0)
                .reduce((a, b) => a > b ? a : b)
            : 0;
        return _CgDetailRow(
          patientId:    e.key,
          patientName:  info['name'] ?? '-',
          group:        info['group'] ?? '',
          house:        info['house'] ?? '',
          visitCount:   visits,
          totalHours:   hours,
          lastVisitInt: lastInt,
          plans:        e.value,
        );
      }).where((r) {
        if (searchText.isEmpty) return true;
        return r.patientName
            .toLowerCase()
            .contains(searchText.toLowerCase());
      }).toList()
        ..sort((a, b) => b.visitCount.compareTo(a.visitCount));
    }

    setState(() {});
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: fromDate != null && toDate != null
          ? DateTimeRange(start: fromDate!, end: toDate!)
          : null,
      locale: const Locale('th'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimary, onPrimary: kWhite),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        fromDate = picked.start;
        toDate   = picked.end;
      });
      _compute();
    }
  }

  Future<void> _downloadPDF() async {
    final font     = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();
    final s  = pw.TextStyle(font: font,     fontSize: 9);
    final sb = pw.TextStyle(font: fontBold, fontSize: 9);
    final pdf = pw.Document();

    if (selectedUser == null) {
      // Summary all CG
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Center(child: pw.Text(
            'สรุปผลการให้บริการ รายบุคคล (CG)',
            style: pw.TextStyle(font: fontBold, fontSize: 13),
            textAlign: pw.TextAlign.center,
          )),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.black, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FixedColumnWidth(40),
              3: const pw.FixedColumnWidth(40),
              4: const pw.FixedColumnWidth(50),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200),
                children: [
                  'ลำดับ', 'ชื่อ CG',
                  'จำนวนผู้สูงอายุ', 'ครั้งที่เยี่ยม',
                  'ชั่วโมงรวม',
                ].map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(h,
                      textAlign: pw.TextAlign.center,
                      style: sb),
                )).toList(),
              ),
              ...cgRows.asMap().entries.map((e) {
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: e.key.isEven
                        ? PdfColors.white
                        : PdfColors.grey50,
                  ),
                  children: [
                    _pdfCell('${e.key + 1}', s),
                    _pdfCell(e.value.user.name, s,
                        align: pw.TextAlign.left),
                    _pdfCell(
                        '${e.value.patientCount}', s),
                    _pdfCell('${e.value.visitCount}', s),
                    _pdfCell(e.value.hoursDisplay, s),
                  ],
                );
              }),
            ],
          ),
        ],
      ));
    } else {
      // Detail for selected user
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Center(child: pw.Column(children: [
            pw.Text(
              'รายงานการให้บริการของ ${selectedUser!.name}',
              style: pw.TextStyle(font: fontBold, fontSize: 13),
              textAlign: pw.TextAlign.center,
            ),
            if (fromDate != null && toDate != null)
              pw.Text(
                'ช่วงวันที่: ${_formatDate(fromDate)} - ${_formatDate(toDate)}',
                style: pw.TextStyle(font: font, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            pw.SizedBox(height: 16),
          ])),
          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.black, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FixedColumnWidth(38),
              3: const pw.FixedColumnWidth(50),
              4: const pw.FixedColumnWidth(46),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200),
                children: [
                  'ลำดับ', 'ชื่อผู้สูงอายุ',
                  'ครั้งที่เยี่ยม', 'ชม.รวม',
                  'เยี่ยมล่าสุด',
                ].map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(h,
                      textAlign: pw.TextAlign.center,
                      style: sb),
                )).toList(),
              ),
              ...detailRows.asMap().entries.map((e) {
                final r = e.value;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: e.key.isEven
                        ? PdfColors.white
                        : PdfColors.grey50,
                  ),
                  children: [
                    _pdfCell('${e.key + 1}', s),
                    _pdfCell(r.patientName, s,
                        align: pw.TextAlign.left),
                    _pdfCell('${r.visitCount}', s),
                    _pdfCell(r.hoursDisplay, s),
                    _pdfCell(r.lastVisitDisplay, s),
                  ],
                );
              }),
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200),
                children: [
                  _pdfCell('', sb),
                  _pdfCell(
                      'รวม ${detailRows.length} ราย', sb,
                      align: pw.TextAlign.left),
                  _pdfCell(
                      '${detailRows.fold(0, (s, r) => s + r.visitCount)}',
                      sb),
                  _pdfCell(
                      '${detailRows.fold(0.0, (s, r) => s + r.totalHours).toStringAsFixed(1)} ชม.',
                      sb),
                  _pdfCell('', sb),
                ],
              ),
            ],
          ),
        ],
      ));
    }

    await Printing.layoutPdf(
      onLayout: (fmt) async => pdf.save(),
      name: 'รายงาน_CG_${selectedUser?.name ?? 'ทั้งหมด'}.pdf',
    );
  }

  pw.Widget _pdfCell(String text, pw.TextStyle style,
      {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, textAlign: align, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      // Filter
      Container(
        color: kBg,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Column(children: [
          Row(children: [
            Expanded(child: _UserDropdown(
              allUsers: allUsers,
              selected: selectedUser,
              onChanged: (u) {
                setState(() {
                  selectedUser = u;
                  searchText   = '';
                });
                _compute();
              },
            )),
            const SizedBox(width: 8),
            SizedBox(
              width: 130,
              child: _SearchBox(
                hint: 'ค้นหาชื่อ...',
                onChanged: (v) {
                  searchText = v;
                  _compute();
                },
              ),
            ),
          ]),
          const SizedBox(height: 8),
          _DateRangeBar(
            fromDate: fromDate,
            toDate:   toDate,
            onTap:    _pickDateRange,
            onClear: () {
              setState(() { fromDate = toDate = null; });
              _compute();
            },
          ),
          const SizedBox(height: 8),
          if (selectedUser != null) _buildSummaryChips(),
          const SizedBox(height: 4),
        ]),
      ),

      Expanded(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kPrimary))
            : selectedUser == null
                ? _buildAllCgList()
                : _buildDetailList(),
      ),

      _DownloadBar(label: 'DOWNLOAD PDF', onTap: _downloadPDF),
    ]);
  }

  Widget _buildSummaryChips() {
    final totalVisits =
        detailRows.fold(0, (s, r) => s + r.visitCount);
    final totalPat    = detailRows.length;
    final totalH =
        detailRows.fold(0.0, (s, r) => s + r.totalHours);

    return Row(children: [
      Expanded(child: _StatChip(
        icon:  Icons.people_rounded,
        value: '$totalPat',
        sub:   'ราย',
        color: kPrimary,
      )),
      const SizedBox(width: 8),
      Expanded(child: _StatChip(
        icon:  Icons.event_note_rounded,
        value: '$totalVisits',
        sub:   'ครั้งรวม',
        color: const Color(0xFF3A7D6B),
      )),
      const SizedBox(width: 8),
      Expanded(child: _StatChip(
        icon:  Icons.timelapse_rounded,
        value: '${totalH.toStringAsFixed(1)}',
        sub:   'ชม.รวม',
        color: const Color(0xFF4D6E8A),
      )),
    ]);
  }

  Widget _buildAllCgList() {
    if (cgRows.isEmpty) {
      return const _EmptyState(msg: 'ไม่พบข้อมูล CG');
    }
    return Column(children: [
      // Header
      Container(
        color: const Color(0xFFDDEDE8),
        child: Row(children: [
          _HCell(width: 38, text: ''),
          const _HCellFlex(text: 'ชื่อ CG / บทบาท'),
          _HCell(width: 52, text: 'ผู้ป่วย'),
          _HCell(width: 46, text: 'ครั้ง'),
          _HCell(width: 58, text: 'ชม.รวม'),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: ListView.separated(
          itemCount: cgRows.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFF0F4F2)),
          itemBuilder: (ctx, i) {
            final r  = cgRows[i];
            final rc = _roleColor(r.user.role);
            return InkWell(
              onTap: () {
                setState(() {
                  selectedUser = r.user;
                  searchText   = '';
                });
                _compute();
              },
              child: Container(
                color: i.isEven ? kCard : kBg,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 11),
                child: Row(children: [
                  SizedBox(
                    width: 38,
                    child: Center(
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: rc.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: GoogleFonts.prompt(
                                fontSize: 11,
                                color: rc,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(r.user.name,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kTextHead,
                            )),
                        Row(children: [
                          _RolePill(role: r.user.role),
                          const SizedBox(width: 4),
                          Text(r.user.ward,
                              style: GoogleFonts.notoSansThai(
                                fontSize: 10,
                                color: kTextMuted,
                              )),
                        ]),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Column(children: [
                      Text('${r.patientCount}',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          )),
                      Text('ราย',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 10, color: kTextMuted)),
                    ]),
                  ),
                  SizedBox(
                    width: 46,
                    child: Column(children: [
                      Text('${r.visitCount}',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3A7D6B),
                          )),
                      Text('ครั้ง',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 10, color: kTextMuted)),
                    ]),
                  ),
                  SizedBox(
                    width: 58,
                    child: Column(children: [
                      Text(r.hoursDisplay,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.prompt(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4D6E8A),
                          )),
                      Text('ชม.',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 10, color: kTextMuted)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFBBCDCA), size: 18),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildDetailList() {
    if (detailRows.isEmpty) {
      return _EmptyState(
          msg: '${selectedUser!.name}\nยังไม่มีข้อมูลการเยี่ยมในช่วงนี้');
    }
    return Column(children: [
      // Selected user banner
      Container(
        color: kPrimary.withOpacity(0.06),
        padding:
            const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: kPrimary.withOpacity(0.15),
            child: Text(
              selectedUser!.name.isNotEmpty
                  ? selectedUser!.name[0]
                  : '?',
              style: GoogleFonts.prompt(
                color: kPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selectedUser!.name,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextHead,
                    )),
                Text(selectedUser!.email,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 10, color: kTextMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => selectedUser = null);
              _compute();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: kPrimary),
            ),
          ),
        ]),
      ),

      // Table header
      Container(
        color: const Color(0xFFDDEDE8),
        child: Row(children: [
          _HCell(width: 36, text: ''),
          const _HCellFlex(text: 'ชื่อผู้สูงอายุ'),
          _HCell(width: 44, text: 'ครั้ง'),
          _HCell(width: 56, text: 'ชม.รวม'),
          _HCell(width: 80, text: 'เยี่ยมล่าสุด'),
        ]),
      ),
      const Divider(height: 1),

      Expanded(
        child: ListView.separated(
          itemCount: detailRows.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFF0F4F2)),
          itemBuilder: (ctx, i) {
            final r  = detailRows[i];
            final gc = groupColor(r.group);
            return InkWell(
              onTap: () => _showPlanDetail(ctx, r),
              child: Container(
                color: i.isEven ? kCard : kBg,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 11),
                child: Row(children: [
                  SizedBox(
                    width: 36,
                    child: Center(
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: gc.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: GoogleFonts.prompt(
                                fontSize: 10,
                                color: gc,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(r.patientName,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kTextHead,
                            )),
                        Row(children: [
                          if (r.group.isNotEmpty) ...[
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1),
                              decoration: BoxDecoration(
                                color: gc.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: Text(
                                r.group.contains('ติดเตียง')
                                    ? 'ติดเตียง'
                                    : r.group.contains('ติดบ้าน')
                                        ? 'ติดบ้าน'
                                        : 'ติดสังคม',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 10,
                                  color: gc,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (r.house.isNotEmpty)
                            Text('บ้าน ${r.house}',
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 10,
                                  color: kTextMuted,
                                )),
                        ]),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Column(children: [
                      Text('${r.visitCount}',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          )),
                      Text('ครั้ง',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 10, color: kTextMuted)),
                    ]),
                  ),
                  SizedBox(
                    width: 56,
                    child: Column(children: [
                      Text(r.hoursDisplay,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.prompt(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3A7D6B),
                          )),
                      Text('ชม.',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 10, color: kTextMuted)),
                    ]),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      r.lastVisitDisplay,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 10, color: kTextMuted),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFBBCDCA), size: 18),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  void _showPlanDetail(BuildContext ctx, _CgDetailRow r) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.6,
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE5E3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Icon(Icons.assignment_rounded,
                  color: kPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(r.patientName,
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextHead,
                    )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${r.visitCount} ครั้ง',
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      color: kPrimary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: ListView.separated(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: r.plans.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final plan = r.plans[i];
                final vd   =
                    plan['visitDate']?.toString() ?? '-';
                final st =
                    plan['startTime']?.toString() ?? '';
                final et =
                    plan['endTime']?.toString()   ?? '';
                final h = double.tryParse(
                        plan['totalHours']
                                ?.toString() ??
                            '') ??
                    0;
                final freq = plan['frequency'] ?? 1;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFE5EDEA)),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ครั้งที่ ${plan['visitCount'] ?? i + 1}',
                            style: GoogleFonts.prompt(
                              fontSize: 11,
                              color: kPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(vd,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              color: kTextMuted,
                            )),
                        const Spacer(),
                        if (h > 0)
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A7D6B)
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              h < 1
                                  ? '${(h * 60).round()} นาที'
                                  : '${h.toStringAsFixed(1)} ชม.',
                              style: GoogleFonts.prompt(
                                fontSize: 11,
                                color:
                                    const Color(0xFF3A7D6B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ]),
                      if (st.isNotEmpty ||
                          et.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: kTextMuted),
                          const SizedBox(width: 4),
                          Text('$st  →  $et',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 12,
                                color: kTextBody,
                              )),
                        ]),
                      ],
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.repeat_rounded,
                            size: 13, color: kTextMuted),
                        const SizedBox(width: 4),
                        Text(
                          'ความถี่: $freq ครั้ง/เดือน',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12, color: kTextBody),
                        ),
                      ]),
                      if ((plan['shortGoal']
                                  ?.toString() ??
                              '')
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'เป้าหมาย: ${plan['shortGoal']}',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12, color: kTextBody),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ]),
      ),
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
}

// ══════════════════════════════════════════════════════════════════
//  Data models
// ══════════════════════════════════════════════════════════════════
class _CgRow {
  final AppUser user;
  final int visitCount, patientCount;
  final double totalHours;
  _CgRow({
    required this.user,
    required this.visitCount,
    required this.patientCount,
    required this.totalHours,
  });
  String get hoursDisplay {
    if (totalHours <= 0) return '-';
    if (totalHours < 1)  return '${(totalHours * 60).round()} น.';
    return totalHours.toStringAsFixed(1);
  }
}

class _CgDetailRow {
  final String patientId, patientName, group, house;
  final int visitCount, lastVisitInt;
  final double totalHours;
  final List<Map<String, dynamic>> plans;
  _CgDetailRow({
    required this.patientId,
    required this.patientName,
    required this.group,
    required this.house,
    required this.visitCount,
    required this.totalHours,
    required this.lastVisitInt,
    required this.plans,
  });
  String get hoursDisplay {
    if (totalHours <= 0) return '-';
    if (totalHours < 1)  return '${(totalHours * 60).round()} น.';
    return totalHours.toStringAsFixed(1);
  }
  String get lastVisitDisplay {
    if (lastVisitInt == 0) return '-';
    final y = lastVisitInt ~/ 10000;
    final m = (lastVisitInt % 10000) ~/ 100;
    final d = lastVisitInt % 100;
    return '${d.toString().padLeft(2, '0')}/'
        '${m.toString().padLeft(2, '0')}/$y';
  }
}

// ══════════════════════════════════════════════════════════════════
//  Reusable small widgets
// ══════════════════════════════════════════════════════════════════
class _SearchBox extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.hint, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E5E2)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.notoSansThai(
          fontSize: 13, color: kTextHead),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.notoSansThai(
            fontSize: 13, color: kTextMuted),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: kPrimaryLight),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12),
          filled: false,
        ),
      ),
    );
  }
}

class _GroupDropdown extends StatelessWidget {
  final List<String> groups;
  final String current;
  final ValueChanged<String?> onChanged;
  const _GroupDropdown({
    required this.groups,
    required this.current,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E5E2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: groups.contains(current) ? current : groups.first,
          items: groups.map((g) {
            return DropdownMenuItem<String>(
              value: g,
              child: Text(g,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12, color: kTextBody)),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: kPrimaryLight, size: 20),
        ),
      ),
    );
  }
}

class _UserDropdown extends StatelessWidget {
  final List<AppUser> allUsers;
  final AppUser? selected;
  final ValueChanged<AppUser?> onChanged;
  const _UserDropdown({
    required this.allUsers,
    required this.selected,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E5E2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppUser?>(
          value: selected,
          isExpanded: true,
          hint: Row(children: [
            const Icon(Icons.person_search_rounded,
                size: 16, color: kPrimary),
            const SizedBox(width: 6),
            Text('ทั้งหมด (รายบุคคล)',
                style: GoogleFonts.notoSansThai(
                  fontSize: 13, color: kTextMuted)),
          ]),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: kPrimaryLight, size: 20),
          items: [
            DropdownMenuItem<AppUser?>(
              value: null,
              child: Row(children: [
                const Icon(Icons.people_rounded,
                    size: 16, color: kPrimary),
                const SizedBox(width: 6),
                Text('ทั้งหมด',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13, color: kTextBody)),
              ]),
            ),
            ...allUsers.map((u) {
              return DropdownMenuItem<AppUser?>(
                value: u,
                child: Row(children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: kPrimary.withOpacity(0.15),
                    child: Text(
                      u.name.isNotEmpty ? u.name[0] : '?',
                      style: GoogleFonts.prompt(
                        fontSize: 9,
                        color: kPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(u.name,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13, color: kTextHead),
                            overflow: TextOverflow.ellipsis),
                        Text(u.role,
                            style: GoogleFonts.notoSansThai(
                              fontSize: 10, color: kTextMuted)),
                      ],
                    ),
                  ),
                ]),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateRangeBar extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _DateRangeBar({
    required this.fromDate,
    required this.toDate,
    required this.onTap,
    required this.onClear,
  });
  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year + 543}';
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8E5E2)),
        ),
        child: Row(children: [
          const Icon(Icons.date_range_rounded,
              size: 17, color: kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fromDate != null && toDate != null
                  ? '${_fmt(fromDate)}  →  ${_fmt(toDate)}'
                  : 'เลือกช่วงวันที่',
              style: GoogleFonts.notoSansThai(
                fontSize: 12,
                color: fromDate != null
                    ? kPrimaryDark
                    : kTextMuted,
              ),
            ),
          ),
          if (fromDate != null)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  size: 16, color: kTextMuted),
            ),
        ]),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value, sub;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.value,
    required this.sub,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.prompt(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
            Text(sub,
                style: GoogleFonts.notoSansThai(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                )),
          ],
        ),
      ]),
    );
  }
}

class _HCell extends StatelessWidget {
  final double width;
  final String text;
  const _HCell({required this.width, required this.text});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 8, horizontal: 2),
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.prompt(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            )),
      ),
    );
  }
}

class _HCellFlex extends StatelessWidget {
  final String text;
  const _HCellFlex({required this.text});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 8, horizontal: 4),
        child: Text(text,
            style: GoogleFonts.prompt(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            )),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String role;
  const _RolePill({required this.role});
  Color get _color {
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
  String get _label {
    switch (role) {
      case 'admin':    return 'Admin';
      case 'staff':    return 'Staff';
      case 'cg':       return 'CG';
      case 'cm':       return 'CM';
      case 'team':     return 'สหสาขา';
      case 'register': return 'ทะเบียน';
      default:         return role;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(_label,
          style: GoogleFonts.notoSansThai(
            fontSize: 10,
            color: _color,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String msg;
  const _EmptyState({required this.msg});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: kTextMuted.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansThai(
                color: kTextMuted,
                fontSize: 14,
                height: 1.6,
              )),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  const _SummaryRow({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF2EF),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(34),
          1: FlexColumnWidth(3),
          2: FixedColumnWidth(42),
          3: FixedColumnWidth(30),
          4: FixedColumnWidth(30),
          5: FixedColumnWidth(46),
          6: FixedColumnWidth(36),
        },
        children: [
          TableRow(children: [
            const _TableCell(text: ''),
            _TableCell(text: label, bold: true, align: TextAlign.left),
            const _TableCell(text: ''),
            const _TableCell(text: ''),
            const _TableCell(text: ''),
            const _TableCell(text: ''),
            const _TableCell(text: ''),
          ]),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool bold;
  final TextAlign align;
  const _TableCell({
    required this.text,
    this.bold  = false,
    this.align = TextAlign.center,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 8, horizontal: 2),
      child: Text(text,
          textAlign: align,
          style: GoogleFonts.notoSansThai(
            fontSize: 11,
            fontWeight:
                bold ? FontWeight.w600 : FontWeight.w400,
            color: bold ? kTextHead : kTextBody,
          )),
    );
  }
}

class _DownloadBar extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DownloadBar({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
        label: Text(label,
            style: GoogleFonts.prompt(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
            )),
        onPressed: onTap,
      ),
    );
  }
}
