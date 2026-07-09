import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/launch_screen.dart';
import 'services/local_service.dart';
import 'firebase_options.dart';

// ── Premium Design System ────────────────────────────────────────
// Primary palette — Deep Forest Teal
const kPrimary      = Color(0xFF1B6B5A);
const kPrimaryDark  = Color(0xFF0E4A3C);
const kPrimaryLight = Color(0xFF2E9E84);
const kAccent       = Color(0xFF00C896);

// Gold / Premium
const kGold         = Color(0xFFD4A843);
const kGoldLight    = Color(0xFFF5D78E);

// Surfaces
const kBg           = Color(0xFFF5F7F6);
const kCard         = Color(0xFFFFFFFF);
const kCardDark     = Color(0xFF1C2B28);
const kSurface      = Color(0xFFF0F5F3);

// Text
const kTextHead     = Color(0xFF0D1F1B);
const kTextBody     = Color(0xFF2E4A44);
const kTextMuted    = Color(0xFF7A9E98);
const kWhite        = Colors.white;

// Status
const kBed          = Color(0xFFE05252);
const kHome         = Color(0xFFE8924A);
const kSocial       = Color(0xFF4A90B8);

// Gradient stops
const kGradStart    = Color(0xFF1B6B5A);
const kGradMid      = Color(0xFF2A8C74);
const kGradEnd      = Color(0xFF3DB896);

final languageNotifier = ValueNotifier<Locale>(const Locale('th', 'TH'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LocalService().forceCreateAdmin();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0E4A3C),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const CarePlanApp());
}

class CarePlanApp extends StatelessWidget {
  const CarePlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: languageNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Careplan CG',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('th', 'TH'),
            Locale('en', 'US'),
          ],
          locale: locale,
          theme: _buildTheme(),
          home: const LaunchScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimary,
        primary: kPrimary,
        secondary: kAccent,
        surface: kSurface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: kBg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.promptTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.prompt(
          fontSize: 30, fontWeight: FontWeight.w800, color: kTextHead,
          letterSpacing: -0.5),
        displayMedium: GoogleFonts.prompt(
          fontSize: 24, fontWeight: FontWeight.w700, color: kTextHead),
        titleLarge: GoogleFonts.prompt(
          fontSize: 18, fontWeight: FontWeight.w700, color: kTextHead),
        titleMedium: GoogleFonts.prompt(
          fontSize: 15, fontWeight: FontWeight.w600, color: kTextHead),
        bodyLarge: GoogleFonts.notoSansThai(
          fontSize: 15, fontWeight: FontWeight.w400, color: kTextBody,
          height: 1.6),
        bodyMedium: GoogleFonts.notoSansThai(
          fontSize: 13, fontWeight: FontWeight.w400, color: kTextBody,
          height: 1.5),
        labelSmall: GoogleFonts.notoSansThai(
          fontSize: 11, fontWeight: FontWeight.w500, color: kTextMuted,
          letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: kWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.prompt(
          color: kWhite, fontSize: 17,
          fontWeight: FontWeight.w700, letterSpacing: 0.3),
        iconTheme: const IconThemeData(color: kWhite, size: 22),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: kWhite,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.prompt(
            fontSize: 15, fontWeight: FontWeight.w700,
            letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimary,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: kPrimary, width: 1.5),
          textStyle: GoogleFonts.prompt(
            fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F8F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD0E5DF), width: 1.2)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD0E5DF), width: 1.2)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 2)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBed, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.notoSansThai(
          fontSize: 14, color: kTextMuted),
        labelStyle: GoogleFonts.notoSansThai(
          fontSize: 13, color: kTextMuted, fontWeight: FontWeight.w500),
        prefixIconColor: kPrimaryLight,
      ),
      cardTheme: CardThemeData(
        color: kCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE8EFED), width: 1)),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: kPrimary,
        foregroundColor: kWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        extendedTextStyle: GoogleFonts.prompt(
          fontSize: 14, fontWeight: FontWeight.w700),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFECF2F0),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE8F5F1),
        labelStyle: GoogleFonts.notoSansThai(
          fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
    );
  }
}

// ── Gradient decorations ──────────────────────────────────────────
BoxDecoration get kHeaderGradient => const BoxDecoration(
  gradient: LinearGradient(
    colors: [kGradStart, kGradMid, kGradEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  ),
);

BoxDecoration get kCardGradient => BoxDecoration(
  gradient: LinearGradient(
    colors: [kPrimary, kGradEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.circular(20),
);

// ── Shared shadow styles ──────────────────────────────────────────
List<BoxShadow> get kCardShadow => [
  BoxShadow(
    color: kPrimary.withOpacity(0.08),
    blurRadius: 20, offset: const Offset(0, 6)),
  BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 8, offset: const Offset(0, 2)),
];

List<BoxShadow> get kFloatShadow => [
  BoxShadow(
    color: kPrimary.withOpacity(0.25),
    blurRadius: 24, offset: const Offset(0, 8),
    spreadRadius: -2),
];

// ── Group colour helpers ──────────────────────────────────────────
Color groupColor(String group) {
  if (group.contains('ติดเตียง') || group.contains('Bedridden')) return kBed;
  if (group.contains('ติดบ้าน')  || group.contains('Homebound'))  return kHome;
  return kSocial;
}

IconData groupIcon(String group) {
  if (group.contains('ติดเตียง') || group.contains('Bedridden')) return Icons.bed_rounded;
  if (group.contains('ติดบ้าน')  || group.contains('Homebound'))  return Icons.home_rounded;
  return Icons.people_rounded;
}