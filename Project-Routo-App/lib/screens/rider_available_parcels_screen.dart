import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'rider_order_details_screen.dart';

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
  static Color greenGlow(double a) => green.withValues(alpha: a);
}

// ─────────────────────────────────────────────────────────────────────────────
//  GEO COORDINATE — simple lat/lng pair
// ─────────────────────────────────────────────────────────────────────────────
class _LatLng {
  final double lat;
  final double lng;
  const _LatLng(this.lat, this.lng);
}

// ─────────────────────────────────────────────────────────────────────────────
//  CITY COORDINATE DATABASE
//  Covers major Maharashtra / India cities used on common routes.
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, _LatLng> _cityCoords = {
  // Maharashtra
  'pune': _LatLng(18.5204, 73.8567),
  'mumbai': _LatLng(19.0760, 72.8777),
  'navi mumbai': _LatLng(19.0330, 73.0297),
  'thane': _LatLng(19.2183, 72.9781),
  'kolhapur': _LatLng(16.7050, 74.2433),
  'satara': _LatLng(17.6805, 73.9989),
  'karad': _LatLng(17.2881, 74.1833),
  'sangli': _LatLng(16.8524, 74.5815),
  'miraj': _LatLng(16.8243, 74.6456),
  'solapur': _LatLng(17.6599, 75.9064),
  'nashik': _LatLng(19.9975, 73.7898),
  'aurangabad': _LatLng(19.8762, 75.3433),
  'nagpur': _LatLng(21.1458, 79.0882),
  'lonavala': _LatLng(18.7481, 73.4072),
  'khandala': _LatLng(18.7580, 73.3823),
  'khopoli': _LatLng(18.7833, 73.3407),
  'panvel': _LatLng(18.9894, 73.1175),
  'ratnagiri': _LatLng(16.9944, 73.3000),
  'amravati': _LatLng(20.9374, 77.7796),
  'latur': _LatLng(18.4088, 76.5604),
  'osmanabad': _LatLng(18.1834, 76.0450),
  'ahmednagar': _LatLng(19.0952, 74.7496),
  'jalgaon': _LatLng(21.0077, 75.5626),
  'dhule': _LatLng(20.9042, 74.7749),
  'nanded': _LatLng(19.1383, 77.3210),
  'wardha': _LatLng(20.7452, 78.6022),
  'yavatmal': _LatLng(20.3888, 78.1204),
  // Other major cities
  'delhi': _LatLng(28.7041, 77.1025),
  'bangalore': _LatLng(12.9716, 77.5946),
  'hyderabad': _LatLng(17.3850, 78.4867),
  'chennai': _LatLng(13.0827, 80.2707),
  'kolkata': _LatLng(22.5726, 88.3639),
  'ahmedabad': _LatLng(23.0225, 72.5714),
  'surat': _LatLng(21.1702, 72.8311),
  'jaipur': _LatLng(26.9124, 75.7873),
  'indore': _LatLng(22.7196, 75.8577),
  'bhopal': _LatLng(23.2599, 77.4126),
  'goa': _LatLng(15.2993, 74.1240),
};

// ─────────────────────────────────────────────────────────────────────────────
//  ROUTE FILTERING ENGINE
// ─────────────────────────────────────────────────────────────────────────────

/// Haversine distance between two coordinates, in km.
double _distanceKm(_LatLng a, _LatLng b) {
  const r = 6371.0;
  final dLat = _toRad(b.lat - a.lat);
  final dLng = _toRad(b.lng - a.lng);
  final sinDLat = math.sin(dLat / 2);
  final sinDLng = math.sin(dLng / 2);
  final h = sinDLat * sinDLat +
      math.cos(_toRad(a.lat)) * math.cos(_toRad(b.lat)) * sinDLng * sinDLng;
  return 2 * r * math.asin(math.sqrt(h));
}

double _toRad(double deg) => deg * math.pi / 180.0;

/// Bearing (degrees, 0–360) from [a] to [b].
double _bearing(_LatLng a, _LatLng b) {
  final dLng = _toRad(b.lng - a.lng);
  final lat1 = _toRad(a.lat);
  final lat2 = _toRad(b.lat);
  final y = math.sin(dLng) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180.0 / math.pi + 360) % 360;
}

/// Shortest angular difference between two bearings.
double _bearingDiff(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

/// Perpendicular distance (km) from point [p] to the segment [start]→[end].
double _perpDistanceKm(_LatLng start, _LatLng end, _LatLng p) {
  final totalDist = _distanceKm(start, end);
  if (totalDist < 0.001) return _distanceKm(start, p);
  // Project p onto the line segment using dot product in flat-earth approx
  final ax = end.lng - start.lng;
  final ay = end.lat - start.lat;
  final bx = p.lng - start.lng;
  final by = p.lat - start.lat;
  final t = ((ax * bx + ay * by) / (ax * ax + ay * ay)).clamp(0.0, 1.0);
  final closestLat = start.lat + t * ay;
  final closestLng = start.lng + t * ax;
  return _distanceKm(p, _LatLng(closestLat, closestLng));
}

/// Resolve a freeform location string to a city key (lowercase).
/// Tries exact match, then partial match.
String? _resolveCity(String location) {
  final norm = location.toLowerCase().trim();
  // Exact match
  if (_cityCoords.containsKey(norm)) return norm;
  // Partial match — location string may be like "Koregaon Park, Pune"
  for (final key in _cityCoords.keys) {
    if (norm.contains(key)) return key;
  }
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
//  PARCEL DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _ParcelListing {
  final String id;
  final String pickupCity;       // display name (Title Case)
  final String pickupCityKey;    // lowercase key into _cityCoords
  final String dropCity;
  final String dropCityKey;
  final String pickupAddress;
  final String dropAddress;
  final String parcelType;
  final String parcelEmoji;
  final String weight;
  final double earningsRaw;      // numeric ₹ value for sorting
  final Color typeColor;
  // Computed after filtering
  double deviationKm = 0;
  bool rejected = false;

  _ParcelListing({
    required this.id,
    required this.pickupCity,
    required this.pickupCityKey,
    required this.dropCity,
    required this.dropCityKey,
    required this.pickupAddress,
    required this.dropAddress,
    required this.parcelType,
    required this.parcelEmoji,
    required this.weight,
    required this.earningsRaw,
    required this.typeColor,
  });

  String get earnings => '₹${earningsRaw.toStringAsFixed(0)}';
  String get deviation => '+${deviationKm.toStringAsFixed(1)} km';
}

// ─────────────────────────────────────────────────────────────────────────────
//  GLOBAL PARCEL POOL
//  Covers many route combinations. Filtering happens dynamically.
// ─────────────────────────────────────────────────────────────────────────────
final List<_ParcelListing> _parcelPool = [
  // ── Pune → Mumbai corridor ──
  _ParcelListing(id: 'PKG-001', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Mumbai', dropCityKey: 'mumbai',
      pickupAddress: 'Koregaon Park, Pune', dropAddress: 'Bandra West, Mumbai',
      parcelType: 'Package', parcelEmoji: '📦', weight: '2.5 kg',
      earningsRaw: 180, typeColor: const Color(0xFF3B82F6)),
  _ParcelListing(id: 'PKG-002', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Mumbai', dropCityKey: 'mumbai',
      pickupAddress: 'Viman Nagar, Pune', dropAddress: 'Andheri East, Mumbai',
      parcelType: 'Documents', parcelEmoji: '📄', weight: '0.5 kg',
      earningsRaw: 90, typeColor: const Color(0xFF06B6D4)),
  _ParcelListing(id: 'PKG-003', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Navi Mumbai', dropCityKey: 'navi mumbai',
      pickupAddress: 'Hinjewadi, Pune', dropAddress: 'Vashi, Navi Mumbai',
      parcelType: 'Electronics', parcelEmoji: '💻', weight: '1.2 kg',
      earningsRaw: 220, typeColor: const Color(0xFF8B5CF6)),
  _ParcelListing(id: 'PKG-004', pickupCity: 'Lonavala', pickupCityKey: 'lonavala',
      dropCity: 'Mumbai', dropCityKey: 'mumbai',
      pickupAddress: 'Lonavala Station Road', dropAddress: 'Dadar, Mumbai',
      parcelType: 'Fragile', parcelEmoji: '🫙', weight: '3.0 kg',
      earningsRaw: 260, typeColor: const Color(0xFFF97316)),
  _ParcelListing(id: 'PKG-005', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Mumbai', dropCityKey: 'mumbai',
      pickupAddress: 'Kothrud, Pune', dropAddress: 'Kurla, Mumbai',
      parcelType: 'Package', parcelEmoji: '📦', weight: '4.8 kg',
      earningsRaw: 350, typeColor: const Color(0xFF10B981)),
  _ParcelListing(id: 'PKG-006', pickupCity: 'Khopoli', pickupCityKey: 'khopoli',
      dropCity: 'Thane', dropCityKey: 'thane',
      pickupAddress: 'Khopoli MIDC', dropAddress: 'Thane Station Road',
      parcelType: 'Documents', parcelEmoji: '📄', weight: '0.3 kg',
      earningsRaw: 70, typeColor: const Color(0xFF06B6D4)),
  _ParcelListing(id: 'PKG-007', pickupCity: 'Panvel', pickupCityKey: 'panvel',
      dropCity: 'Mumbai', dropCityKey: 'mumbai',
      pickupAddress: 'Panvel Bus Stand', dropAddress: 'CST Mumbai',
      parcelType: 'Package', parcelEmoji: '📦', weight: '1.8 kg',
      earningsRaw: 130, typeColor: const Color(0xFF3B82F6)),

  // ── Pune → Kolhapur corridor ──
  _ParcelListing(id: 'PKG-011', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Satara', dropCityKey: 'satara',
      pickupAddress: 'Swargate, Pune', dropAddress: 'Satara Bus Stand',
      parcelType: 'Package', parcelEmoji: '📦', weight: '3.0 kg',
      earningsRaw: 170, typeColor: const Color(0xFF3B82F6)),
  _ParcelListing(id: 'PKG-012', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Karad', dropCityKey: 'karad',
      pickupAddress: 'Shivajinagar, Pune', dropAddress: 'Karad APMC',
      parcelType: 'Documents', parcelEmoji: '📄', weight: '0.8 kg',
      earningsRaw: 210, typeColor: const Color(0xFF06B6D4)),
  _ParcelListing(id: 'PKG-013', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Kolhapur', dropCityKey: 'kolhapur',
      pickupAddress: 'Hadapsar, Pune', dropAddress: 'Kolhapur Central',
      parcelType: 'Electronics', parcelEmoji: '💻', weight: '2.1 kg',
      earningsRaw: 380, typeColor: const Color(0xFF8B5CF6)),
  _ParcelListing(id: 'PKG-014', pickupCity: 'Satara', pickupCityKey: 'satara',
      dropCity: 'Kolhapur', dropCityKey: 'kolhapur',
      pickupAddress: 'Satara Market Yard', dropAddress: 'Kolhapur Bazar',
      parcelType: 'Fragile', parcelEmoji: '🫙', weight: '4.0 kg',
      earningsRaw: 200, typeColor: const Color(0xFFF97316)),
  _ParcelListing(id: 'PKG-015', pickupCity: 'Karad', pickupCityKey: 'karad',
      dropCity: 'Sangli', dropCityKey: 'sangli',
      pickupAddress: 'Karad Old Bus Stand', dropAddress: 'Sangli Market',
      parcelType: 'Package', parcelEmoji: '📦', weight: '5.0 kg',
      earningsRaw: 150, typeColor: const Color(0xFF10B981)),
  _ParcelListing(id: 'PKG-016', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Sangli', dropCityKey: 'sangli',
      pickupAddress: 'Katraj, Pune', dropAddress: 'Sangli Kupwad MIDC',
      parcelType: 'Electronics', parcelEmoji: '💻', weight: '1.5 kg',
      earningsRaw: 310, typeColor: const Color(0xFF8B5CF6)),
  _ParcelListing(id: 'PKG-017', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Miraj', dropCityKey: 'miraj',
      pickupAddress: 'Warje, Pune', dropAddress: 'Miraj Railway Colony',
      parcelType: 'Documents', parcelEmoji: '📄', weight: '0.4 kg',
      earningsRaw: 270, typeColor: const Color(0xFF06B6D4)),

  // ── Pune → Solapur corridor ──
  _ParcelListing(id: 'PKG-021', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Solapur', dropCityKey: 'solapur',
      pickupAddress: 'Pune Station', dropAddress: 'Solapur Market',
      parcelType: 'Package', parcelEmoji: '📦', weight: '6.0 kg',
      earningsRaw: 340, typeColor: const Color(0xFF3B82F6)),
  _ParcelListing(id: 'PKG-022', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Osmanabad', dropCityKey: 'osmanabad',
      pickupAddress: 'Camp, Pune', dropAddress: 'Osmanabad Civil Hospital',
      parcelType: 'Fragile', parcelEmoji: '🫙', weight: '2.2 kg',
      earningsRaw: 295, typeColor: const Color(0xFFF97316)),

  // ── Pune → Nashik corridor ──
  _ParcelListing(id: 'PKG-031', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Nashik', dropCityKey: 'nashik',
      pickupAddress: 'Wakad, Pune', dropAddress: 'Nashik Road',
      parcelType: 'Package', parcelEmoji: '📦', weight: '3.5 kg',
      earningsRaw: 280, typeColor: const Color(0xFF3B82F6)),
  _ParcelListing(id: 'PKG-032', pickupCity: 'Nashik', pickupCityKey: 'nashik',
      dropCity: 'Ahmednagar', dropCityKey: 'ahmednagar',
      pickupAddress: 'Nashik Phata', dropAddress: 'Ahmednagar Camp',
      parcelType: 'Documents', parcelEmoji: '📄', weight: '0.7 kg',
      earningsRaw: 120, typeColor: const Color(0xFF06B6D4)),

  // ── Pune → Aurangabad corridor ──
  _ParcelListing(id: 'PKG-041', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Aurangabad', dropCityKey: 'aurangabad',
      pickupAddress: 'Pune Airport Road', dropAddress: 'Aurangabad CIDCO',
      parcelType: 'Electronics', parcelEmoji: '💻', weight: '1.0 kg',
      earningsRaw: 420, typeColor: const Color(0xFF8B5CF6)),
  _ParcelListing(id: 'PKG-042', pickupCity: 'Ahmednagar', pickupCityKey: 'ahmednagar',
      dropCity: 'Aurangabad', dropCityKey: 'aurangabad',
      pickupAddress: 'Ahmednagar Market', dropAddress: 'Aurangabad Bus Stand',
      parcelType: 'Package', parcelEmoji: '📦', weight: '4.2 kg',
      earningsRaw: 190, typeColor: const Color(0xFF3B82F6)),

  // ── Mumbai → Pune (opposite direction) ──
  _ParcelListing(id: 'PKG-051', pickupCity: 'Mumbai', pickupCityKey: 'mumbai',
      dropCity: 'Pune', dropCityKey: 'pune',
      pickupAddress: 'Dadar, Mumbai', dropAddress: 'Koregaon Park, Pune',
      parcelType: 'Package', parcelEmoji: '📦', weight: '2.0 kg',
      earningsRaw: 200, typeColor: const Color(0xFF3B82F6)),

  // ── Delhi → various ──
  _ParcelListing(id: 'PKG-061', pickupCity: 'Delhi', pickupCityKey: 'delhi',
      dropCity: 'Jaipur', dropCityKey: 'jaipur',
      pickupAddress: 'Connaught Place, Delhi', dropAddress: 'Jaipur MI Road',
      parcelType: 'Documents', parcelEmoji: '📄', weight: '0.6 kg',
      earningsRaw: 250, typeColor: const Color(0xFF06B6D4)),

  // ── Kolhapur → Goa corridor ──
  _ParcelListing(id: 'PKG-071', pickupCity: 'Kolhapur', pickupCityKey: 'kolhapur',
      dropCity: 'Goa', dropCityKey: 'goa',
      pickupAddress: 'Kolhapur Station', dropAddress: 'Panaji, Goa',
      parcelType: 'Package', parcelEmoji: '📦', weight: '3.5 kg',
      earningsRaw: 300, typeColor: const Color(0xFF10B981)),

  // ── Pune → Nagpur corridor ──
  _ParcelListing(id: 'PKG-081', pickupCity: 'Pune', pickupCityKey: 'pune',
      dropCity: 'Nagpur', dropCityKey: 'nagpur',
      pickupAddress: 'Bund Garden, Pune', dropAddress: 'Nagpur Cotton Market',
      parcelType: 'Electronics', parcelEmoji: '💻', weight: '2.8 kg',
      earningsRaw: 550, typeColor: const Color(0xFF8B5CF6)),
  _ParcelListing(id: 'PKG-082', pickupCity: 'Aurangabad', pickupCityKey: 'aurangabad',
      dropCity: 'Nagpur', dropCityKey: 'nagpur',
      pickupAddress: 'Aurangabad Garkheda', dropAddress: 'Nagpur Sitabuldi',
      parcelType: 'Package', parcelEmoji: '📦', weight: '5.5 kg',
      earningsRaw: 380, typeColor: const Color(0xFF3B82F6)),
  _ParcelListing(id: 'PKG-083', pickupCity: 'Wardha', pickupCityKey: 'wardha',
      dropCity: 'Nagpur', dropCityKey: 'nagpur',
      pickupAddress: 'Wardha Bus Stand', dropAddress: 'Nagpur Airport Road',
      parcelType: 'Documents', parcelEmoji: '📄', weight: '0.4 kg',
      earningsRaw: 110, typeColor: const Color(0xFF06B6D4)),

  // ── Mumbai → Goa corridor ──
  _ParcelListing(id: 'PKG-091', pickupCity: 'Mumbai', pickupCityKey: 'mumbai',
      dropCity: 'Goa', dropCityKey: 'goa',
      pickupAddress: 'Bandra, Mumbai', dropAddress: 'Margao, Goa',
      parcelType: 'Package', parcelEmoji: '📦', weight: '4.0 kg',
      earningsRaw: 450, typeColor: const Color(0xFF3B82F6)),
  _ParcelListing(id: 'PKG-092', pickupCity: 'Ratnagiri', pickupCityKey: 'ratnagiri',
      dropCity: 'Goa', dropCityKey: 'goa',
      pickupAddress: 'Ratnagiri Market', dropAddress: 'Panaji Bus Stand',
      parcelType: 'Fragile', parcelEmoji: '🫙', weight: '2.5 kg',
      earningsRaw: 220, typeColor: const Color(0xFFF97316)),

  // ── Bangalore → Hyderabad corridor ──
  _ParcelListing(id: 'PKG-101', pickupCity: 'Bangalore', pickupCityKey: 'bangalore',
      dropCity: 'Hyderabad', dropCityKey: 'hyderabad',
      pickupAddress: 'MG Road, Bangalore', dropAddress: 'Banjara Hills, Hyderabad',
      parcelType: 'Electronics', parcelEmoji: '💻', weight: '1.5 kg',
      earningsRaw: 480, typeColor: const Color(0xFF8B5CF6)),
];

// ─────────────────────────────────────────────────────────────────────────────
//  FILTERING LOGIC
// ─────────────────────────────────────────────────────────────────────────────

/// Maximum allowed perpendicular deviation (km) from the route line.
const double _maxDeviationKm = 80.0;

/// Maximum bearing difference (degrees) for the parcel to be "in the same
/// general direction" as the rider's route.
const double _maxBearingDiffDeg = 60.0;

/// Maximum allowed distance (km) from rider's start to parcel's pickup city.
const double _maxPickupDistKm = 80.0;

class _FilteredParcel {
  final _ParcelListing parcel;
  final double deviationKm;

  _FilteredParcel(this.parcel, this.deviationKm);
}

List<_ParcelListing> _filterParcels(String fromLocation, String toLocation) {
  final riderStartKey = _resolveCity(fromLocation);
  final riderEndKey = _resolveCity(toLocation);

  // Cannot filter without coordinates — return empty list
  if (riderStartKey == null || riderEndKey == null) return [];

  final riderStart = _cityCoords[riderStartKey]!;
  final riderEnd = _cityCoords[riderEndKey]!;

  final riderBearing = _bearing(riderStart, riderEnd);
  final riderDistance = _distanceKm(riderStart, riderEnd);

  final List<_FilteredParcel> matched = [];

  for (final p in _parcelPool) {
    final pickupCoord = _cityCoords[p.pickupCityKey];
    final dropCoord = _cityCoords[p.dropCityKey];
    if (pickupCoord == null || dropCoord == null) continue;

    // ── Rule 1: Pickup must be near the rider's start city ──────────────────
    final pickupDistFromStart = _distanceKm(riderStart, pickupCoord);
    if (pickupDistFromStart > _maxPickupDistKm) continue;

    // ── Rule 2: Parcel direction must align with rider direction ─────────────
    final parcelBearing = _bearing(pickupCoord, dropCoord);
    final bearingDiff = _bearingDiff(riderBearing, parcelBearing);
    if (bearingDiff > _maxBearingDiffDeg) continue;

    // ── Rule 3: Drop city must lie on or along the route segment ─────────────
    // It must not go PAST the rider's destination (too far forward)
    final dropDistFromStart = _distanceKm(riderStart, dropCoord);
    if (dropDistFromStart > riderDistance + _maxDeviationKm) continue;

    // Perpendicular deviation of the drop city from the route line
    final dev = _perpDistanceKm(riderStart, riderEnd, dropCoord);
    if (dev > _maxDeviationKm) continue;

    // Reset rejected state so pool items can show again for a new route
    p.rejected = false;
    p.deviationKm = dev;
    matched.add(_FilteredParcel(p, dev));
  }

  // ── Sort: lowest deviation first, then highest earnings ──────────────────
  matched.sort((a, b) {
    final devCmp = a.deviationKm.compareTo(b.deviationKm);
    if (devCmp != 0) return devCmp;
    return b.parcel.earningsRaw.compareTo(a.parcel.earningsRaw);
  });

  return matched.map((e) => e.parcel).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
//  RIDER AVAILABLE PARCELS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class RiderAvailableParcelsScreen extends StatefulWidget {
  final String fromLocation;
  final String toLocation;

  const RiderAvailableParcelsScreen({
    super.key,
    required this.fromLocation,
    required this.toLocation,
  });

  @override
  State<RiderAvailableParcelsScreen> createState() =>
      _RiderAvailableParcelsScreenState();
}

class _RiderAvailableParcelsScreenState
    extends State<RiderAvailableParcelsScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Filtered parcel list — computed once in initState
  late List<_ParcelListing> _parcels;

  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();
    _parcels = _filterParcels(widget.fromLocation, widget.toLocation);

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 16))
      ..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.linear);

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _entryCtrl, curve: Curves.easeOutCubic));

    // Staggered card animations (one per filtered parcel)
    _cardControllers = List.generate(
        _parcels.length,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500)));
    _cardFades = _cardControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _cardSlides = _cardControllers
        .map((c) =>
            Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
                .animate(
                    CurvedAnimation(parent: c, curve: Curves.easeOutCubic)))
        .toList();

    _entryCtrl.forward();
    _startCardAnimations();
  }

  void _startCardAnimations() async {
    for (int i = 0; i < _cardControllers.length; i++) {
      await Future.delayed(Duration(milliseconds: 150 + i * 100));
      if (mounted) _cardControllers[i].forward();
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    for (final c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<_ParcelListing> get _activeParcels =>
      _parcels.where((p) => !p.rejected).toList();

  void _acceptParcel(_ParcelListing parcel) {
    HapticFeedback.mediumImpact();
    final pCoord = _cityCoords[parcel.pickupCityKey];
    final dCoord = _cityCoords[parcel.dropCityKey];

    Navigator.of(context).push(_slideRoute(RiderOrderDetailsScreen(
      parcelId: parcel.id,
      pickupAddress: parcel.pickupAddress,
      dropAddress: parcel.dropAddress,
      parcelType: parcel.parcelType,
      parcelEmoji: parcel.parcelEmoji,
      weight: parcel.weight,
      earnings: parcel.earnings,
      pickupLatLng: pCoord != null ? LatLng(pCoord.lat, pCoord.lng) : null,
      dropLatLng: dCoord != null ? LatLng(dCoord.lat, dCoord.lng) : null,
    )));
  }

  void _rejectParcel(_ParcelListing parcel) {
    HapticFeedback.selectionClick();
    setState(() => parcel.rejected = true);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildRouteChip(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _activeParcels.isEmpty
                        ? _buildEmptyState()
                        : _buildParcelList(),
                  ),
                ],
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
              color: _C.green.withValues(alpha: 0.07)),
          _orb(
              x: 0.82 + 0.05 * math.cos(t + 2.0),
              y: 0.35 + 0.06 * math.sin(t + 2.0),
              size: 200,
              color: _C.accentA.withValues(alpha: 0.06)),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [_C.textPrimary, Color(0xFF6EE7B7)],
              ).createShader(b),
              child: Text(
                '${_activeParcels.length} Parcels Found',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Parcels available on your selected route',
              style: TextStyle(
                  color: _C.textSec,
                  fontSize: 13,
                  fontWeight: FontWeight.w400),
            ),
          ]),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _C.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: _C.green.withValues(alpha: 0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: _C.green),
            ),
            const SizedBox(width: 6),
            Text('${_activeParcels.length} Active',
                style: const TextStyle(
                    color: _C.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRouteChip() {
    final from = widget.fromLocation.split(',').first;
    final to = widget.toLocation.split(',').first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _C.glass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.glassBorder),
            ),
            child: Row(children: [
              const Icon(Icons.radio_button_checked_rounded,
                  color: _C.accentA, size: 14),
              const SizedBox(width: 6),
              Text(from,
                  style: const TextStyle(
                      color: _C.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                  width: 30,
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_C.accentA, _C.accentB]),
                    borderRadius: BorderRadius.circular(2),
                  )),
              const Icon(Icons.arrow_forward_rounded,
                  color: _C.accentB, size: 12),
              const SizedBox(width: 6),
              Text(to,
                  style: const TextStyle(
                      color: _C.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              const Icon(Icons.location_on_rounded,
                  color: _C.accentB, size: 14),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildParcelList() {
    final active = _activeParcels;
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: active.length,
      itemBuilder: (_, i) {
        final parcel = active[i];
        final idx = _parcels.indexOf(parcel);
        if (idx < 0 || idx >= _cardControllers.length) {
          return _buildParcelCard(parcel, i);
        }
        return FadeTransition(
          opacity: _cardFades[idx],
          child: SlideTransition(
            position: _cardSlides[idx],
            child: _buildParcelCard(parcel, i),
          ),
        );
      },
    );
  }

  Widget _buildParcelCard(_ParcelListing p, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _C.glassBorder),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  p.typeColor.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: emoji + route + type badge
                Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: p.typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: p.typeColor.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(p.parcelEmoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(
                              child: Text(p.pickupCity,
                                  style: const TextStyle(
                                      color: _C.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward_rounded,
                                  color: _C.textSec, size: 14),
                            ),
                            Flexible(
                              child: Text(p.dropCity,
                                  style: const TextStyle(
                                      color: _C.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                          const SizedBox(height: 3),
                          Text(p.id,
                              style: const TextStyle(
                                  color: _C.textSec,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500)),
                        ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: p.typeColor.withValues(alpha: 0.3),
                          width: 1),
                    ),
                    child: Text(p.parcelType,
                        style: TextStyle(
                            color: p.typeColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),

                const SizedBox(height: 14),

                // Route details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.surfaceEl,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.glassBorder),
                  ),
                  child: Column(children: [
                    _routeRow(
                        Icons.radio_button_checked_rounded,
                        _C.accentA,
                        p.pickupAddress),
                    Padding(
                      padding: const EdgeInsets.only(left: 7, top: 4, bottom: 4),
                      child: Container(
                          width: 1,
                          height: 16,
                          color: _C.textSec.withValues(alpha: 0.2)),
                    ),
                    _routeRow(
                        Icons.location_on_rounded,
                        _C.accentB,
                        p.dropAddress),
                  ]),
                ),

                const SizedBox(height: 12),

                // Stats row
                Row(children: [
                  _statBadge(Icons.straighten_rounded, p.deviation, _C.accentA),
                  const SizedBox(width: 8),
                  _statBadge(Icons.monitor_weight_outlined, p.weight, _C.accentC),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: _C.greenGlow(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Text(p.earnings,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ),
                ]),

                const SizedBox(height: 14),

                // Action buttons
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _rejectParcel(p),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _C.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _C.red.withValues(alpha: 0.35)),
                        ),
                        child: const Center(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.close_rounded,
                                color: _C.red, size: 16),
                            SizedBox(width: 6),
                            Text('Reject',
                                style: TextStyle(
                                    color: _C.red,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => _acceptParcel(p),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_C.accentA, _C.accentC]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: _C.blueGlow(0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Center(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Accept Parcel',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _routeRow(IconData icon, Color color, String address) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 8),
      Expanded(
        child: Text(address,
            style: const TextStyle(
                color: _C.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  Widget _statBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📭', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text('No parcels on this route',
            style: TextStyle(
                color: _C.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'No parcels found along\n${widget.fromLocation.split(',').first} → ${widget.toLocation.split(',').first}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _C.textSec, fontSize: 14),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_C.accentA, _C.accentB]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('Try a Different Route',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

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
