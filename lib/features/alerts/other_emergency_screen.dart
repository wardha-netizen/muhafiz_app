import 'package:flutter/material.dart';

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

  final List<String> _questions = [
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
    final isNatural = (_userAnswers[0] == true || _userAnswers[1] == true);
    final isStealthRequired = (_userAnswers[2] == true || _userAnswers[3] == true);
    final isMedical = _userAnswers[4] == true;

    final category = isNatural
        ? 'NATURAL DISASTER'
        : (isStealthRequired ? 'CRIMINAL THREAT' : 'GENERAL EMERGENCY');

    final suggestedType = isMedical
        ? 'Medical'
        : (isNatural ? 'Fire' : (isStealthRequired ? 'Assault' : 'Other'));

    final summary = isNatural
        ? 'Triage suggests environmental risk. Loud alert protocol recommended.'
        : (isStealthRequired
              ? 'Triage suggests criminal threat. Stealth/silent protocol recommended.'
              : 'Triage suggests general emergency. Continue with manual report details.');

    _showResultDialog(
      OtherEmergencyResult(
        category: category,
        suggestedType: suggestedType,
        summary: summary,
      ),
    );
  }

  void _showResultDialog(OtherEmergencyResult result) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Analysis Complete: ${result.category}'),
        content: Text(
          result.suggestedType == 'Fire'
              ? 'Loud sirens and maximum brightness are recommended to help rescuers find you.'
              : (result.suggestedType == 'Assault'
                    ? 'Silent SOS and stealth mode are recommended to keep you hidden.'
                    : 'Proceed with report submission and share maximum evidence.'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, result);
            },
            child: const Text('USE THIS TRIAGE RESULT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Triage')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.help_center_outlined, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 30),
            Text(
              'Question ${_currentQuestionIndex + 1} of 5',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              _questions[_currentQuestionIndex],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(child: _answerButton('NO', false, Colors.grey)),
                const SizedBox(width: 20),
                Expanded(child: _answerButton('YES', true, Colors.redAccent)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
