import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/places_service.dart';

class MuhafizCommandCentreScreen extends StatelessWidget {
  const MuhafizCommandCentreScreen({
    super.key,
    required this.userLocation,
    required this.emergencyType,
    this.severityScore = 1.0,
  });

  final LatLng userLocation;
  final String emergencyType;
  final double severityScore;

  @override
  Widget build(BuildContext context) {
    return DynamicEmergencyMap(
      userLocation: userLocation,
      emergencyType: emergencyType,
      severityScore: severityScore,
    );
  }
}

class DynamicEmergencyMap extends StatefulWidget {
  const DynamicEmergencyMap({
    super.key,
    required this.userLocation,
    required this.emergencyType,
    this.severityScore = 1.0,
  });

  final LatLng userLocation;
  final String emergencyType;
  final double severityScore;

  @override
  State<DynamicEmergencyMap> createState() => _DynamicEmergencyMapState();
}

class _DynamicEmergencyMapState extends State<DynamicEmergencyMap> {
  final PlacesService _placesService = PlacesService();
  Set<Marker> _dynamicMarkers = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContextualData();
  }

  String _getCategory() {
    switch (widget.emergencyType) {
      case 'Fire':
        return 'fire_station';
      case 'Quake':
        return 'park';
      case 'Medical':
        return 'hospital';
      case 'Assault':
      case 'Robbery':
        return 'police';
      case 'Flood':
        return 'establishment';
      default:
        return 'establishment';
    }
  }

  double _computeImpactRadiusMeters() {
    final normalized = widget.severityScore <= 0 ? 1.0 : widget.severityScore;
    final radius = 800 * normalized;
    return radius.clamp(300, 5000);
  }

  Future<void> _loadContextualData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _placesService.fetchNearbyPlaces(
        location: widget.userLocation,
        category: _getCategory(),
      );

      final dynamicMarkers = results.map((place) {
        final geometry = place['geometry'] as Map<String, dynamic>?;
        final location = geometry?['location'] as Map<String, dynamic>?;
        final lat = (location?['lat'] as num?)?.toDouble();
        final lng = (location?['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return null;

        return Marker(
          markerId: MarkerId((place['place_id'] ?? '$lat,$lng').toString()),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: (place['name'] ?? 'Nearby place').toString(),
            snippet: 'Rating: ${(place['rating'] ?? 'N/A').toString()}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            widget.emergencyType == 'Medical'
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueAzure,
          ),
        );
      }).whereType<Marker>().toSet();

      dynamicMarkers.add(
        Marker(
          markerId: const MarkerId('user_loc'),
          position: widget.userLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );

      if (!mounted) return;
      setState(() {
        _dynamicMarkers = dynamicMarkers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Muhafiz Command Centre'),
        actions: [
          IconButton(onPressed: _loadContextualData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.userLocation,
              zoom: 14,
            ),
            markers: _dynamicMarkers,
            circles: {
              Circle(
                circleId: const CircleId('impact_zone'),
                center: widget.userLocation,
                radius: _computeImpactRadiusMeters(),
                fillColor: Colors.red.withValues(alpha: 0.2),
                strokeColor: Colors.red,
                strokeWidth: 1,
              ),
            },
          ),
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_error != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Material(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Map data error: $_error',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
