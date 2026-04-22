import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineEmergencyService {
  static const _pendingKey = 'muhafiz_pending_emergencies';

  // Save an emergency report to local storage (used when offline)
  static Future<void> queue(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_pendingKey) ?? [];
    // Store with local timestamp since Firestore serverTimestamp won't work offline
    final copy = Map<String, dynamic>.from(data);
    copy['localTimestamp'] = DateTime.now().toIso8601String();
    copy['pendingSync'] = true;
    existing.add(json.encode(copy));
    await prefs.setStringList(_pendingKey, existing);
  }

  // Called when connectivity is restored; pushes all cached reports to Firestore
  static Future<int> syncAll() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingKey) ?? [];
    if (pending.isEmpty) return 0;

    final failed = <String>[];
    var synced = 0;

    for (final raw in pending) {
      try {
        final data = json.decode(raw) as Map<String, dynamic>;
        data.remove('localTimestamp');
        data.remove('pendingSync');
        data['timestamp'] = FieldValue.serverTimestamp();
        data['syncedFromOffline'] = true;
        await FirebaseFirestore.instance.collection('emergencies').add(data);
        synced++;
      } catch (_) {
        failed.add(raw);
      }
    }

    await prefs.setStringList(_pendingKey, failed);
    return synced;
  }

  static Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_pendingKey) ?? []).length;
  }

  static Future<List<Map<String, dynamic>>> getPending() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_pendingKey) ?? [])
        .map((s) => json.decode(s) as Map<String, dynamic>)
        .toList();
  }
}
