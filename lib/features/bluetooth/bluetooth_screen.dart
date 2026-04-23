import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../services/bluetooth_alert_service.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  bool _isScanning = false;
  bool _btAvailable = false;
  List<NearbyDevice> _nearbyDevices = [];
  final List<ProximityAlert> _alerts = [];

  StreamSubscription<List<NearbyDevice>>? _devicesSub;
  StreamSubscription<ProximityAlert>? _alertSub;
  StreamSubscription<dynamic>? _adapterSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Keep bluetooth availability updated live (user may toggle it in Settings).
    _adapterSub?.cancel();
    _adapterSub = BluetoothAlertService.adapterStateStream.listen((state) {
      if (!mounted) return;
      final on = state.toString().toLowerCase().contains('on');
      setState(() => _btAvailable = on);
      if (!on && _isScanning) {
        setState(() => _isScanning = false);
      }
    });

    // Seed initial state
    final available = await BluetoothAlertService.isBluetoothAvailable();
    if (mounted) setState(() => _btAvailable = available);

    // Listen to nearby devices stream
    _devicesSub = BluetoothAlertService.nearbyDevices.listen((devices) {
      if (mounted) setState(() => _nearbyDevices = devices);
    });

    // Listen for incoming emergency alerts from other MUHAFIZ users
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
        _showSnack('Turning on Bluetooth…', Colors.orange);
        final ok = await BluetoothAlertService.ensureBluetoothOn();
        if (!ok) {
          _showSnack('Bluetooth is off. Please enable it and try again.', Colors.orange);
          return;
        }
      }
      await BluetoothAlertService.startScanning();
      if (mounted) setState(() => _isScanning = true);
      // Auto-stop after 20 seconds (matches service timeout)
      Future.delayed(const Duration(seconds: 22), () {
        if (mounted) setState(() => _isScanning = false);
      });
    }
  }

  Future<void> _broadcastSOS() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Broadcast SOS?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will alert all active MUHAFIZ users nearby and in Karachi '
          'via Bluetooth and Firebase. Only use in real emergency.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('BROADCAST SOS', style: TextStyle(color: Colors.white)),
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
      if (mounted) _showSnack('SOS broadcast sent to all nearby MUHAFIZ users!', Colors.green);
    } catch (e) {
      if (mounted) _showSnack('Broadcast failed: $e', Colors.red);
    }
  }

  void _showAlertDialog(ProximityAlert alert) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('EMERGENCY NEARBY', style: TextStyle(color: Colors.red, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _alertRow('From', alert.userName),
            _alertRow('Type', alert.emergencyType),
            _alertRow('Location', alert.location.isNotEmpty ? alert.location : 'Nearby'),
            _alertRow('Time', _timeAgo(alert.timestamp)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
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
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Bluetooth Alerts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _btAvailable
                  ? Colors.blue.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bluetooth,
                  size: 14,
                  color: _btAvailable ? Colors.blue : Colors.grey,
                ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade300, size: 16),
              const SizedBox(width: 8),
              Text(
                'How MUHAFIZ Bluetooth Works',
                style: TextStyle(
                    color: Colors.blue.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '• BLE Scan detects nearby MUHAFIZ users within ~50 m\n'
            '• SOS Broadcast alerts all active users in the city via Firebase\n'
            '• Receiving devices VIBRATE with emergency pattern\n'
            '• Works even when app is in background (Firebase listener active)',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildScanControl() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isScanning
              ? Colors.blue.withValues(alpha: 0.6)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bluetooth_searching,
                color: _isScanning ? Colors.blue : Colors.white38,
              ),
              const SizedBox(width: 10),
              Text(
                _isScanning ? 'Scanning for nearby users…' : 'BLE Scanner',
                style: TextStyle(
                  color: _isScanning ? Colors.blue : Colors.white,
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
                    _isScanning ? Colors.grey.shade800 : Colors.blue.shade800,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                _isScanning ? Icons.stop : Icons.search,
                color: Colors.white,
              ),
              label: Text(
                _isScanning ? 'Stop Scan' : 'Start BLE Scan (20 sec)',
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BROADCAST SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Alert all nearby MUHAFIZ users.\nTheir phones will vibrate immediately.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
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
              const Icon(Icons.devices_other, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Nearby BLE Devices',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${_nearbyDevices.length} found',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
        if (_nearbyDevices.isEmpty)
          _buildEmptyState(
            icon: Icons.bluetooth_disabled,
            message: _isScanning
                ? 'Scanning… nearby devices will appear here'
                : 'Start BLE scan to discover nearby devices',
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.bluetooth, color: signalColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              device.name,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            device.proximity,
            style: TextStyle(color: signalColor, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            '${device.rssi} dBm',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
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
              const Icon(Icons.notification_important, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Received Emergency Alerts',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${_alerts.length} received',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
        if (_alerts.isEmpty)
          _buildEmptyState(
            icon: Icons.notifications_none,
            message: 'No emergency alerts received yet.\nListening in background.',
          )
        else
          ...(_alerts.take(5).map(_buildAlertTile)),
      ],
    );
  }

  Widget _buildAlertTile(ProximityAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0A0A),
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
                  'From: ${alert.userName}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (alert.location.isNotEmpty)
                  Text(
                    alert.location,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(
            _timeAgo(alert.timestamp),
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white24, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
