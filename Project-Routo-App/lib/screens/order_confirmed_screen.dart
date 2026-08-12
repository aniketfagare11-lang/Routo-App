import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS — Synced with HomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg1 = Color(0xFF020617);
  static const glass = Color(0x14FFFFFF);
  static const glassBorder = Color(0x20FFFFFF);
  static const surfaceEl = Color(0xFF131F38);
  static const accentA = Color(0xFF3B82F6);
  static const accentB = Color(0xFFF97316);
  static const accentC = Color(0xFF8B5CF6);
  static const green = Color(0xFF10B981);
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSec = Color(0xFF64748B);
  static Color blueGlow(double a) => accentA.withValues(alpha: a);
  static Color greenGlow(double a) => green.withValues(alpha: a);
  static Color orangeGlow(double a) => accentB.withValues(alpha: a);
}

// ─────────────────────────────────────────────────────────────────────────────
//  ORDER CONFIRMED SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class OrderConfirmedScreen extends StatefulWidget {
  final String pickupAddress;
  final String deliveryAddress;
  final String parcelType;
  final String weight;
  final String price;
  final String date;

  const OrderConfirmedScreen({
    super.key,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.parcelType,
    required this.weight,
    required this.price,
    required this.date,
  });

  @override
  State<OrderConfirmedScreen> createState() => _OrderConfirmedScreenState();
}

class _OrderConfirmedScreenState extends State<OrderConfirmedScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _checkCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _bgAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _checkScale;
  late Animation<double> _pulseAnim;

  final String _orderId =
      'RTO${(math.Random().nextInt(900000) + 100000)}';

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 16))
      ..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.linear);

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _entryCtrl, curve: Curves.easeOutCubic));

    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _checkScale =
        CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300),
        () => _checkCtrl.forward());
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _checkCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a, b) => const HomeScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
            opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg1,
      body: Stack(children: [
        _buildBackground(),
        FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildSuccessIcon(),
                    const SizedBox(height: 28),
                    _buildTitle(),
                    const SizedBox(height: 32),
                    _buildOrderIdCard(),
                    const SizedBox(height: 16),
                    _buildRouteCard(),
                    const SizedBox(height: 16),
                    _buildParcelInfoCard(),
                    const SizedBox(height: 16),
                    _buildTimelineCard(),
                    const SizedBox(height: 36),
                    _buildHomeButton(),
                    const SizedBox(height: 14),
                    _buildTrackButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (_, __) {
        final t = _bgAnim.value * 2 * math.pi;
        return Stack(children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF020617),
                  Color(0xFF0C1220)
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          _orb(
              x: 0.15 + 0.08 * math.cos(t),
              y: 0.12 + 0.05 * math.sin(t),
              size: 280,
              color: _C.green.withValues(alpha: 0.07)),
          _orb(
              x: 0.80 + 0.05 * math.cos(t + 2.1),
              y: 0.30 + 0.06 * math.sin(t + 2.1),
              size: 220,
              color: _C.accentA.withValues(alpha: 0.06)),
          _orb(
              x: 0.5 + 0.07 * math.cos(t + 4.2),
              y: 0.70 + 0.04 * math.sin(t + 4.2),
              size: 180,
              color: _C.accentC.withValues(alpha: 0.05)),
        ]);
      },
    );
  }

  Widget _orb(
      {required double x,
      required double y,
      required double size,
      required Color color}) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment(x * 2 - 1, y * 2 - 1),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, Colors.transparent]),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return ScaleTransition(
      scale: _checkScale,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _C.green.withValues(alpha: 0.12),
            border: Border.all(
                color: _C.green.withValues(alpha: 0.35 * _pulseAnim.value),
                width: 2),
            boxShadow: [
              BoxShadow(
                  color: _C.greenGlow(0.3 * _pulseAnim.value),
                  blurRadius: 40,
                  spreadRadius: 4),
            ],
          ),
          child: Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                ),
                boxShadow: [
                  BoxShadow(
                      color: _C.greenGlow(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 38),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(children: [
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [Color(0xFFF1F5F9), Color(0xFF6EE7B7)],
        ).createShader(b),
        child: const Text(
          'Order Confirmed!',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Your parcel has been booked successfully.\nA rider will be assigned shortly.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _C.textSec,
          fontSize: 14,
          height: 1.6,
        ),
      ),
    ]);
  }

  Widget _buildOrderIdCard() {
    return _glassCard(
      accentColor: _C.green,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _C.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.green.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.confirmation_number_rounded,
              color: _C.green, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Order ID',
                style: TextStyle(
                    color: _C.textSec,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(_orderId,
                style: const TextStyle(
                    color: _C.green,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
          ]),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _orderId));
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Order ID copied!',
                    style: TextStyle(color: _C.textPrimary)),
                backgroundColor: const Color(0xFF0F1C35),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.glass,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.glassBorder),
            ),
            child: const Icon(Icons.copy_rounded,
                color: _C.textSec, size: 16),
          ),
        ),
      ]),
    );
  }

  Widget _buildRouteCard() {
    return _glassCard(
      accentColor: _C.accentA,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.route_rounded, 'Route Details', _C.accentA),
        const SizedBox(height: 16),
        _locationRow(
          icon: Icons.radio_button_checked_rounded,
          color: _C.accentA,
          label: 'PICKUP',
          address: widget.pickupAddress.isEmpty
              ? 'Pune, Maharashtra'
              : widget.pickupAddress,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Column(
            children: List.generate(
                3,
                (_) => Container(
                      width: 2,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 3),
                      decoration: BoxDecoration(
                        color: _C.textSec.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
          ),
        ),
        _locationRow(
          icon: Icons.location_on_rounded,
          color: _C.accentB,
          label: 'DELIVERY',
          address: widget.deliveryAddress.isEmpty
              ? 'Mumbai, Maharashtra'
              : widget.deliveryAddress,
        ),
      ]),
    );
  }

  Widget _locationRow({
    required IconData icon,
    required Color color,
    required String label,
    required String address,
  }) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(address,
              style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);
  }

  Widget _buildParcelInfoCard() {
    final types = ['Package', 'Fragile', 'Documents', 'Electronics', 'Other'];
    final emojis = ['📦', '🫙', '📄', '💻', '✉️'];
    final typeLabel = widget.parcelType.isNotEmpty &&
            int.tryParse(widget.parcelType) != null
        ? types[int.parse(widget.parcelType)]
        : (widget.parcelType.isNotEmpty ? widget.parcelType : 'Package');
    final emoji = widget.parcelType.isNotEmpty &&
            int.tryParse(widget.parcelType) != null
        ? emojis[int.parse(widget.parcelType)]
        : '📦';

    return _glassCard(
      accentColor: _C.accentC,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.inventory_2_rounded, 'Parcel Details', _C.accentC),
        const SizedBox(height: 16),
        Row(children: [
          _infoChip(emoji, typeLabel, _C.accentC),
          const SizedBox(width: 10),
          _infoChip('⚖️',
              widget.weight.isEmpty ? '—' : '${widget.weight} kg', _C.accentA),
          const SizedBox(width: 10),
          _infoChip('💰',
              widget.price.isEmpty ? '—' : widget.price, _C.green),
        ]),
        if (widget.date.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _C.accentA.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: _C.accentA.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_month_rounded,
                  color: _C.accentA, size: 15),
              const SizedBox(width: 8),
              Text('Pickup Date: ${widget.date}',
                  style: const TextStyle(
                      color: _C.textSec,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _infoChip(String emoji, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 5),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _buildTimelineCard() {
    return _glassCard(
      accentColor: _C.accentB,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(
            Icons.timeline_rounded, 'What Happens Next', _C.accentB),
        const SizedBox(height: 16),
        _timelineStep(
            icon: Icons.person_search_rounded,
            color: _C.green,
            title: 'Rider Assigned',
            sub: 'A nearby rider will accept your booking',
            isFirst: true),
        _timelineStep(
            icon: Icons.directions_bike_rounded,
            color: _C.accentA,
            title: 'Parcel Picked Up',
            sub: 'Rider collects parcel from your address'),
        _timelineStep(
            icon: Icons.local_shipping_rounded,
            color: _C.accentB,
            title: 'In Transit',
            sub: 'Your parcel is on the way'),
        _timelineStep(
            icon: Icons.check_circle_rounded,
            color: _C.accentC,
            title: 'Delivered',
            sub: 'Parcel delivered to recipient',
            isLast: true),
      ]),
    );
  }

  Widget _timelineStep({
    required IconData icon,
    required Color color,
    required String title,
    required String sub,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        if (!isLast)
          Container(
            width: 2,
            height: 28,
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.4), Colors.transparent]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ]),
      const SizedBox(width: 14),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub,
                style: const TextStyle(
                    color: _C.textSec,
                    fontSize: 12,
                    fontWeight: FontWeight.w400)),
            if (!isLast) const SizedBox(height: 16),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildHomeButton() {
    return GestureDetector(
      onTap: _goHome,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [_C.accentA, _C.accentB],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
                color: _C.blueGlow(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8)),
            BoxShadow(
                color: _C.orangeGlow(0.2),
                blurRadius: 20,
                offset: const Offset(8, 8)),
          ],
        ),
        child: const Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.home_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Back to Home',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3)),
          ]),
        ),
      ),
    );
  }

  Widget _buildTrackButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Live tracking coming soon! Order: $_orderId',
              style: const TextStyle(color: _C.textPrimary)),
          backgroundColor: const Color(0xFF0F1C35),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _C.glass,
          border: Border.all(color: _C.glassBorder),
        ),
        child: const Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.radar_rounded, color: _C.accentA, size: 18),
            SizedBox(width: 8),
            Text('Track Order',
                style: TextStyle(
                    color: _C.accentA,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child, required Color accentColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.glassBorder),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0.02),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 12),
      Text(title,
          style: const TextStyle(
              color: _C.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
    ]);
  }
}
