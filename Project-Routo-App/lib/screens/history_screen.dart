import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../widgets/ai_chatbot_widget.dart';
import 'profile_screen.dart';
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
  static const red = Color(0xFFEF4444);
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSec = Color(0xFF64748B);

  static Color blueGlow(double a) => accentA.withValues(alpha: a);
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryItem {
  final String id;
  final String type; // 'Delivered' | 'Sent'
  final String status; // 'Completed' | 'In Transit' | 'Cancelled'
  final String dateTime;
  final double amount;
  final String from;
  final String to;

  const _HistoryItem({
    required this.id,
    required this.type,
    required this.status,
    required this.dateTime,
    required this.amount,
    required this.from,
    required this.to,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  HISTORY SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _fadeCtrl;
  late TabController _tabCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _fadeAnim;

  final List<_HistoryItem> _delivered = [
    const _HistoryItem(
        id: 'DEL-1042',
        type: 'Delivered',
        status: 'Completed',
        dateTime: '14 Apr 2026 • 10:30 AM',
        amount: 350,
        from: 'Andheri, Mumbai',
        to: 'Bandra, Mumbai'),
    const _HistoryItem(
        id: 'DEL-1041',
        type: 'Delivered',
        status: 'Completed',
        dateTime: '13 Apr 2026 • 2:15 PM',
        amount: 220,
        from: 'Thane, MH',
        to: 'Mulund, Mumbai'),
    const _HistoryItem(
        id: 'DEL-1040',
        type: 'Delivered',
        status: 'Completed',
        dateTime: '12 Apr 2026 • 9:00 AM',
        amount: 480,
        from: 'Dadar, Mumbai',
        to: 'Kurla, Mumbai'),
    const _HistoryItem(
        id: 'DEL-1039',
        type: 'Delivered',
        status: 'Cancelled',
        dateTime: '11 Apr 2026 • 4:45 PM',
        amount: 0,
        from: 'Borivali, Mumbai',
        to: 'Andheri, Mumbai'),
    const _HistoryItem(
        id: 'DEL-1038',
        type: 'Delivered',
        status: 'Completed',
        dateTime: '10 Apr 2026 • 11:20 AM',
        amount: 650,
        from: 'Vasai, MH',
        to: 'Dahisar, Mumbai'),
  ];

  final List<_HistoryItem> _sent = [
    const _HistoryItem(
        id: 'SND-2031',
        type: 'Sent',
        status: 'In Transit',
        dateTime: '14 Apr 2026 • 8:00 AM',
        amount: 180,
        from: 'Pune, MH',
        to: 'Nashik, MH'),
    const _HistoryItem(
        id: 'SND-2030',
        type: 'Sent',
        status: 'Completed',
        dateTime: '13 Apr 2026 • 3:00 PM',
        amount: 95,
        from: 'Nagpur, MH',
        to: 'Amravati, MH'),
    const _HistoryItem(
        id: 'SND-2029',
        type: 'Sent',
        status: 'Completed',
        dateTime: '12 Apr 2026 • 1:30 PM',
        amount: 260,
        from: 'Aurangabad, MH',
        to: 'Pune, MH'),
    const _HistoryItem(
        id: 'SND-2028',
        type: 'Sent',
        status: 'Cancelled',
        dateTime: '10 Apr 2026 • 10:10 AM',
        amount: 0,
        from: 'Kolhapur, MH',
        to: 'Satara, MH'),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 16))
          ..repeat();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _tabCtrl = TabController(length: 2, vsync: this);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.linear);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _fadeCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg1,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildAppBar(context),
      body: Stack(children: [
        _buildBackground(),
        FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: Column(children: [
              const SizedBox(height: 8),
              _buildTabBar(),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildList(_delivered),
                    _buildList(_sent),
                  ],
                ),
              ),
            ]),
          ),
        ),
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
                  isActive: true,
                  on: Icons.history_rounded,
                  off: Icons.history_outlined,
                  label: 'History',
                  onTap: () {}, // Already on History
                ),
                _buildNavItem(
                  context: context,
                  isActive: false,
                  on: Icons.person_rounded,
                  off: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
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

  // ── App Bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _iconBtn(Icons.arrow_back_ios_new_rounded,
            () => Navigator.of(context).pop()),
        title: const Text('History',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        actions: [
          _iconBtn(
              Icons.home_rounded,
              () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (r) => false)),
          const SizedBox(width: 10),
        ],
      );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
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

  // ── Tab Bar ──────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: _C.surfaceEl, borderRadius: BorderRadius.circular(16)),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: [_C.accentA, _C.accentC]),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          labelColor: Colors.white,
          unselectedLabelColor: _C.textSec,
          tabs: const [
            Tab(text: '📦  Delivered'),
            Tab(text: '🚀  Sent'),
          ],
        ),
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────
  Widget _buildList(List<_HistoryItem> items) {
    if (items.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_outlined,
            size: 64, color: _C.textSec.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text('No records found',
            style: TextStyle(
                color: _C.textSec.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildCard(items[i]),
    );
  }

  // ── Card ───────────────────────────────────────────────────────────────────
  Widget _buildCard(_HistoryItem item) {
    final isDelivered = item.type == 'Delivered';
    final isCompleted = item.status == 'Completed';
    final isCancelled = item.status == 'Cancelled';
    final isInTransit = item.status == 'In Transit';

    final typeColor = isDelivered ? _C.accentA : _C.accentC;
    final statusColor = isCancelled
        ? _C.red
        : isInTransit
            ? _C.accentB
            : _C.green;
    final amountColor = isDelivered ? _C.green : _C.accentB;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: _C.glass,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: isInTransit
                    ? _C.accentB.withValues(alpha: 0.35)
                    : _C.glassBorder),
          ),
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header row
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        isDelivered
                            ? Icons.local_shipping_rounded
                            : Icons.send_rounded,
                        color: typeColor,
                        size: 12),
                    const SizedBox(width: 5),
                    Text(item.type.toUpperCase(),
                        style: TextStyle(
                            color: typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(item.id,
                    style: const TextStyle(
                        color: _C.textSec,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(item.status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
              ),
            ]),
            const SizedBox(height: 14),
            // Route
            Row(children: [
              const Icon(Icons.radio_button_checked_rounded,
                  color: _C.accentA, size: 14),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(item.from,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500))),
            ]),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(width: 2, height: 12, color: _C.glassBorder),
            ),
            Row(children: [
              const Icon(Icons.location_on_rounded,
                  color: _C.accentB, size: 14),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(item.to,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500))),
            ]),
            const SizedBox(height: 14),
            // Footer
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.access_time_rounded,
                    size: 13, color: _C.textSec.withValues(alpha: 0.7)),
                const SizedBox(width: 5),
                Text(item.dateTime,
                    style: TextStyle(
                        color: _C.textSec.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ]),
              if (!isCancelled)
                Text(
                  isDelivered
                      ? '+₹${item.amount.toStringAsFixed(0)}'
                      : '-₹${item.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900),
                )
              else
                Text('Cancelled',
                    style: TextStyle(
                        color: _C.red.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Background ─────────────────────────────────────────────────────────────
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
            _orb(0.10 + 0.06 * math.cos(t), 0.20 + 0.05 * math.sin(t), 270,
                _C.accentA.withValues(alpha: 0.08)),
            _orb(
                0.85 + 0.05 * math.cos(t + 2.1),
                0.45 + 0.08 * math.sin(t + 2.1),
                200,
                _C.accentB.withValues(alpha: 0.07)),
            _orb(
                0.45 + 0.07 * math.cos(t + 4.2),
                0.78 + 0.06 * math.sin(t + 4.2),
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
                      RadialGradient(colors: [color, Colors.transparent]))),
        ),
      );
}
