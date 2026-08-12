import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'rider_navigation_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
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
  static Color orangeGlow(double a) => accentB.withValues(alpha: a);
  static Color greenGlow(double a) => green.withValues(alpha: a);
}

// ─────────────────────────────────────────────────────────────────────────────
//  RIDER ORDER DETAILS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class RiderOrderDetailsScreen extends StatefulWidget {
  final String parcelId;
  final String pickupAddress;
  final String dropAddress;
  final String parcelType;
  final String parcelEmoji;
  final String weight;
  final String earnings;
  final LatLng? pickupLatLng;
  final LatLng? dropLatLng;

  const RiderOrderDetailsScreen({
    super.key,
    required this.parcelId,
    required this.pickupAddress,
    required this.dropAddress,
    required this.parcelType,
    required this.parcelEmoji,
    required this.weight,
    required this.earnings,
    this.pickupLatLng,
    this.dropLatLng,
  });

  @override
  State<RiderOrderDetailsScreen> createState() =>
      _RiderOrderDetailsScreenState();
}

class _RiderOrderDetailsScreenState extends State<RiderOrderDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 16))
      ..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.linear);

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _callSender() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(_snackBar('📞 Calling sender...'));
  }

  void _callReceiver() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(_snackBar('📞 Calling receiver...'));
  }

  void _startNavigation() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(_slideRoute(RiderNavigationScreen(
      parcelId: widget.parcelId,
      pickupAddress: widget.pickupAddress,
      dropAddress: widget.dropAddress,
      earnings: widget.earnings,
      pickupLatLng: widget.pickupLatLng,
      dropLatLng: widget.dropLatLng,
    )));
  }

  SnackBar _snackBar(String msg) {
    return SnackBar(
      content: Text(msg, style: const TextStyle(color: _C.textPrimary)),
      backgroundColor: const Color(0xFF0F1C35),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg1,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(children: [
        _buildBackground(),
        FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildHeroHeader(),
                    const SizedBox(height: 24),
                    _buildPickupCard(),
                    const SizedBox(height: 14),
                    _buildDropCard(),
                    const SizedBox(height: 14),
                    _buildParcelDetailsCard(),
                    const SizedBox(height: 14),
                    _buildEarningsCard(),
                    const SizedBox(height: 28),
                    _buildNavigationButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _C.glass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.glassBorder),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
      ),
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
              size: 260,
              color: _C.accentA.withValues(alpha: 0.07)),
          _orb(
              x: 0.80 + 0.05 * math.cos(t + 2.1),
              y: 0.35 + 0.06 * math.sin(t + 2.1),
              size: 200,
              color: _C.accentB.withValues(alpha: 0.06)),
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

  Widget _buildHeroHeader() {
    return Row(children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _C.accentA.withValues(alpha: 0.15),
          border: Border.all(color: _C.accentA.withValues(alpha: 0.3)),
        ),
        child: Center(
            child: Text(widget.parcelEmoji,
                style: const TextStyle(fontSize: 24))),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_C.textPrimary, Color(0xFF93C5FD)],
            ).createShader(b),
            child: const Text('Order Details',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 3),
          Text(widget.parcelId,
              style: const TextStyle(
                  fontSize: 13,
                  color: _C.accentA,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _C.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.green.withValues(alpha: 0.35)),
        ),
        child: const Text('Accepted',
            style: TextStyle(
                color: _C.green,
                fontSize: 11.5,
                fontWeight: FontWeight.w700)),
      ),
    ]);
  }

  Widget _buildPickupCard() {
    return _glassCard(
      accentColor: _C.accentA,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardHeader(Icons.radio_button_checked_rounded, 'Pickup Location',
            _C.accentA),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.surfaceEl,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.glassBorder),
          ),
          child: Row(children: [
            const Icon(Icons.location_on_rounded, color: _C.accentA, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.pickupAddress,
                  style: const TextStyle(
                      color: _C.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _infoTag(Icons.access_time_rounded, 'Pickup by 3:00 PM', _C.accentA),
          const Spacer(),
          GestureDetector(
            onTap: _callSender,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_C.accentA, _C.accentC]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: _C.blueGlow(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.call_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text('Call Sender',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildDropCard() {
    return _glassCard(
      accentColor: _C.accentB,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardHeader(Icons.location_on_rounded, 'Delivery Location', _C.accentB),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.surfaceEl,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.glassBorder),
          ),
          child: Row(children: [
            const Icon(Icons.location_on_rounded, color: _C.accentB, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.dropAddress,
                  style: const TextStyle(
                      color: _C.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _infoTag(Icons.schedule_rounded, 'Deliver by 6:00 PM', _C.accentB),
          const Spacer(),
          GestureDetector(
            onTap: _callReceiver,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_C.accentB, Color(0xFFEF4444)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: _C.orangeGlow(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.call_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text('Call Receiver',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildParcelDetailsCard() {
    return _glassCard(
      accentColor: _C.accentC,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardHeader(
            Icons.inventory_2_rounded, 'Parcel Details', _C.accentC),
        const SizedBox(height: 16),
        Row(children: [
          _detailChip(widget.parcelEmoji, widget.parcelType, _C.accentC),
          const SizedBox(width: 10),
          _detailChip('⚖️', widget.weight, _C.accentA),
          const SizedBox(width: 10),
          _detailChip('🔒', 'Verified', _C.green),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _C.accentC.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.accentC.withValues(alpha: 0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.sticky_note_2_outlined,
                color: _C.accentC, size: 15),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Handle with care. Do not tilt package. Keep upright.',
                style: TextStyle(
                    color: _C.textSec, fontSize: 12.5, height: 1.4),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEarningsCard() {
    return _glassCard(
      accentColor: _C.green,
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
            ),
            boxShadow: [
              BoxShadow(
                  color: _C.greenGlow(0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: const Center(
            child: Icon(Icons.currency_rupee_rounded,
                color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your Earnings',
                style: TextStyle(
                    color: _C.textSec,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
              ).createShader(b),
              child: Text(widget.earnings,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5)),
            ),
          ]),
        ),
        Column(children: [
          _miniStat('149 km', Icons.route_rounded, _C.accentA),
          const SizedBox(height: 6),
          _miniStat('~2h 30m', Icons.timer_rounded, _C.accentC),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildNavigationButton() {
    return GestureDetector(
      onTap: _startNavigation,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [_C.accentA, _C.accentB],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
                color: _C.blueGlow(0.45),
                blurRadius: 28,
                offset: const Offset(0, 8),
                spreadRadius: -2),
            BoxShadow(
                color: _C.orangeGlow(0.20),
                blurRadius: 20,
                offset: const Offset(8, 8),
                spreadRadius: -4),
          ],
        ),
        child: const Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Start Navigation',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 18),
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

  Widget _cardHeader(IconData icon, String title, Color color) {
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

  Widget _infoTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _detailChip(String emoji, String label, Color color) {
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  SLIDE ROUTE HELPER
// ─────────────────────────────────────────────────────────────────────────────
PageRouteBuilder<T> _slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position:
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
