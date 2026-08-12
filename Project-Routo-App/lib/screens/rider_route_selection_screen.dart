import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/directions_service.dart';
import 'rider_available_parcels_screen.dart';

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
  // blueGlow / greenGlow unused in this screen — omitted to keep _C clean
  static Color orangeGlow(double a) => accentB.withValues(alpha: a);
}

// ─────────────────────────────────────────────────────────────────────────────
//  RIDER ROUTE SELECTION SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class RiderRouteSelectionScreen extends StatefulWidget {
  const RiderRouteSelectionScreen({super.key});

  @override
  State<RiderRouteSelectionScreen> createState() =>
      _RiderRouteSelectionScreenState();
}

class _RiderRouteSelectionScreenState extends State<RiderRouteSelectionScreen>
    with TickerProviderStateMixin {
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _startFocus = FocusNode();
  final _endFocus = FocusNode();

  bool _isFetchingGps = false;
  bool _routeReady = false;
  bool _isSearching = false;

  String? _startError;
  String? _endError;

  // ── Real map state ──────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isFetchingRoute = false;
  String _distanceText = '–';
  String _durationText = '–';
  bool _routeApiLoaded = false;

  // Debounce timer — prevents API call on every keystroke.
  Timer? _debounceTimer;

  late AnimationController _bgCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 16))
      ..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.linear);

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();

    for (final fn in [_startFocus, _endFocus]) {
      fn.addListener(() => setState(() {}));
    }
    _startCtrl.addListener(_onFieldChanged);
    _endCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final ready = _startCtrl.text.trim().isNotEmpty &&
        _endCtrl.text.trim().isNotEmpty;

    // Update the ready flag immediately for UI purposes.
    if (ready != _routeReady) {
      setState(() => _routeReady = ready);
    }

    // Debounce: wait 800ms after the user stops typing before hitting the API.
    _debounceTimer?.cancel();
    if (ready) {
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        debugPrint('[RouteSelection] Debounced fetch: '
            '"${_startCtrl.text.trim()}" → "${_endCtrl.text.trim()}"');
        _fetchRoutePreview();
      });
    } else {
      // Both fields not filled — clear the map.
      setState(() {
        _polylines = {};
        _markers = {};
        _routeApiLoaded = false;
        _distanceText = '–';
        _durationText = '–';
      });
    }
  }

  // ── Fetch real route for map preview ────────────────────────────────────
  LatLngBounds? _currentBounds;

  Future<void> _fetchRoutePreview() async {
    if (_isFetchingRoute) return;
    
    final originText = _startCtrl.text.trim();
    final destText = _endCtrl.text.trim();
    
    if (originText.isEmpty || destText.isEmpty) {
      setState(() {
        _polylines = {};
        _markers = {};
        _currentBounds = null;
        _routeApiLoaded = false;
      });
      return;
    }

    setState(() {
      _isFetchingRoute = true;
      _routeApiLoaded = false;
      _polylines = {};
      _markers = {};
    });

    final result = await DirectionsService.getRoute(
      origin: originText,
      destination: destText,
    );

    if (!mounted) return;

    if (result != null && result.polylinePoints.isNotEmpty) {
      setState(() {
        _isFetchingRoute = false;
        _routeApiLoaded = true;
        _distanceText = result.distanceText;
        _durationText = result.durationText;
        _currentBounds = result.bounds;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('preview_route'),
            points: result.polylinePoints,
            color: const Color(0xFF3B82F6),
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        };
        _markers = {
          Marker(
            markerId: const MarkerId('origin'),
            position: result.polylinePoints.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(title: originText.split(',').first),
          ),
          Marker(
            markerId: const MarkerId('dest'),
            position: result.polylinePoints.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(title: destText.split(',').first),
          ),
        };
      });
      
      // Animate camera to fit the full route
      if (_mapController != null && _currentBounds != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(_currentBounds!, 48),
        );
      }
    } else {
      setState(() {
        _isFetchingRoute = false;
        _distanceText = '–';
        _durationText = '–';
        _currentBounds = null;
      });
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _debounceTimer?.cancel();
    _mapController?.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _startFocus.dispose();
    _endFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchGps() async {
    setState(() => _isFetchingGps = true);
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isFetchingGps = false;
        _startCtrl.text = 'Pune, Maharashtra';
        _startError = null;
      });
    }
  }

  bool _validate() {
    setState(() {
      _startError = _startCtrl.text.trim().isEmpty
          ? 'Enter your start location'
          : null;
      _endError = _endCtrl.text.trim().isEmpty
          ? 'Enter your destination'
          : null;
    });
    return _startError == null && _endError == null;
  }

  Future<void> _findParcels() async {
    if (!_validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSearching = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() => _isSearching = false);
      Navigator.of(context).push(_slideRoute(RiderAvailableParcelsScreen(
        fromLocation: _startCtrl.text,
        toLocation: _endCtrl.text,
      )));
    }
  }

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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildHeroHeader(),
                    const SizedBox(height: 24),
                    _buildMapPreview(),
                    const SizedBox(height: 20),
                    _buildRouteCard(),
                    const SizedBox(height: 16),
                    if (_routeReady) _buildRouteInfoChips(),
                    const SizedBox(height: 24),
                    _buildFindButton(),
                    const SizedBox(height: 16),
                    _buildTipsCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
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
              color: _C.accentB.withValues(alpha: 0.08)),
          _orb(
              x: 0.82 + 0.05 * math.cos(t + 2.0),
              y: 0.32 + 0.06 * math.sin(t + 2.0),
              size: 200,
              color: _C.accentA.withValues(alpha: 0.07)),
          _orb(
              x: 0.45 + 0.06 * math.cos(t + 4.1),
              y: 0.72 + 0.04 * math.sin(t + 4.1),
              size: 170,
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
            gradient: RadialGradient(colors: [color, Colors.transparent]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Row(children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [_C.accentB, _C.red],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: _C.orangeGlow(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: const Center(child: Text('🚚', style: TextStyle(fontSize: 24))),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_C.textPrimary, Color(0xFFFED7AA)],
            ).createShader(b),
            child: const Text('Select Your Route',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 3),
          const Text('Enter route to find parcels along the way',
              style: TextStyle(
                  fontSize: 13,
                  color: _C.textSec,
                  fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    ]);
  }

  Widget _buildMapPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.glassBorder),
          color: const Color(0xFF0F172A),
        ),
        child: Stack(
          children: [
            // ── Placeholder shown before both fields are filled ──
            if (!_routeReady)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined,
                        color: _C.textSec.withValues(alpha: 0.5), size: 38),
                    const SizedBox(height: 10),
                    Text(
                      'Enter both locations\nto preview route',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _C.textSec.withValues(alpha: 0.6),
                          fontSize: 12.5,
                          height: 1.5),
                    ),
                  ],
                ),
              )
            else
              // ── Real Google Map ──
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(18.9, 73.3), // centre of Maharashtra
                    zoom: 7,
                  ),
                  onMapCreated: (c) {
                    _mapController = c;
                    // If route already fetched, fit camera now using stored bounds
                    if (_currentBounds != null) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (_mapController != null && _currentBounds != null) {
                          _mapController!.animateCamera(
                            CameraUpdate.newLatLngBounds(_currentBounds!, 48),
                          );
                        }
                      });
                    }
                  },
                  polylines: _polylines,
                  markers: _markers,
                  style: _kDarkMapStylePreview,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  rotateGesturesEnabled: !kIsWeb,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                ),
              ),
            // ── Loading spinner overlay ──
            if (_isFetchingRoute)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x880F172A),
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Color(0xFF3B82F6)),
                  ),
                ),
              ),
            // ── "Route Active" badge ──
            if (_routeApiLoaded && !_isFetchingRoute)
              Positioned(
                top: 10,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.green.withValues(alpha: 0.45)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 7,
                        height: 7,
                        decoration:
                            const BoxDecoration(shape: BoxShape.circle, color: _C.green)),
                    const SizedBox(width: 6),
                    const Text('Route Active',
                        style: TextStyle(
                            color: _C.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.glassBorder),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _C.accentA.withValues(alpha: 0.07),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.accentA.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.accentA.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.route_rounded,
                    color: _C.accentA, size: 16),
              ),
              const SizedBox(width: 12),
              const Text('Your Route',
                  style: TextStyle(
                      color: _C.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 20),
            _buildLocationInput(
              controller: _startCtrl,
              focusNode: _startFocus,
              label: 'START LOCATION',
              hint: 'Where are you starting from?',
              icon: Icons.radio_button_checked_rounded,
              focusColor: _C.accentA,
              error: _startError,
              suffix: _isFetchingGps
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _C.accentA),
                    )
                  : GestureDetector(
                      onTap: _fetchGps,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_C.accentA, _C.accentC]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
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
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 6, bottom: 6),
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
            _buildLocationInput(
              controller: _endCtrl,
              focusNode: _endFocus,
              label: 'DESTINATION',
              hint: 'Where are you going?',
              icon: Icons.location_on_rounded,
              focusColor: _C.accentB,
              error: _endError,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required Color focusColor,
    String? error,
    Widget? suffix,
  }) {
    final focused = focusNode.hasFocus;
    final hasError = error != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          color: focused ? focusColor : _C.textSec,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        child: Text(label),
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
                    ? focusColor.withValues(alpha: 0.6)
                    : _C.glassBorder,
            width: focused ? 1.5 : 1.0,
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                      color: focusColor.withValues(alpha: 0.2),
                      blurRadius: 16)
                ]
              : [],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(
              color: _C.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: _C.textSec.withValues(alpha: 0.6), fontSize: 13.5),
            prefixIcon: Icon(icon,
                color: focused ? focusColor : _C.textSec, size: 18),
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
            Text(error,
                style: const TextStyle(
                    color: _C.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
    ]);
  }

  Widget _buildRouteInfoChips() {
    return AnimatedOpacity(
      opacity: _routeReady ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Row(children: [
        _infoChip(Icons.straighten_rounded,
            _routeApiLoaded ? _distanceText : '…', _C.accentA),
        const SizedBox(width: 10),
        _infoChip(Icons.access_time_rounded,
            _routeApiLoaded ? _durationText : '…', _C.accentC),
        const SizedBox(width: 10),
        _infoChip(Icons.local_gas_station_rounded, '~₹180', _C.accentB),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _buildFindButton() {
    return GestureDetector(
      onTap: _isSearching ? null : _findParcels,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [_C.accentB, Color(0xFFEF4444)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
                color: _C.orangeGlow(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: _isSearching
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Find Parcels on this Route',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2)),
                ]),
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.glassBorder),
            color: _C.glass,
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('💡', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'The more specific your route, the better parcel matches you\'ll find along the way.',
                style: TextStyle(
                    color: _C.textSec,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    height: 1.5),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DARK MAP STYLE (preview) — matches the navigation screen palette
// ─────────────────────────────────────────────────────────────────────────────
const String _kDarkMapStylePreview = '''[
  {"elementType":"geometry","stylers":[{"color":"#0f172a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#64748b"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0f172a"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1e293b"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#334155"}]},
  {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0c1f3f"}]}
]''';


// ─────────────────────────────────────────────────────────────────────────────
//  SLIDE ROUTE HELPER
// ─────────────────────────────────────────────────────────────────────────────
PageRouteBuilder<T> _slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position:
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
