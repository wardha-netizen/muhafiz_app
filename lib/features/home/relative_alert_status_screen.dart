import 'package:flutter/material.dart';

class RelativeAlertStatusScreen extends StatelessWidget {
  const RelativeAlertStatusScreen({
    super.key,
    required this.recipients,
    required this.emergencyType,
    required this.locationText,
  });

  final List<String> recipients;
  final String emergencyType;
  final String locationText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatives Alert Status')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency type: $emergencyType',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Location: $locationText'),
            const SizedBox(height: 18),
            if (recipients.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('No emergency contacts found'),
                  subtitle: Text(
                    'Please add relatives or emergency contacts to receive alerts.',
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: recipients.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final number = recipients[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.sms_rounded,
                          color: Color(0xFFE53935),
                        ),
                        title: Text(number),
                        subtitle: const Text('SMS alert prepared in messaging app'),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Back to report',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
