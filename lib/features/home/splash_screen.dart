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
    final logoSize = MediaQuery.of(context).size.width * 0.78;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Logo dead-centre of the screen
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
          ),
          // Spinner pinned near the bottom
          const Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE53935),
                strokeWidth: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
