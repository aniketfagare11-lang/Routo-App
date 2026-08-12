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
  static const red        = Color(0xFFEF4444);
  static const textSec    = Color(0xFF64748B);
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _Notif {
  final String  id;
  String  title;
  String  body;
  String  time;
  IconData icon;
  Color    color;
  bool     isUnread;

  _Notif({required this.id, required this.title, required this.body, required this.time, required this.icon, required this.color, this.isUnread = false});
}

// ─────────────────────────────────────────────────────────────────────────────
//  NOTIFICATIONS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgCtrl;
  late Animation<double>   _bgAnim;

  final List<_Notif> _recent = [
    _Notif(id: 'n1', title: 'Order Out for Delivery',  body: 'Your parcel DEL-1042 is out for delivery. ETA 10:30 AM — Bandra, Mumbai.', time: '2 mins ago',  icon: Icons.local_shipping_rounded,       color: _C.accentB, isUnread: true),
    _Notif(id: 'n2', title: 'Payment Credited',        body: 'You earned ₹350 for delivering to Bandra. Amount credited to wallet.',       time: '15 mins ago', icon: Icons.account_balance_wallet_rounded, color: _C.accentA, isUnread: true),
    _Notif(id: 'n3', title: 'New Route Available',     body: 'A new delivery route RT-4030 from Andheri → Kurla is available near you.',   time: '1 hr ago',    icon: Icons.route_rounded,                 color: _C.accentC, isUnread: true),
  ];

  final List<_Notif> _yesterday = [
    _Notif(id: 'n4', title: 'Route Completed',         body: 'You successfully completed Route RT-4029. Great job!',                       time: 'Yesterday',   icon: Icons.check_circle_rounded,          color: _C.green),
    _Notif(id: 'n5', title: 'Withdrawal Processed',    body: 'Your UPI withdrawal of ₹2,000 to name@upi has been processed successfully.', time: 'Yesterday',   icon: Icons.currency_rupee_rounded,        color: _C.accentA),
    _Notif(id: 'n6', title: 'Parcel Picked Up',        body: 'Sender confirmed pickup for SND-2031. Route Pune → Nashik is now active.',   time: 'Yesterday',   icon: Icons.inbox_rounded,                 color: _C.accentB),
  ];

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

  int get _unreadCount => [..._recent, ..._yesterday].where((n) => n.isUnread).length;

  void _markAllRead() => setState(() {
    for (final n in [..._recent, ..._yesterday]) {
      n.isUnread = false;
    }
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg1,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(children: [
        _buildBackground(),
        SafeArea(
          child: Column(children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  if (_recent.isNotEmpty) ...[
                    _buildSectionHeader('RECENT', _unreadCount > 0 ? '$_unreadCount NEW' : null),
                    const SizedBox(height: 14),
                    ..._recent.asMap().entries.map((e) => _dismissible(_recent, e.key)),
                    const SizedBox(height: 24),
                  ],
                  if (_yesterday.isNotEmpty) ...[
                    _buildSectionHeader('YESTERDAY', null),
                    const SizedBox(height: 14),
                    ..._yesterday.asMap().entries.map((e) => _dismissible(_yesterday, e.key)),
                  ],
                  if (_recent.isEmpty && _yesterday.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Column(children: [
                        Icon(Icons.notifications_off_outlined, size: 64, color: _C.textSec.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('No notifications', style: TextStyle(color: _C.textSec.withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            _buildMarkAllButton(),
          ]),
        ),
      ]),
    );
  }

  // ── Dismissible wrapper ────────────────────────────────────────────────────
  Widget _dismissible(List<_Notif> list, int idx) {
    final n = list[idx];
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => setState(() => list.removeAt(idx)),
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _C.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.red.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: _C.red, size: 26),
      ),
      child: _buildNotifCard(list, idx),
    );
  }

  // ── Notification Card ──────────────────────────────────────────────────────
  Widget _buildNotifCard(List<_Notif> list, int idx) {
    final n = list[idx];
    return GestureDetector(
      onTap: () => setState(() => n.isUnread = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: _C.glass,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: n.isUnread ? n.color.withValues(alpha: 0.4) : _C.glassBorder),
              ),
              padding: const EdgeInsets.all(18),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(color: n.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(n.icon, color: n.color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(n.title,
                        style: TextStyle(fontWeight: n.isUnread ? FontWeight.w800 : FontWeight.w700, fontSize: 15, color: Colors.white))),
                    if (n.isUnread)
                      Container(width: 8, height: 8,
                        decoration: BoxDecoration(color: n.color, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: n.color.withValues(alpha: 0.5), blurRadius: 6)]),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  Text(n.body, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, height: 1.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Text(n.time, style: TextStyle(fontSize: 11, color: _C.textSec.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                ])),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String? badge) => Row(children: [
    Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.textSec, letterSpacing: 1.5)),
    if (badge != null) ...[
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: _C.accentB.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Text(badge, style: const TextStyle(color: _C.accentB, fontSize: 10, fontWeight: FontWeight.w800)),
      ),
    ],
  ]);

  // ── Mark All Button ────────────────────────────────────────────────────────
  Widget _buildMarkAllButton() => Padding(
    padding: const EdgeInsets.all(20),
    child: GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); _markAllRead(); },
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.accentA.withValues(alpha: 0.3)),
          color: _C.accentA.withValues(alpha: 0.06),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.done_all_rounded, color: _C.accentA.withValues(alpha: 0.9), size: 18),
          const SizedBox(width: 8),
          Text('Mark All as Read', style: TextStyle(color: _C.accentA.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
      ),
    ),
  );

  // ── App Bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
    leading: GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(margin: const EdgeInsets.all(10), decoration: BoxDecoration(color: _C.glass, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.glassBorder)),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16)),
    ),
    title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
    actions: [
      GestureDetector(
        onTap: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
        child: Container(margin: const EdgeInsets.all(10), decoration: BoxDecoration(color: _C.glass, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.glassBorder)),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 16)),
      ),
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
        _orb(0.10 + 0.05 * math.cos(t),       0.20 + 0.08 * math.sin(t),       300, _C.accentA.withValues(alpha: 0.08)),
        _orb(0.88 + 0.06 * math.cos(t + 2.1), 0.35 + 0.07 * math.sin(t + 2.1), 240, _C.accentB.withValues(alpha: 0.07)),
        _orb(0.45 + 0.07 * math.cos(t + 4.2), 0.78 + 0.05 * math.sin(t + 4.2), 180, _C.accentC.withValues(alpha: 0.06)),
      ]);
    },
  );

  Widget _orb(double x, double y, double size, Color color) => Positioned.fill(
    child: Align(alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])))),
  );
}
