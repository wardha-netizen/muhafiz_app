import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../services/settings_provider.dart';
import '../../core/localization/app_localizations.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isUrdu = false;
  Map<Permission, PermissionStatus> statuses = {};

  final Color muhafizOrange = const Color(0xFFFF9800);
  final Color muhafizRed = const Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _checkCurrentStatuses();
  }

  Future<void> _checkCurrentStatuses() async {
    final List<Permission> permissions = [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.sms,
      Permission.camera,
      Permission.microphone,
    ];

    for (var p in permissions) {
      statuses[p] = await p.status;
    }
    if (mounted) setState(() {});
  }

  Future<void> _request(Permission p) async {
    final result = await p.request();
    setState(() => statuses[p] = result);
  }

  String _t(String eng, String ur) =>
      AppLocalizations.text(isUrdu: _isUrdu, english: eng, urdu: ur);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<SettingsProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;

    final Color bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final Color cardColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Safety Permissions', 'حفاظتی اجازتیں'),
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isUrdu = !_isUrdu),
            child: Text(
              _t('اردو', 'English'),
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (v) => themeProvider.toggleTheme(v),
            activeThumbColor: muhafizOrange,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildTile(
                  Permission.location,
                  Icons.location_on,
                  'Live Tracking',
                  'لائیو ٹریکنگ',
                  cardColor,
                  textColor,
                ),
                _buildTile(
                  Permission.bluetoothScan,
                  Icons.bluetooth_searching,
                  'Bluetooth Nearby Alerts',
                  'بلوٹوتھ الرٹس',
                  cardColor,
                  textColor,
                ),
                _buildTile(
                  Permission.bluetoothConnect,
                  Icons.bluetooth_connected,
                  'Bluetooth Connect',
                  'بلوٹوتھ کنکشن',
                  cardColor,
                  textColor,
                ),
                _buildTile(
                  Permission.sms,
                  Icons.chat_bubble,
                  'Silent SOS SMS',
                  'خاموش ایس ایم ایس',
                  cardColor,
                  textColor,
                ),
                _buildTile(
                  Permission.camera,
                  Icons.camera_alt,
                  'Camera Access',
                  'کیمرہ تک رسائی',
                  cardColor,
                  textColor,
                ),
                _buildTile(
                  Permission.microphone,
                  Icons.mic,
                  'Microphone Access',
                  'مائیکروفون تک رسائی',
                  cardColor,
                  textColor,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: muhafizRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  // This matches the key in your main.dart exactly
                  Navigator.pushNamed(context, '/emergency_contacts');
                },
                child: Text(
                  _t('PROCEED', 'آگے بڑھیں'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    Permission p,
    IconData icon,
    String eng,
    String ur,
    Color cardColor,
    Color textColor,
  ) {
    final bool isGranted = statuses[p]?.isGranted ?? false;
    return Card(
      color: cardColor,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: muhafizOrange),
        title: Text(
          _t(eng, ur),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.blueAccent,
                ),
                onPressed: () => _request(p),
              ),
      ),
    );
  }
}
