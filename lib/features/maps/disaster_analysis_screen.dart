import 'package:flutter/material.dart';

class DisasterAnalysisScreen extends StatefulWidget {
  const DisasterAnalysisScreen({super.key});

  @override
  State<DisasterAnalysisScreen> createState() => _DisasterAnalysisScreenState();
}

class _DisasterAnalysisScreenState extends State<DisasterAnalysisScreen> {
  // Fire standards
  final double normalSmokePPM = 15.0;
  final double normalHumidity = 45.0;

  // Quake standards
  final double pWaveSpeedKmS = 6.0;
  final double sWaveSpeedKmS = 3.5;

  // Flood standards
  final double dangerousWaterLevelCm = 100.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scientific Disaster Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFireAnalysis(smoke: 120.5, humidity: 12.0),
          const SizedBox(height: 20),
          _buildQuakeAnalysis(pArrivalTime: 2.0, sArrivalTime: 14.0),
          const SizedBox(height: 20),
          _buildFloodAnalysis(currentLevel: 115.0),
        ],
      ),
    );
  }

  Widget _buildFireAnalysis({required double smoke, required double humidity}) {
    final isFireRisk =
        smoke > (normalSmokePPM * 5) && humidity < (normalHumidity / 2);

    return _buildAnalysisCard(
      title: 'Fire & Air Quality Analysis',
      icon: Icons.whatshot,
      color: Colors.orange,
      content: Column(
        children: [
          _analysisRow(
            'Smoke (CO2/PPM)',
            '$smoke',
            '$normalSmokePPM',
            smoke > normalSmokePPM,
          ),
          _analysisRow(
            'Rel. Humidity',
            '$humidity%',
            '$normalHumidity%',
            humidity < normalHumidity,
          ),
          const Divider(),
          Text(
            isFireRisk
                ? 'CONCLUSION: Drastic smoke increase + humidity drop confirmed. High fire probability.'
                : 'CONCLUSION: Atmospheric levels within manageable range.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isFireRisk ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuakeAnalysis({
    required double pArrivalTime,
    required double sArrivalTime,
  }) {
    final timeDiff = sArrivalTime - pArrivalTime;
    final distance = timeDiff / (1 / sWaveSpeedKmS - 1 / pWaveSpeedKmS);

    return _buildAnalysisCard(
      title: 'Seismic Wave Analysis',
      icon: Icons.waves,
      color: Colors.blueGrey,
      content: Column(
        children: [
          _analysisRow('P-Wave Arrival', '${pArrivalTime}s', '0.0s', true),
          _analysisRow('S-Wave Arrival', '${sArrivalTime}s', 'N/A', true),
          _analysisRow('P-S Interval', '${timeDiff}s', '< 5s (Local)', timeDiff > 5),
          const Divider(),
          Text(
            'ESTIMATED EPICENTER: ${distance.toStringAsFixed(2)} km away.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFloodAnalysis({required double currentLevel}) {
    final isDangerous = currentLevel > dangerousWaterLevelCm;

    return _buildAnalysisCard(
      title: 'Flood Hydrology Analysis',
      icon: Icons.tsunami,
      color: Colors.blue,
      content: Column(
        children: [
          _analysisRow(
            'Water Level',
            '${currentLevel}cm',
            '${dangerousWaterLevelCm}cm',
            isDangerous,
          ),
          const Divider(),
          Text(
            isDangerous
                ? 'CRITICAL: Current level exceeds safe depth standards!'
                : 'SAFE: Levels below flood threshold.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDangerous ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            content,
          ],
        ),
      ),
    );
  }

  Widget _analysisRow(
    String label,
    String current,
    String standard,
    bool isAbnormal,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(
                current,
                style: TextStyle(
                  color: isAbnormal ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(' | Std: '),
              Text(standard, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
