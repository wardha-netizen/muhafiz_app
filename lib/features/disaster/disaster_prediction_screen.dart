import 'package:flutter/material.dart';
import '../../services/air_quality_service.dart';
import '../../services/earthquake_service.dart';
import '../../services/marine_service.dart';
import '../../services/weather_service.dart';

class DisasterPredictionScreen extends StatefulWidget {
  const DisasterPredictionScreen({super.key});

  @override
  State<DisasterPredictionScreen> createState() =>
      _DisasterPredictionScreenState();
}

class _DisasterPredictionScreenState extends State<DisasterPredictionScreen> {
  WeatherData? _weather;
  AirQualityData? _airQuality;
  MarineData? _marine;
  List<EarthquakeEvent> _quakes = [];
  List<DisasterRisk> _risks = [];
  bool _loading = true;
  String? _error;
  DateTime? _lastFetch;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // All APIs are 100% free — no key needed
      final results = await Future.wait([
        WeatherService.fetchKarachiWeather(),
        EarthquakeService.fetchNearKarachi(days: 7, minMagnitude: 2.0, radiusKm: 500),
        AirQualityService.fetchKarachiAirQuality(),
        MarineService.fetchArabianSeaData(),
      ]);

      final w = results[0] as WeatherData;
      final q = results[1] as List<EarthquakeEvent>;
      final aq = results[2] as AirQualityData;
      final m = results[3] as MarineData;

      final risks = [
        WeatherService.assessFireRisk(w),
        WeatherService.assessFloodRisk(w),
        WeatherService.assessCycloneRisk(w),
        WeatherService.assessHeatwaveRisk(w),
        WeatherService.assessDustStormRisk(w),
        WeatherService.assessNonNaturalRisk(w),
        EarthquakeService.assessEarthquakeRisk(q),
        AirQualityService.assessAirQualityRisk(aq),
        MarineService.assessCoastalRisk(m),
      ];
      risks.sort((a, b) => b.level.index.compareTo(a.level.index));

      if (mounted) {
        setState(() {
          _weather = w;
          _quakes = q;
          _airQuality = aq;
          _marine = m;
          _risks = risks;
          _loading = false;
          _lastFetch = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Pre-Disaster Analysis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_lastFetch != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  'Updated ${_timeSince(_lastFetch!)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loading ? null : _fetchAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text(
                    'Fetching live data…\nOpen-Meteo · USGS · Air Quality · Marine',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.signal_wifi_off, color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            const Text('Could not load live data.',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _fetchAll,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Overall threat level = highest risk level across all assessments
    final highestLevel = _risks.isEmpty ? RiskLevel.safe : _risks.first.level;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOverallStatus(highestLevel),
        const SizedBox(height: 16),
        if (_weather != null) _buildWeatherCard(),
        const SizedBox(height: 16),
        _buildSectionLabel('DISASTER RISK ASSESSMENTS — ${_risks.length} categories'),
        const SizedBox(height: 8),
        ..._risks.map(_buildRiskCard),
        const SizedBox(height: 8),
        if (_quakes.isNotEmpty) _buildQuakeList(),
        const SizedBox(height: 16),
        _buildDataSourceNote(),
      ],
    );
  }

  // ── Overall threat banner ──────────────────────────────────────────────────
  Widget _buildOverallStatus(RiskLevel level) {
    final col = _levelColor(level);
    final label = _levelLabel(level);
    final criticalCount = _risks.where((r) => r.level == RiskLevel.critical).length;
    final warningCount = _risks.where((r) => r.level == RiskLevel.warning).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [col.withValues(alpha: 0.25), col.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: col.withValues(alpha: 0.2),
            child: Icon(_levelIcon(level), color: col, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Karachi — Overall Threat: $label',
                  style: TextStyle(
                      color: col, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  criticalCount > 0
                      ? '$criticalCount CRITICAL · $warningCount WARNING across ${_risks.length} categories'
                      : warningCount > 0
                          ? '$warningCount WARNING conditions detected'
                          : 'No significant threats detected',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
          color: Colors.white38, fontSize: 10, letterSpacing: 1.2),
    );
  }

  // ── Current conditions strip ───────────────────────────────────────────────
  Widget _buildWeatherCard() {
    final w = _weather!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KARACHI — CURRENT CONDITIONS',
            style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricTile(Icons.thermostat,
                  '${w.temperature.toStringAsFixed(1)}°C', 'Temp'),
              _metricTile(Icons.device_thermostat,
                  '${w.apparentTemperature.toStringAsFixed(1)}°C', 'Feels'),
              _metricTile(Icons.water_drop,
                  '${w.humidity.toStringAsFixed(0)}%', 'Humidity'),
              _metricTile(Icons.air,
                  '${w.windSpeed.toStringAsFixed(0)} km/h', 'Wind'),
              _metricTile(Icons.grain,
                  '${w.precipitation.toStringAsFixed(1)} mm', 'Rain'),
            ],
          ),
          const SizedBox(height: 12),
          if (_airQuality != null) ...[
            Row(
              children: [
                _pillBadge(
                    'AQI ${_airQuality!.europeanAqi.toInt()}',
                    _airQuality!.europeanAqi > 100
                        ? Colors.red
                        : _airQuality!.europeanAqi > 50
                            ? Colors.orange
                            : Colors.green),
                const SizedBox(width: 8),
                _pillBadge(
                    'Dust ${_airQuality!.dust.toStringAsFixed(0)} μg/m³',
                    _airQuality!.dust > 200 ? Colors.orange : Colors.green),
                const SizedBox(width: 8),
                if (_marine != null)
                  _pillBadge(
                      'Waves ${_marine!.waveHeight.toStringAsFixed(1)} m',
                      _marine!.waveHeight > 2.5 ? Colors.orange : Colors.green),
              ],
            ),
            const SizedBox(height: 10),
          ],
          LinearProgressIndicator(
            value: w.precipProbability / 100,
            backgroundColor: Colors.white12,
            color: w.precipProbability > 70
                ? Colors.red
                : w.precipProbability > 40
                    ? Colors.orange
                    : Colors.green,
          ),
          const SizedBox(height: 4),
          Text(
            'Rain probability: ${w.precipProbability.toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _pillBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _metricTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  // ── Risk card ──────────────────────────────────────────────────────────────
  Widget _buildRiskCard(DisasterRisk risk) {
    final col = _levelColor(risk.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.withValues(alpha: 0.4)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.dark(primary: col),
        ),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: col.withValues(alpha: 0.15),
            child: Icon(_typeIcon(risk.type), color: col, size: 20),
          ),
          title: Text(
            risk.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          trailing: _levelBadge(risk.level),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(risk.description,
                      style: TextStyle(color: col, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 10),
                  ...risk.indicators.map(
                    (ind) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right,
                              size: 16, color: Colors.white54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(ind,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelBadge(RiskLevel level) {
    final col = _levelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col),
      ),
      child: Text(
        _levelLabel(level),
        style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── Earthquake event list ──────────────────────────────────────────────────
  Widget _buildQuakeList() {
    final recent = _quakes.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'RECENT SEISMIC EVENTS (USGS)',
            style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2),
          ),
        ),
        ...recent.map((q) {
          final magCol = q.magnitude >= 5.0
              ? Colors.red
              : q.magnitude >= 4.0
                  ? Colors.orange
                  : Colors.yellow;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: magCol.withValues(alpha: 0.15),
                  child: Text(
                    'M${q.magnitude.toStringAsFixed(1)}',
                    style: TextStyle(
                        color: magCol,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.place,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '${q.distanceKm.toStringAsFixed(0)} km · ${q.depthKm.toStringAsFixed(0)} km deep · ${q.timeAgo}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Data sources ───────────────────────────────────────────────────────────
  Widget _buildDataSourceNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DATA SOURCES — ALL FREE, NO API KEY REQUIRED',
            style: TextStyle(
                color: Colors.white38, fontSize: 10, letterSpacing: 1.1),
          ),
          SizedBox(height: 8),
          Text('• Weather & Heatwave:   Open-Meteo (open-meteo.com)',
              style: TextStyle(color: Colors.white24, fontSize: 11)),
          Text('• Air Quality & Dust:   Open-Meteo Air Quality API',
              style: TextStyle(color: Colors.white24, fontSize: 11)),
          Text('• Coastal & Marine:     Open-Meteo Marine API (Arabian Sea)',
              style: TextStyle(color: Colors.white24, fontSize: 11)),
          Text('• Seismic Activity:     USGS Earthquake Hazards Program',
              style: TextStyle(color: Colors.white24, fontSize: 11)),
          Text('• All data refreshes on demand. Internet required for live data.',
              style: TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _levelColor(RiskLevel l) {
    switch (l) {
      case RiskLevel.critical:
        return Colors.red;
      case RiskLevel.warning:
        return Colors.orange;
      case RiskLevel.watch:
        return Colors.yellow;
      case RiskLevel.safe:
        return Colors.green;
    }
  }

  String _levelLabel(RiskLevel l) {
    switch (l) {
      case RiskLevel.critical:
        return 'CRITICAL';
      case RiskLevel.warning:
        return 'WARNING';
      case RiskLevel.watch:
        return 'WATCH';
      case RiskLevel.safe:
        return 'SAFE';
    }
  }

  IconData _levelIcon(RiskLevel l) {
    switch (l) {
      case RiskLevel.critical:
        return Icons.dangerous;
      case RiskLevel.warning:
        return Icons.warning_amber;
      case RiskLevel.watch:
        return Icons.visibility;
      case RiskLevel.safe:
        return Icons.check_circle_outline;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Fire':
        return Icons.local_fire_department;
      case 'Flood':
        return Icons.water;
      case 'Cyclone':
        return Icons.cyclone;
      case 'Heatwave':
        return Icons.thermostat;
      case 'DustStorm':
        return Icons.blur_on;
      case 'NonNatural':
        return Icons.factory;
      case 'Earthquake':
        return Icons.show_chart;
      case 'AirQuality':
        return Icons.air;
      case 'Coastal':
        return Icons.waves;
      default:
        return Icons.warning_amber;
    }
  }

  String _timeSince(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
