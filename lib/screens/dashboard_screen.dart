import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../translations/app_translations.dart';
import 'report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selected = DateTime.now();
  int totalAll = 0, totalBed = 0, totalHome = 0, totalSocial = 0;
  bool isLoading = true;
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('patients').get();
      final docs = snap.docs;
      setState(() {
        totalAll    = docs.length;
        totalBed    = docs.where((d) =>
            (d['group'] ?? '').toString().contains('ติดเตียง')).length;
        totalHome   = docs.where((d) =>
            (d['group'] ?? '').toString().contains('ติดบ้าน')).length;
        totalSocial = docs.where((d) =>
            (d['group'] ?? '').toString().contains('ติดสังคม')).length;
        isLoading = false;
      });
      _anim.forward(from: 0);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final t    = getTranslations(locale.languageCode);
        final isEn = locale.languageCode == 'en';
        return Scaffold(
          backgroundColor: const Color(0xFFF0F4F2),
          body: CustomScrollView(
            slivers: [
              // Premium SliverAppBar
              SliverAppBar(
                expandedHeight: 130,
                pinned: true,
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
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t['dashboard_title']!,
                                    style: GoogleFonts.playfairDisplay(
                                      color: kWhite, fontSize: 24,
                                      fontWeight: FontWeight.w700)),
                                Text('ภาพรวมระบบ',
                                    style: GoogleFonts.notoSansThai(
                                      color: kWhite.withOpacity(0.5),
                                      fontSize: 11)),
                              ],
                            ),
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
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kWhite.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.refresh_rounded,
                          color: kWhite, size: 18)),
                    onPressed: _load),
                  const SizedBox(width: 8),
                ],
              ),

              SliverToBoxAdapter(
                child: isLoading
                    ? const SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(color: kPrimary)))
                    : FadeTransition(
                        opacity: _fade,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          child: Column(children: [
                            _statsSection(t),
                            const SizedBox(height: 20),
                            _calendarCard(isEn),
                            const SizedBox(height: 20),
                            _reportButton(t),
                          ]),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statsSection(Map<String, String> t) {
    return Column(children: [
      // Hero total card
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D2B26), Color(0xFF1A5045)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D2B26).withOpacity(0.4),
              blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4A0).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF2DD4A0).withOpacity(0.25))),
                child: Text('ผู้สูงอายุในระบบ',
                    style: GoogleFonts.notoSansThai(
                      color: const Color(0xFF9FE1CB),
                      fontSize: 11, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 10),
              Text('$totalAll',
                  style: GoogleFonts.playfairDisplay(
                    color: kWhite, fontSize: 52,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2, height: 1)),
              const SizedBox(height: 4),
              Text(t['dash_total']!,
                  style: GoogleFonts.notoSansThai(
                    color: const Color(0xFF2DD4A0), fontSize: 12,
                    fontWeight: FontWeight.w500)),
            ],
          )),
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2DD4A0).withOpacity(0.1),
              border: Border.all(
                  color: const Color(0xFF2DD4A0).withOpacity(0.25), width: 1.5)),
            child: const Icon(Icons.people_rounded,
                color: Color(0xFF2DD4A0), size: 36)),
        ]),
      ),
      const SizedBox(height: 14),

      // 3 stat cards
      Row(children: [
        Expanded(child: _miniStat(
          t['dash_bed']!, totalBed,
          kBed, Icons.bed_rounded,
          const Color(0xFFFDF1F1), const Color(0xFFFFE4E2))),
        const SizedBox(width: 10),
        Expanded(child: _miniStat(
          t['dash_home']!, totalHome,
          kHome, Icons.home_rounded,
          const Color(0xFFFDF6EF), const Color(0xFFFFEDDA))),
        const SizedBox(width: 10),
        Expanded(child: _miniStat(
          t['dash_social']!, totalSocial,
          kSocial, Icons.people_rounded,
          const Color(0xFFEEF5FC), const Color(0xFFDAECFA))),
      ]),
    ]);
  }

  Widget _miniStat(String label, int value, Color color,
      IconData icon, Color bg, Color iconBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
        border: Border.all(color: color.withOpacity(0.1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 12),
        Text('$value',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28, fontWeight: FontWeight.w700,
              color: color, letterSpacing: -1, height: 1)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.notoSansThai(
              fontSize: 10, color: kTextMuted,
              fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _calendarCard(bool isEn) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: kCardShadow,
        border: Border.all(color: const Color(0xFFECF2F0))),
      child: Column(children: [
        // Calendar header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF0D2B26), Color(0xFF1A5045)]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Row(children: [
            _calBtn(Icons.chevron_left_rounded, () => setState(() =>
                _selected = DateTime(_selected.year, _selected.month - 1))),
            Expanded(
              child: Text(
                isEn
                    ? '${_monthEn(_selected.month)} ${_selected.year}'
                    : '${_monthThai(_selected.month)} ${_selected.year + 543}',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: kWhite, fontWeight: FontWeight.w700,
                  fontSize: 15, letterSpacing: 0.3)),
            ),
            _calBtn(Icons.chevron_right_rounded, () => setState(() =>
                _selected = DateTime(_selected.year, _selected.month + 1))),
          ]),
        ),

        // Day headers
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['MON','TUE','WED','THU','FRI','SAT','SUN']
                .map((d) => SizedBox(
                  width: 34,
                  child: Text(d,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.prompt(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: kTextMuted, letterSpacing: 0.5))))
                .toList()),
        ),
        _buildGrid(),
        const SizedBox(height: 14),
      ]),
    );
  }

  Widget _calBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: kWhite.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kWhite.withOpacity(0.1))),
        child: Icon(icon, color: kWhite, size: 22)),
    );
  }

  Widget _buildGrid() {
    final firstDay    = DateTime(_selected.year, _selected.month, 1);
    final daysInMonth = DateTime(_selected.year, _selected.month + 1, 0).day;
    final startWeekday = firstDay.weekday;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, childAspectRatio: 1),
        itemCount: startWeekday - 1 + daysInMonth,
        itemBuilder: (ctx, i) {
          if (i < startWeekday - 1) return const SizedBox();
          final day = i - (startWeekday - 1) + 1;
          final isToday = day == DateTime.now().day &&
              _selected.month == DateTime.now().month &&
              _selected.year  == DateTime.now().year;
          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: isToday
                    ? const LinearGradient(
                        colors: [Color(0xFF2DD4A0), Color(0xFF1BB884)]) : null,
                color: isToday ? null : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isToday ? [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.35),
                    blurRadius: 10, offset: const Offset(0, 3))
                ] : null,
              ),
              child: Center(child: Text('$day',
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    color: isToday ? kWhite : kTextBody,
                    fontWeight: isToday
                        ? FontWeight.w700 : FontWeight.w400))),
            ),
          );
        }),
    );
  }

  Widget _reportButton(Map<String, String> t) {
    return _ReportButton(
      label: t['dash_report_btn']!,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ReportScreen())),
    );
  }

  String _monthThai(int m) {
    const months = ['','มกราคม','กุมภาพันธ์','มีนาคม','เมษายน','พฤษภาคม',
      'มิถุนายน','กรกฎาคม','สิงหาคม','กันยายน','ตุลาคม','พฤศจิกายน','ธันวาคม'];
    return months[m];
  }
  String _monthEn(int m) {
    const months = ['','January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    return months[m];
  }
}

class _ReportButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _ReportButton({required this.label, required this.onTap});
  @override
  State<_ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<_ReportButton> {
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
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(22),
            boxShadow: kCardShadow,
            border: Border.all(
              color: _pressed
                  ? kPrimary.withOpacity(0.2)
                  : const Color(0xFFECF2F0))),
          child: Row(children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2DD4A0), Color(0xFF1BB884)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.3),
                    blurRadius: 12, offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.analytics_rounded,
                  color: kWhite, size: 26)),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label,
                    style: GoogleFonts.prompt(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: kTextHead)),
                Text('ดูรายงานสถิติทั้งหมด',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12, color: kTextMuted)),
              ],
            )),
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: kPrimary, size: 14)),
          ]),
        ),
      ),
    );
  }
}
