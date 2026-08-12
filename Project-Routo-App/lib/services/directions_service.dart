// ═══════════════════════════════════════════════════════════════════════════
//  directions_service.dart  —  ROUTO
//  Centralised Google Directions API helper.
//  Handles HTTP request, response parsing, polyline decoding, and camera
//  bounds calculation.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  API KEY — Loaded via .env
// ─────────────────────────────────────────────────────────────────────────────
final String kGoogleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_GOOGLE_MAPS_API_KEY';

// ─────────────────────────────────────────────────────────────────────────────
//  RESULT MODEL
// ─────────────────────────────────────────────────────────────────────────────
class DirectionsResult {
  /// Decoded list of LatLng points from overview_polyline.
  final List<LatLng> polylinePoints;

  /// Human-readable distance text, e.g. "149 km".
  final String distanceText;

  /// Human-readable duration text, e.g. "2 hours 30 mins".
  final String durationText;

  /// Raw distance in metres (for sorting / calculations).
  final int distanceMeters;

  /// Raw duration in seconds.
  final int durationSeconds;

  /// Camera bounds that fit the full route.
  final LatLngBounds bounds;

  const DirectionsResult({
    required this.polylinePoints,
    required this.distanceText,
    required this.durationText,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.bounds,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class DirectionsService {
  /// Fetches a driving route between [origin] and [destination].
  ///
  /// Returns a [DirectionsResult] on success, or `null` on error / no route.
  static Future<DirectionsResult?> getRoute({
    required String origin,
    required String destination,
  }) async {
    // Graceful fallback if API key is not configured.
    if (kGoogleMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      debugPrint(
          '[DirectionsService] API Key is missing. Skipping network request.');
      return null;
    }
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${Uri.encodeComponent(origin)}'
        '&destination=${Uri.encodeComponent(destination)}'
        '&mode=driving'
        '&key=$kGoogleMapsApiKey',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('[DirectionsService] HTTP ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status != 'OK') {
        debugPrint('[DirectionsService] API status: $status');
        return null;
      }

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;

      // ── Polyline ──────────────────────────────────────────────────────────
      final encodedPolyline =
          route['overview_polyline']?['points'] as String? ?? '';

      final polylinePoints = PolylinePoints();
      final decodedPoints = polylinePoints.decodePolyline(encodedPolyline);
      final points =
          decodedPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

      if (points.isEmpty) return null;

      // ── Leg summary ───────────────────────────────────────────────────────
      final legs = route['legs'] as List<dynamic>;
      final leg = legs.first as Map<String, dynamic>;

      final distanceText =
          (leg['distance'] as Map<String, dynamic>?)?['text'] as String? ?? '–';
      final durationText =
          (leg['duration'] as Map<String, dynamic>?)?['text'] as String? ?? '–';
      final distanceMeters =
          (leg['distance'] as Map<String, dynamic>?)?['value'] as int? ?? 0;
      final durationSeconds =
          (leg['duration'] as Map<String, dynamic>?)?['value'] as int? ?? 0;

      // ── Viewport bounds ───────────────────────────────────────────────────
      final boundsData = route['bounds'] as Map<String, dynamic>?;
      late LatLngBounds bounds;

      if (boundsData != null) {
        final northeast = boundsData['northeast'];
        final southwest = boundsData['southwest'];
        bounds = LatLngBounds(
          southwest: LatLng(
            (southwest['lat'] as num).toDouble(),
            (southwest['lng'] as num).toDouble(),
          ),
          northeast: LatLng(
            (northeast['lat'] as num).toDouble(),
            (northeast['lng'] as num).toDouble(),
          ),
        );
      } else {
        // Fallback: Compute bounds from points
        double? minLat, maxLat, minLng, maxLng;
        for (final p in points) {
          if (minLat == null || p.latitude < minLat) minLat = p.latitude;
          if (maxLat == null || p.latitude > maxLat) maxLat = p.latitude;
          if (minLng == null || p.longitude < minLng) minLng = p.longitude;
          if (maxLng == null || p.longitude > maxLng) maxLng = p.longitude;
        }
        bounds = LatLngBounds(
          southwest: LatLng(minLat!, minLng!),
          northeast: LatLng(maxLat!, maxLng!),
        );
      }

      return DirectionsResult(
        polylinePoints: points,
        distanceText: distanceText,
        durationText: durationText,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        bounds: bounds,
      );
    } catch (e) {
      debugPrint('[DirectionsService] Error: $e');
      return null;
    }
  }
}
