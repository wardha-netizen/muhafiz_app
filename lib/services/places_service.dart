import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PlacesService {
  PlacesService({String? apiKey}) : _apiKey = apiKey ?? _defaultApiKey;

  static const String _defaultApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  final String _apiKey;

  Future<List<Map<String, dynamic>>> fetchNearbyPlaces({
    required LatLng location,
    required String category,
    int radiusMeters = 3000,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Google Maps API key missing. Pass apiKey or set --dart-define=GOOGLE_MAPS_API_KEY=...',
      );
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${location.latitude},${location.longitude}'
      '&radius=$radiusMeters'
      '&type=$category'
      '&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch nearby places: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['results'] ?? const []);
  }
}
