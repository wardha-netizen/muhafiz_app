import 'dart:convert';
import 'package:http/http.dart' as http;

// Karachi, Pakistan
const double karachiLat = 24.8607;
const double karachiLng = 67.0011;

enum RiskLevel { safe, watch, warning, critical }

class WeatherData {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final double precipitation;
  final double precipProbability;
  final double apparentTemperature; // Heat index / feels-like temperature
  final DateTime fetchedAt;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.precipProbability,
    required this.apparentTemperature,
    required this.fetchedAt,
  });
}

class DisasterRisk {
  final RiskLevel level;
  final String type;
  final String title;
  final String description;
  final List<String> indicators;

  const DisasterRisk({
    required this.level,
    required this.type,
    required this.title,
    required this.description,
    required this.indicators,
  });

  String get levelLabel {
    switch (level) {
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
}

class WeatherService {
  // Open-Meteo API — 100% free, no API key needed
  static const _base = 'https://api.open-meteo.com/v1/forecast';

  static Future<WeatherData> fetchKarachiWeather() async {
    final uri = Uri.parse(
      '$_base'
      '?latitude=$karachiLat&longitude=$karachiLng'
      '&current=temperature_2m,relative_humidity_2m,'
      'wind_speed_10m,precipitation,weather_code,apparent_temperature'
      '&hourly=precipitation_probability'
      '&timezone=Asia%2FKarachi'
      '&forecast_days=1',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Weather API ${response.statusCode}');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final cur = body['current'] as Map<String, dynamic>;
    final hourly = body['hourly'] as Map<String, dynamic>;
    final probList = (hourly['precipitation_probability'] as List).cast<num>();

    return WeatherData(
      temperature: (cur['temperature_2m'] as num).toDouble(),
      humidity: (cur['relative_humidity_2m'] as num).toDouble(),
      windSpeed: (cur['wind_speed_10m'] as num).toDouble(),
      precipitation: (cur['precipitation'] as num).toDouble(),
      precipProbability: probList.isEmpty ? 0 : probList.first.toDouble(),
      apparentTemperature: (cur['apparent_temperature'] as num).toDouble(),
      fetchedAt: DateTime.now(),
    );
  }

  // ── Fire Risk ──────────────────────────────────────────────────────────────
  static DisasterRisk assessFireRisk(WeatherData w) {
    final ind = <String>[];
    var score = 0;

    if (w.temperature > 40) {
      score += 3;
      ind.add('Extreme heat: ${w.temperature.toStringAsFixed(1)}°C');
    } else if (w.temperature > 38) {
      score += 2;
      ind.add('Very high temp: ${w.temperature.toStringAsFixed(1)}°C');
    } else if (w.temperature > 35) {
      score += 1;
      ind.add('High temp: ${w.temperature.toStringAsFixed(1)}°C');
    }

    if (w.humidity < 15) {
      score += 3;
      ind.add('Critically dry: ${w.humidity.toStringAsFixed(0)}% RH');
    } else if (w.humidity < 25) {
      score += 2;
      ind.add('Very dry: ${w.humidity.toStringAsFixed(0)}% RH');
    } else if (w.humidity < 35) {
      score += 1;
      ind.add('Low humidity: ${w.humidity.toStringAsFixed(0)}% RH');
    }

    if (w.windSpeed > 50) {
      score += 2;
      ind.add('Strong wind: ${w.windSpeed.toStringAsFixed(0)} km/h');
    } else if (w.windSpeed > 30) {
      score += 1;
      ind.add('Gusty: ${w.windSpeed.toStringAsFixed(0)} km/h');
    }

    if (w.precipitation < 0.5 && w.precipProbability < 10) {
      score += 1;
      ind.add('No rainfall expected');
    }

    final level = score >= 6
        ? RiskLevel.critical
        : score >= 4
            ? RiskLevel.warning
            : score >= 2
                ? RiskLevel.watch
                : RiskLevel.safe;

    return DisasterRisk(
      level: level,
      type: 'Fire',
      title: 'Fire & Heat Risk',
      description: level == RiskLevel.critical
          ? 'Extreme fire danger! Avoid open flames. Stay hydrated and indoors.'
          : level == RiskLevel.warning
              ? 'High fire risk. Dry and hot conditions favour rapid fire spread.'
              : level == RiskLevel.watch
                  ? 'Moderate risk. Avoid burning waste outdoors.'
                  : 'No significant fire risk. Conditions are normal.',
      indicators: ind.isEmpty ? ['Temperature and humidity within safe range'] : ind,
    );
  }

  // ── Flood Risk ─────────────────────────────────────────────────────────────
  static DisasterRisk assessFloodRisk(WeatherData w) {
    final ind = <String>[];
    var score = 0;

    if (w.precipitation > 50) {
      score += 4;
      ind.add('Heavy rain: ${w.precipitation.toStringAsFixed(1)} mm');
    } else if (w.precipitation > 20) {
      score += 2;
      ind.add('Significant rainfall: ${w.precipitation.toStringAsFixed(1)} mm');
    } else if (w.precipitation > 5) {
      score += 1;
      ind.add('Light rain: ${w.precipitation.toStringAsFixed(1)} mm');
    }

    if (w.precipProbability > 85) {
      score += 2;
      ind.add('Heavy rain forecast: ${w.precipProbability.toStringAsFixed(0)}% chance');
    } else if (w.precipProbability > 60) {
      score += 1;
      ind.add('Rain likely: ${w.precipProbability.toStringAsFixed(0)}%');
    }

    if (w.windSpeed > 60) {
      score += 1;
      ind.add('Storm-force winds can worsen flooding');
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
      type: 'Flood',
      title: 'Flood & Storm Risk',
      description: level == RiskLevel.critical
          ? 'Flash flood alert! Avoid low-lying areas and nullahs. Evacuate if needed.'
          : level == RiskLevel.warning
              ? 'Flooding possible. Avoid coastal areas and blocked drainage areas.'
              : level == RiskLevel.watch
                  ? 'Monitor rainfall. Nullahs may overflow if rain persists.'
                  : 'No flood risk. Conditions are dry.',
      indicators: ind.isEmpty ? ['No significant rainfall'] : ind,
    );
  }

  // ── Cyclone / Storm Risk ───────────────────────────────────────────────────
  static DisasterRisk assessCycloneRisk(WeatherData w) {
    final ind = <String>[];
    var score = 0;

    if (w.windSpeed > 90) {
      score += 4;
      ind.add('Cyclonic winds: ${w.windSpeed.toStringAsFixed(0)} km/h');
    } else if (w.windSpeed > 60) {
      score += 2;
      ind.add('Severe storm winds: ${w.windSpeed.toStringAsFixed(0)} km/h');
    } else if (w.windSpeed > 40) {
      score += 1;
      ind.add('Strong winds: ${w.windSpeed.toStringAsFixed(0)} km/h');
    }

    if (w.windSpeed > 40 && w.precipitation > 20) {
      score += 2;
      ind.add('Combined wind + rain threat');
    }

    if (w.precipProbability > 70 && w.windSpeed > 30) {
      score += 1;
      ind.add('Stormy conditions forecast');
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
      type: 'Cyclone',
      title: 'Cyclone & Storm Risk',
      description: level == RiskLevel.critical
          ? 'Cyclone-level threat! Seek strong shelter immediately. Do NOT go outside.'
          : level == RiskLevel.warning
              ? 'Severe storm conditions. Secure loose objects. Avoid sea and coastal areas.'
              : level == RiskLevel.watch
                  ? 'Gusty conditions. Monitor weather updates hourly.'
                  : 'No storm or cyclone threat.',
      indicators: ind.isEmpty ? ['Calm wind conditions'] : ind,
    );
  }

  // ── Heatwave Risk (Karachi-specific: apparent temp / heat index) ──────────
  static DisasterRisk assessHeatwaveRisk(WeatherData w) {
    final ind = <String>[];
    var score = 0;

    // Apparent temperature (heat index) is more dangerous than raw temp
    if (w.apparentTemperature > 52) {
      score += 4;
      ind.add('Lethal heat index: ${w.apparentTemperature.toStringAsFixed(1)}°C (feels like)');
    } else if (w.apparentTemperature > 47) {
      score += 3;
      ind.add('Extreme heat index: ${w.apparentTemperature.toStringAsFixed(1)}°C (feels like)');
    } else if (w.apparentTemperature > 42) {
      score += 2;
      ind.add('Dangerous heat: ${w.apparentTemperature.toStringAsFixed(1)}°C (feels like)');
    } else if (w.apparentTemperature > 38) {
      score += 1;
      ind.add('Hot: ${w.apparentTemperature.toStringAsFixed(1)}°C (feels like)');
    }

    // Karachi 2015 heatwave killed 1,200+ (high humidity + heat = deadly)
    if (w.temperature > 40 && w.humidity > 40) {
      score += 2;
      ind.add('Humid heat: ${w.temperature.toStringAsFixed(0)}°C + ${w.humidity.toStringAsFixed(0)}% RH — heatstroke risk');
    }

    // No wind = no evaporative cooling (lethal in Karachi summers)
    if (w.temperature > 38 && w.windSpeed < 10) {
      score += 1;
      ind.add('Stagnant hot air: no wind cooling, heat accumulates in buildings');
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
      type: 'Heatwave',
      title: 'Heatwave & Heat Stroke',
      description: level == RiskLevel.critical
          ? 'LETHAL heat conditions! Stay indoors with AC. Drink ORS every 30 min. Call 1122/115 for heat stroke.'
          : level == RiskLevel.warning
              ? 'Dangerous heat. Avoid going outside 11 AM–4 PM. Keep elderly and children hydrated. Watch for heat exhaustion.'
              : level == RiskLevel.watch
                  ? 'Hot conditions. Drink plenty of water. Wear light loose clothing. Limit outdoor activity.'
                  : 'Temperature within normal Karachi range.',
      indicators: ind.isEmpty ? ['Temperature within safe range'] : ind,
    );
  }

  // ── Dust Storm Risk (Karachi-specific: April–June season) ─────────────────
  static DisasterRisk assessDustStormRisk(WeatherData w) {
    final ind = <String>[];
    var score = 0;

    // Primary conditions: low humidity + high wind + no rain = dust storm
    if (w.humidity < 15 && w.windSpeed > 40) {
      score += 4;
      ind.add('Dust storm likely: ${w.humidity.toStringAsFixed(0)}% RH + ${w.windSpeed.toStringAsFixed(0)} km/h wind');
    } else if (w.humidity < 20 && w.windSpeed > 30) {
      score += 3;
      ind.add('High dust risk: very dry + gusty (${w.windSpeed.toStringAsFixed(0)} km/h)');
    } else if (w.humidity < 30 && w.windSpeed > 25) {
      score += 2;
      ind.add('Moderate dust: dry air + wind — reduced visibility possible');
    } else if (w.windSpeed > 35 && w.precipitation < 0.5) {
      score += 1;
      ind.add('Gusty dry conditions — dust nuisance likely');
    }

    // No rain means dust stays airborne longer
    if (w.precipitation < 0.1 && w.precipProbability < 10 && w.humidity < 25) {
      score += 1;
      ind.add('No rainfall to suppress dust — conditions persist');
    }

    final level = score >= 4
        ? RiskLevel.critical
        : score >= 2
            ? RiskLevel.warning
            : score >= 1
                ? RiskLevel.watch
                : RiskLevel.safe;

    return DisasterRisk(
      level: level,
      type: 'DustStorm',
      title: 'Dust Storm & Visibility',
      description: level == RiskLevel.critical
          ? 'Dust storm! Stay indoors, seal windows/doors. Wear N95 mask. Road visibility near zero — avoid driving.'
          : level == RiskLevel.warning
              ? 'Blowing dust reduces visibility. Wear a face covering outdoors. Drive slowly and use headlights.'
              : level == RiskLevel.watch
                  ? 'Dusty conditions. Keep windows closed. Rinse eyes if irritated.'
                  : 'No dust storm threat. Air circulation normal.',
      indicators: ind.isEmpty ? ['Wind and humidity within normal range'] : ind,
    );
  }

  // ── Non-natural risk (Karachi-specific criteria) ──────────────────────────
  static DisasterRisk assessNonNaturalRisk(WeatherData w) {
    final ind = <String>[];
    var score = 0;

    // Power outage risk: extreme heat drives K-Electric overload
    final hour = DateTime.now().hour;
    final isPeakHour = hour >= 12 && hour <= 20;
    if (w.temperature > 40 && isPeakHour) {
      score += 2;
      ind.add('Peak cooling demand (${w.temperature.toStringAsFixed(0)}°C, $hour:00): K-Electric load-shedding likely');
    }

    // Road accident risk: rain + rush hour
    final isRushHour = (hour >= 7 && hour <= 9) || (hour >= 16 && hour <= 19);
    if (w.precipitation > 10 && isRushHour) {
      score += 2;
      ind.add('Rain + rush hour: slippery roads, high accident risk on Karachi roads');
    } else if (w.precipitation > 5) {
      score += 1;
      ind.add('Wet roads: reduce speed, avoid underpass areas (flooding risk)');
    }

    // Industrial accident risk: SITE/Port Qasim — fumes concentrate in low wind
    if (w.windSpeed < 8 && w.temperature > 35) {
      score += 1;
      ind.add('Low wind + heat: industrial fumes may concentrate in SITE/Port Qasim area');
    }

    // Structural fire risk: faulty wiring + extreme heat
    if (w.temperature > 42) {
      score += 1;
      ind.add('Extreme heat increases electrical failure and structural fire risk');
    }

    // Crowd health risk during festivals/prayers in heat
    if (w.apparentTemperature > 45) {
      score += 1;
      ind.add('Crowd heat emergency risk at mosques, markets, and outdoor gatherings');
    }

    // Gas dispersal risk: high wind disperses LPG leaks faster (lowers risk)
    // but low wind + gas = explosion risk
    if (w.windSpeed < 5 && w.humidity < 20) {
      score += 1;
      ind.add('Stagnant air: gas leaks from SSGC pipelines may accumulate — check home lines');
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
      type: 'NonNatural',
      title: 'Urban & Industrial Risk',
      description: level == RiskLevel.critical
          ? 'Multiple hazard conditions active! Expect road accidents, power failures, and industrial incidents.'
          : level == RiskLevel.warning
              ? 'Elevated urban risk. Drive carefully, check gas lines, and prepare for possible load-shedding.'
              : level == RiskLevel.watch
                  ? 'Some adverse conditions. Stay informed and take routine precautions.'
                  : 'Normal urban conditions. No elevated non-natural risks.',
      indicators: ind.isEmpty ? ['Normal environmental and urban conditions'] : ind,
    );
  }
}
