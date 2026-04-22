import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// A nearby MUHAFIZ user detected via BLE scan.
class NearbyDevice {
  final String id;
  final String name;
  final int rssi;
  final DateTime seenAt;

  const NearbyDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.seenAt,
  });

  String get proximity {
    if (rssi > -50) return '<5 m';
    if (rssi > -65) return '~10 m';
    if (rssi > -75) return '~20 m';
    return '~50 m+';
  }
}

/// An emergency alert received from a nearby MUHAFIZ user via Firebase.
class ProximityAlert {
  final String userId;
  final String userName;
  final String emergencyType;
  final String location;
  final DateTime timestamp;

  const ProximityAlert({
    required this.userId,
    required this.userName,
    required this.emergencyType,
    required this.location,
    required this.timestamp,
  });
}

/// Manages both BLE proximity scanning and Firebase-based emergency buzzing.
///
/// Architecture:
///   – BLE scan   : discovers physically nearby devices (within ~50 m)
///   – Firebase   : broadcasts emergency alerts to all active MUHAFIZ users
///                  in the city; triggers vibration on recipients' devices
class BluetoothAlertService {
  static StreamSubscription<List<ScanResult>>? _scanSub;
  static StreamSubscription<QuerySnapshot>? _firestoreSub;

  static final _nearbyController =
      StreamController<List<NearbyDevice>>.broadcast();
  static final _alertController =
      StreamController<ProximityAlert>.broadcast();

  static Stream<List<NearbyDevice>> get nearbyDevices =>
      _nearbyController.stream;
  static Stream<ProximityAlert> get incomingAlerts => _alertController.stream;

  static final Map<String, NearbyDevice> _seen = {};

  // ── BLE scanning ──────────────────────────────────────────────────────────

  static Stream<BluetoothAdapterState> get adapterStateStream =>
      FlutterBluePlus.adapterState;

  static Future<bool> isBluetoothAvailable() async {
    try {
      return FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  /// Ensures Bluetooth is ON (best-effort).
  /// On Android, this can prompt the user to enable Bluetooth.
  /// Returns `true` when adapter state becomes ON within a short timeout.
  static Future<bool> ensureBluetoothOn({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on) {
        return true;
      }

      // Best-effort: prompt user to enable Bluetooth (Android).
      // If unsupported on this platform/device, it will throw and we fall back.
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {}

      final state = await FlutterBluePlus.adapterState
          .firstWhere(
            (s) => s == BluetoothAdapterState.on,
          )
          .timeout(timeout);

      return state == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  /// Scan for any nearby BLE devices (general proximity awareness).
  /// Emits updated [NearbyDevice] list via [nearbyDevices] stream.
  static Future<void> startScanning() async {
    if (!await ensureBluetoothOn()) return;
    await _scanSub?.cancel();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));
    } catch (e) {
      debugPrint('BLE scan start error: $e');
      return;
    }

    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName.isNotEmpty
                ? r.advertisementData.advName
                : 'Unknown Device';

        _seen[r.device.remoteId.str] = NearbyDevice(
          id: r.device.remoteId.str,
          name: name,
          rssi: r.rssi,
          seenAt: DateTime.now(),
        );
      }
      // Remove devices not seen in the last 30 s
      _seen.removeWhere(
          (_, d) => DateTime.now().difference(d.seenAt).inSeconds > 30);
      _nearbyController.add(_seen.values.toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi)));
    });
  }

  static Future<void> stopScanning() async {
    await _scanSub?.cancel();
    _scanSub = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  // ── Firebase emergency broadcast ──────────────────────────────────────────

  /// Writes an emergency beacon document to Firestore.
  /// All active MUHAFIZ users listening via [listenForNearbyAlerts] will
  /// receive it and vibrate within seconds.
  static Future<void> broadcastEmergencyViaFirebase({
    required String emergencyType,
    required String locationText,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name1') ?? 'MUHAFIZ User';

    await FirebaseFirestore.instance.collection('ble_alerts').add({
      'userId': user.uid,
      'userName': name,
      'emergencyType': emergencyType,
      'location': locationText,
      'timestamp': FieldValue.serverTimestamp(),
      'active': true,
    });
  }

  /// Listens to recent (last 10 min) `ble_alerts` from OTHER users.
  /// Vibrates the device and emits a [ProximityAlert] for each new one.
  static void listenForNearbyAlerts() {
    _firestoreSub?.cancel();

    final cutoff = DateTime.now().subtract(const Duration(minutes: 10));
    final user = FirebaseAuth.instance.currentUser;

    _firestoreSub = FirebaseFirestore.instance
        .collection('ble_alerts')
        .where('active', isEqualTo: true)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) async {
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data() as Map<String, dynamic>;

        // Don't alert yourself
        if (data['userId'] == user?.uid) continue;

        final alert = ProximityAlert(
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? 'Unknown',
          emergencyType: data['emergencyType'] ?? 'SOS',
          location: data['location'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );

        _alertController.add(alert);

        // Buzz the receiving device
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(pattern: [0, 600, 200, 600, 200, 600]);
        }
      }
    });
  }

  static void stopListening() {
    _firestoreSub?.cancel();
    _firestoreSub = null;
  }

  static void disposeAll() {
    stopScanning();
    stopListening();
    _nearbyController.close();
    _alertController.close();
  }
}
