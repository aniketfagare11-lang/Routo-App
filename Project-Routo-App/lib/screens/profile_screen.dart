import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settings_screen.dart';
import 'personal_details_screen.dart';
import 'history_screen.dart';
import 'saved_addresses_screen.dart';
import 'earnings_screen.dart';
import 'notifications_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../widgets/ai_chatbot_widget.dart';
// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg1         = Color(0xFF020617);
  static const glass       = Color(0x14FFFFFF);
  static const glassBorder = Color(0x20FFFFFF);
  static const surfaceEl   = Color(0xFF131F38);

  static const accentA = Color(0xFF3B82F6);
  static const accentB = Color(0xFFF97316);
  static const accentC = Color(0xFF8B5CF6);

  static const green       = Color(0xFF10B981);
  static const red         = Color(0xFFEF4444);
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSec     = Color(0xFF64748B);

  static Color blueGlow(double a)   => accentA.withValues(alpha: a);
  static Color orangeGlow(double a) => accentB.withValues(alpha: a);
  static Color purpleGlow(double a) => accentC.withValues(alpha: a);
}

// ─────────────────────────────────────────────────────────────────────────────
//  MENU DATA
// ─────────────────────────────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final Color    color;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROFILE SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {

  late AnimationController _masterCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _bgAnim;
  late Animation<double> _pulseAnim;

  // -- User Data --
  String _userName  = 'Guest User';
  String _userEmail = 'Not signed in';
  User?  _currentUser;
  StreamSubscription<User?>? _userSub;

  @override
  void initState() {
    super.initState();

    _masterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _bgCtrl     = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _pulseCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);

    _fadeAnim  = CurvedAnimation(parent: _masterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _masterCtrl, curve: Curves.easeOutCubic));
    _bgAnim    = CurvedAnimation(parent: _bgCtrl,    curve: Curves.linear);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _loadUserData();
    _masterCtrl.forward();
  }

  void _loadUserData() {
    _userSub = FirebaseAuth.instance.userChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _userName  = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
          _userEmail = user?.email ?? 'No Email';
        });
      }
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _masterCtrl.dispose();
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  List<_MenuItem> _buildMenuItems(BuildContext context) => [
    _MenuItem(icon: Icons.person_outline_rounded,     title: 'Personal Details',   subtitle: 'Name, email, KYC',        color: _C.accentA, onTap: () => _push(context, const PersonalDetailsScreen())),
    _MenuItem(icon: Icons.history_rounded,            title: 'History',            subtitle: 'Delivered & sent parcels', color: _C.accentC, onTap: () => _push(context, const HistoryScreen())),
    _MenuItem(icon: Icons.location_on_outlined,       title: 'Saved Addresses',    subtitle: 'Home, work & more',        color: _C.green,   onTap: () => _push(context, const SavedAddressesScreen())),
    _MenuItem(icon: Icons.account_balance_wallet_rounded, title: 'Earnings',       subtitle: 'Withdraw & analytics',     color: _C.accentB, onTap: () => _push(context, const EarningsScreen())),
    _MenuItem(icon: Icons.notifications_none_rounded, title: 'Notifications',      subtitle: 'Alerts & preferences',     color: _C.accentA, onTap: () => _push(context, const NotificationsScreen())),
    _MenuItem(icon: Icons.shield_outlined,            title: 'Privacy & Security', subtitle: 'Password & 2FA',           color: _C.accentC, onTap: () => _push(context, const PrivacySecurityScreen())),
    _MenuItem(icon: Icons.help_outline_rounded,       title: 'Help & Support',     subtitle: 'FAQ & live chat',          color: _C.green,   onTap: () => _push(context, const HelpSupportScreen())),
    _MenuItem(icon: Icons.settings_outlined,          title: 'Settings',           subtitle: 'App preferences',          color: _C.accentB, onTap: () => _push(context, const SettingsScreen())),
  ];

  void _push(BuildContext ctx, Widget screen) =>
      Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => screen));

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final menuItems = _buildMenuItems(context);

    return Scaffold(
      backgroundColor: _C.bg1,
      extendBody: true,
      body: Stack(children: [
        _buildBackground(),
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(children: [
                    // 70px gap = avatar radius (60) + 10px breathing room
                    const SizedBox(height: 70),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(children: [
                        _buildProfileCard(context),
                        const SizedBox(height: 24),
                        _buildStatsRow(),
                        const SizedBox(height: 28),
                        _buildSectionLabel('Account'),
                        const SizedBox(height: 12),
                        ...menuItems.map((item) => _buildMenuItem(item)),
                        const SizedBox(height: 12),
                        _buildLogoutButton(context),
                        const SizedBox(height: 32),
                        _buildVersionTag(),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
        // Avatar overlay: sits ON TOP of everything, never clipped
        _buildFloatingAvatar(context),
        const AiChatbotWidget(),
      ]),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── Bottom Navigation Bar ───────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xED0F1C35),
          border: const Border(top: BorderSide(color: _C.glassBorder, width: 0.8)),
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
                  context: context,
                  isActive: false,
                  on: Icons.home_filled,
                  off: Icons.home_outlined,
                  label: 'Home',
                  onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                ),
                _buildNavItem(
                  context: context,
                  isActive: false,
                  on: Icons.history_rounded,
                  off: Icons.history_outlined,
                  label: 'History',
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                _buildNavItem(
                  context: context,
                  isActive: true,
                  on: Icons.person_rounded,
                  off: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: () {}, // Already on Profile
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required bool isActive,
    required IconData on,
    required IconData off,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isActive ? const LinearGradient(colors: [_C.accentA, _C.accentC]) : null,
          boxShadow: isActive
              ? [BoxShadow(color: _C.blueGlow(0.45), blurRadius: 14, offset: const Offset(0, 3))]
              : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isActive ? on : off, color: isActive ? Colors.white : _C.textSec, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color: isActive ? Colors.white : _C.textSec,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              )),
        ]),
      ),
    );
  }

  // ── Animated Background ───────────────────────────────────────────────────
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
                colors: [Color(0xFF0F172A), Color(0xFF020617), Color(0xFF0C1220)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          _orb(x: 0.15 + 0.08 * math.cos(t),       y: 0.08 + 0.05 * math.sin(t),       size: 280, color: _C.blueGlow(0.08)),
          _orb(x: 0.78 + 0.06 * math.cos(t + 2.1), y: 0.30 + 0.06 * math.sin(t + 2.1), size: 200, color: _C.orangeGlow(0.06)),
          _orb(x: 0.50 + 0.07 * math.cos(t + 4.2), y: 0.65 + 0.04 * math.sin(t + 4.2), size: 160, color: _C.purpleGlow(0.05)),
        ]);
      },
    );
  }

  Widget _orb({required double x, required double y, required double size, required Color color}) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment(x * 2 - 1, y * 2 - 1),
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, Colors.transparent]),
          ),
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  //
  // PROFILE IMAGE STRATEGY:
  // We use expandedHeight:160 so the header is shorter. The avatar (120px
  // diameter) is NOT placed inside FlexibleSpaceBar (which clips overflow).
  // Instead it is positioned as an overlay directly in the body Stack,
  // sitting at the very top of the scrollable content area. This completely
  // eliminates the clipping bug.
  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0F1C35),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Navigator.of(context).canPop()
          ? GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _C.glass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.glassBorder),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F1C35), Color(0xFF07101E)],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_C.blueGlow(0.14), Colors.transparent]),
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: -20,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_C.orangeGlow(0.10), Colors.transparent]),
              ),
            ),
          ),
          // Bottom divider / fade
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          ),
        ]),
      ),
      title: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (b) => const LinearGradient(
          colors: [Color(0xFFF1F5F9), _C.accentA],
        ).createShader(b),
        child: const Text('Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
      ),
      centerTitle: true,
    );
  }

  // Builds the floating avatar that overlays the boundary between appbar & body.
  // Placed in the body Stack (not inside FlexibleSpaceBar) → never clipped.
  // It floats at exactly: statusBarHeight + kToolbarHeight - avatarRadius
  Widget _buildFloatingAvatar(BuildContext context) {
    final statusH = MediaQuery.of(context).padding.top;
    // Pin avatar so its centre is at the bottom edge of the collapsed appBar
    final topOffset = statusH + kToolbarHeight - 60.0; // 60 = avatar radius
    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Center(
        child: Stack(alignment: Alignment.bottomRight, children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [_C.accentA, _C.accentB]),
                boxShadow: [
                  BoxShadow(
                    color: _C.blueGlow(_pulseAnim.value * 0.50),
                    blurRadius: 28 * _pulseAnim.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: child,
            ),
            child: _currentUser?.photoURL != null
                ? CircleAvatar(
                    radius: 57,
                    backgroundImage: NetworkImage(_currentUser!.photoURL!),
                  )
                : const CircleAvatar(
                    radius: 57,
                    backgroundColor: Color(0xFF0F1C35),
                    child: Icon(Icons.person_rounded, size: 54, color: Color(0xFF64748B)),
                  ),
          ),
          // Camera badge
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Image upload coming soon!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: _C.accentA,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.accentA, _C.accentB]),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF020617), width: 2.5),
                boxShadow: [BoxShadow(color: _C.orangeGlow(0.5), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Profile Card ──────────────────────────────────────────────────────────
  // top padding = 64 (half of avatar 120px) + 8px gap = 64 → leaves room
  // for the avatar which overhangs from above.
  Widget _buildProfileCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 68, 24, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.glassBorder),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.blueGlow(0.07), Colors.white.withValues(alpha: 0.02), Colors.transparent],
              stops: const [0.0, 0.35, 1.0],
            ),
          ),
          child: Column(children: [
            // Name + verified badge
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: Text(_userName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _C.textPrimary, letterSpacing: -0.3),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              if (_currentUser != null)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_C.accentA, _C.accentC]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _C.blueGlow(0.4), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                ),
            ]),
            const SizedBox(height: 8),
            // Email chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _C.accentA.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.accentA.withValues(alpha: 0.2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.alternate_email_rounded, size: 13, color: _C.accentA),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(_userEmail,
                      style: const TextStyle(fontSize: 13, color: _C.accentA, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            // Edit Profile button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _push(context, const PersonalDetailsScreen());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: [_C.accentA.withValues(alpha: 0.15), _C.accentC.withValues(alpha: 0.10)]),
                  border: Border.all(color: _C.accentA.withValues(alpha: 0.25)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_rounded, color: _C.accentA, size: 14),
                  SizedBox(width: 8),
                  Text('Edit Profile', style: TextStyle(color: _C.accentA, fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return const Row(children: [
      Expanded(child: _PremiumStatCard(value: '142',    label: 'Deliveries', icon: Icons.local_shipping_outlined, color: _C.accentA)),
      SizedBox(width: 10),
      Expanded(child: _PremiumStatCard(value: '4.9★',  label: 'Rating',     icon: Icons.star_outline_rounded,   color: _C.accentB)),
      SizedBox(width: 10),
      Expanded(child: _PremiumStatCard(value: '₹24.8k',label: 'Earned',     icon: Icons.currency_rupee_rounded, color: _C.accentC)),
    ]);
  }

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: _C.textSec.withValues(alpha: 0.8),
            letterSpacing: 1.5,
          )),
    );
  }

  // ── Menu Item ─────────────────────────────────────────────────────────────
  Widget _buildMenuItem(_MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.glassBorder),
        color: _C.surfaceEl,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: item.color.withValues(alpha: 0.08),
          highlightColor: item.color.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: item.color.withValues(alpha: 0.25)),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: _C.textPrimary, letterSpacing: 0.1)),
                  const SizedBox(height: 2),
                  Text(item.subtitle,
                      style: const TextStyle(fontSize: 11.5, color: _C.textSec, fontWeight: FontWeight.w400)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, color: item.color.withValues(alpha: 0.7), size: 13),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Logout Button ─────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.red.withValues(alpha: 0.35)),
          color: _C.red.withValues(alpha: 0.06),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.logout_rounded, color: _C.red.withValues(alpha: 0.9), size: 20),
          const SizedBox(width: 10),
          Text('Log Out',
              style: TextStyle(
                  color: _C.red.withValues(alpha: 0.9),
                  fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
        ]),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: _C.glassBorder)),
          title: const Text('Confirm Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: const Text('Are you sure you want to log out of Routo?', style: TextStyle(color: _C.textSec)),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _C.textSec, fontWeight: FontWeight.w600)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.accentA, _C.accentC]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Version tag ───────────────────────────────────────────────────────────
  Widget _buildVersionTag() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_C.accentA, _C.accentB]),
          ),
        ),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [_C.accentA, _C.accentB],
          ).createShader(b),
          child: const Text('ROUTO',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
        ),
        const SizedBox(width: 8),
        Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_C.accentA, _C.accentB]),
          ),
        ),
      ]),
      const SizedBox(height: 4),
      Text('Version 1.0.0', style: TextStyle(fontSize: 11, color: _C.textSec.withValues(alpha: 0.5))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  GRID PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  PREMIUM STAT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumStatCard extends StatefulWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _PremiumStatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  State<_PremiumStatCard> createState() => _PremiumStatCardState();
}

class _PremiumStatCardState extends State<_PremiumStatCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); HapticFeedback.lightImpact(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: widget.color.withValues(alpha: 0.25)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.color.withValues(alpha: 0.10), Colors.transparent],
                ),
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 18),
                ),
                const SizedBox(height: 10),
                Text(widget.value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: widget.color, height: 1)),
                const SizedBox(height: 3),
                Text(widget.label,
                    style: const TextStyle(fontSize: 10, color: _C.textSec, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
