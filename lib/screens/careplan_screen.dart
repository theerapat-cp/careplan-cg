import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/local_service.dart';
import '../main.dart';
import '../translations/app_translations.dart';

class CarePlanScreen extends StatefulWidget {
  final Patient patient;
  final String? carePlanId;
  final Map<String, dynamic>? carePlanData;
  final bool hideVisitInfo;
  const CarePlanScreen({
    super.key,
    required this.patient,
    this.carePlanId,
    this.carePlanData,
    this.hideVisitInfo = false,
  });
  @override
  State<CarePlanScreen> createState() => _CarePlanScreenState();
}

class _CarePlanScreenState extends State<CarePlanScreen> {
  final cgNameCtrl    = TextEditingController();
  final cgPhoneCtrl   = TextEditingController();
  final shortGoalCtrl = TextEditingController();
  final longGoalCtrl  = TextEditingController();
  final activityCtrl  = TextEditingController();
  final evalCtrl      = TextEditingController();

  int visitCount = 1;
  int selectedViewPlan = 1;
  int frequencyCount = 1;

  DateTime?  visitDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  DateTime?  nextDate;
  TimeOfDay? nextTime;

  bool isLoading = true;
  bool isEditing = false;
  List<Map<String, dynamic>> allPlans = [];

  List<AppUser> _userList    = [];
  AppUser?      _selectedUser;

  String   get _role        => LocalService().currentUser?.role ?? 'staff';
  bool     get _isStaffLike =>
      _role == 'staff' || _role == 'cg' ||
      _role == 'cm'    || _role == 'team';
  AppUser? get _currentUser => LocalService().currentUser;

  // ── แก้แล้ว: รองรับข้ามคืน ──────────────────────────────────
  double get _totalHours {
    if (startTime == null || endTime == null) return 0;
    final s = startTime!.hour * 60 + startTime!.minute;
    var   e = endTime!.hour   * 60 + endTime!.minute;
    if (e <= s) e += 24 * 60; // ข้ามคืน — บวก 24 ชั่วโมง
    return (e - s) / 60.0;
  }

  String get _totalHoursDisplay {
    final h = _totalHours;
    if (h <= 0) return 'เลือกเวลาเริ่ม/สิ้นสุดก่อน';
    final hrs  = h.floor();
    final mins = ((h - hrs) * 60).round();
    if (hrs  == 0) return '$mins นาที';
    if (mins == 0) return '$hrs ชั่วโมง';
    return '$hrs ชม. $mins นาที';
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    cgNameCtrl.dispose();
    cgPhoneCtrl.dispose();
    shortGoalCtrl.dispose();
    longGoalCtrl.dispose();
    activityCtrl.dispose();
    evalCtrl.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final snap = await FirebaseFirestore.instance
        .collection('careplans')
        .where('patientId', isEqualTo: widget.patient.id)
        .get();
    allPlans = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

    if (_role == 'admin') {
      _userList = await LocalService().getUsers();
      if (_currentUser != null) {
        _selectedUser = _userList
            .where((u) => u.id == _currentUser!.id)
            .firstOrNull ??
            (_userList.isNotEmpty ? _userList.first : null);
      }
    }

    if (widget.carePlanData != null) {
      _fillData(widget.carePlanData!);
      selectedViewPlan = widget.carePlanData!['visitCount'] ?? 1;
    } else {
      visitDate      = DateTime.now();
      frequencyCount = _calcFrequency(visitDate!);
      visitCount     = allPlans.length + 1;
      _autofillCg();
    }

    setState(() => isLoading = false);
  }

  int _calcFrequency(DateTime ref) {
    int count = 0;
    for (final plan in allPlans) {
      final dt = _parseDate(plan['visitDate']?.toString() ?? '');
      if (dt != null &&
          dt.year  == ref.year &&
          dt.month == ref.month) {
        count++;
      }
    }
    return count + 1;
  }

  void _autofillCg() {
    if (_role == 'admin' && _selectedUser != null) {
      cgNameCtrl.text  = _selectedUser!.name;
      cgPhoneCtrl.text = _selectedUser!.phone;
    } else if (_currentUser != null) {
      cgNameCtrl.text  = _currentUser!.name;
      cgPhoneCtrl.text = _currentUser!.phone;
    }
  }

  void _fillData(Map<String, dynamic> cp) {
    cgNameCtrl.text    = cp['cgName']    ?? '';
    cgPhoneCtrl.text   = cp['cgPhone']   ?? '';
    shortGoalCtrl.text = cp['shortGoal'] ?? '';
    longGoalCtrl.text  = cp['longGoal']  ?? '';
    activityCtrl.text  = cp['activity']  ?? '';
    evalCtrl.text      = cp['eval']      ?? '';
    visitCount         = cp['visitCount'] ?? 1;
    frequencyCount     = cp['frequency']  ?? 1;
    visitDate          = _parseDate(cp['visitDate']);
    startTime          = _parseTime(cp['startTime']);
    endTime            = _parseTime(cp['endTime']);
    nextDate           = _parseDate(cp['nextDate']);
    nextTime           = _parseTime(cp['nextTime']);
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null || val.toString().isEmpty) return null;
    try {
      final p = val.toString().split('/');
      if (p.length == 3) {
        return DateTime(
          int.parse(p[2]) - 543,
          int.parse(p[1]),
          int.parse(p[0]),
        );
      }
    } catch (_) {}
    return null;
  }

  TimeOfDay? _parseTime(dynamic val) {
    if (val == null || val.toString().isEmpty) return null;
    try {
      final p = val.toString().split(':');
      if (p.length >= 2) {
        return TimeOfDay(
          hour:   int.parse(p[0]),
          minute: int.parse(p[1]),
        );
      }
    } catch (_) {}
    return null;
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year + 543}';
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null) return '';
    if (time == null) return _formatDate(date);
    return '${_formatDate(date)}  ${_formatTime(time)} น.';
  }

  Future<void> _pickVisitDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: visitDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('th'),
      builder: (ctx, child) => _pickerTheme(ctx, child!),
    );
    if (picked != null) {
      setState(() {
        visitDate      = picked;
        frequencyCount = _calcFrequency(picked);
      });
    }
  }

  Future<void> _pickTime(String field) async {
    final initial = field == 'start'
        ? (startTime ?? const TimeOfDay(hour: 8,  minute: 0))
        : field == 'end'
            ? (endTime  ?? const TimeOfDay(hour: 9,  minute: 0))
            : (nextTime ?? const TimeOfDay(hour: 9,  minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => _pickerTheme(ctx, child!),
    );
    if (picked != null) {
      setState(() {
        if (field == 'start')     startTime = picked;
        else if (field == 'end')  endTime   = picked;
        else                      nextTime  = picked;
      });
    }
  }

  Future<void> _pickNextDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: nextDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('th'),
      builder: (ctx, child) => _pickerTheme(ctx, child!),
    );
    if (picked != null) setState(() => nextDate = picked);
  }

  Widget _pickerTheme(BuildContext ctx, Widget child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(
          primary: kPrimary,
          onPrimary: kWhite,
          onSurface: kTextHead,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: kPrimary),
        ),
      ),
      child: child,
    );
  }

  void save(Map<String, String> t) async {
    setState(() => isLoading = true);
    try {
      final data = {
        'patientId' : widget.patient.id,
        'cgName'    : cgNameCtrl.text,
        'cgPhone'   : cgPhoneCtrl.text,
        'shortGoal' : shortGoalCtrl.text,
        'longGoal'  : longGoalCtrl.text,
        'activity'  : activityCtrl.text,
        'eval'      : evalCtrl.text,
        'visitDate' : _formatDate(visitDate),
        'startTime' : _formatTime(startTime),
        'endTime'   : _formatTime(endTime),
        'totalHours': _totalHours > 0
            ? _totalHours.toStringAsFixed(2)
            : '0',
        'nextDate'  : _formatDate(nextDate),
        'nextTime'  : _formatTime(nextTime),
        'visitCount': visitCount,
        'frequency' : frequencyCount,
        'createdAt' : FieldValue.serverTimestamp(),
      };
      if (widget.carePlanId != null) {
        await FirebaseFirestore.instance
            .collection('careplans')
            .doc(widget.carePlanId)
            .update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('careplans')
            .add(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '${t['careplan_error']}: $e',
          style: GoogleFonts.notoSansThai(color: kWhite),
        ),
        backgroundColor: kBed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final t         = getTranslations(locale.languageCode);
        final isView    = widget.carePlanData != null && !isEditing;
        final hideVisit = widget.hideVisitInfo || _role == 'register';

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            title: Text(isView
                ? t['careplan_title_view']!
                : t['careplan_title_add']!),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (isView && _role != 'register')
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: kWhite),
                  onPressed: () => setState(() => isEditing = true),
                ),
            ],
            flexibleSpace: Container(decoration: kHeaderGradient),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _patientStrip(),
                const SizedBox(height: 16),

                // ── Card 1: ฉบับที่ + วันที่ + CG ──────────────────
                if (!hideVisit)
                  _card(Column(children: [
                    _sectionTitle(
                        t['careplan_issue_no']!,
                        Icons.bookmark_outline_rounded),
                    const SizedBox(height: 12),
                    Row(children: [
                      Text(
                        '${t['careplan_issue_no']}  ',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 13, color: kTextMuted),
                      ),
                      isView ? _viewDropdown(t) : _visitBadge(visitCount),
                      const Spacer(),
                      Text(
                        '${t['careplan_visit_date']}  ',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 13, color: kTextMuted),
                      ),
                      _inlineDateChip(
                        label: _formatDate(visitDate ?? DateTime.now()),
                        hasValue: true,
                        readOnly: true,
                        onTap: _pickVisitDate,
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _cgSection(t, isView),
                  ])),

                if (hideVisit) _card(_cgSection(t, isView)),
                const SizedBox(height: 14),

                // ── Card 2: เป้าหมาย ────────────────────────────────
                _card(Column(children: [
                  _sectionTitle(
                      t['careplan_short_goal']!, Icons.flag_outlined),
                  const SizedBox(height: 8),
                  _textArea(shortGoalCtrl, isView, 4),
                  const SizedBox(height: 14),
                  _sectionTitle(
                      t['careplan_long_goal']!,
                      Icons.outlined_flag_rounded),
                  const SizedBox(height: 8),
                  _textArea(longGoalCtrl, isView, 4),
                ])),
                const SizedBox(height: 14),

                // ── Card 3: ตาราง / เวลา / นัด ──────────────────────
                _card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ความถี่
                    _sectionTitle(
                        'ความถี่ในการให้บริการ', Icons.repeat_rounded),
                    const SizedBox(height: 8),
                    _autoValueChip(
                      value: '$frequencyCount ครั้ง/เดือน',
                      subLabel: isView
                          ? null
                          : 'คำนวณอัตโนมัติตามเดือน',
                      icon: Icons.auto_fix_high_rounded,
                      color: kPrimary,
                    ),
                    const SizedBox(height: 16),

                    // เวลาเริ่ม / สิ้นสุด
                    Row(children: [
                      Expanded(child: _timeCard(
                        topLabel: t['careplan_start_date']!,
                        time: startTime,
                        readOnly: isView,
                        onTap: () => _pickTime('start'),
                      )),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('→',
                            style: GoogleFonts.prompt(
                                fontSize: 18, color: kTextMuted)),
                      ),
                      Expanded(child: _timeCard(
                        topLabel: t['careplan_end_date']!,
                        time: endTime,
                        readOnly: isView,
                        onTap: () => _pickTime('end'),
                      )),
                    ]),
                    const SizedBox(height: 12),

                    // ระยะเวลาทั้งหมด
                    _sectionTitle(
                        t['careplan_total_hours']!,
                        Icons.timelapse_rounded),
                    const SizedBox(height: 8),
                    _autoValueChip(
                      value: _totalHoursDisplay,
                      subLabel: (startTime != null && endTime != null)
                          ? '${_formatTime(startTime)}  →  ${_formatTime(endTime)}'
                          : null,
                      icon: Icons.calculate_rounded,
                      color: _totalHours > 0
                          ? const Color(0xFF3A7D6B)
                          : kTextMuted,
                    ),
                    const SizedBox(height: 16),

                    // กิจกรรม
                    _fieldLabel(t['careplan_activity']!),
                    const SizedBox(height: 6),
                    _textArea(activityCtrl, isView, 3),
                    const SizedBox(height: 12),

                    // ผลการประเมิน
                    _fieldLabel(t['careplan_eval']!),
                    const SizedBox(height: 6),
                    _textArea(evalCtrl, isView, 3),
                    const SizedBox(height: 16),

                    // วันนัดครั้งต่อไป + เวลา
                    _sectionTitle(
                        t['careplan_next_date']!,
                        Icons.event_available_rounded),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: isView ? null : _pickNextDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isView
                                  ? const Color(0xFFF4F8F7)
                                  : const Color(0xFFEAF5F1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFCCE4DE)),
                            ),
                            child: Row(children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                                color: nextDate != null
                                    ? kPrimary
                                    : kTextMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  nextDate != null
                                      ? _formatDate(nextDate)
                                      : t['careplan_pick_next']!,
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 13,
                                    color: nextDate != null
                                        ? kPrimaryDark
                                        : kTextMuted,
                                  ),
                                ),
                              ),
                              if (!isView)
                                Icon(Icons.expand_more_rounded,
                                    size: 16, color: kTextMuted),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _timeCard(
                          topLabel: 'เวลานัด',
                          time: nextTime,
                          readOnly: isView,
                          onTap: () => _pickTime('next'),
                        ),
                      ),
                    ]),

                    if (nextDate != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: kPrimary.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          const Icon(
                            Icons.notifications_active_rounded,
                            size: 16,
                            color: kPrimary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'นัดหมาย: ${_formatDateTime(nextDate, nextTime)}',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                color: kPrimaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ],
                )),

                const SizedBox(height: 24),
                if (!isView) ...[
                  ElevatedButton(
                    onPressed: () => save(t),
                    child: Text(widget.carePlanData != null
                        ? t['careplan_save_btn']!
                        : t['careplan_add_btn']!),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Patient strip ───────────────────────────────────────────────
  Widget _patientStrip() {
    final gc = groupColor(widget.patient.group);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EDEA)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: gc.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              widget.patient.name.isNotEmpty
                  ? widget.patient.name[0]
                  : '?',
              style: GoogleFonts.prompt(
                color: gc, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.patient.name,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextHead,
                  )),
              Text(widget.patient.group,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 11, color: kTextMuted)),
            ],
          ),
        ),
        Icon(groupIcon(widget.patient.group), color: gc, size: 20),
      ]),
    );
  }

  // ── CG section ─────────────────────────────────────────────────
  Widget _cgSection(Map<String, String> t, bool isView) {
    if (_role == 'admin' && !isView) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(t['careplan_cg_name']!),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCCE4DE)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppUser>(
                value: _selectedUser,
                isExpanded: true,
                hint: Text(
                  t['careplan_cg_name']!,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13, color: kTextMuted),
                ),
                items: _userList.map((u) {
                  return DropdownMenuItem<AppUser>(
                    value: u,
                    child: Text(
                      '${u.name}  (${u.role})',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13, color: kTextHead),
                    ),
                  );
                }).toList(),
                onChanged: (u) {
                  setState(() {
                    _selectedUser    = u;
                    cgNameCtrl.text  = u?.name ?? '';
                    cgPhoneCtrl.text = u?.phone ?? '';
                  });
                },
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: kPrimary, size: 22,
                ),
              ),
            ),
          ),
          if ((_selectedUser?.phone ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kPrimary.withOpacity(0.15)),
              ),
              child: Row(children: [
                const Icon(Icons.phone_outlined, size: 14, color: kPrimary),
                const SizedBox(width: 8),
                Text(_selectedUser!.phone,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13, color: kPrimaryDark,
                      fontWeight: FontWeight.w500)),
              ]),
            ),
          ],
          const SizedBox(height: 10),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(t['careplan_cg_name']!, cgNameCtrl,
            readOnly: true),
        if (cgPhoneCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kPrimary.withOpacity(0.15)),
            ),
            child: Row(children: [
              const Icon(Icons.phone_outlined, size: 14, color: kPrimary),
              const SizedBox(width: 8),
              Text(cgPhoneCtrl.text,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13, color: kPrimaryDark,
                    fontWeight: FontWeight.w500)),
            ]),
          ),
        ],
      ],
    );
  }

  // ── View dropdown ───────────────────────────────────────────────
  Widget _viewDropdown(Map<String, String> t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCCE4DE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedViewPlan,
          isDense: true,
          items: allPlans.map((p) {
            return DropdownMenuItem<int>(
              value: p['visitCount'] as int? ?? 1,
              child: Text(
                '${p['visitCount'] ?? 1}',
                style: GoogleFonts.prompt(
                  fontSize: 14,
                  color: kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              final found = allPlans.firstWhere(
                (p) => (p['visitCount'] ?? 1) == v,
                orElse: () => allPlans.first,
              );
              setState(() {
                selectedViewPlan = v;
                _fillData(found);
              });
            }
          },
        ),
      ),
    );
  }

  Widget _visitBadge(int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$n',
        style: GoogleFonts.prompt(
          fontSize: 15, fontWeight: FontWeight.w700, color: kPrimary),
      ),
    );
  }

  // ── Time card ───────────────────────────────────────────────────
  Widget _timeCard({
    required String topLabel,
    required TimeOfDay? time,
    required bool readOnly,
    required VoidCallback onTap,
  }) {
    final hasVal = time != null;
    return GestureDetector(
      onTap: readOnly ? null : onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: readOnly
              ? const Color(0xFFF4F8F7)
              : const Color(0xFFEAF5F1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCCE4DE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(topLabel,
                style: GoogleFonts.notoSansThai(
                  fontSize: 10, color: kTextMuted)),
            const SizedBox(height: 5),
            Row(children: [
              Icon(Icons.access_time_rounded,
                  size: 15,
                  color: hasVal ? kPrimary : kTextMuted),
              const SizedBox(width: 5),
              Text(
                hasVal ? _formatTime(time) : '--:--',
                style: GoogleFonts.prompt(
                  fontSize: 17,
                  fontWeight:
                      hasVal ? FontWeight.w700 : FontWeight.w400,
                  color: hasVal ? kPrimaryDark : kTextMuted,
                ),
              ),
              if (!readOnly) ...[
                const Spacer(),
                Icon(Icons.edit_rounded, size: 12, color: kTextMuted),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  Widget _inlineDateChip({
    required String label,
    required bool hasValue,
    required bool readOnly,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: readOnly ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: readOnly
              ? const Color(0xFFF4F8F7)
              : const Color(0xFFEAF5F1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCCE4DE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansThai(
                fontSize: 12,
                color: hasValue ? kPrimaryDark : kTextMuted,
              ),
            ),
            if (!readOnly) ...[
              const SizedBox(width: 4),
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: kPrimary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _autoValueChip({
    required String value,
    String? subLabel,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.prompt(
                    fontSize: 15,
                    color: color,
                    fontWeight: FontWeight.w700,
                  )),
              if (subLabel != null)
                Text(subLabel,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 11,
                      color: color.withOpacity(0.7),
                    )),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────
  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EDEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: kPrimary),
      const SizedBox(width: 6),
      Expanded(
        child: Text(title,
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kTextHead,
            )),
      ),
    ]);
  }

  Widget _fieldLabel(String label) {
    return Text(label,
        style: GoogleFonts.notoSansThai(
          fontSize: 13,
          color: kTextMuted,
          fontWeight: FontWeight.w500,
        ));
  }

  Widget _textArea(
      TextEditingController ctrl, bool readOnly, int lines) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      maxLines: lines,
      style: GoogleFonts.notoSansThai(
        fontSize: 14, color: kTextHead),
      decoration: InputDecoration(
        filled: true,
        fillColor: readOnly
            ? const Color(0xFFF4F8F7)
            : const Color(0xFFEAF5F1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCCE4DE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCCE4DE)),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _infoRow(
    String label,
    TextEditingController ctrl, {
    bool readOnly = false,
  }) {
    return Row(children: [
      SizedBox(
        width: 110,
        child: Text(label,
            style: GoogleFonts.notoSansThai(
              fontSize: 13, color: kTextMuted)),
      ),
      Expanded(
        child: TextField(
          controller: ctrl,
          readOnly: readOnly,
          style: GoogleFonts.notoSansThai(
            fontSize: 14, color: kTextHead),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 9),
            filled: true,
            fillColor: readOnly
                ? const Color(0xFFF4F8F7)
                : kCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFD8E5E2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFD8E5E2)),
            ),
          ),
        ),
      ),
    ]);
  }
}
