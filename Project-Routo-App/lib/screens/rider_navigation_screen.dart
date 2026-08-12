import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/directions_service.dart';
import 'home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS  (unchanged from original)
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
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSec = Color(0xFF64748B);
  static Color blueGlow(double a) => accentA.withValues(alpha: a);
  static Color greenGlow(double a) => green.withValues(alpha: a);
}

// ─────────────────────────────────────────────────────────────────────────────
//  DELIVERY STEP ENUM
// ─────────────────────────────────────────────────────────────────────────────
enum _DeliveryStep { initial, headingToPickup, pickedUp, delivered }

// Initial camera centred on India — replaced by real bounds once API responds.
const CameraPosition _kInitialCamera = CameraPosition(
  target: LatLng(20.5937, 78.9629), // centre of India
  zoom: 5.0,
);

// ─────────────────────────────────────────────────────────────────────────────
//  RIDER NAVIGATION SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class RiderNavigationScreen extends StatefulWidget {
  final String parcelId;
  final String pickupAddress;
  final String dropAddress;
  final String earnings;
  final LatLng? pickupLatLng;
  final LatLng? dropLatLng;

  const RiderNavigationScreen({
    super.key,
    required this.parcelId,
    required this.pickupAddress,
    required this.dropAddress,
    required this.earnings,
    this.pickupLatLng,
    this.dropLatLng,
  });

  @override
  State<RiderNavigationScreen> createState() => _RiderNavigationScreenState();
}

class _RiderNavigationScreenState extends State<RiderNavigationScreen>
    with TickerProviderStateMixin {
  // ── Delivery state
  _DeliveryStep _step = _DeliveryStep.initial;
  bool _showDeliveredOverlay = false;

  // ── Flutter animation controllers
  late AnimationController _bgCtrl;
  late AnimationController _progressCtrl;
  late AnimationController _overlayCtrl;
  late AnimationController _btnCtrl;

  late Animation<double> _bgAnim;
  late Animation<double> _progressAnim;
  late Animation<double> _overlayScale;
  late Animation<double> _btnScale;

  // ── Route & Map State
  GoogleMapController? _mapController;
  Timer? _vehicleTimer;

  // Route is empty until the Directions API responds — NO static fallback.
  List<LatLng> _activeRoute = [];
  final List<double> _segmentDistances = [];
  double _totalDistance = 0.0;

  double _phaseT = 0.0;
  int _camTick = 0;
  // Vehicle starts at origin — will be set once route is fetched.
  LatLng _vehiclePos = const LatLng(0, 0);

  // Loading flag — shows spinner on map while API call is in flight.
  bool _isLoadingRoute = true;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _mapCreated = false;
  bool _showMapFallback = false;

  // -- Animation State Extensions
  final double _vehicleRotation = 0.0;
  BitmapDescriptor? _vehicleIcon;

  // ── Lifecycle

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.linear);

    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _progressAnim = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic);

    _overlayCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _overlayScale = CurvedAnimation(parent: _overlayCtrl, curve: Curves.elasticOut);

    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _btnScale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    // Do NOT pre-draw any route — fetch real data immediately.
    _fetchRealRoute();
    _loadVehicleIcon();

    // Set a timeout to show fallback if map fails to load.
    Future.delayed(const Duration(seconds: 8), _triggerMapFallback);
  }

  Future<void> _loadVehicleIcon({bool active = false}) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 64.0; 

    // Dynamic glow based on activity
    final glowPaint = Paint()
      ..color = _C.accentA.withValues(alpha: active ? 0.5 : 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, active ? 14 : 8);
    canvas.drawCircle(const Offset(size / 2, size / 2), active ? 26 : 20, glowPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 12, dotPaint);

    final innerPaint = Paint()
      ..color = _C.accentA
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), 8, innerPaint);

    final img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ImageByteFormat.png);
    if (mounted) {
      setState(() {
        _vehicleIcon = BitmapDescriptor.bytes(data!.buffer.asUint8List());
      });
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _progressCtrl.dispose();
    _overlayCtrl.dispose();
    _btnCtrl.dispose();
    _vehicleTimer?.cancel();
    super.dispose();
  }

  // ── Directions API Integration (via shared DirectionsService) ────────────

  Future<void> _fetchRealRoute() async {
    // Log exactly what is being sent so mismatches are immediately visible.
    debugPrint('[RiderNav] Fetching route:');
    debugPrint('[RiderNav]   origin      = "${widget.pickupAddress}"');
    debugPrint('[RiderNav]   destination = "${widget.dropAddress}"');

    // Clear any previous route state before the new request.
    if (mounted) {
      setState(() {
        _isLoadingRoute = true;
        _activeRoute = [];
        _polylines = {};
        _markers = {};
      });
    }

    // Prioritise LatLng if available for exact routing.
    final origin = widget.pickupLatLng != null
        ? '${widget.pickupLatLng!.latitude},${widget.pickupLatLng!.longitude}'
        : widget.pickupAddress;
    final destination = widget.dropLatLng != null
        ? '${widget.dropLatLng!.latitude},${widget.dropLatLng!.longitude}'
        : widget.dropAddress;

    final result = await DirectionsService.getRoute(
      origin: origin,
      destination: destination,
    );

    if (!mounted) return;

    if (result != null && result.polylinePoints.isNotEmpty) {
      debugPrint('[RiderNav] Route OK — ${result.polylinePoints.length} points, '
          '${result.distanceText}, ${result.durationText}');
      setState(() {
        _isLoadingRoute = false;
        _activeRoute = result.polylinePoints;
        _vehiclePos = _activeRoute.first;
        _calculateDistances();
        _initMapOverlays();
      });
      // Fit camera to the real route bounds (from API, not computed).
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _mapController != null) {
          _fitCameraToRoute(bounds: result.bounds);
        }
      });
    } else {
      debugPrint('[RiderNav] Route fetch failed. Using direct path fallback.');
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
          // Fallback: direct line from pickup to drop
          if (widget.pickupLatLng != null && widget.dropLatLng != null) {
            _activeRoute = [widget.pickupLatLng!, widget.dropLatLng!];
            _vehiclePos = _activeRoute.first;
            _calculateDistances();
            _initMapOverlays();
            
            // Fit camera to fallback bounds
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _mapController != null) {
                final b = LatLngBounds(
                  southwest: LatLng(
                    math.min(widget.pickupLatLng!.latitude, widget.dropLatLng!.latitude),
                    math.min(widget.pickupLatLng!.longitude, widget.dropLatLng!.longitude),
                  ),
                  northeast: LatLng(
                    math.max(widget.pickupLatLng!.latitude, widget.dropLatLng!.latitude),
                    math.max(widget.pickupLatLng!.longitude, widget.dropLatLng!.longitude),
                  ),
                );
                _fitCameraToRoute(bounds: b);
              }
            });
          }
        });
      }
    }
  }

  void _calculateDistances() {
    _segmentDistances.clear();
    _totalDistance = 0.0;
    if (_activeRoute.isEmpty) return;
    for (int i = 0; i < _activeRoute.length - 1; i++) {
      final dLat = _activeRoute[i].latitude - _activeRoute[i + 1].latitude;
      final dLng = _activeRoute[i].longitude - _activeRoute[i + 1].longitude;
      final d = math.sqrt(dLat * dLat + dLng * dLng);
      _segmentDistances.add(d);
      _totalDistance += d;
    }
  }

  // ── Map Configuration

  void _initMapOverlays() {
    if (_activeRoute.isEmpty) return;
    _markers = _buildMarkers(_vehiclePos);
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _activeRoute,
        color: const Color(0xFF3B82F6), // blue matches accentA
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  Set<Marker> _buildMarkers(LatLng vehiclePos) {
    if (_activeRoute.isEmpty) return {};
    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _activeRoute.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: '📦 Pickup'),
      ),
      Marker(
        markerId: const MarkerId('drop'),
        position: _activeRoute.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: '🏁 Delivery'),
      ),
      Marker(
        markerId: const MarkerId('vehicle'),
        position: vehiclePos,
        icon: _vehicleIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        flat: true,
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 5,
      ),
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    debugPrint('[RiderNav] GoogleMap created successfully.');
    setState(() {
      _mapController = controller;
      _mapCreated = true;
    });

    // Only fit camera if the real route is already loaded (API responded
    // before the map widget finished initialising — rare but possible).
    if (_activeRoute.isNotEmpty) {
      Future.delayed(
        const Duration(milliseconds: 300),
        () => _fitCameraToRoute(),
      );
    }
  }

  void _triggerMapFallback() {
    if (!_mapCreated && mounted) {
      debugPrint('[RiderNav] Map load timeout — showing fallback.');
      setState(() => _showMapFallback = true);
    }
  }

  /// Fits the map camera to the route bounds.
  /// If [bounds] is provided (from the API) it is used directly;
  /// otherwise bounds are computed from [_activeRoute] points.
  void _fitCameraToRoute({LatLngBounds? bounds}) {
    if (_mapController == null || _activeRoute.isEmpty) return;
    final b = bounds ?? _computeBoundsFromRoute();
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(b, 56),
    );
  }

  LatLngBounds _computeBoundsFromRoute() {
    final lats = _activeRoute.map((p) => p.latitude);
    final lngs = _activeRoute.map((p) => p.longitude);
    return LatLngBounds(
      southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
      northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
    );
  }

  // ── Vehicle Animation (Smooth, Distance-based)

  void _startVehicleAnimation() {
    _vehicleTimer?.cancel();
    _phaseT = 0.0;
    _camTick = 0;

    // Slower updates: 200ms delay between steps as requested
    _vehicleTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      
      // Slower increment: 0.01 per step for smooth, deliberate movement
      _phaseT = (_phaseT + 0.01).clamp(0.0, 1.0);
      
      final routeT = _mapPhaseToRouteT(_phaseT);
      final newPos = _interpolateRoute(routeT);
      
      setState(() {
        _vehiclePos = newPos;
        _markers = _buildMarkers(newPos);
      });

      if (_phaseT >= 1.0) _vehicleTimer?.cancel();
    });
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * math.pi / 180;
    double lng1 = start.longitude * math.pi / 180;
    double lat2 = end.latitude * math.pi / 180;
    double lng2 = end.longitude * math.pi / 180;

    double dLon = lng2 - lng1;

    double y = math.sin(dLon) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  void _stopVehicleAnimation() {
    _vehicleTimer?.cancel();
  }

  double _mapPhaseToRouteT(double phaseT) {
    switch (_step) {
      case _DeliveryStep.initial:
        return 0.0;
      case _DeliveryStep.headingToPickup:
        return phaseT * 0.46;
      case _DeliveryStep.pickedUp:
        return 0.46 + phaseT * 0.54;
      case _DeliveryStep.delivered:
        return 1.0;
    }
  }

  LatLng _interpolateRoute(double t) {
    if (_activeRoute.isEmpty) return const LatLng(0, 0);
    if (t <= 0.0 || _totalDistance == 0.0) return _activeRoute.first;
    if (t >= 1.0) return _activeRoute.last;

    final targetDist = t * _totalDistance;
    double walked = 0.0;

    for (int i = 0; i < _segmentDistances.length; i++) {
      if (walked + _segmentDistances[i] >= targetDist) {
        final segDist = _segmentDistances[i];
        final segT = segDist == 0 ? 0.0 : ((targetDist - walked) / segDist);
        final from = _activeRoute[i];
        final to = _activeRoute[i + 1];
        return LatLng(
          from.latitude + (to.latitude - from.latitude) * segT,
          from.longitude + (to.longitude - from.longitude) * segT,
        );
      }
      walked += _segmentDistances[i];
    }
    return _activeRoute.last;
  }

  // ── Delivery Step Logic

  double get _progressValue {
    switch (_step) {
      case _DeliveryStep.initial: return 0.0;
      case _DeliveryStep.headingToPickup: return 0.33;
      case _DeliveryStep.pickedUp: return 0.66;
      case _DeliveryStep.delivered: return 1.0;
    }
  }

  String get _etaText {
    if (_step == _DeliveryStep.delivered) return 'Delivered successfully';
    if (_step == _DeliveryStep.initial) return 'Ready to start delivery';
    
    if (_phaseT > 0.92) return 'Almost delivered...';
    if (_phaseT > 0.05) return 'On the way to destination...';
    
    return 'Delivery started...';
  }

  String get _actionLabel {
    switch (_step) {
      case _DeliveryStep.initial: return '🚀  Start Delivery';
      case _DeliveryStep.headingToPickup: return '➡️  Continue';
      case _DeliveryStep.pickedUp: return '✅  Mark as Delivered';
      case _DeliveryStep.delivered: return '🎉  Delivery Complete';
    }
  }

  List<Color> get _actionGradient {
    switch (_step) {
      case _DeliveryStep.initial: return [_C.accentA, _C.accentC];
      case _DeliveryStep.headingToPickup: return [_C.accentB, const Color(0xFFEF4444)];
      case _DeliveryStep.pickedUp: return [const Color(0xFF059669), _C.green];
      case _DeliveryStep.delivered: return [const Color(0xFF059669), _C.green];
    }
  }

  Future<void> _advanceStep() async {
    if (_step == _DeliveryStep.delivered) return;
    HapticFeedback.mediumImpact();

    await _btnCtrl.forward();
    await _btnCtrl.reverse();

    setState(() {
      switch (_step) {
        case _DeliveryStep.initial:
          _step = _DeliveryStep.headingToPickup;
          _loadVehicleIcon(active: true); // Update icon to glowing/active state
          break;
        case _DeliveryStep.headingToPickup:
          _step = _DeliveryStep.pickedUp;
          break;
        case _DeliveryStep.pickedUp:
          _step = _DeliveryStep.delivered;
          _showDeliveredOverlay = true;
          _loadVehicleIcon(active: false); // Reset icon
          break;
        case _DeliveryStep.delivered:
          break;
      }
    });

    _progressCtrl.animateTo(_progressValue,
        duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic);

    if (_step == _DeliveryStep.headingToPickup || _step == _DeliveryStep.pickedUp) {
      _startVehicleAnimation();
    } else if (_step == _DeliveryStep.delivered) {
      _stopVehicleAnimation();

      setState(() {
        if (_activeRoute.isNotEmpty) {
          _vehiclePos = _activeRoute.last;
          _markers = _buildMarkers(_activeRoute.last);
        }
      });

      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      _overlayCtrl.forward();
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a, b) => const HomeScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  // ── Build Widget Tree ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg1,
      body: Stack(children: [
        _buildBackground(),
        SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildMapArea()),
              _buildBottomPanel(),
            ],
          ),
        ),
        if (_showDeliveredOverlay) _buildDeliveredOverlay(),
      ]),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (_, __) {
        const pi = math.pi;
        final t = _bgAnim.value * 2 * pi;
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
              y: 0.25 + 0.05 * math.sin(t),
              size: 280,
              color: _C.accentA.withValues(alpha: 0.07)),
          _orb(
              x: 0.80 + 0.05 * math.cos(t + 2.1),
              y: 0.55 + 0.06 * math.sin(t + 2.1),
              size: 220,
              color: _C.accentB.withValues(alpha: 0.06)),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _C.glass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.glassBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _C.glass,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.glassBorder),
                ),
                child: Row(children: [
                  const Icon(Icons.navigation_rounded, color: _C.accentA, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _step == _DeliveryStep.pickedUp || _step == _DeliveryStep.delivered
                          ? widget.dropAddress
                          : widget.pickupAddress,
                      style: const TextStyle(
                          color: _C.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _C.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.green.withValues(alpha: 0.35)),
          ),
          child: Text(widget.earnings,
              style: const TextStyle(
                  color: _C.green, fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Widget _buildMapArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.glassBorder),
            color: const Color(0xFF0F172A),
          ),
          child: Stack(
            children: [
              if (_showMapFallback)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map_rounded, color: _C.textSec, size: 42),
                      const SizedBox(height: 14),
                      Text(
                        'Map loading failed.\nPlease check your connection\nor API key configuration.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _C.textSec.withValues(alpha: 0.7), fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: _kInitialCamera,
                    markers: _markers,
                    polylines: _polylines,
                    onMapCreated: _onMapCreated,
                    style: _kDarkMapStyle,
                    mapType: MapType.normal,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    rotateGesturesEnabled: !kIsWeb,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                  ),
                ),
              // ── Loading overlay while Directions API call is in flight ──
              if (_isLoadingRoute)
                Positioned.fill(
                  child: Container(
                    color: const Color(0xCC0F172A),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Fetching route…',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.60),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: _buildStepBadgesRow(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBadgesRow() {
    return Row(children: [
      _stepBadge('1', 'Start', _C.accentA, _step.index >= 1),
      const SizedBox(width: 8),
      _stepConnector(),
      const SizedBox(width: 8),
      _stepBadge('2', 'On the way', _C.accentC, _step.index >= 2),
      const SizedBox(width: 8),
      _stepConnector(),
      const SizedBox(width: 8),
      _stepBadge('3', 'Delivered', _C.green, _step.index >= 3),
    ]);
  }

  Widget _stepBadge(String num, String label, Color color, bool active) {
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color : _C.surfaceEl,
          border: Border.all(color: active ? color : _C.glassBorder, width: active ? 2 : 1),
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1)]
              : [],
        ),
        child: Center(
          child: active
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : Text(num,
                  style: const TextStyle(
                      color: _C.textSec, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              color: active ? color : _C.textSec, fontSize: 9, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _stepConnector() {
    return Expanded(
      child: Container(
        height: 1.5,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_C.accentA, _C.accentC]),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  const Icon(Icons.info_outline_rounded, color: _C.accentA, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                      child: Text(
                        _etaText,
                        key: ValueKey(_etaText),
                        style: const TextStyle(
                            color: _C.textSec, fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, __) {
                    final val = _progressAnim.value == 0.0 ? _progressValue : _progressAnim.value;
                    return Column(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: val,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _step == _DeliveryStep.delivered ? _C.green : _C.accentA,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Start',
                              style: TextStyle(
                                  color: _C.textSec, fontSize: 10.5, fontWeight: FontWeight.w500)),
                          Text('On the way',
                              style: TextStyle(
                                  color: _C.textSec, fontSize: 10.5, fontWeight: FontWeight.w500)),
                          Text('Delivered',
                              style: TextStyle(
                                  color: _C.green, fontSize: 10.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ]);
                  },
                ),
                const SizedBox(height: 16),
                ScaleTransition(
                  scale: _btnScale,
                  child: GestureDetector(
                    onTap: _step == _DeliveryStep.delivered ? null : _advanceStep,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: _actionGradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: _actionGradient.first.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Center(
                        child: Text(_actionLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2)),
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

  Widget _buildDeliveredOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: Colors.black.withValues(alpha: 0.75),
          child: Center(
            child: ScaleTransition(
              scale: _overlayScale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1C35),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _C.green.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(color: _C.greenGlow(0.3), blurRadius: 60, spreadRadius: 4),
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
                            color: _C.greenGlow(0.35), blurRadius: 28, spreadRadius: 2)
                      ],
                    ),
                    child: const Text('🎉', style: TextStyle(fontSize: 42)),
                  ),
                  const SizedBox(height: 22),
                  const Text('Parcel Delivered!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 8),
                  Text(
                    'Great job! You\'ve successfully delivered\n${widget.parcelId} to the recipient.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5), fontSize: 13.5, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF064E3B), Color(0xFF065F46)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _C.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.currency_rupee_rounded, color: _C.green, size: 20),
                      const SizedBox(width: 6),
                      Text('You earned ${widget.earnings}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _goHome,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(colors: [_C.accentA, _C.accentB]),
                        boxShadow: [
                          BoxShadow(
                              color: _C.blueGlow(0.4), blurRadius: 16, offset: const Offset(0, 6))
                        ],
                      ),
                      child: const Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.home_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Back to Home',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        ]),
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  DARK MAP STYLE JSON
// ─────────────────────────────────────────────────────────────────────────────
const String _kDarkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#0f172a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#64748b"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0f172a"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1e293b"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#0f172a"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#334155"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1e293b"}]},
  {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0c1f3f"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#1e3a5f"}]}
]''';
