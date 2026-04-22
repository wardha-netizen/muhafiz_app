import 'package:workmanager/workmanager.dart';

// This function MUST be outside any class (top-level)
// so the OS can find it while the app is in the background
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Logic: Look for "pending" reports in local cache and push to Firestore
    // This runs only when the system detects a stable network connection
    return Future.value(true);
  });
}

class BackgroundSyncService {
  // Initialize this in your main.dart
  static void initialize() {
    Workmanager().initialize(callbackDispatcher);
  }

  // Call this whenever an SOS is triggered while offline
  static void scheduleSync() {
    Workmanager().registerOneOffTask(
      'muhafiz_sync_task',
      'sync_emergency_data',
      constraints: Constraints(
        networkType: NetworkType.connected, // Only sync when online
      ),
    );
  }
}
