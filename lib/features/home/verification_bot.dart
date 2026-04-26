import 'package:flutter/material.dart';

class VerificationBot extends StatefulWidget {
  final String disasterType;
  const VerificationBot({super.key, required this.disasterType});

  @override
  State<VerificationBot> createState() => _VerificationBotState();
}

class _VerificationBotState extends State<VerificationBot> {
  int _currentStep = 0;
  final List<bool> _responses = [];
  bool _isUrdu = false;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  static const Map<String, List<String>> _questionsEn = {
    'Fire': [
      'Can you smell strong chemical or wood fumes?',
      'Do you see dark or thick smoke clouds nearby?',
      'Are you experiencing any difficulty breathing?',
      'Is the surrounding temperature feeling unusually high?',
      'Can you see visible flames or a glowing orange horizon?',
    ],
    'Quake': [
      'Did you feel a sharp jolt or a rolling motion just now?',
      'Are heavy objects (like wardrobes/fans) swaying or falling?',
      'Do you hear a loud rumbling sound like a passing train?',
      'Are there visible cracks appearing in the walls or ceiling?',
      'Is it difficult to maintain your balance while standing?',
    ],
    'Flood': [
      'Is the water level rising above your ankles?',
      'Is the water flowing rapidly rather than standing still?',
      'Are your electrical outlets or appliances submerged?',
      'Is the sewage system or drains starting to overflow?',
      'Are access roads or exits currently blocked by water?',
    ],
    'Medical': [
      'Is the person conscious and responding to their name?',
      "Is there visible heavy bleeding that won't stop?",
      'Does the person have a pulse or are they breathing?',
      'Is there a suspected bone fracture or head injury?',
      'Is the person showing signs of a stroke (slurred speech)?',
    ],
  };

  static const Map<String, List<String>> _questionsUr = {
    'Fire': [
      'کیا آپ کو تیز کیمیکل یا لکڑی کا دھواں آ رہا ہے؟',
      'کیا قریب میں گہرے یا گھنے دھوئیں کے بادل نظر آ رہے ہیں؟',
      'کیا آپ کو سانس لینے میں دشواری ہو رہی ہے؟',
      'کیا آس پاس کا درجہ حرارت غیر معمولی طور پر زیادہ محسوس ہو رہا ہے؟',
      'کیا آپ کو شعلے یا چمکتا ہوا نارنجی افق نظر آ رہا ہے؟',
    ],
    'Quake': [
      'کیا آپ کو ابھی تیز جھٹکا یا لرزش محسوس ہوئی؟',
      'کیا بھاری اشیاء (جیسے الماری/پنکھے) ہل رہی ہیں یا گر رہی ہیں؟',
      'کیا آپ کو گزرتی ٹرین جیسی تیز گڑگڑاہٹ سنائی دے رہی ہے؟',
      'کیا دیواروں یا چھت میں دراڑیں نظر آ رہی ہیں؟',
      'کیا کھڑے ہونے میں توازن برقرار رکھنا مشکل ہے؟',
    ],
    'Flood': [
      'کیا پانی کی سطح آپ کے ٹخنوں سے اوپر بڑھ رہی ہے؟',
      'کیا پانی رکنے کی بجائے تیزی سے بہہ رہا ہے؟',
      'کیا آپ کے بجلی کے آؤٹ لیٹ یا آلات زیر آب ہیں؟',
      'کیا سیوریج سسٹم یا نالیاں بھرنا شروع ہو گئی ہیں؟',
      'کیا سڑکیں یا نکاس پانی سے بند ہیں؟',
    ],
    'Medical': [
      'کیا شخص ہوش میں ہے اور اپنے نام کا جواب دے رہا ہے؟',
      'کیا بھاری خون بہنا نظر آ رہا ہے جو رک نہیں رہا؟',
      'کیا شخص کی نبض ہے یا وہ سانس لے رہا ہے؟',
      'کیا ہڈی ٹوٹنے یا سر میں چوٹ کا شک ہے؟',
      'کیا شخص فالج کی علامات دکھا رہا ہے (لڑکھڑاتی آواز)؟',
    ],
  };

  List<String> get _questions {
    final bank = _isUrdu ? _questionsUr : _questionsEn;
    return bank[widget.disasterType] ??
        (_isUrdu
            ? ['کیا صورتحال فوری ہے؟', 'کیا قریب میں لوگ ہیں؟', 'کیا یہ محفوظ ہے؟', 'کیا آپ کو مدد چاہیے؟', 'تصدیق کریں؟']
            : ['Is the situation urgent?', 'Are there people nearby?', 'Is it safe?', 'Do you need help?', 'Confirm?']);
  }

  void _handleAnswer(bool answer) {
    setState(() {
      _responses.add(answer);
      if (_currentStep < 4) {
        _currentStep++;
      } else {
        _showFinalVerdict();
      }
    });
  }

  void _showFinalVerdict() {
    final yesCount = _responses.where((r) => r).length;
    final isConfirmed = yesCount >= 3;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isConfirmed
              ? _t('Disaster Confirmed', 'آفت کی تصدیق ہو گئی')
              : _t('Situation Monitored', 'صورتحال زیر نظر ہے'),
        ),
        content: Text(
          isConfirmed
              ? _t(
                  'Based on your answers, we are notifying emergency services for ${widget.disasterType}.',
                  'آپ کے جوابات کی بنیاد پر، ہم ${widget.disasterType} کے لیے ہنگامی خدمات کو مطلع کر رہے ہیں۔',
                )
              : _t(
                  "The situation doesn't meet critical emergency criteria yet, but we will keep monitoring.",
                  'یہ صورتحال ابھی تک ہنگامی معیار پر پوری نہیں اترتی، لیکن ہم نگرانی جاری رکھیں گے۔',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, isConfirmed);
            },
            child: Text(_t('PROCEED', 'جاری رکھیں')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Colors.black87;
    final onMuted = isDark ? Colors.white54 : Colors.black54;
    final questions = _questions;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => setState(() => _isUrdu = !_isUrdu),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Text(_isUrdu ? 'EN' : 'اردو',
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
              value: (_currentStep + 1) / 5, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            _t('Step ${_currentStep + 1} of 5',
                'مرحلہ ${_currentStep + 1} از 5'),
            style: TextStyle(color: onMuted),
          ),
          const SizedBox(height: 10),
          Text(
            questions[_currentStep],
            textAlign: TextAlign.center,
            textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: onSurface),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChoiceButton(_t('NO', 'نہیں'), false, Colors.grey),
              _buildChoiceButton(_t('YES', 'ہاں'), true, Colors.red),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(String text, bool value, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(120, 50),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () => _handleAnswer(value),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 18)),
    );
  }
}
