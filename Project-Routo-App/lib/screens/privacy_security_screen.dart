import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class _C {
  static const bg1 = Color(0xFF020617);
  static const glass = Color(0x14FFFFFF);
  static const glassBorder = Color(0x20FFFFFF);
  static const accentA = Color(0xFF3B82F6);
  static const accentB = Color(0xFFF97316);
  static const accentC = Color(0xFF8B5CF6);
  static const green = Color(0xFF10B981);
  static const textSec = Color(0xFF64748B);
}

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 16))
          ..repeat();
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
      body: Stack(children: [
        _buildBackground(),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 10),
              _buildSectionHeader('Login Security'),
              const SizedBox(height: 16),
              _buildToggleTile('Biometric Access', 'Use Face ID or Touch ID',
                  true, Icons.fingerprint_rounded, _C.accentA),
              const SizedBox(height: 12),
              _buildToggleTile('Two-Factor Auth', 'Secure with OTP & codes',
                  false, Icons.verified_user_rounded, _C.accentC),
              const SizedBox(height: 12),
              _buildActionTile(
                  'Change Password',
                  'Update your login credentials',
                  Icons.lock_reset_rounded,
                  _C.accentB),
              const SizedBox(height: 32),
              _buildSectionHeader('Data & Privacy'),
              const SizedBox(height: 16),
              _buildToggleTile(
                  'Location History',
                  'Track active route in background',
                  true,
                  Icons.map_rounded,
                  _C.accentA),
              const SizedBox(height: 12),
              _buildToggleTile(
                  'Personalized Ads',
                  'Allow data sharing for better deals',
                  false,
                  Icons.privacy_tip_rounded,
                  _C.accentC),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: _appBarAction(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).pop()),
      title: const Text('Privacy & Security',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      actions: [
        _appBarAction(
            icon: Icons.home_rounded,
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (r) => false)),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _appBarAction({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: _C.glass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.glassBorder)),
        child: Icon(icon, color: Colors.white, size: 16),
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
              ]))),
          _orb(
              x: 0.12 + 0.05 * math.cos(t),
              y: 0.15 + 0.08 * math.sin(t),
              size: 300,
              color: _C.accentA.withValues(alpha: 0.08)),
          _orb(
              x: 0.85 + 0.06 * math.cos(t + 2.1),
              y: 0.40 + 0.07 * math.sin(t + 2.1),
              size: 240,
              color: _C.accentB.withValues(alpha: 0.07)),
          _orb(
              x: 0.48 + 0.07 * math.cos(t + 4.2),
              y: 0.75 + 0.05 * math.sin(t + 4.2),
              size: 190,
              color: _C.accentC.withValues(alpha: 0.06)),
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
                    gradient:
                        RadialGradient(colors: [color, Colors.transparent])))));
  }

  Widget _buildSectionHeader(String title) {
    return Text(title.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _C.textSec,
            letterSpacing: 1.5));
  }

  Widget _buildToggleTile(
      String title, String subtitle, bool val, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
              color: _C.glass,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _C.glassBorder)),
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ])),
            Switch(
              value: val,
              onChanged: (_) {},
              activeThumbColor: _C.green,
              activeTrackColor: _C.green.withValues(alpha: 0.25),
              inactiveThumbColor: Colors.white30,
              inactiveTrackColor: Colors.white12,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildActionTile(
      String title, String subtitle, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
              color: _C.glass,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _C.glassBorder)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 22)),
            title: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            subtitle: Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.3), size: 16),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
