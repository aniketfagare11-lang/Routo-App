import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg1         = Color(0xFF020617);
  static const glass       = Color(0x14FFFFFF);
  static const glassBorder = Color(0x20FFFFFF);
  static const surfaceEl   = Color(0xFF131F38);
  static const accentA     = Color(0xFF3B82F6);
  static const accentB     = Color(0xFFF97316);
  static const accentC     = Color(0xFF8B5CF6);
  static const green       = Color(0xFF10B981);
  static const red         = Color(0xFFEF4444);
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSec     = Color(0xFF64748B);

  static Color blueGlow(double a)   => accentA.withValues(alpha: a);
  static Color orangeGlow(double a) => accentB.withValues(alpha: a);
  static Color purpleGlow(double a) => accentC.withValues(alpha: a);
}

// ─────────────────────────────────────────────────────────────────────────────
//  EARNINGS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double>   _bgAnim;
  late Animation<double>   _fadeAnim;

  bool _isWeekly = false;

  // Mock chart data
  final List<double> _dailyData  = [320, 580, 420, 890, 650, 1200, 980];
  final List<double> _weeklyData = [4200, 5800, 3900, 7200, 6100, 8500, 9200];
  List<String> get _dailyLabels  => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  List<String> get _weeklyLabels => ['W1','W2','W3','W4','W5','W6','W7'];

  // Mock withdrawal history
  final List<_Withdrawal> _withdrawals = [
    const _Withdrawal(method: 'UPI', amount: 2000, date: '12 Apr 2026', status: 'Completed'),
    const _Withdrawal(method: 'Bank', amount: 5000, date: '08 Apr 2026', status: 'Completed'),
    const _Withdrawal(method: 'UPI', amount: 1500, date: '01 Apr 2026', status: 'Completed'),
    const _Withdrawal(method: 'Bank', amount: 3500, date: '25 Mar 2026', status: 'Pending'),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _bgAnim   = CurvedAnimation(parent: _bgCtrl,   curve: Curves.linear);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _formatRupee(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '₹${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg1,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(children: [
        _buildBackground(),
        FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 10),
                _buildTotalEarningsCard(),
                const SizedBox(height: 24),
                _buildChartCard(),
                const SizedBox(height: 24),
                _buildWithdrawButton(context),
                const SizedBox(height: 32),
                _buildSectionHeader('WITHDRAWAL HISTORY'),
                const SizedBox(height: 14),
                ..._withdrawals.map(_buildWithdrawalTile),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    leading: _iconBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.of(context).pop()),
    title: const Text('Earnings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
    actions: [
      _iconBtn(Icons.home_rounded, () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false)),
      const SizedBox(width: 10),
    ],
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _C.glass, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.glassBorder)),
      child: Icon(icon, color: Colors.white, size: 16),
    ),
  );

  // ── Total Earnings Card ────────────────────────────────────────────────────
  Widget _buildTotalEarningsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _C.accentA.withValues(alpha: 0.3)),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_C.accentA.withValues(alpha: 0.18), _C.accentC.withValues(alpha: 0.10), Colors.transparent],
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _C.accentA.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.account_balance_wallet_rounded, color: _C.accentA, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Total Earnings', style: TextStyle(color: _C.textSec, fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [_C.accentA, _C.accentC]).createShader(b),
              child: const Text('₹24,850', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1)),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _C.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.trending_up_rounded, color: _C.green, size: 14),
                  SizedBox(width: 4),
                  Text('+18.4% this month', style: TextStyle(color: _C.green, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              _miniStat('This Week', '₹3,200',  _C.accentA),
              const SizedBox(width: 12),
              _miniStat('Pending',    '₹850',    _C.accentB),
              const SizedBox(width: 12),
              _miniStat('Deliveries', '142',     _C.accentC),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: _C.textSec, fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
    ),
  );

  // ── Chart Card ─────────────────────────────────────────────────────────────
  Widget _buildChartCard() {
    final data   = _isWeekly ? _weeklyData  : _dailyData;
    final labels = _isWeekly ? _weeklyLabels : _dailyLabels;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.glassBorder),
            color: _C.glass,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Earnings Analytics', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: _C.surfaceEl, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  _chartToggleBtn('Daily',  !_isWeekly),
                  _chartToggleBtn('Weekly',  _isWeekly),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: _EarningsChart(data: data, labels: labels),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chartToggleBtn(String label, bool active) => GestureDetector(
    onTap: () => setState(() => _isWeekly = label == 'Weekly'),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: active ? const LinearGradient(colors: [_C.accentA, _C.accentC]) : null,
      ),
      child: Text(label, style: TextStyle(
        color: active ? Colors.white : _C.textSec,
        fontSize: 12, fontWeight: FontWeight.w700,
      )),
    ),
  );

  // ── Withdraw Button ────────────────────────────────────────────────────────
  Widget _buildWithdrawButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showWithdrawSheet(context);
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [_C.accentA, _C.accentC]),
          boxShadow: [BoxShadow(color: _C.blueGlow(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.account_balance_rounded, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Text('Withdraw Earnings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _WithdrawSheet(),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) => Text(title,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.textSec, letterSpacing: 1.5));

  // ── Withdrawal Tile ────────────────────────────────────────────────────────
  Widget _buildWithdrawalTile(_Withdrawal w) {
    final isUpi      = w.method == 'UPI';
    final color      = isUpi ? _C.accentC : _C.accentA;
    final isPending  = w.status == 'Pending';
    final statusColor = isPending ? _C.accentB : _C.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _C.surfaceEl,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.glassBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(isUpi ? Icons.phone_android_rounded : Icons.account_balance_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${w.method} Withdrawal', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(w.date, style: const TextStyle(color: _C.textSec, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${w.amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(w.status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }

  // ── Background ─────────────────────────────────────────────────────────────
  Widget _buildBackground() => AnimatedBuilder(
    animation: _bgAnim,
    builder: (_, __) {
      final t = _bgAnim.value * 2 * math.pi;
      return Stack(children: [
        Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF020617), Color(0xFF0C1220)]))),
        _orb(0.15 + 0.06 * math.cos(t),       0.12 + 0.05 * math.sin(t),       280, _C.blueGlow(0.08)),
        _orb(0.82 + 0.05 * math.cos(t + 2.1), 0.42 + 0.08 * math.sin(t + 2.1), 220, _C.orangeGlow(0.07)),
        _orb(0.45 + 0.07 * math.cos(t + 4.2), 0.72 + 0.05 * math.sin(t + 4.2), 180, _C.purpleGlow(0.06)),
      ]);
    },
  );

  Widget _orb(double x, double y, double size, Color color) => Positioned.fill(
    child: Align(
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent]))),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  EARNINGS CHART — CustomPainter
// ─────────────────────────────────────────────────────────────────────────────
class _EarningsChart extends StatefulWidget {
  final List<double> data;
  final List<String> labels;
  const _EarningsChart({required this.data, required this.labels});

  @override
  State<_EarningsChart> createState() => _EarningsChartState();
}

class _EarningsChartState extends State<_EarningsChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_EarningsChart old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        painter: _ChartPainter(data: widget.data, labels: widget.labels, progress: _anim.value),
        size: Size.infinite,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final double progress;

  _ChartPainter({required this.data, required this.labels, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const topPad    = 10.0;
    const bottomPad = 28.0;
    const sidePad   = 8.0;

    final maxVal  = data.reduce(math.max);
    const minVal  = 0.0;
    final range   = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;
    final chartH  = size.height - topPad - bottomPad;
    final slotW   = (size.width - sidePad * 2) / (data.length - 1);

    List<Offset> pts = [];
    for (int i = 0; i < data.length; i++) {
      final x = sidePad + i * slotW;
      final y = topPad + chartH * (1 - (data[i] - minVal) / range);
      pts.add(Offset(x, y));
    }

    // Gradient fill
    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i+1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i+1].dx) / 2, pts[i+1].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i+1].dx, pts[i+1].dy);
    }
    final fillPath = Path.from(path)
      ..lineTo(pts.last.dx, size.height - bottomPad)
      ..lineTo(pts.first.dx, size.height - bottomPad)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFF3B82F6).withValues(alpha: 0.35 * progress), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Animated clip for line draw-on effect
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()..color = const Color(0xFF3B82F6)..style = PaintingStyle.fill;
    final dotBg    = Paint()..color = const Color(0xFF0F172A)..style = PaintingStyle.fill;
    for (final pt in pts) {
      canvas.drawCircle(pt, 5, dotBg);
      canvas.drawCircle(pt, 4, dotPaint);
    }
    canvas.restore();

    // Labels
    const labelStyle = TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600);
    for (int i = 0; i < labels.length; i++) {
      final x = sidePad + i * slotW;
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottomPad + 8));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.progress != progress || old.data != data;
}

// ─────────────────────────────────────────────────────────────────────────────
//  WITHDRAW BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet();

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _upiCtrl    = TextEditingController();
  final _nameCtrl   = TextEditingController();
  final _acNoCtrl   = TextEditingController();
  final _ifscCtrl   = TextEditingController();
  final _bankCtrl   = TextEditingController();
  final _amtCtrl    = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _upiCtrl.dispose(); _nameCtrl.dispose(); _acNoCtrl.dispose();
    _ifscCtrl.dispose(); _bankCtrl.dispose(); _amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0x20FFFFFF))),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Withdraw Earnings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Choose your withdrawal method', style: TextStyle(color: _C.textSec, fontSize: 13)),
            const SizedBox(height: 20),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: _C.surfaceEl, borderRadius: BorderRadius.circular(14)),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [_C.accentA, _C.accentC]),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                labelColor: Colors.white,
                unselectedLabelColor: _C.textSec,
                tabs: const [
                  Tab(text: '🏦  Bank Transfer'),
                  Tab(text: '📱  UPI'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 360,
              child: TabBarView(controller: _tab, children: [
                _buildBankForm(),
                _buildUpiForm(),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildBankForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        _sheetInput(_nameCtrl,   'Account Holder Name', Icons.person_outline_rounded,    _C.accentA, TextInputType.text),
        const SizedBox(height: 14),
        _sheetInput(_acNoCtrl,   'Account Number',      Icons.credit_card_rounded,        _C.accentC, TextInputType.number),
        const SizedBox(height: 14),
        _sheetInput(_ifscCtrl,   'IFSC Code',           Icons.code_rounded,               _C.accentB, TextInputType.text),
        const SizedBox(height: 14),
        _sheetInput(_bankCtrl,   'Bank Name',           Icons.account_balance_rounded,    _C.accentA, TextInputType.text),
        const SizedBox(height: 14),
        _sheetInput(_amtCtrl,    'Amount (₹)',          Icons.currency_rupee_rounded,     _C.green,   TextInputType.number),
        const SizedBox(height: 20),
        _submitBtn('Initiate Bank Transfer', _C.accentA),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildUpiForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        _sheetInput(_upiCtrl, 'Enter UPI ID (e.g. name@upi)', Icons.phone_android_rounded, _C.accentC, TextInputType.emailAddress),
        const SizedBox(height: 14),
        _sheetInput(_amtCtrl, 'Amount (₹)', Icons.currency_rupee_rounded, _C.green, TextInputType.number),
        const SizedBox(height: 20),
        // UPI App icons
        const Align(alignment: Alignment.centerLeft,
          child: Text('PAY VIA', style: TextStyle(color: _C.textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _upiAppBtn('GPay', Icons.g_mobiledata_rounded, const Color(0xFF4285F4)),
          _upiAppBtn('PhonePe', Icons.phone_rounded, const Color(0xFF5F259F)),
          _upiAppBtn('Paytm', Icons.payment_rounded, const Color(0xFF00BAF2)),
          _upiAppBtn('BHIM', Icons.account_balance_rounded, const Color(0xFF138808)),
        ]),
        const SizedBox(height: 20),
        _submitBtn('Send via UPI', _C.accentC),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _upiAppBtn(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $label...'), backgroundColor: color, behavior: SnackBarBehavior.floating),
        );
      },
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: _C.textSec, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _sheetInput(TextEditingController ctrl, String hint, IconData icon, Color color, TextInputType kt) {
    return Container(
      decoration: BoxDecoration(color: _C.surfaceEl, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.glassBorder)),
      child: TextField(
        controller: ctrl,
        keyboardType: kt,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: color, size: 18),
          hintText: hint,
          hintStyle: TextStyle(color: _C.textSec.withValues(alpha: 0.7), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _submitBtn(String label, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Withdrawal request submitted!'),
            backgroundColor: _C.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [color, _C.accentC]),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _Withdrawal {
  final String method, date, status;
  final double amount;
  const _Withdrawal({required this.method, required this.amount, required this.date, required this.status});
}
