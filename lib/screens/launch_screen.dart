import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../main.dart';
import '../services/local_service.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});
  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _ringCtrl;
  late Animation<double> _fade;
  late Animation<double> _slideY;
  late Animation<double> _pulse;
  late Animation<double> _shimmer;
  late Animation<double> _ringScale;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat();
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat();

    _fade = CurvedAnimation(parent: _mainCtrl, curve: Curves.easeOut);
    _slideY = Tween<double>(begin: 60, end: 0).animate(
        CurvedAnimation(parent: _mainCtrl, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));
    _ringScale = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut));

    _mainCtrl.forward();

    Future.delayed(const Duration(milliseconds: 3400), () async {
      if (!mounted) return;
      // ตรวจ session ที่เคย login ค้างไว้
      final savedUser = await LocalService().restoreSession();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => savedUser != null
              ? HomeScreen(user: savedUser)   // ข้ามหน้า login ไปเลย
              : const LoginScreen(),           // ยังไม่เคย login
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF071C18),
              Color(0xFF0D2B26),
              Color(0xFF174038),
              Color(0xFF0F2E28),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle grid
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),

            // Top-right orb
            Positioned(
              top: -100, right: -80,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 360, height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2DD4A0).withOpacity(0.06 + _pulseCtrl.value * 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom-left orb
            Positioned(
              bottom: -120, left: -80,
              child: Container(
                width: 400, height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1BB884).withOpacity(0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _mainCtrl,
                builder: (_, child) => FadeTransition(
                  opacity: _fade,
                  child: Transform.translate(
                    offset: Offset(0, _slideY.value),
                    child: child,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo with rings
                    AnimatedBuilder(
                      animation: Listenable.merge([_pulse, _ringCtrl]),
                      builder: (_, child) => Transform.scale(
                          scale: _pulse.value, child: child),
                      child: _buildLogo(),
                    ),
                    const SizedBox(height: 44),

                    // App name with shimmer
                    AnimatedBuilder(
                      animation: _shimmer,
                      builder: (_, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              kWhite.withOpacity(0.5),
                              kWhite,
                              const Color(0xFF9FE1CB),
                              kWhite,
                              kWhite.withOpacity(0.5),
                            ],
                            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                            begin: Alignment(_shimmer.value - 1, 0),
                            end: Alignment(_shimmer.value, 0),
                          ).createShader(bounds),
                          child: child!,
                        );
                      },
                      child: Text(
                        'Careplan CG',
                        style: GoogleFonts.playfairDisplay(
                          color: kWhite,
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 9),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF2DD4A0).withOpacity(0.3),
                            width: 1),
                        borderRadius: BorderRadius.circular(30),
                        color: const Color(0xFF2DD4A0).withOpacity(0.08),
                      ),
                      child: Text(
                        'ระบบดูแลผู้สูงอายุ',
                        style: GoogleFonts.notoSansThai(
                          color: const Color(0xFF9FE1CB),
                          fontSize: 14,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ELDERLY CARE MANAGEMENT SYSTEM',
                      style: GoogleFonts.prompt(
                        color: kWhite.withOpacity(0.2),
                        fontSize: 9,
                        letterSpacing: 3.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 80),
                    _buildLoadingDots(),
                  ],
                ),
              ),
            ),

            // Version
            Positioned(
              bottom: 44, left: 0, right: 0,
              child: FadeTransition(
                opacity: _fade,
                child: Column(children: [
                  Container(
                    width: 40, height: 1,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent,
                          kWhite.withOpacity(0.15), Colors.transparent]),
                    ),
                  ),
                  Text(
                    'Careplan CG  •  v1.0.0',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.prompt(
                      color: kWhite.withOpacity(0.2),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 150, height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring (animated rotation)
          AnimatedBuilder(
            animation: _ringCtrl,
            builder: (_, __) => Transform.rotate(
              angle: _ringCtrl.value * 2 * 3.1415,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.transparent,
                    width: 0,
                  ),
                  gradient: SweepGradient(
                    colors: [
                      const Color(0xFF2DD4A0).withOpacity(0.0),
                      const Color(0xFF2DD4A0).withOpacity(0.25),
                      const Color(0xFF2DD4A0).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Static rings
          Container(
            width: 144, height: 144,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF2DD4A0).withOpacity(0.12), width: 1),
            ),
          ),
          Container(
            width: 118, height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF2DD4A0).withOpacity(0.22), width: 1),
              color: kWhite.withOpacity(0.03),
            ),
          ),

          // Inner logo
          Container(
            width: 92, height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2A7C6F), Color(0xFF155048)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                  color: const Color(0xFF2DD4A0).withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2DD4A0).withOpacity(0.25),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF2A7C6F).withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(54, 54),
                painter: _ShieldHeartPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            final delay = i * 0.33;
            final value = ((_pulseCtrl.value + delay) % 1.0);
            final opacity = value < 0.5 ? value * 2 : (1.0 - value) * 2;
            final scale  = 0.7 + opacity * 0.5;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 7 * scale, height: 7 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9FE1CB)
                    .withOpacity(0.25 + opacity * 0.75),
              ),
            );
          },
        );
      }),
    );
  }
}

class _ShieldHeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;

    final shieldPath = Path();
    shieldPath.moveTo(cx, 0);
    shieldPath.lineTo(size.width, size.height * 0.22);
    shieldPath.lineTo(size.width, size.height * 0.62);
    shieldPath.quadraticBezierTo(
        size.width, size.height * 0.85, cx, size.height);
    shieldPath.quadraticBezierTo(
        0, size.height * 0.85, 0, size.height * 0.62);
    shieldPath.lineTo(0, size.height * 0.22);
    shieldPath.close();

    paint.color = kWhite.withOpacity(0.12);
    canvas.drawPath(shieldPath, paint);

    final shieldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = kWhite.withOpacity(0.45)
      ..strokeWidth = 1.2;
    canvas.drawPath(shieldPath, shieldStroke);

    final heartPath = Path();
    final hx = cx, hy = size.height * 0.55;
    final r = size.width * 0.22;
    heartPath.moveTo(hx, hy + r * 0.8);
    heartPath.cubicTo(hx, hy + r * 0.8, hx - r * 1.8, hy + r * 0.2,
        hx - r * 1.8, hy - r * 0.4);
    heartPath.arcToPoint(Offset(hx, hy - r * 0.1),
        radius: Radius.circular(r * 0.95), clockwise: true);
    heartPath.arcToPoint(Offset(hx + r * 1.8, hy - r * 0.4),
        radius: Radius.circular(r * 0.95), clockwise: true);
    heartPath.cubicTo(hx + r * 1.8, hy + r * 0.2, hx, hy + r * 0.8,
        hx, hy + r * 0.8);
    heartPath.close();
    paint.color = kWhite.withOpacity(0.95);
    canvas.drawPath(heartPath, paint);

    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF2A7C6F)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final py = hy - r * 0.1;
    final pulsePath = Path();
    pulsePath.moveTo(hx - r * 1.2, py);
    pulsePath.lineTo(hx - r * 0.6, py);
    pulsePath.lineTo(hx - r * 0.2, py - r * 0.8);
    pulsePath.lineTo(hx + r * 0.2, py + r * 0.8);
    pulsePath.lineTo(hx + r * 0.6, py);
    pulsePath.lineTo(hx + r * 1.2, py);
    canvas.drawPath(pulsePath, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.5;
    const spacing = 56.0;
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
