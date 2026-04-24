import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlacesService {
  Future<List<Map<String, dynamic>>> fetchNearbyPlaces({
    required LatLng location,
    required String category,
    int radiusMeters = 3000,
  }) async {
    final amenity = _categoryToAmenity(category);
    final query = '''
[out:json][timeout:15];
node["amenity"="$amenity"](around:$radiusMeters,${location.latitude},${location.longitude});
out center 20;
''';

    try {
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            body: query,
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final elements = (data['elements'] as List? ?? []).cast<Map<String, dynamic>>();

      return elements.map((e) {
        final tags = (e['tags'] as Map<String, dynamic>?) ?? {};
        final lat = (e['lat'] as num?)?.toDouble();
        final lng = (e['lon'] as num?)?.toDouble();
        return {
          'name': tags['name'] ?? amenity,
          'lat': lat ?? 0.0,
          'lng': lng ?? 0.0,
          'phone': tags['phone'],
        };
      }).where((p) => p['lat'] != 0.0 && p['lng'] != 0.0).toList();
    } catch (_) {
      return [];
    }
  }

  String _categoryToAmenity(String category) {
    switch (category) {
      case 'fire_station':
        return 'fire_station';
      case 'hospital':
        return 'hospital';
      case 'police':
        return 'police';
      case 'park':
        return 'park';
      default:
        return 'hospital';
    }
  }
}
