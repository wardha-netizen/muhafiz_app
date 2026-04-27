import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'offline_emergency_service.dart';
import 'bluetooth_alert_service.dart';
import 'sms_service.dart';

class SosContact {
  final String name;
  final String phone;
  const SosContact({required this.name, required this.phone});
}

/// Manages the full lifecycle of an offline SOS event:
///   1. Auto-sends SMS to saved contacts immediately (SMS needs no internet).
///   2. Watches for connectivity; once restored, syncs queued reports to
///      Firestore and broadcasts a Firebase BLE alert to all MUHAFIZ users.
class OfflineSosService extends ChangeNotifier {
  static final OfflineSosService instance = OfflineSosService._();
  OfflineSosService._();

  bool isActive = false;
  bool isSyncing = false;
  bool isSynced = false;
  String emergencyType = '';
  String locationText = '';
  List<SosContact> smsSentTo = [];

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Future<void> trigger({
    required String emergencyType,
    required String locationText,
    required String userName,
    String? contact1Phone,
    String? contact1Name,
    String? contact2Phone,
    String? contact2Name,
  }) async {
    _connectivitySub?.cancel();

    this.emergencyType = emergencyType;
    this.locationText = locationText;
    isActive = true;
    isSynced = false;
    isSyncing = false;
    smsSentTo = [];
    notifyListeners();

    final msg = '🚨 MUHAFIZ EMERGENCY ALERT 🚨\n'
        'User: $userName\n'
        'Emergency: $emergencyType\n'
        'Location: $locationText\n'
        'Sent via MUHAFIZ Emergency App';

    final c1 = contact1Phone?.trim() ?? '';
    final c2 = contact2Phone?.trim() ?? '';

    if (c1.isNotEmpty) {
      try {
        await SMSService.sendEmergencySMS(c1, msg);
        smsSentTo = [
          ...smsSentTo,
          SosContact(
            name: (contact1Name?.isNotEmpty == true) ? contact1Name! : 'Contact 1',
            phone: c1,
          ),
        ];
        notifyListeners();
      } catch (_) {}
    }

    if (c2.isNotEmpty) {
      try {
        await SMSService.sendEmergencySMS(c2, msg);
        smsSentTo = [
          ...smsSentTo,
          SosContact(
            name: (contact2Name?.isNotEmpty == true) ? contact2Name! : 'Contact 2',
            phone: c2,
          ),
        ];
        notifyListeners();
      } catch (_) {}
    }

    // When internet returns: sync queued report + alert MUHAFIZ community
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) async {
      if (results.contains(ConnectivityResult.none)) return;
      if (isSynced || isSyncing) return;

      isSyncing = true;
      notifyListeners();

      try {
        await OfflineEmergencyService.syncAll();
        await BluetoothAlertService.broadcastEmergencyViaFirebase(
          emergencyType: this.emergencyType,
          locationText: this.locationText,
        );
        isSynced = true;
      } catch (_) {}

      isSyncing = false;
      notifyListeners();
      _connectivitySub?.cancel();
    });
  }

  void stopSos() {
    _connectivitySub?.cancel();
    isActive = false;
    isSyncing = false;
    isSynced = false;
    smsSentTo = [];
    emergencyType = '';
    locationText = '';
    notifyListeners();
  }
}
