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
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo.png'), context);
  }

  Future<void> _navigateNext() async {
    // Run minimum splash duration and auth state resolution in parallel.
    final results = await Future.wait([
      Future<User?>.delayed(
        const Duration(milliseconds: 1500),
        () => FirebaseAuth.instance.currentUser,
      ),
      FirebaseAuth.instance.authStateChanges().first,
    ]);

    if (!mounted) return;
    final user = results[1]; // auth state is authoritative
    if (user != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
