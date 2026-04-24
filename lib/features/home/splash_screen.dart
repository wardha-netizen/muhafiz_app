import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Don't artificially block startup; keep a tiny delay to let the first frame
    // render and the logo decode happen smoothly.
    _timer = Timer(const Duration(milliseconds: 350), _navigateNext);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache the splash logo to avoid a janky first paint on slower devices.
    precacheImage(const AssetImage('assets/images/logo.png'), context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateNext() {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    // If already logged in, go straight to Home; otherwise show Login
    if (user != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: MediaQuery.of(context).size.width * 0.65,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Color(0xFFE53935),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
