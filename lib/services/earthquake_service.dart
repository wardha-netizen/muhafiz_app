import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'weather_service.dart';

// Karachi coordinates (reuse constants from weather_service)
const double _lat = karachiLat;
const double _lng = karachiLng;

class EarthquakeEvent {
  final double magnitude;
  final String place;
  final DateTime time;
  final double lat;
  final double lng;
  final double depthKm;
  final double distanceKm;

  const EarthquakeEvent({
    required this.magnitude,
    required this.place,
    required this.time,
    required this.lat,
    required this.lng,
    required this.depthKm,
    required this.distanceKm,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String get magnitudeLabel {
    if (magnitude >= 7.0) return 'Major';
    if (magnitude >= 5.0) return 'Strong';
    if (magnitude >= 4.0) return 'Moderate';
    if (magnitude >= 3.0) return 'Minor';
    return 'Micro';
  }
}

class EarthquakeService {
  // USGS Earthquake Hazards Program — 100% free, no API key needed
  static const _usgs = 'https://earthquake.usgs.gov/fdsnws/event/1/query';

  static Future<List<EarthquakeEvent>> fetchNearKarachi({
    int days = 7,
    double minMagnitude = 2.0,
    double radiusKm = 500,
  }) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));

    final uri = Uri.parse(
      '$_usgs?format=geojson'
      '&latitude=$_lat&longitude=$_lng'
      '&maxradiuskm=${radiusKm.toInt()}'
      '&minmagnitude=$minMagnitude'
      '&starttime=${start.toIso8601String().substring(0, 19)}'
      '&endtime=${now.toIso8601String().substring(0, 19)}'
      '&orderby=time&limit=20',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('USGS API ${response.statusCode}');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final features = (body['features'] as List).cast<Map<String, dynamic>>();

    return features.map((f) {
      final props = f['properties'] as Map<String, dynamic>;
      final coords =
          ((f['geometry'] as Map)['coordinates'] as List).cast<num>();

      final eLng = coords[0].toDouble();
      final eLat = coords[1].toDouble();
      final depth = coords[2].toDouble();

      return EarthquakeEvent(
        magnitude: (props['mag'] as num?)?.toDouble() ?? 0,
        place: (props['place'] as String?) ?? 'Unknown',
        time: DateTime.fromMillisecondsSinceEpoch(props['time'] as int),
        lat: eLat,
        lng: eLng,
        depthKm: depth,
        distanceKm: _haversine(_lat, _lng, eLat, eLng),
      );
    }).toList();
  }

  static DisasterRisk assessEarthquakeRisk(List<EarthquakeEvent> events) {
    final ind = <String>[];
    var score = 0;

    final h24 = events
        .where((e) => DateTime.now().difference(e.time).inHours <= 24)
        .toList();
    final d7 = events
        .where((e) => DateTime.now().difference(e.time).inDays <= 7)
        .toList();

    final max24h = h24.isEmpty
        ? 0.0
        : h24.map((e) => e.magnitude).reduce((a, b) => a > b ? a : b);

    if (max24h >= 6.0) {
      score += 5;
      ind.add('Severe quake M${max24h.toStringAsFixed(1)} in last 24h!');
    } else if (max24h >= 5.0) {
      score += 3;
      ind.add('Strong quake M${max24h.toStringAsFixed(1)} in last 24h');
    } else if (max24h >= 4.0) {
      score += 2;
      ind.add('Moderate quake M${max24h.toStringAsFixed(1)} in last 24h');
    } else if (h24.isNotEmpty) {
      score += 1;
      ind.add('${h24.length} minor quake(s) in last 24h');
    }

    if (d7.length > 10) {
      score += 2;
      ind.add('High seismic activity: ${d7.length} events in 7 days');
    } else if (d7.length > 5) {
      score += 1;
      ind.add('Elevated activity: ${d7.length} events in 7 days');
    }

    // Shallow quakes are more dangerous for Karachi
    final shallowRecent =
        h24.where((e) => e.depthKm < 30 && e.magnitude >= 3.0).length;
    if (shallowRecent > 0) {
      score += 1;
      ind.add('$shallowRecent shallow quake(s) detected (<30 km depth)');
    }

    final level = score >= 5
        ? RiskLevel.critical
        : score >= 3
            ? RiskLevel.warning
            : score >= 1
                ? RiskLevel.watch
                : RiskLevel.safe;

    return DisasterRisk(
      level: level,
      type: 'Earthquake',
      title: 'Seismic Activity',
      description: level == RiskLevel.critical
          ? 'Major seismic activity! Drop, Cover, Hold On. Prepare for aftershocks.'
          : level == RiskLevel.warning
              ? 'Elevated seismic activity. Avoid coastal areas and stay away from old buildings.'
              : level == RiskLevel.watch
                  ? 'Minor seismic activity in the region. Monitor updates.'
                  : 'No significant seismic threats in the past 7 days.',
      indicators: ind.isEmpty ? ['Seismically quiet (7-day window)'] : ind,
    );
  }

  static double _haversine(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double d) => d * pi / 180;
}
