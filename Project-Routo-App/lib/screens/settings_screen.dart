import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg1 = Color(0xFF020617);
  static const glass = Color(0x14FFFFFF);
  static const glassBorder = Color(0x20FFFFFF);
  static const accentA = Color(0xFF3B82F6);
  static const accentB = Color(0xFFF97316);
  static const accentC = Color(0xFF8B5CF6);
  static const red = Color(0xFFEF4444);
  static const textSec = Color(0xFF64748B);
}

// ─────────────────────────────────────────────────────────────────────────────
//  SETTINGS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late Animation<double> _bgAnim;

  // Stateful
  bool _darkMode = true;
  bool _notificationsOn = true;
  bool _locationOn = true;
  String _language = 'English';

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
              // ── PREFERENCES ────────────────────────────────────────────────
              _buildGroup('PREFERENCES', [
                _buildToggle('Dark Mode', Icons.dark_mode_rounded, _C.accentB,
                    _darkMode, (v) => setState(() => _darkMode = v)),
                _buildToggle(
                    'Notifications',
                    Icons.notifications_rounded,
                    _C.accentA,
                    _notificationsOn,
                    (v) => setState(() => _notificationsOn = v)),
                _buildToggle(
                    'Location Permission',
                    Icons.location_on_rounded,
                    _C.accentC,
                    _locationOn,
                    (v) => setState(() => _locationOn = v)),
                _buildItem('Language', Icons.language_rounded, _C.accentA,
                    trailing: _language,
                    onTap: () => _showLanguageDialog(context)),
                _buildItem('Currency', Icons.currency_rupee_rounded, _C.accentC,
                    trailing: 'INR (₹)'),
              ]),
              const SizedBox(height: 24),
              // ── ABOUT ───────────────────────────────────────────────────────
              _buildGroup('ABOUT ROUTO', [
                _buildItem(
                    'App Version', Icons.info_outline_rounded, _C.accentA,
                    trailing: 'v1.0.0'),
                _buildItem(
                    'Terms of Service', Icons.description_rounded, _C.accentC),
                _buildItem('Privacy Policy', Icons.policy_rounded, _C.accentB),
                _buildItem(
                    'Rate the App', Icons.star_outline_rounded, _C.accentB),
              ]),
              const SizedBox(height: 28),
              // ── LOGOUT ─────────────────────────────────────────────────────
              GestureDetector(
                onTap: () => _showLogoutDialog(context),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _C.red.withValues(alpha: 0.35)),
                    color: _C.red.withValues(alpha: 0.06),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: _C.red.withValues(alpha: 0.9), size: 20),
                        const SizedBox(width: 10),
                        Text('Log Out',
                            style: TextStyle(
                                color: _C.red.withValues(alpha: 0.9),
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
              const SizedBox(height: 32),
              // ── Footer ─────────────────────────────────────────────────────
              Center(
                  child: Column(children: [
                Text('Made with ❤️ in India — Routo Team',
                    style: TextStyle(
                        color: _C.textSec.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('© 2026 Routo. All rights reserved.',
                    style: TextStyle(
                        color: _C.textSec.withValues(alpha: 0.4),
                        fontSize: 10)),
              ])),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Language Dialog ────────────────────────────────────────────────────────
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _C.glassBorder)),
        title: const Text('Select Language',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final lang in [
            'English',
            'हिंदी (Hindi)',
            'मराठी (Marathi)',
            'தமிழ் (Tamil)',
            'తెలుగు (Telugu)'
          ])
            _langTile(lang),
        ]),
      ),
    );
  }

  Widget _langTile(String lang) => ListTile(
        title: Text(lang,
            style: TextStyle(
                color: _language == lang ? _C.accentA : Colors.white,
                fontWeight: FontWeight.w600)),
        trailing: _language == lang
            ? const Icon(Icons.check_rounded, color: _C.accentA, size: 18)
            : null,
        onTap: () {
          setState(() => _language = lang.split(' ')[0]);
          Navigator.pop(context);
        },
      );

  // ── Logout Dialog ──────────────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: _C.glassBorder)),
          title: const Text('Confirm Logout',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: const Text('Are you sure you want to log out?',
              style: TextStyle(color: _C.textSec)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: _C.textSec, fontWeight: FontWeight.w600))),
            Container(
              decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [_C.accentA, _C.accentC]),
                  borderRadius: BorderRadius.circular(12)),
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      (r) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Log Out',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build Helpers ──────────────────────────────────────────────────────────
  Widget _buildGroup(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _C.textSec,
                  letterSpacing: 1.5))),
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
                color: _C.glass,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _C.glassBorder)),
            child: Column(children: children),
          ),
        ),
      ),
    ]);
  }

  Widget _buildItem(String title, IconData icon, Color color,
      {String? trailing, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 19)),
            const SizedBox(width: 14),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600))),
            if (trailing != null)
              Text(trailing,
                  style: const TextStyle(
                      color: _C.textSec,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded,
                color: _C.textSec.withValues(alpha: 0.5), size: 13),
          ]),
        ),
      ),
    );
  }

  Widget _buildToggle(String title, IconData icon, Color color, bool val,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 19)),
        const SizedBox(width: 14),
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600))),
        Switch(
          value: val,
          onChanged: (v) {
            HapticFeedback.lightImpact();
            onChanged(v);
          },
          activeThumbColor: color,
          activeTrackColor: color.withValues(alpha: 0.3),
          inactiveThumbColor: Colors.white30,
          inactiveTrackColor: Colors.white12,
        ),
      ]),
    );
  }

  // ── App Bar & Background ───────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: _C.glass,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.glassBorder)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16))),
        title: const Text('Settings',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        actions: [
          GestureDetector(
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (r) => false),
              child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: _C.glass,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.glassBorder)),
                  child: const Icon(Icons.home_rounded,
                      color: Colors.white, size: 16))),
          const SizedBox(width: 10),
        ],
      );

  Widget _buildBackground() => AnimatedBuilder(
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
            _orb(0.15 + 0.05 * math.cos(t), 0.10 + 0.06 * math.sin(t), 280,
                _C.accentA.withValues(alpha: 0.08)),
            _orb(
                0.82 + 0.06 * math.cos(t + 2.1),
                0.35 + 0.08 * math.sin(t + 2.1),
                210,
                _C.accentB.withValues(alpha: 0.07)),
            _orb(
                0.48 + 0.07 * math.cos(t + 4.2),
                0.70 + 0.05 * math.sin(t + 4.2),
                170,
                _C.accentC.withValues(alpha: 0.06)),
          ]);
        },
      );

  Widget _orb(double x, double y, double size, Color color) => Positioned.fill(
        child: Align(
            alignment: Alignment(x * 2 - 1, y * 2 - 1),
            child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        RadialGradient(colors: [color, Colors.transparent])))),
      );
}
