import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import '../main.dart';
//import 'login_screen.dart';

// ─────────────────────────────────────────────
//  USAGE:
//  1. Place your Routo logo at assets/images/routo_logo.png
//  2. In pubspec.yaml add:
//       flutter:
//         assets:
//           - assets/images/routo_logo.png
//  3. Set SplashScreen() as your initial route.
//  4. Replace `_navigateToNext()` body with your Navigator push.
// ─────────────────────────────────────────────

// ─── Brand Colors extracted from Routo logo ───
class RoutoColors {
  static const navyDeep = Color(0xFF060E2E); // darkest navy (background edge)
  static const navyMid = Color(0xFF0A1F5C); // core background
  static const navyLight = Color(0xFF142B73); // radial center highlight
  static const orange = Color(0xFFE8500A); // primary brand orange
  static const orangeLight =
      Color(0xFFFF7A3D); // lighter orange (tagline accent)
  static const white = Color(0xFFFFFFFF);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ──
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _glowCtrl;

  // ── Animations ──
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _nameSlide; // 0→1 mapped to offset
  late final Animation<double> _nameFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _progressVal;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();

    // Logo: scale + fade in
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _logoScale = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoCtrl,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    // Text stagger: name + tagline
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _nameSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _textCtrl,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)),
    );
    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _textCtrl,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _textCtrl,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    // Progress bar
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _progressVal = CurvedAnimation(
      parent: _progressCtrl,
      curve: Curves.easeInOut,
    );

    // Glow pulse (infinite)
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _progressCtrl.forward();

    // Navigate after splash completes
    await Future.delayed(const Duration(milliseconds: 1800));
    _navigateToNext();
  }

  void _navigateToNext() {
    if (!mounted) return;
    // ── Replace with AuthWrapper to use StreamBuilder ──
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _progressCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoutoColors.navyDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Background radial gradient ──
          _buildBackground(),

          // ── 2. Subtle speed-line decoration ──
          _buildSpeedLines(),

          // ── 3. Main centered content ──
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // ── Glow bloom behind logo ──
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildGlowBloom(),
                    _buildRings(),
                    _buildLogo(),
                  ],
                ),

                const SizedBox(height: 28),

                // ── App name ──
                _buildAppName(),

                const SizedBox(height: 4),

                // ── Category subtitle ──
                _buildCategory(),

                const SizedBox(height: 20),

                // ── Orange divider with diamond ──
                _buildDivider(),

                const SizedBox(height: 16),

                // ── Tagline ──
                _buildTagline(),

                const Spacer(flex: 3),

                // ── Loading bar ──
                _buildProgressBar(),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Background ───────────────────────────────────────────────
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.15),
          radius: 1.1,
          colors: [
            RoutoColors.navyLight,
            RoutoColors.navyMid,
            RoutoColors.navyDeep,
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
    );
  }

  // ─── Speed lines ──────────────────────────────────────────────
  Widget _buildSpeedLines() {
    return Positioned.fill(
      child: CustomPaint(painter: _SpeedLinesPainter()),
    );
  }

  // ─── Glow bloom ───────────────────────────────────────────────
  Widget _buildGlowBloom() {
    return AnimatedBuilder(
      animation: _glowPulse,
      builder: (_, __) => Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              RoutoColors.orange.withValues(alpha: 0.20 * _glowPulse.value),
              RoutoColors.orange.withValues(alpha: 0.06 * _glowPulse.value),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }

  // ─── Decorative rings ─────────────────────────────────────────
  Widget _buildRings() {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(190),
          _ring(240),
        ],
      ),
    );
  }

  Widget _ring(double size) {
    return AnimatedBuilder(
      animation: _logoFade,
      builder: (_, __) => Opacity(
        opacity: _logoFade.value * 0.5,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: RoutoColors.orange.withValues(alpha: 0.12),
              width: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Logo ─────────────────────────────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoCtrl,
      builder: (_, child) => Opacity(
        opacity: _logoFade.value,
        child: Transform.scale(
          scale: _logoScale.value,
          child: child,
        ),
      ),
      child: Container(
        width: 152,
        height: 152,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: RoutoColors.orange.withValues(alpha: 0.40),
              blurRadius: 36,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: RoutoColors.navyDeep.withValues(alpha: 0.55),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/routo_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // ─── App name ─────────────────────────────────────────────────
  Widget _buildAppName() {
    return AnimatedBuilder(
      animation: _textCtrl,
      builder: (_, child) => Opacity(
        opacity: _nameFade.value,
        child: Transform.translate(
          offset: Offset(0, _nameSlide.value * 18),
          child: child,
        ),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [RoutoColors.white, Color(0xFFCCD6F6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
        child: const Text(
          'ROUTO',
          style: TextStyle(
            fontFamily:
                'Barlow', // Add Barlow to pubspec fonts, or use a system bold
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: RoutoColors.white,
            letterSpacing: 8,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  // ─── Category ─────────────────────────────────────────────────
  Widget _buildCategory() {
    return AnimatedBuilder(
      animation: _nameFade,
      builder: (_, child) => Opacity(
        opacity: _nameFade.value * 0.4,
        child: child,
      ),
      child: const Text(
        'SMART ROUTE DELIVERY',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: RoutoColors.white,
          letterSpacing: 4.5,
        ),
      ),
    );
  }

  // ─── Divider ──────────────────────────────────────────────────
  Widget _buildDivider() {
    return AnimatedBuilder(
      animation: _taglineFade,
      builder: (_, child) => Opacity(opacity: _taglineFade.value, child: child),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _divLine(),
          const SizedBox(width: 8),
          Transform.rotate(
            angle: 0.785,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: RoutoColors.orange,
                boxShadow: [
                  BoxShadow(
                    color: RoutoColors.orange.withValues(alpha: 0.7),
                    blurRadius: 6,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _divLine(),
        ],
      ),
    );
  }

  Widget _divLine() => Container(
        width: 40,
        height: 0.8,
        color: RoutoColors.orange.withValues(alpha: 0.5),
      );

  // ─── Tagline ──────────────────────────────────────────────────
  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _taglineFade,
      builder: (_, child) => Opacity(opacity: _taglineFade.value, child: child),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xB3FFFFFF), // 70% white
            letterSpacing: 0.4,
          ),
          children: [
            TextSpan(
              text: 'Move Smart. ',
              style: TextStyle(
                color: RoutoColors.orangeLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: 'Deliver Faster.'),
          ],
        ),
      ),
    );
  }

  // ─── Progress bar ─────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _progressVal,
            builder: (_, __) {
              return SizedBox(
                width: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _progressVal.value,
                    minHeight: 2,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      RoutoColors.orange,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'LOADING',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 3,
              color: Color(0x40FFFFFF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Speed lines painter ──────────────────────────────────────────
class _SpeedLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..strokeCap = StrokeCap.round;

    // Left-side speed streaks (mirroring logo motion lines)
    void streak(double y, double w, double opacity) {
      p
        ..color = const Color(0xFFE8500A).withValues(alpha: opacity)
        ..strokeWidth = 0.8;
      canvas.drawLine(Offset(0, y), Offset(w, y), p);
    }

    streak(size.height * 0.32, size.width * 0.18, 0.08);
    streak(size.height * 0.325, size.width * 0.12, 0.05);
    streak(size.height * 0.330, size.width * 0.15, 0.04);

    // Right-side symmetry
    streak(size.height * 0.60, size.width * 0.16, 0.06);
    streak(size.height * 0.606, size.width * 0.10, 0.04);

    // Subtle dot grid (top-left and bottom-right corners)
    p.style = PaintingStyle.fill;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        canvas.drawCircle(
          Offset(20.0 + c * 22, 90.0 + r * 22),
          1.0,
          p..color = Colors.white.withValues(alpha: 0.04),
        );
        canvas.drawCircle(
          Offset(size.width - 20.0 - c * 22, size.height - 90.0 - r * 22),
          1.0,
          p..color = Colors.white.withValues(alpha: 0.04),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// End of file
