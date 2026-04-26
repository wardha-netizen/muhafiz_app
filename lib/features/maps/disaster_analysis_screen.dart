import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_provider.dart';

class DisasterAnalysisScreen extends StatefulWidget {
  const DisasterAnalysisScreen({super.key});

  @override
  State<DisasterAnalysisScreen> createState() => _DisasterAnalysisScreenState();
}

class _DisasterAnalysisScreenState extends State<DisasterAnalysisScreen> {
  bool _isUrdu = false;

  final double normalSmokePPM = 15.0;
  final double normalHumidity = 45.0;
  final double pWaveSpeedKmS = 6.0;
  final double sWaveSpeedKmS = 3.5;
  final double dangerousWaterLevelCm = 100.0;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF6F7FB);
  Color get _surface => _isDark ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _onSurface => _isDark ? Colors.white : Colors.black87;
  Color get _onMuted => _isDark ? Colors.white60 : Colors.black54;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Scientific Disaster Analysis', 'سائنسی آفات تجزیہ'),
              style: TextStyle(
                  color: _onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            Text(
              _t('Real-time risk metrics', 'حقیقی وقت خطرے کا اشارہ'),
              style: TextStyle(color: _onMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          // Language toggle
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => setState(() => _isUrdu = !_isUrdu),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isUrdu
                      ? Colors.green.withValues(alpha: 0.18)
                      : (_isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isUrdu
                        ? Colors.green.withValues(alpha: 0.6)
                        : (_isDark ? Colors.white24 : Colors.black12),
                  ),
                ),
                child: Text(
                  _isUrdu ? 'EN' : 'اردو',
                  style: TextStyle(
                    color: _isUrdu ? Colors.green : _onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Theme toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () =>
                  Provider.of<SettingsProvider>(context, listen: false)
                      .toggleTheme(!_isDark),
              icon: Icon(
                _isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: _onSurface,
                size: 20,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFireAnalysis(smoke: 120.5, humidity: 12.0),
          const SizedBox(height: 20),
          _buildQuakeAnalysis(pArrivalTime: 2.0, sArrivalTime: 14.0),
          const SizedBox(height: 20),
          _buildFloodAnalysis(currentLevel: 115.0),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFireAnalysis(
      {required double smoke, required double humidity}) {
    final isFireRisk =
        smoke > (normalSmokePPM * 5) && humidity < (normalHumidity / 2);

    return _buildAnalysisCard(
      title: _t('Fire & Air Quality Analysis', 'آگ اور ہوا کے معیار کا تجزیہ'),
      icon: Icons.whatshot,
      color: Colors.orange,
      content: Column(
        children: [
          _analysisRow(
            _t('Smoke (CO2/PPM)', 'دھواں (CO2/PPM)'),
            '$smoke',
            '$normalSmokePPM',
            smoke > normalSmokePPM,
          ),
          _analysisRow(
            _t('Rel. Humidity', 'رشتہ دار نمی'),
            '$humidity%',
            '$normalHumidity%',
            humidity < normalHumidity,
          ),
          Divider(color: _isDark ? Colors.white12 : Colors.black12),
          Text(
            isFireRisk
                ? _t(
                    'CONCLUSION: Drastic smoke increase + humidity drop confirmed. High fire probability.',
                    'نتیجہ: دھوئیں میں شدید اضافہ + نمی میں کمی۔ آگ کا خطرہ زیادہ۔')
                : _t(
                    'CONCLUSION: Atmospheric levels within manageable range.',
                    'نتیجہ: فضائی سطح قابل انتظام حد میں۔'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isFireRisk ? Colors.red : Colors.green,
            ),
            textDirection:
                _isUrdu ? TextDirection.rtl : TextDirection.ltr,
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
    final distance =
        timeDiff / (1 / sWaveSpeedKmS - 1 / pWaveSpeedKmS);

    return _buildAnalysisCard(
      title: _t('Seismic Wave Analysis', 'زلزلہ لہر تجزیہ'),
      icon: Icons.waves,
      color: Colors.blueGrey,
      content: Column(
        children: [
          _analysisRow(
              _t('P-Wave Arrival', 'پی لہر آمد'), '${pArrivalTime}s', '0.0s', true),
          _analysisRow(
              _t('S-Wave Arrival', 'ایس لہر آمد'), '${sArrivalTime}s', 'N/A', true),
          _analysisRow(
              _t('P-S Interval', 'پی-ایس وقفہ'),
              '${timeDiff}s',
              _t('< 5s (Local)', '< 5 سیکنڈ (مقامی)'),
              timeDiff > 5),
          Divider(color: _isDark ? Colors.white12 : Colors.black12),
          Text(
            _t(
              'ESTIMATED EPICENTER: ${distance.toStringAsFixed(2)} km away.',
              'متوقع مرکز: ${distance.toStringAsFixed(2)} کلومیٹر دور۔',
            ),
            style:
                TextStyle(fontWeight: FontWeight.bold, color: _onSurface),
            textDirection:
                _isUrdu ? TextDirection.rtl : TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  Widget _buildFloodAnalysis({required double currentLevel}) {
    final isDangerous = currentLevel > dangerousWaterLevelCm;

    return _buildAnalysisCard(
      title: _t('Flood Hydrology Analysis', 'سیلاب آبیاتی تجزیہ'),
      icon: Icons.tsunami,
      color: Colors.blue,
      content: Column(
        children: [
          _analysisRow(
            _t('Water Level', 'پانی کی سطح'),
            '${currentLevel}cm',
            '${dangerousWaterLevelCm}cm',
            isDangerous,
          ),
          Divider(color: _isDark ? Colors.white12 : Colors.black12),
          Text(
            isDangerous
                ? _t(
                    'CRITICAL: Current level exceeds safe depth standards!',
                    'خطرناک: موجودہ سطح محفوظ گہرائی سے زیادہ!')
                : _t(
                    'SAFE: Levels below flood threshold.',
                    'محفوظ: سیلاب کی حد سے نیچے۔'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDangerous ? Colors.red : Colors.green,
            ),
            textDirection:
                _isUrdu ? TextDirection.rtl : TextDirection.ltr,
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
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: _isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _onSurface,
                    ),
                    textDirection:
                        _isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: _onMuted, fontSize: 13),
              textDirection:
                  _isUrdu ? TextDirection.rtl : TextDirection.ltr),
          Row(
            children: [
              Text(
                current,
                style: TextStyle(
                  color: isAbnormal ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '  |  ${_t('Std', 'معیار')}: ',
                style: TextStyle(color: _onMuted, fontSize: 12),
              ),
              Text(standard,
                  style: TextStyle(color: _onMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
