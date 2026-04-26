import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_provider.dart';

class OtherEmergencyResult {
  final String category;
  final String suggestedType;
  final String summary;

  const OtherEmergencyResult({
    required this.category,
    required this.suggestedType,
    required this.summary,
  });
}

class OtherEmergencyScreen extends StatefulWidget {
  const OtherEmergencyScreen({super.key});

  @override
  State<OtherEmergencyScreen> createState() => _OtherEmergencyScreenState();
}

class _OtherEmergencyScreenState extends State<OtherEmergencyScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, bool> _userAnswers = {};
  bool _isUrdu = false;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  List<String> get _questions => _isUrdu
      ? [
          'کیا خطرہ ماحول سے متعلق ہے (موسم، زمین، یا آگ)؟',
          'کیا اس سے متعدد عمارتیں یا بڑا علاقہ متاثر ہے؟',
          'کیا کوئی شخص نقصان پہنچانے کی نیت رکھتا ہے (ڈکیتی/حملہ)؟',
          'کیا آپ کو محفوظ رہنے کے لیے اپنا مقام چھپانا ہے؟',
          'کیا یہ اچانک صحت سے متعلق بحران ہے (طبی)؟',
        ]
      : [
          'Is the danger related to the environment (weather, earth, or fire)?',
          'Are multiple buildings or a large area affected by this?',
          'Is there a person actively intending to cause harm (Robbery/Assault)?',
          'Do you need to hide your location to stay safe?',
          'Is this a sudden health-related crisis (Medical)?',
        ];

  void _processAnswer(bool answer) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answer;
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _formulateConclusion();
      }
    });
  }

  void _formulateConclusion() {
    final isNatural =
        (_userAnswers[0] == true || _userAnswers[1] == true);
    final isStealthRequired =
        (_userAnswers[2] == true || _userAnswers[3] == true);
    final isMedical = _userAnswers[4] == true;

    final categoryEn = isNatural
        ? 'NATURAL DISASTER'
        : (isStealthRequired ? 'CRIMINAL THREAT' : 'GENERAL EMERGENCY');
    final categoryUr = isNatural
        ? 'قدرتی آفت'
        : (isStealthRequired ? 'مجرمانہ خطرہ' : 'عام ہنگامی صورتحال');

    final suggestedType = isMedical
        ? 'Medical'
        : (isNatural ? 'Fire' : (isStealthRequired ? 'Assault' : 'Other'));

    final summaryEn = isNatural
        ? 'Triage suggests environmental risk. Loud alert protocol recommended.'
        : (isStealthRequired
              ? 'Triage suggests criminal threat. Stealth/silent protocol recommended.'
              : 'Triage suggests general emergency. Continue with manual report details.');
    final summaryUr = isNatural
        ? 'ٹریاج سے ماحولیاتی خطرے کا اشارہ ملتا ہے۔ بلند آواز الرٹ پروٹوکول تجویز ہے۔'
        : (isStealthRequired
              ? 'ٹریاج سے مجرمانہ خطرے کا اشارہ ملتا ہے۔ خفیہ پروٹوکول تجویز ہے۔'
              : 'ٹریاج سے عام ہنگامی صورتحال کا اشارہ۔ دستی رپورٹ جاری رکھیں۔');

    _showResultDialog(
      OtherEmergencyResult(
        category: _isUrdu ? categoryUr : categoryEn,
        suggestedType: suggestedType,
        summary: _isUrdu ? summaryUr : summaryEn,
      ),
    );
  }

  void _showResultDialog(OtherEmergencyResult result) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
            '${_t('Analysis Complete:', 'تجزیہ مکمل:')} ${result.category}'),
        content: Text(
          result.suggestedType == 'Fire'
              ? _t(
                  'Loud sirens and maximum brightness are recommended to help rescuers find you.',
                  'بچاؤ کاروں کی مدد کے لیے تیز سائرن اور زیادہ چمک تجویز ہے۔',
                )
              : (result.suggestedType == 'Assault'
                    ? _t(
                        'Silent SOS and stealth mode are recommended to keep you hidden.',
                        'چھپے رہنے کے لیے خاموش SOS اور اسٹیلتھ موڈ تجویز ہے۔',
                      )
                    : _t(
                        'Proceed with report submission and share maximum evidence.',
                        'رپورٹ جمع کرنا جاری رکھیں اور زیادہ سے زیادہ ثبوت شیئر کریں۔',
                      )),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, result);
            },
            child: Text(_t('USE THIS TRIAGE RESULT', 'یہ ٹریاج نتیجہ استعمال کریں')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<SettingsProvider>(context).themeMode == ThemeMode.dark;
    final bg = isDark ? const Color(0xFF121212) : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black87;
    final onMuted = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          _t('Emergency Triage', 'ہنگامی ٹریاج'),
          style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _isUrdu = !_isUrdu),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Text(_isUrdu ? 'EN' : 'اردو',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
          ),
          IconButton(
            icon: Icon(
                isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: isDark ? Colors.amber : Colors.blueGrey),
            onPressed: () =>
                Provider.of<SettingsProvider>(context, listen: false)
                    .toggleTheme(!isDark),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_center_outlined,
                size: 80,
                color: isDark ? Colors.blueGrey : Colors.blueGrey.shade300),
            const SizedBox(height: 30),
            Text(
              _t('Question ${_currentQuestionIndex + 1} of 5',
                  'سوال ${_currentQuestionIndex + 1} از 5'),
              style: TextStyle(color: onMuted),
            ),
            const SizedBox(height: 10),
            Text(
              _questions[_currentQuestionIndex],
              textAlign: TextAlign.center,
              textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: onSurface),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                    child: _answerButton(
                        _t('NO', 'نہیں'), false, Colors.grey)),
                const SizedBox(width: 20),
                Expanded(
                    child: _answerButton(
                        _t('YES', 'ہاں'), true, Colors.redAccent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _answerButton(String label, bool value, Color color) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _processAnswer(value),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
