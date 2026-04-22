import 'dart:convert';
import 'package:http/http.dart' as http;
import 'weather_service.dart';

// Offshore Arabian Sea point near Karachi coast
const double _marineLat = 24.5;
const double _marineLng = 66.5;

class MarineData {
  final double waveHeight;
  final double swellWaveHeight;
  final double windWaveHeight;
  final DateTime fetchedAt;

  const MarineData({
    required this.waveHeight,
    required this.swellWaveHeight,
    required this.windWaveHeight,
    required this.fetchedAt,
  });
}

class MarineService {
  // Open-Meteo Marine API — 100% free, no API key needed
  static const _base = 'https://marine-api.open-meteo.com/v1/marine';

  static Future<MarineData> fetchArabianSeaData() async {
    final uri = Uri.parse(
      '$_base'
      '?latitude=$_marineLat&longitude=$_marineLng'
      '&current=wave_height,swell_wave_height,wind_wave_height'
      '&timezone=Asia%2FKarachi',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Marine API ${response.statusCode}');
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final cur = body['current'] as Map<String, dynamic>;

    return MarineData(
      waveHeight: (cur['wave_height'] as num?)?.toDouble() ?? 0,
      swellWaveHeight: (cur['swell_wave_height'] as num?)?.toDouble() ?? 0,
      windWaveHeight: (cur['wind_wave_height'] as num?)?.toDouble() ?? 0,
      fetchedAt: DateTime.now(),
    );
  }

  static DisasterRisk assessCoastalRisk(MarineData d) {
    final ind = <String>[];
    var score = 0;

    // Wave height thresholds for Arabian Sea / Karachi coast
    if (d.waveHeight > 4.0) {
      score += 4;
      ind.add('Dangerous waves: ${d.waveHeight.toStringAsFixed(1)} m — storm surge risk');
    } else if (d.waveHeight > 2.5) {
      score += 2;
      ind.add('Rough seas: ${d.waveHeight.toStringAsFixed(1)} m');
    } else if (d.waveHeight > 1.5) {
      score += 1;
      ind.add('Moderate waves: ${d.waveHeight.toStringAsFixed(1)} m');
    }

    // Swell from distant storms can push storm surge into Karachi
    if (d.swellWaveHeight > 3.0) {
      score += 2;
      ind.add('Large ocean swell: ${d.swellWaveHeight.toStringAsFixed(1)} m — coastal flooding possible');
    } else if (d.swellWaveHeight > 2.0) {
      score += 1;
      ind.add('Elevated swell: ${d.swellWaveHeight.toStringAsFixed(1)} m — avoid Clifton/Seaview');
    }

    // Wind waves indicate local storm strength
    if (d.windWaveHeight > 2.0) {
      score += 1;
      ind.add('High local wind waves: ${d.windWaveHeight.toStringAsFixed(1)} m');
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
      type: 'Coastal',
      title: 'Coastal & Storm Surge Risk',
      description: level == RiskLevel.critical
          ? 'Dangerous sea conditions! Evacuate coastal areas. Clifton, Seaview, Hawks Bay at risk. Storm surge possible.'
          : level == RiskLevel.warning
              ? 'Rough Arabian Sea. Avoid all coastal areas and waterfront (Clifton, Seaview, Port). No fishing.'
              : level == RiskLevel.watch
                  ? 'Moderate sea conditions. Exercise caution near Karachi coastline.'
                  : 'Calm Arabian Sea — no coastal threat.',
      indicators: ind.isEmpty ? ['Calm seas — Arabian Sea conditions normal'] : ind,
    );
  }
}
