import 'dart:convert';
import 'package:http/http.dart' as http;
import 'weather_service.dart';

class AirQualityData {
  final double pm10;
  final double pm25;
  final double dust;
  final double europeanAqi;
  final DateTime fetchedAt;

  const AirQualityData({
    required this.pm10,
    required this.pm25,
    required this.dust,
    required this.europeanAqi,
    required this.fetchedAt,
  });
}

class AirQualityService {
  // Open-Meteo Air Quality API — 100% free, no API key needed
  static const _base = 'https://air-quality-api.open-meteo.com/v1/air-quality';

  static Future<AirQualityData> fetchKarachiAirQuality() async {
    final uri = Uri.parse(
      '$_base'
      '?latitude=$karachiLat&longitude=$karachiLng'
      '&current=pm10,pm2_5,dust,european_aqi'
      '&timezone=Asia%2FKarachi',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Air Quality API ${response.statusCode}');
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final cur = body['current'] as Map<String, dynamic>;

    return AirQualityData(
      pm10: (cur['pm10'] as num?)?.toDouble() ?? 0,
      pm25: (cur['pm2_5'] as num?)?.toDouble() ?? 0,
      dust: (cur['dust'] as num?)?.toDouble() ?? 0,
      europeanAqi: (cur['european_aqi'] as num?)?.toDouble() ?? 0,
      fetchedAt: DateTime.now(),
    );
  }

  static DisasterRisk assessAirQualityRisk(AirQualityData d) {
    final ind = <String>[];
    var score = 0;

    // European AQI: >150 = Very Poor, >100 = Poor, >50 = Moderate
    if (d.europeanAqi > 150) {
      score += 3;
      ind.add('Very poor air quality (AQI: ${d.europeanAqi.toInt()})');
    } else if (d.europeanAqi > 100) {
      score += 2;
      ind.add('Poor air quality (AQI: ${d.europeanAqi.toInt()})');
    } else if (d.europeanAqi > 50) {
      score += 1;
      ind.add('Moderate air quality (AQI: ${d.europeanAqi.toInt()})');
    }

    // Dust concentration — Karachi is prone to dust storms (April–June)
    if (d.dust > 500) {
      score += 3;
      ind.add('Dust storm conditions: ${d.dust.toStringAsFixed(0)} μg/m³');
    } else if (d.dust > 200) {
      score += 2;
      ind.add('Heavy airborne dust: ${d.dust.toStringAsFixed(0)} μg/m³');
    } else if (d.dust > 50) {
      score += 1;
      ind.add('Elevated dust levels: ${d.dust.toStringAsFixed(0)} μg/m³');
    }

    // PM2.5 — fine particulate matter, health risk
    if (d.pm25 > 75) {
      score += 2;
      ind.add('Hazardous PM2.5: ${d.pm25.toStringAsFixed(0)} μg/m³ (WHO limit: 15)');
    } else if (d.pm25 > 35) {
      score += 1;
      ind.add('Elevated PM2.5: ${d.pm25.toStringAsFixed(0)} μg/m³');
    }

    // PM10 — coarse particulate (SITE industrial area, vehicular)
    if (d.pm10 > 150) {
      score += 1;
      ind.add('High PM10 (industrial/vehicular): ${d.pm10.toStringAsFixed(0)} μg/m³');
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
      type: 'AirQuality',
      title: 'Air Quality & Dust Storm',
      description: level == RiskLevel.critical
          ? 'Hazardous air quality! Stay indoors, seal windows. Wear N95 mask if going out. Dust storm possible.'
          : level == RiskLevel.warning
              ? 'Poor air. Limit outdoor exposure. Children, elderly, and asthma patients must stay home.'
              : level == RiskLevel.watch
                  ? 'Moderate pollution. Reduce strenuous outdoor activity. Monitor updates.'
                  : 'Air quality is acceptable for normal outdoor activities.',
      indicators: ind.isEmpty ? ['Air quality within normal range'] : ind,
    );
  }
}
