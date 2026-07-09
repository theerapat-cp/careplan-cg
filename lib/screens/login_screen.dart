import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/local_service.dart';
import '../translations/app_translations.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailCtrl = TextEditingController();
  final passCtrl  = TextEditingController();
  bool isLoading  = false;
  bool showPass   = false;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset>  _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void login(Map<String, String> t) async {
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      _showSnack(t['login_empty']!, kBed);
      return;
    }
    setState(() => isLoading = true);
    final user = await LocalService().login(
        emailCtrl.text.trim(), passCtrl.text);
    setState(() => isLoading = false);
    if (user != null && mounted) {
      Navigator.pushReplacement(context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => HomeScreen(user: user),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      _showSnack(t['login_error']!, kBed);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: kWhite, size: 18),
        const SizedBox(width: 10),
        Text(msg, style: GoogleFonts.notoSansThai(
            color: kWhite, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      elevation: 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        final t = getTranslations(locale.languageCode);
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFF071C18),
          body: Stack(children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF071A16),
                    Color(0xFF0E3028),
                    Color(0xFF1B5040),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Decorative orbs
            Positioned(top: -90, right: -60,
              child: Container(width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF2DD4A0).withOpacity(0.08),
                    Colors.transparent,
                  ]),
                ))),
            Positioned(top: 100, left: -50,
              child: Container(width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5C542).withOpacity(0.04)))),
            Positioned(bottom: 220, right: -30,
              child: Container(width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2DD4A0).withOpacity(0.05)))),

            // Subtle grid
            Positioned.fill(child: CustomPaint(painter: _MiniGridPainter())),

            // Content
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(children: [
                    // Top branding section
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo mark
                            Container(
                              width: 68, height: 68,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2DD4A0), Color(0xFF1BB884)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2DD4A0).withOpacity(0.4),
                                    blurRadius: 24, offset: const Offset(0, 10)),
                                  BoxShadow(
                                    color: const Color(0xFF2DD4A0).withOpacity(0.15),
                                    blurRadius: 40, offset: const Offset(0, 20)),
                                ],
                              ),
                              child: const Icon(Icons.favorite_rounded,
                                  color: kWhite, size: 34),
                            ),
                            const SizedBox(height: 28),
                            Text('Careplan CG',
                                style: GoogleFonts.playfairDisplay(
                                  color: kWhite, fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5, height: 1.1)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF2DD4A0)),
                              ),
                              const SizedBox(width: 8),
                              Text(t['app_name'] ?? 'ระบบดูแลผู้สูงอายุ',
                                  style: GoogleFonts.notoSansThai(
                                    color: kWhite.withOpacity(0.4),
                                    fontSize: 13, letterSpacing: 0.5)),
                            ]),
                          ],
                        ),
                      ),
                    ),

                    // Bottom card
                    Expanded(
                      flex: 6,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(36)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 40,
                              offset: const Offset(0, -8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Handle bar
                              Center(child: Container(
                                width: 44, height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDDE8E5),
                                  borderRadius: BorderRadius.circular(2)))),
                              const SizedBox(height: 28),

                              Text(t['login_title']!,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 26, fontWeight: FontWeight.w700,
                                    color: kTextHead, letterSpacing: -0.3)),
                              const SizedBox(height: 6),
                              Text(t['login_subtitle']!,
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 13, color: kTextMuted)),
                              const SizedBox(height: 32),

                              // Email
                              _inputLabel(t['login_email_label']!),
                              const SizedBox(height: 8),
                              _StyledTextField(
                                controller: emailCtrl,
                                hintText: t['login_email_hint'] ?? '',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 20),

                              // Password
                              _inputLabel(t['login_pass_label']!),
                              const SizedBox(height: 8),
                              _StyledTextField(
                                controller: passCtrl,
                                hintText: '••••••••',
                                obscureText: !showPass,
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    showPass
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20, color: kTextMuted),
                                  onPressed: () =>
                                      setState(() => showPass = !showPass),
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Login button
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
                                  : _LoginButton(
                                      label: t['login_btn']!,
                                      onTap: () => login(t)),

                              const SizedBox(height: 20),

                              // Footer note
                              Center(
                                child: Text(
                                  'Careplan CG  •  v1.0.0',
                                  style: GoogleFonts.prompt(
                                    fontSize: 11, color: kTextMuted,
                                    letterSpacing: 0.5),
                                ),
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
          ]),
        );
      },
    );
  }

  Widget _inputLabel(String text) => Text(text,
      style: GoogleFonts.prompt(
          fontSize: 13, fontWeight: FontWeight.w600, color: kTextBody));
}

// ── Styled Text Field ─────────────────────────────────────────────
class _StyledTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData prefixIcon;
  final Widget? suffixIcon;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  State<_StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<_StyledTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused
              ? kPrimary
              : const Color(0xFFD8E5E2),
          width: _focused ? 2 : 1,
        ),
        color: _focused
            ? kPrimary.withOpacity(0.03)
            : const Color(0xFFF4FAF8),
        boxShadow: _focused
            ? [BoxShadow(
                color: kPrimary.withOpacity(0.12),
                blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          style: GoogleFonts.notoSansThai(
              fontSize: 14, color: kTextHead),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: GoogleFonts.notoSansThai(
                fontSize: 13, color: kTextMuted),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _focused
                    ? kPrimary.withOpacity(0.15)
                    : kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8)),
              child: Icon(widget.prefixIcon,
                  size: 16, color: kPrimary),
            ),
            suffixIcon: widget.suffixIcon,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            filled: false,
          ),
        ),
      ),
    );
  }
}

// ── Login Button ──────────────────────────────────────────────────
class _LoginButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _LoginButton({required this.label, required this.onTap});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
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
              Text(widget.label,
                  style: GoogleFonts.prompt(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kWhite, letterSpacing: 0.3)),
              const SizedBox(width: 10),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: kWhite.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 16, color: kWhite),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 0.5;
    const spacing = 52.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
