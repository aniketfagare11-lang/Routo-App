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
  static const red        = Color(0xFFEF4444);
  static const textSec    = Color(0xFF64748B);
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _Address {
  String label;
  String address;
  String city;
  String taluka;
  String district;
  String state;
  String pincode;
  bool   isDefault;
  IconData icon;
  Color    color;

  _Address({
    required this.label,
    required this.address,
    required this.city,
    required this.taluka,
    required this.district,
    required this.state,
    required this.pincode,
    this.isDefault = false,
    required this.icon,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  SAVED ADDRESSES SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgCtrl;
  late Animation<double>   _bgAnim;

  final List<_Address> _addresses = [
    _Address(
      label: 'Home', address: 'Flat 4B, Shivaji Nagar', city: 'Mumbai',
      taluka: 'Andheri', district: 'Mumbai Suburban', state: 'Maharashtra',
      pincode: '400058', isDefault: true, icon: Icons.home_rounded, color: _C.accentA,
    ),
    _Address(
      label: 'Work', address: '10th Floor, Tech Park, MIDC', city: 'Pune',
      taluka: 'Hinjewadi', district: 'Pune', state: 'Maharashtra',
      pincode: '411057', icon: Icons.work_rounded, color: _C.accentC,
    ),
    _Address(
      label: 'Parents', address: '22, Gandhi Chowk, Main Road', city: 'Nashik',
      taluka: 'Nashik Road', district: 'Nashik', state: 'Maharashtra',
      pincode: '422101', icon: Icons.location_on_rounded, color: _C.accentB,
    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg1,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFAB(context),
      body: Stack(children: [
        _buildBackground(),
        SafeArea(
          child: _addresses.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _buildAddressCard(context, i),
                ),
        ),
      ]),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.location_off_rounded, size: 64, color: _C.textSec.withValues(alpha: 0.4)),
    const SizedBox(height: 16),
    Text('No saved addresses', style: TextStyle(color: _C.textSec.withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Text('Tap + to add your first address', style: TextStyle(color: _C.textSec.withValues(alpha: 0.4), fontSize: 13)),
  ]));

  // ── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFAB(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(colors: [_C.accentA, _C.accentB]),
      boxShadow: [BoxShadow(color: _C.accentA.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: FloatingActionButton.extended(
      onPressed: () => _showAddressSheet(context, null),
      backgroundColor: Colors.transparent,
      elevation: 0, highlightElevation: 0,
      icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
      label: const Text('Add Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
    ),
  );

  // ── App Bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
    leading: _iconBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.of(context).pop()),
    title: const Text('Saved Addresses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
    actions: [
      _iconBtn(Icons.home_rounded, () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false)),
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

  // ── Address Card ───────────────────────────────────────────────────────────
  Widget _buildAddressCard(BuildContext context, int idx) {
    final a = _addresses[idx];
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: _C.glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: a.isDefault ? a.color.withValues(alpha: 0.4) : _C.glassBorder),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: a.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(a.icon, color: a.color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(a.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                if (a.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _C.accentB.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Text('DEFAULT', style: TextStyle(color: _C.accentB, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ],
              ]),
              const SizedBox(height: 6),
              Text(a.address, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('${a.city}, ${a.district}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              const SizedBox(height: 2),
              Text('${a.state} - ${a.pincode}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            ])),
            _popMenu(context, idx),
          ]),
        ),
      ),
    );
  }

  Widget _popMenu(BuildContext context, int idx) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.more_vert_rounded, color: _C.textSec, size: 18),
      ),
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _C.glassBorder)),
      onSelected: (val) {
        if (val == 'edit')    { _showAddressSheet(context, idx); }
        if (val == 'default') { setState(() { for (final a in _addresses) { a.isDefault = false; } _addresses[idx].isDefault = true; }); }
        if (val == 'delete')  { setState(() => _addresses.removeAt(idx)); }
      },
      itemBuilder: (_) => [
        _popItem('edit',    Icons.edit_rounded,          'Edit',           _C.accentA),
        _popItem('default', Icons.star_rounded,          'Set as Default', _C.accentB),
        _popItem('delete',  Icons.delete_outline_rounded,'Delete',         _C.red),
      ],
    );
  }

  PopupMenuItem<String> _popItem(String val, IconData icon, String label, Color color) =>
      PopupMenuItem(
        value: val,
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]),
      );

  // ── Add / Edit Bottom Sheet ────────────────────────────────────────────────
  void _showAddressSheet(BuildContext context, int? editIdx) {
    final isEdit = editIdx != null;
    final src    = isEdit ? _addresses[editIdx] : null;

    final labelCtrl    = TextEditingController(text: src?.label ?? '');
    final addressCtrl  = TextEditingController(text: src?.address ?? '');
    final cityCtrl     = TextEditingController(text: src?.city ?? '');
    final talukaCtrl   = TextEditingController(text: src?.taluka ?? '');
    final districtCtrl = TextEditingController(text: src?.district ?? '');
    final stateCtrl    = TextEditingController(text: src?.state ?? 'Maharashtra');
    final pincodeCtrl  = TextEditingController(text: src?.pincode ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheetState) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: Color(0x20FFFFFF))),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text(isEdit ? 'Edit Address' : 'Add New Address',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  _sheetField(labelCtrl,    'Label (Home / Work)',   Icons.label_rounded,            _C.accentA),
                  const SizedBox(height: 12),
                  _sheetField(addressCtrl,  'Address Line',          Icons.location_on_outlined,     _C.accentB),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _sheetField(cityCtrl,    'City',    Icons.location_city_rounded, _C.accentC)),
                    const SizedBox(width: 12),
                    Expanded(child: _sheetField(talukaCtrl,  'Taluka',  Icons.map_outlined,          _C.accentA)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _sheetField(districtCtrl, 'District', Icons.domain_rounded,    _C.accentB)),
                    const SizedBox(width: 12),
                    Expanded(child: _sheetField(stateCtrl,    'State',    Icons.flag_outlined,     _C.accentC)),
                  ]),
                  const SizedBox(height: 12),
                  _sheetField(pincodeCtrl, 'Pincode', Icons.pin_drop_rounded, _C.green, kt: TextInputType.number),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        final newAddr = _Address(
                          label: labelCtrl.text.isEmpty ? 'Address' : labelCtrl.text,
                          address: addressCtrl.text,
                          city: cityCtrl.text,
                          taluka: talukaCtrl.text,
                          district: districtCtrl.text,
                          state: stateCtrl.text,
                          pincode: pincodeCtrl.text,
                          icon: Icons.location_on_rounded,
                          color: _C.accentA,
                        );
                        if (isEdit) {
                          _addresses[editIdx] = newAddr;
                          _addresses[editIdx].isDefault = src?.isDefault ?? false;
                        } else {
                          _addresses.add(newAddr);
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity, height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(colors: [_C.accentA, _C.accentB]),
                        boxShadow: [BoxShadow(color: _C.accentA.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Center(child: Text(isEdit ? 'Save Changes' : 'Add Address',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String hint, IconData icon, Color color, {TextInputType kt = TextInputType.text}) =>
      Container(
        decoration: BoxDecoration(color: _C.surfaceEl, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.glassBorder)),
        child: TextField(
          controller: ctrl,
          keyboardType: kt,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color, size: 16),
            hintText: hint,
            hintStyle: TextStyle(color: _C.textSec.withValues(alpha: 0.6), fontSize: 12),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );

  // ── Background ─────────────────────────────────────────────────────────────
  Widget _buildBackground() => AnimatedBuilder(
    animation: _bgAnim,
    builder: (_, __) {
      final t = _bgAnim.value * 2 * math.pi;
      return Stack(children: [
        Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF020617), Color(0xFF0C1220)]))),
        _orb(0.15 + 0.05 * math.cos(t),       0.12 + 0.06 * math.sin(t),       270, _C.accentA.withValues(alpha: 0.08)),
        _orb(0.82 + 0.06 * math.cos(t + 2.1), 0.38 + 0.08 * math.sin(t + 2.1), 220, _C.accentB.withValues(alpha: 0.07)),
        _orb(0.52 + 0.07 * math.cos(t + 4.2), 0.75 + 0.05 * math.sin(t + 4.2), 180, _C.accentC.withValues(alpha: 0.06)),
      ]);
    },
  );

  Widget _orb(double x, double y, double size, Color color) => Positioned.fill(
    child: Align(alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])))),
  );
}
