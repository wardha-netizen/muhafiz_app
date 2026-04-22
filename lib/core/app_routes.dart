import 'package:flutter/material.dart';
import '../features/features.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot_password';
  static const location = '/location';
  static const disasterAnalysis = '/disaster_analysis';
  static const disasterPrediction = '/disaster_prediction';
  static const permissions = '/permissions';
  static const emergencyContacts = '/emergency_contacts';
  static const emergencyReports = '/emergency_reports';
  static const home = '/home';
  static const report = '/report';
  static const offlineGuide = '/offline_guide';
  static const bluetoothAlerts = '/bluetooth_alerts';
  static const karachiMap = '/karachi_map';

  static Route<dynamic> _smoothRoute({
    required RouteSettings settings,
    required Widget child,
  }) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        final offsetTween = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: offsetTween.animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _smoothRoute(settings: settings, child: const SplashScreen());
      case login:
        return _smoothRoute(settings: settings, child: const LoginScreen());
      case signup:
        return _smoothRoute(settings: settings, child: const SignUpScreen());
      case forgotPassword:
        return _smoothRoute(settings: settings, child: const ForgotPasswordScreen());
      case location:
        return _smoothRoute(settings: settings, child: const LocationScreen());
      case disasterAnalysis:
        return _smoothRoute(settings: settings, child: const DisasterAnalysisScreen());
      case disasterPrediction:
        return _smoothRoute(settings: settings, child: const DisasterPredictionScreen());
      case permissions:
        return _smoothRoute(settings: settings, child: const PermissionsScreen());
      case emergencyContacts:
        return _smoothRoute(settings: settings, child: const EmergencyContactsScreen());
      case emergencyReports:
        return _smoothRoute(settings: settings, child: const EmergencyReportsScreen());
      case home:
        return _smoothRoute(settings: settings, child: const HomeScreen());
      case report:
        return _smoothRoute(settings: settings, child: const ReportEmergencyScreen());
      case offlineGuide:
        return _smoothRoute(settings: settings, child: const OfflineGuideScreen());
      case bluetoothAlerts:
        return _smoothRoute(settings: settings, child: const BluetoothScreen());
      case karachiMap:
        return _smoothRoute(settings: settings, child: const KarachiEmergencyMapScreen());
      default:
        return _smoothRoute(
          settings: settings,
          child: Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }
}
