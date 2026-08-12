import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class _C {
  static const bg1        = Color(0xFF020617);
  static const glass      = Color(0x14FFFFFF);
  static const glassBorder= Color(0x20FFFFFF);
  static const accentA    = Color(0xFF3B82F6);
  static const accentB    = Color(0xFFF97316);
  static const accentC    = Color(0xFF8B5CF6);
  static const green      = Color(0xFF10B981);
  static const textSec    = Color(0xFF64748B);
}

class MyRoutesScreen extends StatefulWidget {
  const MyRoutesScreen({super.key});

  @override
  State<MyRoutesScreen> createState() => _MyRoutesScreenState();
}

class _MyRoutesScreenState extends State<MyRoutesScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late Animation<double> _bgAnim;

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
      body: Stack(children: [
        _buildBackground(),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildSectionHeader('Active Deliveries'),
              const SizedBox(height: 16),
              _buildRouteCard('RT-4029', 'In Transit', '10:30 AM', '14:00 PM', 3, progress: 0.65),
              const SizedBox(height: 24),
              _buildSectionHeader('History'),
              const SizedBox(height: 16),
              _buildRouteCard('RT-4028', 'Completed', '08:00 AM', '12:30 PM', 5, isCompleted: true),
              const SizedBox(height: 16),
              _buildRouteCard('RT-4027', 'Completed', 'Yesterday', 'Yesterday', 8, isCompleted: true),
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
      leading: _appBarAction(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).pop()),
      title: const Text('My Routes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      actions: [
        _appBarAction(icon: Icons.home_rounded, onTap: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false)),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _appBarAction({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _C.glass, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.glassBorder)),
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
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF020617), Color(0xFF0C1220)]))),
          _orb(x: 0.10 + 0.06 * math.cos(t),       y: 0.20 + 0.05 * math.sin(t),       size: 270, color: _C.accentA.withValues(alpha: 0.08)),
          _orb(x: 0.88 + 0.05 * math.cos(t + 2.1), y: 0.45 + 0.08 * math.sin(t + 2.1), size: 190, color: _C.accentB.withValues(alpha: 0.07)),
          _orb(x: 0.40 + 0.07 * math.cos(t + 4.2), y: 0.80 + 0.06 * math.sin(t + 4.2), size: 180, color: _C.accentC.withValues(alpha: 0.06)),
        ]);
      },
    );
  }

  Widget _orb({required double x, required double y, required double size, required Color color}) {
    return Positioned.fill(child: Align(alignment: Alignment(x * 2 - 1, y * 2 - 1), child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])))));
  }

  Widget _buildSectionHeader(String title) {
    return Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.textSec, letterSpacing: 1.5));
  }

  Widget _buildRouteCard(String id, String status, String start, String end, int stops, {bool isCompleted = false, double? progress}) {
    final color = isCompleted ? _C.green : _C.accentB;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(color: _C.glass, borderRadius: BorderRadius.circular(24), border: Border.all(color: _C.glassBorder)),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Route $id', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
                child: Text(status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: color)),
              ),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              _iconLabel(Icons.access_time_filled_rounded, '$start - $end', isCompleted ? _C.textSec : _C.accentA),
              const Spacer(),
              _iconLabel(Icons.location_on_rounded, '$stops Stops', isCompleted ? _C.textSec : _C.accentC),
            ]),
            if (progress != null) ...[
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(_C.accentA),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(color: _C.accentA, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _iconLabel(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }
}
