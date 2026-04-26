import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/settings_provider.dart';
import '../../core/app_routes.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isUrdu = false;
  String? _emailError;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  static bool _isValidEmail(String email) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(email.trim());

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(
          _t('Please enter both email and password.',
              'براہ کرم ای میل اور پاس ورڈ دونوں درج کریں۔'),
          Colors.orange);
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _emailError =
          _t('Enter a valid email address', 'درست ای میل ایڈریس درج کریں'));
      return;
    }
    setState(() => _emailError = null);

    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      TextInput.finishAutofillContext();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.permissions,
        (route) => false,
      );
    } catch (e) {
      _showSnackBar(
          _t('Login Failed: ${e.toString()}', 'لاگ ان ناکام: ${e.toString()}'),
          Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar(
          _t('Please enter your email for the reset link.',
              'براہ کرم ری سیٹ لنک کے لیے اپنا ای میل درج کریں۔'),
          Colors.orange);
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showSuccessDialog(email);
    } catch (e) {
      _showSnackBar(
          _t('Error: ${e.toString()}', 'خرابی: ${e.toString()}'), Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Reset Link Sent', 'ری سیٹ لنک بھیجا گیا')),
        content: Text(
            _t('A recovery link was sent to $email.',
                '$email پر ریکوری لنک بھیجا گیا۔')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<SettingsProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color bg = isDark ? const Color(0xFF0D0D0D) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Language + theme toggles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isUrdu = !_isUrdu),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.redAccent
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Text(_isUrdu ? 'EN' : 'اردو',
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                                isDark
                                    ? Icons.wb_sunny_outlined
                                    : Icons.nightlight_round,
                                color: isDark ? Colors.amber : Colors.blueGrey),
                            onPressed: () =>
                                Provider.of<SettingsProvider>(context,
                                        listen: false)
                                    .toggleTheme(!isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Text(
                        _t('Welcome back.', 'خوش آمدید۔'),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildInputField(
                        label: _t('Email', 'ای میل'),
                        controller: _emailController,
                        isDark: isDark,
                        icon: Icons.email_outlined,
                        autofillHints: [AutofillHints.email],
                        errorText: _emailError,
                        onChanged: (_) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: _t('Password', 'پاس ورڈ'),
                        controller: _passwordController,
                        isDark: isDark,
                        icon: Icons.lock_outline,
                        isPassword: true,
                        autofillHints: [AutofillHints.password],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: Text(
                            _t('Forgot Password?', 'پاس ورڈ بھول گئے؟'),
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _login,
                          child: Text(
                            _t('Log in', 'لاگ ان کریں'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _t("Don't have an account?",
                                'اکاؤنٹ نہیں ہے؟'),
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignUpScreen(),
                              ),
                            ),
                            child: Text(
                              _t('Create Medical ID', 'میڈیکل ID بنائیں'),
                              style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    IconData? icon,
    bool isPassword = false,
    Iterable<String>? autofillHints,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      autofillHints: autofillHints,
      onChanged: onChanged,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        errorText: errorText,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: errorText != null
              ? const BorderSide(color: Colors.red, width: 1.5)
              : BorderSide.none,
        ),
      ),
    );
  }
}
