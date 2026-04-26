import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../../services/bluetooth_alert_service.dart';
import '../../services/emergency_buzzer_service.dart';
import '../../services/settings_provider.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  bool _isScanning = false;
  bool _btAvailable = false;
  bool _isUrdu = false;
  List<NearbyDevice> _nearbyDevices = [];
  final List<ProximityAlert> _alerts = [];

  StreamSubscription<List<NearbyDevice>>? _devicesSub;
  StreamSubscription<ProximityAlert>? _alertSub;
  StreamSubscription<dynamic>? _adapterSub;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF6F7FB);
  Color get _surface => _isDark ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _onSurface => _isDark ? Colors.white : Colors.black87;
  Color get _onMuted => _isDark ? Colors.white54 : Colors.black54;
  Color get _onFaint => _isDark ? Colors.white24 : Colors.black26;
  Color get _border => _isDark ? Colors.white12 : Colors.black12;

  String _t(String en, String ur) => _isUrdu ? ur : en;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _adapterSub?.cancel();
    _adapterSub = BluetoothAlertService.adapterStateStream.listen((state) {
      if (!mounted) return;
      final on = state.toString().toLowerCase().contains('on');
      setState(() => _btAvailable = on);
      if (!on && _isScanning) {
        setState(() => _isScanning = false);
      }
    });

    final available = await BluetoothAlertService.isBluetoothAvailable();
    if (mounted) setState(() => _btAvailable = available);

    _devicesSub = BluetoothAlertService.nearbyDevices.listen((devices) {
      if (mounted) setState(() => _nearbyDevices = devices);
    });

    _alertSub = BluetoothAlertService.incomingAlerts.listen((alert) {
      if (mounted) {
        setState(() => _alerts.insert(0, alert));
        _showAlertDialog(alert);
      }
    });

    BluetoothAlertService.listenForNearbyAlerts();
  }

  Future<void> _toggleScan() async {
    if (_isScanning) {
      await BluetoothAlertService.stopScanning();
      if (mounted) setState(() => _isScanning = false);
    } else {
      if (!_btAvailable) {
        _showSnack(
          _t('Turning on Bluetooth…', 'بلوٹوتھ آن ہو رہا ہے…'),
          Colors.orange,
        );
        final ok = await BluetoothAlertService.ensureBluetoothOn();
        if (!ok) {
          _showSnack(
            _t('Bluetooth is off. Please enable it and try again.',
                'بلوٹوتھ بند ہے۔ براہ کرم چالو کریں اور دوبارہ کوشش کریں۔'),
            Colors.orange,
          );
          return;
        }
      }
      await BluetoothAlertService.startScanning();
      if (mounted) setState(() => _isScanning = true);
      Future.delayed(const Duration(seconds: 22), () {
        if (mounted) setState(() => _isScanning = false);
      });
    }
  }

  Future<void> _broadcastSOS() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text(
          _t('Broadcast SOS?', 'SOS نشر کریں؟'),
          style: TextStyle(color: _onSurface),
        ),
        content: Text(
          _t(
            'This will alert all active MUHAFIZ users nearby and in Karachi '
            'via Bluetooth and Firebase. Only use in real emergency.',
            'یہ بلوٹوتھ اور فائربیس کے ذریعے تمام فعال محافظ صارفین کو الرٹ کرے گا۔ '
            'صرف حقیقی ہنگامی صورت میں استعمال کریں۔',
          ),
          style: TextStyle(color: _onMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _t('Cancel', 'منسوخ'),
              style: TextStyle(color: _onMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _t('BROADCAST SOS', 'SOS نشر کریں'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BluetoothAlertService.broadcastEmergencyViaFirebase(
        emergencyType: 'SOS — HELP NEEDED',
        locationText: 'Karachi (see MUHAFIZ app for details)',
      );
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(pattern: [0, 800, 200, 800, 200, 800]);
      }
      if (mounted) {
        _showSnack(
          _t('SOS broadcast sent to all nearby MUHAFIZ users!',
              'SOS تمام قریبی محافظ صارفین کو بھیج دیا گیا!'),
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('${_t('Broadcast failed', 'نشر ناکام')}: $e', Colors.red);
      }
    }
  }

  Widget _buildAlertDialog(ProximityAlert alert) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A0000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.red, width: 2),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.red),
          const SizedBox(width: 8),
          Text(
            _t('EMERGENCY NEARBY', 'قریب ہنگامی صورتحال'),
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _alertRow(_t('From', 'از'), alert.userName),
          _alertRow(_t('Type', 'قسم'), alert.emergencyType),
          _alertRow(
              _t('Location', 'مقام'),
              alert.location.isNotEmpty ? alert.location : _t('Nearby', 'قریب')),
          _alertRow(_t('Time', 'وقت'), _timeAgo(alert.timestamp)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            EmergencyBuzzerService.instance.stop();
            Navigator.pop(context);
          },
          child: const Text('OK', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  void _showAlertDialog(ProximityAlert alert) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _buildAlertDialog(alert),
    ).then((_) {
      EmergencyBuzzerService.instance.stop();
    });
  }

  Widget _alertRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            TextSpan(
                text: value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) {
      return _isUrdu ? '${diff.inSeconds} سیکنڈ پہلے' : '${diff.inSeconds}s ago';
    }
    if (diff.inMinutes < 60) {
      return _isUrdu ? '${diff.inMinutes} منٹ پہلے' : '${diff.inMinutes}m ago';
    }
    return _isUrdu ? '${diff.inHours} گھنٹے پہلے' : '${diff.inHours}h ago';
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    _alertSub?.cancel();
    _adapterSub?.cancel();
    BluetoothAlertService.stopScanning();
    BluetoothAlertService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Bluetooth Alerts', 'بلوٹوتھ الرٹس'),
              style: TextStyle(
                  color: _onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            Text(
              _t('Peer-to-peer emergency network', 'ہم جہت ہنگامی نیٹ ورک'),
              style: TextStyle(color: _onMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          // BT status badge
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _btAvailable
                  ? Colors.blue.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bluetooth,
                    size: 14,
                    color: _btAvailable ? Colors.blue : Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _btAvailable ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: _btAvailable ? Colors.blue : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Language toggle
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => setState(() => _isUrdu = !_isUrdu),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isUrdu
                      ? Colors.green.withValues(alpha: 0.18)
                      : (_isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isUrdu
                        ? Colors.green.withValues(alpha: 0.6)
                        : (_isDark ? Colors.white24 : Colors.black12),
                  ),
                ),
                child: Text(
                  _isUrdu ? 'EN' : 'اردو',
                  style: TextStyle(
                    color: _isUrdu ? Colors.green : _onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Theme toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () =>
                  Provider.of<SettingsProvider>(context, listen: false)
                      .toggleTheme(!_isDark),
              icon: Icon(
                _isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: _onSurface,
                size: 20,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHowItWorksCard(),
          const SizedBox(height: 16),
          _buildScanControl(),
          const SizedBox(height: 16),
          _buildSOSBroadcast(),
          const SizedBox(height: 16),
          _buildNearbyDevices(),
          const SizedBox(height: 16),
          _buildIncomingAlerts(),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    final cardBg = _isDark ? const Color(0xFF0A1628) : const Color(0xFFE3F2FD);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade400, size: 16),
              const SizedBox(width: 8),
              Text(
                _t('How MUHAFIZ Bluetooth Works',
                    'محافظ بلوٹوتھ کیسے کام کرتا ہے'),
                style: TextStyle(
                    color: Colors.blue.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _t(
              '• BLE Scan detects nearby MUHAFIZ users within ~50 m\n'
              '• SOS Broadcast alerts all active users in the city via Firebase\n'
              '• Receiving devices VIBRATE with emergency pattern\n'
              '• Works even when app is in background (Firebase listener active)',
              '• BLE اسکین ~50 میٹر کے اندر قریبی محافظ صارفین کا پتہ لگاتا ہے\n'
              '• SOS نشر فائربیس کے ذریعے شہر کے تمام فعال صارفین کو الرٹ کرتا ہے\n'
              '• وصول کنندہ آلات ہنگامی نمونے سے وائبریٹ کرتے ہیں\n'
              '• بیک گراؤنڈ میں بھی کام کرتا ہے (فائربیس سننے والا فعال)',
            ),
            style: TextStyle(color: _onMuted, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildScanControl() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isScanning
              ? Colors.blue.withValues(alpha: 0.6)
              : _border,
        ),
        boxShadow: _isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bluetooth_searching,
                color: _isScanning ? Colors.blue : _onFaint,
              ),
              const SizedBox(width: 10),
              Text(
                _isScanning
                    ? _t('Scanning for nearby users…', 'قریبی صارفین کی تلاش…')
                    : _t('BLE Scanner', 'بی ایل ای اسکینر'),
                style: TextStyle(
                  color: _isScanning ? Colors.blue : _onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isScanning)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.blue),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isScanning ? Colors.grey.shade600 : Colors.blue.shade800,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                _isScanning ? Icons.stop : Icons.search,
                color: Colors.white,
              ),
              label: Text(
                _isScanning
                    ? _t('Stop Scan', 'اسکین بند کریں')
                    : _t('Start BLE Scan (20 sec)', 'بی ایل ای اسکین شروع کریں (20 سیکنڈ)'),
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: _toggleScan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSBroadcast() {
    return GestureDetector(
      onTap: _broadcastSOS,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade900, Colors.red.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('BROADCAST SOS', 'SOS نشر کریں'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t(
                      'Alert all nearby MUHAFIZ users.\nTheir phones will vibrate immediately.',
                      'تمام قریبی محافظ صارفین کو الرٹ کریں۔\nان کے فون فوری وائبریٹ کریں گے۔',
                    ),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyDevices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(Icons.devices_other, color: _onMuted, size: 16),
              const SizedBox(width: 8),
              Text(
                _t('Nearby BLE Devices', 'قریبی بی ایل ای آلات'),
                style: TextStyle(
                    color: _onMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const Spacer(),
              Text(
                _t('${_nearbyDevices.length} found',
                    '${_nearbyDevices.length} ملے'),
                style: TextStyle(color: _onFaint, fontSize: 12),
              ),
            ],
          ),
        ),
        if (_nearbyDevices.isEmpty)
          _buildEmptyState(
            icon: Icons.bluetooth_disabled,
            message: _isScanning
                ? _t('Scanning… nearby devices will appear here',
                    'اسکین جاری… قریبی آلات یہاں نظر آئیں گے')
                : _t('Start BLE scan to discover nearby devices',
                    'قریبی آلات دریافت کرنے کے لیے BLE اسکین شروع کریں'),
          )
        else
          ...(_nearbyDevices.take(10).map(_buildDeviceTile)),
      ],
    );
  }

  Widget _buildDeviceTile(NearbyDevice device) {
    final signalColor = device.rssi > -60
        ? Colors.green
        : device.rssi > -75
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: _isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(Icons.bluetooth, color: signalColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              device.name,
              style: TextStyle(color: _onSurface, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(device.proximity,
              style: TextStyle(color: signalColor, fontSize: 12)),
          const SizedBox(width: 8),
          Text('${device.rssi} dBm',
              style: TextStyle(color: _onFaint, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildIncomingAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.notification_important,
                  color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Text(
                _t('Received Emergency Alerts', 'موصول ہنگامی الرٹس'),
                style: TextStyle(
                    color: _onMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const Spacer(),
              Text(
                _t('${_alerts.length} received', '${_alerts.length} موصول'),
                style: TextStyle(color: _onFaint, fontSize: 12),
              ),
            ],
          ),
        ),
        if (_alerts.isEmpty)
          _buildEmptyState(
            icon: Icons.notifications_none,
            message: _t(
              'No emergency alerts received yet.\nListening in background.',
              'ابھی تک کوئی ہنگامی الرٹ موصول نہیں ہوا۔\nبیک گراؤنڈ میں سن رہا ہے۔',
            ),
          )
        else
          ...(_alerts.take(5).map(_buildAlertTile)),
      ],
    );
  }

  Widget _buildAlertTile(ProximityAlert alert) {
    final tileBg =
        _isDark ? const Color(0xFF2A0A0A) : const Color(0xFFFFF3F3);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.emergencyType,
                  style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                Text(
                  '${_t('From', 'از')}: ${alert.userName}',
                  style: TextStyle(color: _onMuted, fontSize: 12),
                ),
                if (alert.location.isNotEmpty)
                  Text(
                    alert.location,
                    style: TextStyle(color: _onFaint, fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(
            _timeAgo(alert.timestamp),
            style: TextStyle(color: _onFaint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: _onFaint, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: _onMuted, fontSize: 12),
            textDirection:
                _isUrdu ? TextDirection.rtl : TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}
