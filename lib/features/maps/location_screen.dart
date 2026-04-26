import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_provider.dart';
import '../home/home_screen.dart';
import '../home/permissions_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isUrdu = false;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  void _navigateToPermissions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PermissionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<SettingsProvider>(context).themeMode == ThemeMode.dark;
    final bg = isDark ? const Color(0xFF121212) : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black87;
    final onMuted = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: onSurface),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              Text(
                _t('Track yourself.', 'اپنا مقام ٹریک کریں۔'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _t(
                  'To ensure MUHAFIZ can trigger Stealth Mode or Beacon alarms, we need access to your location and system settings.',
                  'محافظ کو اسٹیلتھ موڈ یا بیکن الارم چالو کرنے کے لیے آپ کے مقام اور سسٹم سیٹنگز تک رسائی ضروری ہے۔',
                ),
                textAlign: TextAlign.center,
                textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(color: onMuted, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _navigateToPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _t('Allow Permissions', 'اجازت دیں'),
                    style: const TextStyle(
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
                child: Text(
                  _t('Skip for now', 'ابھی چھوڑیں'),
                  style: TextStyle(color: onMuted, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
