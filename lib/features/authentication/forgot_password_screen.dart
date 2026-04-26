import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _isUrdu = false;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage(
          _t('Please enter your email address.',
              'براہ کرم اپنا ای میل ایڈریس درج کریں۔'),
          Colors.orange);
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showMessage(
          _t('Password reset link sent to $email',
              '$email پر پاس ورڈ ری سیٹ لنک بھیجا گیا'),
          Colors.green);
    } catch (e) {
      _showMessage(
          _t('Failed to send reset link: $e', 'ری سیٹ لنک بھیجنا ناکام: $e'),
          Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<SettingsProvider>(context).themeMode == ThemeMode.dark;
    final bg = isDark ? const Color(0xFF121212) : Colors.white;
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.grey[200]!;
    final onSurface = isDark ? Colors.white : Colors.black87;
    final onMuted = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          _t('Forgot Password', 'پاس ورڈ بھول گئے'),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              _t(
                'Enter your email to receive a password reset link.',
                'پاس ورڈ ری سیٹ لنک حاصل کرنے کے لیے اپنا ای میل درج کریں۔',
              ),
              style: TextStyle(color: onMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: onSurface),
              decoration: InputDecoration(
                labelText: _t('Email', 'ای میل'),
                labelStyle: TextStyle(color: onMuted),
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.redAccent),
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _sendResetLink,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _t('Send Reset Link', 'ری سیٹ لنک بھیجیں'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
