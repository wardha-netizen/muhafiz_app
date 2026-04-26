import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/places_service.dart';
import '../../services/settings_provider.dart';

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
  List<Map<String, dynamic>> _places = [];
  bool _isLoading = true;
  bool _isUrdu = false;
  String? _error;

  String _t(String en, String ur) => _isUrdu ? ur : en;

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
      default:
        return 'hospital';
    }
  }

  double _computeImpactRadiusMeters() {
    final normalized = widget.severityScore <= 0 ? 1.0 : widget.severityScore;
    return (800 * normalized).clamp(300, 5000);
  }

  Color _emergencyColor() {
    switch (widget.emergencyType) {
      case 'Fire':
        return Colors.orange;
      case 'Medical':
        return Colors.red;
      case 'Assault':
      case 'Robbery':
        return Colors.blue;
      default:
        return Colors.red;
    }
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
        radiusMeters: _computeImpactRadiusMeters().toInt(),
      );

      if (!mounted) return;
      setState(() {
        _places = results;
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
    final isDark =
        Provider.of<SettingsProvider>(context).themeMode == ThemeMode.dark;
    final color = _emergencyColor();
    final radius = _computeImpactRadiusMeters();
    final sheetBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final sheetText = isDark ? Colors.white : Colors.black87;
    final sheetMuted = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.emergencyType} ${_t('Command Centre', 'کمانڈ سینٹر')}'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _isUrdu = !_isUrdu),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: Text(_isUrdu ? 'EN' : 'اردو',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadContextualData,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.userLocation,
              initialZoom: 14,
              maxZoom: 18,
              minZoom: 10,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.muhafiz_1',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: widget.userLocation,
                    radius: radius,
                    useRadiusInMeter: true,
                    color: color.withValues(alpha: 0.18),
                    borderColor: color,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.userLocation,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 6),
                        ],
                      ),
                      child: Icon(Icons.my_location, size: 22, color: color),
                    ),
                  ),
                  ..._places.map((p) {
                    final lat = p['lat'] as double;
                    final lng = p['lng'] as double;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => _showPlaceSheet(
                            p, sheetBg, sheetText, sheetMuted),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 4),
                            ],
                          ),
                          child: Icon(_categoryIcon(),
                              size: 20, color: Colors.white),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_error != null && !_isLoading)
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
                    '${_t('Could not load nearby places:', 'قریبی مقامات لوڈ نہیں ہو سکے:')} $_error',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          if (!_isLoading && _places.isEmpty && _error == null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Material(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _t('No nearby services found in this area.',
                        'اس علاقے میں کوئی قریبی سروس نہیں ملی۔'),
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _categoryIcon() {
    switch (widget.emergencyType) {
      case 'Fire':
        return Icons.fire_truck;
      case 'Medical':
        return Icons.local_hospital;
      case 'Assault':
      case 'Robbery':
        return Icons.local_police;
      case 'Quake':
        return Icons.park;
      default:
        return Icons.place;
    }
  }

  void _showPlaceSheet(Map<String, dynamic> place, Color bg, Color text,
      Color muted) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (place['name'] ?? _t('Nearby service', 'قریبی سروس')).toString(),
              style: TextStyle(
                  color: text, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (place['phone'] != null) ...[
              const SizedBox(height: 12),
              Text(
                '${_t('Phone:', 'فون:')} ${place['phone']}',
                style: TextStyle(color: muted, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
