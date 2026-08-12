import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS (Synced with HomeScreen)
// ─────────────────────────────────────────────────────────────────────────────
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

class ParcelDetailsScreen extends StatefulWidget {
  final String fromLocation;
  final String toLocation;

  const ParcelDetailsScreen({
    super.key,
    required this.fromLocation,
    required this.toLocation,
  });

  @override
  State<ParcelDetailsScreen> createState() => _ParcelDetailsScreenState();
}

class _ParcelDetailsScreenState extends State<ParcelDetailsScreen>
    with TickerProviderStateMixin {
  bool _isAccepting = false;
  final Set<int> _selectedIndices = {0, 1, 2, 3, 4};

  // ── Animation controllers ─────────────────────────────────────────────────
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardScales;

  // Background orbiting
  late AnimationController _bgOrbitCtrl;
  late Animation<double> _bgOrbitAnim;

  // ── Design tokens ─────────────────────────────────────────────────────────
  // Design tokens switched to _C

  final List<Map<String, dynamic>> _mockParcels = [
    {
      'type': 'Box',
      'weight': '2.5 kg',
      'price': '₹50',
      'date': 'Today, 2:00 PM',
      'icon': Icons.inventory_2_rounded,
    },
    {
      'type': 'Document',
      'weight': '0.5 kg',
      'price': '₹20',
      'date': 'Today, 4:30 PM',
      'icon': Icons.description_rounded,
    },
    {
      'type': 'Electronics',
      'weight': '1.0 kg',
      'price': '₹30',
      'date': 'Tomorrow, 9:00 AM',
      'icon': Icons.devices_rounded,
    },
    {
      'type': 'Clothing',
      'weight': '1.5 kg',
      'price': '₹10',
      'date': 'Tomorrow, 11:00 AM',
      'icon': Icons.checkroom_rounded,
    },
    {
      'type': 'Box',
      'weight': '3.0 kg',
      'price': '₹10',
      'date': 'Tomorrow, 1:00 PM',
      'icon': Icons.inventory_2_rounded,
    },
  ];

  int get _totalEarnings {
    int total = 0;
    for (int i in _selectedIndices) {
      final priceStr = _mockParcels[i]['price'] as String;
      total += int.tryParse(priceStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();

    _cardControllers = List.generate(
      _mockParcels.length,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 180)),
    );
    _cardScales = _cardControllers
        .map((c) => Tween<double>(begin: 1.0, end: 0.96)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    // Background orbiting orbs
    _bgOrbitCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat();
    _bgOrbitAnim = CurvedAnimation(parent: _bgOrbitCtrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    for (final c in _cardControllers) {
      c.dispose();
    }
    _bgOrbitCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAcceptRoute() async {
    if (_selectedIndices.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _isAccepting = true);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isAccepting = false);
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (context) => _buildSuccessDialog(),
      );
    }
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF12122A),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: _C.green.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: _C.green.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                    decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _C.green.withValues(alpha: 0.3),
                      Colors.transparent,
                    ]),
                  ),
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_C.green, Color(0xFF22C55E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Route Accepted!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You have accepted ${_selectedIndices.length} parcels\nfor delivery. Safe travels!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                    child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [_C.accentA, _C.accentB],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _C.accentA.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Go Back Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg1,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackground(),
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildRouteSummaryCard(),
                      const SizedBox(height: 24),
                      _buildSectionHeader(),
                      const SizedBox(height: 14),
                      ...List.generate(_mockParcels.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildParcelCard(i, _mockParcels[i]),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
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
      title: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [_C.accentA, _C.accentB],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds),
        child: const Text(
          'Route Details',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgOrbitAnim,
      builder: (_, __) {
        final t = _bgOrbitAnim.value * 2 * math.pi;
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
          _orb(
            x: 0.15 + 0.08 * math.cos(t),
            y: 0.12 + 0.05 * math.sin(t),
            size: 280,
            color: _C.accentA.withValues(alpha: 0.08),
          ),
          _orb(
            x: 0.75 + 0.06 * math.cos(t + 2.1),
            y: 0.35 + 0.06 * math.sin(t + 2.1),
            size: 220,
            color: _C.accentB.withValues(alpha: 0.07),
          ),
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

  Widget _orb({required double x, required double y, required double size, required Color color}) {
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

  // ── Route Summary Card ────────────────────────────────────────────────────
  Widget _buildRouteSummaryCard() {
    final from = widget.fromLocation.split(',').first.trim();
    final to = widget.toLocation.split(',').first.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _C.glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon column
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _C.accentA.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location_rounded,
                            color: _C.accentA, size: 16),
                      ),
                      ...List.generate(
                        3,
                        (_) => Container(
                          width: 2,
                          height: 6,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: _C.textSec.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _C.accentB.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: _C.accentB, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Location text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(from,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            '148 km  ·  ~2h 30m',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.38),
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(to,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  // Stats column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _statBadge(Icons.inventory_2_rounded,
                          '${_mockParcels.length} Parcels', _C.accentC),
                      const SizedBox(height: 8),
                      _statBadge(Icons.local_fire_department_rounded, 'Express',
                          _C.accentB),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Earnings strip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: _C.accentA.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.accentA.withValues(alpha: 0.22)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded,
                            color: _C.accentA, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Total Earnings',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (b) => const LinearGradient(
                        colors: [_C.accentA, _C.accentB],
                      ).createShader(b),
                      child: Text(
                        '₹$_totalEarnings',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Parcels to Deliver',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.1),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _C.accentA.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.accentA.withValues(alpha: 0.3)),
          ),
          child: Text(
            '${_selectedIndices.length} Selected',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _C.accentA),
          ),
        ),
      ],
    );
  }

  // ── Parcel Card ───────────────────────────────────────────────────────────
  Widget _buildParcelCard(int index, Map<String, dynamic> parcel) {
    final isSelected = _selectedIndices.contains(index);

    return GestureDetector(
      onTapDown: (_) => _cardControllers[index].forward(),
      onTapUp: (_) async {
        await _cardControllers[index].reverse();
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedIndices.remove(index);
          } else {
            _selectedIndices.add(index);
          }
        });
      },
      onTapCancel: () => _cardControllers[index].reverse(),
      child: ScaleTransition(
        scale: _cardScales[index],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isSelected ? _C.accentA.withValues(alpha: 0.55) : _C.glassBorder,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _C.accentA.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon bubble — neutral unselected, accent when selected
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _C.accentA.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  parcel['icon'] as IconData,
                  color: isSelected ? _C.accentA : _C.textSec,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            parcel['type'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.75),
                              letterSpacing: 0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Unified accent gradient price
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (b) => const LinearGradient(
                            colors: [_C.accentA, _C.accentB],
                          ).createShader(b),
                          child: Text(
                            parcel['price'] as String,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.monitor_weight_outlined,
                            size: 13, color: _C.textSec),
                        const SizedBox(width: 4),
                        Text(parcel['weight'] as String,
                            style: const TextStyle(
                                fontSize: 12,
                                color: _C.textSec,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 10),
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: _C.textSec),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            parcel['date'] as String,
                            style: const TextStyle(
                                fontSize: 12,
                                color: _C.textSec,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Selection indicator — unified accent gradient
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [_C.accentA, _C.accentB],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : _C.textSec.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: _C.accentA.withValues(alpha: 0.35),
                              blurRadius: 8)
                        ]
                      : [],
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 15)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isEmpty = _selectedIndices.isEmpty;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: const BoxDecoration(
              color: Color(0x14FFFFFF),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: _C.glassBorder, width: 1)),
            ),
            child: GestureDetector(
              onTap: isEmpty ? null : _handleAcceptRoute,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: isEmpty
                      ? const LinearGradient(
                          colors: [Color(0xFF2A2A3A), Color(0xFF1E1E30)])
                      : const LinearGradient(
                          colors: [_C.accentA, _C.accentB],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  boxShadow: isEmpty
                      ? []
                      : [
                          BoxShadow(
                            color: _C.accentA.withValues(alpha: 0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          ),
                        ],
                ),
                child: Center(
                  child: _isAccepting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEmpty
                                  ? Icons.remove_circle_outline_rounded
                                  : Icons.check_circle_rounded,
                              color: isEmpty ? _C.textSec : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isEmpty
                                  ? 'Select at least 1 parcel'
                                  : 'Accept ${_selectedIndices.length} Parcels & Start',
                              style: TextStyle(
                                color: isEmpty ? _C.textSec : Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
