import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muhafiz_1/services/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Provide a mock SharedPreferences backend for all tests
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsProvider', () {
    test('defaults to system theme mode', () {
      final provider = SettingsProvider();
      // Before loadSettings completes, defaults to system (or last persisted value)
      expect(provider.themeMode, isA<ThemeMode>());
    });

    test('toggleTheme switches to dark mode', () async {
      final provider = SettingsProvider();
      await provider.loadSettings(); // Wait for prefs to load

      provider.toggleTheme(true);
      expect(provider.isDarkMode, isTrue);
      expect(provider.themeMode, ThemeMode.dark);
    });

    test('toggleTheme switches to light mode', () async {
      final provider = SettingsProvider();
      await provider.loadSettings();

      provider.toggleTheme(false);
      expect(provider.isDarkMode, isFalse);
      expect(provider.themeMode, ThemeMode.light);
    });
  });
}
