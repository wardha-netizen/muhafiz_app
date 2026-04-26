import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_provider.dart';

class RelativeAlertStatusScreen extends StatefulWidget {
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
  State<RelativeAlertStatusScreen> createState() =>
      _RelativeAlertStatusScreenState();
}

class _RelativeAlertStatusScreenState
    extends State<RelativeAlertStatusScreen> {
  bool _isUrdu = false;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<SettingsProvider>(context).themeMode == ThemeMode.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF6F7FB);
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black87;
    final onMuted = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          _t('Alert Status', 'الرٹ کی صورتحال'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_t('Emergency type:', 'ہنگامی قسم:')} ${widget.emergencyType}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              '${_t('Location:', 'مقام:')} ${widget.locationText}',
              style: TextStyle(color: onMuted),
            ),
            const SizedBox(height: 18),
            if (widget.recipients.isEmpty)
              Card(
                color: surface,
                child: ListTile(
                  leading:
                      const Icon(Icons.info_outline, color: Colors.redAccent),
                  title: Text(
                    _t('No emergency contacts found',
                        'کوئی ہنگامی رابطہ نہیں ملا'),
                    style: TextStyle(color: onSurface),
                  ),
                  subtitle: Text(
                    _t(
                      'Please add relatives or emergency contacts to receive alerts.',
                      'براہ کرم الرٹ وصول کرنے کے لیے رشتہ داروں یا ہنگامی رابطے شامل کریں۔',
                    ),
                    style: TextStyle(color: onMuted),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: widget.recipients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final number = widget.recipients[index];
                    return Card(
                      color: surface,
                      child: ListTile(
                        leading: const Icon(Icons.sms_rounded,
                            color: Color(0xFFE53935)),
                        title: Text(number,
                            style: TextStyle(color: onSurface)),
                        subtitle: Text(
                          _t('Alert sent via SMS/WhatsApp',
                              'SMS/WhatsApp کے ذریعے الرٹ بھیجا گیا'),
                          style: TextStyle(color: onMuted),
                        ),
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
                child: Text(
                  _t('Back to Report', 'رپورٹ پر واپس'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
