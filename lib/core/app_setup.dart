import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/features.dart';
import '../services/services.dart';
import 'app_routes.dart';
import 'theme/app_theme.dart';

class AppSetup extends StatelessWidget {
  const AppSetup({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Muhafiz',
      themeMode: settingsProvider.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const SplashScreen(),
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.signup: (context) => const SignUpScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.location: (context) => const LocationScreen(),
        AppRoutes.disasterAnalysis: (context) => const DisasterAnalysisScreen(),
        AppRoutes.permissions: (context) => const PermissionsScreen(),
        AppRoutes.emergencyContacts: (context) => const EmergencyContactsScreen(),
        AppRoutes.emergencyReports: (context) => const EmergencyReportsScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.report: (context) => const ReportEmergencyScreen(),
      },
    );
  }
}
