import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/settings_provider.dart';

const LatLng _karachiCentre = LatLng(24.8607, 67.0011);

enum _PoiType { hospital, police, fire, ambulance, pharmacy, park, water }

class _Poi {
  final _PoiType type;
  final LatLng pos;
  final String name;
  final String? phone;
  final bool isStatic;

  const _Poi({
    required this.type,
    required this.pos,
    required this.name,
    this.phone,
    this.isStatic = false,
  });
}

List<_Poi> _staticKarachiPois() => [
      const _Poi(type: _PoiType.hospital, pos: LatLng(24.8592, 67.0694), name: 'Aga Khan University Hospital', phone: '021-111-911-911', isStatic: true),
      const _Poi(type: _PoiType.hospital, pos: LatLng(24.8704, 67.0327), name: 'Jinnah Postgraduate Medical Centre', phone: '021-99201300', isStatic: true),
      const _Poi(type: _PoiType.hospital, pos: LatLng(24.8604, 67.0301), name: 'Civil Hospital Karachi', phone: '021-99215740', isStatic: true),
      const _Poi(type: _PoiType.hospital, pos: LatLng(24.8815, 67.0604), name: 'Liaquat National Hospital', phone: '021-34412442', isStatic: true),
      const _Poi(type: _PoiType.hospital, pos: LatLng(24.8895, 67.1027), name: 'Indus Hospital Korangi', phone: '021-35110000', isStatic: true),
      const _Poi(type: _PoiType.hospital, pos: LatLng(24.8725, 67.0400), name: 'DOW University Hospital', phone: '021-99261300', isStatic: true),
      const _Poi(type: _PoiType.hospital, pos: LatLng(24.8503, 67.0139), name: 'South City Hospital', phone: '021-35860001', isStatic: true),
      const _Poi(type: _PoiType.hospital, pos: LatLng(24.9367, 67.0747), name: 'KMDC Teaching Hospital', phone: '021-36616006', isStatic: true),
      const _Poi(type: _PoiType.police, pos: LatLng(24.8604, 67.0194), name: 'Saddar Police Station', phone: '15', isStatic: true),
      const _Poi(type: _PoiType.police, pos: LatLng(24.8241, 67.0330), name: 'Clifton Police Station', phone: '15', isStatic: true),
      const _Poi(type: _PoiType.police, pos: LatLng(24.8711, 67.0195), name: 'Garden Police Station', phone: '15', isStatic: true),
      const _Poi(type: _PoiType.police, pos: LatLng(24.7906, 67.0595), name: 'DHA Phase-II Police Station', phone: '15', isStatic: true),
      const _Poi(type: _PoiType.police, pos: LatLng(24.9087, 67.0187), name: 'SITE Police Station', phone: '15', isStatic: true),
      const _Poi(type: _PoiType.police, pos: LatLng(24.8375, 67.1308), name: 'Korangi Police Station', phone: '15', isStatic: true),
      const _Poi(type: _PoiType.police, pos: LatLng(24.9614, 67.0628), name: 'Surjani Police Station', phone: '15', isStatic: true),
      const _Poi(type: _PoiType.fire, pos: LatLng(24.8736, 67.0339), name: 'Karachi Fire Brigade HQ (Saddar)', phone: '16', isStatic: true),
      const _Poi(type: _PoiType.fire, pos: LatLng(24.8169, 67.0228), name: 'Clifton Fire Station', phone: '16', isStatic: true),
      const _Poi(type: _PoiType.fire, pos: LatLng(24.9614, 67.0628), name: 'North Karachi Fire Station', phone: '16', isStatic: true),
      const _Poi(type: _PoiType.fire, pos: LatLng(24.8900, 67.0400), name: 'Lyari Fire Station', phone: '021-32262030', isStatic: true),
      const _Poi(type: _PoiType.ambulance, pos: LatLng(24.8601, 67.0087), name: 'Edhi Foundation HQ (Mithadar)', phone: '115', isStatic: true),
      const _Poi(type: _PoiType.ambulance, pos: LatLng(24.8950, 67.0750), name: 'Edhi Centre North Nazimabad', phone: '115', isStatic: true),
      const _Poi(type: _PoiType.ambulance, pos: LatLng(24.9231, 67.0947), name: 'Chhipa Welfare Gulshan', phone: '1020', isStatic: true),
      const _Poi(type: _PoiType.ambulance, pos: LatLng(24.8592, 67.0694), name: 'Aman Foundation Ambulance', phone: '1102', isStatic: true),
      const _Poi(type: _PoiType.park, pos: LatLng(24.8723, 67.0259), name: 'Nishtar Park (Evacuation Ground)', isStatic: true),
      const _Poi(type: _PoiType.park, pos: LatLng(24.8102, 67.0228), name: 'Bagh Ibn Qasim (Clifton)', isStatic: true),
      const _Poi(type: _PoiType.park, pos: LatLng(24.8459, 67.0728), name: 'Hill Park (Evacuation Point)', isStatic: true),
      const _Poi(type: _PoiType.park, pos: LatLng(24.8019, 67.0339), name: 'Seaview Ground (Emergency Muster)', isStatic: true),
      const _Poi(type: _PoiType.park, pos: LatLng(24.9021, 67.0659), name: 'Gulshan-e-Iqbal Park', isStatic: true),
      const _Poi(type: _PoiType.water, pos: LatLng(24.8756, 67.0287), name: 'KWSB HQ (Water Emergency: 1630)', phone: '1630', isStatic: true),
    ];

class KarachiEmergencyMapScreen extends StatefulWidget {
  const KarachiEmergencyMapScreen({super.key});

  @override
  State<KarachiEmergencyMapScreen> createState() =>
      _KarachiEmergencyMapScreenState();
}

class _KarachiEmergencyMapScreenState
    extends State<KarachiEmergencyMapScreen> {
  final MapController _mapController = MapController();

  LatLng _userLocation = _karachiCentre;
  List<_Poi> _pois = [];
  bool _usingStaticData = false;
  bool _isUrdu = false;
  Timer? _locationTimer;

  final Set<_PoiType> _visible = {..._PoiType.values};

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  @override
  void initState() {
    super.initState();
    _pois = _staticKarachiPois();
    _usingStaticData = true;
    _getUserLocation();
    _tryLoadOverpassPois();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _getUserLocation();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 6));

      if (mounted) {
        setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {}
  }

  Future<void> _tryLoadOverpassPois() async {
    const mirrors = [
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
    ];

    final lat = _karachiCentre.latitude;
    final lng = _karachiCentre.longitude;
    const r = 15000;

    final query = '''
[out:json][timeout:20];
(
  node["amenity"="hospital"](around:$r,$lat,$lng);
  way["amenity"="hospital"](around:$r,$lat,$lng);
  node["amenity"="police"](around:$r,$lat,$lng);
  node["amenity"="fire_station"](around:$r,$lat,$lng);
  node["amenity"="ambulance_station"](around:$r,$lat,$lng);
  node["amenity"="pharmacy"](around:8000,$lat,$lng);
  node["leisure"="park"](around:$r,$lat,$lng);
  way["leisure"="park"](around:$r,$lat,$lng);
  node["man_made"="water_tower"](around:$r,$lat,$lng);
  node["amenity"="water_point"](around:$r,$lat,$lng);
);
out center;
''';

    for (final mirror in mirrors) {
      try {
        final response = await http
            .post(Uri.parse(mirror), body: query)
            .timeout(const Duration(seconds: 18));

        if (response.statusCode != 200) continue;

        final data = json.decode(response.body) as Map<String, dynamic>;
        final elements =
            (data['elements'] as List).cast<Map<String, dynamic>>();
        final parsed = <_Poi>[];

        for (final el in elements) {
          double? elLat, elLng;
          if (el['type'] == 'node') {
            elLat = (el['lat'] as num?)?.toDouble();
            elLng = (el['lon'] as num?)?.toDouble();
          } else if (el['center'] != null) {
            elLat = (el['center']['lat'] as num?)?.toDouble();
            elLng = (el['center']['lon'] as num?)?.toDouble();
          }
          if (elLat == null || elLng == null) continue;

          final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
          final amenity = tags['amenity'] as String? ?? '';
          final leisure = tags['leisure'] as String? ?? '';
          final manMade = tags['man_made'] as String? ?? '';
          final name = (tags['name'] as String?) ??
              (tags['name:en'] as String?) ??
              _defaultName(amenity, leisure, manMade);

          _PoiType? type;
          if (amenity == 'hospital') {
            type = _PoiType.hospital;
          } else if (amenity == 'police') {
            type = _PoiType.police;
          } else if (amenity == 'fire_station') {
            type = _PoiType.fire;
          } else if (amenity == 'ambulance_station') {
            type = _PoiType.ambulance;
          } else if (amenity == 'pharmacy') {
            type = _PoiType.pharmacy;
          } else if (leisure == 'park') {
            type = _PoiType.park;
          } else if (manMade == 'water_tower' || amenity == 'water_point') {
            type = _PoiType.water;
          }
          if (type == null) { continue; }

          parsed.add(_Poi(
            type: type,
            pos: LatLng(elLat, elLng),
            name: name,
            phone: tags['phone'] as String?,
          ));
        }

        if (parsed.isNotEmpty && mounted) {
          setState(() {
            _pois = [..._staticKarachiPois(), ...parsed];
            _usingStaticData = false;
          });
        }
        return;
      } catch (_) {
        continue;
      }
    }
    if (mounted) setState(() => _usingStaticData = true);
  }

  String _defaultName(String amenity, String leisure, String manMade) {
    if (amenity == 'hospital') return 'Hospital';
    if (amenity == 'police') return 'Police Station';
    if (amenity == 'fire_station') return 'Fire Station';
    if (amenity == 'ambulance_station') return 'Ambulance';
    if (amenity == 'pharmacy') return 'Pharmacy';
    if (leisure == 'park') return 'Park / Evacuation Ground';
    if (manMade == 'water_tower') return 'Water Tower';
    return 'Water Point';
  }

  Color _poiColor(_PoiType t) {
    switch (t) {
      case _PoiType.hospital: return Colors.red.shade700;
      case _PoiType.police: return Colors.blue.shade700;
      case _PoiType.fire: return Colors.orange.shade700;
      case _PoiType.ambulance: return Colors.green.shade600;
      case _PoiType.pharmacy: return Colors.teal.shade600;
      case _PoiType.park: return Colors.lightGreen.shade700;
      case _PoiType.water: return Colors.cyan.shade700;
    }
  }

  IconData _poiIcon(_PoiType t) {
    switch (t) {
      case _PoiType.hospital: return Icons.local_hospital;
      case _PoiType.police: return Icons.local_police;
      case _PoiType.fire: return Icons.fire_truck;
      case _PoiType.ambulance: return Icons.emergency;
      case _PoiType.pharmacy: return Icons.medical_services;
      case _PoiType.park: return Icons.park;
      case _PoiType.water: return Icons.water_drop;
    }
  }

  String _poiLabel(_PoiType t) {
    switch (t) {
      case _PoiType.hospital: return _t('Hospital', 'اسپتال');
      case _PoiType.police: return _t('Police', 'پولیس');
      case _PoiType.fire: return _t('Fire', 'فائر');
      case _PoiType.ambulance: return _t('Ambulance', 'ایمبولینس');
      case _PoiType.pharmacy: return _t('Pharmacy', 'دواخانہ');
      case _PoiType.park: return _t('Evacuation', 'انخلاء');
      case _PoiType.water: return _t('Water', 'پانی');
    }
  }

  @override
  Widget build(BuildContext context) {
    final barBg =
        _isDark ? Colors.grey.shade900 : Colors.grey.shade200;
    final onSurface = _isDark ? Colors.white : Colors.black87;
    final onMuted = _isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Karachi Emergency Map', 'کراچی ہنگامی نقشہ')),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Language toggle
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => setState(() => _isUrdu = !_isUrdu),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isUrdu
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _isUrdu ? 'EN' : 'اردو',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Theme toggle
          IconButton(
            icon: Icon(
              _isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: Colors.white,
            ),
            onPressed: () =>
                Provider.of<SettingsProvider>(context, listen: false)
                    .toggleTheme(!_isDark),
          ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: _t('Refresh POI data', 'ڈیٹا تازہ کریں'),
            onPressed: _tryLoadOverpassPois,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(barBg: barBg, onSurface: onSurface),
          if (_usingStaticData) _buildStaticDataBanner(onMuted: onMuted),
          Expanded(child: _buildMap()),
          _buildLegend(barBg: barBg, onMuted: onMuted),
        ],
      ),
    );
  }

  Widget _buildStaticDataBanner({required Color onMuted}) {
    return Container(
      color: Colors.amber.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.offline_bolt, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _t(
                'Showing verified Karachi emergency services (offline data). Tap refresh to load live map.',
                'تصدیق شدہ کراچی ہنگامی خدمات دکھائی جا رہی ہیں (آف لائن)۔ لائیو نقشے کے لیے ریفریش کریں۔',
              ),
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          TextButton(
            onPressed: _tryLoadOverpassPois,
            child: Text(
              _t('REFRESH', 'تازہ کریں'),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
      {required Color barBg, required Color onSurface}) {
    return Container(
      height: 46,
      color: barBg,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: _PoiType.values.map((t) {
          final on = _visible.contains(t);
          final count = _pois.where((p) => p.type == t).length;
          final labelColor = on
              ? Colors.white
              : (_isDark ? Colors.white54 : Colors.black54);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(
                '${_poiLabel(t)} ($count)',
                style: TextStyle(fontSize: 11, color: labelColor),
              ),
              selected: on,
              selectedColor: _poiColor(t),
              backgroundColor:
                  _isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              onSelected: (v) => setState(() {
                if (v) {
                  _visible.add(t);
                } else {
                  _visible.remove(t);
                }
              }),
              visualDensity: VisualDensity.compact,
              showCheckmark: false,
              avatar: Icon(_poiIcon(t),
                  size: 14, color: on ? Colors.white : _poiColor(t)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMap() {
    final visiblePois =
        _pois.where((p) => _visible.contains(p.type)).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userLocation,
        initialZoom: 12,
        maxZoom: 18,
        minZoom: 9,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.muhafiz_1',
          maxZoom: 18,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _userLocation,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.red.shade700, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 6),
                  ],
                ),
                child: Icon(Icons.my_location,
                    size: 20, color: Colors.red.shade700),
              ),
            ),
            ...visiblePois.map((p) => Marker(
                  point: p.pos,
                  width: 34,
                  height: 34,
                  child: GestureDetector(
                    onTap: () => _showPoiSheet(p),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _poiColor(p.type),
                        shape: BoxShape.circle,
                        border: p.isStatic
                            ? Border.all(color: Colors.white, width: 1.5)
                            : null,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black38,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Icon(_poiIcon(p.type),
                          size: 18, color: Colors.white),
                    ),
                  ),
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(
      {required Color barBg, required Color onMuted}) {
    return Container(
      color: barBg,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _PoiType.values
              .map((t) => Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_poiIcon(t), size: 14, color: _poiColor(t)),
                        const SizedBox(width: 3),
                        Text(_poiLabel(t),
                            style: TextStyle(
                                color: onMuted, fontSize: 10)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showPoiSheet(_Poi poi) {
    final sheetBg =
        _isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textPrimary = _isDark ? Colors.white : Colors.black87;
    final textMuted = _isDark ? Colors.white54 : Colors.black54;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _poiColor(poi.type),
                  child: Icon(_poiIcon(poi.type), color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_poiLabel(poi.type)}${poi.isStatic ? ' · ${_t('Verified', 'تصدیق شدہ')}' : ' · ${_t('Live', 'لائیو')}'}',
                        style: TextStyle(
                            color: _poiColor(poi.type),
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (poi.phone != null) ...[
              GestureDetector(
                onTap: () => launchUrl(Uri(scheme: 'tel', path: poi.phone)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? Colors.green.shade900
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade700),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Text(poi.phone!,
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const Spacer(),
                      Text(
                        _t('TAP TO CALL', 'کال کریں'),
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.directions, color: Colors.white),
                label: Text(
                  _t('Get Directions (OpenStreetMap)',
                      'راستہ دکھائیں (اوپن اسٹریٹ میپ)'),
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () => launchUrl(Uri.parse(
                  'https://www.openstreetmap.org/directions?to=${poi.pos.latitude},${poi.pos.longitude}',
                )),
              ),
            ),
            if (!_isDark) ...[
              const SizedBox(height: 4),
              Text(
                _t('Verified static data · tap marker to navigate',
                    'تصدیق شدہ ڈیٹا · نیویگیشن کے لیے ٹیپ کریں'),
                style: TextStyle(color: textMuted, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
