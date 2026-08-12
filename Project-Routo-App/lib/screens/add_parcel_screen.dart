import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:routo_app/screens/home_screen.dart';
import 'package:routo_app/screens/order_confirmed_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS — Synced with HomeScreen & Login dark palette
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg1 = Color(0xFF020617);

  static const glass = Color(0x14FFFFFF);
  static const glassBorder = Color(0x20FFFFFF);
  static const surfaceEl = Color(0xFF131F38);

  static const accentA = Color(0xFF3B82F6); // blue
  static const accentB = Color(0xFFF97316); // orange
  static const accentC = Color(0xFF8B5CF6); // purple

  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);
  static const cyan = Color(0xFF06B6D4);

  static const textPrimary = Color(0xFFF1F5F9);
  static const textSec = Color(0xFF64748B);

  static Color blueGlow(double a) => accentA.withValues(alpha: a);
  static Color orangeGlow(double a) => accentB.withValues(alpha: a);
  static Color purpleGlow(double a) => accentC.withValues(alpha: a);
  static Color greenGlow(double a) => green.withValues(alpha: a);
}

// ─────────────────────────────────────────────────────────────────────────────
//  PARCEL TYPES
// ─────────────────────────────────────────────────────────────────────────────
const _kParcelTypes = [
  {'label': 'Package', 'emoji': '📦', 'color': 0xFF3B82F6},
  {'label': 'Fragile', 'emoji': '🫙', 'color': 0xFFF97316},
  {'label': 'Documents', 'emoji': '📄', 'color': 0xFF06B6D4},
  {'label': 'Electronics', 'emoji': '💻', 'color': 0xFF8B5CF6},
  {'label': 'Other', 'emoji': '✉️', 'color': 0xFF10B981},
];

// ─────────────────────────────────────────────────────────────────────────────
//  ADD PARCEL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AddParcelScreen extends StatefulWidget {
  const AddParcelScreen({super.key});

  @override
  State<AddParcelScreen> createState() => _AddParcelScreenState();
}

class _AddParcelScreenState extends State<AddParcelScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();

  final _originFocus = FocusNode();
  final _destFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _landmarkFocus = FocusNode();
  final _receiverPhoneFocus = FocusNode();

  // ── State ─────────────────────────────────────────────────────────────────
  String? _originError;
  String? _destError;
  String? _dateError;
  String? _weightError;
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isFetchingLoc = false;
  bool _isPriceSuggested = true;
  int _selectedType = 0;

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _successCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _bgCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _successAnim;
  late Animation<double> _btnScale;
  late Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 16))
          ..repeat();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _successAnim =
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
    _btnScale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.linear);

    _fadeCtrl.forward();
    _slideCtrl.forward();

    _weightCtrl.addListener(_onWeightChanged);
    for (final fn in [
      _originFocus,
      _destFocus,
      _weightFocus,
      _priceFocus,
      _landmarkFocus,
      _receiverPhoneFocus
    ]) {
      fn.addListener(() => setState(() {}));
    }
  }

  void _onWeightChanged() {
    final w = double.tryParse(_weightCtrl.text);
    if (w != null) {
      final suggested = w < 2
          ? '₹100'
          : w <= 5
              ? '₹200'
              : '₹350';
      if (_priceCtrl.text.isEmpty || _isPriceSuggested) {
        _priceCtrl.text = suggested;
        _isPriceSuggested = true;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _originCtrl,
      _destCtrl,
      _dateCtrl,
      _weightCtrl,
      _priceCtrl,
      _notesCtrl,
      _landmarkCtrl,
      _receiverPhoneCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _originFocus,
      _destFocus,
      _weightFocus,
      _priceFocus,
      _landmarkFocus,
      _receiverPhoneFocus
    ]) {
      f.dispose();
    }
    for (final a in [_fadeCtrl, _slideCtrl, _successCtrl, _btnCtrl, _bgCtrl]) {
      a.dispose();
    }
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLoc = true);
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isFetchingLoc = false;
        _originCtrl.text = 'Pune, Maharashtra';
        _originError = null;
      });
    }
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _C.accentA,
            onPrimary: Colors.white,
            surface: Color(0xFF0F1C35),
            onSurface: Colors.white,
          ),
          dialogTheme: DialogThemeData(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateCtrl.text =
            '${picked.day.toString().padLeft(2, '0')} / ${picked.month.toString().padLeft(2, '0')} / ${picked.year}';
        _dateError = null;
      });
    }
  }

  bool _validate() {
    setState(() {
      _originError = _originCtrl.text.trim().isEmpty
          ? 'Please enter a collection point'
          : null;
      _destError = _destCtrl.text.trim().isEmpty
          ? 'Please enter a delivery address'
          : null;
      _dateError =
          _dateCtrl.text.trim().isEmpty ? 'Select a collection date' : null;
      _weightError =
          _weightCtrl.text.trim().isEmpty ? 'Enter parcel weight in kg' : null;
    });
    return _originError == null &&
        _destError == null &&
        _dateError == null &&
        _weightError == null;
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    if (!_validate()) return;
    await _btnCtrl.forward();
    await _btnCtrl.reverse();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      _successCtrl.forward();
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, a, b) => OrderConfirmedScreen(
              pickupAddress: _originCtrl.text,
              deliveryAddress: _destCtrl.text,
              parcelType: _selectedType.toString(),
              weight: _weightCtrl.text,
              price: _priceCtrl.text,
              date: _dateCtrl.text,
            ),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildHeroHeader(),
                    const SizedBox(height: 24),
                    _buildLocationCard(),
                    const SizedBox(height: 16),
                    _buildParcelTypeCard(),
                    const SizedBox(height: 16),
                    _buildDetailsCard(),
                    const SizedBox(height: 16),
                    _buildNotesCard(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 16),
                    _buildDisclaimer(),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isSuccess) _buildSuccessOverlay(),
      ]),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
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

  // ── Background ────────────────────────────────────────────────────────────
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
              x: 0.12 + 0.07 * math.cos(t),
              y: 0.10 + 0.05 * math.sin(t),
              size: 260,
              color: _C.blueGlow(0.09)),
          _orb(
              x: 0.82 + 0.05 * math.cos(t + 2.0),
              y: 0.32 + 0.06 * math.sin(t + 2.0),
              size: 200,
              color: _C.orangeGlow(0.07)),
          _orb(
              x: 0.45 + 0.06 * math.cos(t + 4.1),
              y: 0.72 + 0.04 * math.sin(t + 4.1),
              size: 170,
              color: _C.purpleGlow(0.06)),
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

  // ── Hero Header ───────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Row(children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [_C.accentA, _C.accentB],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: _C.blueGlow(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: const Center(child: Text('📦', style: TextStyle(fontSize: 24))),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_C.textPrimary, Color(0xFF93C5FD)],
            ).createShader(b),
            child: const Text('Book a Delivery',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 3),
          const Text('Fill in the details to send your parcel',
              style: TextStyle(
                  fontSize: 13, color: _C.textSec, fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    ]);
  }

  // ── Location Card ─────────────────────────────────────────────────────────
  Widget _buildLocationCard() {
    return _GlassCard(
      accentColor: _C.accentA,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              icon: Icons.local_shipping_rounded,
              title: 'Pickup & Delivery',
              color: _C.accentA),
          const SizedBox(height: 20),
          // Pickup Address
          _buildInput(
            controller: _originCtrl,
            focusNode: _originFocus,
            label: 'Pickup Address',
            hint: 'Where should we pick up the parcel?',
            icon: Icons.my_location_rounded,
            focusColor: _C.accentA,
            error: _originError,
            suffix: _isFetchingLoc
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _C.accentA),
                  )
                : GestureDetector(
                    onTap: _fetchLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_C.accentA, _C.accentC]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                              color: _C.blueGlow(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child:
                          const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.gps_fixed_rounded,
                            color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('GPS',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
          ),

          // Dashed connector line
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
            child: Column(
              children: List.generate(
                  3,
                  (_) => Container(
                        width: 2,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: _C.textSec.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
            ),
          ),

          // Delivery Address
          _buildInput(
            controller: _destCtrl,
            focusNode: _destFocus,
            label: 'Delivery Address',
            hint: 'Where should it be delivered?',
            icon: Icons.location_on_rounded,
            focusColor: _C.accentB,
            error: _destError,
          ),

          // Distance estimate pill
          if (_originCtrl.text.isNotEmpty && _destCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _C.accentA.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.accentA.withValues(alpha: 0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.straighten_rounded, color: _C.accentA, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimated delivery: ~2h 30m  ·  149 km',
                    style: TextStyle(
                        color: _C.textSec,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 12),
                Text('₹120 base',
                    style: TextStyle(
                        color: _C.accentB,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
          const SizedBox(height: 14),
          // Landmark (optional)
          _buildInput(
            controller: _landmarkCtrl,
            focusNode: _landmarkFocus,
            label: 'Landmark (Optional)',
            hint: 'e.g. Near Pune Railway Station',
            icon: Icons.place_outlined,
            focusColor: _C.accentC,
          ),
          const SizedBox(height: 14),
          // Receiver Phone Number
          _buildInput(
            controller: _receiverPhoneCtrl,
            focusNode: _receiverPhoneFocus,
            label: 'Receiver Phone Number',
            hint: '+91 98765 43210',
            icon: Icons.phone_outlined,
            focusColor: _C.green,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // ── Parcel Type Card ──────────────────────────────────────────────────────
  Widget _buildParcelTypeCard() {
    return _GlassCard(
      accentColor: _C.accentC,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              icon: Icons.category_rounded,
              title: 'Parcel Type',
              color: _C.accentC),
          const SizedBox(height: 18),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _kParcelTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final t = _kParcelTypes[i];
                final color = Color(t['color'] as int);
                final selected = _selectedType == i;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedType = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: 76,
                    decoration: BoxDecoration(
                      color:
                          selected ? color.withValues(alpha: 0.15) : _C.glass,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? color.withValues(alpha: 0.7)
                            : _C.glassBorder,
                        width: selected ? 1.5 : 1.0,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  spreadRadius: 0)
                            ]
                          : [],
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t['emoji'] as String,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 6),
                          Text(
                            t['label'] as String,
                            style: TextStyle(
                              color: selected ? color : _C.textSec,
                              fontSize: 10.5,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Parcel Details Card ───────────────────────────────────────────────────
  Widget _buildDetailsCard() {
    return _GlassCard(
      accentColor: _C.accentB,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionHeader(
            icon: Icons.inventory_2_rounded,
            title: 'Parcel Details',
            color: _C.accentB),
        const SizedBox(height: 20),

        // Weight + Price row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: _buildInput(
              controller: _weightCtrl,
              focusNode: _weightFocus,
              label: 'Weight (kg)',
              hint: '0.0',
              icon: Icons.monitor_weight_outlined,
              focusColor: _C.accentA,
              error: _weightError,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildInput(
                controller: _priceCtrl,
                focusNode: _priceFocus,
                label: 'Price (₹)',
                hint: 'Auto-calculated',
                icon: Icons.currency_rupee_rounded,
                focusColor: _C.green,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _isPriceSuggested = false),
              ),
              if (_isPriceSuggested && _priceCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 4),
                  child: Row(children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 10, color: _C.green),
                    const SizedBox(width: 4),
                    Text('AI suggested',
                        style: TextStyle(
                            color: _C.green.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
            ]),
          ),
        ]),
        const SizedBox(height: 14),

        // Collection Date
        _buildInput(
          controller: _dateCtrl,
          label: 'Collection Date',
          hint: 'Tap to choose a date',
          icon: Icons.calendar_month_rounded,
          focusColor: _C.cyan,
          readOnly: true,
          onTap: _pickDate,
          error: _dateError,
        ),
      ]),
    );
  }

  // ── Notes Card ────────────────────────────────────────────────────────────
  Widget _buildNotesCard() {
    return _GlassCard(
      accentColor: _C.green,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionHeader(
            icon: Icons.sticky_note_2_outlined,
            title: 'Special Instructions',
            color: _C.green),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: _C.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.glassBorder),
          ),
          child: TextField(
            controller: _notesCtrl,
            maxLines: 3,
            style: const TextStyle(
                color: _C.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'e.g. Handle with care, leave at reception…',
              hintStyle: TextStyle(
                  color: _C.textSec.withValues(alpha: 0.7), fontSize: 13),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10, top: 14),
                child:
                    Icon(Icons.edit_note_rounded, color: _C.textSec, size: 20),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return ScaleTransition(
      scale: _btnScale,
      child: GestureDetector(
        onTap: _isLoading ? null : _submit,
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
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Confirm Booking',
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
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Center(
      child: Text(
        '🔒  Your parcel details are encrypted and secure',
        style: TextStyle(
            color: _C.textSec.withValues(alpha: 0.7),
            fontSize: 11.5,
            fontWeight: FontWeight.w400),
      ),
    );
  }

  // ── Success Overlay ───────────────────────────────────────────────────────
  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: Colors.black.withValues(alpha: 0.70),
          child: Center(
            child: ScaleTransition(
              scale: _successAnim,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1C35),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _C.green.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                        color: _C.greenGlow(0.25),
                        blurRadius: 48,
                        spreadRadius: 4),
                    BoxShadow(
                        color: _C.blueGlow(0.12),
                        blurRadius: 60,
                        spreadRadius: 8),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _C.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: _C.greenGlow(0.3),
                            blurRadius: 24,
                            spreadRadius: 2)
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: _C.green, size: 44),
                  ),
                  const SizedBox(height: 22),
                  const Text('Booking Confirmed!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                    'Your parcel has been booked\nsuccessfully. Track it in My Deliveries.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                        height: 1.6),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                          colors: [_C.accentA, _C.accentB]),
                      boxShadow: [
                        BoxShadow(
                            color: _C.blueGlow(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Center(
                          child: Text('Back to Home',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Input field ───────────────────────────────────────────────────────────
  Widget _buildInput({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required Color focusColor,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffix,
    String? error,
    ValueChanged<String>? onChanged,
  }) {
    final focused = focusNode?.hasFocus ?? false;
    final hasError = error != null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          color: focused ? focusColor : _C.textSec,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        child: Text(label.toUpperCase()),
      ),
      const SizedBox(height: 7),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _C.surfaceEl,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasError
                ? _C.red.withValues(alpha: 0.7)
                : focused
                    ? focusColor.withValues(alpha: 0.65)
                    : _C.glassBorder,
            width: focused ? 1.5 : 1.0,
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                      color: focusColor.withValues(alpha: 0.2), blurRadius: 16)
                ]
              : hasError
                  ? [
                      BoxShadow(
                          color: _C.red.withValues(alpha: 0.12), blurRadius: 10)
                    ]
                  : [],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          style: const TextStyle(
              color: _C.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: _C.textSec.withValues(alpha: 0.6),
                fontSize: 13.5,
                fontWeight: FontWeight.w400),
            prefixIcon:
                Icon(icon, color: focused ? focusColor : _C.textSec, size: 18),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 10), child: suffix)
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          ),
        ),
      ),
      if (hasError)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 4),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, size: 12, color: _C.red),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                    color: _C.red, fontSize: 11, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  const _GlassCard({required this.child, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? _C.accentA;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.glassBorder),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.07),
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
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
              color: _C.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }
}
