import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../home/permissions_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final bool _isLoading = false;

  // --- LOGIC: NAVIGATION TO PERMISSIONS DASHBOARD ---
  // Updated to ensure all hardware permissions are handled together
  void _navigateToPermissions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PermissionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Visual Icon
              Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 100,
                  color: Color(0xFFE53935),
                ),
              ),
              const SizedBox(height: 50),

              const Text(
                'Track yourself.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  // fontFamily: 'Pacifico', // Add font to pubspec.yaml to enable
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'To ensure MUHAFIZ can trigger Stealth Mode or Beacon alarms, we need access to your location and system settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 60),

              // Action Buttons
              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFFE53935))
                  : Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            // UPDATED: Now points to the Permissions Dashboard
                            onPressed: _navigateToPermissions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Allow Permissions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          ),
                          child: const Text(
                            'Skip for now',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
