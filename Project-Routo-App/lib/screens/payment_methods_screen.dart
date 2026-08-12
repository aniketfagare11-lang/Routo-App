import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg1        = Color(0xFF020617);
  static const glass      = Color(0x14FFFFFF);
  static const glassBorder= Color(0x20FFFFFF);
  static const accentA    = Color(0xFF3B82F6);
  static const accentB    = Color(0xFFF97316);
  static const accentC    = Color(0xFF8B5CF6);
  static const green      = Color(0xFF10B981);
  static const textSec    = Color(0xFF64748B);

  static Color blueGlow(double a)   => accentA.withValues(alpha: a);
  static Color purpleGlow(double a) => accentC.withValues(alpha: a);
}

// ─────────────────────────────────────────────────────────────────────────────
//  UPI BRAND COLORS
// ─────────────────────────────────────────────────────────────────────────────
class _Brand {
  static const gPay   = Color(0xFF4285F4); // Google Blue
  static const gpayY  = Color(0xFFFBBC04); // Google Yellow accent
  static const phonePe= Color(0xFF5F259F); // PhonePe Purple
  static const paytm  = Color(0xFF00BAF2); // Paytm Cyan
  static const bhim   = Color(0xFF138808); // BHIM Green
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAYMENT METHODS SCREEN — India-first UPI focus
// ─────────────────────────────────────────────────────────────────────────────
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgCtrl;
  late Animation<double>   _bgAnim;

  String? _selectedUpi;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg1,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFAB(context),
      body: Stack(children: [
        _buildBackground(),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            physics: const BouncingScrollPhysics(),
            children: [
              // ── UPI APPS ────────────────────────────────────────────────────
              _sectionHeader('PAY VIA UPI APP'),
              const SizedBox(height: 14),
              _buildUpiCard(
                name:     'Google Pay',
                tagline:  'Fast & Secure Payments',
                color:    _Brand.gPay,
                accent2:  _Brand.gpayY,
                painter:  const _GPay(),
              ),
              const SizedBox(height: 12),
              _buildUpiCard(
                name:     'PhonePe',
                tagline:  'India\'s Most Trusted UPI',
                color:    _Brand.phonePe,
                painter:  const _PhonePe(),
              ),
              const SizedBox(height: 12),
              _buildUpiCard(
                name:     'Paytm',
                tagline:  'Pay, Shop & Invest',
                color:    _Brand.paytm,
                painter:  const _Paytm(),
              ),
              const SizedBox(height: 12),
              _buildUpiCard(
                name:     'BHIM UPI',
                tagline:  'Government of India',
                color:    _Brand.bhim,
                painter:  const _BHIM(),
              ),
              const SizedBox(height: 28),

              // ── LINKED UPI IDs ──────────────────────────────────────────────
              _sectionHeader('LINKED UPI IDs'),
              const SizedBox(height: 14),
              _buildLinkedUpiTile('name@okicici', 'Google Pay',  _Brand.gPay,    const _GPay()),
              const SizedBox(height: 12),
              _buildLinkedUpiTile('name@ybl',     'PhonePe',     _Brand.phonePe, const _PhonePe()),
              const SizedBox(height: 28),

              // ── BANK ACCOUNT ────────────────────────────────────────────────
              _sectionHeader('LINKED BANK ACCOUNT'),
              const SizedBox(height: 14),
              _buildBankCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) => Text(title,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.textSec, letterSpacing: 1.5));

  // ─────────────────────────────────────────────────────────────────────────
  //  PREMIUM UPI APP CARD
  //  Layout: [Logo 48×48] | Name + Tagline | [Select button]
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildUpiCard({
    required String name,
    required String tagline,
    required Color  color,
    required CustomPainter painter,
    Color?  accent2,
  }) {
    final isSelected = _selectedUpi == name;
    final borderColor = isSelected ? color : _C.glassBorder;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedUpi = isSelected ? null : name);
        if (!isSelected) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$name selected'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 1),
          ));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isSelected
                ? [color.withValues(alpha: 0.14), color.withValues(alpha: 0.05), Colors.transparent]
                : [Colors.white.withValues(alpha: 0.04), Colors.transparent],
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 4))]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(children: [
                // ── Brand logo box ──────────────────────────────────
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.15),
                        (accent2 ?? color).withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: CustomPaint(painter: painter, size: const Size(52, 52)),
                ),
                const SizedBox(width: 16),
                // ── Name + tagline ──────────────────────────────────
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(tagline,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12, fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ])),
                const SizedBox(width: 12),
                // ── Select indicator ────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? color : _C.glassBorder,
                      width: isSelected ? 0 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : null,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  LINKED UPI TILE (existing verified IDs)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLinkedUpiTile(String upiId, String app, Color color, CustomPainter painter) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: _C.glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.glassBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: color.withValues(alpha: 0.12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: CustomPaint(painter: painter, size: const Size(44, 44)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(upiId,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(app, style: const TextStyle(color: _C.textSec, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _C.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: const Text('Active', style: TextStyle(color: _C.green, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BANK CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBankCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.accentA.withValues(alpha: 0.35)),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_C.accentA.withValues(alpha: 0.18), _C.accentC.withValues(alpha: 0.10), Colors.black26],
            ),
            boxShadow: [BoxShadow(color: _C.blueGlow(0.15), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.account_balance_rounded, color: Colors.white70, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('HDFC Bank',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _C.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Text('Primary', style: TextStyle(color: _C.green, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 20),
            // Card number with chip-style UI
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Row(children: [
                Icon(Icons.credit_card_rounded, color: Colors.white38, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text('XXXX  XXXX  XXXX  4242',
                    style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _cardLabel('ACCOUNT HOLDER', 'RAHUL SHARMA')),
              const SizedBox(width: 16),
              Expanded(child: _cardLabel('IFSC', 'HDFC0001234')),
              const SizedBox(width: 16),
              Expanded(child: _cardLabel('BRANCH', 'Andheri West')),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _cardLabel(String title, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
  ]);

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFAB(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(colors: [_C.accentA, _C.accentB]),
      boxShadow: [BoxShadow(color: _C.blueGlow(0.4), blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Add UPI / Bank account coming soon!'),
          backgroundColor: _C.accentA,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      },
      backgroundColor: Colors.transparent, elevation: 0, highlightElevation: 0,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text('Add Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
    ),
  );

  // ── App Bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
    leading: GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _C.glass, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.glassBorder)),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16))),
    title: const Text('Payment Methods', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
    actions: [
      GestureDetector(
        onTap: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
        child: Container(margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _C.glass, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.glassBorder)),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 16))),
      const SizedBox(width: 10),
    ],
  );

  // ── Background ─────────────────────────────────────────────────────────────
  Widget _buildBackground() => AnimatedBuilder(
    animation: _bgAnim,
    builder: (_, __) {
      final t = _bgAnim.value * 2 * math.pi;
      return Stack(children: [
        Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF020617), Color(0xFF0C1220)]))),
        _orb(0.12 + 0.05 * math.cos(t),       0.15 + 0.06 * math.sin(t),       280, _C.blueGlow(0.08)),
        _orb(0.85 + 0.06 * math.cos(t + 2.1), 0.42 + 0.08 * math.sin(t + 2.1), 230, _C.accentB.withValues(alpha: 0.07)),
        _orb(0.45 + 0.07 * math.cos(t + 4.2), 0.72 + 0.05 * math.sin(t + 4.2), 190, _C.purpleGlow(0.06)),
      ]);
    },
  );

  Widget _orb(double x, double y, double size, Color color) => Positioned.fill(
    child: Align(alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])))),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  BRAND LOGO PAINTERS
//  Each painter renders a clean, recognisable representation of the payment
//  brand logo entirely with Canvas — no external assets required.
// ═════════════════════════════════════════════════════════════════════════════

// ── Google Pay ────────────────────────────────────────────────────────────────
class _GPay extends CustomPainter {
  const _GPay();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.30;

    // "G" letter — multicolored segments
    final colors = [
      const Color(0xFF4285F4), // blue
      const Color(0xFF34A853), // green
      const Color(0xFFFBBC04), // yellow
      const Color(0xFFEA4335), // red
    ];
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = size.width * 0.09..strokeCap = StrokeCap.round;

    // Draw 4 colored arcs forming a "G"
    final angles = [
      [0.0, math.pi * 0.55],   // blue  top-right
      [math.pi * 0.55, math.pi * 0.55], // green bottom
      [math.pi * 1.10, math.pi * 0.55], // yellow left
      [math.pi * 1.65, math.pi * 0.55], // red  top-left
    ];
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        angles[i][0], angles[i][1], false, paint,
      );
    }

    // Horizontal stroke of the "G"
    final strokePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), Offset(cx + r, cy), strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── PhonePe ───────────────────────────────────────────────────────────────────
class _PhonePe extends CustomPainter {
  const _PhonePe();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Purple background circle
    final bgPaint = Paint()..color = _Brand.phonePe.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.40, bgPaint);

    // White "P" letterform
    final p = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path();
    final x = cx - size.width * 0.11;
    final y = cy - size.height * 0.22;
    final w = size.width * 0.10;
    final h = size.height * 0.44;
    final bw = size.width * 0.16;
    final bh = size.height * 0.20;
    // Stem
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(w / 2)));
    // Bowl
    path.addOval(Rect.fromLTWH(x + w - 1, y, bw, bh));
    canvas.drawPath(path, p);

    // White dot for PhonePe style
    final dp = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx + size.width * 0.12, cy + size.height * 0.16), size.width * 0.06, dp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Paytm ─────────────────────────────────────────────────────────────────────
class _Paytm extends CustomPainter {
  const _Paytm();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Two-tone background pill (Paytm style)
    final blueP = Paint()..color = const Color(0xFF00BAF2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, size.height * 0.2, size.width, size.height * 0.6), Radius.circular(size.width * 0.15)),
      blueP,
    );

    // "P" letter in white
    final tp = TextPainter(
      text: const TextSpan(
        text: 'P',
        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'sans-serif'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    // "aytm" small text below — simplified as a blue bar
    final barP = Paint()..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.2, size.height * 0.70, size.width * 0.6, size.height * 0.07), const Radius.circular(4)),
      barP,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── BHIM ─────────────────────────────────────────────────────────────────────
class _BHIM extends CustomPainter {
  const _BHIM();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Tricolor wheel — India flag colors
    final green = Paint()..color = const Color(0xFF138808);
    final white = Paint()..color = Colors.white;
    final saffron = Paint()..color = const Color(0xFFFF9933);
    final navy = Paint()..color = const Color(0xFF000080);

    // Three arcs
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.36),
        -math.pi / 2, 2 * math.pi / 3, true, saffron);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.36),
        -math.pi / 2 + 2 * math.pi / 3, 2 * math.pi / 3, true, white);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.36),
        -math.pi / 2 + 4 * math.pi / 3, 2 * math.pi / 3, true, green);

    // Ashoka chakra (navy circle)
    canvas.drawCircle(Offset(cx, cy), size.width * 0.14, navy);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.08, white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
