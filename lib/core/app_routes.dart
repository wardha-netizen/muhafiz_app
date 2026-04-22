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

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case location:
        return MaterialPageRoute(builder: (_) => const LocationScreen());
      case disasterAnalysis:
        return MaterialPageRoute(builder: (_) => const DisasterAnalysisScreen());
      case disasterPrediction:
        return MaterialPageRoute(builder: (_) => const DisasterPredictionScreen());
      case permissions:
        return MaterialPageRoute(builder: (_) => const PermissionsScreen());
      case emergencyContacts:
        return MaterialPageRoute(builder: (_) => const EmergencyContactsScreen());
      case emergencyReports:
        return MaterialPageRoute(builder: (_) => const EmergencyReportsScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case report:
        return MaterialPageRoute(builder: (_) => const ReportEmergencyScreen());
      case offlineGuide:
        return MaterialPageRoute(builder: (_) => const OfflineGuideScreen());
      case bluetoothAlerts:
        return MaterialPageRoute(builder: (_) => const BluetoothScreen());
      case karachiMap:
        return MaterialPageRoute(builder: (_) => const KarachiEmergencyMapScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }
}
