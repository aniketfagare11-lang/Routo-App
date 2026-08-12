// ═══════════════════════════════════════════════════════════════════════════
//  home_screen.dart  —  ROUTO  •  Ultra-Premium Dark Theme
//  Dependencies to add in pubspec.yaml:
//    shimmer: ^3.0.0
//    lottie: ^3.1.0       (place a Lottie JSON in assets/animations/delivery.json)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

import 'add_parcel_screen.dart';
import 'parcel_details_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'rider_route_selection_screen.dart';
import 'rider_available_parcels_screen.dart';
import '../widgets/ai_chatbot_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  // Background
  static const bg0 = Color(0xFF0F172A);
  static const bg1 = Color(0xFF020617);

  // Surface / glass
  static const glass = Color(0x14FFFFFF); // white 8%
  static const glassBorder = Color(0x20FFFFFF); // white 12%
  static const surface = Color(0xFF0F1C35);
  static const surfaceEl = Color(0xFF131F38);

  // Accent gradient  (blue → orange — same brand identity)
  static const accentA = Color(0xFF3B82F6);
  static const accentB = Color(0xFFF97316);
  static const accentC = Color(0xFF8B5CF6);

  // Status
  static const green = Color(0xFF10B981);
  static const greenBg = Color(0x1A10B981);
  static const orange = Color(0xFFF97316);
  static const orangeBg = Color(0x1AF97316);
  static const blue = Color(0xFF3B82F6);
  static const blueBg = Color(0x1A3B82F6);

  // Text
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSec = Color(0xFF64748B);
  static const textMuted = Color(0xFF334155);

  // Glow alphas
  static Color blueGlow(double a) => accentA.withValues(alpha: a);
  static Color orangeGlow(double a) => accentB.withValues(alpha: a);
  static Color purpleGlow(double a) => accentC.withValues(alpha: a);
}

const _kRadius = 24.0;
const _kCardRadius = 20.0;

// ─────────────────────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────────
  int _currentIndex = 0;
  bool _isSearching = false;
  bool _showResults = false;
  bool _isLoadingActivity = true;
  bool _isOnline = true; // Online/Offline toggle
  String _userName = 'User'; // populated from Firebase in initState

  final TextEditingController _fromController =
      TextEditingController(text: 'Pune, Maharashtra');
  final TextEditingController _toController =
      TextEditingController(text: 'Mumbai, Maharashtra');

  // ── Animation controllers ────────────────────────────────────────────────
  late AnimationController _masterCtrl; // staggered page-load
  late AnimationController _pulseCtrl; // logo glow pulse
  late AnimationController _bgOrbitCtrl; // floating orbs
  late AnimationController _tabCtrl; // bottom nav pill

  // Derived animations
  late Animation<double> _masterFade;
  late Animation<Offset> _headerSlide;
  late Animation<Offset> _bodySlide;
  late Animation<double> _pulseAnim;
  late Animation<double> _bgOrbitAnim;

  @override
  void initState() {
    super.initState();

    // Master stagger
    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _masterFade = CurvedAnimation(parent: _masterCtrl, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero)
            .animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    ));
    _bodySlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    // Pulse (logo glow)
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Background orbiting orbs
    _bgOrbitCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat();
    _bgOrbitAnim = CurvedAnimation(parent: _bgOrbitCtrl, curve: Curves.linear);

    // Tab pill
    _tabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));

    _masterCtrl.forward();
    _loadUserName();

    // Simulate activity load
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _isLoadingActivity = false);
    });
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _pulseCtrl.dispose();
    _bgOrbitCtrl.dispose();
    _tabCtrl.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  // ── Firebase: resolve display name ───────────────────────────────────────
  void _loadUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String name;
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      // Use the first word of the display name (e.g. "Aniket Fagare" → "Aniket")
      name = user.displayName!.trim().split(' ').first;
    } else if (user.email != null && user.email!.isNotEmpty) {
      // Extract part before '@' and capitalize first letter
      final raw = user.email!.split('@').first;
      // Remove digits/special chars at end (e.g. "aniketfagare11" → "aniketfagare")
      final letters = raw.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      name = letters.isNotEmpty
          ? '${letters[0].toUpperCase()}${letters.substring(1).toLowerCase()}'
          : 'User';
    } else {
      name = 'User';
    }

    if (mounted) setState(() => _userName = name);
  }

  // ── Handlers ─────────────────────────────────────────────────────────────
  void _handleSwap() {
    setState(() {
      final t = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = t;
      _showResults = false;
    });
  }

  Future<void> _handleSearch() async {
    if (_fromController.text.trim().isEmpty ||
        _toController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both locations')));
      return;
    }
    setState(() {
      _isSearching = true;
      _showResults = false;
    });
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) {
      setState(() {
        _isSearching = false;
        _showResults = true;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg1,
      extendBody: true,
      body: FadeTransition(
        opacity: _masterFade,
        child: Stack(
          children: [
            // ── Animated deep-space background ──
            IgnorePointer(child: _buildAnimatedBackground()),
            // ── Main scrollable content ──
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SlideTransition(
                        position: _bodySlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            // 1. Main action cards
                            _buildWhatSection(),
                            const SizedBox(height: 28),

                            // 2. Recommended Route
                            _buildSectionLabel('Recommended Route'),
                            const SizedBox(height: 12),
                            _buildRecommendedRouteCard(),
                            const SizedBox(height: 28),

                            // 3. Today's Opportunities
                            _buildSectionLabel("Today's Opportunities"),
                            const SizedBox(height: 12),
                            _buildOpportunitiesCard(),
                            const SizedBox(height: 28),

                            // 4. Your Deliveries
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionLabel('Your Deliveries'),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _currentIndex = 1);
                                    Navigator.of(context).push(
                                        _slideRoute(const HistoryScreen()));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _C.blueBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: _C.blueGlow(0.3), width: 1),
                                    ),
                                    child: const Text('View All',
                                        style: TextStyle(
                                            color: _C.accentA,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDeliveries(),
                            const SizedBox(height: 28),

                            // 5. My Activity mini cards
                            _buildSectionLabel('My Activity'),
                            const SizedBox(height: 12),
                            _buildActivityMiniCards(),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            const AiChatbotWidget(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ANIMATED BACKGROUND — floating glowing orbs
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgOrbitAnim,
      builder: (_, __) {
        final t = _bgOrbitAnim.value * 2 * math.pi;
        return Stack(children: [
          // Deep gradient base
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
          // Orb 1 — blue
          _orb(
            x: 0.15 + 0.08 * math.cos(t),
            y: 0.12 + 0.05 * math.sin(t),
            size: 280,
            color: _C.accentA.withValues(alpha: 0.08),
          ),
          // Orb 2 — orange
          _orb(
            x: 0.75 + 0.06 * math.cos(t + 2.1),
            y: 0.35 + 0.06 * math.sin(t + 2.1),
            size: 220,
            color: _C.accentB.withValues(alpha: 0.07),
          ),
          // Orb 3 — purple
          _orb(
            x: 0.5 + 0.07 * math.cos(t + 4.2),
            y: 0.72 + 0.04 * math.sin(t + 4.2),
            size: 180,
            color: _C.accentC.withValues(alpha: 0.06),
          ),
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

  // ─────────────────────────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SlideTransition(
      position: _headerSlide,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F1C35), Color(0xFF07101E)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Stack(children: [
              // Noise grid overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(36)),
                  child: CustomPaint(painter: _GridPainter()),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 28),
                      _buildGreeting(),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo
        Row(children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_C.accentA, _C.accentB],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.blueGlow(_pulseAnim.value * 0.5),
                    blurRadius: 20 * _pulseAnim.value,
                    spreadRadius: 2 * _pulseAnim.value,
                  ),
                ],
              ),
              child: const Center(
                child: Text('R',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    )),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFF1F5F9), _C.accentB],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(b),
            child: const Text('ROUTO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 5,
                )),
          ),
        ]),
        // Action bar — profile avatar moved to bottom nav
        Row(children: [
          _buildOnlineToggle(),
          const SizedBox(width: 10),
          _buildNotificationBadge(),
        ]),
      ],
    );
  }

  Widget _buildNotificationBadge() {
    return Stack(clipBehavior: Clip.none, children: [
      _glassButton(const Icon(Icons.notifications_outlined,
          color: Colors.white, size: 20)),
      Positioned(
        top: -2,
        right: -2,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _C.accentB,
            border: Border.all(color: _C.bg0, width: 2),
            boxShadow: [BoxShadow(color: _C.orangeGlow(0.6), blurRadius: 6)],
          ),
          child: const Center(
            child: Text('3',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    ]);
  }

  Widget _glassButton(Widget child) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _C.glass,
            border: Border.all(color: _C.glassBorder, width: 1),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildAvatarButton() {
    return GestureDetector(
      onTap: () =>
          Navigator.of(context).push(_slideRoute(const ProfileScreen())),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [_C.accentA, _C.accentC]),
          border: Border.all(color: _C.glassBorder, width: 2),
          boxShadow: [BoxShadow(color: _C.blueGlow(0.4), blurRadius: 12)],
        ),
        child: const Center(
          child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildOnlineToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isOnline = !_isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _isOnline
              ? _C.green.withValues(alpha: 0.15)
              : _C.textMuted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isOnline ? _C.green.withValues(alpha: 0.4) : _C.glassBorder,
            width: 1,
          ),
          boxShadow: _isOnline
              ? [
                  BoxShadow(
                      color: _C.green.withValues(alpha: 0.25), blurRadius: 8)
                ]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isOnline ? _C.green : _C.textSec,
              boxShadow: _isOnline
                  ? [
                      BoxShadow(
                          color: _C.green.withValues(alpha: 0.6), blurRadius: 5)
                    ]
                  : [],
            ),
          ),
          const SizedBox(width: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: _isOnline ? _C.green : _C.textSec,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            child: Text(_isOnline ? 'Online' : 'Offline'),
          ),
        ]),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final String timeGreeting;
    final String timeEmoji;

    if (hour < 12) {
      timeGreeting = 'Good morning';
      timeEmoji = '☀️';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
      timeEmoji = '🌤️';
    } else {
      timeGreeting = 'Good evening';
      timeEmoji = '🌙';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lottie Delivery Animation — error-guarded so a missing/corrupt asset
        // never crashes the home screen.
        SizedBox(
          width: 140,
          height: 100,
          child: Lottie.asset(
            'assets/animations/delivery.json',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 8),
        // Dynamic greeting pill
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _C.glass,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: _C.glassBorder, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeEmoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$timeGreeting, $_userName 👋',
                      style: const TextStyle(
                        color: _C.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        // Heading
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFF1F5F9), Color(0xFF93C5FD), _C.accentB],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'What would you\nlike to do today?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Send or deliver parcels with Routo.',
          style: TextStyle(
            fontSize: 14.5,
            color: _C.textSec,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(children: [
      Expanded(child: _buildStatChip('📦', '5', 'Parcels')),
      const SizedBox(width: 10),
      Expanded(child: _buildStatChip('₹', '360', 'Earnings')),
      const SizedBox(width: 10),
      Expanded(child: _buildStatChip('⭐', '4.9', 'Rating')),
    ]);
  }

  Widget _buildStatChip(String emoji, String val, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          decoration: BoxDecoration(
            color: _C.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.glassBorder, width: 0.8),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(val,
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                  color: _C.textSec,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                )),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  WHAT DO YOU WANT TO DO — premium action cards
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWhatSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionLabel('Choose your action'),
      const SizedBox(height: 4),
      const Text(
        'Send or deliver parcels with Routo',
        style: TextStyle(
            fontSize: 13, color: _C.textSec, fontWeight: FontWeight.w400),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: _PremiumActionCard(
            emoji: '📤',
            title: 'Send\nParcel',
            subtitle: 'Book a delivery',
            gradientColors: const [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
            glowColor: _C.accentA,
            onTap: () => Navigator.of(context).push(
              _slideRoute(const AddParcelScreen()),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _PremiumActionCard(
            emoji: '🚚',
            title: 'Deliver\nParcel',
            subtitle: 'Earn on your route',
            gradientColors: const [Color(0xFFF97316), Color(0xFFEF4444)],
            glowColor: _C.accentB,
            onTap: () => Navigator.of(context).push(
              _slideRoute(const RiderRouteSelectionScreen()),
            ),
          ),
        ),
      ]),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ROUTE CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRouteCard() {
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _iconBox(Icons.map_outlined, _C.accentA, _C.blueBg),
          const SizedBox(width: 12),
          const Text('Select Route',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary)),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: _buildLocationField(
              controller: _fromController,
              label: 'From',
              dot: _C.accentA,
            ),
          ),
          const SizedBox(width: 12),
          _buildSwapBtn(),
        ]),
        const SizedBox(height: 12),
        _buildLocationField(
          controller: _toController,
          label: 'To',
          dot: _C.accentB,
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          text: 'Find Available Parcels',
          icon: Icons.search_rounded,
          isLoading: _isSearching,
          onTap: _handleSearch,
          gradientColors: const [_C.accentA, _C.accentB],
          shadowColor: _C.accentA,
        ),
      ]),
    );
  }

  Widget _buildSwapBtn() {
    return GestureDetector(
      onTap: _handleSwap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _C.blueBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.blueGlow(0.3), width: 1),
            ),
            child: const Icon(Icons.swap_vert_rounded,
                color: _C.accentA, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required Color dot,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _C.surfaceEl,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.glassBorder, width: 1.2),
      ),
      child: Row(children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dot.withValues(alpha: 0.25),
            border: Border.all(color: dot, width: 2.5),
            boxShadow: [
              BoxShadow(color: dot.withValues(alpha: 0.4), blurRadius: 6)
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(
                    color: _C.textSec,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  )),
              const SizedBox(height: 2),
              TextField(
                controller: controller,
                onChanged: (_) {
                  if (_showResults) setState(() => _showResults = false);
                },
                style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  RESULTS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildResultsCard() {
    return _GlassCard(
      glowColor: _C.green,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          _iconBox(Icons.inventory_2_outlined, _C.green, _C.greenBg),
          const SizedBox(width: 12),
          const Text('Route Results',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary)),
          const Spacer(),
          // Animated success badge
          const _AnimatedPill(label: 'Route Found!', color: _C.green),
        ]),
        const SizedBox(height: 16),
        // Route path indicator
        _buildRoutePath(),
        const SizedBox(height: 14),
        _buildParcelInfoBox(),
        const SizedBox(height: 12),
        _buildEarningsBox(),
        const SizedBox(height: 20),
        _PrimaryButton(
          text: 'Accept & View Details',
          icon: Icons.inventory_rounded,
          gradientColors: const [_C.accentA, _C.accentB],
          shadowColor: _C.accentA,
          onTap: () => Navigator.of(context).push(
            _slideRoute(ParcelDetailsScreen(
              fromLocation: _fromController.text,
              toLocation: _toController.text,
            )),
          ),
        ),
      ]),
    );
  }

  Widget _buildRoutePath() {
    final from = _fromController.text.split(',').first;
    final to = _toController.text.split(',').first;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surfaceEl,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.glassBorder),
      ),
      child: Row(children: [
        const Icon(Icons.radio_button_checked, color: _C.accentA, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(from,
              style: const TextStyle(
                  color: _C.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5),
              overflow: TextOverflow.ellipsis),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.arrow_forward, color: _C.accentB, size: 14),
        ),
        Expanded(
          child: Text(to,
              style: const TextStyle(
                  color: _C.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.location_on_rounded, color: _C.accentB, size: 16),
      ]),
    );
  }

  Widget _buildParcelInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.greenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.green.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(color: _C.green.withValues(alpha: 0.08), blurRadius: 16)
        ],
      ),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _C.green,
            boxShadow: [
              BoxShadow(
                  color: _C.green.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child:
              const Center(child: Text('📦', style: TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available Parcels',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.textSec)),
              SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('5',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: _C.green,
                          height: 1)),
                  SizedBox(width: 8),
                  Text('parcels on route',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.green)),
                ],
              ),
              SizedBox(height: 3),
              Text('Waiting to be picked up',
                  style: TextStyle(color: _C.textSec, fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildEarningsBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _C.orangeBg,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: _C.accentB.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _C.accentB,
            boxShadow: [BoxShadow(color: _C.orangeGlow(0.5), blurRadius: 10)],
          ),
          child: const Icon(Icons.currency_rupee_rounded,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Earn up to ',
              style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              children: [
                TextSpan(
                    text: '₹120 ',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: _C.accentB)),
                TextSpan(text: 'on this route'),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TODAY'S EARNINGS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTodaysEarningsCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kCardRadius),
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: _C.green.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
        border: Border.all(color: _C.green.withValues(alpha: 0.25), width: 1),
      ),
      padding: const EdgeInsets.all(22),
      child: Row(children: [
        // Left: text content
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Potential earnings today',
                style: TextStyle(
                    color: _C.green.withValues(alpha: 0.8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('Earn up to ₹280',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('8 parcels available on your routes',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w400)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  color: _C.green,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _C.green.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.directions_bike_rounded,
                      color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Start Delivering',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 16),
        // Right: decorative circle stat
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _C.green.withValues(alpha: 0.15),
            border:
                Border.all(color: _C.green.withValues(alpha: 0.3), width: 1.5),
          ),
          child: const Center(
            child: Text('₹280',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.1)),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  RECOMMENDED ROUTE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRecommendedRouteCard() {
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          _iconBox(Icons.route_rounded, _C.accentA, _C.blueBg),
          const SizedBox(width: 12),
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Best match for you',
                  style: TextStyle(
                      color: _C.textSec,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500)),
              SizedBox(height: 2),
              Text('Pune → Mumbai',
                  style: TextStyle(
                      color: _C.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.orangeBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _C.accentB.withValues(alpha: 0.3), width: 1),
            ),
            child: const Text('₹120',
                style: TextStyle(
                    color: _C.accentB,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
          ),
        ]),
        const SizedBox(height: 16),
        // Route visual
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _C.surfaceEl,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.glassBorder),
          ),
          child: Row(children: [
            // Origin dot
            Column(children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.accentA,
                      boxShadow: [
                        BoxShadow(color: _C.blueGlow(0.5), blurRadius: 6)
                      ])),
              Container(
                  width: 1.5,
                  height: 28,
                  color: _C.textMuted.withValues(alpha: 0.5)),
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.accentB,
                      boxShadow: [
                        BoxShadow(color: _C.orangeGlow(0.5), blurRadius: 6)
                      ])),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pune, Maharashtra',
                        style: TextStyle(
                            color: _C.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Text('Mumbai, Maharashtra',
                        style: TextStyle(
                            color: _C.textPrimary.withValues(alpha: 0.8),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                  ]),
            ),
            const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('~3 hrs',
                  style: TextStyle(
                      color: _C.textSec,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              SizedBox(height: 14),
              Text('149 km',
                  style: TextStyle(
                      color: _C.textSec,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        // Info chips row
        Row(children: [
          _routeChip(
              Icons.inventory_2_outlined, '3 parcels', _C.accentA, _C.blueBg),
          const SizedBox(width: 8),
          _routeChip(Icons.access_time_rounded, 'Pickup by 2 PM', _C.orange,
              _C.orangeBg),
        ]),
        const SizedBox(height: 16),
        // Quick action
        _PrimaryButton(
          text: 'Accept Route',
          icon: Icons.check_circle_outline_rounded,
          gradientColors: const [_C.accentA, _C.accentB],
          shadowColor: _C.accentA,
          onTap: () => Navigator.of(context).push(
            _slideRoute(const ParcelDetailsScreen(
                fromLocation: 'Pune, Maharashtra',
                toLocation: 'Mumbai, Maharashtra')),
          ),
        ),
      ]),
    );
  }

  Widget _routeChip(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  WEEKLY PERFORMANCE (kept, not shown on home — available for Analytics tab)
  Widget _buildWeeklyPerformance() {
    return Row(children: [
      Expanded(
          child: _buildPerfCard(
              '📦', '24', 'Parcels', _C.accentA, _C.blueBg, '+3 vs last week')),
      const SizedBox(width: 10),
      Expanded(
          child: _buildPerfCard('₹', '1,840', 'Earnings', _C.green, _C.greenBg,
              '+₹240 vs last week')),
      const SizedBox(width: 10),
      Expanded(
          child: _buildPerfCard(
              '⭐', '4.9', 'Rating', _C.accentB, _C.orangeBg, 'Top 5% driver')),
    ]);
  }

  Widget _buildPerfCard(String emoji, String value, String label, Color accent,
      Color bg, String trend) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
          decoration: BoxDecoration(
            color: _C.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 14)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(10)),
                child: Text(emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              Text(value,
                  style: TextStyle(
                    color: accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  )),
              const SizedBox(height: 3),
              Text(label,
                  style: const TextStyle(
                      color: _C.textSec,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(trend,
                  style: TextStyle(
                      color: accent.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TODAY'S OPPORTUNITIES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOpportunitiesCard() {
    return _GlassCard(
      glowColor: _C.accentA,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          _iconBox(Icons.bolt_rounded, _C.accentB, _C.orangeBg),
          const SizedBox(width: 12),
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Live near you',
                  style: TextStyle(
                      color: _C.textSec,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500)),
              SizedBox(height: 2),
              Text('Parcels ready for pickup',
                  style: TextStyle(
                      color: _C.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          // Live pulse badge
          const _LiveBadge(),
        ]),
        const SizedBox(height: 18),
        // Stats row
        Row(children: [
          Expanded(
              child: _buildOppStat(
                  '📦', '8', 'Parcels available', _C.accentA, _C.blueBg)),
          const SizedBox(width: 10),
          Expanded(
              child: _buildOppStat(
                  '₹', '₹280', 'Potential earn', _C.green, _C.greenBg)),
        ]),
        const SizedBox(height: 18),
        // CTA
        _PrimaryButton(
          text: 'Browse Opportunities',
          icon: Icons.explore_rounded,
          gradientColors: const [_C.accentA, _C.accentB],
          shadowColor: _C.accentA,
          onTap: () => Navigator.of(context).push(
            _slideRoute(const RiderAvailableParcelsScreen(
              fromLocation: 'Pune, Maharashtra',
              toLocation: 'Mumbai, Maharashtra',
            )),
          ),
        ),
      ]),
    );
  }

  Widget _buildOppStat(
      String emoji, String value, String label, Color accent, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    color: accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                    color: _C.textSec,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  YOUR DELIVERIES  (max 3 + empty state)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDeliveries() {
    if (_isLoadingActivity) return _buildActivityShimmer();

    const items = [
      _ActivityData(
          emoji: '📦',
          title: 'Parcel to Mumbai',
          sub: 'Picked up · 2 hours ago',
          status: 'In Transit',
          sc: _C.blue,
          sb: _C.blueBg),
      _ActivityData(
          emoji: '✅',
          title: 'Parcel to Nashik',
          sub: 'Delivered · Yesterday',
          status: 'Delivered',
          sc: _C.green,
          sb: _C.greenBg),
      _ActivityData(
          emoji: '🕐',
          title: 'Parcel to Pune',
          sub: 'Waiting · 3 hours ago',
          status: 'Pending',
          sc: _C.orange,
          sb: _C.orangeBg),
    ];

    // ── Empty state ──
    if (items.isEmpty) return _buildDeliveriesEmptyState();

    return _GlassCard(
      child: Column(
        children: items.asMap().entries.map((e) {
          return Column(children: [
            _buildActivityTile(e.value),
            if (e.key < items.length - 1)
              Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 0.8,
                  color: _C.textMuted),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildDeliveriesEmptyState() {
    return _GlassCard(
      child: Column(children: [
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _C.blueBg,
            border: Border.all(color: _C.blueGlow(0.2), width: 1),
          ),
          child:
              const Center(child: Text('📭', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 16),
        const Text('No deliveries yet',
            style: TextStyle(
                color: _C.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Start delivering parcels to see your\nactivity here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _C.textSec, fontSize: 13, height: 1.5)),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ACTIVITY MINI CARDS  (Parcels Sent + Parcels Delivered counts)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActivityMiniCards() {
    return Row(children: [
      Expanded(
        child: _buildMiniStatCard(
          emoji: '📦',
          label: 'Parcels Sent',
          value: '4',
          accent: _C.accentC,
          bg: _C.accentC.withValues(alpha: 0.10),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: _buildMiniStatCard(
          emoji: '🚚',
          label: 'Parcels Delivered',
          value: '5',
          accent: _C.green,
          bg: _C.green.withValues(alpha: 0.10),
        ),
      ),
    ]);
  }

  Widget _buildMiniStatCard({
    required String emoji,
    required String label,
    required String value,
    required Color accent,
    required Color bg,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    color: accent,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: _C.textSec,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BOTTOM NAV  — 3 tabs: Home · History · Profile
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xED0F1C35),
          border:
              const Border(top: BorderSide(color: _C.glassBorder, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  idx: 0,
                  on: Icons.home_filled,
                  off: Icons.home_outlined,
                  label: 'Home',
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _buildNavItem(
                  idx: 1,
                  on: Icons.history_rounded,
                  off: Icons.history_outlined,
                  label: 'History',
                  onTap: () async {
                    setState(() => _currentIndex = 1);
                    await Navigator.of(context)
                        .push(_slideRoute(const HistoryScreen()));
                    if (mounted) {
                      setState(() => _currentIndex = 0);
                    }
                  },
                ),
                _buildNavItem(
                  idx: 2,
                  on: Icons.person_rounded,
                  off: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: () async {
                    setState(() => _currentIndex = 2);
                    await Navigator.of(context)
                        .push(_slideRoute(const ProfileScreen()));
                    if (mounted) {
                      setState(() => _currentIndex = 0);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int idx,
    required IconData on,
    required IconData off,
    required String label,
    required VoidCallback onTap,
  }) {
    final active = _currentIndex == idx;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: active
              ? const LinearGradient(colors: [_C.accentA, _C.accentC])
              : null,
          boxShadow: active
              ? [
                  BoxShadow(
                      color: _C.blueGlow(0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(active ? on : off,
              color: active ? Colors.white : _C.textSec, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color: active ? Colors.white : _C.textSec,
                fontSize: 11.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              )),
        ]),
      ),
    );
  }

  Widget _buildActivityShimmer() {
    return Shimmer.fromColors(
      baseColor: _C.surface,
      highlightColor: _C.surfaceEl,
      child: _GlassCard(
        shimmer: true,
        child: Column(
            children: List.generate(
                3,
                (i) => Column(children: [
                      Row(children: [
                        Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: _C.surface,
                                borderRadius: BorderRadius.circular(12))),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Container(
                                  height: 14,
                                  width: 160,
                                  decoration: BoxDecoration(
                                      color: _C.surface,
                                      borderRadius: BorderRadius.circular(6))),
                              const SizedBox(height: 6),
                              Container(
                                  height: 11,
                                  width: 110,
                                  decoration: BoxDecoration(
                                      color: _C.surface,
                                      borderRadius: BorderRadius.circular(6))),
                            ])),
                        Container(
                            width: 64,
                            height: 24,
                            decoration: BoxDecoration(
                                color: _C.surface,
                                borderRadius: BorderRadius.circular(20))),
                      ]),
                      if (i < 2)
                        Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            height: 0.8,
                            color: _C.textMuted),
                    ]))),
      ),
    );
  }

  Widget _buildActivityTile(_ActivityData item) {
    return Row(children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _C.surfaceEl,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.glassBorder),
        ),
        child: Center(
            child: Text(item.emoji, style: const TextStyle(fontSize: 22))),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.title,
              style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary)),
          const SizedBox(height: 3),
          Text(item.sub, style: const TextStyle(fontSize: 12.5, color: _C.textSec)),
        ]),
      ),
      _GlowStatusChip(label: item.status, color: item.sc, bg: item.sb),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _C.textPrimary,
          letterSpacing: -0.3,
        ));
  }

  Widget _iconBox(IconData icon, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: fg, size: 20),
    );
  }

  // opaque:true allows the HomeScreen to correctly unmount during transition,
  // preventing black screen rendering issues when returning.
  PageRoute _slideRoute(Widget page) {
    return PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 380),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REUSABLE COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

/// Glass morphism card
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final bool shimmer;
  const _GlassCard({required this.child, this.glowColor, this.shimmer = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: _C.surface.withValues(alpha: shimmer ? 1 : 0.85),
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: Border.all(
              color: glowColor != null
                  ? glowColor!.withValues(alpha: 0.25)
                  : _C.glassBorder,
              width: 1.2,
            ),
            boxShadow: glowColor != null
                ? [
                    BoxShadow(
                        color: glowColor!.withValues(alpha: 0.1),
                        blurRadius: 24)
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
          ),
          padding: const EdgeInsets.all(22),
          child: child,
        ),
      ),
    );
  }
}

/// Premium tap-scale action card
class _PremiumActionCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color glowColor;
  final VoidCallback onTap;

  const _PremiumActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_PremiumActionCard> createState() => _PremiumActionCardState();
}

class _PremiumActionCardState extends State<_PremiumActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.38),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji container with glass look
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.8),
                    ),
                    child: Text(widget.emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  )),
              const SizedBox(height: 4),
              Text(widget.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  )),
              const SizedBox(height: 14),
              // Bottom arrow row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient primary CTA button
class _PrimaryButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final Color shadowColor;
  final bool isLoading;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
    required this.gradientColors,
    required this.shadowColor,
    this.isLoading = false,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => _ctrl.forward(),
      onTapUp: widget.isLoading
          ? null
          : (_) {
              _ctrl.reverse();
              widget.onTap();
            },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(widget.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        )),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ]),
          ),
        ),
      ),
    );
  }
}

/// Animated live pulse badge
class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _C.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _C.green.withValues(alpha: 0.35 * _pulse.value + 0.15),
              width: 1),
          boxShadow: [
            BoxShadow(
                color: _C.green.withValues(alpha: 0.2 * _pulse.value),
                blurRadius: 8)
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.green.withValues(alpha: _pulse.value),
              boxShadow: [
                BoxShadow(
                    color: _C.green.withValues(alpha: _pulse.value * 0.6),
                    blurRadius: 4)
              ],
            ),
          ),
          const SizedBox(width: 5),
          const Text('LIVE',
              style: TextStyle(
                  color: _C.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ]),
      ),
    );
  }
}

/// Glowing status chip
class _GlowStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _GlowStatusChip(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8)
        ],
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

/// Animated success pill
class _AnimatedPill extends StatefulWidget {
  final String label;
  final Color color;
  const _AnimatedPill({required this.label, required this.color});

  @override
  State<_AnimatedPill> createState() => _AnimatedPillState();
}

class _AnimatedPillState extends State<_AnimatedPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: widget.color.withValues(alpha: 0.35), width: 1),
          boxShadow: [
            BoxShadow(
                color: widget.color.withValues(alpha: 0.25), blurRadius: 10)
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 7,
            height: 7,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: widget.color),
          ),
          const SizedBox(width: 6),
          Text(widget.label,
              style: TextStyle(
                  color: widget.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityData {
  final String emoji, title, sub, status;
  final Color sc, sb;
  const _ActivityData({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.status,
    required this.sc,
    required this.sb,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOM PAINTER — subtle dot grid
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
//  HOW TO ADD LOTTIE (delivery animation in header):
//
//  1. Add to pubspec.yaml:
//       lottie: ^3.1.0
//       assets:
//         - assets/animations/delivery.json
//
//  2. Download a free Lottie from lottiefiles.com (search "delivery")
//     Save to assets/animations/delivery.json
//
//  3. Inside _buildGreeting(), after the subtitle text, add:
//       Lottie.asset(
//         'assets/animations/delivery.json',
//         width: 140,
//         height: 140,
//         fit: BoxFit.contain,
//       ),
//
//  4. Uncomment the lottie import at the top of this file.
// ═══════════════════════════════════════════════════════════════════════════
