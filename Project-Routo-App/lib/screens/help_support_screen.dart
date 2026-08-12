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
  static const surfaceEl  = Color(0xFF131F38);
  static const accentA    = Color(0xFF3B82F6);
  static const accentB    = Color(0xFFF97316);
  static const accentC    = Color(0xFF8B5CF6);
  static const green      = Color(0xFF10B981);
  static const textSec    = Color(0xFF64748B);

  static Color blueGlow(double a) => accentA.withValues(alpha: a);
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELP & SUPPORT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgCtrl;
  late Animation<double>   _bgAnim;

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
              _buildHeroSection(context),
              const SizedBox(height: 24),
              _sectionHeader('QUICK ACTIONS'),
              const SizedBox(height: 14),
              _buildActionRow(context),
              const SizedBox(height: 24),
              _sectionHeader('FREQUENTLY ASKED QUESTIONS'),
              const SizedBox(height: 14),
              _buildFaqItem('How do I track my delivery?',
                  'Open the "History" tab in your Profile to see real-time updates on all your deliveries and shipments.'),
              _buildFaqItem('How to withdraw earnings?',
                  'Go to Profile > Earnings and tap "Withdraw". You can transfer via Bank Transfer or UPI (GPay, PhonePe, Paytm, BHIM).'),
              _buildFaqItem('What happens if I miss a stop?',
                  'The app will auto-suggest a reroute. You can also contact the sender directly from the delivery details screen.'),
              _buildFaqItem('How to update payment details?',
                  'Go to Profile > Earnings > Withdraw to manage your bank or UPI details.'),
              _buildFaqItem('Is my data secure with Routo?',
                  'Yes! We use end-to-end encryption. You can review data settings under Privacy & Security in your profile.'),
              _buildFaqItem('How do I get verified as a carrier?',
                  'Go to Personal Details and upload your Aadhaar or PAN card. KYC verification usually takes 1-2 business days.'),
              _buildFaqItem('How are delivery charges calculated?',
                  'Charges are based on distance, parcel weight, and delivery speed. You will see the base amount before accepting any delivery.'),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Hero Section ───────────────────────────────────────────────────────────
  Widget _buildHeroSection(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _C.glassBorder),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_C.accentA.withValues(alpha: 0.15), _C.accentC.withValues(alpha: 0.1), Colors.black45],
            ),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _C.accentA.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.support_agent_rounded, size: 44, color: _C.accentA),
            ),
            const SizedBox(height: 18),
            const Text('How can we help you?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Our support team is available 24/7 for you.', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Connecting to support agent...'), backgroundColor: _C.accentA,
                    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(colors: [_C.accentA, _C.accentB]),
                  boxShadow: [BoxShadow(color: _C.blueGlow(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Text('Start Live Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Action Row ─────────────────────────────────────────────────────────────
  Widget _buildActionRow(BuildContext context) {
    return Row(children: [
      Expanded(child: _actionCard(context, 'Contact\nSupport', Icons.call_rounded, _C.accentA, () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Calling 1800-XXX-XXXX...'), backgroundColor: _C.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      })),
      const SizedBox(width: 12),
      Expanded(child: _actionCard(context, 'Report\nIssue', Icons.flag_rounded, _C.accentB, () => _showReportDialog(context))),
      const SizedBox(width: 12),
      Expanded(child: _actionCard(context, 'My\nTickets', Icons.confirmation_number_rounded, _C.accentC, () => _showTicketDialog(context))),
    ]);
  }

  Widget _actionCard(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(label, textAlign: TextAlign.center,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3)),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────
  void _showReportDialog(BuildContext context) {
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _C.glassBorder)),
        title: const Text('Report an Issue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            decoration: BoxDecoration(color: _C.surfaceEl, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.glassBorder)),
            child: TextField(
              controller: descCtrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Describe your issue in detail...',
                hintStyle: TextStyle(color: _C.textSec.withValues(alpha: 0.6), fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _C.textSec))),
          TextButton(onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Issue reported! Ticket ID: #RT-9981'), backgroundColor: _C.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
          }, child: const Text('Submit', style: TextStyle(color: _C.accentB, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  void _showTicketDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _C.glassBorder)),
        title: const Text('My Tickets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _ticketRow('#RT-9980', 'Payment delay issue', 'Resolved',  _C.green),
          const SizedBox(height: 10),
          _ticketRow('#RT-9963', 'Route not loading',   'In Review', _C.accentB),
          const SizedBox(height: 10),
          _ticketRow('#RT-9941', 'App crash on login',  'Closed',    _C.textSec),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: _C.textSec))),
        ],
      ),
    );
  }

  Widget _ticketRow(String id, String desc, String status, Color color) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(id, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      Text(desc, style: const TextStyle(color: _C.textSec, fontSize: 11)),
    ])),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    ),
  ]);

  // ── FAQ ────────────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) => Text(title,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.textSec, letterSpacing: 1.5));

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: _C.surfaceEl, borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.glassBorder)),
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(question, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          iconColor: _C.accentB,
          collapsedIconColor: _C.accentA,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(answer, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13, height: 1.6, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar & Background ───────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
    leading: GestureDetector(onTap: () => Navigator.of(context).pop(),
      child: Container(margin: const EdgeInsets.all(10), decoration: BoxDecoration(color: _C.glass, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.glassBorder)),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16))),
    title: const Text('Help & Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
    actions: [
      GestureDetector(onTap: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
        child: Container(margin: const EdgeInsets.all(10), decoration: BoxDecoration(color: _C.glass, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.glassBorder)),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 16))),
      const SizedBox(width: 10),
    ],
  );

  Widget _buildBackground() => AnimatedBuilder(
    animation: _bgAnim,
    builder: (_, __) {
      final t = _bgAnim.value * 2 * math.pi;
      return Stack(children: [
        Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF020617), Color(0xFF0C1220)]))),
        _orb(0.12 + 0.05 * math.cos(t),       0.15 + 0.06 * math.sin(t),       300, _C.accentA.withValues(alpha: 0.08)),
        _orb(0.85 + 0.06 * math.cos(t + 2.1), 0.40 + 0.07 * math.sin(t + 2.1), 240, _C.accentB.withValues(alpha: 0.07)),
        _orb(0.48 + 0.07 * math.cos(t + 4.2), 0.75 + 0.05 * math.sin(t + 4.2), 190, _C.accentC.withValues(alpha: 0.06)),
      ]);
    },
  );

  Widget _orb(double x, double y, double size, Color color) => Positioned.fill(
    child: Align(alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])))),
  );
}
