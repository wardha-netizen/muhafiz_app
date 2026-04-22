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

  Map<String, List<String>> get _questionBank => {
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
          isConfirmed ? 'Disaster Confirmed' : 'Situation Monitored',
        ),
        content: Text(
          isConfirmed
              ? 'Based on your answers, we are notifying emergency services for ${widget.disasterType}.'
              : "The situation doesn't meet critical emergency criteria yet, but we will keep monitoring.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, isConfirmed);
            },
            child: const Text('PROCEED'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questionBank[widget.disasterType] ??
        [
          'Is the situation urgent?',
          'Are there people nearby?',
          'Is it safe?',
          'Do you need help?',
          'Confirm?',
        ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: (_currentStep + 1) / 5, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            'Step ${_currentStep + 1} of 5',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            questions[_currentStep],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChoiceButton('NO', false, Colors.grey),
              _buildChoiceButton('YES', true, Colors.red),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () => _handleAnswer(value),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
