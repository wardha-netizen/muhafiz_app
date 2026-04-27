import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/offline_sos_service.dart';
import '../../services/bluetooth_alert_service.dart';
import '../../services/settings_provider.dart';
import '../../core/app_routes.dart';

class OfflineSosScreen extends StatefulWidget {
  const OfflineSosScreen({super.key});

  @override
  State<OfflineSosScreen> createState() => _OfflineSosScreenState();
}

class _OfflineSosScreenState extends State<OfflineSosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _nearbyCount = 0;
  bool _isUrdu = false;
  StreamSubscription<List<NearbyDevice>>? _bleSub;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Scan BLE to show nearby device count for awareness
    BluetoothAlertService.startScanning();
    _bleSub = BluetoothAlertService.nearbyDevices.listen((devices) {
      if (mounted) setState(() => _nearbyCount = devices.length);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _bleSub?.cancel();
    BluetoothAlertService.stopScanning();
    super.dispose();
  }

  void _confirmStop(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Stop SOS?', 'ایس او ایس بند کریں؟')),
        content: Text(_t(
          'This deactivates the offline emergency. Are you safe now?',
          'یہ آف لائن ایمرجنسی بند کر دے گا۔ کیا آپ ابھی محفوظ ہیں؟',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('Cancel', 'منسوخ'),
                style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OfflineSosService>().stopSos();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.home, (r) => false);
            },
            child: Text(_t("Yes, I'm Safe", 'ہاں، میں محفوظ ہوں'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<OfflineSosService>();
    final isDark =
        context.watch<SettingsProvider>().themeMode == ThemeMode.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.grey[50]!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top row: dismiss + language
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => _confirmStop(context),
                      icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                      label: Text(
                        _t('Dismiss', 'بند کریں'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isUrdu = !_isUrdu),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _isUrdu ? 'EN' : 'اردو',
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Pulsing SOS ring
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 136,
                    height: 136,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.12),
                      border: Border.all(color: Colors.red, width: 3),
                    ),
                    child: const Center(
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  _t('OFFLINE EMERGENCY ACTIVE', 'آف لائن ایمرجنسی فعال'),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 8),

                if (sos.emergencyType.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sos.emergencyType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                if (sos.locationText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.red, size: 13),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          sos.locationText,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 30),

                // ── SMS SENT ─────────────────────────────────────────────
                _Card(
                  cardBg: cardBg,
                  textColor: textColor,
                  icon: Icons.sms_outlined,
                  iconColor: Colors.green,
                  title: _t('Alerts Sent via SMS', 'ایس ایم ایس الرٹ بھیجے گئے'),
                  child: sos.smsSentTo.isEmpty
                      ? Text(
                          _t(
                            'No emergency contacts saved. Add them in Profile.',
                            'کوئی رابطہ محفوظ نہیں۔ پروفائل میں شامل کریں۔',
                          ),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.45),
                            fontSize: 13,
                          ),
                        )
                      : Column(
                          children: sos.smsSentTo
                              .map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.green, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${c.name}  ·  ${c.phone}',
                                          style: TextStyle(
                                              color: textColor, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),

                const SizedBox(height: 12),

                // ── BLE NEARBY ───────────────────────────────────────────
                _Card(
                  cardBg: cardBg,
                  textColor: textColor,
                  icon: Icons.bluetooth_searching,
                  iconColor: Colors.blue,
                  title: _t('Nearby MUHAFIZ Users', 'قریبی محافظ صارفین'),
                  child: Row(
                    children: [
                      Text(
                        _nearbyCount == 0
                            ? _t('Scanning nearby devices...',
                                'قریبی ڈیوائسز اسکین ہو رہی ہیں...')
                            : _t(
                                '$_nearbyCount device(s) detected nearby',
                                '$_nearbyCount قریبی ڈیوائس ملی',
                              ),
                        style: TextStyle(
                          color: _nearbyCount > 0
                              ? Colors.blue
                              : textColor.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: _nearbyCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (_nearbyCount == 0)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── COMMUNITY SYNC STATUS ────────────────────────────────
                _Card(
                  cardBg: cardBg,
                  textColor: textColor,
                  icon: sos.isSynced
                      ? Icons.cloud_done
                      : sos.isSyncing
                          ? Icons.cloud_sync
                          : Icons.cloud_off_outlined,
                  iconColor: sos.isSynced
                      ? Colors.green
                      : sos.isSyncing
                          ? Colors.orange
                          : Colors.grey,
                  title: _t(
                      'MUHAFIZ Community Alert', 'محافظ کمیونٹی الرٹ'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (sos.isSyncing)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.orange),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              sos.isSynced
                                  ? _t(
                                      '✓ All MUHAFIZ users alerted',
                                      '✓ تمام محافظ صارفین کو الرٹ کیا گیا',
                                    )
                                  : sos.isSyncing
                                      ? _t(
                                          'Syncing to MUHAFIZ servers...',
                                          'محافظ سرورز سے ہم آہنگ ہو رہا ہے...',
                                        )
                                      : _t(
                                          'Waiting for internet connection...',
                                          'انٹرنیٹ کا انتظار ہے...',
                                        ),
                              style: TextStyle(
                                color: sos.isSynced
                                    ? Colors.green
                                    : textColor.withValues(alpha: 0.6),
                                fontSize: 13,
                                fontWeight: sos.isSynced
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!sos.isSynced) ...[
                        const SizedBox(height: 6),
                        Text(
                          _t(
                            'Once connected, your emergency is broadcast to all active MUHAFIZ users automatically.',
                            'کنیکٹ ہونے پر، آپ کی ایمرجنسی تمام فعال محافظ صارفین کو خودکار طور پر بھیجی جائے گی۔',
                          ),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.4),
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Emergency guides
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE53935)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.offlineGuide),
                    icon: const Icon(Icons.menu_book_outlined,
                        color: Color(0xFFE53935)),
                    label: Text(
                      _t('Emergency Guides (Offline)', 'آف لائن ہنگامی رہنما'),
                      style: const TextStyle(color: Color(0xFFE53935)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Stop SOS
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.white10 : Colors.grey[200],
                      foregroundColor: textColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirmStop(context),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(
                      _t("Stop SOS — I'm Safe", 'ایس او ایس بند کریں - میں محفوظ ہوں'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared card widget ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Color cardBg;
  final Color textColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _Card({
    required this.cardBg,
    required this.textColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
